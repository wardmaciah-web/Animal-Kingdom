local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Milestones=require(RS.Shared.Gameplay.Definitions.IndexRewardDefinitions)
local Index=Knit.CreateService({Name="IndexService",Client={}})
local Data,Economy
function Index:GetProgress(player)
 local data=Data:Get(player)
 return Pets.IndexProgress(data and data.PetIndex)
end
function Index:Claim(player,percent)
 local def
 for _,reward in ipairs(Milestones) do if reward.Percent==percent then def=reward end end
 local data=Data:Get(player);local _,_,completion=self:GetProgress(player)
 if not def or not data or completion<percent or data.IndexRewards[tostring(percent)] then return false,"Milestone unavailable" end
 data.IndexRewards[tostring(percent)]=true -- consume claim before crediting; no yielding operations
 Economy:Add(player,"Coins",def.Coins,"Index");Economy:Add(player,"FriendshipTokens",def.FriendshipTokens,"Index")
 Data:Publish(player,"IndexRewards");return true,"Index reward claimed!"
end
function Index:KnitInit() Data=Knit.GetService("PlayerDataService");Economy=Knit.GetService("EconomyService") end
return Index
