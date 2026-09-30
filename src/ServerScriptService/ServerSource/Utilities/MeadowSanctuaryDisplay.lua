-- Existing authoritative DisplayedPetIds rendered on the existing authored wood.
-- The historic module name is retained so SanctuaryService has one display owner.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(RS.Packages.Knit)
local Appearance = require(RS.Shared.Gameplay.PetAppearance)
local Definitions = require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Geometry = require(RS.Shared.Gameplay.PetVisualGeometry)
local SlotLayout=require(script.Parent.SanctuarySlotLayout)
local M = {}
local layouts = setmetatable({}, { __mode = "k" })
local queued, playerConnections = {}, {}

local function layoutFor(display)
	local cached = layouts[display]
	if cached then return cached end
	local slots, highest = {}, -math.huge
 local anchors=display:FindFirstChild("PetDisplaySlots",true)
 if anchors then
  for _,anchor in ipairs(anchors:GetChildren()) do
   local id=anchor:GetAttribute("SlotId") or tonumber(anchor.Name:match("^Slot_(%d+)$"))
   local cf=anchor:IsA("Attachment") and anchor.WorldCFrame or (anchor:IsA("BasePart") and anchor.CFrame)
   if id and cf then
    local fill=Geometry.Number(anchor:GetAttribute("FootprintFill"),.82,.7,.85)
    slots[id]={Instance=anchor,Surface=cf.Position,Rotation=cf.Rotation,SurfaceMode=anchor:GetAttribute("SurfaceSource") or "AuthoredAnchor",
     Limits=Vector3.new(Geometry.Number(anchor:GetAttribute("UsableWidth"),5,1,30)*fill,Geometry.Number(anchor:GetAttribute("VisibleHeight"),6,1,30),Geometry.Number(anchor:GetAttribute("UsableDepth"),5,1,30)*fill)}
   end
  end
  layouts[display]=slots;return slots
 end
	for _, slot in ipairs(display:GetChildren()) do
		local id = tonumber(slot.Name:match("^PetSlot_(%d+)$"))
		if id and (slot:IsA("Model") or slot:IsA("BasePart")) then
			local bounds = Geometry.Measure(slot, CFrame.new())
			if bounds then
				slots[id] = { Instance = slot, Bounds = bounds, Center = bounds.Center }
				highest = math.max(highest, bounds.Max.Y)
			end
		end
	end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances = { display }
	ray.RespectCanCollide = true
	for _, info in pairs(slots) do
		local nearest = math.huge
		for _, other in pairs(slots) do
			if other ~= info then
				local offset = other.Center - info.Center
				local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if distance > 0.1 then nearest = math.min(nearest, distance) end
			end
		end
		-- Live bleacher mesh bounds are 22 studs; their real slot spacing is only 4.5.
		-- Neighbor separation is a hard limit, including meshes with inflated bounds.
		local width = math.min(info.Bounds.Size.X, nearest * 0.96, 12)
		local depth = math.min(info.Bounds.Size.Z, nearest * 0.96, 12)
		info.Limits = Vector3.new(width * 0.78, math.min(math.max(width, depth) * 1.1, 6), depth * 0.78)
		local top = info.Instance:FindFirstChild("PetDisplaySurface", true)
		if top and top:IsA("Attachment") then
			info.Surface = top.WorldPosition
			info.SurfaceMode = "AuthoredAttachment"
		else
			local hit = workspace:Raycast(Vector3.new(info.Center.X, highest + 4, info.Center.Z), Vector3.new(0, -math.max(64, highest - info.Bounds.Min.Y + 12), 0), ray)
			info.Surface = Vector3.new(info.Center.X, hit and hit.Position.Y or info.Bounds.Max.Y, info.Center.Z)
			info.SurfaceMode = hit and "DisplayRaycast" or "BoundsFallback"
		end
		-- Identity is the established front of current wood tiers. Future authored
		-- overrides can orient displays without changing animal or placement scripts.
		info.Rotation = Geometry.Rotation(info.Instance:GetAttribute("PetDisplayRotation") or display:GetAttribute("PetDisplayRotation"))
	end
	layouts[display] = slots
	return slots
