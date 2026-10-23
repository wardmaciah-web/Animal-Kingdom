param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [string]$Workspace = 'E:\AnimalKingdom\Agents\Worktrees\Coding'
)
$ErrorActionPreference = 'Stop'
$runtime = Join-Path $Workspace '.tools\omniroute-recovery'
$lock = Get-Content -Raw -LiteralPath (Join-Path $runtime 'runtime-lock.json') | ConvertFrom-Json
$profile = Join-Path $env:USERPROFILE '.codex\ak-free.config.toml'
if ((Get-FileHash -LiteralPath $profile).Hash.ToLowerInvariant() -ne $lock.profile_sha256) {
    throw 'Reviewed free-only profile changed; verify it before another request.'
}
if ((Get-FileHash -LiteralPath (Join-Path $runtime 'payload-rules.json')).Hash.ToLowerInvariant() -ne $lock.rules_sha256) {
    throw 'Reviewed zero-cost payload rules changed.'
}
$process = Get-CimInstance Win32_Process -Filter ('ProcessId = ' + $lock.pid)
if (-not $process -or $process.ExecutablePath -ne $lock.executable -or $process.CommandLine -ne $lock.command_line -or $process.CreationDate.ToUniversalTime().ToString('o') -ne $lock.created_utc) {
    throw 'Verified router process is no longer running. No model request sent.'
}
$listener = Get-NetTCPConnection -State Listen -LocalPort 20129 -ErrorAction Stop
if (@($listener).Count -ne 1 -or $listener.LocalAddress -ne '127.0.0.1' -or $listener.OwningProcess -ne $lock.pid) {
    throw 'Router listener identity changed. No model request sent.'
}
$oldKey = $env:AK_FREE_ROUTER_KEY
try {
    $env:AK_FREE_ROUTER_KEY = Get-Content -Raw -LiteralPath (Join-Path $runtime 'runtime\client-key')
    # Keep the explicit provider override: ignoring base user configuration also
    # skipped profiles on the installed CLI. Never silently use the default model.
    $reviewPrompt = $Prompt + "`nSupervised review only. Do not invoke tools, edit files, or start workers."
    $reviewPrompt | & codex.cmd exec --profile ak-free --ephemeral --cd $Workspace `
        -c model_provider=ak_free -c model=openrouter/cohere/north-mini-code:free `
        -
    $reviewExitCode = $LASTEXITCODE
} finally {
    $env:AK_FREE_ROUTER_KEY = $oldKey
}
exit $reviewExitCode
