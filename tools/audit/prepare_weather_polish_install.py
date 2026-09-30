"""Package only weather presentation sources for the known live Studio paths."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[2]
rows=[]
for name in ['WeatherVFXQuality','WeatherSoundDefinitions','WeatherAudioController','WeatherCelestialEffects','WeatherEnvironmentEffects','MeteorShowerEffects','SpiritNightEffects']:
    rows.append({'path':['ReplicatedStorage','Shared',name],'class':'ModuleScript','source':(root/'src/ReplicatedStorage/Shared'/f'{name}.lua').read_text()})
rows.append({'path':['StarterPlayer','StarterPlayerScripts','WeatherVisualController'],'class':'LocalScript','source':(root/'src/StarterPlayer/StarterPlayerScripts/WeatherVisualController.client.lua').read_text()})
code='assert(not game:GetService("RunService"):IsRunning(),"Stop Play before installing weather presentation sources")\n'
code+='local rows=game:GetService("HttpService"):JSONDecode([====['+json.dumps(rows)+']====])\n'
code+='''for _, r in ipairs(rows) do
 local parent=game
 for i=1,#r.path-1 do parent=assert(parent:FindFirstChild(r.path[i]),r.path[i]) end
 local target=parent:FindFirstChild(r.path[#r.path])
 if not target then target=Instance.new(r.class);target.Name=r.path[#r.path];target.Parent=parent end
 assert(target.ClassName==r.class)
 target.Source=r.source
 print("[WeatherPolishInstall] "..target:GetFullName().." bytes="..#r.source)
end
'''
(root/'tools/audit/InstallWeatherPolish.lua').write_text(code)
Path('/private/tmp/ak-phase2-command.lua').write_text(code)
print(f'Prepared {len(rows)} presentation sources; authored map and server scripts untouched')
