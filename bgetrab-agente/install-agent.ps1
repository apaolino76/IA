# install-agent.ps1
# Copia o agente oci.json deste repositorio para a pasta de agentes do Kiro CLI
# no perfil do usuario atual. Funciona em qualquer maquina (usa $env:USERPROFILE),
# entao serve tanto em casa quanto no trabalho sem edicao.

$ErrorActionPreference = "Stop"

# Pasta do repositorio (onde este script esta)
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $repoRoot "agents\oci.json"

if (-not (Test-Path $src)) {
    Write-Error "Nao encontrei o modelo do agente em: $src"
    exit 1
}

# Destino: <perfil do usuario>\.kiro\agents
$destDir = Join-Path $env:USERPROFILE ".kiro\agents"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null

$dest = Join-Path $destDir "oci.json"
Copy-Item $src $dest -Force
Write-Host "Agente copiado para: $dest"

# Validacao (nao falha o script se o CLI nao estiver no PATH)
try {
    kiro-cli agent validate --path $dest
    Write-Host "Validacao concluida."
} catch {
    Write-Warning "Nao foi possivel validar automaticamente. Rode manualmente:"
    Write-Warning "  kiro-cli agent validate --path `"$dest`""
}
