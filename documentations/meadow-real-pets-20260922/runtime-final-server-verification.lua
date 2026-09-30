assert(game:GetService("RunService"):IsStudio())
local RS=game.ReplicatedStorage;local K=require(RS.Packages.Knit);K.OnStart():await()
local p=game.Players:GetPlayers()[1];local Profile=K.GetService("ProfileService")
assert(Profile.Profiles[p] and Profile.Profiles[p].is_mock)
local audit=RS.MeadowLiveAudit
local Data=K.GetService("PlayerDataService");local data=Data:Get(p)
local defs=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Models=require(RS.Shared.Gameplay.PetModelValidation)
local Eggs=require(RS.Shared.Gameplay.Definitions.EggDefinitions)
local Pets=K.GetService("PetService")
local checks={ids={},pools={},ready=0}
local seen={}
for _,d in ipairs(defs.MeadowOrdered) do
 assert(not seen[d.PetId]);seen[d.PetId]=true
 local m,issue=Models.Resolve(d.PetId)
 checks.ids[d.PetId]={ready=m~=nil,issue=issue,rarity=d.Rarity,income=d.BaseIncomePerSecond}
 if m then checks.ready+=1 end
end
assert(#defs.MeadowOrdered==15 and checks.ready==14)
for i=1,5 do local pool=Eggs[string.format("Meadow_Shakeable_%02d",i)];local sum=0;for _,e in ipairs(pool.Pets)do sum+=e.Weight;assert(defs[e.PetId].IsMeadowPet)end;assert(#pool.Pets==3 and sum==100);checks.pools[i]={id=pool.Id,total=sum,cost=pool.Cost}end
audit:SetAttribute("Static",game.HttpService:JSONEncode(checks))
audit:SetAttribute("Session","Final sources")
audit:SetAttribute("RunPhase","Final reveal verification")
data.PetStorageCapacity=math.max(data.PetStorageCapacity,#data.Pets+14)
Data:Publish(p,"PetStorageCapacity")
for _,d in ipairs(defs.MeadowOrdered) do
 if Models.Resolve(d.PetId) then
  audit:SetAttribute("CurrentPet",d.PetId)
  local pet=Pets:Grant(p,d.PetId,"Normal",false,false)
  assert(pet)
  RS.AnimalKingdomRemotes.GameplayFeedback:FireClient(p,{Success=true,Action="StudioVisualCheck",Result={Kind="Hatch",EggId=string.format("Meadow_Shakeable_%02d",math.ceil(table.find(defs.MeadowOrdered,d)/3)),Duration=.3,Results={{Pet=pet,AutoDeleted=false,NewDiscovery=false}}}})
  task.wait(3.2)
 end
end
audit:SetAttribute("RunPhase","Complete");audit:SetAttribute("Done",true)
