param([string]$RuntimeRoot = 'D:\AnimalKingdom3D')
$ErrorActionPreference = 'Stop'
$runtimePath = (Resolve-Path -LiteralPath $RuntimeRoot).Path
$env:AK_3D_ROOT = $runtimePath
$locations = @{
    TEMP='scratch\session-temp'; TMP='scratch\session-temp'; HF_HOME='cache\huggingface';
    HF_HUB_CACHE='cache\huggingface\hub'; HUGGINGFACE_HUB_CACHE='cache\huggingface\hub';
    TORCH_HOME='cache\torch'; TORCH_EXTENSIONS_DIR='cache\torch-extensions';
    U2NET_HOME='cache\u2net'; UV_CACHE_DIR='cache\uv'; PIP_CACHE_DIR='cache\pip';
    XDG_CACHE_HOME='cache'; NUMBA_CACHE_DIR='cache\numba'; CUDA_CACHE_PATH='cache\cuda';
    MPLCONFIGDIR='cache\matplotlib'; BLENDER_USER_CONFIG='cache\blender\config';
    BLENDER_USER_SCRIPTS='cache\blender\scripts'; BLENDER_USER_DATAFILES='cache\blender\datafiles'
}
foreach ($key in $locations.Keys) {
    $path = Join-Path $runtimePath $locations[$key]
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    [Environment]::SetEnvironmentVariable($key, $path, 'Process')
}
$env:PYTHONUNBUFFERED='1'
$env:PYTHONDONTWRITEBYTECODE='1'
$env:PYTHONNOUSERSITE='1'
$env:CUDA_MODULE_LOADING='LAZY'
$env:HF_HUB_DISABLE_SYMLINKS_WARNING='1'
$env:HF_HUB_OFFLINE='1'
$env:TRANSFORMERS_OFFLINE='1'
