"""Build mapped source, sourcemap and compile all first-party Luau after each phase."""
from pathlib import Path
import subprocess,sys,json,time
root=Path(__file__).resolve().parents[2]
out=root/'documentations/gameplay-20-systems-20260917';out.mkdir(exist_ok=True)
phase=sys.argv[1]
commands=[['rojo','build','default.project.json','-o',str(out/'AnimalKingdom-gameplay-source.rbxlx')],['rojo','sourcemap','default.project.json','-o',str(out/'AnimalKingdom-gameplay.sourcemap.json')]]
compiler=Path('/private/tmp/ak-phase2-luau-build/luau-compile')
results=[]
for command in commands:
 p=subprocess.run(command,cwd=root,text=True,capture_output=True);results.append({'command':command,'exit':p.returncode,'output':p.stdout+p.stderr})
 if p.returncode: print(p.stdout+p.stderr);sys.exit(p.returncode)
files=[p for p in (root/'src').rglob('*.lua') if 'Packages' not in p.parts]
for p in files:
 r=subprocess.run([str(compiler),str(p)],capture_output=True,text=True,errors="replace")
 if r.returncode: print(str(p),r.stderr);sys.exit(r.returncode)
record={'phase':phase,'at':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'results':results,'compiled':len(files)}
with (out/'phase-validation.jsonl').open('a') as f:f.write(json.dumps(record)+'\n')
print(f'PASS phase {phase}: Rojo build, sourcemap, {len(files)} native Luau compilations')
