-- Install as a temporary server Script after the paired test has completed.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer())
task.spawn(function()
 local S=game.ServerScriptService.ServerSource.Server
 local Profiles=require(S.ProfileService);local Resource=require(S.ResourceService)
 local player=game.Players:GetPlayers()[1];local original=assert(Profiles.Profiles[player]);local pivot=player.Character:GetPivot()
 local root=player.Character.HumanoidRootPart;local anchored=root.Anchored;root.Anchored=true
 local function copy(v) if type(v)~="table" then return v end;local t={};for k,x in pairs(v) do t[k]=copy(x) end;return t end
 local data=copy(require(game.ReplicatedStorage.SharedSource.Datas.ProfileTemplate))
 require(game.ReplicatedStorage.Shared.Gameplay.ProfileMigrations).Apply(data,function() return game.HttpService:GenerateGUID(false) end)
 for _,biome in ipairs(require(game.ReplicatedStorage.Shared.Gameplay.Definitions.BiomeDefinitions).Ordered) do data.UnlockedBiomes[biome.Id]=true end
 Profiles.Profiles[player]={Data=data,IsActive=function() return true end,FirstSessionTime=os.time()}
 local checks,failures=0,0
 local function check(ok,message) checks+=1;if not ok then failures+=1 end;print("AK_TREE_MOTION "..(ok and "PASS " or "FAIL ")..message) end
 local ok,issue=pcall(function()
  for _,kind in ipairs({"Model","MeshPart"}) do
   local target,record
   for object,r in pairs(Resource:GetRecords()) do if object.ClassName==kind and r.State=="AVAILABLE" then target=object;record=r;break end end
   assert(target,"Missing authored "..kind)
   data.PetStorageCapacity=50;player.Character:PivotTo(CFrame.new(record.InteractionPosition+Vector3.new(0,1,4)))
   local originalPivot=target:GetPivot()
   check(Resource:Gather(player,target),kind.." interaction accepted")
   task.wait(.35);check(target:GetPivot()~=originalPivot and record.State=="SHAKING",kind.." actual original asset visibly rotates during shake")
   data.PetStorageCapacity=0 -- no award; exercise final capacity recheck on this exact instance
   task.wait(1.1)
   check(record.State=="AVAILABLE" and target:GetPivot()==originalPivot and target:GetAttribute("RespawnAt")==nil and #data.Pets==0,kind.." cancelled hatch restores exact tree without consuming cooldown")
  end
 end)
 if not ok then check(false,tostring(issue)) end
 Profiles.Profiles[player]=original;Profiles.Client.GetData:Fire(player,original.Data);require(S.PetService):Publish(player)
 if player.Character then player.Character:PivotTo(pivot);root.Anchored=anchored end
 print("AK_TREE_MOTION_DONE assertions="..checks.." failures="..failures.." savedProfileUnchanged=true")
end)
