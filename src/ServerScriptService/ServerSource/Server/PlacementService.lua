local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local Http=game:GetService("HttpService")
local Knit=require(RS.Packages.Knit)
local Definitions=require(RS.Shared.Gameplay.Definitions.ShopDefinitions)
local Resolver=require(RS.Shared.Gameplay.AssetResolver)
local Locator=require(SSS.PlotLocator)
local Service=Knit.CreateService({Name="PlacementService",Client={}})
local Data,Plots;local visuals={};local renderedPlot={}
local function footprintInside(cf,size,model)
 local bounds,extent=model:GetBoundingBox()
 for _,x in ipairs({-extent.X/2,extent.X/2}) do for _,y in ipairs({-extent.Y/2,extent.Y/2}) do for _,z in ipairs({-extent.Z/2,extent.Z/2}) do
  local p=cf:PointToObjectSpace(bounds:PointToWorldSpace(Vector3.new(x,y,z)))
  if math.abs(p.X)>size.X/2-1 or math.abs(p.Z)>size.Z/2-1 or p.Y<size.Y/2-.1 or p.Y>size.Y/2+25 then return false end
 end end end
 return true
end
function Service:Build(def,cf,size,offset,rotation)
 local assets=RS:FindFirstChild('Assets');local category=assets and assets:FindFirstChild(def.Category);local template=category and category:FindFirstChild(def.ModelName)
 if not template or template:GetAttribute('Placeholder')or not(template:IsA('BasePart')or template:FindFirstChildWhichIsA('BasePart',true))then return nil end
 local model=Resolver.Create(def.Category,def.ModelName,def.DisplayName)
 -- Geometry may change with final assets; fit declared footprint and ground by bounds.
 local _,bounds=model:GetBoundingBox();local scale=math.min(def.Size.X/bounds.X,def.Size.Y/bounds.Y,def.Size.Z/bounds.Z)
 if scale>0 then model:ScaleTo(model:GetScale()*scale) end
 model:PivotTo(cf*CFrame.new(offset.X,size.Y/2,offset.Z)*CFrame.Angles(0,math.rad(rotation),0))
 local bound,extent=model:GetBoundingBox();local base=cf:PointToObjectSpace(bound.Position).Y-extent.Y/2
 model:PivotTo(model:GetPivot()+cf.UpVector*(size.Y/2-base))
 return model
end
function Service:Place(player,id,offset,rotation)
 local data=Data:Get(player);local def=Definitions[id];local plot=Plots:GetPlot(player)
 if not data or not def or not plot or not Plots:IsNearOwnPlot(player) then return false,"Visit your own plot first" end
 if rotation%90~=0 or rotation>=360 or math.abs(offset.Y)>1 then return false,"Invalid placement rotation or height" end
 local used=0;for _,p in ipairs(data.PlotProgression.Placements) do if p.ItemId==id then used+=1 end end
 if used>=(data.Items[id] or 0) then return false,"You do not own another copy" end
 if #data.PlotProgression.Placements>=25+data.PlotProgression.Level*5 then return false,"Plot placement limit reached" end
 local cf,size=Locator.getBounds(plot);if not cf then return false,"Plot bounds unavailable" end
 local model=self:Build(def,cf,size,offset,rotation)
 if not model then return false,"This decoration is temporarily unavailable." end
 if not footprintInside(cf,size,model) then model:Destroy();return false,"Outside plot bounds" end
 local bound,extent=model:GetBoundingBox();local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={plot,player.Character}
 for _,part in ipairs(workspace:GetPartBoundsInBox(bound,extent-Vector3.new(.05,.05,.05),params)) do
  if part.CanCollide or part:GetAttribute("PlacedItem") then model:Destroy();return false,"That location is occupied" end
 end
 local uid=Http:GenerateGUID(false)
 table.insert(data.PlotProgression.Placements,{UID=uid,ItemId=id,X=offset.X,Z=offset.Z,Rotation=rotation})
 self:Install(player,uid,model);Data:Publish(player,"PlotProgression");return true,"Item placed!"
end
function Service:Install(player,uid,model)
 local folder=visuals[player]
 if not folder then folder=Instance.new("Folder");folder.Name="PlotItems_"..player.UserId;folder.Parent=workspace;visuals[player]=folder end
 model.Name=uid;model:SetAttribute("OwnerUserId",player.UserId)
 for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then part.CanQuery=true;part:SetAttribute("PlacedItem",true) end end
 model.Parent=folder
end
function Service:Remove(player,uid)
 local data=Data:Get(player);if not data or not Plots:IsNearOwnPlot(player) then return false,"Visit your plot first" end
 for i,entry in ipairs(data.PlotProgression.Placements) do
  if entry.UID==uid then
   table.remove(data.PlotProgression.Placements,i)
   local object=visuals[player] and visuals[player]:FindFirstChild(uid);if object then object:Destroy() end
   Data:Publish(player,"PlotProgression");return true,"Item returned to storage"
  end
 end
 return false,"Placement not owned"
end
function Service:Restore(player)
 local plot=Plots:GetPlot(player);if renderedPlot[player]==plot then return end
 if visuals[player] then visuals[player]:Destroy();visuals[player]=nil end
 renderedPlot[player]=plot
 local data=Data:Get(player);if not plot or not data then return end
 local cf,size=Locator.getBounds(plot);if not cf then return end
 for _,entry in ipairs(data.PlotProgression.Placements) do
  local def=Definitions[entry.ItemId]
  if def and type(entry.X)=="number" and type(entry.Z)=="number" then
   local model=self:Build(def,cf,size,Vector3.new(entry.X,0,entry.Z),entry.Rotation or 0)
   if model then if footprintInside(cf,size,model) then self:Install(player,entry.UID,model) else model:Destroy() end end
  end
 end
end
function Service:KnitInit() Data=Knit.GetService("PlayerDataService");Plots=Knit.GetService("PlotService") end
function Service:KnitStart()
 local profiles=Knit.GetService("ProfileService")
 profiles.Releasing:Connect(function(player) if visuals[player] then visuals[player]:Destroy();visuals[player]=nil end;renderedPlot[player]=nil end)
 task.spawn(function() while true do task.wait(3);for player in pairs(profiles.Profiles) do self:Restore(player) end end end)
end
return Service
