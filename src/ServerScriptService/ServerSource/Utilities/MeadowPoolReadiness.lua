local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Models=require(RS.Shared.Gameplay.PetAssetLoading)
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Rarities=require(RS.Shared.Gameplay.Definitions.RarityDefinitions)
local M={}
local server,clients={},setmetatable({},{__mode="k"})
function M.Acknowledge(player,id,signature,loaded)
 local _,issue,_,expected=Models.Resolve(id)
 if issue or signature~=expected then return false end
 clients[player]=clients[player] or {}
 clients[player][id]=loaded and signature or nil
 return true
end
function M.Check(def,player)
 if not def or not def.CanonicalPool or type(def.Pets)~='table' or #def.Pets==0 then return false,"Invalid imported reward pool" end
 local total,unique=0,{}
 for _,entry in ipairs(def.Pets) do
  local pet=Pets[entry.PetId]
  local income=pet and (pet.BaseIncome or pet.BaseIncomePerSecond or pet.CoinsPerSecond)
  if not pet or pet.Biome~=def.Biome or pet.LegacyOnly or pet.RetiredFromRewards or not Rarities[pet.Rarity] or type(income)~="number" or income~=income or income<=0 or income>=math.huge then return false,"Invalid imported catalog entry: "..tostring(entry.PetId) end
  if unique[entry.PetId] or type(entry.DropWeight)~="number" or entry.DropWeight~=entry.DropWeight or entry.DropWeight<=0 or entry.DropWeight>=math.huge then return false,"Invalid imported pool weights" end
  unique[entry.PetId]=true;total+=entry.DropWeight
  local _,issue,_,signature=Models.Resolve(entry.PetId)
  if issue then return false,issue end
  local status=server[entry.PetId]
  if not status or status.signature~=signature then
   -- The canonical resolver above validates newly registered imports as well.
   status={signature=signature};server[entry.PetId]=status
  end
  if status.error then return false,pet.DisplayName..": "..status.error end
  if player and (not clients[player] or clients[player][entry.PetId]~=signature) then return false,pet.DisplayName..": textures are still loading on your device" end
 end
 if total<=0 or total>=math.huge then return false,"Invalid imported pool weights" end
 return true
end
function M.Start()
 for _,def in ipairs(Pets.Ordered) do
  if def.LegacyOnly or def.RetiredFromRewards then continue end
  -- Servers validate the authored bindings; rendering clients fetch the images.
  -- ImageLabel texture preloads on a headless server do not complete.
  local _,issue,_,signature=Models.Resolve(def.PetId)
  server[def.PetId]={signature=signature,error=issue}
  if issue and def.ModelAssets then warn("[PetAssets] "..issue) end
 end
 Players.PlayerRemoving:Connect(function(player) clients[player]=nil end)
end
return M
