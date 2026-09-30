local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Knit=require(RS.Packages.Knit)
local Policy=require(script.Parent.Parent.Utilities.GameplayRequestPolicy)
local Rarities=require(RS.Shared.Gameplay.Definitions.RarityDefinitions)
local Service=Knit.CreateService({Name="GameplayService",Client={}})
local Data;local busy=setmetatable({},{__mode="k"})
local function remote(folder,name)
 local r=folder:FindFirstChild(name)
 if r then assert(r:IsA("RemoteEvent"),name.." must be a RemoteEvent");return r end
 r=Instance.new("RemoteEvent");r.Name=name;r.Parent=folder;return r
end
function Service:Dispatch(player,action,p)
 local pets=Knit.GetService("PetService")
 local activities=Knit.GetService("ChallengeService").Activities
 if action=="ActivityClaim"then return activities:Claim(player,p.Id)
 elseif action=="ActivityAbandon"then return activities:Abandon(player,p.Kind,p.Id)
 elseif action=="MissionStart"then return activities:Mission(player,p.UID,p.Kind)
 elseif action=="MissionClaim"then return activities:ClaimMission(player,p.Id)
 elseif action=="ActivityAccept"then if activities.Routes then return activities.Routes:Accept(player,p.Id,p.Biome)end;return false,"Activities are getting ready."
 elseif action=="PawDiscover"then if activities.Routes then return activities.Routes:Discover(player,p.Id,p.Index)end;return false,"Trail unavailable."end
 if action=="MovePet" then return pets:Move(player,p.UID,p.Location,p.Slot>0 and p.Slot or nil)
 elseif action=="SwapSanctuary" then return pets:SwapSanctuary(player,p.HeldSlot,p.SanctuarySlot,p.HeldUID,p.SanctuaryUID)
 elseif action=="SellPets" then return pets:Sell(player,p.Mode,p.UID)
 elseif action=="PetAssetsLoaded" then return require(script.Parent.Parent.Utilities.MeadowPoolReadiness).Acknowledge(player,p.Id,p.Signature,p.Loaded)
 elseif action=="DisplayMeadowPet" then return Knit.GetService("SanctuaryService").Client:SetPetDisplayed(player,p.UID,p.Displayed)
 elseif action=="Equip" then return pets:Equip(player,p.UID,p.Equipped)
 elseif action=="Favorite" then return pets:Flag(player,p.UID,"Favorite",p.Value)
 elseif action=="Lock" then return pets:Flag(player,p.UID,"Locked",p.Value)
 elseif action=="RequestDelete" then return pets:RequestDelete(player,p.UID)
 elseif action=="Delete" then return pets:Delete(player,p.UID,p.Token)
 elseif action=="LuckyTry" then return Knit.GetService("LuckyTreeService"):Try(player,p.EventId,p.RequestId)
 elseif action=="Gather" then return Knit.GetService("ResourceService"):Gather(player,p.Target)
 elseif action=="Upgrade" then return Knit.GetService("UpgradeService"):Purchase(player,p.Id)
 elseif action=="UnlockBiome" then return Knit.GetService("BiomeService"):Unlock(player,p.Id)
 elseif action=="ClaimMastery" then return Knit.GetService("ProgressionService"):ClaimMastery(player,p.Biome,p.Level)
 elseif action=="ClaimChallenge" then return Knit.GetService("ChallengeService"):Claim(player,p.Period,p.Id)
 elseif action=="ClaimIndex" then return Knit.GetService("IndexService"):Claim(player,p.Percent)
 elseif action=="ClaimSeasonal" then return Knit.GetService("SeasonalService"):Claim(player,p.Season,p.RewardId)
 elseif action=="TutorialNext" or action=="TutorialComplete" then return Knit.GetService("TutorialService"):Complete(player)
 elseif action=="TutorialRevealDone" then return Knit.GetService("TutorialService"):RevealDone(player,p.UID)
 elseif action=="TutorialRestart" then return Knit.GetService("TutorialService"):Restart(player)
  elseif action=="ShopBuy" then return Knit.GetService("ShopService"):Buy(player,p.Id,p.RequestId,p.Rotation)
  elseif action=="KingdomBuy" then return Knit.GetService("ShopService"):BuyBoost(player,p.Id,p.Rotation,p.RequestId)
  elseif action=="StartExpedition" then return Knit.GetService("GardenExpeditionService"):Start(player,p.UID,p.DurationId,p.RequestId)
  elseif action=="ClaimExpedition" then return Knit.GetService("GardenExpeditionService"):Claim(player,p.UID,p.RequestId)
  elseif action=="ClaimAllExpeditions" then return Knit.GetService("GardenExpeditionService"):ClaimAll(player,p.RequestId)
  elseif action=="VisitGarden" then return Knit.GetService("GardenExpeditionService"):VisitGarden(player)
  elseif action=="ReturnGarden" then return Knit.GetService("GardenExpeditionService"):ReturnToKingdom(player)
  elseif action=="CancelExpedition" then return Knit.GetService("GardenExpeditionService"):Cancel(player,p.UID,p.RequestId)
  elseif action=="BuyGardenSupply" then return Knit.GetService("GardenExpeditionService"):BuySupply(player,p.Id,p.RequestId)
  elseif action=="UpgradeGarden" then return Knit.GetService("GardenExpeditionService"):Upgrade(player,p.Id,p.RequestId)
  elseif action=="BuyGardenCosmetic" then return Knit.GetService("GardenExpeditionService"):BuyCosmetic(player,p.Id,p.RequestId)
  elseif action=="EquipGardenCosmetic" then return Knit.GetService("GardenExpeditionService"):EquipCosmetic(player,p.UID,p.CosmeticId,p.RequestId)
 elseif action=="Place" then return Knit.GetService("PlacementService"):Place(player,p.Id,p.Offset,p.Rotation)
 elseif action=="RemovePlacement" then return Knit.GetService("PlacementService"):Remove(player,p.UID)
 elseif action=="TeleportPlot" then return Knit.GetService("PlotService"):Teleport(player)
 elseif action=="PlotVisitors" then return Knit.GetService("PlotService"):SetVisitors(player,p.Allowed)
 elseif action=="PlotUpgrade" then return Knit.GetService("PlotService"):Upgrade(player)
 elseif action=="CollectIdle" then return Knit.GetService("PlotService"):Collect(player)
 elseif action=="Setting" or action=="AutoDelete" then
  local data=Data:Get(player)
  if action=="AutoDelete" then
   if not Rarities[p.Rarity] or p.Rarity=="Secret" then return false,"Protected rarity" end
   data.Settings.AutoDelete[p.Rarity]=p.Value
  else
   if p.Id~="ReducedMotion" and p.Id~="ShowOtherPets" then return false,"Invalid setting" end
   data.Settings[p.Id]=p.Value
  end
  Data:Publish(player,"Settings");return true
 end
 return false,"Invalid action"
