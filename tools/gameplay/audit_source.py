"""Read-only release checks against the generated Rojo hierarchy."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parents[2]
out=root/'documentations/gameplay-20-systems-20260917'
mapdata=json.loads((out/'AnimalKingdom-gameplay.sourcemap.json').read_text())
nodes={};files={}
def walk(item,path=()):
 current=() if item['className']=='DataModel' else path+(item['name'],)
 nodes[current]=item
 for f in item.get('filePaths',[]):
  if f.endswith('.lua'):files[f]=current
 for child in item.get('children',[]):walk(child,current)
walk(mapdata)
missing=[];edges={};checked=0;services=set();lookups=[]
for filename,path in files.items():
 if '/Packages/' in filename or '/Externals/' in filename:continue
 source=(root/filename).read_text();edges[path]=[]
 if filename.startswith('src/ServerScriptService/ServerSource/Server/'):
  services.update(re.findall(r'Name\s*=\s*"(\w+Service)"',source));lookups.extend(re.findall(r'Knit.GetService\("(\w+)"\)',source))
 for expression in re.findall(r'require\(([\w]+(?:\.[\w]+)+)\)',source):
  parts=expression.split('.')
  if parts[0]=='script':resolved=list(path)
  elif parts[0] in ['RS','ReplicatedStorage']:resolved=['ReplicatedStorage']
  elif parts[0] in ['SSS','ServerScriptService']:resolved=['ServerScriptService']
  else:continue
  for part in parts[1:]:
   if part=='Parent':resolved=resolved[:-1]
   else:resolved.append(part)
  key=tuple(resolved);checked+=1
  if key not in nodes:missing.append({'file':filename,'require':expression,'resolved':'.'.join(resolved)})
  else:edges[path].append(key)
assert not missing,missing
unknown=sorted(set(lookups)-services);assert not unknown,unknown
visited=set();active=set()
def dfs(path):
 if path in active:raise AssertionError('Cyclic require: '+'.'.join(path))
 if path in visited:return
 active.add(path)
 for child in edges.get(path,[]):dfs(child)
 active.remove(path);visited.add(path)
for path in edges:dfs(path)
baseline=json.loads((out/'baseline-hashes.json').read_text())
protected=['default.project.json','src/ServerScriptService/ServerSource/Server/WeatherAdminService.lua','src/ServerScriptService/ServerSource/Server/WeatherEventService.lua','src/ReplicatedStorage/Shared/AdminCameraDefinitions.lua','src/StarterPlayer/StarterPlayerScripts/AdminCameraController.client.lua','src/StarterPlayer/StarterPlayerScripts/WeatherVisualController.client.lua','src/StarterPlayer/StarterPlayerScripts/AnimalKingdomAnnouncements.client.lua','src/ServerScriptService/AK_PlotAssignment.server.lua']
for f in protected:assert hashlib.sha256((root/f).read_bytes()).hexdigest()==baseline[f],'Unexpected protected edit: '+f
summary={'literal_requires_checked':checked,'missing_requires':missing,'cyclic_requires':False,'registered_services':len(services),'service_lookups':len(lookups),'missing_services':unknown,'protected_files_unchanged':protected}
(out/'source-audit.json').write_text(json.dumps(summary,indent=2)+'\n')
print(f'PASS source audit: {checked} literal requires; {len(services)} services; no missing service, missing static require, or static require cycle; {len(protected)} protected sources unchanged')
