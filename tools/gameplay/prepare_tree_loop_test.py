from pathlib import Path
import json,sys
root=Path(__file__).resolve().parents[2]
rows=[{'path':['ServerScriptService'],'name':'AKTreeLoopServerTest','class':'Script','source':(root/'tests/TreeEggLoop.studio.server.lua').read_text()},{'path':['StarterPlayer','StarterPlayerScripts'],'name':'AKTreeLoopClientTest','class':'LocalScript','source':(root/'tests/TreeEggLoop.studio.client.lua').read_text()}]
motion=(root/'tests/TreeShakeMotion.studio.server.lua').read_text()
motion='local h=game.ReplicatedStorage:WaitForChild("AKTreeLoopHarness",360);if h then repeat task.wait(.1) until h:GetAttribute("Stage")=="Complete" end;\n'+motion
rows.append({'path':['ServerScriptService'],'name':'AKTreeMotionTemporary','class':'Script','source':motion})
remove='--remove' in sys.argv
code='assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"Edit mode required")\nlocal rows=game.HttpService:JSONDecode([====['+json.dumps(rows)+']====])\n'
code+='for _,row in ipairs(rows) do local parent=game:GetService(row.path[1]);if row.path[2] then parent=parent[row.path[2]] end;local old=parent:FindFirstChild(row.name);if old then assert(old:GetAttribute("TemporaryAudit"),"Unexpected test ownership");old:Destroy() end;'
if not remove:code+='local s=Instance.new(row.class);s.Name=row.name;s.Source=row.source;s:SetAttribute("TemporaryAudit",true);s.Parent=parent;'
code+='end\nworkspace:SetAttribute("AKTreeLoopExpected",'+('nil' if remove else '4' if '--four' in sys.argv else '2' if '--multi' in sys.argv else '1')+');print("AK_TREE_TESTS_'+('REMOVED' if remove else 'INSTALLED')+'")'
Path('/private/tmp/ak-loop-command.lua').write_text(code)
print('Prepared removal' if remove else 'Prepared tree-loop test install')
