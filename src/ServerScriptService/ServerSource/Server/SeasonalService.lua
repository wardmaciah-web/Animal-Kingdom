local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Definitions=require(RS.Shared.Gameplay.Definitions.SeasonalDefinitions)
local Service=Knit.CreateService({Name="SeasonalService",Client={}})
function Service:IsActive(id)
 local def=Definitions[id];local now=os.time()
 return def~=nil and def.StartsAt>0 and now>=def.StartsAt and now<def.EndsAt
end
function Service:GetProgress(player,id)
 if not Definitions[id] then return nil end
 local data=Knit.GetService("PlayerDataService"):Get(player);if not data then return nil end
 local season=data.SeasonalData[id]
 if not season then season={Progress={},Claims={},Edition=Definitions[id].StartsAt};data.SeasonalData[id]=season end
 -- Preserve old editions; changing the calendar never wipes rewards/history.
 if season.Edition~=Definitions[id].StartsAt then
  season.History=season.History or {};season.History[tostring(season.Edition)]={Progress=season.Progress,Claims=season.Claims}
  season.Edition=Definitions[id].StartsAt;season.Progress={};season.Claims={}
 end
 return season
end
function Service:Track(player,id,key,amount)
 if not self:IsActive(id) or type(amount)~="number" or amount<=0 or amount~=amount or amount==math.huge then return false end
 local progress=self:GetProgress(player,id);if not progress then return false end
 progress.Progress[key]=(progress.Progress[key] or 0)+math.floor(amount)
 Knit.GetService("PlayerDataService"):Publish(player,"SeasonalData");return true
end
function Service:Claim(player,id,rewardId)
 if not self:IsActive(id) then return false,"Season is inactive" end
 local def=Definitions[id];local reward=def.Rewards and def.Rewards[rewardId]
 local progress=self:GetProgress(player,id)
 if not reward or not progress or progress.Claims[rewardId] or (progress.Progress[reward.Type] or 0)<reward.Target then return false,"Reward unavailable" end
 progress.Claims[rewardId]=true
 local economy=Knit.GetService("EconomyService")
 for currency,amount in pairs(reward.Currencies or {}) do economy:Add(player,currency,amount,"Seasonal") end
 Knit.GetService("PlayerDataService"):Publish(player,"SeasonalData");return true
end
return Service
