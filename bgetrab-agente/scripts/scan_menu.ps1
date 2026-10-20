<#
  scan_menu.ps1 - Verificacao de aderencia dos CSVs FATOS_CAGED_TRABS_AJUSTADO
  Projeto BGETRAB (OCI). Menu interativo, processa UM ano por vez.

  CRITERIOS (schema de 50 campos; indice 0-based entre parenteses):
    [1] DT_COMPETENCIA_MOVIMENTACAO (idx 2) no formato AAAAMM (truncamento)
    [2] Estrutura: 50 campos por linha (desalinhamento por ';' em NM_TRABALHADOR)
    [3] VL_SALARIO_MENSAL_DECLARADO (idx 24) vazio
    [4] NU_IDADE_TRABALHADOR (idx 18) vazio
    [5] NU_CPF_TRABALHADOR (idx 16) mascarado
    [6] NU_PIS_TRABALHADOR (idx 19) mascarado
    [A] Todos

  O foco aceita SELECAO MULTIPLA separada por virgula (ex.: 1  |  1,4  |  3,5,6  |  A).
  A Estrutura (contagem de 50 campos) e sempre calculada internamente, pois os demais
  criterios dependem dela; porem so e EXIBIDA/consolidada se o criterio [2] for escolhido.

  Modos:
    [A] Amostragem rapida : inicio 80 MB + meio 4 MB + fim 4 MB (~1 min/ano)
    [C] Completo          : streaming de blocos de 256 MB (lento; le o arquivo inteiro)

  SAIDA EM ARQUIVO (append entre execucoes):
    scripts/resultados/scan_resultados.csv  (colunas FIXAS; so as escolhidas sao preenchidas)
    scripts/resultados/scan_resultados.log  (bloco legivel, igual a tela)
  Ambos em UTF-8 sem BOM.

  Observacao LGPD: o script conta ocorrencias; NAO exibe valores de campos com PII.
  Requer sessao OCI valida (perfil bgetrab-session). Variaveis de CA (bundle) do ambiente.
#>

$ErrorActionPreference = 'Stop'

$NS      = 'grmu0oy5wsd9'
$BUCKET  = 'bucket-bgetrab-prod'
$PREFIX  = 'FATOS_CAGED_TRABS_AJUSTADO_'
$PROFILE = 'bgetrab-session'

# Controle de expiracao de sessao (Opcao B): o token de sessao OCI dura ~60 min e o
# 'oci session refresh' NAO funciona neste ambiente (TLS do endpoint auth.* interceptado).
# Em vez de refrescar, o script LE o 'exp' do token e, se faltar menos que SESSION_MARGIN_MIN
# minutos para expirar, PAUSA e pede novo login (oci session authenticate) antes de cada bloco.
$SESSION_MARGIN_MIN = 3

$bundle = $env:OCI_CLI_CA_BUNDLE
if (-not $bundle) { $bundle = Join-Path $env:USERPROFILE '.oci\oci-ca-bundle.pem' }

# pasta/arquivos de saida (ao lado deste script)
$OUT_DIR = Join-Path $PSScriptRoot 'resultados'
New-Item -ItemType Directory -Force -Path $OUT_DIR | Out-Null
$OUT_CSV = Join-Path $OUT_DIR 'scan_resultados.csv'
$OUT_LOG = Join-Path $OUT_DIR 'scan_resultados.log'
$ENC = New-Object System.Text.UTF8Encoding($false)

# indices (0-based)
$IDX_DTCMOV = 2
$IDX_NM     = 14
$IDX_CPF    = 16
$IDX_IDADE  = 18
$IDX_PIS    = 19
$IDX_SAL    = 24

# mapa numero -> codigo de criterio
$CRIT = [ordered]@{
  '1' = 'dtcmov'
  '2' = 'estrutura'
  '3' = 'salario'
  '4' = 'idade'
  '5' = 'cpf'
  '6' = 'pis'
}
$CRIT_LABEL = @{
  'dtcmov'    = 'DT_COMPETENCIA_MOVIMENTACAO fora de AAAAMM'
  'estrutura' = 'Estrutura (linhas !=50 campos)'
  'salario'   = 'VL_SALARIO_MENSAL_DECLARADO vazio'
  'idade'     = 'NU_IDADE_TRABALHADOR vazio'
  'cpf'       = 'NU_CPF mascarado'
  'pis'       = 'NU_PIS mascarado'
}

