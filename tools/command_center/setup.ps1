param(
    [ValidateSet('Prepare', 'Credentials', 'Install', 'Uninstall')][string]$Action = 'Prepare',
    [switch]$ApproveStartup
)
$ErrorActionPreference = 'Stop'
$runtime = 'D:\AnimalKingdom3D\command-center'
$taskName = 'AnimalKingdomCommandCenter'
$python = 'D:\AnimalKingdom3D\tools\python\cpython-3.11.17-windows-x86_64-none\python.exe'
if ($Action -eq 'Prepare') {
    New-Item -ItemType Directory -Path $runtime -Force | Out-Null
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    # Restrict the new dedicated runtime, never any existing shared asset folders.
    & icacls.exe $runtime /inheritance:r /grant:r "${identity}:(OI)(CI)F" 'SYSTEM:(OI)(CI)F' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not restrict runtime permissions' }
    $config = Join-Path $runtime 'config.json'
    if (-not (Test-Path -LiteralPath $config)) { Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'config.example.json') -Destination $config }
    Write-Output 'Prepared. Worker is paused by default. No startup task installed.'
} elseif ($Action -eq 'Credentials') {
    if (-not (Test-Path -LiteralPath (Join-Path $runtime 'config.json'))) { throw 'Run Prepare first' }
    foreach ($service in @('github', 'notion')) {
        $value = Read-Host "Enter $service token (blank keeps existing credential; never paste into chat)" -AsSecureString
        if ($value.Length -gt 0) {
            $value | ConvertFrom-SecureString | Set-Content -LiteralPath (Join-Path $runtime "$service.secret")
            if ($service -eq 'github') {
                $configPath = Join-Path $runtime 'config.json'
                $configuration = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
                $configuration.github_auth = 'environment'
                $configuration | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $configPath -Encoding UTF8
            }
        }
    }
    Write-Output 'Credentials saved encrypted for this Windows user.'
} elseif ($Action -eq 'Install') {
    if (-not $ApproveStartup) { throw 'Explicit opt-in required: -Action Install -ApproveStartup' }
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) { throw 'Existing startup task preserved; inspect it before replacement' }
    $config = Join-Path $runtime 'config.json'
    $configuration = Get-Content -LiteralPath $config -Raw | ConvertFrom-Json
    $githubSecret = Join-Path $runtime 'github.secret'
    if ($configuration.github_auth -ne 'environment' -or -not (Test-Path -LiteralPath $githubSecret)) {
        throw 'Unattended startup requires a separate fine-grained GitHub token restricted to this repository. Provision it through -Action Credentials; the broad existing GCM login was used only for the supervised demonstration.'
    }
    $secure = Get-Content -LiteralPath $githubSecret -Raw | ConvertTo-SecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $env:AK_GITHUB_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        & $python (Join-Path $PSScriptRoot 'bridge.py') doctor --config $config
        if ($LASTEXITCODE -ne 0) { throw 'Authentication preflight failed; startup was not installed' }
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        Remove-Item Env:AK_GITHUB_TOKEN -ErrorAction SilentlyContinue
    }
    $smokeRoot = Join-Path $runtime 'jobs\command-center-smoke'
    $verified = $false
    if (Test-Path -LiteralPath $smokeRoot) {
        foreach ($jobDir in Get-ChildItem -LiteralPath $smokeRoot -Directory) {
            $qaPath = Join-Path $jobDir.FullName 'qa.json'
            if (Test-Path -LiteralPath $qaPath) {
                $qa = Get-Content -LiteralPath $qaPath -Raw | ConvertFrom-Json
                if ($qa.state -in @('review','done') -and $qa.commit -match '^[0-9a-f]{40}$' -and $qa.tests.Count -ge 2 -and -not ($qa.tests | Where-Object { -not $_.passed })) { $verified = $true }
            }
        }
    }
    if (-not $verified) { throw 'Verified smoke-test evidence required; startup was not installed' }
    & $python (Join-Path $PSScriptRoot 'bridge.py') pause --config $config
    if ($LASTEXITCODE -ne 0) { throw 'Could not pause pickup; startup was not installed' }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $launch = Join-Path $PSScriptRoot 'launch.ps1'
    $actionSpec = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -File `"$launch`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $identity
    $principal = New-ScheduledTaskPrincipal -UserId $identity -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -StartWhenAvailable
    Register-ScheduledTask -TaskName $taskName -Action $actionSpec -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
    Write-Output 'Logon startup registered. Start-ScheduledTask starts it now; resume pickup separately after doctor and smoke verification.'
} elseif ($Action -eq 'Uninstall') {
    & $python (Join-Path $PSScriptRoot 'bridge.py') stop --config (Join-Path $runtime 'config.json')
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Output 'Startup removed. Logs, branches, credentials and evidence preserved.'
}
