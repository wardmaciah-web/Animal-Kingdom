local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Knit =
	require(
		RS
			:WaitForChild("Packages")
			:WaitForChild("Superbullet")
	)

local Defs =
	require(
		RS
			:WaitForChild("Shared")
			:WaitForChild("Gameplay")
			:WaitForChild("Definitions")
			:WaitForChild("MeadowTreeDefinitions")
	)

local function bounds(object)

	if object:IsA("Model") then
		return object:GetBoundingBox()
	end

	return object.CFrame, object.Size
end

local function interaction(object)

	local cf, size = bounds(object)

	return Vector3.new(
		cf.Position.X,
		cf.Position.Y - size.Y / 2 + 3.25,
		cf.Position.Z
	)
end

local function rootPart(object)

	if object:IsA("BasePart") then
		return object
	end

	return object.PrimaryPart
		or object:FindFirstChildWhichIsA(
			"BasePart",
			true
		)
end

------------------------------------------------------------
-- WAIT FOR REAL RESOURCE SERVICE
------------------------------------------------------------

local resource
local deadline = os.clock() + 30

repeat

	local ok, result =
		pcall(function()
			return Knit.GetService(
				"ResourceService"
			)
		end)

	if ok and result then
		resource = result
		break
	end

	task.wait(0.2)

until os.clock() >= deadline

assert(
	resource,
	"[REAL NEW MEADOW] ResourceService unavailable"
)

-- Let the normal world services finish first.
task.wait(0.75)

print("")
print("==============================================")
print("[REAL NEW MEADOW] REGISTERING TRIPO TREES")
print("==============================================")

local found = 0
local working = 0

------------------------------------------------------------
-- ACTUAL NEW SCENE MODELS ONLY
------------------------------------------------------------

for _, tree in ipairs(workspace:GetDescendants()) do

	if tree:IsA("Model")
		and tree:GetAttribute(
			"AK_NewMeadowSceneTree"
		) == true then

		found += 1

		local tier =
			tonumber(
				tree:GetAttribute(
					"AK_MeadowTreeIndex"
				)
			)

		local poolId =
			string.format(
				"Meadow_Shakeable_%02d",
				tier
			)

		local def =
			Defs[poolId]

		if not def then

			warn(
				"[REAL NEW MEADOW] MISSING DEF:",
				tree:GetFullName()
			)

			continue
		end

		----------------------------------------------------
		-- REFRESH POSITION FROM THE ACTUAL MODEL
		----------------------------------------------------

		local pos =
			interaction(tree)

		tree:SetAttribute(
			"InteractionPosition",
			pos
		)

		tree:SetAttribute(
			"BiomeId",
			"Meadow"
		)

		tree:SetAttribute(
			"AuthoredGatherableTree",
			true
		)

		tree:SetAttribute(
			"TreeTier",
			tier
		)

		tree:SetAttribute(
			"RewardPoolId",
			poolId
		)

		tree:SetAttribute(
			"ShakeableId",
			poolId
		)

		tree:SetAttribute(
			"EggId",
			poolId
		)

		tree:SetAttribute(
			"DropTable",
			"MeadowTree"
		)

		if not CollectionService:HasTag(
			tree,
			"GatherableTree"
		) then

			CollectionService:AddTag(
				tree,
				"GatherableTree"
			)
		end

		----------------------------------------------------
		-- REGISTER IN REAL RESOURCE SERVICE
		----------------------------------------------------

		local record =
			resource:GetRecords()[tree]

		if not record then

			resource:Register(tree)

			task.wait()

			record =
				resource:GetRecords()[tree]
		end

		if not record then

			warn(
				"[REAL NEW MEADOW] REGISTER FAILED:",
				tree:GetFullName()
			)

			continue
		end

		----------------------------------------------------
		-- KEEP RECORD POSITION SYNCHRONIZED
		----------------------------------------------------

		record.InteractionPosition = pos
		record.Biome = "Meadow"
		record.Table = "MeadowTree"
		record.State = "AVAILABLE"

		tree:SetAttribute(
			"ResourceState",
			"AVAILABLE"
		)

		tree:SetAttribute(
			"RespawnAt",
			nil
		)

		----------------------------------------------------
		-- USE REAL RESOURCE SERVICE PROMPT
		----------------------------------------------------

		local root =
			rootPart(tree)

		if not root then

			warn(
				"[REAL NEW MEADOW] NO ROOT:",
				tree:GetFullName()
			)

			continue
		end

		local anchor =
			root:FindFirstChild(
				"AKTreeInteraction"
			)

		if not anchor then

			anchor =
				Instance.new(
					"Attachment"
				)

			anchor.Name =
				"AKTreeInteraction"

			anchor.Parent =
				root
		end

		anchor.WorldPosition = pos

		local prompt =
			record.Prompt

		if prompt then

			-- SAME prompt ResourceService connected to Gather().
			prompt.Parent = anchor
			prompt.Name = "GatherPrompt"

			prompt.ActionText =
				"SEARCH · "
				.. require(RS.Shared.Gameplay.PetNumberFormat).Number(def.Cost)
				.. " Forest Coins"

			prompt.ObjectText =
				def.DisplayName
				or "Meadow Tree"

			prompt.Enabled = true
			prompt.HoldDuration = 0.2
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false

			working += 1

			print(
				"[REAL NEW MEADOW] LIVE:",
				tree:GetAttribute(
					"AK_TripoMeshId"
				),
				"| tier",
				tier,
				"|",
				prompt.ActionText,
				"| position",
				math.floor(pos.X),
				math.floor(pos.Y),
				math.floor(pos.Z)
			)

		else

			warn(
				"[REAL NEW MEADOW] RECORD HAS NO PROMPT:",
				tree:GetFullName()
			)
		end
	end
end

print("")
print("Actual Tripo trees found:", found)
print("Working Search prompts:", working)

if found > 0 and working == found then

	print(
		"[REAL NEW MEADOW] SUCCESS — ALL ACTUAL NEW TREES LIVE"
	)

else

	warn(
		"[REAL NEW MEADOW] SOME ACTUAL NEW TREES FAILED"
	)
end

print("==============================================")

