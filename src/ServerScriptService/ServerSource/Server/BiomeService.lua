local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local SSS=game:GetService("ServerScriptService")
local Knit=require(RS.Packages.Knit)
local Signal=require(RS.Packages.Signal)
local Definitions=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local Landing=require(SSS.BiomeTeleport.Landing)
local Guard=require(script.Parent.Parent.Utilities.GameplayGuard)
local Biomes=Knit.CreateService({Name="BiomeService",Client={},Unlocked=Signal.new()})
local Data,Economy
local floors={};local adminBypass=setmetatable({},{__mode="k"})
function Biomes:IsUnlocked(player,id)
 local data=Data:Get(player)
 return Definitions.IsContentReady(id) and data~=nil and data.UnlockedBiomes[id]==true
end
-- Admin navigation can bypass barriers; rewards still require released content and saved access.
function Biomes:SetAdminBypass(player,enabled)
 if not Knit.GetService("WeatherAdminService"):IsAuthorized(player) then return false end
 adminBypass[player]=enabled==true;return true
end
function Biomes:GetFloor(id)
 local floor=floors[id]
 if floor and floor.Parent then return floor end
 floor=Landing.FindFloor(id);floors[id]=floor;return floor
end
function Biomes:AtPosition(position)
 for _,def in ipairs(Definitions.Ordered) do
  local floor=self:GetFloor(def.Id)
  if floor then
   local point=floor.CFrame:PointToObjectSpace(position)
   if math.abs(point.X)<=floor.Size.X/2 and math.abs(point.Z)<=floor.Size.Z/2 and math.abs(point.Y)<100 then return def.Id end
  end
 end
 return "Town"
end
function Biomes:Unlock(player,id)
 local def=Definitions[id];local data=Data:Get(player)
 if def and not Definitions.IsContentReady(id) then return false,Definitions.ComingSoonMessage end
 if not def or not data or data.UnlockedBiomes[id] then return false,"Biome unavailable or already unlocked" end
 if def.PreviousBiome and not self:IsUnlocked(player,def.PreviousBiome) then return false,"Unlock "..def.PreviousBiome.." first" end
 if not Economy:Spend(player,def.Currency,def.Cost,"Biome") then return false,"Not Enough Coins" end
 data.UnlockedBiomes[id]=true;Data:Publish(player,"UnlockedBiomes");self.Unlocked:Fire(player,id)
 return true,def.DisplayName.." Unlocked!"
end
function Biomes:KnitInit() Data=Knit.GetService("PlayerDataService");Economy=Knit.GetService("EconomyService") end
function Biomes:KnitStart()
 -- One low-frequency boundary monitor. Never creates/moves map geometry.
 task.spawn(function()
  while true do
   task.wait(1)
   for _,player in ipairs(Players:GetPlayers()) do
    local root=Guard.Alive(player)
    if root and Data:Get(player) then
     local id=self:AtPosition(root.Position);player:SetAttribute("CurrentBiome",id)
     if id~="Town" and not self:IsUnlocked(player,id) and not adminBypass[player] then
      -- Existing server-authorized admin teleports remain usable for testing.
      local isAdmin=Knit.GetService("WeatherAdminService"):IsAuthorized(player)
      if isAdmin then adminBypass[player]=true
      else
       local floor=self:GetFloor("Meadow")
       local markers=workspace:FindFirstChild("BiomeTeleportPoints")
       local marker=markers and markers:FindFirstChild("Meadow")
       if floor and marker then Landing.Move(player.Character,marker,floor) end
      end
     end
    end
   end
  end
 end)
end
return Biomes
