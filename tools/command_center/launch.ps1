param([string]$Config = 'D:\AnimalKingdom3D\command-center\config.json')
$ErrorActionPreference = 'Stop'
# DPAPI: only the Windows user who provisioned these files can decrypt them.
$runtime = Split-Path -Parent $Config
foreach ($pair in @(@('github.secret', 'AK_GITHUB_TOKEN'), @('notion.secret', 'AK_NOTION_TOKEN'))) {
    $secretFile = Join-Path $runtime $pair[0]
    if (Test-Path -LiteralPath $secretFile) {
        $secure = Get-Content -LiteralPath $secretFile -Raw | ConvertTo-SecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { [Environment]::SetEnvironmentVariable($pair[1], [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr), 'Process') }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    }
}
try {
    & 'D:\AnimalKingdom3D\tools\python\cpython-3.11.17-windows-x86_64-none\python.exe' (Join-Path $PSScriptRoot 'bridge.py') run --config $Config
    exit $LASTEXITCODE
} finally {
    Remove-Item Env:AK_GITHUB_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:AK_NOTION_TOKEN -ErrorAction SilentlyContinue
}
