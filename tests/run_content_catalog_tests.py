"""Verify dynamic catalog size while preserving the current generated pet records."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
paths = {
    "Config": "src/ReplicatedStorage/SharedSource/Datas/AnimalKingdomConfig.lua",
    "Database": "src/ReplicatedStorage/SharedSource/Datas/PetDatabase.lua",
    "Before": "documentations/production-polish-20260922/before/src/ReplicatedStorage/SharedSource/Datas/PetDatabase.lua",
    "Teleport": "src/ServerScriptService/BiomeTeleport/init.server.lua",
}


def quote(text):
    separator = "===="
    while "]" + separator + "]" in text:
        separator += "="
    return "[" + separator + "[" + text + "]" + separator + "]"


program = "local sources={\n" + "\n".join(
    f"[ {quote(name)} ]={quote((root / path).read_text())}," for name, path in paths.items()
) + "\n}\n" + (root / "tests/ContentCatalog.spec.lua").read_text()
with tempfile.TemporaryDirectory(prefix="ak-content-catalog-") as directory:
    path = Path(directory) / "checks.luau"
    path.write_text(program)
    subprocess.run([args.luau, str(path)], check=True)
