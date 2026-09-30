-- Extends the authored Garden beds; never rebuilds the realm or player plots.
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Locator=require(game.ServerScriptService.PlotLocator)
local Progress=require(RS.Shared.Gameplay.GardenProgress)
local Runtime={Plots={},Assignments={}}
local CROP_SOURCE="Lightweight authored Garden crop; inserted Vegetable Garden has beds/fences only"
local function plotNumber(name)
 return type(name)=="string" and tonumber(name:match("%d+")) or nil
end
local function part(parent,name,size,cf,color,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 if shape then p.Shape=shape end;p.Parent=parent;return p
end
local function folder(parent,name,class)
 local v=parent:FindFirstChild(name);if not v then v=Instance.new(class or "Folder");v.Name=name;v.Parent=parent end;return v
end
local function placementMarker(parent,name,cf)
 local marker=parent:FindFirstChild(name)
 if marker then
  -- Adopt only the old runtime's small, invisible, inert markers. A matching
  -- name alone must never turn a piece of authored geometry into a locator.
  local legacy=marker:IsA("BasePart") and marker.Transparency==1 and not marker.CanCollide
   and not marker.CanTouch and not marker.CanQuery and marker.Size.X<=1.1 and marker.Size.Y<=1.1 and marker.Size.Z<=1.1
  assert(marker:IsA("BasePart") and (marker:GetAttribute("AKGeneratedGardenMarker")==true or legacy),
   "Unverified Garden marker geometry preserved: "..marker:GetFullName())
 else
  marker=part(parent,name,Vector3.one,cf,Color3.new())
 end
 marker:SetAttribute("AKGeneratedGardenMarker",true)
 marker.CFrame=cf;marker.Transparency=1;marker.Anchored=true
 marker.CanCollide=false;marker.CanQuery=false;marker.CanTouch=false
 return marker
end
local function effectPart(model,preferred)
 if not model then return nil end
 local named=model:FindFirstChild(preferred,true)
 if named and named:IsA("BasePart") then return named end
 if model:IsA("BasePart") then return model end
 return (model:IsA("Model") and model.PrimaryPart) or model:FindFirstChildWhichIsA("BasePart",true)
end
function Runtime.BuildCrops()
 local root=folder(RS,"GardenAssets");local crops=folder(root,"Crops")
 local green=Color3.fromRGB(82,144,67);local orange=Color3.fromRGB(238,126,43)
 for _,id in ipairs({"Carrot","Tomato","Pumpkin","Starberry","Moonmelon"}) do
  if crops:FindFirstChild(id) then continue end
  local m=folder(crops,id,"Model");m:SetAttribute("GardenCrop",true)
  local function p(name,size,x,y,z,color,shape) return part(m,name,size,CFrame.new(x,y,z),color,shape or Enum.PartType.Ball) end
  local top
  if id=="Carrot" then
   p("OrangeRoot",Vector3.new(.65,1.1,.65),0,.45,0,orange)
   p("RootTip",Vector3.new(.35,.55,.35),0,-.08,0,orange);top=1.1
  elseif id=="Tomato" then
   p("RedFruit",Vector3.new(1.2,1,1.2),0,.5,0,Color3.fromRGB(223,65,63));top=1
  elseif id=="Pumpkin" then
   for n=1,7 do local a=n*math.pi*2/7;p("PumpkinRib",Vector3.new(.8,1.25,.8),math.cos(a)*.4,.65,math.sin(a)*.4,n%2==0 and orange or Color3.fromRGB(227,140,44)) end;top=1.35
  elseif id=="Starberry" then
   p("PinkBerry",Vector3.new(1.1,1.2,1.1),0,.6,0,Color3.fromRGB(223,90,146));top=1.25
   for n=1,5 do local a=n*math.pi*2/5;local ray=p("StarPoint",Vector3.new(.11,.32,.06),math.sin(a)*.12,.6+math.cos(a)*.12,-.54,Color3.fromRGB(255,225,148),Enum.PartType.Block);ray.CFrame*=CFrame.Angles(0,0,-a) end
  else
   p("MintMelon",Vector3.new(1.6,1.3,1.45),0,.65,0,Color3.fromRGB(167,220,211));top=1.32
   -- A fine pale crescent on the fruit, assembled from five rounded segments.
   for n=0,5 do local a=math.rad(55+n*50);p("Crescent",Vector3.new(.12,.14,.08),math.cos(a)*.28,.68+math.sin(a)*.28,-.713,Color3.fromRGB(250,247,193)) end
  end
  p("Stem",Vector3.new(.18,.4,.18),0,top+.08,0,green,Enum.PartType.Cylinder).CFrame*=CFrame.Angles(0,0,math.rad(90))
  for n=1,3 do local a=n*math.pi*2/3;local leaf=p("Leaf",Vector3.new(.18,.12,.7),math.sin(a)*.22,top+.12,math.cos(a)*.22,green);leaf.CFrame*=CFrame.Angles(.2,a,.2) end
  m.WorldPivot=CFrame.new()
  m:SetAttribute("Source",CROP_SOURCE)
 end
 -- Keep magical details facing the plot fronts, including templates saved by an earlier build.
 for _,id in ipairs({"Starberry","Moonmelon"}) do
  local model=crops:FindFirstChild(id)
  if model and model:GetAttribute("Source")==CROP_SOURCE then
   for _,v in ipairs(model:GetDescendants()) do
    if v:IsA("BasePart") and (v.Name=="StarPoint" or v.Name=="Crescent") and v.Position.Z<0 then
     v.CFrame=CFrame.new(v.Position.X,v.Position.Y,-v.Position.Z)*v.CFrame.Rotation
    end
   end
  end
 end
 -- Imported crop templates can use any internal mesh names. Lighting is
 -- optional; an empty template cannot prevent all Garden plots initializing.
 local melonModel=crops:FindFirstChild("Moonmelon")
 local melon=effectPart(melonModel,"MintMelon")
 if melon and not melonModel:FindFirstChild("MoonGlow",true) then local light=Instance.new("PointLight");light.Name="MoonGlow";light.Brightness=.12;light.Range=2;light.Shadows=false;light.Color=Color3.fromRGB(183,231,224);light.Parent=melon end
 local berryModel=crops:FindFirstChild("Starberry")
 local berry=effectPart(berryModel,"PinkBerry")
 if berry and not berryModel:FindFirstChild("StarSparkle",true) then
  local a=Instance.new("Attachment");a.Name="StarSparkle";a.Position=Vector3.new(0,.4,0);a.Parent=berry
  local e=Instance.new("ParticleEmitter");e.Texture="rbxasset://textures/particles/sparkles_main.dds";e.Rate=.3;e.Lifetime=NumberRange.new(.6,.8);e.Speed=NumberRange.new(.15,.3);e.Size=NumberSequence.new(.08);e.Color=ColorSequence.new(Color3.fromRGB(255,226,166));e.LightEmission=.2;e.Parent=a
 end
 return crops
end
local function ownerSign(plot,player)
 local sign=plot:FindFirstChild("PlotSign");if not sign then return end
 local gui=sign:FindFirstChild("PlotSignGui")
 if gui then
  local label=gui:FindFirstChildWhichIsA("TextLabel",true)
  if label then label.Text=player and (player.DisplayName.."'s Garden\n@"..player.Name) or "AVAILABLE GARDEN";label.TextScaled=true;label.TextColor3=Color3.fromRGB(255,245,209) end
 end
 for _,g in ipairs(sign:GetChildren()) do if g.Name=="PlotStatusBillboard" then g:Destroy() end end
end
function Runtime.Prepare()
 Runtime.BuildCrops()
 local realm=workspace:FindFirstChild("PetGardenRealm");if not realm then warn("[Garden] Authored realm missing");return end
 local playerPlots=Locator.getPlots();local count=0
 for _,p in ipairs(realm:GetChildren()) do if p.Name:match("^GardenPlot%d+$") then count+=1 end end
 assert(count==#playerPlots,string.format("Garden plot count %d must match actual player plots %d",count,#playerPlots))
 -- Resolve by the same PlotId number used by Assign, never by list position.
 -- Validate the full mapping before changing any existing ownership display.
 local mapped={}
 for _,playerPlot in ipairs(playerPlots) do
  local index=plotNumber(playerPlot.Name)
  assert(index and not mapped[index],"Player plot has a missing or duplicate numeric PlotId: "..playerPlot.Name)
  local plot=realm:FindFirstChild("GardenPlot"..index)
  assert(plot and plot:IsA("Model"),"Matching Garden plot missing for "..playerPlot.Name)
  local soil=plot:FindFirstChild("SoilBase")
  assert(soil and soil:IsA("BasePart"),"Garden soil missing for "..playerPlot.Name)
  mapped[index]=plot
 end
 Runtime.Plots={}
 for _,playerPlot in ipairs(playerPlots) do
  local index=plotNumber(playerPlot.Name)
  local plot=mapped[index]
  Runtime.Plots[index]=plot;plot:SetAttribute("OwnerUserId",0);plot:SetAttribute("GardenPlotNumber",index);ownerSign(plot,nil)
  local soil=plot:FindFirstChild("SoilBase");assert(soil,"Garden soil missing")
  for _,v in ipairs(plot:GetChildren()) do
   if v:IsA("BasePart") and v:GetAttribute("AKGeneratedGardenMarker")==true then
    v.Transparency=1;v.CanCollide=false;v.CanQuery=false;v.CanTouch=false
   end
  end
  for slot=1,3 do
   local area=folder(plot,"ForageSlot_"..slot,"Model");area:SetAttribute("SlotId",slot);area:SetAttribute("VisualState","")
   local origin=soil.CFrame*CFrame.new((slot-2)*9,soil.Size.Y/2+.1,0)
   placementMarker(area,"PetAnchor",origin)
   local offsets={Vector3.new(-2.5,0,-7),Vector3.new(2.5,0,-4),Vector3.new(-2.5,0,0),Vector3.new(2.5,0,4),Vector3.new(-2.5,0,8)}
   for i,offset in ipairs(offsets) do placementMarker(area,"CropNode_"..i,origin*CFrame.new(offset)) end
   local plaque=area:FindFirstChild("SlotMarker") or part(area,"SlotMarker",Vector3.new(4,.14,1.5),origin*CFrame.new(0,.06,10),Color3.fromRGB(142,112,71))
   if not area:FindFirstChild("HarvestBasket") then
    local basket=folder(area,"HarvestBasket","Model");local basketCF=origin*CFrame.new(2.8,.1,9.7);local wood=Color3.fromRGB(156,113,67)
    part(basket,"Base",Vector3.new(1.1,.12,.8),basketCF,wood).Material=Enum.Material.Wood
    for _,x in ipairs({-.55,.55}) do part(basket,"BasketSide",Vector3.new(.12,.6,.85),basketCF*CFrame.new(x,.32,0),wood).Material=Enum.Material.Wood end
    for _,z in ipairs({-.4,.4}) do part(basket,"BasketSide",Vector3.new(1.1,.6,.12),basketCF*CFrame.new(0,.32,z),wood).Material=Enum.Material.Wood end
   end
   local board=folder(plaque,"SlotStatus","BillboardGui");board.Size=UDim2.fromOffset(130,34);board.StudsOffsetWorldSpace=Vector3.new(0,1.3,0);board.MaxDistance=70;board.AlwaysOnTop=false
   local label=folder(board,"Text","TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=.18;label.BackgroundColor3=Color3.fromRGB(49,78,47);label.TextColor3=Color3.fromRGB(255,245,211);label.Font=Enum.Font.GothamBold;label.TextSize=12;label.Text="SLOT "..slot.." · AVAILABLE"
  end
 end
 print("[Garden] Ready: "..count.." matching plots; 3 forage slots each")
end
function Runtime.Assign(player)
 local existing=Runtime.Assignments[player];if existing and existing.Parent then return existing end
 local n=plotNumber(player:GetAttribute("PlotId"))
 if not n then return end
 local plot=Runtime.Plots[n]
 if plot and (plot:GetAttribute("OwnerUserId") or 0)==0 then
  Runtime.Assignments[player]=plot;plot:SetAttribute("OwnerUserId",player.UserId);plot:SetAttribute("OwnerName",player.DisplayName)
  player:SetAttribute("GardenPlotId",n);ownerSign(plot,player);return plot
 end
end
function Runtime.Release(player)
 local plot=Runtime.Assignments[player];Runtime.Assignments[player]=nil;player:SetAttribute("GardenPlotId",nil)
 if plot then
  plot:SetAttribute("OwnerUserId",0);plot:SetAttribute("OwnerName","");ownerSign(plot,nil)
  for i=1,3 do local slot=plot:FindFirstChild("ForageSlot_"..i);if slot then slot:SetAttribute("VisualState","");slot.SlotMarker.SlotStatus.Text.Text="SLOT "..i.." · AVAILABLE" end end
 end
end
function Runtime.Sync(player,data,now)
 local plot=Runtime.Assign(player);if not plot then return end
 local used={}
 for _,trip in ipairs(data.GardenExpeditions) do
  local pet
  for _,candidate in ipairs(data.Pets) do if candidate.UID==trip.UID then pet=candidate;break end end
  local slot=plot:FindFirstChild("ForageSlot_"..tostring(trip.SlotId))
  if slot and pet and trip.ForagingVersion==1 then
   used[trip.SlotId]=true
   local ready=now>=trip.ReadyAt
   local state={TripId=trip.TripId,Pet={UID=pet.UID,PetId=pet.PetId,Level=pet.Level,Mutation=pet.Mutation,Shiny=pet.Shiny,Prismatic=pet.Prismatic,Cosmetic=pet.Cosmetic,Weight=pet.Weight,CoinsPerSecond=pet.CoinsPerSecond},Ready=ready,Next=Progress.Next(trip,now),Last=trip.LastHarvest,Seed=trip.Seed}
   slot:SetAttribute("VisualState",Http:JSONEncode(state))
   slot.SlotMarker.SlotStatus.Text.Text=ready and "READY!" or "SLOT "..trip.SlotId.." · FORAGING"
  end
 end
 for i=1,3 do if not used[i] then local slot=plot["ForageSlot_"..i];slot:SetAttribute("VisualState","");slot.SlotMarker.SlotStatus.Text.Text="SLOT "..i.." · AVAILABLE" end end
end
return Runtime