function Append-File([string]$path,[string]$text) {
  if (Test-Path $path) { $existing = [System.IO.File]::ReadAllText($path) } else { $existing = '' }
  [System.IO.File]::WriteAllText($path, $existing + $text, $ENC)
}

function Ensure-CsvHeader {
  if (-not (Test-Path $OUT_CSV)) {
    $hdr = 'timestamp;ano;modo;criterios;linhas;desalinhadas;dtcmov_fora;dtcmov_pct;sal_vazio;idade_vazio;cpf_masc;pis_masc;situacao;tempo_s'
    [System.IO.File]::WriteAllText($OUT_CSV, $hdr + "`r`n", $ENC)
  }
}

function Parse-Foco([string]$raw) {
  # retorna lista de codigos de criterio na ordem 1..6; 'A' = todos
  $raw = $raw.Trim()
  if ($raw -match '^[Aa]$') { return @($CRIT.Values) }
  $sel = New-Object System.Collections.Generic.List[string]
  foreach ($tok in ($raw -split '[,; ]+')) {
    $t = $tok.Trim()
    if ($t -eq '') { continue }
    if ($CRIT.Contains($t)) {
      $code = $CRIT[$t]
      if (-not $sel.Contains($code)) { $sel.Add($code) }
    }
  }
  return $sel
}

function Test-Session {
  $job = Start-Job -ArgumentList $bundle,$NS,$PROFILE -ScriptBlock {
    param($b,$ns,$prof)
    $env:OCI_CLI_CA_BUNDLE=$b; $env:REQUESTS_CA_BUNDLE=$b; $env:SSL_CERT_FILE=$b
    oci os ns get --profile $prof --auth security_token 2>&1
  }
  if (Wait-Job $job -Timeout 30) { $r = Receive-Job $job } else { Stop-Job $job; $r = $null }
  Remove-Job $job -Force
  return (($r | Out-String) -match $NS)
}

function Get-TokenExpiry {
  # retorna [DateTimeOffset] de expiracao do token da sessao, lendo o claim exp do JWT.
  # NAO expoe o token. Retorna $null se nao conseguir ler.
  try {
    $cfg = Join-Path $env:USERPROFILE '.oci\config'
    $tokFile = $null
    $inProf = $false
    foreach ($ln in (Get-Content $cfg)) {
      if ($ln -match '^\s*\[(.+)\]\s*$') { $inProf = ($Matches[1] -eq $PROFILE); continue }
      if ($inProf -and $ln -match '^\s*security_token_file\s*=\s*(.+?)\s*$') { $tokFile = $Matches[1]; break }
    }
    if (-not $tokFile) { $tokFile = Join-Path $env:USERPROFILE (".oci\sessions\{0}\token" -f $PROFILE) }
    if (-not (Test-Path $tokFile)) { return $null }
    $jwt = (Get-Content $tokFile -Raw).Trim()
    $parts = $jwt.Split('.')
    if ($parts.Count -lt 2) { return $null }
    $p = $parts[1].Replace('-','+').Replace('_','/')
    switch ($p.Length % 4) { 2 { $p += '==' } 3 { $p += '=' } }
    $obj = ([System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($p))) | ConvertFrom-Json
    if (-not $obj.exp) { return $null }
    return [DateTimeOffset]::FromUnixTimeSeconds([int64]$obj.exp)
  } catch { return $null }
}

