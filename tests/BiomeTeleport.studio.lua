local server=game.ServerScriptService.BiomeTeleport
local Landing=require(server.Landing)
local names=require(server.Destinations)
local markers=workspace.BiomeTeleportPoints
local meadow=markers.Meadow.CFrame
Landing.EnsureMarkers(names)
local dummy=Instance.new("Model") dummy.Name="BiomeTeleportVerification"
local root=Instance.new("Part") root.Name="HumanoidRootPart" root.Size=Vector3.new(2,2,1) root.Parent=dummy
local hum=Instance.new("Humanoid") hum.HipHeight=2 hum.Parent=dummy dummy.PrimaryPart=root dummy.Parent=workspace
local player={Character=dummy} local owned={} for _,id in pairs(names) do owned[id]=true end
local profiles={Profiles={[player]={Data={UnlockedBiomes=owned}}}} local tick=1 local replies={}
local handle,forget=require(server.RequestHandler).new(profiles,markers,Landing,names,function(_,name,ok) table.insert(replies,{name,ok}) end,function() return tick end)
local ok,err=pcall(function()
 local count=0
 for name,id in pairs(names) do
  local marker=markers[name] local floor=assert(Landing.FindFloor(id))
  assert(marker:IsA("Part") and marker.Anchored and not marker.CanCollide and not marker.CanTouch and not marker.CanQuery and marker.Transparency==1,name.." marker settings")
  local duplicates=0 for _,v in ipairs(markers:GetChildren()) do if v.Name==name then duplicates+=1 end end assert(duplicates==1,name.." duplicate")
  tick+=1 handle(player,name) assert(replies[#replies][2],"Move failed: "..name)
  local target=marker.Position assert((Vector3.new(root.Position.X,target.Y,root.Position.Z)-target).Magnitude<.01 and root.Position.Y-target.Y>=3,"Bad landing")
  assert(hum.Health>0 and not root.Anchored,"Movement disabled")
  print("AK_FINISH_PASS",name,root.Position)
  tick+=1 local before=root.CFrame owned[id]=nil handle(player,name) assert(root.CFrame==before and replies[#replies][2]==false,"Locked biome moved: "..name) owned[id]=true
  count+=1
 end
 assert(count==12 and #markers:GetChildren()==12 and meadow==markers.Meadow.CFrame)
 tick+=1 local n=#replies handle(player,{}) handle(player,"INVALID") handle(player,"ME") handle(player,"Meadow",CFrame.new()) assert(#replies==n,"Invalid request accepted")
 handle(player,"Meadow") n=#replies handle(player,"Jungle") assert(#replies==n,"Debounce failed")
 tick+=1 player.Character=nil handle(player,"Meadow") assert(replies[#replies][2]==false,"Missing character accepted") player.Character=dummy
 tick+=1 root.Name="MissingRoot" handle(player,"Meadow") assert(replies[#replies][2]==false,"Missing root accepted") root.Name="HumanoidRootPart"
 tick+=1 profiles.Profiles[player]=nil handle(player,"Meadow") assert(replies[#replies][2]==false,"Missing profile accepted")
 forget(player)
 print("AK_FINISH_SECURITY_PASS", "12 locked checks; invalid names/types/positions; debounce; missing character/root/profile")
end)
dummy:Destroy() assert(ok,err)
local main=game.StarterGui.AnimalKingdomUI.Main.Source
assert(main:find('teleportRemote:FireServer(biome.Name)',1,true))
assert(main:find('profiles.UpdateSpecificData',1,true) and main:find('profiles.GetData:Fire()',1,true))
print("AK_FINISH_TESTS_PASS")

-- Exercise the actual client ownership/button callbacks without writing player saves.
local binding = main:match('(\t\trefreshOwnership%[biome.Id%].-)\n\tend\n\tlocal function applyOwnership')
local sync = main:match('(\tlocal function applyOwnership.-)\nend\n\n%-%- TRADE')
assert(binding and sync, "Client binding not found")
sync = sync:gsub('\tlocal Knit = require[^\n]+\n', '')
local testModule=Instance.new("ModuleScript")
testModule.Name="BiomeTeleportClientVerification"
testModule.Source=[==[
return function(bindingNames)
 local function signal()
  local listeners={}
  return {Connect=function(_,fn) table.insert(listeners,fn) end,Fire=function(_,...) for _,fn in ipairs(listeners) do fn(...) end end}
 end
 local function connect(s,fn) s:Connect(fn) end
 local profiles={GetData=signal(),UpdateSpecificData=signal()}
 local requested=false local request=profiles.GetData.Fire
 profiles.GetData.Fire=function() requested=true end
 local Knit={GetService=function() return profiles end,OnStart=function() return {andThen=function(_,fn) fn() return {catch=function() end} end} end}
 local screen={Parent=true} local T={Green=1,Red=2,Blue=3,Yellow=4}
 local refreshOwnership={} local buttons={} local records={} local sent={} local unlocks={}
 local currencyKeys={ForestCoins="Coins",FriendshipTokens="Friendship Tokens"}
 local balances={}
 local function applyCurrency(key,value) if currencyKeys[key] then balances[key]=value end end
 local teleportRemote={FireServer=function(_,name) table.insert(sent,name) end}
 local Bridge={Request=function(_,payload) table.insert(unlocks,payload.BiomeId) end}
 local formatNumber=tostring
 for name,id in pairs(bindingNames) do
  local biome={Id=id,Name=name,Price=123,Unlocked=false}
  local status={} local action={Activated=signal()}
  buttons[id]=action records[id]={biome=biome,status=status}
]==]..binding..[==[
 end
]==]..sync..[==[
 assert(requested,"Missing initial snapshot request")
 local owned={} for _,id in pairs(bindingNames) do owned[id]=true end
 request(profiles.GetData,{UnlockedBiomes=owned,ForestCoins=2500,FriendshipTokens=7})
 assert(balances.ForestCoins==2500 and balances.FriendshipTokens==7,"Currency snapshot missing")
 profiles.UpdateSpecificData:Fire({"ForestCoins"},1250)
 assert(balances.ForestCoins==1250 and balances.FriendshipTokens==7,"Currency update drift")
 for name,id in pairs(bindingNames) do
  assert(buttons[id].Text=="TELEPORT" and records[id].status.Text=="UNLOCKED",name.." snapshot")
  buttons[id].Activated:Fire() assert(sent[#sent]==name,name.." incorrect remote name")
  profiles.UpdateSpecificData:Fire({"UnlockedBiomes",id},false)
  local n=#sent buttons[id].Activated:Fire() assert(#sent==n and unlocks[#unlocks]==id,name.." locked callback")
  profiles.UpdateSpecificData:Fire({"UnlockedBiomes",id},true)
  buttons[id].Activated:Fire() assert(sent[#sent]==name,name.." unlock update")
  print("AK_FINISH_BUTTON_PASS",name)
 end
 profiles.UpdateSpecificData:Fire({"UnlockedBiomes"},{Meadow=true})
 for _,id in pairs(bindingNames) do assert(records[id].biome.Unlocked==(id=="Meadow")) assert(records[id].biome.Price==123) end
 print("AK_FINISH_CLIENT_PASS","snapshot, per-biome updates, whole-table updates, all 12 callbacks")
end
]==]
testModule.Parent=game.ServerStorage
local passed,problem=pcall(function() require(testModule)(names) end)
testModule:Destroy()
assert(passed,problem)
local config=require(game.ReplicatedStorage.SharedSource.Datas.AnimalKingdomConfig)
local display=require(game.StarterGui.AnimalKingdomUI.ExampleData)
for index,biome in ipairs(config.Biomes) do
 assert(display.Biomes[index].Id==biome.Id and display.Biomes[index].Price==biome.UnlockCost,"Incorrect displayed biome price: "..biome.Id)
end
print("AK_FINISH_CURRENCY_PRICE_PASS","server currency updates; all biome prices match authoritative config")
