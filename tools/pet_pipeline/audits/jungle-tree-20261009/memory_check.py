"""Snapshot admission only; all AI work remains in the supervised runners."""
from pathlib import Path
import sys,json
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from pet_pipeline import preflight,check_hardware,write
h=preflight(Path('D:/AnimalKingdom3D'))
try:
    check_hardware(h)
    h['admission']='pass'
except RuntimeError as e:
    h['admission']='blocked';h['reason']=str(e)
write(Path(__file__).with_name(sys.argv[1] if len(sys.argv)>1 else 'memory-after-optimization.json'),h)
print(json.dumps(h,indent=2))
