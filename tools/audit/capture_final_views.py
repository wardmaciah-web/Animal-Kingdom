from pathlib import Path
import subprocess,time
ROOT=Path('/Users/jefferypryor/Documents/SuperbulletAI/Real_Animal_K')
areas=['Meadow','Forest','Jungle','Desert','Snow','Volcano','Ocean','AncientRuins','MagicalForest','Sky','Prehistoric','Mythical','Town','PlayerPlots']
for name in areas:
    if name=='Town': position='workspace.TownPlaza.Position'; offset='Vector3.new(0,300,300)'
    elif name=='PlayerPlots': position='Vector3.new(-338,8,473)';offset='Vector3.new(0,330,330)'
    else:position=f'workspace.{name}.{name}Floor.Position';offset='Vector3.new(0,250,250)'
    code=f"assert(not game:GetService('RunService'):IsRunning());local p={position};local c=workspace.CurrentCamera;c.CameraType=Enum.CameraType.Scriptable;c.CFrame=CFrame.lookAt(p+{offset},p+Vector3.new(0,20,0));c.Focus=CFrame.new(p);print('[FinalVisualSweep] {name}')"
    Path('/private/tmp/ak-phase2-command.lua').write_text(code)
    subprocess.run(['osascript','/private/tmp/ak-phase2-studio.scpt'],check=True,stdout=subprocess.DEVNULL)
    time.sleep(2)
    subprocess.run(['screencapture','-x','-l','14955',str(ROOT/'documentations/full-audit-20260917/final-views'/f'{name}.png')],check=True)
    print('Captured '+name,flush=True)
