-- Animal Kingdom Native Town Material Commit V3
-- Studio Command Bar script. Uses only models imported by Studio's native 3D importer.
-- It contains no FBX/OBJ parsing and no geometry reconstruction APIs.

local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")

local IMPORT_FOLDER_NAME="AnimalKingdomTownNativeMaterialImports"
local ROLLBACK_NAME="AnimalKingdomTownNativeCommitV3Rollback"
local MARKER="AnimalKingdomTownNativeMaterialV3"
local PREVIEW_NAME="AnimalKingdomTownMaterialPreviewV3"
local POSITION_TOLERANCE=.001
local SIZE_TOLERANCE=.001
local DOT_TOLERANCE=.999999
local SCALE_RATIO_TOLERANCE=.03

local SPECS={
	{key="TradingHall",template="TradingHall_MaterialSplit",logical="TradingHall",parent="town",source="Inn.fbx",count=5},
	{key="Rewards",template="Rewards_MaterialSplit",logical="RewardsBuilding",parent="town",source="House_4.fbx",count=5},
	{key="GeneralStore",template="GeneralStore_MaterialSplit",logical="GeneralStoreBuilding",parent="DecorativeBuildings",source="House_2.fbx",count=5},
	{key="Blacksmith",template="Blacksmith_MaterialSplit",logical="BlacksmithBuilding",parent="DecorativeBuildings",source="Blacksmith.fbx",count=5},
	{key="Well",template="Well_MaterialSplit",logical="CentralWell",parent="Decor",source="Well.fbx",count=3},
	{key="MarketStand1",template="MarketStand1_MaterialSplit",logical="MarketStand1",parent="DisplayProps",source="MarketStand_1.fbx",count=3},
	{key="MarketStand2",template="MarketStand2_MaterialSplit",logical="MarketStand2",parent="DisplayProps",source="MarketStand_2.fbx",count=3},
	{key="Cart",template="Cart_MaterialSplit",logical="MarketCart",parent="DisplayProps",source="Cart.fbx",count=4},
}

local PALETTES={
	TradingHall={Walls={238,218,179,Enum.Material.SmoothPlastic},Timber={79,55,42,Enum.Material.WoodPlanks},Roof={83,82,78,Enum.Material.Slate},Stone={145,139,126,Enum.Material.Cobblestone},Gold={220,177,81,Enum.Material.SmoothPlastic}},
	Rewards={Walls={246,232,199,Enum.Material.SmoothPlastic},Timber={117,78,52,Enum.Material.WoodPlanks},Roof={91,78,72,Enum.Material.Slate},Stone={145,139,126,Enum.Material.Cobblestone},Terracotta={170,73,70,Enum.Material.SmoothPlastic}},
	GeneralStore={Walls={238,218,179,Enum.Material.SmoothPlastic},Timber={117,78,52,Enum.Material.WoodPlanks},Roof={144,82,61,Enum.Material.Slate},Stone={145,139,126,Enum.Material.Cobblestone},Sage={105,145,96,Enum.Material.SmoothPlastic}},
	Blacksmith={Walls={213,187,147,Enum.Material.SmoothPlastic},Timber={79,55,42,Enum.Material.WoodPlanks},Roof={68,67,64,Enum.Material.Slate},Stone={145,139,126,Enum.Material.Cobblestone},ForgeAccent={177,91,64,Enum.Material.SmoothPlastic}},
	Well={Stone={161,154,139,Enum.Material.Cobblestone},Wood={117,78,52,Enum.Material.WoodPlanks},Roof={83,82,78,Enum.Material.Slate}},
	MarketStand1={Wood={117,78,52,Enum.Material.WoodPlanks},Cream={238,218,179,Enum.Material.SmoothPlastic},Canopy={105,145,96,Enum.Material.SmoothPlastic}},
	MarketStand2={Wood={117,78,52,Enum.Material.WoodPlanks},Cream={238,218,179,Enum.Material.SmoothPlastic},Canopy={170,73,70,Enum.Material.SmoothPlastic}},
	Cart={MainWood={177,123,77,Enum.Material.WoodPlanks},DarkWood={117,78,52,Enum.Material.WoodPlanks},WheelFrame={79,55,42,Enum.Material.WoodPlanks},Accent={177,91,64,Enum.Material.SmoothPlastic}},
}

