"""Run the actual admin policy/weather modules with controlled service/time adapters."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
sources = {
    "RequestPolicy": "src/ServerScriptService/AdminCommandCenter/RequestPolicy.lua",
    "ActivityLog": "src/ServerScriptService/AdminCommandCenter/ActivityLog.lua",
    "PlotStatus": "src/ServerScriptService/AdminCommandCenter/PlotStatus.lua",
    "WeatherEventService": "src/ServerScriptService/ServerSource/Server/WeatherEventService.lua",
    "Tests": "tests/AdminCommandCenter.spec.lua",
    "AdminCommandService": "src/ServerScriptService/ServerSource/Server/AdminCommandService.lua",
    "ServiceTests": "tests/AdminCommandService.spec.lua",
    "AdminSpectate": "src/StarterPlayer/StarterPlayerScripts/AdminSpectate.lua",
    "SpectateTests": "tests/AdminSpectate.spec.lua",
}

def quote(text):
    separator = "===="
    while "]" + separator + "]" in text:
        separator += "="
    return "[" + separator + "[" + text + "]" + separator + "]"

program = "local sources = {\n" + "\n".join(
    f"[ {quote(name)} ] = {quote((root / path).read_text())}," for name, path in sources.items()
) + "\n}\n" + """
local base = getfenv()
local function loadSource(name, overrides)
    local env = setmetatable(overrides or {}, {__index=base})
    local fn = assert(loadstring(assert(sources[name]), name))
    setfenv(fn, env)
    return fn()
end
loadSource("Tests")(loadSource)
loadSource("ServiceTests")(loadSource)
loadSource("SpectateTests")(loadSource)
"""
with tempfile.TemporaryDirectory(prefix="ak-admin-tests-") as directory:
    path = Path(directory) / "tests.luau"
    path.write_text(program)
    subprocess.run([args.luau, str(path)], check=True)
