<#
  apex_tunnel.ps1 - Acesso automatizado ao APEX (BGETRAB_OAC) via Bastion (port forwarding).
  Projeto BGETRAB (OCI).

  Faz: 1) valida sessao OCI; 2) reutiliza a sessao de Bastion ACTIVE (ou cria uma nova);
       3) monta o SSH command no padrao do usuario (-v, chave privada, porta local 443);
       4) abre o navegador no APEX; 5) inicia o tunel SSH em 1o plano.

  Login no APEX permanece MANUAL (nao automatizado - seguranca).

  Requisitos: sessao OCI valida (perfil bgetrab-session); OpenSSH (ssh) no PATH;
  par de chaves SSH (a chave PUBLICA ja registrada/aceita pelo bastion).

  O caminho das chaves NAO e fixo. Resolucao, em ordem de prioridade:
    1) parametros -PrivKey / -PubKey;
    2) variaveis de ambiente BGETRAB_SSH_PRIV_KEY / BGETRAB_SSH_PUB_KEY;
    3) autodescoberta em %USERPROFILE%\.ssh (par *.key + *.key.pub, ou id_*).
  Se a .pub nao for informada, assume-se "<priv>.pub".

  Uso:
    powershell -ExecutionPolicy Bypass -File .\scripts\apex_tunnel.ps1
    powershell -ExecutionPolicy Bypass -File .\scripts\apex_tunnel.ps1 -PrivKey "C:\caminho\minha-chave.key"
#>

param(
  # Caminho da chave PRIVADA SSH. Se omitido, usa env BGETRAB_SSH_PRIV_KEY ou autodescoberta em ~/.ssh.
  [string] $PrivKey,
  # Caminho da chave PUBLICA SSH. Se omitido, usa env BGETRAB_SSH_PUB_KEY ou "<PrivKey>.pub".
  [string] $PubKey
)

$ErrorActionPreference = 'Stop'

# ---- Parametros fixos (memoria do projeto) ----
$NS         = 'grmu0oy5wsd9'
$PROFILE    = 'bgetrab-session'
$BASTION_ID = 'ocid1.bastion.oc1.sa-saopaulo-1.amaaaaaa2n4fqhiaicw4malxu4pzbkpg7rfy2q7spaxhhxyqrsulghxh6baa'
$SESS_DEFAULT = 'Session-APEX'   # nome padrao (Enter aceita); perguntado ao usuario adiante
$TARGET_IP  = '10.217.48.81'
$TARGET_PORT= 443
$LOCAL_PORT = 443
$TTL        = 10800
# ---- Resolucao do caminho das chaves SSH (parametro > env > autodescoberta em ~/.ssh) ----
function Resolve-SshKeys {
  param([string]$PrivArg, [string]$PubArg)

  # 1) Chave privada: parametro -> env -> autodescoberta
  $priv = $PrivArg
  if (-not $priv) { $priv = $env:BGETRAB_SSH_PRIV_KEY }
  if (-not $priv) {
    $sshDir = Join-Path $env:USERPROFILE '.ssh'
    if (Test-Path $sshDir) {
      # Preferir um par *.key (padrao OCI); senao id_* (sem extensao .pub)
      $cand = Get-ChildItem -Path $sshDir -Filter '*.key' -File -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1
      if (-not $cand) {
        $cand = Get-ChildItem -Path $sshDir -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^id_' -and $_.Extension -ne '.pub' } |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1
      }
      if ($cand) { $priv = $cand.FullName }
    }
  }
  if (-not $priv) {
    throw "Chave privada SSH nao encontrada. Informe via -PrivKey, a variavel BGETRAB_SSH_PRIV_KEY, ou coloque o par em %USERPROFILE%\.ssh."
  }
  if (-not (Test-Path $priv)) { throw "Chave privada nao existe no caminho: $priv" }

  # 2) Chave publica: parametro -> env -> "<priv>.pub"
  $pub = $PubArg
  if (-not $pub) { $pub = $env:BGETRAB_SSH_PUB_KEY }
  if (-not $pub) { $pub = "$priv.pub" }
  if (-not (Test-Path $pub)) { throw "Chave publica nao existe no caminho: $pub (informe -PubKey ou BGETRAB_SSH_PUB_KEY)" }

  return [pscustomobject]@{ Priv = $priv; Pub = $pub }
}

$keys = Resolve-SshKeys -PrivArg $PrivKey -PubArg $PubKey
$PRIV_KEY = $keys.Priv
$PUB_KEY  = $keys.Pub
Write-Host ("Chave privada: {0}" -f $PRIV_KEY) -ForegroundColor DarkGray
Write-Host ("Chave publica: {0}" -f $PUB_KEY)  -ForegroundColor DarkGray
$APEX_URL   = 'https://localhost/ords/_/landing'

$bundle = $env:OCI_CLI_CA_BUNDLE
if (-not $bundle) { $bundle = Join-Path $env:USERPROFILE '.oci\oci-ca-bundle.pem' }

