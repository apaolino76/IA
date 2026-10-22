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

# 2) Procurar CAs de inspecao TLS nas stores do Windows
#    Alem do Kaspersky (antivirus), ambientes corporativos usam proxies de
#    inspecao TLS como Zscaler. Cada um reassina o certificado do servidor com
#    a SUA CA. O curl do Windows valida pela store do SO, mas o Python do OCI
#    CLI valida SOMENTE pelo arquivo PEM - por isso TODAS as CAs de inspecao
#    precisam estar no bundle. Faltando alguma, apenas certos endpoints
#    (ex.: database.<regiao>.oraclecloud.com) falham com CERTIFICATE_VERIFY_FAILED.
Write-Host "2) Procurando CAs de inspecao TLS (Kaspersky, Zscaler, etc.)..."

# Padroes de emissores de inspecao TLS conhecidos. Acrescente outros se necessario.
$inspectionPatterns = @("Kaspersky","Zscaler","Fortinet","Fortigate","Netskope","Palo Alto","BlueCoat","Symantec Web","Cisco Umbrella","Forcepoint","McAfee Web","Sophos")
$regex = ($inspectionPatterns | ForEach-Object { [regex]::Escape($_) }) -join "|"

$stores = @("Cert:\CurrentUser\Root","Cert:\LocalMachine\Root","Cert:\CurrentUser\CA","Cert:\LocalMachine\CA")
$found = @{}  # chave = thumbprint (dedup entre stores)
foreach ($store in $stores) {
  Get-ChildItem $store -ErrorAction SilentlyContinue |
    Where-Object { $_.Subject -match $regex -or $_.Issuer -match $regex } |
    ForEach-Object {
      if (-not $found.ContainsKey($_.Thumbprint)) { $found[$_.Thumbprint] = $_ }
    }
}

$bundle = Join-Path $ociDir "oci-ca-bundle.pem"

# 3) Montar bundle combinado: certifi + todas as CAs de inspecao encontradas
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append((Get-Content $certifi -Raw))

if ($found.Count -gt 0) {
  foreach ($cert in $found.Values) {
    $cn = ($cert.Subject -split ',')[0]
    Write-Host "   CA de inspecao encontrada: $cn (thumbprint $($cert.Thumbprint))" -ForegroundColor Green
    $bytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    $b64   = [System.Convert]::ToBase64String($bytes, [System.Base64FormattingOptions]::InsertLineBreaks)
    [void]$sb.Append("`r`n# ---- CA de inspecao TLS: $cn ----`r`n")
    [void]$sb.Append("-----BEGIN CERTIFICATE-----`r`n$b64`r`n-----END CERTIFICATE-----`r`n")
  }
  Set-Content -Path $bundle -Value $sb.ToString() -Encoding ascii
  Write-Host "3) Bundle combinado criado: $bundle ($($found.Count) CA(s) de inspecao + certifi)" -ForegroundColor Green
} else {
  Write-Host "   Nenhuma CA de inspecao TLS encontrada. Usando o certifi padrao como bundle." -ForegroundColor Yellow
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
