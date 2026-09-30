"""Prepare guarded EDIT-mode source installation and authored-tree registration."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[2]
base=root/'documentations/tree-egg-loop-20260917'
hashes=json.loads((base/'baseline-hashes.json').read_text());rows=[]
for p in (root/'src').rglob('*.lua'):
 if 'Packages' in p.parts: continue
 rel=str(p.relative_to(root))
 if hashes.get(rel)==hashlib.sha256(p.read_bytes()).hexdigest():continue
 path=list(p.relative_to(root/'src').parts);name=path[-1]
 cls='LocalScript' if name.endswith('.client.lua') else 'Script' if name.endswith('.server.lua') else 'ModuleScript'
 path[-1]=name.replace('.client.lua','').replace('.server.lua','').removesuffix('.lua')
 rows.append({'path':path,'class':cls,'source':p.read_text()})
code='''assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"Studio Edit mode required")
local rows=game.HttpService:JSONDecode([====['''+json.dumps(rows)+''']====])
local sourceCount=#rows
for _,row in ipairs(rows) do
 local parent=game:GetService(row.path[1])
 for i=2,#row.path-1 do local next=parent:FindFirstChild(row.path[i]);if not next then next=Instance.new("Folder");next.Name=row.path[i];next.Parent=parent end;parent=next end
 local name=row.path[#row.path];local object=parent:FindFirstChild(name)
 if not object then object=Instance.new(row.class);object.Name=name;object.Parent=parent end
 assert(object.ClassName==row.class,"Class mismatch: "..object:GetFullName());object.Source=row.source
end
for _,entry in ipairs({{game.ServerScriptService,"AK_GameplayReleaseTest"},{game.StarterPlayer.StarterPlayerScripts,"AK_GameplayClientTest"}}) do
 local object=entry[1]:FindFirstChild(entry[2]);if object and object:GetAttribute("TemporaryAudit")==true then object:Destroy() end
end
workspace:SetAttribute("AK_GameplayTestStage",nil);workspace:SetAttribute("AK_MultiplayerExpected",nil)
local removed=0
for _,object in ipairs(workspace:GetDescendants()) do
 local category=object:GetAttribute("AssetCategory")
 if object:GetAttribute("GameplayGenerated")==true and (category=="Trees" or category=="Resources" or category=="Eggs") then object:Destroy();removed+=1 end
end
local runtime=workspace:FindFirstChild("AKGameplayRuntime");if runtime and #runtime:GetChildren()==0 then runtime:Destroy() end
local Collection=game:GetService("CollectionService")
for _,object in ipairs(Collection:GetTagged("EggStation")) do Collection:RemoveTag(object,"EggStation");for _,child in ipairs(object:GetDescendants()) do if child:IsA("ProximityPrompt") and child.Name=="EggPrompt" then child:Destroy() end end end
local discovery=game.ServerScriptService.ServerSource.Utilities.AuthoredTreeDiscovery:Clone()
discovery.Parent=game.ServerScriptService.ServerSource.Utilities
local entries=require(discovery).Scan();discovery:Destroy()
local rows={};local counts={}
for _,entry in ipairs(entries) do
 local object=entry.Object
 object:SetAttribute("BiomeId",entry.Biome);object:SetAttribute("ResourceType","Tree");object:SetAttribute("RespawnTime",20)
 object:SetAttribute("AuthoredGatherableTree",true);object:SetAttribute("InteractionPosition",entry.InteractionPosition)
 Collection:AddTag(object,"GatherableTree");counts[entry.Biome]=(counts[entry.Biome] or 0)+1
 table.insert(rows,{Path=object:GetFullName(),Class=object.ClassName,Biome=entry.Biome,Root=entry.Root:GetFullName(),Pivot={entry.Pivot:GetComponents()},Interaction={entry.InteractionPosition.X,entry.InteractionPosition.Y,entry.InteractionPosition.Z}})
end
local encoded=game.HttpService:JSONEncode({Trees=rows,Counts=counts,RemovedGenerated=removed})
print("AK_TREE_REGISTER_BEGIN");for i=1,#encoded,500 do print("AK_TREE_REGISTER_CHUNK "..encoded:sub(i,i+499)) end;print("AK_TREE_REGISTER_END")
print("AK_TREE_LOOP_INSTALLED sources="..sourceCount.." registeredTrees="..#entries.." removedGenerated="..removed)
'''
(base/'InstallTreeLoop.studio.lua').write_text(code)
Path('/private/tmp/ak-loop-command.lua').write_text(code)
print('Prepared',len(rows),'source changes and guarded tree registration')
