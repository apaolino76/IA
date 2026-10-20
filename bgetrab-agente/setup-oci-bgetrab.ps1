# setup-oci-bgetrab.ps1
# Configura o bundle de CA (resolve intercepcao TLS do Kaspersky) e as variaveis
# de ambiente para operar o OCI CLI no projeto BGETRAB.
#
# NAO manipula credenciais (chave privada, passphrase, tokens).
# Executar em PowerShell:
#   powershell -ExecutionPolicy Bypass -File .\setup-oci-bgetrab.ps1
# Depois, abra uma JANELA NOVA do terminal.

$ErrorActionPreference = "Stop"
Write-Host "== Setup OCI BGETRAB ==" -ForegroundColor Cyan

$ociDir = Join-Path $HOME ".oci"
if (-not (Test-Path $ociDir)) { New-Item -ItemType Directory -Path $ociDir -Force | Out-Null }

# 1) Descobrir o certifi usado pelo OCI CLI (Python)
Write-Host "1) Localizando o cacert.pem do OCI CLI..."
$ociCmd = Get-Command oci -ErrorAction SilentlyContinue
if (-not $ociCmd) { Write-Host "   OCI CLI nao encontrado no PATH. Instale o OCI CLI antes." -ForegroundColor Red; exit 1 }

$certifi = $null
# Procurar certifi perto do executavel do oci
$base = Split-Path (Split-Path $ociCmd.Source -Parent) -Parent
$cand = Get-ChildItem -Path $base -Filter "cacert.pem" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match "certifi" -and $_.FullName -notmatch "pip" } |
        Select-Object -First 1
if ($cand) { $certifi = $cand.FullName }
if (-not $certifi) {
  # fallback: busca ampla em Python do usuario
  $cand = Get-ChildItem -Path "$HOME\AppData\Local\Programs\Python" -Filter "cacert.pem" -Recurse -ErrorAction SilentlyContinue |
          Where-Object { $_.FullName -match "certifi" -and $_.FullName -notmatch "pip" } |
          Select-Object -First 1
  if ($cand) { $certifi = $cand.FullName }
}
if (-not $certifi) { Write-Host "   Nao encontrei o cacert.pem do certifi. Verifique a instalacao do OCI CLI." -ForegroundColor Red; exit 1 }
Write-Host "   certifi: $certifi" -ForegroundColor Green

# 2) Procurar a CA do Kaspersky nas stores do Windows
Write-Host "2) Procurando CA do Kaspersky nas stores de certificados..."
$kcert = $null
foreach ($store in @("Cert:\CurrentUser\Root","Cert:\LocalMachine\Root")) {
  $c = Get-ChildItem $store -ErrorAction SilentlyContinue | Where-Object { $_.Subject -match "Kaspersky" } | Select-Object -First 1
  if ($c) { $kcert = $c; break }
}

$bundle = Join-Path $ociDir "oci-ca-bundle.pem"

if ($kcert) {
  Write-Host "   CA Kaspersky encontrada (thumbprint $($kcert.Thumbprint))." -ForegroundColor Green
  $kpem = Join-Path $ociDir "kaspersky-ca.pem"
  $bytes = $kcert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
  $b64 = [System.Convert]::ToBase64String($bytes, [System.Base64FormattingOptions]::InsertLineBreaks)
  $pem = "-----BEGIN CERTIFICATE-----`r`n$b64`r`n-----END CERTIFICATE-----`r`n"
  Set-Content -Path $kpem -Value $pem -Encoding ascii
  # 3) Montar bundle combinado
  $combinado = (Get-Content $certifi -Raw) + "`r`n# ---- CA Kaspersky (SSL inspection) ----`r`n" + (Get-Content $kpem -Raw)
  Set-Content -Path $bundle -Value $combinado -Encoding ascii
  Write-Host "3) Bundle combinado criado: $bundle" -ForegroundColor Green
} else {
  Write-Host "   Nenhuma CA Kaspersky encontrada. Usando o certifi padrao como bundle." -ForegroundColor Yellow
  Copy-Item $certifi $bundle -Force
}

# 4) Persistir variaveis de ambiente (usuario)
Write-Host "4) Persistindo variaveis de ambiente (setx)..."
setx OCI_CLI_CA_BUNDLE  "$bundle"  | Out-Null
setx REQUESTS_CA_BUNDLE "$bundle"  | Out-Null
setx SSL_CERT_FILE      "$bundle"  | Out-Null
setx OCI_CLI_AUTH       "security_token" | Out-Null
setx OCI_CLI_PROFILE    "bgetrab-session" | Out-Null

Write-Host ""
Write-Host "Concluido." -ForegroundColor Cyan
Write-Host "Bundle: $bundle"
Write-Host "Proximos passos:"
Write-Host "  1) Abra uma JANELA NOVA do terminal."
Write-Host "  2) oci session authenticate --region sa-saopaulo-1   (perfil: bgetrab-session)"
Write-Host "  3) oci os ns get   (esperado: grmu0oy5wsd9)"
