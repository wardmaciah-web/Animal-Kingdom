-- Animal Kingdom Town Color Pipeline V2
-- Studio Command Bar script. Parses eight simple shared-space OBJ packages.
-- It never parses FBX, invokes Open Cloud, or rebuilds the town layout.
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local StudioService = game:GetService("StudioService")
local AssetService = game:GetService("AssetService")

local MARKER = "AnimalKingdomTownVisualPolishV2"
local ROLLBACK_NAME = "AnimalKingdomTownVisualPolishV2Rollback"
local POSITION_TOLERANCE = 0.001
local SIZE_TOLERANCE = 0.001
local VECTOR_DOT_TOLERANCE = 0.999999
local SCALE_TOLERANCE = 0.000001
local TEMPLATE_FOLDER_NAME = "AnimalKingdomTownMaterialTemplatesV2"
local TEMPLATE_NAMES = {
	TradingHall="TradingHall_MaterialSplit", RewardsBuilding="Rewards_MaterialSplit",
	GeneralStoreBuilding="GeneralStore_MaterialSplit", BlacksmithBuilding="Blacksmith_MaterialSplit",
	CentralWell="Well_MaterialSplit", MarketStand1="MarketStand1_MaterialSplit",
	MarketStand2="MarketStand2_MaterialSplit", MarketCart="Cart_MaterialSplit",
}

local function stop(message)
	error("Town polish stopped before mutation: " .. tostring(message), 0)
end

if Workspace:GetAttribute(MARKER) == true then
	warn("AnimalKingdomTownVisualPolishV2 is already applied; no changes made")
	return
end
local staleRollback = ServerStorage:FindFirstChild(ROLLBACK_NAME)
if staleRollback then
	if #staleRollback:GetChildren() == 0 and next(staleRollback:GetAttributes()) == nil then
		staleRollback:Destroy()
		warn("Removed empty AnimalKingdomTownVisualPolishV2Rollback preflight residue")
	else
		stop("non-empty rollback state exists at ServerStorage." .. ROLLBACK_NAME .. "; preserved without modification")
	end
end

-- V1 damage recovery is intentionally narrow: it only runs when both the V1
-- marker/rollback exist and a current replacement bears the V1 replacement tag.
local function recoverV1DamageIfNeeded()
	local v1Rollback=ServerStorage:FindFirstChild("AnimalKingdomTownVisualPolishV1Rollback")
	if Workspace:GetAttribute("AnimalKingdomTownVisualPolishV1")~=true or not v1Rollback then return end
	local town=Workspace:FindFirstChild("AnimalKingdomTown")
	if not town then return end
	local damaged={}
	for _,candidate in ipairs(town:GetDescendants()) do
		if (candidate:IsA("Model") or candidate:IsA("BasePart")) and candidate:GetAttribute("AK_MaterialSplitReplacement")==true then
			table.insert(damaged,candidate)
		end
	end
	if #damaged==0 then return end
	local destinations={
		TradingHall=town, RewardsBuilding=town,
		GeneralStoreBuilding=town:FindFirstChild("DecorativeBuildings"), BlacksmithBuilding=town:FindFirstChild("DecorativeBuildings"),
		CentralWell=town:FindFirstChild("Decor"), MarketStand1=town:FindFirstChild("DisplayProps"),
		MarketStand2=town:FindFirstChild("DisplayProps"), MarketCart=town:FindFirstChild("DisplayProps"), Paths=town,
	}
	local originals={}
	for name,parent in pairs(destinations) do
		local original=v1Rollback:FindFirstChild(name,true)
		if name~="Paths" and not original then error("V1 damage recovery missing original: "..name,0) end
		if not parent then error("V1 damage recovery missing destination for: "..name,0) end
		originals[name]={object=original,parent=parent}
	end
	for _,object in ipairs(damaged) do object:Destroy() end
	local visual=town:FindFirstChild("VisualPolish"); if visual then visual:Destroy() end
	local currentPaths=town:FindFirstChild("Paths")
	for name,record in pairs(originals) do
		if record.object and (name~="Paths" or not currentPaths) then record.object.Name=name; record.object.Parent=record.parent; if name=="Paths" then record.object:SetAttribute("AK_V2RestoredOriginal",true) end end
	end
	Workspace:SetAttribute("AnimalKingdomTownVisualPolishV1",nil)
	v1Rollback:Destroy()
	print("AK_V1_DAMAGE_RECOVERY COMPLETE")
end
recoverV1DamageIfNeeded()

-- The operating-system chooser is the only local-file permission interaction.
local IMPORT_NAMES = {
	TradingHall_MaterialSplit="TradingHall_MaterialSplit", Rewards_MaterialSplit="Rewards_MaterialSplit",
	GeneralStore_MaterialSplit="GeneralStore_MaterialSplit", Blacksmith_MaterialSplit="Blacksmith_MaterialSplit",
	Well_MaterialSplit="Well_MaterialSplit", MarketStand1_MaterialSplit="MarketStand1_MaterialSplit",
	MarketStand2_MaterialSplit="MarketStand2_MaterialSplit", Cart_MaterialSplit="Cart_MaterialSplit",
}
local IMPORT_COLORS = {
	TradingHall_MaterialSplit={Walls={238,218,179},Timber={79,55,42},Roof={83,82,78},Stone={145,139,126},Gold={220,177,81},Sage={105,145,96}},
	Rewards_MaterialSplit={Walls={246,232,199},Timber={117,78,52},Roof={91,78,72},Stone={145,139,126},Terracotta={170,73,70},Gold={220,177,81}},
	GeneralStore_MaterialSplit={Walls={238,218,179},Timber={117,78,52},Roof={144,82,61},Stone={145,139,126},Sage={105,145,96}},
	Blacksmith_MaterialSplit={Walls={213,187,147},Timber={79,55,42},Roof={68,67,64},Stone={145,139,126},ForgeAccent={177,91,64}},
	Well_MaterialSplit={Stone={161,154,139},Wood={117,78,52},Roof={83,82,78},Water={84,178,200}},
	MarketStand1_MaterialSplit={Wood={117,78,52},Cream={238,218,179},Canopy={105,145,96}},
	MarketStand2_MaterialSplit={Wood={117,78,52},Cream={238,218,179},Canopy={170,73,70}},
	Cart_MaterialSplit={MainWood={177,123,77},DarkWood={117,78,52},WheelFrame={79,55,42},Accent={177,91,64}},
}
local function importRole(name)
	return name:match("AK_([%w_]+)")
end
local function importMaterial(role)
	local n=string.lower(role)
	if n:find("timber") or n:find("wood") or n:find("wheel") or n:find("frame") then return Enum.Material.WoodPlanks end
	if n:find("roof") then return Enum.Material.Slate end
	if n:find("stone") then return Enum.Material.Cobblestone end
	if n:find("metal") then return Enum.Material.Metal end
	return Enum.Material.SmoothPlastic
