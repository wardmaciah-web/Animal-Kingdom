local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Pets = require(ReplicatedStorage.SharedSource.Datas.PetDatabase)

local Controller = Knit.CreateController({ Name = "AnimalKingdomController" })
local DataController
local SanctuaryService

local function formatNumber(value)
	local suffixes = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, suffix in ipairs(suffixes) do
		if value >= suffix[1] then return string.format("%.2f%s", value / suffix[1], suffix[2]) end
	end
	return tostring(math.floor(value))
end

local function rounded(parent)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = parent
end

function Controller:CreateUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AnimalKingdomUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "CurrencyPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.fromScale(0.5, 0.025)
	panel.Size = UDim2.fromScale(0.46, 0.13)
	panel.BackgroundColor3 = Color3.fromRGB(31, 66, 42)
	panel.BackgroundTransparency = 0.08
	panel.Parent = gui
	rounded(panel)
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(280, 86)
	constraint.MaxSize = Vector2.new(680, 125)
	constraint.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0.025, 0)
	layout.Parent = panel

	local function label(name)
		local value = Instance.new("TextLabel")
		value.Name = name
		value.Size = UDim2.fromScale(0.29, 0.72)
		value.BackgroundTransparency = 1
		value.TextColor3 = Color3.new(1, 1, 1)
		value.TextScaled = true
		value.Font = Enum.Font.GothamBold
		value.Parent = panel
		local textConstraint = Instance.new("UITextSizeConstraint")
		textConstraint.MinTextSize = 12
		textConstraint.MaxTextSize = 24
		textConstraint.Parent = value
		return value
	end

	local coins = label("ForestCoins")
	local tokens = label("FriendshipTokens")
	local collect = Instance.new("TextButton")
	collect.Name = "CollectButton"
	collect.Size = UDim2.fromScale(0.3, 0.68)
	collect.BackgroundColor3 = Color3.fromRGB(241, 188, 61)
	collect.TextColor3 = Color3.fromRGB(49, 39, 14)
	collect.Text = "COLLECT"
	collect.TextScaled = true
	collect.Font = Enum.Font.GothamBold
	collect.Parent = panel
	rounded(collect)
	local buttonConstraint = Instance.new("UITextSizeConstraint")
	buttonConstraint.MinTextSize = 13
	buttonConstraint.MaxTextSize = 22
	buttonConstraint.Parent = collect
	collect.Activated:Connect(function() SanctuaryService:Collect() end)

	local inventory = Instance.new("ScrollingFrame")
	inventory.Name = "PetInventory"
	inventory.AnchorPoint = Vector2.new(0, 1)
	inventory.Position = UDim2.fromScale(0.025, 0.97)
	inventory.Size = UDim2.fromScale(0.32, 0.36)
	inventory.BackgroundColor3 = Color3.fromRGB(31, 66, 42)
	inventory.BackgroundTransparency = 0.08
	inventory.AutomaticCanvasSize = Enum.AutomaticSize.Y
	inventory.CanvasSize = UDim2.new()
	inventory.ScrollBarThickness = 7
	inventory.Parent = gui
	rounded(inventory)
	local inventoryConstraint = Instance.new("UISizeConstraint")
	inventoryConstraint.MinSize = Vector2.new(250, 180)
	inventoryConstraint.MaxSize = Vector2.new(440, 390)
	inventoryConstraint.Parent = inventory
	local inventoryLayout = Instance.new("UIListLayout")
	inventoryLayout.Padding = UDim.new(0, 6)
	inventoryLayout.Parent = inventory

	local renderedSignature = ""
	local function renderInventory(data)
		local displayed = {}
		for _, id in ipairs(data.DisplayedPetIds or {}) do displayed[id] = true end
		local signature = tostring(#(data.OwnedPets or {})) .. ":" .. table.concat(data.DisplayedPetIds or {}, ",")
		if signature == renderedSignature then return end
		renderedSignature = signature
		for _, child in ipairs(inventory:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
		for _, owned in ipairs(data.OwnedPets or {}) do
			local definition = Pets[owned.PetId]
			if definition then
				local button = Instance.new("TextButton")
				button.Name = owned.UniquePetId
				button.Size = UDim2.new(1, -12, 0, 52)
				button.BackgroundColor3 = displayed[owned.UniquePetId] and Color3.fromRGB(241, 188, 61) or Color3.fromRGB(70, 112, 78)
				button.TextColor3 = Color3.new(1, 1, 1)
				button.Text = string.format("%s [%s]  %s/s", definition.Name, owned.Mutation, formatNumber(definition.CoinsPerSecond))
				button.TextScaled = true
				button.Font = Enum.Font.GothamMedium
				button.Parent = inventory
				rounded(button)
				button.Activated:Connect(function()
					SanctuaryService:SetPetDisplayed(owned.UniquePetId, not displayed[owned.UniquePetId])
				end)
			end
		end
	end

	task.spawn(function()
		while gui.Parent do
			local data = DataController:GetPlayerData()
			if data then
				coins.Text = "Forest Coins\n" .. formatNumber(data.ForestCoins or 0)
				tokens.Text = "Friendship\n" .. formatNumber(data.FriendshipTokens or 0)
				collect.Text = "COLLECT\n" .. formatNumber(data.UncollectedSanctuaryCoins or 0)
				renderInventory(data)
			end
			task.wait(0.5)
		end
	end)
end

function Controller:KnitStart()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("AnimalKingdomUI")
	-- The production StarterGui package owns the full simulator interface. Check
	-- the source container as well as PlayerGui so startup order cannot race this.
	local productionSource = StarterGui:FindFirstChild("AnimalKingdomUI")
	if productionSource or (existing and existing:GetAttribute("ProductionUI")) then return end
	if existing then existing:Destroy() end
	self:CreateUI()
end

function Controller:KnitInit()
	DataController = Knit.GetController("DataController")
	SanctuaryService = Knit.GetService("SanctuaryService")
end

return Controller
