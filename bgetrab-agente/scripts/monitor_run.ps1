<#
.SYNOPSIS
    Monitor de uma task-run do OCI Data Integration (projeto BGETRAB).
.DESCRIPTION
    Consulta "oci data-integration task-run get" periodicamente e grava o progresso
    em log, encerrando ao atingir um estado terminal (SUCCESS/ERROR/TERMINATED/TERMINATING).
.EXAMPLE
    .\scripts\monitor_run.ps1 -AppKey <app-key> -RunKey <run-key> -Ano 2002
.EXAMPLE
    .\scripts\monitor_run.ps1 -AppKey <app> -RunKey <run> -IntervaloSeg 300 -LogPath C:\tmp\run.log
.NOTES
    Autenticacao: sessao por token (perfil bgetrab-session). Ver regra do projeto.
#>
[CmdletBinding()]
param(
    # Chave da aplicacao do Data Integration que contem a task-run.
    [Parameter(Mandatory = $true)]
    [string] $AppKey,

    # Chave da task-run a monitorar.
    [Parameter(Mandatory = $true)]
    [string] $RunKey,

    # OCID do workspace do Data Integration (default: workspace BGETRAB).
    [string] $WorkspaceId = "ocid1.disworkspace.oc1.sa-saopaulo-1.antxeljr2ow634yalmswakvw2phbbfl2wbyy7nsonk67nrdbzc5sdxtqlljq",

    # Ano da carga (usado apenas para nomear o log quando -LogPath nao e informado).
    [string] $Ano,

    # Intervalo entre consultas, em segundos (default: 600 = 10 min).
    [int] $IntervaloSeg = 600,

    # Caminho do arquivo de log. Default: <raiz-do-repo>\analises\_monitor_<ano|run>.log
    [string] $LogPath,

    # Perfil e metodo de autenticacao do OCI CLI.
    [string] $Profile = "bgetrab-session",
    [string] $AuthMethod = "security_token"
)

$ErrorActionPreference = "Stop"

# Resolve a raiz do repo a partir da localizacao deste script (scripts\ -> raiz).
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Define o caminho do log se nao informado: analises\_monitor_<ano|run>.log (pasta ignorada no git).
if (-not $LogPath) {
    $sufixo = if ($Ano) { $Ano } else { $RunKey.Substring(0, [Math]::Min(8, $RunKey.Length)) }
    $analisesDir = Join-Path $repoRoot "analises"
    if (-not (Test-Path $analisesDir)) { New-Item -ItemType Directory -Force -Path $analisesDir | Out-Null }
    $LogPath = Join-Path $analisesDir ("_monitor_{0}.log" -f $sufixo)
}

$terminais = @("SUCCESS", "ERROR", "TERMINATED", "TERMINATING")

Write-Host "Monitorando task-run $RunKey a cada $IntervaloSeg s. Log: $LogPath"
while ($true) {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    try {
        $raw = oci data-integration task-run get `
            --workspace-id $WorkspaceId --application-key $AppKey --task-run-key $RunKey `
            --profile $Profile --auth $AuthMethod 2>&1
        $o = ($raw -join "`n") | ConvertFrom-Json
        $status  = $o.data.status
        $records = $o.data.'records-written'
        $bytes   = $o.data.'bytes-processed'
        $err     = $o.data.'error-message'
        $linha = "$ts  STATUS=$status  RECORDS=$records  BYTES=$bytes  ERROR=$err"
    } catch {
        $linha = "$ts  ERRO_AO_CONSULTAR: $($_.Exception.Message)"
        $status = $null
    }
    Add-Content -Path $LogPath -Value $linha
    Write-Host $linha
    if ($status -and ($terminais -contains $status)) {
        Add-Content -Path $LogPath -Value "$ts  >> ESTADO TERMINAL ($status). Encerrando monitor."
        Write-Host "Estado terminal: $status. Encerrando."
        break
    }
    Start-Sleep -Seconds $IntervaloSeg
}