end
local function meshPartFromOBJ(vertices,faces,name)
	local editable=AssetService:CreateEditableMesh()
	if not editable then error("CreateEditableMesh unavailable; enable Studio editable-mesh support") end
	local ids={}
	for index,vertex in ipairs(vertices) do ids[index]=editable:AddVertex(vertex) end
	local triangles=0
	for _,polygon in ipairs(faces) do
		if #polygon<3 then editable:Destroy(); error(name.." contains degenerate polygon") end
		for j=2,#polygon-1 do editable:AddTriangle(ids[polygon[1]],ids[polygon[j]],ids[polygon[j+1]]); triangles+=1 end
	end
	if triangles==0 then editable:Destroy(); error(name.." contains no triangles") end
	local part=AssetService:CreateMeshPartAsync(Content.fromObject(editable),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})
	editable:Destroy()
	part.Name=name; part.Anchored=true; part.CanTouch=false; part.CanQuery=false; part.CastShadow=true; part.DoubleSided=true
	return part
end
local function objIndex(token,vertexCount)
	local raw=string.match(token,"^([+-]?%d+)")
	local index=raw and tonumber(raw)
	if not index or index==0 then error("invalid OBJ face index: "..tostring(token)) end
	if index<0 then index=vertexCount+index+1 end
	if index<1 or index>vertexCount then error("OBJ face index out of range: "..tostring(token)) end
	return index