function Ensure-SessionTime {
  # Opcao B: antes de cada bloco, se faltar < SESSION_MARGIN_MIN min para expirar, pausa e
  # pede novo login. Fica no loop ate a sessao ter folga (e o token valido).
  while ($true) {
    $exp = Get-TokenExpiry
    if ($null -eq $exp) {
      Write-Host '    [nao foi possivel ler a expiracao do token; verifique a sessao]' -ForegroundColor Yellow
      return
    }
    $mins = ($exp.ToUnixTimeSeconds() - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds())/60.0
    if ($mins -ge $SESSION_MARGIN_MIN) { return }  # folga suficiente
    Write-Host ''
    Write-Host ("  [SESSAO EXPIRANDO] faltam ~{0:N1} min. Pausando antes do proximo bloco." -f $mins) -ForegroundColor Yellow
    Write-Host '  No OUTRO terminal rode:  oci session authenticate --region sa-saopaulo-1' -ForegroundColor Cyan
    Write-Host '  (perfil: bgetrab-session). Depois volte aqui.' -ForegroundColor Cyan
    [void](Read-Host '  Pressione ENTER apos concluir o login para continuar')
    $exp2 = Get-TokenExpiry
    if ($exp2 -and (($exp2.ToUnixTimeSeconds() - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds())/60.0) -ge $SESSION_MARGIN_MIN) {
      Write-Host ("  [sessao renovada - nova expiracao em ~{0:N1} min]" -f (($exp2.ToUnixTimeSeconds()-[DateTimeOffset]::UtcNow.ToUnixTimeSeconds())/60.0)) -ForegroundColor Green
      return
    }
    Write-Host '  [sessao ainda sem folga - verifique se usou o perfil bgetrab-session. Tentando de novo...]' -ForegroundColor Yellow
  }
}

function Get-Anos {
  $job = Start-Job -ArgumentList $bundle,$NS,$BUCKET,$PREFIX -ScriptBlock {
    param($b,$ns,$bk,$pfx)
    $env:OCI_CLI_CA_BUNDLE=$b; $env:REQUESTS_CA_BUNDLE=$b; $env:SSL_CERT_FILE=$b
    oci os object list --namespace $ns --bucket-name $bk --prefix $pfx --fields name,size --all 2>&1
  }
  if (Wait-Job $job -Timeout 90) { $out = Receive-Job $job } else { Stop-Job $job; Remove-Job $job -Force; throw 'Timeout listando objetos' }
  Remove-Job $job -Force
  $data = ($out | Out-String) | ConvertFrom-Json
  $res = @()
  foreach ($o in $data.data) {
    if ($o.name -match 'FATOS_CAGED_TRABS_AJUSTADO_(\d{4})\.csv$') {
      $res += [pscustomobject]@{ Ano=[int]$Matches[1]; Name=$o.name; Size=[int64]$o.size }
    }
  }
  return ($res | Sort-Object Ano)
}

function Get-Range([string]$name,[int64]$ini,[int64]$fim,[string]$file) {
  $job = Start-Job -ArgumentList $bundle,$NS,$BUCKET,$name,$ini,$fim,$file,$PROFILE -ScriptBlock {
    param($b,$ns,$bk,$nm,$i,$f,$out,$prof)
    $env:OCI_CLI_CA_BUNDLE=$b; $env:REQUESTS_CA_BUNDLE=$b; $env:SSL_CERT_FILE=$b
    oci os object get --namespace $ns --bucket-name $bk --name $nm --file $out --range ("bytes={0}-{1}" -f $i,$f) --profile $prof --auth security_token 2>&1 | Out-Null
  }
  if (Wait-Job $job -Timeout 600) { Receive-Job $job | Out-Null; $ok=$true } else { Stop-Job $job; $ok=$false }
  Remove-Job $job -Force
  return $ok
}

function New-Acc { return @{ total=0; desal=0; sal=0; idade=0; cpf=0; pis=0; dtok=0; dtbad=0 } }