end

function M.GetSlot(player,slotId)
 local plot=Knit.GetService('PlotService'):GetPlot(player)
 local display=SlotLayout.FindDisplay(plot)
 return display and layoutFor(display)[slotId]
end

local function signature(pet)
	return table.concat({ pet.PetId, tostring(pet.Cosmetic), tostring(pet.Mutation), tostring(pet.Shiny), tostring(pet.Prismatic),tostring(pet.Weight),tostring(pet.CoinsPerSecond) }, ":")
end

local function sync(player)
	local data = Knit.GetService("PlayerDataService"):Get(player)
	local plot = Knit.GetService("PlotService"):GetPlot(player)
	if not data or not plot then return end
	local display = SlotLayout.FindDisplay(plot)
	if not display then return end
	local root = workspace:FindFirstChild("Sanctuaries")
	if not root then root = Instance.new("Folder"); root.Name = "Sanctuaries"; root.Parent = workspace end
	local folder = root:FindFirstChild(tostring(player.UserId))
	if not folder then folder = Instance.new("Folder"); folder.Name = tostring(player.UserId); folder.Parent = root end
	local pets = folder:FindFirstChild("DisplayedPets")
	if not pets then pets = Instance.new("Folder"); pets.Name = "DisplayedPets"; pets.Parent = folder end
	local owned, keep = {}, {}
	for _, pet in ipairs(data.Pets) do owned[pet.UID] = pet end
	local slots = layoutFor(display)
 -- Plot assignment and profile loading can complete in either order.
 local capacity=0;for _ in pairs(slots)do capacity+=1 end;capacity=math.min(70,capacity)
 Knit.GetService('PetService'):ReconcileSanctuary(player,slots)
 if data.SanctuaryCapacity~=capacity then
  data.SanctuaryCapacity=capacity
  Knit.GetService('PlayerDataService'):Publish(player,'SanctuaryCapacity')
 end
 local approach=folder:FindFirstChild('ManageSanctuary');if approach then approach:Destroy() end
 local interactions=folder:FindFirstChild('SlotInteractions')
 if not interactions then interactions=Instance.new('Folder');interactions.Name='SlotInteractions';interactions.Parent=folder end
 local active=owned[data.ActiveHeldPetUID]
 for slotId,slot in pairs(slots)do
  local name='Slot_'..slotId
  local anchor=interactions:FindFirstChild(name)
  if not anchor then
   anchor=Instance.new('Part');anchor.Name=name;anchor.Size=Vector3.new(.15,.15,.15)
   anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false
   anchor.Position=slot.Surface;anchor:SetAttribute('SlotId',slotId);anchor.Parent=interactions
   local prompt=Instance.new('ProximityPrompt');prompt.Name='SanctuaryPetSlotPrompt'
   prompt.MaxActivationDistance=9;prompt.HoldDuration=.1;prompt.RequiresLineOfSight=false
   prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
   prompt:SetAttribute('OwnerUserId',player.UserId);prompt:SetAttribute('SlotId',slotId);prompt.Parent=anchor
   game:GetService('CollectionService'):AddTag(prompt,'SanctuaryPetSlotPrompt')
  end
  local prompt=anchor.SanctuaryPetSlotPrompt
  prompt.ActionText=(data.SanctuaryPetSlots[slotId] or '')~='' and 'SWAP' or 'PLACE'
  prompt.ObjectText='Sanctuary Slot '..slotId
  prompt.Enabled=active~=nil and active.Location=='Held'
 end
	for slotId, uid in ipairs(data.SanctuaryPetSlots or {}) do
		local pet = owned[uid]
		local def = pet and Definitions[pet.PetId]
		local slot = slots[slotId]
		if def and slot then
			local visualSignature = signature(pet)
			local model = pets:FindFirstChild(uid)
			if model and model:GetAttribute("MeadowVisualSignature") ~= visualSignature then model:Destroy(); model = nil end
			if not model then
				model = Appearance.Create(pet, "Display")
				if model then
					model.Name = uid
     for _,label in ipairs(model:GetDescendants())do if label:IsA("BillboardGui")then label.Enabled=false end end
					model:SetAttribute("MeadowVisualSignature", visualSignature)
					model:SetAttribute("BaseIncomePerSecond", def.BaseIncomePerSecond or def.CoinsPerSecond)
     model:SetAttribute("CoinsPerSecond",pet.CoinsPerSecond)
					model:SetAttribute("OwnerUserId", player.UserId)
					model.Parent = pets
				end
			end
			if model then
				keep[model] = true
				-- Unchanged visual records need no re-scaling or replicated PivotTo.
				if model:GetAttribute("SlotId") ~= slotId or model:GetAttribute("DisplayVersion") ~= 4 then
					local rotation = slot.Rotation * Geometry.Rotation(def.SanctuaryRotation or def.DisplayRotation or def.ModelRotation)
					local individualFit=(model:GetAttribute("WeightVisualScale") or 1)/require(RS.Shared.Gameplay.Definitions.PetWeightDefinitions).MaxVisualScale
     local bounds = Geometry.Fit(model, slot.Limits, rotation, individualFit*(def.SanctuaryScale or def.DisplayScale or 1))
					if bounds then
						model:PivotTo(Geometry.GroundCFrame(bounds, slot.Surface, rotation, 0.04, def.SanctuaryYOffset or def.DisplayYOffset))
						require(RS.Shared.Gameplay.PetLabel).Position(model)
      model:SetAttribute("SlotId", slotId)
						model:SetAttribute("DisplayVersion", 4)
						model:SetAttribute("DisplaySurfaceY", slot.Surface.Y)
						model:SetAttribute("DisplaySurfaceMode", slot.SurfaceMode)
      model:SetAttribute("DisplayBasePivot",model:GetPivot())
      game:GetService("CollectionService"):AddTag(model,"SanctuaryDisplayPet")
					end
				end
			end
		end
	end
	for _, model in ipairs(pets:GetChildren()) do
		if model:GetAttribute("MeadowVisualSignature") and not keep[model] then model:Destroy() end
	end
