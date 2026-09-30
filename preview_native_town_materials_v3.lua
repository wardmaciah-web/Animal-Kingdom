-- Animal Kingdom Native Town Material Preview V3
-- Stage A only. Native Roblox Studio FBX imports must already exist in ServerStorage.
-- This script cannot find, move, hide, delete, or replace any live town object.

local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")

local IMPORT_FOLDER_NAME="AnimalKingdomTownNativeMaterialImports"
local PREVIEW_FOLDER_NAME="AnimalKingdomTownMaterialPreviewV3"
local PREVIEW_MARKER="AnimalKingdomTownMaterialPreviewV3"

local ORDER={
	"TradingHall_MaterialSplit","Rewards_MaterialSplit","GeneralStore_MaterialSplit","Blacksmith_MaterialSplit",
	"Well_MaterialSplit","MarketStand1_MaterialSplit","MarketStand2_MaterialSplit","Cart_MaterialSplit",
}

local EXPECTED_COUNTS={
	TradingHall_MaterialSplit=5, Rewards_MaterialSplit=5, GeneralStore_MaterialSplit=5,
	Blacksmith_MaterialSplit=5, Well_MaterialSplit=3, MarketStand1_MaterialSplit=3,
	MarketStand2_MaterialSplit=3, Cart_MaterialSplit=4,
}

local PALETTES={
	TradingHall_MaterialSplit={
		Walls={238,218,179,Enum.Material.SmoothPlastic}, Timber={79,55,42,Enum.Material.WoodPlanks},
		Roof={83,82,78,Enum.Material.Slate}, Stone={145,139,126,Enum.Material.Cobblestone},
		Sage={105,145,96,Enum.Material.SmoothPlastic}, Gold={220,177,81,Enum.Material.SmoothPlastic},
	},
	Rewards_MaterialSplit={
		Walls={246,232,199,Enum.Material.SmoothPlastic}, Timber={117,78,52,Enum.Material.WoodPlanks},
		Roof={91,78,72,Enum.Material.Slate}, Stone={145,139,126,Enum.Material.Cobblestone},
		Terracotta={170,73,70,Enum.Material.SmoothPlastic}, Gold={220,177,81,Enum.Material.SmoothPlastic},
	},
	GeneralStore_MaterialSplit={
		Walls={238,218,179,Enum.Material.SmoothPlastic}, Timber={117,78,52,Enum.Material.WoodPlanks},
		Roof={144,82,61,Enum.Material.Slate}, Stone={145,139,126,Enum.Material.Cobblestone},
		Sage={105,145,96,Enum.Material.SmoothPlastic},
	},
	Blacksmith_MaterialSplit={
		Walls={213,187,147,Enum.Material.SmoothPlastic}, Timber={79,55,42,Enum.Material.WoodPlanks},
		Roof={68,67,64,Enum.Material.Slate}, Stone={145,139,126,Enum.Material.Cobblestone},
		ForgeAccent={177,91,64,Enum.Material.SmoothPlastic},
	},
	Well_MaterialSplit={
		Stone={161,154,139,Enum.Material.Cobblestone}, Wood={117,78,52,Enum.Material.WoodPlanks},
		Roof={83,82,78,Enum.Material.Slate}, Water={84,178,200,Enum.Material.SmoothPlastic},
	},
	MarketStand1_MaterialSplit={
		Wood={117,78,52,Enum.Material.WoodPlanks}, Cream={238,218,179,Enum.Material.SmoothPlastic},
		Canopy={105,145,96,Enum.Material.SmoothPlastic},
	},
	MarketStand2_MaterialSplit={
		Wood={117,78,52,Enum.Material.WoodPlanks}, Cream={238,218,179,Enum.Material.SmoothPlastic},
		Canopy={170,73,70,Enum.Material.SmoothPlastic},
	},
	Cart_MaterialSplit={
		MainWood={177,123,77,Enum.Material.WoodPlanks}, DarkWood={117,78,52,Enum.Material.WoodPlanks},
		WheelFrame={79,55,42,Enum.Material.WoodPlanks}, Accent={177,91,64,Enum.Material.SmoothPlastic},
	},
}

local function stop(message)
	error("Native town material preview stopped before preview creation: "..tostring(message),0)
end

if Workspace:GetAttribute(PREVIEW_MARKER)==true or Workspace:FindFirstChild(PREVIEW_FOLDER_NAME) then
	warn("Animal Kingdom native material preview V3 already exists; no changes made")
	return
end

local importRoot=ServerStorage:FindFirstChild(IMPORT_FOLDER_NAME)
if not importRoot then stop("missing ServerStorage."..IMPORT_FOLDER_NAME.."; import the eight verified FBXs with Studio's native 3D Importer first") end