function Analyze([string[]]$lines,[hashtable]$acc,[string[]]$crit) {
  $wantDt  = $crit -contains 'dtcmov'
  $wantSal = $crit -contains 'salario'
  $wantIda = $crit -contains 'idade'
  $wantCpf = $crit -contains 'cpf'
  $wantPis = $crit -contains 'pis'
  foreach ($ln in $lines) {
    if ($ln -eq '') { continue }
    if ($ln -like 'ID_SEQ_FATOS*') { continue }  # descarta cabecalho
    $f = $ln.Split(';')
    $acc.total++
    if ($f.Count -ne 50) { $acc.desal++; continue }  # estrutura sempre contada
    if ($wantDt) {
      $dc = $f[$IDX_DTCMOV].Trim()
      if ($dc -match '^\d{4}(0[1-9]|1[0-2])$') { $acc.dtok++ } else { $acc.dtbad++ }
    }
    if ($wantSal -and $f[$IDX_SAL].Trim()   -eq '') { $acc.sal++ }
    if ($wantIda -and $f[$IDX_IDADE].Trim() -eq '') { $acc.idade++ }
    if ($wantCpf -and $f[$IDX_CPF] -like '*`**')    { $acc.cpf++ }
    if ($wantPis -and $f[$IDX_PIS] -like '*`**')    { $acc.pis++ }
  }
}

function Scan-Amostra([pscustomobject]$a,[string[]]$crit) {
  $tmp = Join-Path $env:TEMP ('bge_'+$a.Ano)
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  $acc = New-Acc
  $blocos = @(
    @{ ini=[int64]0;                 fim=[int64](80MB-1);          dropFirst=$false; dropLast=$true },
    @{ ini=[int64]($a.Size/2);       fim=[int64]($a.Size/2+4MB-1); dropFirst=$true;  dropLast=$true },
    @{ ini=[int64]($a.Size-4MB);     fim=[int64]($a.Size-1);       dropFirst=$true;  dropLast=$false }
  )
  foreach ($bl in $blocos) {
    Ensure-SessionTime
    $file = Join-Path $tmp ('b'+$bl.ini+'.csv')
    if (Get-Range $a.Name $bl.ini $bl.fim $file) {
      $lines = [System.IO.File]::ReadAllLines($file)
      if ($lines.Count -gt 1) {
        $s = 0; $e = $lines.Count-1
        if ($bl.dropFirst) { $s = 1 }
        if ($bl.dropLast)  { $e = $lines.Count-2 }
        if ($e -ge $s) { Analyze $lines[$s..$e] $acc $crit }
      }
      Remove-Item $file -Force -ErrorAction SilentlyContinue
    }
  }
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  return $acc
}

function Scan-Completo([pscustomobject]$a,[string[]]$crit) {
  $tmp = Join-Path $env:TEMP ('bgefull_'+$a.Ano)
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  $acc = New-Acc
  $BLOCK = [int64]256MB
  $pos = [int64]0
  $carry = ''
  $n = 0
  while ($pos -lt $a.Size) {
    Ensure-SessionTime
    $fim = [Math]::Min($pos + $BLOCK - 1, $a.Size - 1)
    $file = Join-Path $tmp 'blk.csv'
    $n++
    Write-Host ("    bloco {0}: bytes {1:N0}-{2:N0} ({3:N1}%)" -f $n,$pos,$fim,(100.0*$fim/$a.Size))
    if (-not (Get-Range $a.Name $pos $fim $file)) { Write-Host '    (falha no bloco; abortando ano)'; break }
    $text = [System.IO.File]::ReadAllText($file)
    Remove-Item $file -Force -ErrorAction SilentlyContinue
    $text = $carry + $text
    $isLast = ($fim -ge $a.Size - 1)
    $lines = $text -split "`n"
    if (-not $isLast) {
      $carry = $lines[$lines.Count-1]
      $lines = $lines[0..($lines.Count-2)]
    } else { $carry = '' }
    $lines = $lines | ForEach-Object { $_.TrimEnd("`r") }
    Analyze $lines $acc $crit
    $pos = $fim + 1
  }
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  return $acc
}

