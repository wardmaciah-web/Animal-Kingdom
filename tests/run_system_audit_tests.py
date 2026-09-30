"""Execute the actual plot lookup/profile lifecycle modules with Luau adapters."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
sources = {
    "PlotLocator": "src/ServerScriptService/PlotLocator.lua",
    "ProfileService": "src/ServerScriptService/ServerSource/Server/ProfileService.lua",
    "Tests": "tests/SystemAudit.spec.lua",
    "ProfileMigrations": "src/ReplicatedStorage/Shared/Gameplay/ProfileMigrations.lua",
}


def quote(text):
    separator = "===="
    while "]" + separator + "]" in text:
        separator += "="
    return "[" + separator + "[" + text + "]" + separator + "]"


program = "local sources = {\n" + "\n".join(
    f"[ {quote(name)} ] = {quote((root / path).read_text())},"
    for name, path in sources.items()
) + "\n}\n" + """
local base = getfenv()
local function loadSource(name, overrides)
    local env = setmetatable(overrides or {}, {__index=base})
    local fn = assert(loadstring(assert(sources[name]), name))
    setfenv(fn, env)
    return fn()
end
loadSource("Tests")(loadSource)
"""
with tempfile.TemporaryDirectory(prefix="ak-system-audit-") as directory:
    path = Path(directory) / "tests.luau"
    path.write_text(program)
    subprocess.run([args.luau, str(path)], check=True)