end

local function schedule(player)
	if queued[player] then return end
	queued[player] = true
	task.defer(function()
		queued[player] = nil
		if player.Parent == Players then sync(player) end
	end)
end

local function watch(player)
	if playerConnections[player] then return end
	playerConnections[player] = player:GetAttributeChangedSignal("PlotId"):Connect(function()
  Knit.GetService('PetService'):Publish(player)
  schedule(player)
 end)
	schedule(player)
end

function M.Start()
	if M.Started then return end
	M.Started = true
 SlotLayout.Bind()
	local profiles = Knit.GetService("ProfileService")
	profiles.Loaded:Connect(watch)
	profiles.UpdateSpecificData:Connect(function(player, path)
		if path[1] == "DisplayedPetIds" or path[1] == "Pets" or path[1] == "ActiveHeldPetUID" then schedule(player) end
	end)
	profiles.Releasing:Connect(function(player)
		if playerConnections[player] then playerConnections[player]:Disconnect(); playerConnections[player] = nil end
		queued[player] = nil
		local root = workspace:FindFirstChild("Sanctuaries")
		local folder = root and root:FindFirstChild(tostring(player.UserId))
		local approach = folder and folder:FindFirstChild('SlotInteractions')
		if approach then approach:Destroy() end
		local pets = folder and folder:FindFirstChild("DisplayedPets")
		if pets then
			for _, model in ipairs(pets:GetChildren()) do
				if model:GetAttribute("MeadowVisualSignature") then model:Destroy() end
			end
		end
	end)
	for player in pairs(profiles.Profiles) do watch(player) end
end

return M
