"""Read-only admission snapshot; never starts generation."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from pet_pipeline import preflight, check_hardware, write

hardware = preflight(Path('D:/AnimalKingdom3D'))
try:
    check_hardware(hardware)
    hardware['admission'] = 'pass'
except RuntimeError as error:
    hardware['admission'] = 'blocked'
    hardware['reason'] = str(error)
write(Path(__file__).with_name('preflight.json'), hardware)
print(json.dumps(hardware, indent=2))
