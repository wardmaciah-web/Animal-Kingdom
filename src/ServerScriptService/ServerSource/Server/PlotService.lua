local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local Knit=require(RS.Packages.Knit)
local Locator=require(SSS.PlotLocator)
local Guard=require(script.Parent.Parent.Utilities.GameplayGuard)
local Signal=require(RS.Packages.Signal)
local Service=Knit.CreateService({Name="PlotService",Client={},Collected=Signal.new()})
local Data,Economy
local collecting=setmetatable({},{__mode="k"})
local touchedAt=setmetatable({},{__mode="k"})
function Service:GetPlot(player)
 for _,plot in ipairs(Locator.getPlots()) do if plot:GetAttribute("OwnerUserId")==player.UserId and plot:GetAttribute("Claimed")==true then return plot end end
end
function Service:CanVisit(visitor,owner)
 if visitor==owner then return true end
 local data=Data:Get(owner);return data~=nil and data.PlotProgression.VisitorsAllowed==true
end
function Service:IsNearOwnPlot(player)
 local plot=self:GetPlot(player);if not plot then return false end
 local cf,size=Locator.getBounds(plot);local root=Guard.Alive(player)
 if not cf or not root then return false end
 local point=cf:PointToObjectSpace(root.Position)
 return math.abs(point.X)<=size.X/2+12 and math.abs(point.Z)<=size.Z/2+12 and math.abs(point.Y)<=25
end
function Service:Teleport(player)
 local plot=self:GetPlot(player);local root=Guard.Alive(player)
 if not plot or not root or not Data:Get(player) then return false,"Your plot is not ready yet" end
 local cf,size=Locator.getBounds(plot);if not cf then return false,"Your plot is not ready yet" end
 if player:GetAttribute("InGarden") then
  local ok,why=Knit.GetService("GardenExpeditionService"):ReturnToKingdom(player)
  if not ok then return false,why end
 end
 local spawn=plot.Parent:FindFirstChild("Plot"..tostring(plot:GetAttribute("PlotId")).."Spawn")
 local target=spawn and spawn:IsA("BasePart") and spawn.CFrame+Vector3.new(0,4,0) or cf*CFrame.new(0,size.Y/2+4,-size.Z*.22)
 root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
 player.Character:PivotTo(target);player:SetAttribute("CurrentBiome","Town")
 return true,{Kind="PlotVisit"}
end
function Service:SetVisitors(player,allowed)
 local data=Data:Get(player);if not data or not self:GetPlot(player) then return false,"Plot unavailable" end
 data.PlotProgression.VisitorsAllowed=allowed;Data:Publish(player,"PlotProgression");return true
end
function Service:Upgrade(player)
 local data=Data:Get(player);if not data or not self:IsNearOwnPlot(player) then return false,"Visit your plot first" end
 local level=data.PlotProgression.Level
 if level>=10 then return false,"Maximum plot level" end
 local cost=math.floor(2500*2^level)
 if not Economy:Spend(player,"Coins",cost,"Plot") then return false,"Not Enough Coins" end
 data.PlotProgression.Level=level+1;Data:Publish(player,"PlotProgression");return true,"Plot upgraded!"
end
function Service:Collect(player)
 if collecting[player] then return false,"Collection in progress" end
 collecting[player]=true
 local ok,accepted,result=xpcall(function()
  if not self:IsNearOwnPlot(player) then return false,"Visit your plot to collect income" end
  Knit.GetService("SanctuaryService"):Accrue(player)
  local data=Data:Get(player);local amount=data and math.floor(data.UncollectedSanctuaryCoins) or 0
  if amount<=0 then return false,"No income to collect yet" end
  local creditedOK,credited=Economy:Add(player,"Coins",amount,"Idle")
  if not creditedOK or credited<=0 then return false,"Coin capacity reached" end
  data.UncollectedSanctuaryCoins-=credited;Data:Publish(player,"UncollectedSanctuaryCoins")
  self.Collected:Fire(player,credited)
  return true,{Kind="IncomeCollected",Amount=credited}
 end,debug.traceback)
 collecting[player]=nil
 if not ok then warn(result or accepted);return false,"Collection unavailable" end
 return accepted,result
end
function Service:TouchCollector(player,plot,pad)
 if self:GetPlot(player)~=plot or not pad or pad.Parent~=plot or pad.Name~='IncomeCollector' then return false end
 local root=Guard.Alive(player)
 if not root then return false end
 local point=pad.CFrame:PointToObjectSpace(root.Position)
 if math.abs(point.X)>pad.Size.X/2+3 or math.abs(point.Z)>pad.Size.Z/2+3 or math.abs(point.Y)>8 then return false end
 if touchedAt[player] and os.clock()-touchedAt[player]<1 then return false end
 touchedAt[player]=os.clock()
 return self:Collect(player)
end
function Service:KnitStart()
 require(script.Parent.Parent.Utilities.PlotCollector).Start(self,Data)
end
function Service:KnitInit() Data=Knit.GetService("PlayerDataService");Economy=Knit.GetService("EconomyService") end
return Service
