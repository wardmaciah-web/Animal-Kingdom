-- Run only as a temporary Script in Studio Play; all mutations target the existing mock profile.
local K=require(game.ReplicatedStorage.Packages.Knit);K.OnStart():await()
local Http=game:GetService('HttpService');local p=game.Players:GetPlayers()[1]
assert(game:GetService('RunService'):IsStudio() and p:GetAttribute('ProfileDataMode')=='StudioMockSnapshot','Mock profile required')
local profiles=K.GetService('ProfileService');local profile=profiles.Profiles[p]
local function copy(v)if type(v)~='table'then return v end local n={}for k,x in pairs(v)do n[k]=copy(x)end return n end
local original=copy(profile.Data)
local checks={};local function check(v,name)assert(v,name);table.insert(checks,name)end
local Pets=K.GetService('PetService');local Plot=K.GetService('PlotService');local Garden=K.GetService('GardenExpeditionService')
local L=require(game.ReplicatedStorage.Shared.Gameplay.PetLocations)
local Def=require(game.ReplicatedStorage.Shared.Gameplay.Definitions.PetDefinitions)
local Value=require(game.ReplicatedStorage.Shared.Gameplay.SellValueCalculator)
local Model=require(game.ReplicatedStorage.Shared.Gameplay.PetModelResolver)
local data=profile.Data
data.Pets={};data.OwnedPets=data.Pets;data.GardenExpeditions={};data.PetIndex={};data.ActiveHeldPetUID='';data.Currencies.Coins=100000;data.PetStorageCapacity=500
local species
for id,def in pairs(Def)do if type(def)=='table' and def.Rarity=='Common' and not def.LegacyOnly and Model.Resolve(id) then species=id;break end end
assert(species,'Real common species required')
local function pet(location,slot,flag,id)
 local v=Pets:Create(id or species,'Normal');v.Weight=10;v.Level=4;v.XP=7;v.AcquiredAt=12345;v.Cosmetic='FlowerCrown'
 if flag then v[flag]=true end;L.Set(v,location,slot);table.insert(data.Pets,v);Pets:Discover(data,v);return v
