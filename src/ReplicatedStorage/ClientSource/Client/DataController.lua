local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Signal=require(RS.Packages.Signal)
local Controller=Knit.CreateController({Name="DataController",Data=nil,Changed=Signal.new()})
local Profiles
function Controller:GetPlayerData() return self.Data end
function Controller:WaitUntilProfileLoaded() while not self.Data do task.wait(.05) end end
function Controller:RequestToUpdateData() Profiles.GetData:Fire() end
function Controller:KnitInit() Profiles=Knit.GetService("ProfileService") end
function Controller:KnitStart()
 -- Subscribe before requesting a snapshot, so updates cannot fall into the old startup gap.
 Profiles.UpdateSpecificData:Connect(function(path,value)
  local data=self.Data;if not data then return end
  for i=1,#path-1 do data=data[path[i]];if type(data)~="table" then return end end
  data[path[#path]]=value;self.Changed:Fire(path[1],self.Data)
 end)
 Profiles.GetData:Connect(function(data) self.Data=data;self.Changed:Fire(nil,data) end)
 self:RequestToUpdateData()
end
return Controller