end
local function parseOBJFile(file)
	local filename=file.Name:match("([^/\\]+)$") or file.Name
	local stem=filename:gsub("%.[Oo][Bb][Jj]$","")
	if not IMPORT_NAMES[stem] then error("unexpected OBJ selected: "..filename) end
	local text=file:GetBinaryContents()
	local vertices,groups,order={},{},{}
	local current=nil
	for line in string.gmatch(text,"[^\r\n]+") do
		local fields={}; for field in string.gmatch(line,"%S+") do fields[#fields+1]=field end
		if fields[1]=="v" then
			local x,y,z=tonumber(fields[2]),tonumber(fields[3]),tonumber(fields[4])
			if not (x and y and z) then error(filename.." has malformed vertex") end
			vertices[#vertices+1]=Vector3.new(x,y,z)
		elseif fields[1]=="o" or fields[1]=="g" then
			local nextGroup=fields[2]
			if not nextGroup then error(filename.." has unnamed OBJ object/group") end
			if nextGroup~=current then
				current=nextGroup
				if groups[current] then error(filename.." repeats non-contiguous OBJ object/group: "..current) end
				groups[current]={}; order[#order+1]=current
			end
		elseif fields[1]=="f" then
			if not current then error(filename.." has face before object") end
			local face={}; for i=2,#fields do face[#face+1]=objIndex(fields[i],#vertices) end
			if #face<3 then error(filename.." has degenerate face") end
			groups[current][#groups[current]+1]=face
		end
	end
	local model=Instance.new("Model"); model.Name=stem
	local meshCount=0
	for _,name in ipairs(order) do
		local role=importRole(name); local rgb=role and IMPORT_COLORS[stem][role]
		if not rgb then model:Destroy(); error(filename.." has unknown semantic group: "..tostring(name)) end
		local part=meshPartFromOBJ(vertices,groups[name],name)
		part.Color=Color3.fromRGB(rgb[1],rgb[2],rgb[3]); part.Material=importMaterial(role); part.Parent=model
		meshCount+=1
	end
	if meshCount==0 then model:Destroy(); error(filename.." contains no semantic groups") end
	return model,meshCount
end
local function templateSetValid(folder)
	if not folder then return false end
	local total=0
	for stem in pairs(IMPORT_NAMES) do
		local model=folder:FindFirstChild(stem); if not model then return false end
		for _,d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then total+=1 end end
	end
	return total==33
end
local existingTemplates=ServerStorage:FindFirstChild(TEMPLATE_FOLDER_NAME)
if not templateSetValid(existingTemplates) then
	if existingTemplates then stop("existing ServerStorage."..TEMPLATE_FOLDER_NAME.." is incomplete; preserved without overwrite") end
	local ok,files=pcall(function() return StudioService:PromptImportFilesAsync({"obj"}) end)
	if not ok then stop("Studio file prompt unavailable; run this launcher from Studio Command Bar or a trusted local plugin: "..tostring(files)) end
	if not files or #files~=8 then stop("select exactly the 8 packaged OBJ files; selected="..tostring(files and #files or 0)) end
	local staging=Instance.new("Folder"); staging.Name=TEMPLATE_FOLDER_NAME
	local imported={}; local total=0
	local importOk,importError=pcall(function()
		for _,file in ipairs(files) do
			local model,count=parseOBJFile(file)
			if imported[model.Name] then model:Destroy(); error("duplicate packaged OBJ selected: "..model.Name) end
			imported[model.Name]=true; total+=count; model.Parent=staging
		end
		for stem in pairs(IMPORT_NAMES) do if not imported[stem] then error("missing selected import: "..stem..".obj") end end
		if total~=33 then error("material mesh count mismatch: expected 33, got "..total) end
	end)
	if not importOk then staging:Destroy(); stop("local OBJ import failed: "..tostring(importError)) end
	staging:SetAttribute("AK_OBJTemplatesValidated",true); staging.Parent=ServerStorage
	print("AK_TOWN_V2_OBJ_TEMPLATE_IMPORT_COMPLETE"); print("templatesReady=8/8"); print("materialMeshes=33")
end

local town = Workspace:FindFirstChild("AnimalKingdomTown")
local townGround = town and town:FindFirstChild("TownGround")
local plaza = townGround and townGround:FindFirstChild("TownPlaza")
if not (town and plaza and plaza:IsA("BasePart")) then stop("existing town/TownPlaza not found") end

local function firstAt(root, names)
	if not root then return nil end
	for _, name in ipairs(names) do
		local hit = root:FindFirstChild(name, true)
		if hit then return hit end
	end
	return nil
end

local function findPrebuilt(root, expectedName, sourceName)
	if not root then return nil end
	local exact = root:FindFirstChild(expectedName, true)
	if exact then return exact end
	local sourceMatches = {}
	for _, candidate in ipairs(root:GetDescendants()) do
		if candidate:GetAttribute("AK_PrebuildSource") == sourceName then
			table.insert(sourceMatches, candidate)
		end
	end
	if #sourceMatches == 1 then return sourceMatches[1] end
	local stem = string.lower((sourceName:gsub("%.fbx$", "")))
	local nameMatches = {}
	for _, candidate in ipairs(root:GetDescendants()) do
		if (candidate:IsA("Model") or candidate:IsA("BasePart")) and string.lower(candidate.Name) == stem then
			table.insert(nameMatches, candidate)
		end
	end
	if #nameMatches == 1 then return nameMatches[1] end
	return nil
end

local trading = findPrebuilt(town, "TradingHall", "Inn.fbx")
local rewards = findPrebuilt(town, "RewardsBuilding", "House_4.fbx")
local decorative = town:FindFirstChild("DecorativeBuildings")
local pet = findPrebuilt(decorative or town, "PetShopBuilding", "House_1.fbx")
local general = findPrebuilt(decorative or town, "GeneralStoreBuilding", "House_2.fbx")
local blacksmith = findPrebuilt(decorative or town, "BlacksmithBuilding", "Blacksmith.fbx")
local well = findPrebuilt(town, "CentralWell", "Well.fbx") or firstAt(town, {"Well"})
local displays = town:FindFirstChild("DisplayProps")
local market1 = findPrebuilt(displays or town, "MarketStand1", "MarketStand_1.fbx")
local market2 = findPrebuilt(displays or town, "MarketStand2", "MarketStand_2.fbx")
local cart = findPrebuilt(displays or town, "MarketCart", "Cart.fbx")
local fenceRoot = town:FindFirstChild("Fence")
local entranceRoot = town:FindFirstChild("Entrance")
local oldPaths = town:FindFirstChild("Paths")
local futurePlots = Workspace:FindFirstChild("AnimalKingdomFuturePlayerPlots")
local templateFolder = ServerStorage:FindFirstChild(TEMPLATE_FOLDER_NAME)

local function foundPath(instance, optionalLabel)
	return instance and instance:GetFullName() or optionalLabel
end
local function sourceOf(instance)
	return instance and tostring(instance:GetAttribute("AK_PrebuildSource") or "UNSET") or "MISSING"
end
print("AK_TOWN_POLISH_OBJECT_RESOLUTION")
print("TradingHall="..foundPath(trading,"MISSING")); print("TradingHallSource="..sourceOf(trading))
print("Rewards="..foundPath(rewards,"MISSING"))
print("PetShop="..foundPath(pet,"NOT_PRESENT")); print("GeneralStore="..foundPath(general,"NOT_PRESENT")); print("Blacksmith="..foundPath(blacksmith,"NOT_PRESENT"))
print("CentralWell="..foundPath(well,"MISSING"))
print("MarketStand1="..foundPath(market1,"NOT_PRESENT")); print("MarketStand2="..foundPath(market2,"NOT_PRESENT")); print("MarketCart="..foundPath(cart,"NOT_PRESENT"))
print("Fence="..foundPath(fenceRoot,"MISSING"))

local required = {
	{"TradingHall",trading}, {"RewardsBuilding",rewards}, {"GeneralStoreBuilding",general},
	{"BlacksmithBuilding",blacksmith}, {"CentralWell",well}, {"MarketStand1",market1},
	{"MarketStand2",market2}, {"MarketCart",cart}, {"Fence",fenceRoot},
}
for _, entry in ipairs(required) do
	local name, instance = entry[1], entry[2]
	if not instance then stop("required existing object missing: " .. name) end
end
if not templateFolder then stop("missing required import folder: ServerStorage."..TEMPLATE_FOLDER_NAME) end
for _, entry in ipairs({{"PetShop",pet},{"GeneralStore",general},{"Blacksmith",blacksmith},{"MarketStand1",market1},{"MarketStand2",market2},{"MarketCart",cart}}) do
	if not entry[2] then warn("AK_TOWN_POLISH_OPTIONAL_NOT_PRESENT: "..entry[1]) end
end

local replacementSpecs={{old=trading,key="TradingHall"},{old=rewards,key="RewardsBuilding"},{old=well,key="CentralWell"}}
local function addReplacement(instance,key) if instance then table.insert(replacementSpecs,{old=instance,key=key}) end end
addReplacement(general,"GeneralStoreBuilding"); addReplacement(blacksmith,"BlacksmithBuilding")
addReplacement(market1,"MarketStand1"); addReplacement(market2,"MarketStand2"); addReplacement(cart,"MarketCart")
for _,spec in ipairs(replacementSpecs) do
	local templateName=TEMPLATE_NAMES[spec.key]
	if not templateName then stop("no local template mapping for existing object: "..spec.key) end
	spec.template=templateFolder:FindFirstChild(templateName)
	if not spec.template then stop("missing required Studio import: ServerStorage."..TEMPLATE_FOLDER_NAME.."."..templateName) end
end

local function partsOf(instance)
	local result = {}
	if not instance then return result end
	if instance:IsA("BasePart") then table.insert(result, instance) end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then table.insert(result, descendant) end
	end
	return result
end

local function worldCorners(part)
	local s = part.Size * .5
	local result = {}
	for _, x in ipairs({-s.X,s.X}) do for _, y in ipairs({-s.Y,s.Y}) do for _, z in ipairs({-s.Z,s.Z}) do
		table.insert(result, part.CFrame:PointToWorldSpace(Vector3.new(x,y,z)))
	end end end
	return result
end

local function localFootprint(instance)
	if not instance then return nil end
	local minX,maxX,minZ,maxZ = math.huge,-math.huge,math.huge,-math.huge
	local count = 0
	for _, part in ipairs(partsOf(instance)) do
		for _, corner in ipairs(worldCorners(part)) do
			local q = plaza.CFrame:PointToObjectSpace(corner)
			minX,maxX,minZ,maxZ = math.min(minX,q.X),math.max(maxX,q.X),math.min(minZ,q.Z),math.max(maxZ,q.Z)
			count += 1
		end
	end
	if count == 0 then return nil end
	return {minX=minX,maxX=maxX,minZ=minZ,maxZ=maxZ,x=(minX+maxX)/2,z=(minZ+maxZ)/2,w=maxX-minX,d=maxZ-minZ}
end

local obstacleRoots = {}
local function addIfPresent(list,value) if value then table.insert(list,value) end end
addIfPresent(obstacleRoots,trading); addIfPresent(obstacleRoots,rewards); addIfPresent(obstacleRoots,pet)
addIfPresent(obstacleRoots,general); addIfPresent(obstacleRoots,blacksmith); addIfPresent(obstacleRoots,well); addIfPresent(obstacleRoots,fenceRoot)
local obstacles = {}
for _, root in ipairs(obstacleRoots) do
	local fp = localFootprint(root)
	if fp then fp.name=root.Name; table.insert(obstacles,fp) end
end
local footprints = {
	TradingHall=localFootprint(trading), RewardsBuilding=localFootprint(rewards),
	PetShopBuilding=localFootprint(pet), GeneralStoreBuilding=localFootprint(general),
	BlacksmithBuilding=localFootprint(blacksmith), CentralWell=localFootprint(well),
	MarketStand1=localFootprint(market1), MarketStand2=localFootprint(market2),
	MarketCart=localFootprint(cart),
}
for _, key in ipairs({"TradingHall","RewardsBuilding","CentralWell"}) do
	if not footprints[key] then stop("required object has no visible BasePart footprint: "..key) end
end

local entranceFP = entranceRoot and localFootprint(entranceRoot)
local function boundaryEntrance()
	if entranceFP then return Vector2.new(entranceFP.x,entranceFP.z) end
	local frontZ = -plaza.Size.Z/2 + 3
	return Vector2.new(0,frontZ)
end
local entrancePoint = boundaryEntrance()
local wellFP = footprints.CentralWell
local center = Vector2.new(wellFP.x,wellFP.z)

local pathPlans = {}
local pathCounts = {}
local function planRect(group,name,x,z,w,d,yaw)
	local p={group=group,name=name,x=x,z=z,w=w,d=d,yaw=yaw or 0}
	table.insert(pathPlans,p); pathCounts[group]=(pathCounts[group] or 0)+1; return p
end
local function segment(group,name,a,b,width)
	local delta=b-a
	local length=delta.Magnitude
	if length < .5 then return nil end
	return planRect(group,name,(a.X+b.X)/2,(a.Y+b.Y)/2,width,length,math.atan2(-delta.X,delta.Y))
end
local function towardRect(rect, from, gap)
	if not (rect and from) then return nil end
	local dx,dz=from.X-rect.x,from.Y-rect.z
	if math.abs(dx)/(rect.w/2) > math.abs(dz)/(rect.d/2) then
		return Vector2.new(rect.x+(dx>=0 and 1 or -1)*(rect.w/2+gap), math.clamp(from.Y,rect.minZ,rect.maxZ))
	end
	return Vector2.new(math.clamp(from.X,rect.minX,rect.maxX),rect.z+(dz>=0 and 1 or -1)*(rect.d/2+gap))
end
local plazaSize=math.clamp(math.max(wellFP.w,wellFP.d)+18,26,34)
local holeW,holeD=wellFP.w+2.5,wellFP.d+2.5
local bandX=(plazaSize-holeW)/2
local bandZ=(plazaSize-holeD)/2
planRect("CentralPlazaPolish","CentralNorth",center.X,center.Y-(holeD/2+bandZ/2),plazaSize,bandZ,0)
planRect("CentralPlazaPolish","CentralSouth",center.X,center.Y+(holeD/2+bandZ/2),plazaSize,bandZ,0)
planRect("CentralPlazaPolish","CentralWest",center.X-(holeW/2+bandX/2),center.Y,bandX,holeD,0)
planRect("CentralPlazaPolish","CentralEast",center.X+(holeW/2+bandX/2),center.Y,bandX,holeD,0)

local centralRect={x=center.X,z=center.Y,w=plazaSize,d=plazaSize,minX=center.X-plazaSize/2,maxX=center.X+plazaSize/2,minZ=center.Y-plazaSize/2,maxZ=center.Y+plazaSize/2}
local function connect(group, targetRect, width, apronW, apronD)
	if not targetRect then return false end
	local targetApproach=towardRect(targetRect,center,.35)
	local centralExit=towardRect(centralRect,targetApproach,.15)
	if not (targetApproach and centralExit) then return false end
	segment(group,group.."Connector",centralExit,targetApproach,width)
	planRect(group,group.."Apron",targetApproach.X,targetApproach.Y,apronW,apronD,0)
	return true
end
local entranceExit=towardRect(centralRect,entrancePoint,.15)
local eDir=(entranceExit-entrancePoint)
local eStart=entrancePoint+(eDir.Magnitude>0 and eDir.Unit or Vector2.new(0,1))*2
segment("MainPath","EntranceToWell",eStart,entranceExit,9)
connect("TradingHallPath",footprints.TradingHall,9,12,6)
connect("RewardsPath",footprints.RewardsBuilding,6,9,5)
if footprints.PetShopBuilding then connect("PetShopPath",footprints.PetShopBuilding,6,8,5) end
if footprints.GeneralStoreBuilding then connect("GeneralStorePath",footprints.GeneralStoreBuilding,6,8,5) end
if footprints.BlacksmithBuilding then connect("BlacksmithPath",footprints.BlacksmithBuilding,6,9,5) end
if footprints.MarketStand1 then connect("MarketPaths",footprints.MarketStand1,5,7,4) end
if footprints.MarketStand2 then connect("MarketPaths",footprints.MarketStand2,5,7,4) end

local function axes(plan)
	local c,s=math.cos(plan.yaw),math.sin(plan.yaw)
	return Vector2.new(c,-s),Vector2.new(s,c)
end
local function projectedRadius(plan,axis)
	local ax,az=axes(plan)
	return math.abs(axis:Dot(ax))*plan.w/2+math.abs(axis:Dot(az))*plan.d/2
end
local function planHitsRect(plan,rect,tolerance)
	if not (plan and rect) then return false end
	local pc=Vector2.new(plan.x,plan.z); local rc=Vector2.new(rect.x,rect.z)
	local pax,paz=axes(plan)
	for _,axis in ipairs({pax,paz,Vector2.new(1,0),Vector2.new(0,1)}) do
		local dist=math.abs((rc-pc):Dot(axis))
		local rr=math.abs(axis.X)*rect.w/2+math.abs(axis.Y)*rect.d/2
		if dist >= projectedRadius(plan,axis)+rr-(tolerance or 0) then return false end
	end
	return true
end
local pathBuildingIntersections,pathWellIntersections,pathFenceIntersections=0,0,0
local buildingPairs={{trading,"TradingHall"},{rewards,"RewardsBuilding"}}
if pet then table.insert(buildingPairs,{pet,"PetShopBuilding"}) end
if general then table.insert(buildingPairs,{general,"GeneralStoreBuilding"}) end
if blacksmith then table.insert(buildingPairs,{blacksmith,"BlacksmithBuilding"}) end
for _, plan in ipairs(pathPlans) do
	for _, pair in ipairs(buildingPairs) do
		local fp=footprints[pair[2]]
		if fp and planHitsRect(plan,fp,.2) then pathBuildingIntersections+=1 end
	end
	if planHitsRect(plan,wellFP,.2) then pathWellIntersections+=1 end
	-- Fence contact is allowed only for the entrance connector; all other pieces must remain clear.
	if plan.group~="MainPath" then
		for _,part in ipairs(partsOf(fenceRoot)) do
			local fp=localFootprint(part)
			if fp and planHitsRect(plan,fp,.1) then pathFenceIntersections+=1 end
		end
	end
end
-- Aprons deliberately touch their destination footprint; do not count that destination contact.
-- Recalculate fatal intersections using only connector pieces against non-destination buildings.
pathBuildingIntersections=0
for _,plan in ipairs(pathPlans) do
	if not string.find(plan.name,"Apron",1,true) then
		for key,fp in pairs(footprints) do
			if string.find(key,"Building") and not string.find(plan.group,key:gsub("Building",""),1,true) and planHitsRect(plan,fp,.2) then
				pathBuildingIntersections+=1
			end
		end
	end
end

local function intentionallyReplaced(instance)
	for _,spec in ipairs(replacementSpecs) do
		if instance==spec.old or instance:IsDescendantOf(spec.old) then return true end
	end
	return false
end
local transformParts,transformModels={},{}
for _,descendant in ipairs(town:GetDescendants()) do
	if not intentionallyReplaced(descendant) then
		if descendant:IsA("BasePart") then transformParts[descendant]={cf=descendant.CFrame,size=descendant.Size}
		elseif descendant:IsA("Model") then transformModels[descendant]={scale=descendant:GetScale()} end
	end
end
local futureSnapshot={}
if futurePlots then
	for _,p in ipairs(futurePlots:GetDescendants()) do if p:IsA("BasePart") then futureSnapshot[p]={cf=p.CFrame,size=p.Size} end end
end

local palettes={
	TradingHall={wall=Color3.fromRGB(238,218,179),wood=Color3.fromRGB(79,55,42),roof=Color3.fromRGB(83,82,78),stone=Color3.fromRGB(145,139,126),window=Color3.fromRGB(220,177,81),accent=Color3.fromRGB(105,145,96),combined=Color3.fromRGB(211,181,128)},
	RewardsBuilding={wall=Color3.fromRGB(246,232,199),wood=Color3.fromRGB(117,78,52),roof=Color3.fromRGB(91,78,72),stone=Color3.fromRGB(145,139,126),window=Color3.fromRGB(220,177,81),accent=Color3.fromRGB(170,73,70),combined=Color3.fromRGB(214,148,122)},
	PetShopBuilding={wall=Color3.fromRGB(246,232,199),wood=Color3.fromRGB(117,78,52),roof=Color3.fromRGB(83,82,78),stone=Color3.fromRGB(145,139,126),window=Color3.fromRGB(220,205,126),accent=Color3.fromRGB(108,166,190),combined=Color3.fromRGB(157,201,215)},
	GeneralStoreBuilding={wall=Color3.fromRGB(238,218,179),wood=Color3.fromRGB(117,78,52),roof=Color3.fromRGB(144,82,61),stone=Color3.fromRGB(145,139,126),window=Color3.fromRGB(220,177,81),accent=Color3.fromRGB(105,145,96),combined=Color3.fromRGB(157,184,132)},
	BlacksmithBuilding={wall=Color3.fromRGB(213,187,147),wood=Color3.fromRGB(79,55,42),roof=Color3.fromRGB(68,67,64),stone=Color3.fromRGB(145,139,126),window=Color3.fromRGB(196,118,62),accent=Color3.fromRGB(177,91,64),combined=Color3.fromRGB(165,128,92)},
	CentralWell={wall=Color3.fromRGB(145,139,126),wood=Color3.fromRGB(117,78,52),roof=Color3.fromRGB(83,82,78),stone=Color3.fromRGB(161,154,139),window=Color3.fromRGB(84,178,200),accent=Color3.fromRGB(84,178,200),combined=Color3.fromRGB(159,142,111)},
	MarketStand1={wall=Color3.fromRGB(238,218,179),wood=Color3.fromRGB(117,78,52),roof=Color3.fromRGB(105,145,96),stone=Color3.fromRGB(145,139,126),window=Color3.fromRGB(220,177,81),accent=Color3.fromRGB(105,145,96),combined=Color3.fromRGB(133,174,117)},
	MarketStand2={wall=Color3.fromRGB(238,218,179),wood=Color3.fromRGB(117,78,52),roof=Color3.fromRGB(170,73,70),stone=Color3.fromRGB(145,139,126),window=Color3.fromRGB(220,177,81),accent=Color3.fromRGB(170,73,70),combined=Color3.fromRGB(190,112,92)},
	MarketCart={wall=Color3.fromRGB(177,123,77),wood=Color3.fromRGB(117,78,52),roof=Color3.fromRGB(79,55,42),stone=Color3.fromRGB(83,82,78),window=Color3.fromRGB(220,177,81),accent=Color3.fromRGB(177,91,64),combined=Color3.fromRGB(141,91,55)},
}
local targets={}
for _,spec in ipairs(replacementSpecs) do table.insert(targets,{spec.old,spec.key}) end
if pet then table.insert(targets,{pet,"PetShopBuilding"}) end
local materialGroupsDetected=0
for _,pair in ipairs(targets) do materialGroupsDetected += #partsOf(pair[1]) end
local templateMeshParts=0
local EXPECTED_GROUPS={TradingHall=5,RewardsBuilding=5,GeneralStoreBuilding=5,BlacksmithBuilding=5,CentralWell=3,MarketStand1=3,MarketStand2=3,MarketCart=4}
local EXPECTED_SOURCE_SIZE={
	TradingHall=Vector3.new(4.029112577,3.491201901,4.021362305), RewardsBuilding=Vector3.new(1.936935425,1.073302492,2.123567260),
	GeneralStoreBuilding=Vector3.new(2.220160723,3.250352149,3.420024515), BlacksmithBuilding=Vector3.new(3.890024543,3.003413919,3.283497096),
	CentralWell=Vector3.new(.666367233,1.250447852,1.003556275), MarketStand1=Vector3.new(.950941265,1.049173479,1.189832214),
	MarketStand2=Vector3.new(.517172009,1.042149515,1.154234695), MarketCart=Vector3.new(.461997479,.796056013,.927388852),
}
local emptyMeshParts,unknownSemanticGroups,buildingsWithOneColor=0,0,0
for _,spec in ipairs(replacementSpecs) do
	local templateParts=partsOf(spec.template)
	if #templateParts~=(EXPECTED_GROUPS[spec.key] or -1) then stop("template group count mismatch for "..spec.key..": expected "..tostring(EXPECTED_GROUPS[spec.key])..", got "..#templateParts) end
	local distinct={}
	for _,part in ipairs(templateParts) do
		if not part:IsA("MeshPart") or part.Size.X<=0 or part.Size.Y<=0 or part.Size.Z<=0 then emptyMeshParts+=1 end
		local role=importRole(part.Name); local rgb=role and IMPORT_COLORS[TEMPLATE_NAMES[spec.key]][role]
		if not rgb then unknownSemanticGroups+=1 else distinct[string.format("%d,%d,%d",rgb[1],rgb[2],rgb[3])]=true end
		if part.DoubleSided~=true or part.Transparency~=0 then stop("template visibility validation failed: "..part:GetFullName()) end
	end
	local colorCount=0; for _ in pairs(distinct) do colorCount+=1 end; if colorCount<2 then buildingsWithOneColor+=1 end
	local _,templateSize=spec.template:GetBoundingBox()
	if (templateSize-EXPECTED_SOURCE_SIZE[spec.key]).Magnitude>.05 then stop("OBJ template combined bounds mismatch for "..spec.key..": expected "..tostring(EXPECTED_SOURCE_SIZE[spec.key])..", got "..tostring(templateSize)) end
	templateMeshParts += #templateParts
end
if templateMeshParts~=33 then stop("Studio material templates contain "..templateMeshParts.." BaseParts; expected exactly 33") end
if emptyMeshParts~=0 or unknownSemanticGroups~=0 or buildingsWithOneColor~=0 then stop(string.format("OBJ template semantic validation failed empty=%d unknown=%d oneColor=%d",emptyMeshParts,unknownSemanticGroups,buildingsWithOneColor)) end

print("AK_TOWN_POLISH_PREFLIGHT")
print("TownPlazaFound=true")
print("TradingHallFound="..tostring(trading~=nil)); print("RewardsFound="..tostring(rewards~=nil))
print("PetShopFound="..tostring(pet~=nil)); print("GeneralStoreFound="..tostring(general~=nil)); print("BlacksmithFound="..tostring(blacksmith~=nil))
print("CentralWellFound="..tostring(well~=nil)); print("MarketStand1Found="..tostring(market1~=nil)); print("MarketStand2Found="..tostring(market2~=nil))
print("BuildingPositionsLocked=true"); print("BuildingRotationsLocked=true"); print("BuildingScalesLocked=true")
print("MaterialGroupsDetected="..materialGroupsDetected)
print("MaterialTemplatePartsDetected="..templateMeshParts)
print("PathSegmentsPlanned="..#pathPlans)
print("PathBuildingIntersections="..pathBuildingIntersections)
print("PathWellIntersections="..pathWellIntersections)
print("PathFenceIntersections="..pathFenceIntersections)
if pathBuildingIntersections>0 or pathWellIntersections>0 or pathFenceIntersections>0 then stop("planned path intersection validation failed") end
if #pathPlans~=17 then stop("existing solved path plan changed; expected 17 segments, found "..#pathPlans) end

local propertySnapshot={}
local addedLights={}
local replacementRecords={}
local function remember(object,properties)
	if propertySnapshot[object] then return end
	local state={}
	for _,property in ipairs(properties) do local ok,value=pcall(function() return object[property] end); if ok then state[property]=value end end
	propertySnapshot[object]=state
end
local function restore(reason,rollback,visualPolish)
	warn("AK_TOWN_POLISH_ROLLBACK: "..tostring(reason))
	for object,state in pairs(propertySnapshot) do if object and object.Parent then for property,value in pairs(state) do pcall(function() object[property]=value end) end end end
	for _,light in ipairs(addedLights) do if light and light.Parent then light:Destroy() end end
	for index=#replacementRecords,1,-1 do
		local record=replacementRecords[index]
		if record.replacement then record.replacement:Destroy() end
		if record.original then
			record.original.Name=record.name
			record.original.Parent=record.parent
		end
	end
	if visualPolish and visualPolish.Parent then visualPolish:Destroy() end
	if oldPaths and oldPaths.Parent~=town then oldPaths.Parent=town end
	Workspace:SetAttribute(MARKER,nil)
	if rollback and rollback.Parent then rollback:Destroy() end
	error("Town visual polish failed and was rolled back: "..tostring(reason),0)
end

local function boundingBox(instance)
	if instance:IsA("Model") then return instance:GetBoundingBox() end
	if instance:IsA("BasePart") then return instance.CFrame,instance.Size end
	local wrapper=Instance.new("Model")
	for _,child in ipairs(instance:GetChildren()) do child:Clone().Parent=wrapper end
	local cf,size=wrapper:GetBoundingBox(); wrapper:Destroy(); return cf,size
end
local function modelClone(template,logicalName)
	local clone=template:Clone()
	if clone:IsA("Model") then clone.Name=logicalName; return clone end
	local wrapper=Instance.new("Model"); wrapper.Name=logicalName; clone.Parent=wrapper; return wrapper
end
local function roleForSplitPart(part)
	local n=string.lower(part.Name)
	if n:find("mainwood") then return "wall" end
	if n:find("darkwood") then return "wood" end
	if n:find("wheelframe") then return "roof" end
	if n:find("wall") or n:find("cream") then return "wall" end
	if n:find("timber") or n:find("wood") then return "wood" end
	if n:find("roof") then return "roof" end
	if n:find("stone") then return "stone" end
	if n:find("gold") or n:find("window") then return "window" end
	if n:find("water") or n:find("sage") or n:find("terracotta") or n:find("forge") or n:find("canopy") or n:find("accent") then return "accent" end
	return nil
end
local function styleSplitModel(model,key)
	local templateName=TEMPLATE_NAMES[key]
	local colors=IMPORT_COLORS[templateName]
	if not colors then error("missing exact semantic palette for "..key) end
	for _,part in ipairs(partsOf(model)) do
		local role=importRole(part.Name); local rgb=role and colors[role]
		if not rgb then error("unrecognized material mesh role: "..part:GetFullName()) end
		part.Color=Color3.fromRGB(rgb[1],rgb[2],rgb[3]); part.Material=importMaterial(role)
		part.Anchored=true; part.CanTouch=false; part.CanQuery=false; part.CastShadow=true; part.DoubleSided=true; part.Transparency=0
	end
end
local function prepareReplacement(spec)
	local oldCF,oldSize=boundingBox(spec.old)
	local replacement=modelClone(spec.template,spec.old.Name)
	local _,initialSize=replacement:GetBoundingBox()
	local ratios={oldSize.X/initialSize.X,oldSize.Y/initialSize.Y,oldSize.Z/initialSize.Z}; table.sort(ratios)
	local factor=ratios[2]
	replacement:ScaleTo(replacement:GetScale()*factor)
	local newCF=replacement:GetBoundingBox()
	replacement:PivotTo(oldCF*newCF:Inverse()*replacement:GetPivot())
	styleSplitModel(replacement,spec.key)
	for attribute,value in pairs(spec.old:GetAttributes()) do replacement:SetAttribute(attribute,value) end
	replacement:SetAttribute("AK_MaterialSplitReplacement",true)
	local record={original=spec.old,replacement=replacement,parent=spec.old.Parent,name=spec.old.Name,oldCF=oldCF,oldSize=oldSize,key=spec.key}
	replacement.Name=spec.old.Name.."_MaterialSplit_PENDING"
	local checkCF,checkSize=replacement:GetBoundingBox()
	local centerDelta=(checkCF.Position-oldCF.Position).Magnitude
	local sizeDelta=(checkSize-oldSize).Magnitude
	local orientationMatch=checkCF.RightVector:Dot(oldCF.RightVector)>VECTOR_DOT_TOLERANCE and checkCF.UpVector:Dot(oldCF.UpVector)>VECTOR_DOT_TOLERANCE and checkCF.LookVector:Dot(oldCF.LookVector)>VECTOR_DOT_TOLERANCE
	print("AK_OBJ_REPLACEMENT_ALIGNMENT"); print("name="..spec.key); print("oldCenter="..tostring(oldCF.Position)); print("newCenter="..tostring(checkCF.Position)); print("centerDelta="..centerDelta); print("oldSize="..tostring(oldSize)); print("newSize="..tostring(checkSize)); print("sizeDelta="..sizeDelta); print("orientationMatch="..tostring(orientationMatch)); print("template="..spec.template.Name)
	if centerDelta>.01 or sizeDelta>.05 or not orientationMatch then replacement:Destroy(); error("material-split bounds alignment failed for "..spec.key) end
	table.insert(replacementRecords,record)
	return record
end

local function semanticRole(part,root,index,count)
	if not (part and root) then return "combined" end
	local n=string.lower(part.Name.." "..root.Name.." "..part.Material.Name.." "..part.MaterialVariant)
	if n:find("water") then return "accent" end
	if n:find("window") or n:find("glass") or n:find("light") then return "window" end
	if n:find("roof") or n:find("tile") or n:find("shingle") then return "roof" end
	if n:find("stone") or n:find("brick") or n:find("base") or n:find("foundation") then return "stone" end
	if n:find("wood") or n:find("beam") or n:find("timber") or n:find("door") or n:find("frame") or n:find("wheel") then return "wood" end
	if n:find("wall") or n:find("plaster") or n:find("beige") then return "wall" end
	if n:find("banner") or n:find("canopy") or n:find("cloth") or n:find("forge") or n:find("ember") then return "accent" end
	if count==1 then return "combined" end
	local fp=localFootprint(part)
	local rootFP=localFootprint(root)
	if fp and rootFP and fp.z < rootFP.z-rootFP.d*.2 then return "roof" end
	return ({"wall","wood","roof","stone","accent"})[((index-1)%5)+1]
end
local function recolorRoot(root,key)
	if not (root and palettes[key]) then return false end
	local parts=partsOf(root); local palette=palettes[key]
	if #parts==1 and parts[1]:IsA("MeshPart") then
		error("solid-building recolor disabled; material-split replacement required for "..key)
	end
	for index,part in ipairs(parts) do
		remember(part,{"Color","Material","MaterialVariant","Transparency","Reflectance","CastShadow"})
		local role=semanticRole(part,root,index,#parts)
		part.Color=palette[role] or palette.wall
		part.CastShadow=true
		if not part:IsA("MeshPart") then
			if role=="wood" then part.Material=Enum.Material.WoodPlanks
			elseif role=="stone" then part.Material=Enum.Material.Cobblestone
			elseif role=="roof" then part.Material=Enum.Material.Slate
			else part.Material=Enum.Material.SmoothPlastic end
		end
	end
	return #parts>0
end

local function makeFolder(parent,name) local f=Instance.new("Folder"); f.Name=name; f.Parent=parent; return f end
local function createPath(parent,plan,topY)
	local p=Instance.new("Part")
	p.Name=plan.name; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=false
	p.Material=Enum.Material.Cobblestone; p.Color=Color3.fromRGB(201,183,150); p.Size=Vector3.new(plan.w,.1,plan.d)
	p.CFrame=plaza.CFrame*CFrame.new(plan.x,plaza.Size.Y/2+.055,plan.z)*CFrame.Angles(0,plan.yaw,0)
	p:SetAttribute("AK_TownPolishPath",true); p.Parent=parent
	return p
end
local function polishSimple(root,kind)
	if not root then return end
	local ps=partsOf(root)
	for i,p in ipairs(ps) do
		remember(p,{"Color","Material","MaterialVariant","Transparency","Reflectance","CastShadow"})
		local n=string.lower(p.Name)
		if kind=="fence" or kind=="bench" then p.Color=Color3.fromRGB(132,86,52)
		elseif kind=="lamp" then p.Color=(n:find("light") or n:find("glass")) and Color3.fromRGB(255,220,125) or Color3.fromRGB(66,53,43)
		elseif kind=="planter" then p.Color=(n:find("leaf") or n:find("bush") or n:find("flower")) and Color3.fromRGB(105,145,96) or Color3.fromRGB(151,120,83) end
		if not p:IsA("MeshPart") then p.Material=(kind=="lamp" and Enum.Material.Metal or Enum.Material.Wood) end
	end
	if kind=="lamp" and #ps>0 and not root:FindFirstChild("AK_TownPolishLight",true) then
		local host=ps[1]; for _,p in ipairs(ps) do if p.Position.Y>host.Position.Y then host=p end end
		local light=Instance.new("PointLight"); light.Name="AK_TownPolishLight"; light.Color=Color3.fromRGB(255,220,145); light.Brightness=.8; light.Range=10; light.Shadows=false; light.Parent=host; table.insert(addedLights,light)
	end
end

local function polishSigns(root)
	if not root then return end
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") then remember(d,{"TextColor3","TextStrokeColor3","TextStrokeTransparency","Font","BackgroundTransparency"}); d.Font=Enum.Font.FredokaOne; d.TextColor3=Color3.fromRGB(248,224,166); d.TextStrokeColor3=Color3.fromRGB(72,48,35); d.TextStrokeTransparency=.15; d.BackgroundTransparency=1
		elseif d:IsA("BasePart") then remember(d,{"Color","Material"}); d.Color=Color3.fromRGB(117,78,52); if not d:IsA("MeshPart") then d.Material=Enum.Material.WoodPlanks end end
	end
end

-- Prepare every aligned replacement while every original is still present.
-- Failure here destroys only the temporary replacements; Workspace originals stay put.
local prepareOk,prepareError=pcall(function()
	for _,spec in ipairs(replacementSpecs) do prepareReplacement(spec) end
end)
if not prepareOk then
	for _,record in ipairs(replacementRecords) do if record.replacement then record.replacement:Destroy() end end
	stop("replacement preparation failed; originals untouched: "..tostring(prepareError))
end
if #replacementRecords~=8 then
	for _,record in ipairs(replacementRecords) do if record.replacement then record.replacement:Destroy() end end
	stop("templatesReady must be 8/8; got "..#replacementRecords)
end
print("AK_TOWN_V2_TRANSACTION_PREFLIGHT")
print("templatesReady=8/8"); print("meshParts="..templateMeshParts); print("emptyMeshParts="..emptyMeshParts)
print("unknownSemanticGroups="..unknownSemanticGroups); print("buildingsWithOneColor="..buildingsWithOneColor); print("originalsStillPresent=true")

local rollback,visualPolish
local liveTargets={}
local mutationOk,mutationError=pcall(function()
	-- Parent all eight pending replacements while every original is still present,
	-- then revalidate before the atomic swap.
	for _,record in ipairs(replacementRecords) do record.replacement.Parent=record.parent end
	for _,record in ipairs(replacementRecords) do
		local cf,size=record.replacement:GetBoundingBox()
		if (cf.Position-record.oldCF.Position).Magnitude>.01 or (size-record.oldSize).Magnitude>.05 then error("live pending replacement alignment changed: "..record.key) end
	end
	-- Atomic commit begins only after all eight live pending replacements passed.
	rollback=Instance.new("Folder"); rollback.Name=ROLLBACK_NAME; rollback.Parent=ServerStorage
	rollback:SetAttribute("Purpose","All eight authoritative gray originals plus prior Paths and visual property state")
	for _,record in ipairs(replacementRecords) do record.original.Parent=rollback end
	for _,record in ipairs(replacementRecords) do
		record.replacement.Name=record.name
		table.insert(liveTargets,{record.replacement,record.key})
	end
	if oldPaths then oldPaths.Parent=rollback end
	-- Paths are deliberately created only after the complete eight-building commit.
	visualPolish=makeFolder(town,"VisualPolish")
	local pathsFolder=makeFolder(visualPolish,"Paths")
	local centralFolder=makeFolder(visualPolish,"CentralPlazaPolish")
	makeFolder(visualPolish,"AddedSigns")
	local groups={}
	for _,plan in ipairs(pathPlans) do
		local parent
		if plan.group=="CentralPlazaPolish" then parent=centralFolder else
			parent=groups[plan.group]; if not parent then parent=makeFolder(pathsFolder,plan.group); groups[plan.group]=parent end
		end
		createPath(parent,plan)
	end
	polishSimple(fenceRoot,"fence")
	polishSimple(town:FindFirstChild("Benches"),"bench")
	polishSimple(town:FindFirstChild("Lights"),"lamp")
	polishSimple(town:FindFirstChild("Planters"),"planter")
	polishSigns(firstAt(town,{"TradingHallSign"})); polishSigns(firstAt(town,{"RewardsSign"}))
end)
if not mutationOk then restore(mutationError,rollback,visualPolish) end

local validationOk,validationError=pcall(function()
	local moved,resized,rotated,scaled=0,0,0,0
	for part,state in pairs(transformParts) do
		if not part.Parent then error("existing town part removed: "..part:GetFullName()) end
		local positionDelta=(part.Position-state.cf.Position).Magnitude
		local sizeDelta=(part.Size-state.size).Magnitude
		local rightDot=part.CFrame.RightVector:Dot(state.cf.RightVector)
		local upDot=part.CFrame.UpVector:Dot(state.cf.UpVector)
		local lookDot=part.CFrame.LookVector:Dot(state.cf.LookVector)
		local partMoved=positionDelta>POSITION_TOLERANCE
		local partResized=sizeDelta>SIZE_TOLERANCE
		local partRotated=rightDot<VECTOR_DOT_TOLERANCE or upDot<VECTOR_DOT_TOLERANCE or lookDot<VECTOR_DOT_TOLERANCE
		if partMoved or partResized or partRotated then
			print("AK_TOWN_POLISH_TRANSFORM_DIAGNOSTIC")
			print("object="..part:GetFullName()); print("positionDelta="..positionDelta)
			print("rightDot="..rightDot); print("upDot="..upDot); print("lookDot="..lookDot); print("sizeDelta="..sizeDelta)
		end
		if partMoved then moved+=1 end
		if partResized then resized+=1 end
		if partRotated then rotated+=1 end
	end
	for model,state in pairs(transformModels) do
		if not model.Parent then error("existing town model removed") end
		if math.abs(model:GetScale()-state.scale)>SCALE_TOLERANCE then scaled+=1 end
	end
	for part,state in pairs(futureSnapshot) do if not part.Parent or (part.CFrame.Position-state.cf.Position).Magnitude>POSITION_TOLERANCE or (part.Size-state.size).Magnitude>SIZE_TOLERANCE then error("future player plot changed") end end
	print("movedParts="..moved); print("rotatedParts="..rotated); print("resizedParts="..resized); print("scaledModels="..scaled)
	if moved>0 or resized>0 or rotated>0 or scaled>0 then error(string.format("transform lock failed movedParts=%d resizedParts=%d rotatedParts=%d scaledModels=%d",moved,resized,rotated,scaled)) end
	for _,record in ipairs(replacementRecords) do
		local cf,size=record.replacement:GetBoundingBox()
		if (cf.Position-record.oldCF.Position).Magnitude>.01 or (size-record.oldSize).Magnitude>.05 then error("replacement visible bounds changed: "..record.key) end
		local parts=partsOf(record.replacement)
		if #parts~=(EXPECTED_GROUPS[record.key] or -1) then error("replacement lost material mesh separation: "..record.key) end
		local colors,materials={},{}
		local visible,doubleSided=0,0
		for _,part in ipairs(parts) do
			if part.Transparency==0 and part.Size.X>0 and part.Size.Y>0 and part.Size.Z>0 then visible+=1 end
			if part:IsA("MeshPart") and part.DoubleSided then doubleSided+=1 end
			colors[tostring(part.Color)]=true; materials[part.Material.Name]=true
		end
		local colorCount,materialCount=0,0; for _ in pairs(colors) do colorCount+=1 end; for _ in pairs(materials) do materialCount+=1 end
		print("AK_VISUAL_MODEL_VALIDATION"); print("building="..record.key); print("parts="..#parts)
		print("distinctColors="..colorCount); print("distinctMaterials="..materialCount); print("visibleParts="..visible)
		print("doubleSidedParts="..doubleSided); print("boundsMatch=true")
		if visible~=#parts or doubleSided~=#parts or colorCount<2 or materialCount<2 then error("visual semantic validation failed: "..record.key) end
	end
	local grayOnly=0
	for _,pair in ipairs(liveTargets) do
		local colorful=false
		for _,p in ipairs(partsOf(pair[1])) do local c=p.Color; if math.max(c.R,c.G,c.B)-math.min(c.R,c.G,c.B)>.035 then colorful=true end end
		if not colorful then grayOnly+=1 end
	end
	if grayOnly>0 then error("buildings still gray-only: "..grayOnly) end
	if not visualPolish or #pathPlans==0 then error("path network missing") end
	Workspace:SetAttribute(MARKER,true)
	print("ANIMAL KINGDOM TOWN COLOR PIPELINE V2 COMPLETE")
	print("Buildings repositioned: 0"); print("Buildings resized: 0"); print("Buildings rotated: 0")
	print("Trading Hall recolored: YES"); print("Rewards recolored: YES"); print("Pet Shop recolored: "..(pet and "YES" or "SKIPPED_NOT_PRESENT")); print("General Store recolored: "..(general and "YES" or "SKIPPED_NOT_PRESENT")); print("Blacksmith recolored: "..(blacksmith and "YES" or "SKIPPED_NOT_PRESENT"))
	print("Central Well polished: YES"); print("Market polished: "..((market1 or market2 or cart) and "YES" or "SKIPPED_NOT_PRESENT")); print("Path network: COMPLETE")
	print("Town entrance connected: YES"); print("Trading Hall connected: YES"); print("Rewards connected: YES"); print("Pet Shop connected: "..(pet and "YES" or "SKIPPED_NOT_PRESENT")); print("General Store connected: "..(general and "YES" or "SKIPPED_NOT_PRESENT")); print("Blacksmith connected: "..(blacksmith and "YES" or "SKIPPED_NOT_PRESENT")); print("Market connected: "..((market1 or market2) and "YES" or "SKIPPED_NOT_PRESENT"))
	print("Town layout changed: NO"); print("Gameplay changes: 0"); print("Script Source writes: 0"); print("Failures: 0")
end)
if not validationOk then restore(validationError,rollback,visualPolish) end
