-- Animal Kingdom V3 native Trading Hall persistence canary.
-- Studio Command Bar script. Intentionally affects exactly one live building.

local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")

local BACKUP_NAME="AK_V3_CANARY_BACKUP"
local POSITION_TOLERANCE=.01
local SIZE_TOLERANCE=.05
local DOT_TOLERANCE=.999999
local RATIO_SPREAD_TOLERANCE=.03

local PALETTE={
	Walls={Color3.fromRGB(238,218,179),Enum.Material.SmoothPlastic},
	Timber={Color3.fromRGB(79,55,42),Enum.Material.WoodPlanks},
	Roof={Color3.fromRGB(83,82,78),Enum.Material.Slate},
	Stone={Color3.fromRGB(145,139,126),Enum.Material.Cobblestone},
	Gold={Color3.fromRGB(220,177,81),Enum.Material.SmoothPlastic},
}
local ROLES={"Walls","Timber","Roof","Stone","Gold"}

local function stop(message)
	error("AK V3 Trading Hall canary stopped: "..tostring(message),0)
end

local function partsOf(root)
	local result={}
	if not root then return result end
	if root:IsA("BasePart") then result[#result+1]=root end
	for _,item in ipairs(root:GetDescendants()) do if item:IsA("BasePart") then result[#result+1]=item end end
	return result
end

local function meshPartsOf(root)
	local result={}
	for _,part in ipairs(partsOf(root)) do if part:IsA("MeshPart") then result[#result+1]=part end end
	return result
end

local function roleOf(name)
	local compact=string.lower(name):gsub("[^%w]","")
	for _,role in ipairs(ROLES) do if compact:find(string.lower(role),1,true) then return role end end
	return nil
end

local function boundingBox(instance)
	if instance:IsA("Model") then return instance:GetBoundingBox() end
	if instance:IsA("BasePart") then return instance.CFrame,instance.Size end
	local wrapper=Instance.new("Model")
	for _,child in ipairs(instance:GetChildren()) do child:Clone().Parent=wrapper end
	local cf,size=wrapper:GetBoundingBox(); wrapper:Destroy(); return cf,size
end

local function asModel(instance,name)
	local clone=instance:Clone()
	if clone:IsA("Model") then clone.Name=name; return clone end
	local model=Instance.new("Model"); model.Name=name; clone.Parent=model; return model
end

local function orientationMatches(a,b)
	return a.RightVector:Dot(b.RightVector)>=DOT_TOLERANCE and a.UpVector:Dot(b.UpVector)>=DOT_TOLERANCE and a.LookVector:Dot(b.LookVector)>=DOT_TOLERANCE
end

local function physicalState(original)
	local parts=partsOf(original)
	if #parts~=1 then stop("authoritative gray TradingHall must contain exactly 1 BasePart; found "..#parts) end
	local part=parts[1]
	return {
		Anchored=part.Anchored, CanCollide=part.CanCollide, CanTouch=part.CanTouch,
		CanQuery=part.CanQuery, CollisionGroup=part.CollisionGroup, CastShadow=part.CastShadow,
	}
end

local function snapshotObject(instance)
	local state={instance=instance,parent=instance.Parent,name=instance.Name,attributes=instance:GetAttributes(),parts={}}
	for _,part in ipairs(partsOf(instance)) do state.parts[part]={parent=part.Parent,cf=part.CFrame,size=part.Size} end
	return state
end

local function assertSnapshotUnchanged(state,label)
	if state.instance.Parent~=state.parent or state.instance.Name~=state.name then error(label.." hierarchy changed") end
	for part,partState in pairs(state.parts) do
		if part.Parent~=partState.parent or (part.Position-partState.cf.Position).Magnitude>.001 or (part.Size-partState.size).Magnitude>.001 or not orientationMatches(part.CFrame,partState.cf) then error(label.." BasePart transform changed") end
	end
end

if ServerStorage:FindFirstChild(BACKUP_NAME) then stop("ServerStorage."..BACKUP_NAME.." already exists; no mutation performed") end

local town=Workspace:FindFirstChild("AnimalKingdomTown")
local original=town and town:FindFirstChild("TradingHall")
local imports=ServerStorage:FindFirstChild("AnimalKingdomTownNativeMaterialImports")
local source=imports and imports:FindFirstChild("TradingHall_MaterialSplit")
if not town then stop("Workspace.AnimalKingdomTown missing") end
if not original then stop("Workspace.AnimalKingdomTown.TradingHall missing") end
if not source then stop("ServerStorage.AnimalKingdomTownNativeMaterialImports.TradingHall_MaterialSplit missing") end

local oldParent,oldName=original.Parent,original.Name
local oldAttributes=original:GetAttributes()
local oldCF,oldSize=boundingBox(original)
local oldPhysical=physicalState(original)

-- Snapshot everything explicitly required to remain untouched.
local otherPaths={
	{"RewardsBuilding",town},
	{"GeneralStoreBuilding",town:FindFirstChild("DecorativeBuildings")},
	{"BlacksmithBuilding",town:FindFirstChild("DecorativeBuildings")},
	{"CentralWell",town:FindFirstChild("Decor")},
	{"MarketStand1",town:FindFirstChild("DisplayProps")},
	{"MarketStand2",town:FindFirstChild("DisplayProps")},
	{"MarketCart",town:FindFirstChild("DisplayProps")},
}
local otherSnapshots={}
for _,entry in ipairs(otherPaths) do
	local object=entry[2] and entry[2]:FindFirstChild(entry[1])
	if not object then stop("other authoritative building missing: "..entry[1]) end
	otherSnapshots[#otherSnapshots+1]=snapshotObject(object)
end
local paths=town:FindFirstChild("Paths")
local pathSnapshot=paths and snapshotObject(paths) or nil
local townGround=town:FindFirstChild("TownGround")
local plaza=townGround and townGround:FindFirstChild("TownPlaza")
if not (plaza and plaza:IsA("BasePart")) then stop("TownPlaza missing") end
local plazaCF,plazaSize=plaza.CFrame,plaza.Size

-- Validate and prepare the native replacement while it is unparented.
local sourceParts=partsOf(source)
local sourceMeshes=meshPartsOf(source)
if #sourceParts~=5 or #sourceMeshes~=5 then stop(string.format("native TradingHall requires 5 BaseParts/5 MeshParts; found %d/%d",#sourceParts,#sourceMeshes)) end
local sourceRoles={}
for _,part in ipairs(sourceParts) do
	local role=roleOf(part.Name)
	if not role or sourceRoles[role] then stop("invalid or duplicate native semantic mesh: "..part.Name) end
	sourceRoles[role]=true
	if tostring(part.MeshId)=="" or part.Size.X<=0 or part.Size.Y<=0 or part.Size.Z<=0 then stop("native source MeshPart invalid: "..part.Name) end
end
for _,role in ipairs(ROLES) do if not sourceRoles[role] then stop("native source missing semantic mesh: AK_"..role) end end

local replacement=asModel(source,"TradingHall_V3_CANARY_PENDING")
local prepared=false
local prepareOk,prepareReason=pcall(function()
	local _,nativeSize=replacement:GetBoundingBox()
	local ratioX,ratioY,ratioZ=oldSize.X/nativeSize.X,oldSize.Y/nativeSize.Y,oldSize.Z/nativeSize.Z
	local ratios={ratioX,ratioY,ratioZ}; table.sort(ratios); local chosen=ratios[2]
	local spread=(ratios[3]-ratios[1])/math.max(chosen,1e-9)
	print("AK_V3_CANARY_SCALE_CHECK"); print("ratioX="..ratioX); print("ratioY="..ratioY); print("ratioZ="..ratioZ); print("chosenScale="..chosen); print("ratioSpread="..spread)
	if spread>RATIO_SPREAD_TOLERANCE then error("native source is not proportional to original") end
	replacement:ScaleTo(replacement:GetScale()*chosen)
	local nativeCF=replacement:GetBoundingBox()
	replacement:PivotTo(oldCF*nativeCF:Inverse()*replacement:GetPivot())
	local seen={}
	for _,part in ipairs(partsOf(replacement)) do
		local role=roleOf(part.Name); local style=role and PALETTE[role]
		if not style or seen[role] then error("prepared semantic role invalid: "..part.Name) end
		seen[role]=true; part.Color=style[1]; part.Material=style[2]
		part.Anchored=oldPhysical.Anchored; part.CanCollide=oldPhysical.CanCollide; part.CanTouch=oldPhysical.CanTouch
		part.CanQuery=oldPhysical.CanQuery; part.CollisionGroup=oldPhysical.CollisionGroup; part.CastShadow=oldPhysical.CastShadow
	end
	for attribute,value in pairs(oldAttributes) do replacement:SetAttribute(attribute,value) end
	replacement:SetAttribute("AK_NativeTownMaterialV3",true)
	replacement:SetAttribute("AK_V3PersistenceCanary",true)
	local newCF,newSize=replacement:GetBoundingBox()
	local centerDelta=(newCF.Position-oldCF.Position).Magnitude
	local sizeDelta=(newSize-oldSize).Magnitude
	local orientationMatch=orientationMatches(newCF,oldCF)
	print("AK_V3_CANARY_ALIGNMENT"); print("centerDelta="..centerDelta); print("sizeDelta="..sizeDelta); print("orientationMatch="..tostring(orientationMatch))
	if centerDelta>POSITION_TOLERANCE or sizeDelta>SIZE_TOLERANCE or not orientationMatch then error("prepared replacement alignment failed") end
	prepared=true
end)
if not prepareOk or not prepared then replacement:Destroy(); stop("preparation failed; original untouched: "..tostring(prepareReason)) end

local backup=nil
local originalMoved=false
local swapOk,swapReason=pcall(function()
	backup=Instance.new("Folder"); backup.Name=BACKUP_NAME; backup:SetAttribute("Purpose","Persistent original TradingHall for V3 canary"); backup.Parent=ServerStorage
	original.Parent=backup; originalMoved=true
	replacement.Name="TradingHall"; replacement.Parent=town

	local live=town:FindFirstChild("TradingHall")
	if live~=replacement then error("live TradingHall is not prepared canary") end
	local liveParts,liveMeshes=partsOf(live),meshPartsOf(live)
	if #liveParts~=5 or #liveMeshes~=5 then error("live canary part count mismatch") end
	if live:GetAttribute("AK_NativeTownMaterialV3")~=true or live:GetAttribute("AK_V3PersistenceCanary")~=true then error("live canary attributes missing") end
	local seen={}
	for _,part in ipairs(liveParts) do
		local role=roleOf(part.Name); local style=role and PALETTE[role]
		if not style or seen[role] then error("live semantic role mismatch: "..part.Name) end
		seen[role]=true
		if part.Color~=style[1] or part.Material~=style[2] or tostring(part.MeshId)=="" then error("live semantic appearance mismatch: "..part.Name) end
	end
	for _,role in ipairs(ROLES) do if not seen[role] then error("live canary missing AK_"..role) end end
	local liveCF,liveSize=boundingBox(live)
	if (liveCF.Position-oldCF.Position).Magnitude>POSITION_TOLERANCE or (liveSize-oldSize).Magnitude>SIZE_TOLERANCE or not orientationMatches(liveCF,oldCF) then error("live canary bounds mismatch") end
	local backupOriginal=backup:FindFirstChild(oldName)
	if backupOriginal~=original or #partsOf(backupOriginal)~=1 then error("persistent original backup validation failed") end
	for index,state in ipairs(otherSnapshots) do assertSnapshotUnchanged(state,"other building "..index) end
	if pathSnapshot then assertSnapshotUnchanged(pathSnapshot,"Paths") elseif town:FindFirstChild("Paths") then error("Paths was added") end
	if plaza.Size~=plazaSize or (plaza.Position-plazaCF.Position).Magnitude>.001 or not orientationMatches(plaza.CFrame,plazaCF) then error("TownPlaza changed") end
end)

if not swapOk then
	local recoveryOk,recoveryReason=pcall(function()
		if replacement then replacement:Destroy() end
		if originalMoved then original.Name=oldName; original.Parent=oldParent end
		if backup then backup:Destroy() end
	end)
	if recoveryOk then stop("post-move failure recovered original and removed canary backup: "..tostring(swapReason)) end
	error("AK V3 canary failed; recovery could not complete. Backup preserved if available. swap="..tostring(swapReason).." recovery="..tostring(recoveryReason),0)
end

-- Deliberately no cleanup, rollback, delayed task, coroutine, or backup destruction follows.
print("AK V3 TRADING HALL CANARY COMMITTED")
print("LiveTradingHallParts=5")
print("LiveTradingHallV3=true")
print("LiveTradingHallCanary=true")
print("OriginalBackupExists=true")
print("OriginalBackupParts=1")
print("OtherBuildingsTouched=0")
print("PathsTouched=0")
print("TownPlazaTouched=0")
print("CleanupAfterSuccess=NONE")