local function normalizedStem(name)
	local value=string.lower(name)
	value=value:gsub("%.fbx$",""):gsub("%s*%(%d+%)%s*$",""):gsub("[%s_%-]",""):gsub("[^%w]","")
	return value
end

local function partsOf(root)
	local result={}
	if not root then return result end
	if root:IsA("BasePart") then table.insert(result,root) end
	for _,descendant in ipairs(root:GetDescendants()) do if descendant:IsA("BasePart") then table.insert(result,descendant) end end
	return result
end

local function meshPartsOf(root)
	local result={}
	for _,part in ipairs(partsOf(root)) do if part:IsA("MeshPart") then table.insert(result,part) end end
	return result
end

local function asModel(instance,newName)
	local clone=instance:Clone()
	if clone:IsA("Model") then clone.Name=newName; return clone end
	local model=Instance.new("Model"); model.Name=newName; clone.Parent=model; return model
end

local function semanticRole(partName,palette)
	local compact=string.lower(partName):gsub("[^%w]","")
	local ordered={"ForgeAccent","WheelFrame","MainWood","DarkWood","Terracotta","Canopy","Accent","Walls","Timber","Roof","Stone","Water","Cream","Sage","Gold","Wood"}
	for _,role in ipairs(ordered) do
		if palette[role] and string.find(compact,string.lower(role),1,true) then return role end
	end
	return nil
end

print("AK_NATIVE_IMPORT_INVENTORY")
local inventory={importRoot}
for _,candidate in ipairs(importRoot:GetDescendants()) do
	if candidate:IsA("Model") or candidate:IsA("Folder") or candidate:IsA("MeshPart") then table.insert(inventory,candidate) end
