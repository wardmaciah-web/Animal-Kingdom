-- QA ONLY: inject into Studio Play as a temporary Script. Never sync into the game.
local K=require(game.ReplicatedStorage.Packages.Knit);K.OnStart():await()
local Http=game:GetService('HttpService');local p=game.Players:GetPlayers()[1]
assert(game:GetService('RunService'):IsStudio() and p:GetAttribute('ProfileDataMode')=='StudioMockSnapshot','Mock profile required')
local profiles=K.GetService('ProfileService');local profile=assert(profiles.Profiles[p])
local function copy(v)if type(v)~='table'then return v end local t={}for k,x in pairs(v)do t[k]=copy(x)end return t end
local original=copy(profile.Data);local originalCF=p.Character:GetPivot()
local G=game.ReplicatedStorage.Shared.Gameplay
local L=require(G.PetLocations);local M=require(G.ProfileMigrations)
local Pets=K.GetService('PetService');local Data=K.GetService('PlayerDataService');local Resource=K.GetService('ResourceService')
local Garden=K.GetService('GardenExpeditionService');local Plot=K.GetService('PlotService');local Sanctuary=K.GetService('SanctuaryService')
local Placement=K.GetService('PlacementService');local Display=require(game.ServerScriptService.ServerSource.Utilities.MeadowSanctuaryDisplay)
local checks={};local function check(v,name)assert(v,name);table.insert(checks,name)end
local function stage(s)workspace:SetAttribute('AKFinalStage',s)end
local function fingerprint(pet)return Http:JSONEncode({pet.UID,pet.PetId,pet.Weight,pet.XP,pet.Level,pet.Mutation,pet.Shiny,pet.Prismatic,pet.Cosmetic,pet.AcquiredAt})end
local ok,err=xpcall(function()
 Sanctuary:Accrue(p)
 profile.Data=M.Apply(copy(require(game.ReplicatedStorage.SharedSource.Datas.ProfileTemplate)),function()return Http:GenerateGUID(false)end)
 local data=profile.Data;data.Currencies.Coins=100000;data.SanctuaryIncomeUpdatedAt=workspace:GetServerTimeNow()
 data.TutorialCompleted=true;Pets:Publish(p)
 for key in pairs(data)do Data:Publish(p,key)end
 local tree,record
 for object,r in pairs(Resource:GetRecords())do if object:GetAttribute('AK_NewMeadowSceneTree') and object:GetAttribute('AK_MeadowTreeIndex')==1 then tree,record=object,r;break end end
 check(tree~=nil and record.Prompt.Enabled,'new Tripo Meadow tree registered with live prompt')
 local originalPivot=tree:GetPivot();local root=p.Character.HumanoidRootPart
 root.Anchored=true;p.Character:PivotTo(CFrame.new(record.InteractionPosition+Vector3.new(0,2,4)))
 local accepted,why=Resource:Gather(p,tree);check(accepted,'new Meadow search accepted: '..tostring(why))
 stage('Tree search / reveal')
 task.wait(4)
 check(#data.Pets==1 and record.Awarded==true,'tree commits exactly one owned reward')
 local first=data.Pets[1];local firstUID=first.UID
 check(first.Location=='Held' and first.LocationSlot==1,'reward enters first free Held slot')
 check(Pets:Equip(p,firstUID,true) and data.ActiveHeldPetUID==firstUID,'select exact reward UID')
 workspace:SetAttribute('AKFinalPetUID',firstUID)
 task.wait(6)
 check(#data.Pets==1,'reveal does not grant a second reward')
 check(Pets:Flag(p,firstUID,'Locked',true),'lock exact reward UID')
 check(not Pets:Sell(p,'Inventory','') and L.Find(data,firstUID)==first,'Sell All preserves locked Held reward')
 local second=Pets:Create(first.PetId,'Normal');second.Shiny=false;second.Prismatic=false
 L.Set(second,'Inventory');table.insert(data.Pets,second);Pets:Publish(p)
 local before=data.Currencies.Coins;local payout=require(G.SellValueCalculator).Calculate(second)
 local sold,result=Pets:Sell(p,'Inventory','');check(sold and result.Count==1 and result.Total==payout and data.Currencies.Coins==before+payout,'eligible Inventory sale pays once')
 check(not Pets:Sell(p,'Inventory',''),'repeat sale cannot credit twice')
 check(Pets:Flag(p,firstUID,'Locked',false),'unlock for Garden')
 local immutable=fingerprint(first)
 check(Pets:Move(p,firstUID,'Inventory') and first.Location=='Inventory' and fingerprint(first)==immutable,'STORE preserves exact UID and all stats')
 check(Garden:Start(p,firstUID,'SproutRun',Http:GenerateGUID(false)),'stored reward enters real Garden trip')
 local trip=data.GardenExpeditions[1];stage('Real 60-second Garden trip')
 while os.time()<=trip.ReadyAt do task.wait(.5)end
 local harvested=data.Currencies.GardenHarvest
 check(Garden:Claim(p,firstUID,Http:GenerateGUID(false)) and L.Find(data,firstUID)==first and first.Location=='Inventory','Garden claim returns same record/UID')
 check(data.Currencies.GardenHarvest>harvested,'Garden claim credits existing GardenHarvest')
 check(tree:GetAttribute('ResourceState')=='AVAILABLE' and (tree:GetPivot().Position-originalPivot.Position).Magnitude<.001,'Tripo tree restores to original search position')
 local slot=assert(Display.GetSlot(p,1));p.Character:PivotTo(CFrame.new(slot.Surface+Vector3.new(0,3,0)))
 check(Pets:Equip(p,firstUID,true),'hold returned Garden pet')
 check(Pets:SwapSanctuary(p,first.LocationSlot,1,firstUID,''),'PLACE at physical own Sanctuary slot')
 second=Pets:Create(first.PetId,'Normal');L.Set(second,'Inventory');table.insert(data.Pets,second);Pets:Publish(p)
 check(Pets:Equip(p,second.UID,true),'hold second exact owned UID')
 local f1,f2=fingerprint(first),fingerprint(second)
 check(Pets:SwapSanctuary(p,second.LocationSlot,1,second.UID,firstUID),'SWAP at occupied physical slot')
 check(fingerprint(first)==f1 and fingerprint(second)==f2,'SWAP preserves both exact UIDs and all stats')
 local incomeBefore=data.UncollectedSanctuaryCoins;task.wait(1.2);Sanctuary:Accrue(p)
 check(data.UncollectedSanctuaryCoins>incomeBefore,'existing Sanctuary accumulator earns income')
 check(Pets:Move(p,firstUID,'Inventory') and data.ActiveHeldPetUID=='','STORE empties active hand')
 check(Pets:SwapSanctuary(p,0,1,'',second.UID) and data.ActiveHeldPetUID==second.UID,'PICK UP selects same Sanctuary pet in free Held slot')
 check(fingerprint(second)==f2,'PICK UP preserves all exact pet stats')
 stage('Physical Touched collector')
 local plot=assert(Plot:GetPlot(p));local pad=assert(plot:FindFirstChild('IncomeCollector'))
 p.Character:PivotTo(pad.CFrame+Vector3.new(12,5,0));task.wait(1.2)
 data.UncollectedSanctuaryCoins=27.75;Data:Publish(p,'UncollectedSanctuaryCoins');before=data.Currencies.Coins
 local touches=0;local conn=pad.Touched:Connect(function(part)if part:IsDescendantOf(p.Character)then touches+=1 end end)
 p.Character:PivotTo(pad.CFrame+Vector3.new(0,5,0));root.AssemblyLinearVelocity=Vector3.zero;root.Anchored=false
 task.wait(3);conn:Disconnect();root.Anchored=true
 check(touches>0,'character actually touches physical collector')
 check(data.Currencies.Coins==before+27 and data.UncollectedSanctuaryCoins==.75,'Touched collector pays exactly once and retains fraction')
 stage('Decorations and saved-state round trip')
 check(K.GetService('ShopService'):Buy(p,'WoodenChair'),'buy real available decoration')
 local owned=data.Items.WoodenChair;local placed
 for x=-40,40,10 do for z=-40,40,10 do
  if Placement:Place(p,'WoodenChair',Vector3.new(x,0,z),0)then placed=data.PlotProgression.Placements[#data.PlotProgression.Placements];break end
 end;if placed then break end end
 check(placed~=nil and data.Items.WoodenChair==owned,'place keeps permanent owned count')
 check(Placement:Remove(p,placed.UID) and data.Items.WoodenChair==owned,'remove keeps permanent owned count')
 check(Placement:Place(p,'WoodenChair',Vector3.new(placed.X,0,placed.Z),0),'owned decoration can be placed again')
 check(Plot:Upgrade(p) and data.PlotProgression.Level==1,'existing Decoration Capacity upgrade')
 p.Character:PivotTo(CFrame.new(slot.Surface+Vector3.new(0,3,0)))
 check(Pets:Equip(p,firstUID,true) and Pets:SwapSanctuary(p,first.LocationSlot,1,firstUID,''),'save fixture contains Sanctuary placement')
 check(Pets:Equip(p,second.UID,true) and Pets:Flag(p,second.UID,'Locked',true),'save fixture contains active locked Held pet')
 local third=Pets:Create(first.PetId,'Normal');L.Set(third,'Inventory');table.insert(data.Pets,third);Pets:Publish(p)
 check(Garden:Start(p,third.UID,'SproutRun',Http:GenerateGUID(false)),'save fixture contains Garden trip')
 local saved=Http:JSONEncode(data);local restored=M.Apply(Http:JSONDecode(saved),function()error('Unexpected ownership UID recreation')end)
 check(#restored.Pets==3 and L.Find(restored,firstUID).Location=='Sanctuary','restore preserves Sanctuary UID')
 check(L.Find(restored,second.UID).Locked and restored.ActiveHeldPetUID==second.UID and restored.HeldPetSlots[second.LocationSlot]==second.UID,'restore preserves lock, active UID and Held slot')
 check(restored.GardenExpeditions[1].UID==third.UID and L.Find(restored,third.UID).Location=='Garden','restore preserves Garden trip and same owned UID')
 check(restored.Items.WoodenChair==owned and #restored.PlotProgression.Placements==1,'restore preserves decoration ownership and placement')
 check(restored.Currencies.Coins==data.Currencies.Coins and restored.Currencies.GardenHarvest==data.Currencies.GardenHarvest,'restore does not duplicate currency or reward')
 for _,pet in ipairs(data.Pets)do check(fingerprint(L.Find(restored,pet.UID))==fingerprint(pet),'restore preserves all stats '..pet.UID)end
 local seen={}for _,pet in ipairs(restored.Pets)do check(not seen[pet.UID],'unique restored UID '..pet.UID);seen[pet.UID]=true end
 profile.Data=restored;Pets:Publish(p);for key in pairs(restored)do Data:Publish(p,key)end
 task.wait(2)
 check(Display.GetSlot(p,1)~=nil,'physical Sanctuary slot still resolves after restore')
 workspace:SetAttribute('AKFinalFixture',saved)
end,debug.traceback)
profile.Data=original;Pets:Publish(p);for key in pairs(original)do Data:Publish(p,key)end
if p.Character and p.Character:FindFirstChild('HumanoidRootPart')then p.Character.HumanoidRootPart.Anchored=false;p.Character:PivotTo(originalCF)end
workspace:SetAttribute('AKFinalResults',Http:JSONEncode({Passed=ok,Checks=checks,Error=not ok and err or nil,PersistenceScope='JSON + existing ProfileMigrations round trip; no production write or real rejoin'}))
stage(ok and 'Passed' or 'Failed');if not ok then warn(err)end
