local Workspace = game:GetService("Workspace")

-- The entire admin room is exempt, including camera titles and event controls.
-- Resolve it each time because runtime services may create or replace the room.
local function isProtectedAdminRoomObject(instance)
	local room = Workspace:FindFirstChild("WeatherAdminRoom")
	return room ~= nil and (instance == room or instance:IsDescendantOf(room))
end

-- Biome names in unrelated Workspace UI are not biome presentation labels.
local function isBiomeLabelScope(instance)
	local world = Workspace:FindFirstChild("World")
	local current = instance
	while current and current ~= Workspace do
		if current.Name == "BiomeLabelAnchor"
			or (current.Parent == Workspace and current.Name == "BiomeEnvironments")
			or (world ~= nil and current.Parent == world
				and (current.Name == "BiomeBlockout" or current.Name == "Biomes"))
		then
			return true
		end
		current = current.Parent
	end
	return false
end

------------------------------------------------------------
-- ANIMAL KINGDOM
-- REMOVE EVERY BIOME LABEL
--
-- Works in:
-- Studio Play Test
-- Published game
--
-- Does NOT delete biome models/floors/trees.
-- Only label/sign objects.
------------------------------------------------------------

local BIOME_NAMES = {
	"Meadow",
	"Forest",
	"Jungle",
	"Desert",
	"Snow",
	"Volcano",
	"Ocean",
	"Ancient Ruins",
	"Magical Forest",
	"Sky",
	"Prehistoric",
	"Mythical",
}

------------------------------------------------------------
-- NORMALIZE TEXT
------------------------------------------------------------

local function normalize(text)

	text = string.lower(text or "")

	text = text:gsub("_", " ")
	text = text:gsub("%s+", " ")

	return text
end

------------------------------------------------------------
-- CHECK IF TEXT IS A BIOME NAME
------------------------------------------------------------

local function containsBiomeName(text)

	local n = normalize(text)

	for _, biome in ipairs(BIOME_NAMES) do

		local b = normalize(biome)

		if string.find(
			n,
			b,
			1,
			true
			) then

			return true
		end
	end

	return false
end

------------------------------------------------------------
-- FIND THE LABEL CONTAINER TO DELETE
------------------------------------------------------------

local function getDeleteTarget(obj)

	if isProtectedAdminRoomObject(obj) then
		return nil
	end
	if not isBiomeLabelScope(obj) then
		return nil
	end

	--------------------------------------------------------
	-- Anything explicitly named BiomeSign
	--------------------------------------------------------

	local current = obj

	while current and current ~= Workspace do

		local name =
			string.lower(current.Name)

		if name == "biomesign"
			or name == "biome_sign"
			or name == "biomelabel"
			or name == "biome_label"
		then

			return current
		end

		current = current.Parent
	end

	--------------------------------------------------------
	-- GUI text containing an actual biome name
	--------------------------------------------------------

	if obj:IsA("TextLabel")
		or obj:IsA("TextButton")
	then

		if containsBiomeName(obj.Text) then

			------------------------------------------------
			-- Prefer deleting the BillboardGui/SurfaceGui
			-- instead of only the TextLabel.
			------------------------------------------------

			current = obj.Parent

			while current
				and current ~= Workspace
			do

				if current:IsA("BillboardGui")
					or current:IsA("SurfaceGui")
				then

					------------------------------------------------
					-- If GUI is inside a BiomeSign part/model,
					-- delete the whole sign.
					------------------------------------------------

					local parent =
						current.Parent

					if parent then

						local parentName =
							string.lower(
								parent.Name
							)

						if parentName == "biomesign"
							or parentName == "biome_sign"
						then

							return parent
						end
					end

					return current
				end

				current = current.Parent
			end

			------------------------------------------------
			-- Last resort: delete text itself
			------------------------------------------------

			return obj
		end
	end

	return nil
end

------------------------------------------------------------
-- CLEAN EXISTING LABELS
------------------------------------------------------------

local function cleanAll()

	local targets = {}

	for _, obj in ipairs(
		Workspace:GetDescendants()
		) do

		if isProtectedAdminRoomObject(obj) then
			continue
		end

		local target =
			getDeleteTarget(obj)

		if target
			and target.Parent
		then

			targets[target] = true
		end
	end

	local removed = 0

	for target in pairs(targets) do

		if isProtectedAdminRoomObject(target) then
			continue
		end

		if target.Parent then

			print(
				"[AK] Removing biome label:",
				target:GetFullName()
			)

			target:Destroy()

			removed += 1
		end
	end

	if removed > 0 then

		print(
			"[AK] Biome labels removed:",
			removed
		)
	end
end

------------------------------------------------------------
-- INITIAL CLEAN
------------------------------------------------------------

cleanAll()

------------------------------------------------------------
-- DELETE NEW LABELS AS SOON AS THEY SPAWN
------------------------------------------------------------

Workspace.DescendantAdded:Connect(
	function(obj)

		if isProtectedAdminRoomObject(obj) then
			return
		end

		task.defer(function()

			-- The object may have moved into the room while this was deferred.
			if isProtectedAdminRoomObject(obj) then
				return
			end

			if not obj.Parent then
				return
			end

			local target =
				getDeleteTarget(obj)

			if target and isProtectedAdminRoomObject(target) then
				return
			end

			if target
				and target.Parent
			then

				print(
					"[AK] Blocked biome label:",
					target:GetFullName()
				)

				target:Destroy()
			end
		end)
	end
)

------------------------------------------------------------
-- SAFETY PASSES FOR RUNTIME SERVICES
------------------------------------------------------------

task.delay(1, cleanAll)
task.delay(3, cleanAll)
task.delay(6, cleanAll)

print(
	"[AK] Global biome label remover active"
)
