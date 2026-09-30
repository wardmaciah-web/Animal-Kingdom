-- Bounded startup loading, with acknowledged retries so a busy server cannot lose readiness.
local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local Models=require(RS.Shared.Gameplay.PetAssetLoading)
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Knit=require(RS.Packages.Knit)
Knit.OnStart():await()
Knit.GetController('DataController'):WaitUntilProfileLoaded()
local remotes=RS:WaitForChild('AnimalKingdomRemotes')
local request=remotes:WaitForChild('UIRequest')
local pending,ordered={},{}
for _,def in ipairs(Pets.Ordered)do
 if not def.LegacyOnly and not def.RetiredFromRewards and (def.ModelAssets or Models.Resolve(def.PetId))then
  local entry={Id=def.PetId,RequestId='pet-assets-'..Http:GenerateGUID(false),NextLoad=0,NextSend=0}
  pending[entry.RequestId]=entry;table.insert(ordered,entry)
 end
end
local remaining=#ordered
local feedback=remotes:WaitForChild('GameplayFeedback').OnClientEvent:Connect(function(result)
 local entry=pending[result.RequestId]
 if result.Action~='PetAssetsLoaded'or not entry then return end
 if result.Success then
  pending[entry.RequestId]=nil;remaining-=1
  game.Players.LocalPlayer:SetAttribute('AKImportedPetsReady',#ordered-remaining)
 else entry.NextSend=os.clock()+1 end
end)
local active,nextSend=0,0
while script.Parent and remaining>0 do
 local now=os.clock()
 for _,entry in ipairs(ordered)do
  if not pending[entry.RequestId]then continue end
  if entry.Signature then
   if now>=nextSend and now>=entry.NextSend then
    nextSend=now+.3;entry.NextSend=now+2
    request:FireServer('PetAssetsLoaded',{Id=entry.Id,Signature=entry.Signature,Loaded=true},entry.RequestId)
   end
  elseif not entry.Loading and active<4 and now>=entry.NextLoad then
   entry.Loading=true;active+=1
   task.spawn(function()
    local ok,result=Models.Preload(entry.Id)
    if ok then entry.Signature=result
    elseif entry.LastIssue~=result then warn('[PetAssets] '..tostring(result));entry.LastIssue=result end
    entry.Loading=false;active-=1;entry.NextLoad=os.clock()+15
   end)
  end
 end
 task.wait(.15)
end
feedback:Disconnect()
