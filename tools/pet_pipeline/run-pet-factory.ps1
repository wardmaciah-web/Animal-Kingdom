param(
    [string]$Recipe = 'ocelot',
    [string]$RuntimeRoot = 'D:\AnimalKingdom3D',
    [string]$Output
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'runtime-env.ps1') -RuntimeRoot $RuntimeRoot
$recipePath = Join-Path $PSScriptRoot ('configs\' + $Recipe + '.json')
if (!(Test-Path -LiteralPath $recipePath)) { throw "Missing recipe: $recipePath" }
if (!$Output) { $Output = Join-Path $RuntimeRoot ('outputs\' + $Recipe + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss')) }
& (Join-Path $RuntimeRoot 'tools\deps-stage\Scripts\python.exe') (Join-Path $PSScriptRoot 'pet_pipeline.py') generate --config $recipePath --runtime-root $RuntimeRoot --output $Output
if ($LASTEXITCODE -ne 0) { throw "Pet production failed; preserved evidence: $Output" }
