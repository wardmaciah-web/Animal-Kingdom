"""Run the production Garden client scheduler in deterministic local adapters."""
import argparse
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = (root / "src/StarterPlayer/StarterPlayerScripts/GardenPlotVisuals.client.lua").read_text()
separator = "===="
while "]" + separator + "]" in source:
    separator += "="
program = "local sourceCode=[" + separator + "[" + source + "]" + separator + "]\n"
program += (root / "tests/GardenVisualScheduler.spec.lua").read_text()
with tempfile.TemporaryDirectory(prefix="ak-garden-visuals-") as directory:
    path = Path(directory) / "checks.luau"
    path.write_text(program)
    subprocess.run([args.luau, str(path)], check=True)