local ROLE_ORDER={"ForgeAccent","WheelFrame","MainWood","DarkWood","Terracotta","Canopy","Accent","Walls","Timber","Roof","Stone","Cream","Sage","Gold","Wood"}

local function stop(message) error("Native town material V3 commit stopped: "..tostring(message),0) end
local function partsOf(root)
	local result={}; if not root then return result end
	if root:IsA("BasePart") then table.insert(result,root) end
	for _,item in ipairs(root:GetDescendants()) do if item:IsA("BasePart") then table.insert(result,item) end end
	return result
end
local function meshPartsOf(root)
	local result={}; for _,part in ipairs(partsOf(root)) do if part:IsA("MeshPart") then table.insert(result,part) end end; return result
end
local function normalized(name)
	return string.lower(name):gsub("%.fbx$",""):gsub("%s*%(%d+%)%s*$",""):gsub("[^%w]","")
end
local function roleOf(name,palette)
	local compact=normalized(name)
	for _,role in ipairs(ROLE_ORDER) do if palette[role] and compact:find(string.lower(role),1,true) then return role end end
	return nil
end
local function parentFor(town,parentKey)
	if parentKey=="town" then return town end
	return town:FindFirstChild(parentKey)
end
local function findLogical(town,spec)
	local parent=parentFor(town,spec.parent)
	if not parent then return nil end
	local exact=parent:FindFirstChild(spec.logical)
	if exact then return exact end
	local matches={}
	for _,candidate in ipairs(parent:GetDescendants()) do
		if (candidate:IsA("Model") or candidate:IsA("BasePart")) and (candidate:GetAttribute("AK_PrebuildSource")==spec.source or normalized(candidate.Name)==normalized(spec.logical)) then table.insert(matches,candidate) end
	end
	return #matches==1 and matches[1] or nil
end
local function boundingBox(instance)
	if instance:IsA("Model") then return instance:GetBoundingBox() end
	if instance:IsA("BasePart") then return instance.CFrame,instance.Size end
	local wrapper=Instance.new("Model"); for _,child in ipairs(instance:GetChildren()) do child:Clone().Parent=wrapper end
	local cf,size=wrapper:GetBoundingBox(); wrapper:Destroy(); return cf,size
end
local function asModel(instance,name)
	local clone=instance:Clone()
	if clone:IsA("Model") then clone.Name=name; return clone end
	local model=Instance.new("Model"); model.Name=name; clone.Parent=model; return model
end
local function sameTransform(a,b)
	return (a.Position-b.Position).Magnitude<=POSITION_TOLERANCE and a.RightVector:Dot(b.RightVector)>=DOT_TOLERANCE and a.UpVector:Dot(b.UpVector)>=DOT_TOLERANCE and a.LookVector:Dot(b.LookVector)>=DOT_TOLERANCE
end

if Workspace:GetAttribute(MARKER)==true then warn("Animal Kingdom native town material V3 already committed; no changes made"); return end
if ServerStorage:FindFirstChild(ROLLBACK_NAME) then stop("existing ServerStorage."..ROLLBACK_NAME.." must be preserved; refusing to overwrite") end
local town=Workspace:FindFirstChild("AnimalKingdomTown")
local townGround=town and town:FindFirstChild("TownGround")
local plaza=townGround and townGround:FindFirstChild("TownPlaza")
if not (town and plaza and plaza:IsA("BasePart")) then stop("authoritative town/TownPlaza missing") end
if math.abs(plaza.Size.X-216)>.05 or math.abs(plaza.Size.Z-180)>.05 then stop("authoritative TownPlaza is not the approved 216x180 footprint: "..tostring(plaza.Size)) end