end
function Service:KnitInit()
 Data=Knit.GetService("PlayerDataService")
 local folder=RS:FindFirstChild("AnimalKingdomRemotes") or Instance.new("Folder");folder.Name="AnimalKingdomRemotes";folder.Parent=RS
 self.Request=remote(folder,"UIRequest");self.Feedback=remote(folder,"GameplayFeedback")
 remote(folder,"GameplayNotice");remote(folder,"GatherVisual")
end
-- Correlate completion with the requesting button and replay identical requests once.
-- Prices, inventory and rewards remain entirely in the existing services.
local receipts=setmetatable({},{__mode="k"})
function Service:KnitStart()
 self.Request.OnServerEvent:Connect(function(player,action,payload,requestId,...)
  if select("#",...)~=0 then return end
  if requestId~=nil and (type(requestId)~="string" or #requestId<8 or #requestId>80) then return end
  local ledger=receipts[player]
  if requestId and ledger and ledger.ById[requestId] then
   local receipt=ledger.ById[requestId]
   if receipt.Action==action then self.Feedback:FireClient(player,receipt) end
   return
  end
  if not Policy.Check(player,action,payload) or busy[player] or not Data:Get(player) then
   if requestId and type(action)=='string'and Policy.Actions[action]then self.Feedback:FireClient(player,{Action=action,RequestId=requestId,Success=false,Result='Please wait a moment and try again.'})end
   return
  end
  busy[player]=true
  local ok,success,result=pcall(self.Dispatch,self,player,action,payload)
  busy[player]=nil
  if not ok then warn("[GameplayService] "..tostring(action)..": "..tostring(success));success=false;result="Action unavailable; please try again" end
  local receipt={Action=action,RequestId=requestId,Success=success==true,Result=result}
  if requestId then
   ledger=ledger or {ById={},Order={}};receipts[player]=ledger
   ledger.ById[requestId]=receipt;table.insert(ledger.Order,requestId)
   if #ledger.Order>64 then ledger.ById[table.remove(ledger.Order,1)]=nil end
  end
  if player.Parent==Players then self.Feedback:FireClient(player,receipt) end
 end)
end
return Service
