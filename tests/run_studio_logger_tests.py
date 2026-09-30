"""Execute the actual Studio loggers against a deterministic failing transport."""
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
    "Server": "src/ServerScriptService/SuperbulletServerLogger/init.server.lua",
    "Client": "src/StarterPlayer/StarterPlayerScripts/SuperbulletClientLogger/init.client.lua",
}
program = "local sources={\n" + "\n".join(
    f"[ {quote(name)} ]={quote((root / path).read_text())}," for name, path in sources.items()
) + "\n}\n" + (root / "tests/StudioLogger.spec.lua").read_text()
with tempfile.TemporaryDirectory(prefix="ak-studio-logger-") as directory:
    path = Path(directory) / "checks.luau"
    path.write_text(program)
    subprocess.run([args.luau, str(path)], check=True)
