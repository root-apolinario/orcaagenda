# Execute no PowerShell, dentro da pasta do projeto:
# .\scripts\backup-supabase.ps1 -ProjectRef SEU_PROJECT_REF
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[a-z0-9]+$')]
  [string]$ProjectRef
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$out = Join-Path (Get-Location) "backups\orcaagenda_$stamp.sql"
New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null

Write-Host "O Supabase CLI solicitara autenticacao segura se necessario."
npx supabase db dump --project-ref $ProjectRef --file $out
Write-Host "Backup criado em: $out"
