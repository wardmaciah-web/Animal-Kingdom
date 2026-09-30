-- Fresh Studio mock Play session only. This exercises runtime services and
-- sends the real Secret reveal to the single test client. Never install under src.
assert(game:GetService("RunService"):IsStudio())
assert(game.ServerScriptService.ServerSource.Server.ProfileService:GetAttribute("AKUseMockProfiles")==true)
local ok,result=xpcall(function()
local K=require(game.ReplicatedStorage.Packages.Knit)
local p=game.Players:GetPlayers()[1]
assert(p:GetAttribute("ProfileDataMode")=="StudioMockSnapshot")
local Data=K.GetService("PlayerDataService");local d=assert(Data:Get(p))

local S=K.GetService("LuckyTreeService");local Eco=K.GetService("EconomyService")
local Rules=require(game.ReplicatedStorage.Shared.Gameplay.LuckyTreeRules)
local Mods=K.GetService("ModifierService");local Progress=K.GetService("ProgressionService")
local Http=game.HttpService;local snapshots={}
local function snapshot(label)
 local seen={};local rows={}
 for _,pet in ipairs(d.Pets)do assert(not seen[pet.UID],"Duplicate owned UID");seen[pet.UID]=true;table.insert(rows,{UID=pet.UID,PetId=pet.PetId,Location=pet.Location,Slot=pet.LocationSlot})end
 table.insert(snapshots,{Label=label,Coins=d.Currencies.Coins,Pets=rows})
end
snapshot("fresh mock")
local locked=S:StudioFixture("Forest")
local blocked,reason=S:StudioTry(p,locked,"blocked","Coins");assert(not blocked)
assert(not Rules.Event(d,locked.EventId,false))
Eco:Add(p,"Coins",100000,"QA_MockFixture")
assert(K.GetService("BiomeService"):Unlock(p,"Forest"))
local event=S:StudioFixture("Meadow");local count=#d.Pets
local ok,result=S:StudioTry(p,event,"secret","Secret");assert(ok and #d.Pets==count+1)
snapshot("Secret committed")
assert(result.Results[1].WeightRecord and result.Results[1].WeightRecord.First)
game.ReplicatedStorage.AnimalKingdomRemotes.GameplayFeedback:FireClient(p,{Action="LuckyTry",Success=true,RequestId="QA_REAL_SECRET_REVEAL",Result=result})
local receipt=Rules.Event(d,event.EventId,false).Receipts[1]
local owned=K.GetService("PetService"):FindOwned(d,result.Results[1].Pet.UID)
assert(owned~=receipt.Result.Results[1].Pet,"Receipt is a snapshot, not aliased ownership")
local replay,again=S:Try(p,event.EventId,"secret");assert(replay and again.Results[1].Pet.UID==owned.UID and #d.Pets==count+1)
snapshot("Secret replay")
local boost=S:StudioFixture("Forest")
local boosted,b=S:StudioTry(p,boost,"boost","Luck");assert(boosted)
local record=Rules.Event(d,boost.EventId,false).Receipts[1]
assert(b.ExpiresAt-record.AwardedAt==300,"Exactly 300 seconds from authoritative award timestamp")
assert(d.Boosts.LuckyTree_Forest.ExpiresAt==b.ExpiresAt)
local before=#d.Pets;local coinsBefore=d.Currencies.Coins
local coin=S:StudioFixture("Forest");local paid,c=S:StudioTry(p,coin,"coins","Coins")
assert(paid and d.Currencies.Coins-coinsBefore==20000 and #d.Pets==before)
snapshot("boost and coins")
assert(Progress:GetStreak(p)==0,"No Lucky streak farming")
local copy=Http:JSONDecode(Http:JSONEncode(d))
copy.BiomeMastery.Meadow={Searches=75,Claims={["1"]=true}}
copy.IndexRewards["25"]=true
local contractsBefore=Http:JSONEncode(copy.Contracts)
local oldUIDs={};for _,pet in ipairs(copy.Pets)do oldUIDs[pet.UID]=pet.Location end
local M=require(game.ReplicatedStorage.Shared.Gameplay.ProfileMigrations)
M.Apply(copy,function()error("Valid existing UIDs must not be regenerated")end)
assert(copy.DataVersion==5 and copy.BiomeMastery.Meadow.Searches==75 and copy.BiomeMastery.Meadow.Claims["1"])
assert(copy.IndexRewards["25"] and copy.PetIndex.MeadowCelestialLamb)
assert(Http:JSONEncode(copy.Contracts)==contractsBefore)
assert(copy.WeightRecords.MeadowCelestialLamb==d.WeightRecords.MeadowCelestialLamb)
assert(Rules.Event(copy,event.EventId,false).Used==1)
assert(copy.Boosts.LuckyTree_Forest.ExpiresAt==b.ExpiresAt)
for _,pet in ipairs(copy.Pets)do assert(oldUIDs[pet.UID]==pet.Location and pet.AwardProgressApplied==true)end
return {Snapshots=snapshots,UIDViolations=0,ForestLockedReason=reason,SecretUID=owned.UID,Record=result.Results[1].WeightRecord,BoostSeconds=b.ExpiresAt-record.AwardedAt,Status=S:GetStatus(),MockRestoration={Version=copy.DataVersion,ContractsPreserved=true,IndexClaimPreserved=true,MasteryClaimPreserved=true,RecordsPreserved=true,BoostExpiryPreserved=true,Used=Rules.Event(copy,event.EventId,false).Used},Streak=Progress:GetStreak(p)}

end,debug.traceback)
script:SetAttribute("Result",game.HttpService:JSONEncode({ok=ok,result=result}))
