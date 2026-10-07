-- Integrates with the existing active profile; never awards cinematic rewards.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local remote=Instance.new("RemoteEvent");remote.Name="KingdomIntroComplete";remote.Parent=RS
local eligible={}
local function ready(p)
 task.spawn(function()
  local deadline=os.clock()+120
  repeat task.wait(.25)until p:GetAttribute("ProfileReady")==true or not p.Parent or os.clock()>deadline
  if not p.Parent or p:GetAttribute("ProfileReady")~=true then return end
  local service=Knit.GetService("ProfileService");local profile=service.Profiles[p]
  if not profile or not profile:IsActive()then return end
  p:SetAttribute("IntroCompleted",profile.Data.IntroCompleted==true);eligible[p]=os.clock();p:SetAttribute("IntroReady",true)
 end)
end
Players.PlayerAdded:Connect(ready);for _,p in Players:GetPlayers()do ready(p)end
Players.PlayerRemoving:Connect(function(p)eligible[p]=nil end)
remote.OnServerEvent:Connect(function(p)
 if not eligible[p]then return end
 local service=Knit.GetService("ProfileService");local profile=service.Profiles[p]
 if not profile or not profile:IsActive()then return end
 if profile.Data.IntroCompleted~=true then service:ChangeData(p,{"IntroCompleted"},true)end
 p:SetAttribute("IntroCompleted",true);eligible[p]=nil
end)