function Classify([hashtable]$acc,[string[]]$crit) {
  # avalia APENAS os criterios escolhidos; AFETADO se algum apresenta problema real
  if ($crit -contains 'estrutura' -and $acc.desal -gt 0) { return 'AFETADO' }
  if ($crit -contains 'dtcmov'    -and $acc.dtbad -gt 0) { return 'AFETADO' }
  if ($crit -contains 'salario'   -and $acc.sal   -gt 0) { return 'AFETADO' }
  if ($crit -contains 'idade'     -and $acc.idade -gt 0) { return 'AFETADO' }
  $t = [Math]::Max(1,$acc.total)
  if ($crit -contains 'cpf' -and $acc.cpf -lt $t) { return 'ATENCAO (CPF nao 100% mascarado)' }
  if ($crit -contains 'pis' -and $acc.pis -lt $t) { return 'ATENCAO (PIS nao 100% mascarado)' }
  return 'limpo'
}

function Report-Result([int]$ano,[hashtable]$acc,[string[]]$crit,[string]$modo,[double]$seg) {
  $t = [Math]::Max(1,$acc.total)
  $pct = 100.0*$acc.dtbad/$t
  $sit = Classify $acc $crit
  $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  $critStr = ($crit -join ',')

  # linhas de detalhe (so dos criterios escolhidos)
  $det = New-Object System.Collections.Generic.List[string]
  $det.Add(("  linhas amostradas        : {0:N0}" -f $acc.total))
  if ($crit -contains 'estrutura') { $det.Add(("  desalinhadas (!=50)      : {0:N0}" -f $acc.desal)) }
  if ($crit -contains 'dtcmov')    { $det.Add(("  DT_COMPETENCIA_MOVIMENTACAO fora de AAAAMM : {0:N0}  ({1:N2}%)" -f $acc.dtbad,$pct)) }
  if ($crit -contains 'salario')   { $det.Add(("  VL_SALARIO_MENSAL_DECLARADO vazio : {0:N0}" -f $acc.sal)) }
  if ($crit -contains 'idade')     { $det.Add(("  NU_IDADE_TRABALHADOR vazio        : {0:N0}" -f $acc.idade)) }
  if ($crit -contains 'cpf')       { $det.Add(("  NU_CPF mascarado                  : {0:N0} / {1:N0}" -f $acc.cpf,$acc.total)) }
  if ($crit -contains 'pis')       { $det.Add(("  NU_PIS mascarado                  : {0:N0} / {1:N0}" -f $acc.pis,$acc.total)) }

  # ---- tela ----
  Write-Host ''
  Write-Host ("===== RESULTADO $ano ($modo) [criterios: $critStr] =====") -ForegroundColor Cyan
  foreach ($d in $det) { Write-Host $d }
  Write-Host ("  situacao                 : {0}" -f $sit)
  Write-Host '================================'

  # ---- LOG ----
  $log = New-Object System.Collections.Generic.List[string]
  $log.Add("===== RESULTADO $ano ($modo) [criterios: $critStr] - $ts =====")
  foreach ($d in $det) { $log.Add($d) }
  $log.Add(("  situacao                 : {0}" -f $sit))
  $log.Add(("  tempo (s)                : {0:N1}" -f $seg))
  $log.Add('================================')
  Append-File $OUT_LOG (($log -join "`r`n") + "`r`n")

  # ---- CSV (colunas FIXAS; so as escolhidas preenchidas) ----
  Ensure-CsvHeader
  $desC = if ($crit -contains 'estrutura') { $acc.desal } else { '' }
  $dtC  = if ($crit -contains 'dtcmov')    { $acc.dtbad } else { '' }
  $dtP  = if ($crit -contains 'dtcmov')    { ('{0:N2}' -f $pct) -replace ',', '.' } else { '' }
  $salC = if ($crit -contains 'salario')   { $acc.sal } else { '' }
  $idaC = if ($crit -contains 'idade')     { $acc.idade } else { '' }
  $cpfC = if ($crit -contains 'cpf')       { $acc.cpf } else { '' }
  $pisC = if ($crit -contains 'pis')       { $acc.pis } else { '' }
  $row = ("{0};{1};{2};{3};{4};{5};{6};{7};{8};{9};{10};{11};{12};{13:N1}" -f `
          $ts,$ano,$modo,$critStr,$acc.total,$desC,$dtC,$dtP,$salC,$idaC,$cpfC,$pisC,$sit,$seg)
  Append-File $OUT_CSV ($row + "`r`n")
}

# ---- validacao de sessao ----
Write-Host 'Validando sessao OCI...' -ForegroundColor Yellow
if (-not (Test-Session)) {
  Write-Host 'Sessao OCI invalida/expirada. Rode: oci session authenticate --region sa-saopaulo-1 (perfil bgetrab-session) e tente de novo.' -ForegroundColor Red
  return
}
Write-Host 'Sessao OK.' -ForegroundColor Green
Write-Host ("Resultados serao gravados em:")
Write-Host ("  CSV: $OUT_CSV")
Write-Host ("  LOG: $OUT_LOG")

$anos = Get-Anos

while ($true) {
  Write-Host ''
  Write-Host '==================== MENU - VARREDURA CAGED ====================' -ForegroundColor Cyan
  $i = 1
  $map = @{}
  foreach ($a in $anos) {
    $gb = $a.Size/1GB
    $flag = if ($a.Size -lt 1KB) { ' [VAZIO]' } else { '' }
    Write-Host ("  [{0,2}] {1}  ({2:N2} GB){3}" -f $i,$a.Ano,$gb,$flag)
    $map[$i] = $a
    $i++
  }
  Write-Host '  [T] Todos os anos (pula vazios)'
  Write-Host '  [Q] Sair'
  $sel = Read-Host 'Escolha o numero do ano (ou T / Q)'
  if ($sel -match '^[Qq]$') { break }

  $alvo = @()
  if ($sel -match '^[Tt]$') { $alvo = $anos | Where-Object { $_.Size -ge 1KB } }
  elseif ($sel -match '^\d+$' -and $map.ContainsKey([int]$sel)) { $alvo = @($map[[int]$sel]) }
  else { Write-Host 'Opcao invalida.' -ForegroundColor Red; continue }

  $modo = Read-Host 'Modo: [A]mostragem rapida ou [C]ompleto'

  Write-Host ''
  Write-Host 'Criterios (escolha um ou mais, separados por virgula; ou A para todos):'
  Write-Host '  [1] DT_COMPETENCIA_MOVIMENTACAO (formato AAAAMM)'
  Write-Host '  [2] Estrutura (50 campos / desalinhamento)'
  Write-Host '  [3] VL_SALARIO_MENSAL_DECLARADO vazio'
  Write-Host '  [4] NU_IDADE_TRABALHADOR vazio'
  Write-Host '  [5] NU_CPF_TRABALHADOR mascarado'
  Write-Host '  [6] NU_PIS_TRABALHADOR mascarado'
  Write-Host '  [A] Todos'
  $focoRaw = Read-Host 'Criterios'
  $crit = Parse-Foco $focoRaw
  if ($crit.Count -eq 0) {
    Write-Host 'Nenhum criterio valido; usando [1] DT_COMPETENCIA_MOVIMENTACAO por padrao.' -ForegroundColor Yellow
    $crit = @('dtcmov')
  }
  Write-Host ("Criterios selecionados: " + ($crit -join ', ')) -ForegroundColor DarkGray

  foreach ($a in $alvo) {
    if ($a.Size -lt 1KB) { Write-Host ("Ano {0}: CSV vazio - pulando." -f $a.Ano) -ForegroundColor Yellow; continue }
    Write-Host ''
    Write-Host ("Varredura {0} ({1:N2} GB)..." -f $a.Ano,($a.Size/1GB)) -ForegroundColor Yellow
    $t0 = Get-Date
    if ($modo -match '^[Cc]$') { $acc = Scan-Completo $a $crit; $m='Completo' }
    else                       { $acc = Scan-Amostra  $a $crit; $m='Amostragem' }
    $seg = ((Get-Date)-$t0).TotalSeconds
    Report-Result $a.Ano $acc $crit $m $seg
    Write-Host ("  (tempo: {0:N1} s) - gravado em scan_resultados.csv/.log" -f $seg) -ForegroundColor DarkGray
  }
}
Write-Host 'Encerrado.'
Write-Host ("Resultados em: $OUT_DIR")