-- V2 damage recovery is a separate all-or-nothing precheck.
local function recoverV2IfRequired()
	local live={}; local damaged=false
	for _,spec in ipairs(SPECS) do
		local object=findLogical(town,spec); if not object then stop("live object missing before V2 recovery check: "..spec.logical) end
		live[spec.logical]=object; if object:GetAttribute("AK_MaterialSplitReplacement")==true then damaged=true end
	end
	if not damaged then return end
	local rollback=ServerStorage:FindFirstChild("AnimalKingdomTownVisualPolishV2Rollback")
	local originals={}
	if rollback then for _,spec in ipairs(SPECS) do originals[spec.logical]=rollback:FindFirstChild(spec.logical,true) end end
	local complete=rollback~=nil
	for _,spec in ipairs(SPECS) do if not originals[spec.logical] then complete=false end end
	if not complete then print("AK_V2_RECOVERY_REQUIRED_BUT_UNAVAILABLE"); stop("V2 replacement detected without complete eight-building rollback") end
	local holding=Instance.new("Folder"); holding.Name="AnimalKingdomV2DamagedHolding"; holding.Parent=ServerStorage
	local movedOriginals={}
	local ok,reason=pcall(function()
		for _,spec in ipairs(SPECS) do live[spec.logical].Parent=holding end
		for _,spec in ipairs(SPECS) do
			local original=originals[spec.logical]; original.Name=spec.logical; original.Parent=parentFor(town,spec.parent); movedOriginals[#movedOriginals+1]=original
		end
	end)
	if not ok then
		for _,original in ipairs(movedOriginals) do original.Parent=rollback end
		for _,spec in ipairs(SPECS) do local damagedObject=holding:FindFirstChild(spec.logical); if damagedObject then damagedObject.Parent=parentFor(town,spec.parent) end end
		holding:Destroy(); stop("V2 original recovery rolled back: "..tostring(reason))
	end
	holding:Destroy(); rollback:Destroy(); Workspace:SetAttribute("AnimalKingdomTownVisualPolishV2",nil)
	print("AK_V2_ORIGINALS_RESTORED")
end
recoverV2IfRequired()

-- Resolve authoritative originals after any recovery.
local records={}
for _,spec in ipairs(SPECS) do
	local old=findLogical(town,spec); if not old then stop("authoritative original missing: "..spec.logical) end
	records[spec.key]={spec=spec,original=old,parent=old.Parent,name=old.Name,attributes=old:GetAttributes()}
end

-- Native-source resolver: exact/normally equivalent names only, recursively.
local importRoot=ServerStorage:FindFirstChild(IMPORT_FOLDER_NAME)
if not importRoot then stop("missing ServerStorage."..IMPORT_FOLDER_NAME) end
local function findNative(templateName)
	local matches={}
	if normalized(importRoot.Name)==normalized(templateName) then table.insert(matches,importRoot) end
	for _,candidate in ipairs(importRoot:GetDescendants()) do
		if (candidate:IsA("Model") or candidate:IsA("Folder") or candidate:IsA("BasePart")) and normalized(candidate.Name)==normalized(templateName) then table.insert(matches,candidate) end
	end
	-- Prefer an outer filename wrapper over a nested same-named model only when both own exactly the same MeshParts.
	table.sort(matches,function(a,b) return #a:GetFullName()<#b:GetFullName() end)
	if #matches==0 then return nil end
	if #matches>1 then
		local a,b=meshPartsOf(matches[1]),meshPartsOf(matches[2]); local set={}; for _,p in ipairs(a) do set[p]=true end
		local same=#a==#b; for _,p in ipairs(b) do if not set[p] then same=false end end
		if not same then stop("ambiguous native source for "..templateName..": "..matches[1]:GetFullName().." | "..matches[2]:GetFullName()) end
	end
	return matches[1]
end

local nativeTotal,emptyParts,unknownParts=0,0,0
for _,spec in ipairs(SPECS) do
	local source=findNative(spec.template); if not source then stop("missing verified native source: "..spec.template) end
	local parts=partsOf(source); if #parts~=spec.count then stop(spec.template.." BasePart count="..#parts.." expected="..spec.count) end
	local palette=PALETTES[spec.key]; local seen={}
	for _,part in ipairs(parts) do
		if not part:IsA("MeshPart") then stop(spec.template.." contains non-MeshPart geometry: "..part:GetFullName()) end
		local role=roleOf(part.Name,palette); if not role then unknownParts+=1 else if seen[role] then stop(spec.template.." duplicate semantic role: "..role) end; seen[role]=true end
		if tostring(part.MeshId)=="" or part.Transparency>=1 or part.Size.X<=0 or part.Size.Y<=0 or part.Size.Z<=0 then emptyParts+=1 end
	end
	records[spec.key].source=source; nativeTotal+=#parts
end
if nativeTotal~=33 or emptyParts~=0 or unknownParts~=0 then stop(string.format("native source preflight failed parts=%d empty=%d unknown=%d",nativeTotal,emptyParts,unknownParts)) end

local function majorityProperty(oldParts,property)
	local counts,values={},{ }
	for _,part in ipairs(oldParts) do
		local value=part[property]; local key=tostring(value); counts[key]=(counts[key] or 0)+1; values[key]=value
	end
	local bestKey,bestCount=nil,-1; for key,count in pairs(counts) do if count>bestCount then bestKey,bestCount=key,count end end
	return values[bestKey]
end
local function physicalSnapshot(original)
	local oldParts=partsOf(original); if #oldParts==0 then stop("authoritative original has no BasePart: "..original:GetFullName()) end
	local state={}
	for _,property in ipairs({"Anchored","CanCollide","CanTouch","CanQuery","CollisionGroup","CastShadow"}) do state[property]=majorityProperty(oldParts,property) end
	return state
end
local function applyPhysical(model,state)
	for _,part in ipairs(partsOf(model)) do for property,value in pairs(state) do part[property]=value end end
end
local function styleNative(model,spec)
	local palette=PALETTES[spec.key]
	for _,part in ipairs(partsOf(model)) do
		local role=roleOf(part.Name,palette); local style=role and palette[role]
		if not style then error("unknown prepared semantic part: "..part.Name) end
		part.Color=Color3.fromRGB(style[1],style[2],style[3]); part.Material=style[4]
	end
end

-- Snapshot protected transforms before any V3 Workspace mutation.
local plazaCF,plazaSize=plaza.CFrame,plaza.Size
local future=Workspace:FindFirstChild("AnimalKingdomFuturePlayerPlots")
local futureSnapshot={}
if future then for _,part in ipairs(future:GetDescendants()) do if part:IsA("BasePart") then futureSnapshot[part]={cf=part.CFrame,size=part.Size} end end end
local function isOriginalOrDescendant(instance)
	for _,record in pairs(records) do if instance==record.original or instance:IsDescendantOf(record.original) then return true end end
	return false
end
local protectedParts={}
for _,part in ipairs(town:GetDescendants()) do if part:IsA("BasePart") and not isOriginalOrDescendant(part) then protectedParts[part]={cf=part.CFrame,size=part.Size} end end

-- Existing paths are immutable in this buildings-only commit.
local existingPaths=town:FindFirstChild("Paths")
local pathSnapshot={}
if existingPaths then
	for _,part in ipairs(partsOf(existingPaths)) do
		pathSnapshot[part]={parent=part.Parent,cf=part.CFrame,size=part.Size,color=part.Color,material=part.Material,transparency=part.Transparency}
	end
end

-- Phase 1: prepare all eight unparented replacements. Originals remain untouched.
local prepared={}
local prepareOk,prepareReason=pcall(function()
	for _,spec in ipairs(SPECS) do
		local record=records[spec.key]; local oldCF,oldSize=boundingBox(record.original)
		local replacement=asModel(record.source,record.name.."_V3_PENDING")
		local _,nativeSize=replacement:GetBoundingBox()
		local ratios={oldSize.X/nativeSize.X,oldSize.Y/nativeSize.Y,oldSize.Z/nativeSize.Z}
		local sorted={ratios[1],ratios[2],ratios[3]}; table.sort(sorted); local chosen=sorted[2]
		local spread=(sorted[3]-sorted[1])/math.max(chosen,1e-9)
		print("AK_NATIVE_SCALE_CHECK"); print("building="..spec.key); print("ratioX="..ratios[1]); print("ratioY="..ratios[2]); print("ratioZ="..ratios[3]); print("chosenScale="..chosen); print("ratioSpread="..spread)
		if spread>SCALE_RATIO_TOLERANCE then replacement:Destroy(); error("non-proportional native source for "..spec.key) end
		replacement:ScaleTo(replacement:GetScale()*chosen)
		local newCF=replacement:GetBoundingBox(); replacement:PivotTo(oldCF*newCF:Inverse()*replacement:GetPivot())
		styleNative(replacement,spec); record.physical=physicalSnapshot(record.original); applyPhysical(replacement,record.physical)
		for attribute,value in pairs(record.attributes) do replacement:SetAttribute(attribute,value) end
		replacement:SetAttribute("AK_NativeTownMaterialV3",true)
		local checkCF,checkSize=replacement:GetBoundingBox(); local centerDelta=(checkCF.Position-oldCF.Position).Magnitude; local sizeDelta=(checkSize-oldSize).Magnitude
		local orientationMatch=checkCF.RightVector:Dot(oldCF.RightVector)>=DOT_TOLERANCE and checkCF.UpVector:Dot(oldCF.UpVector)>=DOT_TOLERANCE and checkCF.LookVector:Dot(oldCF.LookVector)>=DOT_TOLERANCE
		print("AK_NATIVE_REPLACEMENT_ALIGNMENT"); print("building="..spec.key); print("oldCenter="..tostring(oldCF.Position)); print("newCenter="..tostring(checkCF.Position)); print("oldSize="..tostring(oldSize)); print("newSize="..tostring(checkSize)); print("centerDelta="..centerDelta); print("sizeDelta="..sizeDelta); print("orientationMatch="..tostring(orientationMatch))
		if centerDelta>.01 or sizeDelta>.05 or not orientationMatch then replacement:Destroy(); error("native replacement alignment failed for "..spec.key) end
		record.oldCF,record.oldSize,record.replacement=oldCF,oldSize,replacement; prepared[#prepared+1]=record
	end
end)
if not prepareOk or #prepared~=8 then
	for _,record in ipairs(prepared) do if record.replacement then record.replacement:Destroy() end end
	stop("precommit preparation failed; all originals remain live: "..tostring(prepareReason or #prepared))
end
for _,record in pairs(records) do if record.original.Parent~=record.parent or record.original.Name~=record.name then for _,item in ipairs(prepared) do item.replacement:Destroy() end; stop("original changed during precommit: "..record.spec.key) end end
print("AK_NATIVE_COMMIT_PRECHECK"); print("preparedReplacements=8/8"); print("nativeMeshParts="..nativeTotal); print("emptyMeshParts="..emptyParts); print("unknownSemanticParts="..unknownParts); print("allAlignmentChecks=true"); print("allOriginalsStillPresent=true")

local propertySnapshot={}; local addedLights={}
local function remember(object,properties)
	if propertySnapshot[object] then return end; local state={}; for _,property in ipairs(properties) do state[property]=object[property] end; propertySnapshot[object]=state
end
local function polishSimple(root,kind)
	if not root then return end
	local parts=partsOf(root)
	for _,part in ipairs(parts) do
		remember(part,{"Color","Material","MaterialVariant","Transparency","Reflectance","CastShadow"}); local n=string.lower(part.Name)
		if kind=="fence" or kind=="bench" then part.Color=Color3.fromRGB(132,86,52)
		elseif kind=="lamp" then part.Color=(n:find("light") or n:find("glass")) and Color3.fromRGB(255,220,125) or Color3.fromRGB(66,53,43)
		elseif kind=="planter" then part.Color=(n:find("leaf") or n:find("bush") or n:find("flower")) and Color3.fromRGB(105,145,96) or Color3.fromRGB(151,120,83) end
		if not part:IsA("MeshPart") then part.Material=(kind=="lamp" and Enum.Material.Metal or Enum.Material.Wood) end
	end
	if kind=="lamp" and #parts>0 and not root:FindFirstChild("AK_TownPolishLight",true) then local host=parts[1]; for _,part in ipairs(parts) do if part.Position.Y>host.Position.Y then host=part end end; local light=Instance.new("PointLight"); light.Name="AK_TownPolishLight"; light.Color=Color3.fromRGB(255,220,145); light.Brightness=.8; light.Range=10; light.Parent=host; addedLights[#addedLights+1]=light end
end
local function polishSign(root)
	if not root then return end
	for _,item in ipairs(root:GetDescendants()) do
		if item:IsA("TextLabel") then remember(item,{"TextColor3","TextStrokeColor3","TextStrokeTransparency","Font","BackgroundTransparency"}); item.Font=Enum.Font.FredokaOne; item.TextColor3=Color3.fromRGB(248,224,166); item.TextStrokeColor3=Color3.fromRGB(72,48,35); item.TextStrokeTransparency=.15; item.BackgroundTransparency=1
		elseif item:IsA("BasePart") then remember(item,{"Color","Material"}); item.Color=Color3.fromRGB(117,78,52) end
	end
end
local rollback=nil
local function restore(reason)
	warn("AK_NATIVE_V3_ATOMIC_ROLLBACK: "..tostring(reason))
	for _,record in pairs(records) do if record.replacement then record.replacement:Destroy() end; if record.original then record.original.Name=record.name; record.original.Parent=record.parent end end
	for object,state in pairs(propertySnapshot) do if object.Parent then for property,value in pairs(state) do object[property]=value end end end
	for _,light in ipairs(addedLights) do if light.Parent then light:Destroy() end end
	Workspace:SetAttribute(MARKER,nil); if rollback then rollback:Destroy() end
	error("Native town material V3 commit failed and restored all originals: "..tostring(reason),0)
end

local commitOk,commitReason=pcall(function()
	rollback=Instance.new("Folder"); rollback.Name=ROLLBACK_NAME; rollback:SetAttribute("Purpose","Eight authoritative pre-V3 buildings only"); rollback.Parent=ServerStorage
	for _,spec in ipairs(SPECS) do local record=records[spec.key]; record.original.Parent=rollback end
	for _,spec in ipairs(SPECS) do local record=records[spec.key]; record.replacement.Name=record.name; record.replacement.Parent=record.parent end
	polishSimple(town:FindFirstChild("Fence"),"fence"); polishSimple(town:FindFirstChild("Benches"),"bench"); polishSimple(town:FindFirstChild("Lights"),"lamp"); polishSimple(town:FindFirstChild("Planters"),"planter")
	polishSign(town:FindFirstChild("TradingHallSign",true)); polishSign(town:FindFirstChild("RewardsSign",true))
end)
if not commitOk then restore(commitReason) end

local validationOk,validationReason=pcall(function()
	for _,spec in ipairs(SPECS) do
		local record=records[spec.key]; local replacement=record.replacement; local parts=partsOf(replacement)
		if replacement.Parent~=record.parent or replacement.Name~=record.name or replacement:GetAttribute("AK_NativeTownMaterialV3")~=true then error("committed hierarchy/marker mismatch: "..spec.key) end
		if #parts~=spec.count then error("committed MeshPart count mismatch: "..spec.key) end
		local palette=PALETTES[spec.key]; local semantic={}
		for _,part in ipairs(parts) do
			if not part:IsA("MeshPart") or tostring(part.MeshId)=="" or part.Transparency>=1 then error("committed native mesh invalid: "..part:GetFullName()) end
			local role=roleOf(part.Name,palette); local expected=role and palette[role]; if not expected then error("committed semantic invalid: "..part.Name) end
			semantic[role]=true; if part.Color~=Color3.fromRGB(expected[1],expected[2],expected[3]) or part.Material~=expected[4] then error("committed style mismatch: "..part.Name) end
		end
		local cf,size=replacement:GetBoundingBox(); if (cf.Position-record.oldCF.Position).Magnitude>.01 or (size-record.oldSize).Magnitude>.05 or not sameTransform(cf,record.oldCF) then error("committed bounds mismatch: "..spec.key) end
		local semanticCount,semanticNames=0,{}; for role in pairs(semantic) do semanticCount+=1; semanticNames[#semanticNames+1]=role end; table.sort(semanticNames)
		print("AK_NATIVE_COMMITTED_MODEL_VALIDATION"); print("model="..spec.key); print("expectedMeshParts="..spec.count); print("actualMeshParts="..#parts); print("MeshIdsNonempty="..#parts); print("semanticNames="..semanticCount); print("paletteMatch=true"); print("transparencyVisible="..#parts); print("boundingBoxMatch=true"); print("parent="..replacement.Parent:GetFullName()); print("logicalName="..replacement.Name); print("AK_NativeTownMaterialV3=true")
		print("semanticRoleList="..table.concat(semanticNames,","))
	end
	if plaza.Size~=plazaSize or not sameTransform(plaza.CFrame,plazaCF) then error("TownPlaza changed") end
	for part,state in pairs(futureSnapshot) do if not part.Parent or part.Size~=state.size or not sameTransform(part.CFrame,state.cf) then error("future plot changed") end end
	for part,state in pairs(protectedParts) do if not part.Parent or part.Size~=state.size or not sameTransform(part.CFrame,state.cf) then error("unrelated town BasePart transform changed: "..part.Name) end end
	local currentPaths=town:FindFirstChild("Paths")
	local moved,resized,rotated,recolored,deleted=0,0,0,0,0
	for part,state in pairs(pathSnapshot) do
		if not part.Parent then deleted+=1 else
			if part.Parent~=state.parent or (part.Position-state.cf.Position).Magnitude>POSITION_TOLERANCE then moved+=1 end
			if (part.Size-state.size).Magnitude>SIZE_TOLERANCE then resized+=1 end
			if part.CFrame.RightVector:Dot(state.cf.RightVector)<DOT_TOLERANCE or part.CFrame.UpVector:Dot(state.cf.UpVector)<DOT_TOLERANCE or part.CFrame.LookVector:Dot(state.cf.LookVector)<DOT_TOLERANCE then rotated+=1 end
			if part.Color~=state.color or part.Material~=state.material or part.Transparency~=state.transparency then recolored+=1 end
		end
	end
	local currentPathParts=currentPaths and partsOf(currentPaths) or {}; local added=0
	for _,part in ipairs(currentPathParts) do if not pathSnapshot[part] then added+=1 end end
	if (existingPaths~=nil)~=(currentPaths~=nil) or moved>0 or resized>0 or rotated>0 or recolored>0 or added>0 or deleted>0 then error("existing path preservation validation failed") end
	print("AK_PATH_PRESERVATION_V3"); print("ExistingPathsFolder="..tostring(existingPaths~=nil)); print("ExistingPathParts="..#currentPathParts); print("PathPartsMoved="..moved); print("PathPartsResized="..resized); print("PathPartsRotated="..rotated); print("PathPartsRecolored="..recolored); print("PathPartsAdded="..added); print("PathPartsDeleted="..deleted)
	print("AK_NATIVE_V3_POST_COMMIT"); print("TownPlazaUnchanged=true"); print("FuturePlotTransformsUnchanged=true"); print("UnrelatedTownTransformsUnchanged=true"); print("ExistingPathsUnchanged=true"); print("NewPathsCreated=0")
end)
if not validationOk then restore(validationReason) end

Workspace:SetAttribute(MARKER,true)
local preview=Workspace:FindFirstChild(PREVIEW_NAME); if preview then preview:Destroy() end
print("ANIMAL KINGDOM NATIVE TOWN BUILDING COMMIT V3 COMPLETE")
print("Native models=8"); print("Native MeshParts=33"); print("TownPlazaUnchanged=true"); print("FuturePlotTransformsUnchanged=true"); print("UnrelatedTownTransformsUnchanged=true"); print("ExistingPathsUnchanged=true"); print("NewPathsCreated=0"); print("Rollback="..rollback:GetFullName()); print("PreviewRemovedAfterValidation="..tostring(preview~=nil)); print("ExtraWorkspaceImportsDeleted=0"); print("Script Source writes=0")