function Invoke-Oci([string[]]$ociArgs,[int]$timeout=60) {
  $job = Start-Job -ArgumentList $bundle,$ociArgs -ScriptBlock {
    param($b,$a)
    $env:OCI_CLI_CA_BUNDLE=$b; $env:REQUESTS_CA_BUNDLE=$b; $env:SSL_CERT_FILE=$b
    & oci @a 2>&1
  }
  if (Wait-Job $job -Timeout $timeout) { $r = Receive-Job $job } else { Stop-Job $job; $r = 'TIMEOUT' }
  Remove-Job $job -Force
  return ($r | Out-String)
}


# ---- 1) validar sessao OCI ----
Write-Host 'Validando sessao OCI...' -ForegroundColor Yellow
$ns = Invoke-Oci @('os','ns','get','--profile',$PROFILE,'--auth','security_token') 30
if ($ns -notmatch $NS) {
  Write-Host 'Sessao OCI invalida/expirada. Rode em outro terminal:' -ForegroundColor Red
  Write-Host '  oci session authenticate --region sa-saopaulo-1   (perfil: bgetrab-session)' -ForegroundColor Cyan
  return
}
Write-Host 'Sessao OCI OK.' -ForegroundColor Green

# ---- nome da sessao (perguntar; Enter usa o padrao) ----
$resp = Read-Host ("Defina o nome da sessao? [padrao: {0}]" -f $SESS_DEFAULT)
if ([string]::IsNullOrWhiteSpace($resp)) { $SESS_NAME = $SESS_DEFAULT } else { $SESS_NAME = $resp.Trim() }
Write-Host ("Nome da sessao: {0}" -f $SESS_NAME) -ForegroundColor DarkGray


# ---- 2) reutilizar sessao ACTIVE ou criar ----
Write-Host 'Procurando sessao de bastion ACTIVE...' -ForegroundColor Yellow
$sid = $null
$lst = Invoke-Oci @('bastion','session','list','--bastion-id',$BASTION_ID,'--session-lifecycle-state','ACTIVE','--all','--profile',$PROFILE,'--auth','security_token') 60
try {
  $d = $lst | ConvertFrom-Json
  $match = $d.data | Where-Object { $_.'display-name' -eq $SESS_NAME } | Select-Object -First 1
  if ($match) { $sid = $match.id; Write-Host ("Reutilizando sessao ACTIVE: $sid") -ForegroundColor Green }
} catch { }

if (-not $sid) {
  Write-Host 'Nenhuma sessao ACTIVE encontrada; criando nova...' -ForegroundColor Yellow
  $cr = Invoke-Oci @('bastion','session','create-port-forwarding','--bastion-id',$BASTION_ID,'--display-name',$SESS_NAME,'--ssh-public-key-file',$PUB_KEY,'--target-private-ip',$TARGET_IP,'--target-port',"$TARGET_PORT",'--session-ttl',"$TTL",'--profile',$PROFILE,'--auth','security_token') 90
  try { $sid = ($cr | ConvertFrom-Json).data.id } catch { }
  if (-not $sid) { Write-Host 'Falha ao criar a sessao:' -ForegroundColor Red; Write-Host $cr; return }
  Write-Host ("Sessao criada: $sid (aguardando ACTIVE)") -ForegroundColor Green
  for ($t=1; $t -le 12; $t++) {
    Start-Sleep 8
    $g = Invoke-Oci @('bastion','session','get','--session-id',$sid,'--profile',$PROFILE,'--auth','security_token') 45
    try { $st = ($g | ConvertFrom-Json).data.'lifecycle-state' } catch { $st = '?' }
    Write-Host ("  tentativa $t : $st")
    if ($st -eq 'ACTIVE') { break }
    if ($st -eq 'FAILED' -or $st -eq 'DELETED') { Write-Host "estado terminal: $st" -ForegroundColor Red; return }
  }
}

# ---- 3) montar o SSH command no padrao do usuario ----
$sshCmd = ('ssh -i "{0}" -v -N -L {1}:{2}:{3} -p 22 {4}@host.bastion.sa-saopaulo-1.oci.oraclecloud.com' -f `
           $PRIV_KEY, $LOCAL_PORT, $TARGET_IP, $TARGET_PORT, $sid)
Write-Host ''
Write-Host '=== SSH command (tunel) ===' -ForegroundColor Cyan
Write-Host $sshCmd
Write-Host ''

# ---- 4) abrir navegador no APEX (apos pequeno atraso, em background) ----
Start-Job -ArgumentList $APEX_URL -ScriptBlock { param($u); Start-Sleep 3; Start-Process $u } | Out-Null
Write-Host ("Navegador abrira em ~3s: $APEX_URL") -ForegroundColor Green

# ---- 5) iniciar o tunel em 1o plano (segura o terminal; feche para derrubar) ----
Write-Host 'Iniciando tunel SSH (verbose). Feche esta janela/CTRL+C para encerrar o tunel.' -ForegroundColor Yellow
Write-Host ''
& ssh -i "$PRIV_KEY" -v -N -L "$LOCAL_PORT`:$TARGET_IP`:$TARGET_PORT" -p 22 "$sid@host.bastion.sa-saopaulo-1.oci.oraclecloud.com"