end
table.sort(inventory,function(a,b) return a:GetFullName()<b:GetFullName() end)
for _,candidate in ipairs(inventory) do
	print("FullName="..candidate:GetFullName())
	print("ClassName="..candidate.ClassName)
	print("Name="..candidate.Name)
	print("BasePartDescendantCount="..#partsOf(candidate))
	print("MeshPartDescendantCount="..#meshPartsOf(candidate))
end

local function candidateDepth(candidate)
	local depth=0; local cursor=candidate
	while cursor and cursor~=importRoot do depth+=1; cursor=cursor.Parent end
	return depth
end

local function candidateScore(candidate,expectedName)
	local palette=PALETTES[expectedName]
	local expectedCount=EXPECTED_COUNTS[expectedName]
	local candidateName=normalizedStem(candidate.Name)
	local wanted=normalizedStem(expectedName)
	local shortWanted=wanted:gsub("materialsplit$","")
	local parts=partsOf(candidate)
	if #parts==0 then return -math.huge,0,0 end
	local score=0
	if candidateName==wanted then score+=1000
	elseif string.find(candidateName,wanted,1,true) then score+=650
	elseif candidateName==shortWanted then score+=500
	elseif string.find(candidateName,shortWanted,1,true) then score+=300 end
	if #parts==expectedCount then score+=260 else score-=math.abs(#parts-expectedCount)*45 end
	local recognized,unknown,seen=0,0,{}
	for _,part in ipairs(parts) do
		local role=part:IsA("MeshPart") and semanticRole(part.Name,palette) or nil
		if role then
			recognized+=1; seen[role]=true
		else
			unknown+=1
		end
	end
	local uniqueRoles=0; for _ in pairs(seen) do uniqueRoles+=1 end
	score+=recognized*45+uniqueRoles*20-unknown*70
	-- With otherwise equal evidence, prefer the outermost container that owns the
	-- same geometry set; this retains a native filename wrapper around its model.
	score-=candidateDepth(candidate)*.01
	return score,recognized,unknown
end

local function sameGeometrySet(a,b)
	local ap,bp=partsOf(a),partsOf(b)
	if #ap~=#bp then return false end
	local membership={}; for _,part in ipairs(ap) do membership[part]=true end
	for _,part in ipairs(bp) do if not membership[part] then return false end end
	return true
end

local function findNativeImport(expectedName)
	local candidates={}
	local universe={importRoot}
	for _,candidate in ipairs(importRoot:GetDescendants()) do
		if candidate:IsA("Model") or candidate:IsA("Folder") or candidate:IsA("BasePart") then table.insert(universe,candidate) end
	end
	for _,candidate in ipairs(universe) do
		local score,recognized,unknown=candidateScore(candidate,expectedName)
		if score>-math.huge and (normalizedStem(candidate.Name):find(normalizedStem(expectedName):gsub("materialsplit$",""),1,true) or recognized>=math.max(2,EXPECTED_COUNTS[expectedName]-1)) then
			table.insert(candidates,{instance=candidate,score=score,recognized=recognized,unknown=unknown})
		end
	end
	table.sort(candidates,function(a,b)
		if a.score~=b.score then return a.score>b.score end
		return a.instance:GetFullName()<b.instance:GetFullName()
	end)
	if #candidates==0 then return nil end
	local winner=candidates[1]
	if #candidates>1 then
		local runnerUp=candidates[2]
		local close=winner.score-runnerUp.score<25
		if close and sameGeometrySet(winner.instance,runnerUp.instance) then
			if winner.instance:IsDescendantOf(runnerUp.instance) then winner=runnerUp end
			close=false
		end
		if close then
			print("AK_NATIVE_IMPORT_AMBIGUOUS")
			print("expected="..expectedName)
			for index=1,math.min(6,#candidates) do
				local item=candidates[index]
				print("candidate"..index.."="..item.instance:GetFullName().." score="..string.format("%.2f",item.score).." recognized="..item.recognized.." unknown="..item.unknown)
			end
			stop("ambiguous native import for "..expectedName)
		end
	end
	return winner.instance
end

local function boundingBox(instance)
	if instance:IsA("Model") then return instance:GetBoundingBox() end
	if instance:IsA("BasePart") then return instance.CFrame,instance.Size end
	local wrapper=Instance.new("Model")
	for _,child in ipairs(instance:GetChildren()) do child:Clone().Parent=wrapper end
	local cf,size=wrapper:GetBoundingBox(); wrapper:Destroy(); return cf,size
end

-- Full native-import preflight. No Workspace object is created before this passes.
local imports={}
local totalParts,totalMeshes=0,0
for _,name in ipairs(ORDER) do
	local source=findNativeImport(name)
	if not source then stop("missing native import: ServerStorage."..IMPORT_FOLDER_NAME.."."..name) end
	local parts=partsOf(source)
	if #parts~=EXPECTED_COUNTS[name] then stop(name.." has "..#parts.." BaseParts; expected "..EXPECTED_COUNTS[name]) end
	local palette=PALETTES[name]
	local roles={}
	for _,part in ipairs(parts) do
		if not part:IsA("MeshPart") then stop(name.." contains non-MeshPart geometry: "..part:GetFullName()) end
		local role=semanticRole(part.Name,palette)
		if not role then stop(name.." contains unknown semantic mesh name: "..part.Name) end
		if roles[role] then stop(name.." contains duplicate semantic role: "..role) end
		roles[role]=true
		if tostring(part.MeshId)=="" then stop(name.." contains an empty native MeshId: "..part.Name) end
		if part.Size.X<=0 or part.Size.Y<=0 or part.Size.Z<=0 then stop(name.." contains zero-size geometry: "..part.Name) end
		totalMeshes+=1
	end
	totalParts+=#parts
	imports[name]=source
end
if totalParts~=33 or totalMeshes~=33 then stop(string.format("native import total mismatch: BaseParts=%d MeshParts=%d expected=33",totalParts,totalMeshes)) end

local REPORT_LABELS={
	TradingHall_MaterialSplit="TradingHall", Rewards_MaterialSplit="Rewards",
	GeneralStore_MaterialSplit="GeneralStore", Blacksmith_MaterialSplit="Blacksmith",
	Well_MaterialSplit="Well", MarketStand1_MaterialSplit="MarketStand1",
	MarketStand2_MaterialSplit="MarketStand2", Cart_MaterialSplit="Cart",
}
print("AK_NATIVE_IMPORT_RESOLUTION")
for _,name in ipairs(ORDER) do print(REPORT_LABELS[name].."="..imports[name]:GetFullName()) end
for _,name in ipairs(ORDER) do print(REPORT_LABELS[name].."Parts="..#partsOf(imports[name])) end
print("ExpectedTotal=33")
print("ResolvedTotal="..totalParts)

-- Find a review location beyond all current Workspace BaseParts. This is read-only
-- inspection of the place; no live town object is addressed or modified.
local maximumX=-math.huge
for _,descendant in ipairs(Workspace:GetDescendants()) do
	if descendant:IsA("BasePart") then maximumX=math.max(maximumX,descendant.Position.X+descendant.Size.Magnitude*.5) end
end
if maximumX==-math.huge then maximumX=0 end
local grass=Workspace:FindFirstChild("GrassFloor")
local reviewGroundY=(grass and grass:IsA("BasePart")) and (grass.Position.Y+grass.Size.Y*.5) or 0

local maxWidth,maxDepth=0,0
for _,name in ipairs(ORDER) do
	local _,size=boundingBox(imports[name]); maxWidth=math.max(maxWidth,size.X); maxDepth=math.max(maxDepth,size.Z)
end
local cellWidth=math.max(35,maxWidth+24)
local cellDepth=math.max(35,maxDepth+24)
local platformWidth=cellWidth*4+20
local platformDepth=cellDepth*2+20
local centerX=maximumX+50+platformWidth*.5
local centerZ=0

local preview=Instance.new("Folder"); preview.Name=PREVIEW_FOLDER_NAME
local platform=Instance.new("Part")
platform.Name="PreviewGround"; platform.Anchored=true; platform.CanCollide=true; platform.CanTouch=false; platform.CanQuery=false
platform.Material=Enum.Material.SmoothPlastic; platform.Color=Color3.fromRGB(225,218,202); platform.Size=Vector3.new(platformWidth,.5,platformDepth)
platform.CFrame=CFrame.new(centerX,reviewGroundY-.25,centerZ); platform.Parent=preview

local previewModels={}
local creationOk,creationError=pcall(function()
	for index,name in ipairs(ORDER) do
		local model=asModel(imports[name],name)
		local palette=PALETTES[name]
		for _,part in ipairs(partsOf(model)) do
			local role=semanticRole(part.Name,palette); local style=role and palette[role]
			if not style then error(name.." lost semantic role during clone: "..part.Name) end
			part.Color=Color3.fromRGB(style[1],style[2],style[3]); part.Material=style[4]
			part.Anchored=true; part.CanTouch=false; part.CanQuery=false; part.CastShadow=true
		end
		local row=math.floor((index-1)/4); local column=(index-1)%4
		local targetX=centerX+(column-1.5)*cellWidth
		local targetZ=centerZ+(row-.5)*cellDepth
		local oldCF,size=model:GetBoundingBox()
		local targetCF=CFrame.new(targetX,reviewGroundY+size.Y*.5,targetZ)*oldCF.Rotation
		model:PivotTo(targetCF*oldCF:Inverse()*model:GetPivot())
		model:SetAttribute("AK_NativeMaterialPreviewV3",true)
		model.Parent=preview; previewModels[name]=model
	end
end)
if not creationOk then preview:Destroy(); stop("preview clone preparation failed; real town untouched: "..tostring(creationError)) end

-- Factual preview measurements. These intentionally do not infer visual completeness.
for _,name in ipairs(ORDER) do
	local model=previewModels[name]; local parts=partsOf(model)
	local colors,materials,transparencyValues,collisionValues={},{},{},{}
	local partNames,meshIds={},{ }
	local nonemptyMeshIds,visibleParts=0,0
	for _,part in ipairs(parts) do
		partNames[#partNames+1]=part.Name
		colors[tostring(part.Color)]=true; materials[part.Material.Name]=true
		transparencyValues[tostring(part.Transparency)]=true; collisionValues[tostring(part.CanCollide)]=true
		if part:IsA("MeshPart") then
			meshIds[#meshIds+1]=part.Name.."="..tostring(part.MeshId)
			if tostring(part.MeshId)~="" then nonemptyMeshIds+=1 end
		end
		if part.Transparency<1 and part.Size.X>0 and part.Size.Y>0 and part.Size.Z>0 then visibleParts+=1 end
	end
	table.sort(partNames); table.sort(meshIds)
	local distinctColors,distinctMaterials=0,0; for _ in pairs(colors) do distinctColors+=1 end; for _ in pairs(materials) do distinctMaterials+=1 end
	local cf,size=model:GetBoundingBox()
	print("AK_NATIVE_TOWN_PREVIEW_MODEL")
	print("model="..name); print("BaseParts="..#parts); print("MeshParts="..#meshIds)
	print("partNames="..table.concat(partNames,",")); print("distinctColors="..distinctColors); print("distinctMaterials="..distinctMaterials)
	local tv,cv={},{}; for value in pairs(transparencyValues) do tv[#tv+1]=value end; for value in pairs(collisionValues) do cv[#cv+1]=value end; table.sort(tv); table.sort(cv)
	print("TransparencyValues="..table.concat(tv,",")); print("CanCollideValues="..table.concat(cv,","))
	print("boundingBoxCFrame="..tostring(cf)); print("boundingBoxSize="..tostring(size)); print("MeshIds="..table.concat(meshIds," | "))
	print("everyMeshPartHasNonEmptyMeshId="..tostring(nonemptyMeshIds==#meshIds)); print("everyPartVisible="..tostring(visibleParts==#parts))
end

preview:SetAttribute("Purpose","Visual review only; never a commit source without explicit later approval")
preview:SetAttribute("NativeImports",8); preview:SetAttribute("MaterialPieces",33)
preview.Parent=Workspace
Workspace:SetAttribute(PREVIEW_MARKER,true)
print("ANIMAL KINGDOM NATIVE TOWN MATERIAL PREVIEW V3 CREATED")
print("Native models measured=8")
print("Native material pieces measured=33")
print("Original town objects addressed=0")
print("Original town objects modified=0")
print("Paths modified=0")
print("VISUAL USER REVIEW REQUIRED BEFORE COMMIT")