end
local ok,err=xpcall(function()
 local sell=pet('Inventory');local keep={pet('Inventory',nil,'Locked'),pet('Inventory',nil,'Favorite'),pet('Inventory',nil,'Prismatic'),pet('Held',1),pet('Sanctuary',1),pet('Garden',1)}
 local secret,protected
 for id,d in pairs(Def)do if type(d)=='table' and d.Rarity=='Secret' then secret=secret or id end;if type(d)=='table' and d.Protected then protected=protected or id end end
 if secret then table.insert(keep,pet('Inventory',nil,nil,secret))end
 if protected then table.insert(keep,pet('Inventory',nil,nil,protected))end
 data.ActiveHeldPetUID=keep[4].UID;Pets:Publish(p)
 local before=data.Currencies.Coins;local expected=Value.Calculate(sell)
 local accepted,result=Pets:Sell(p,'Inventory','');check(accepted and result.Total==expected and result.Count==1 and data.Currencies.Coins==before+expected,'eligible sale exact payout')
 for _,v in ipairs(keep)do check(L.Find(data,v.UID)==v,'protected/location survives '..v.UID)end
 check(not Pets:Sell(p,'Inventory','') and data.Currencies.Coins==before+expected,'repeat sale no double credit')
 check(not Pets:Sell(p,'Held',keep[4].UID),'held sale rejected')
 check(Pets:Flag(p,keep[1].UID,'Locked',false),'unlock exact UID');check(Pets:Flag(p,keep[1].UID,'Locked',true),'lock exact UID')
 local saved=Http:JSONDecode(Http:JSONEncode(data));check(L.Find(saved,keep[1].UID).Locked,'lock serialization restore')
 local h=keep[4];local fingerprint=Http:JSONEncode({h.UID,h.PetId,h.Weight,h.Level,h.XP,h.Mutation,h.Shiny,h.Prismatic,h.Cosmetic,h.AcquiredAt})
 check(Pets:Move(p,h.UID,'Inventory') and data.ActiveHeldPetUID=='' and data.HeldPetSlots[1]=='','STORE frees exact slot')
 check(Http:JSONEncode({h.UID,h.PetId,h.Weight,h.Level,h.XP,h.Mutation,h.Shiny,h.Prismatic,h.Cosmetic,h.AcquiredAt})==fingerprint,'STORE preserves stats/UID')
 data.GardenExpeditions={};L.Set(keep[6],'Inventory');Pets:Publish(p)
 check(Garden:Start(p,h.UID,'SproutRun',Http:GenerateGUID(false)),'stored pet enters Garden')
 check(h.Location=='Garden' and L.Find(data,h.UID)==h,'Garden same record')
 check(Garden:Cancel(p,h.UID,Http:GenerateGUID(false)) and h.Location=='Inventory','Garden recall same record')
 local display=require(game.ServerScriptService.ServerSource.Utilities.MeadowSanctuaryDisplay)
 local slot=assert(display.GetSlot(p,1));p.Character:PivotTo(CFrame.new(slot.Surface+Vector3.new(0,3,0)))
 local displayed=keep[5]
 check(Pets:SwapSanctuary(p,0,1,'',displayed.UID) and displayed.Location=='Held' and data.ActiveHeldPetUID==displayed.UID,'physical pickup exact UID')
 check(Pets:SwapSanctuary(p,displayed.LocationSlot,1,displayed.UID,'') and displayed.Location=='Sanctuary' and data.ActiveHeldPetUID=='','PLACE still works')
 check(Pets:Equip(p,h.UID,true),'hold second pet');check(Pets:SwapSanctuary(p,h.LocationSlot,1,h.UID,displayed.UID) and h.Location=='Sanctuary' and displayed.Location=='Held','SWAP same records')
 while L.FirstFree(data,'Held',5)do pet('Held',L.FirstFree(data,'Held',5))end
 data.ActiveHeldPetUID='';Pets:Publish(p)
 local accepted,reason=Pets:SwapSanctuary(p,0,1,'',h.UID);check(not accepted and reason=='Held slots full' and h.Location=='Sanctuary','full Held pickup rejected')
 -- Isolate money tests from ongoing Sanctuary earning.
 for _,v in ipairs(data.Pets)do if v.Location=='Sanctuary' then L.Set(v,'Inventory')end end;Pets:Publish(p)
 local plot=assert(Plot:GetPlot(p));local pad=assert(plot:FindFirstChild('IncomeCollector'))
 p.Character:PivotTo(pad.CFrame+Vector3.new(0,4,0));p.Character.HumanoidRootPart.Anchored=true;task.wait(1.1)
 data.UncollectedSanctuaryCoins=12.75;before=data.Currencies.Coins
 accepted,result=Plot:TouchCollector(p,plot,pad);check(accepted and result.Amount==12 and data.UncollectedSanctuaryCoins==.75 and data.Currencies.Coins==before+12,'collector whole payout fractional remainder '..tostring(accepted)..' '..tostring(result and result.Amount)..' '..tostring(data.UncollectedSanctuaryCoins))
 check(not Plot:TouchCollector(p,plot,pad) and data.Currencies.Coins==before+12,'repeat Touched debounced')
 local other=game.Workspace.PlayerPlots:FindFirstChild('Plot2Floor');check(not Plot:TouchCollector(p,other,other.IncomeCollector),'non-owner collector rejected')
 data.Currencies.Coins=9000000000000000-3;data.UncollectedSanctuaryCoins=10.5
 accepted,result=Plot:Collect(p);check(accepted and result.Amount==3 and data.UncollectedSanctuaryCoins==7.5,'currency cap retains remainder')
 check(not Plot:Collect(p) and data.UncollectedSanctuaryCoins==7.5,'full currency no fake collection')
 local ids={}for _,v in ipairs(data.Pets)do check(not ids[v.UID],'unique UID '..v.UID);ids[v.UID]=true end
end,debug.traceback)
p.Character.HumanoidRootPart.Anchored=false
profile.Data=original;Pets:Publish(p);K.GetService('PlayerDataService'):Publish(p,'Currencies','GardenExpeditions','UncollectedSanctuaryCoins')
workspace:SetAttribute('AKPhase1Results',Http:JSONEncode({Passed=ok,Checks=checks,Error=not ok and err or nil}))
if not ok then warn(err)end
