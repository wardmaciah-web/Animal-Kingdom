"""Run actual Garden layout/travel modules in deterministic, storage-free adapters."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]


def quote(text):
    separator = "===="
    while "]" + separator + "]" in text:
        separator += "="
    return "[" + separator + "[" + text + "]" + separator + "]"


sources = {
    "Runtime": "src/ServerScriptService/ServerSource/Utilities/GardenPlotRuntime.lua",
    "Service": "src/ServerScriptService/ServerSource/Server/GardenExpeditionService.lua",
}
program = "local sources={\n" + "\n".join(
    f"[ {quote(name)} ]={quote((root / path).read_text())}," for name, path in sources.items()
) + "\n}\n" + (root / "tests/GardenPresentation.spec.lua").read_text()
with tempfile.TemporaryDirectory(prefix="ak-garden-presentation-") as directory:
    path = Path(directory) / "checks.luau"
    path.write_text(program)
    subprocess.run([args.luau, str(path)], check=True)
