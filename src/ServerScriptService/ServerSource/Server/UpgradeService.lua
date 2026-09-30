local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Definitions=require(RS.Shared.Gameplay.Definitions.UpgradeDefinitions)
local Service=Knit.CreateService({Name="UpgradeService",Client={}})
local Data,Economy
function Service:Purchase(player,id)
 if id=="EquippedSlots" then return false,"Held Pets has five slots for every player." end
 local def=Definitions[id];local data=Data:Get(player)
 if not def or not data then return false,"Invalid upgrade" end
 local level=math.clamp(data.Upgrades[id] or 0,0,def.MaxLevel)
 if level>=def.MaxLevel then return false,"Maximum level reached" end
 if not Economy:Spend(player,def.Currency,def.Costs[level+1],"Upgrade") then return false,"Not Enough "..def.Currency end
 data.Upgrades[id]=level+1
 if id=="PetStorage" then data.PetStorageCapacity=math.max(data.PetStorageCapacity,50+def.Effect*(level+1)) end
 if id=="EquippedSlots" then data.MaxEquippedPets=math.max(data.MaxEquippedPets,3+def.Effect*(level+1)) end
 Data:Publish(player,"Upgrades","PetStorageCapacity","MaxEquippedPets")
 Knit.GetService("ModifierService"):PublishOdds(player)
 if id=="WalkSpeed" then Knit.GetService("EventModifierService"):RefreshMovement(player) end
 return true,def.DisplayName.." upgraded!"
end
function Service:KnitInit() Data=Knit.GetService("PlayerDataService");Economy=Knit.GetService("EconomyService") end
function Service:KnitStart()
 Knit.GetService("ProfileService").Loaded:Connect(function(player) Knit.GetService("EventModifierService"):RefreshMovement(player) end)
end
return Service
