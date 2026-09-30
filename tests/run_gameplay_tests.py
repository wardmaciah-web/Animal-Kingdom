"""Run production gameplay modules in deterministic Luau adapters (no network/storage writes)."""
from pathlib import Path
import subprocess,json,tempfile
root=Path(__file__).resolve().parents[1]
files={}
for base in ['src/ReplicatedStorage/Shared/Gameplay','src/ReplicatedStorage/SharedSource/Datas','src/ServerScriptService/ServerSource/Server','src/ServerScriptService/ServerSource/Utilities']:
 for p in root.joinpath(base).rglob('*.lua'):
  files[str(p.relative_to(root/'src')).removesuffix('.lua').replace('/','.')]=p.read_text()
files['ReplicatedStorage.Shared.EventDefinitions']=(root/'src/ReplicatedStorage/Shared/EventDefinitions.lua').read_text()
def quote(text):
 sep='===='
 while ']'+sep+']' in text:sep+='='
 return '['+sep+'['+text+']'+sep+']'
program='local sources={\n'+'\n'.join('[ '+quote(k)+' ]='+quote(v)+',' for k,v in files.items())+'\n}\n'+(root/'tests/Gameplay.spec.lua').read_text()
with tempfile.TemporaryDirectory(prefix='ak-gameplay-') as d:
 p=Path(d)/'tests.luau';p.write_text(program)
 subprocess.run(['/private/tmp/ak-phase2-luau-build/luau',str(p)],check=True)
