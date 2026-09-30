-- These adapters execute production modules. They do not simulate physics:
-- teleport cases verify delegation/fallback/state, leaving clearance to the
-- established Teleports.Near helper and actual Studio Play testing.
local vectorMeta={}
local function vector(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectorMeta) end
function vectorMeta.__add(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function vectorMeta.__sub(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function vectorMeta.__index(a,key)
 if key=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
end
local frameMeta={}
local function frame(x,y,z,yaw)
 local position=type(x)=="table" and x or vector(x,y,z)
 return setmetatable({Position=position,Yaw=yaw or 0},frameMeta)
end
function frameMeta.__index(a,key)
 if key=="Rotation" then return frame(0,0,0,a.Yaw) end
 if key=="VectorToWorldSpace" then return function(self,v)
  local c,s=math.cos(self.Yaw),math.sin(self.Yaw)
  return vector(v.X*c+v.Z*s,v.Y,-v.X*s+v.Z*c)
 end end
end
function frameMeta.__mul(a,b) return frame(a.Position+a:VectorToWorldSpace(b.Position),nil,nil,a.Yaw+b.Yaw) end
local function near(a,b) return (a-b).Magnitude<1e-5 end
local methods={}
local function instance(class,name,parent)
 local value=setmetatable({ClassName=class,Name=name or class,children={},attributes={},Position=vector(),Size=vector(1,1,1),CFrame=frame(),Transparency=0,CanCollide=true,CanTouch=true,CanQuery=true}, {
  __index=function(self,key)
   if methods[key] then return methods[key] end
   for _,child in ipairs(self.children) do if child.Name==key then return child end end
  end,
  __newindex=function(self,key,value)
   if key=="Parent" and value then table.insert(value.children,self) end
   rawset(self,key,value)
  end,
 })
 value.Parent=parent
 return value
end
function methods:IsA(class)
 return self.ClassName==class or class=="BasePart" and (self.ClassName=="Part" or self.ClassName=="MeshPart" or self.ClassName=="SpawnLocation")
end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants()
 local result={}
 local function visit(parent) for _,child in ipairs(parent.children) do table.insert(result,child);visit(child) end end
 visit(self);return result
end
function methods:FindFirstChild(name,recursive)
 for _,child in ipairs(recursive and self:GetDescendants() or self.children) do if child.Name==name then return child end end
end
function methods:FindFirstChildWhichIsA(class,recursive)
 for _,child in ipairs(recursive and self:GetDescendants() or self.children) do if child:IsA(class) then return child end end
end
function methods:GetAttribute(name) return self.attributes[name] end
function methods:SetAttribute(name,value) self.attributes[name]=value end
function methods:GetFullName() return self.Name end
function methods:Destroy() self.destroyed=true end

local storage=instance("ReplicatedStorage","ReplicatedStorage")
storage.Shared={Gameplay={GardenProgress="Progress",Definitions={GardenDefinitions="Garden",PetDefinitions="Pets",VariantDefinitions="Variants"},PetMath="PetMath",PetAppearance="Appearance"}}
storage.Packages={Knit="Knit"}
local server={PlotLocator="Locator",AdminCommandCenter={Teleports="Teleports"}}
local world=instance("Workspace","Workspace")
local realm=instance("Model","PetGardenRealm",world)
local assets=instance("Folder","GardenAssets",storage)
local crops=instance("Folder","Crops",assets)
for _,id in ipairs({"Carrot","Tomato","Pumpkin","Starberry","Moonmelon"}) do
 local crop=instance("Model",id,crops)
 local mesh=instance("MeshPart",id=="Starberry" and "StarPoint" or "ImportedMesh",crop)
 mesh.Position=vector(0,0,-2);mesh.CFrame=frame(mesh.Position)
end
local playerPlots={}
local function makePlot(id,yaw)
 local playerPlot=instance("Part","Plot"..id.."Floor")
 table.insert(playerPlots,playerPlot)
 local plot=instance("Model","GardenPlot"..id,realm)
 local soil=instance("Part","SoilBase",plot);soil.Size=vector(40,1,30);soil.CFrame=frame(1000,0,id*40,yaw)
 local sign=instance("Part","PlotSign",plot);sign.Position=vector(1000,1,id*40-16)
 sign.CFrame=frame(sign.Position,nil,nil,math.pi)
 local pad=instance("Part","PetPad",plot);pad.Size=vector(5,2,5)
 local cropAnchor=instance("Part","CropAnchor1",plot);cropAnchor.Size=vector(2,1,2)
 local known=instance("Part","VerifiedLocator",plot);known:SetAttribute("AKGeneratedGardenMarker",true)
 return plot,playerPlot
end
local plot1,playerPlot1=makePlot(1)
local plot3,playerPlot3=makePlot(3,math.pi/2)
local services={}
local values={
 Locator={getPlots=function() return playerPlots end},Progress={},Garden={RealmCenter=vector(1000,0,100)},Pets={},Variants={},PetMath={},Appearance={},
 Knit={CreateService=function(s) return s end,GetService=function(name) return assert(services[name],name) end},
 Guard={IsPlayer=function(player) return player~=nil end,Alive=function(player) return player.Root end},
}
local env=setmetatable({
 game={ServerScriptService=server,GetService=function(_,name)
  if name=="ReplicatedStorage" then return storage elseif name=="ServerScriptService" then return server else return {} end
 end},workspace=world,require=function(key) return assert(values[key],tostring(key)) end,
 Instance={new=function(class) return instance(class) end},Vector3={new=vector,one=vector(1,1,1)},
 CFrame={new=frame,Angles=function(_,yaw) return frame(0,0,0,yaw) end,lookAt=function(position) return frame(position) end},
 Color3={new=function() return {} end,fromRGB=function() return {} end},
 UDim2={fromOffset=function() return {} end,fromScale=function() return {} end},
 Enum={Material={SmoothPlastic=1,Wood=2},Font={GothamBold=1},PartType={}},
 NumberRange={new=function() return {} end},NumberSequence={new=function() return {} end},ColorSequence={new=function() return {} end},
 print=function() end,
 script={Parent={Parent={Utilities={GameplayGuard="Guard",GardenPlotRuntime="Runtime"}}}},
},{__index=getfenv()})
local function load(name)
 local fn=assert(loadstring(sources[name],name));setfenv(fn,env);return fn()
end
local Runtime=load("Runtime");values.Runtime=Runtime
local berry=crops.Starberry.StarPoint;local berryFrame=berry.CFrame
Runtime.Prepare()
assert(Runtime.Plots[1]==plot1 and Runtime.Plots[3]==plot3 and Runtime.Plots[2]==nil,"Noncontiguous plot IDs were mapped by list position")
assert(plot1.PetPad.CanCollide and plot1.PetPad.Transparency==0,"Authored PetPad was hidden or made noncolliding")
assert(plot1.CropAnchor1.CanCollide and plot1.CropAnchor1.Transparency==0,"Authored CropAnchor was modified by its name")
assert(plot1.VerifiedLocator.Transparency==1 and not plot1.VerifiedLocator.CanCollide,"Explicit placement marker was not made inert")
assert(plot1.ForageSlot_1.PetAnchor:GetAttribute("AKGeneratedGardenMarker")==true,"Generated markers lack provenance")
assert(berry.CFrame==berryFrame,"Imported crop was reoriented")
assert(berry:FindFirstChild("StarSparkle") and crops.Moonmelon.ImportedMesh:FindFirstChild("MoonGlow"),"Generic imported crop parts did not receive optional effects")
Runtime.Prepare()
assert(#berry:GetChildren()==1,"Repeated preparation duplicated optional crop effects")
print("PASS Garden layout: numeric mapping, authored geometry preserved, marker provenance, generic crop effects, idempotence")

local function player(id,plotId)
 local p=instance("Player","Player"..id);p.UserId=id;p.DisplayName=p.Name;p.Root={CFrame=frame(0,4,0),Position=vector(0,4,0)}
 p:SetAttribute("PlotId",plotId);return p
end
local p1,p3=player(1,"Plot1Floor"),player(3,"Plot3Floor")
assert(Runtime.Assign(p1)==plot1 and Runtime.Assign(p3)==plot3,"Player assignment did not match its physical PlotId")
assert(not Runtime.Assign(player(4,"Plot3Floor")),"Second player took an occupied Garden")
assert(p3:GetAttribute("GardenPlotId")==3,"GardenPlotId used sorted position")
Runtime.Release(p3)
assert(plot3:GetAttribute("OwnerUserId")==0 and p3:GetAttribute("GardenPlotId")==nil,"Garden release left ownership state")
assert(Runtime.Assign(p3)==plot3,"Released Garden cannot be reassigned")
print("PASS Garden ownership: matching noncontiguous ID, no cross-owner assignment, release and reassignment")

-- Preserve the current four consecutive IDs, and ensure invalid layouts fail
-- before changing owner attributes on otherwise valid plots.
local plot2=makePlot(2);local plot4=makePlot(4)
Runtime.Prepare()
for id=1,4 do assert(Runtime.Plots[id]==realm:FindFirstChild("GardenPlot"..id)) end
plot1:SetAttribute("OwnerUserId",99)
local originalName=playerPlots[4].Name;playerPlots[4].Name="Plot1"
local valid=pcall(Runtime.Prepare)
assert(not valid and plot1:GetAttribute("OwnerUserId")==99,"Invalid duplicate plot IDs partially reset owners")
playerPlots[4].Name=originalName
Runtime.Prepare();Runtime.Assignments={};Runtime.Assign(p3)
print("PASS Garden mapping: existing four plots retained; duplicate IDs rejected before owner reset")

local calls,results={},{}
values.Teleports={Near=function(p,anchor)
 table.insert(calls,anchor)
 local success=table.remove(results,1)==true
 if success then p.Root.Position=anchor.Position;p.Root.CFrame=anchor end
 return success,"TEST BLOCKED LANDING"
end}
local spawn=instance("Part","PlotSpawn",playerPlot3);spawn.CFrame=frame(50,2,50)
services.PlotService={GetPlot=function() return playerPlot3 end}
local arrival=instance("Part","GardenArrival",realm);arrival.Position=vector(1000,2,145)
arrival.CFrame=frame(arrival.Position)
local Service=load("Service")
local originalReturn=p3.Root.CFrame
results={false,true}
local ok,response=Service:VisitGarden(p3)
assert(ok and response.Kind=="GardenVisit" and p3:GetAttribute("InGarden"),"Garden fallback landing failed")
local expected=plot3.PlotSign.Position+plot3.SoilBase.CFrame.Rotation:VectorToWorldSpace(vector(7,2,5))
assert(near(calls[1].Position,expected),"Garden approach ignores bed orientation")
assert(near(calls[2].Position,arrival.Position),"Blocked plot approach did not try Garden arrival")
calls={};results={false,false}
ok=Service:ReturnToKingdom(p3)
assert(not ok and p3:GetAttribute("InGarden"),"Failed return incorrectly cleared Garden state")
assert(calls[1]==originalReturn and calls[2]==spawn.CFrame,"Return did not try saved position then owned plot")
calls={};results={true}
ok,response=Service:ReturnToKingdom(p3)
assert(ok and response.Kind=="GardenReturn" and not p3:GetAttribute("InGarden"),"Safe retry did not return")
assert(calls[1]==originalReturn,"Failed return discarded original return location")
calls={};results={false,false}
local before=p3.Root.CFrame
ok,response=Service:VisitGarden(p3)
assert(not ok and p3.Root.CFrame==before and not p3:GetAttribute("InGarden"),"Blocked Garden visit moved player or changed state")
assert(not string.find(response,"TEST BLOCKED LANDING",1,true),"Internal landing error leaked to player")
calls={};results={true}
Service:ReturnToKingdom(p3)
assert(calls[1]==spawn.CFrame,"Failed visit saved a return position despite not moving")
print("PASS Garden travel: safe-landing delegation, rotated approach, arrival fallback, failure state retained, retry succeeds, friendly error")
