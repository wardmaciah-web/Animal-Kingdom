local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local screen = script.Parent
local definitions = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EventDefinitions"))
local weatherState = ReplicatedStorage:WaitForChild("WeatherState")
-- The phone HUD exposes the same current event through its tappable context chip.
-- Suppress the full card where it otherwise covers touch navigation; timing and artwork stay unchanged.
task.spawn(function()
 local ui=screen.Parent:WaitForChild('AnimalKingdomUI')
 local function visibility()
  screen.Enabled=not ui:GetAttribute('CompactLayout')and not ui:GetAttribute('RewardRevealActive')and(ui:GetAttribute('ActiveMenu')or '')==''
 end
 for _,key in ipairs({'CompactLayout','RewardRevealActive','ActiveMenu'})do ui:GetAttributeChangedSignal(key):Connect(visibility)end
 visibility()
end)

local generation = 0
local activeKey
local activeCard
local countdownLabel
local endsAt = 0
local hasInitialSnapshot = false
local refreshQueued = false
local runningTweens = {}
local DEBUG_UI = RunService:IsStudio()

-- Artwork is UI-only. EventDefinitions remains the source for all event text.
local EVENT_CARD_IMAGES = {
	SunnySkies = "rbxassetid://88425768751804",
	RainyDay = "rbxassetid://114674921602382",
	Thunderstorm = "rbxassetid://92403835613689",
	Snowfall = "rbxassetid://76661117656518",
	Foggy = "rbxassetid://99104255943045",
	Windy = "rbxassetid://112381280370991",
	Heatwave = "rbxassetid://76106281136407",
	Aurora = "rbxassetid://80700863827597",
	BloodMoon = "rbxassetid://74180652862291",
	MeteorShower = "rbxassetid://124363674183252",
	SpiritNight = "rbxassetid://76438929387740",
	Rainbow = "rbxassetid://107219758422340",
	Chaos = "rbxassetid://131557230584021",
	Inverted = "rbxassetid://92045192481117",
	Nightmare = "rbxassetid://105268491188486",
	Void = "rbxassetid://79390179989574",
	Golden = "rbxassetid://140425806946255",
	AdminAbuse = "rbxassetid://138046290685051",
}
local IMAGE_TO_EVENT = {}
for eventId, imageId in pairs(EVENT_CARD_IMAGES) do IMAGE_TO_EVENT[imageId] = eventId end

task.spawn(function()
	local images = {}
	-- Pass typed image instances: raw content strings use the generic loader,
	-- which can report Failure for otherwise valid image/decal artwork.
	for eventId, imageId in pairs(EVENT_CARD_IMAGES) do
		local image = Instance.new("ImageLabel")
		image.Name = eventId .. "Preload"
		image.Image = imageId
		table.insert(images, image)
	end
	local ok, err = pcall(function()
		ContentProvider:PreloadAsync(images, function(imageId, status)
			if DEBUG_UI and status ~= Enum.AssetFetchStatus.Success then
				warn("[WeatherEventUI] Image preload failed: " .. tostring(IMAGE_TO_EVENT[imageId]) .. " " .. imageId .. " (" .. status.Name .. ")")
			end
		end)
	end)
	for _, image in ipairs(images) do image:Destroy() end
	if not ok then warn("[WeatherEventUI] Image preload error: " .. tostring(err)) end
end)

local function make(className, properties, parent)
	local instance = Instance.new(className)
	for property, value in pairs(properties) do
		instance[property] = value
	end
	instance.Parent = parent
	return instance
end

local function tween(instance, seconds, properties, style, direction)
	local animation = TweenService:Create(instance, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), properties)
	table.insert(runningTweens, animation)
	animation.Completed:Connect(function()
		local index = table.find(runningTweens, animation)
		if index then table.remove(runningTweens, index) end
	end)
	animation:Play()
	return animation
end

local function cancelTweens()
	local oldTweens = runningTweens
	runningTweens = {}
	for _, animation in ipairs(oldTweens) do animation:Cancel() end
end

local function formatTime(deadline)
	local seconds = math.max(0, math.ceil(deadline - workspace:GetServerTimeNow()))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function currentScale()
	local size = screen.AbsoluteSize
	return math.clamp(math.min(size.X / 500, size.Y / 330), 0.72, 1)
end

local function cardWidth(compact)
	local width = math.max(320, screen.AbsoluteSize.X)
	if compact then return math.floor(math.min(width - 24, 320, math.max(220, width * (width < 700 and 0.63 or 0.3)))) end
	return math.floor(math.min(600, math.max(260, width * (width < 700 and 0.88 or 0.52)), width - 24))
end

local ARTWORK_ASPECT_RATIO = 1.6
local function imageSize(compact)
	local width = cardWidth(compact)
	return UDim2.fromOffset(width, math.floor(width / ARTWORK_ASPECT_RATIO))
end

local function removeCard(smooth)
	generation += 1
	cancelTweens()
	local card = activeCard
	activeCard = nil
	countdownLabel = nil
	activeKey = nil
	endsAt = 0
	if not smooth then
		-- A Break fade can still be finishing when an admin starts another event.
		for _, child in ipairs(screen:GetChildren()) do
			if child.Name == "ActiveEventCard" or child.Name == "CustomEventImage" then child:Destroy() end
		end
		return
	end
	if not card then return end
	if DEBUG_UI then print("[WeatherEventUI] Hiding card for Break") end
	local scale = card:FindFirstChildOfClass("UIScale")
	if card:IsA("ImageLabel") then
		tween(card, 0.22, { ImageTransparency = 1 })
	else
		tween(card, 0.22, { BackgroundTransparency = 1 })
	end
	if scale then tween(scale, 0.22, { Scale = scale.Scale * 0.85 }) end
	for _, descendant in ipairs(card:GetDescendants()) do
		if descendant:IsA("ImageLabel") then
			tween(descendant, 0.22, { ImageTransparency = 1 })
		elseif descendant:IsA("TextLabel") then
			tween(descendant, 0.22, { TextTransparency = 1, BackgroundTransparency = 1 })
		elseif descendant:IsA("Frame") then
			tween(descendant, 0.22, { BackgroundTransparency = 1 })
		end
	end
	task.delay(0.24, function() card:Destroy() end)
end

local function createCard(definition, deadline)
	local secret = definition.IsSecret or definition.Category == "Secret"
	local accent = secret and Color3.fromRGB(246, 170, 255) or Color3.fromRGB(129, 241, 215)
	local dark = secret and Color3.fromRGB(51, 30, 75) or Color3.fromRGB(27, 61, 82)
	local card = make("Frame", {
		Name = "ActiveEventCard", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(420, 254),
		BackgroundColor3 = dark, BackgroundTransparency = 0.06, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = 1,
	}, screen)
	make("UICorner", { CornerRadius = UDim.new(0, 22) }, card)
	local stroke = make("UIStroke", { Color = accent, Thickness = secret and 3 or 2, Transparency = 0.12 }, card)
	make("UIGradient", { Color = ColorSequence.new(dark, secret and Color3.fromRGB(104, 45, 116) or Color3.fromRGB(37, 117, 137)), Rotation = 25 }, card)
	local scale = make("UIScale", { Scale = currentScale() }, card)
	make("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }, card)

	local imageArea = make("Frame", {
		Name = "EventImageArea", Position = UDim2.fromOffset(0, 22), Size = UDim2.fromOffset(94, 94),
		BackgroundColor3 = accent, BackgroundTransparency = 0.65, BorderSizePixel = 0,
	}, card)
	make("UICorner", { CornerRadius = UDim.new(0, 17) }, imageArea)
	make("UIGradient", { Color = ColorSequence.new(accent, dark), Rotation = 60 }, imageArea)
	local imageId = definition.ImageId
	if type(imageId) == "string" and imageId ~= "" then
		make("ImageLabel", { Name = "EventImage", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = imageId, ScaleType = Enum.ScaleType.Fit }, imageArea)
	else
		make("TextLabel", { Name = "FallbackIcon", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = secret and "✦" or "✧", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 58, Font = Enum.Font.GothamBold }, imageArea)
	end

	local function label(name, value, position, size, textSize, bold, color)
		local item = make("TextLabel", {
			Name = name, BackgroundTransparency = 1, Position = position, Size = size,
			Text = value, TextColor3 = color or Color3.fromRGB(255, 255, 255),
			TextSize = textSize, TextScaled = false, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
			Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
		}, card)
		make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = textSize }, item)
		return item
	end
	local badge = label("Badge", secret and "SECRET EVENT" or "KINGDOM EVENT", UDim2.fromOffset(108, 0), UDim2.new(1, -108, 0, 21), 12, true, accent)
	local title = label("Title", definition.DisplayName, UDim2.fromOffset(108, 24), UDim2.new(1, -108, 0, 37), 25, true)
	local description = label("Description", definition.Description, UDim2.fromOffset(108, 63), UDim2.new(1, -108, 0, 54), 14, false, Color3.fromRGB(235, 241, 251))
	local effects = definition.DisplayEffects or {}
	local effectsText = #effects > 0 and table.concat(effects, "  •  ") or "Event details coming soon"
	local effectsLabel = label("DisplayEffects", effectsText, UDim2.fromOffset(0, 132), UDim2.new(1, 0, 0, 55), 15, true, accent)
	local timer = label("Countdown", "Time Left: " .. formatTime(deadline), UDim2.fromOffset(0, 197), UDim2.new(1, 0, 0, 32), 18, true)
	return card, scale, stroke, imageArea, badge, title, description, effectsLabel, timer
end

local function createCustomCard(imageId, deadline)
	local card = make("ImageLabel", {
		Name = "CustomEventImage", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46), Size = imageSize(false),
		Image = imageId, ImageTransparency = 0, ImageColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Fit, ClipsDescendants = true, Visible = true, ZIndex = 10,
	}, screen)
	make("UICorner", { CornerRadius = UDim.new(0, 18) }, card)
	local scale = make("UIScale", { Scale = 1 }, card)
	-- The artwork contains no live time value. Keep a legible footer bound to
	-- the same server EndsAt snapshot used by the admin room and fallback card.
	local timer = make("TextLabel", {
		Name = "Countdown", AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -5), Size = UDim2.new(1, -14, 0, 26),
		BackgroundColor3 = Color3.fromRGB(17, 28, 42), BackgroundTransparency = 0.1,
		BorderSizePixel = 0, Text = "Time Left: " .. formatTime(deadline),
		TextColor3 = Color3.new(1, 1, 1), TextSize = 15, Font = Enum.Font.GothamBold,
		TextScaled = false, ZIndex = 11,
	}, card)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, timer)
	return card, scale, timer
end

local function showEvent(definition, eventId, key, deadline, newEvent)
	removeCard(false)
	activeKey = key
	endsAt = deadline
	local token = generation
	local imageId = EVENT_CARD_IMAGES[eventId]
	if not imageId and DEBUG_UI then warn("[WeatherEventUI] Missing card image for: " .. tostring(eventId)) end
	local custom = imageId ~= nil
	local card, scale, stroke, imageArea, badge, title, description, effectsLabel, timer
	if custom then
		card, scale, timer = createCustomCard(imageId, deadline)
		if DEBUG_UI then
			print("[WeatherEventUI] Showing custom card:", eventId, imageId)
		end
	else
		card, scale, stroke, imageArea, badge, title, description, effectsLabel, timer = createCard(definition, deadline)
	end
	activeCard = card
	countdownLabel = timer
	local baseScale = custom and 1 or currentScale()
	if custom and not newEvent then
		card.AnchorPoint = Vector2.new(1, 0)
		card.Position = UDim2.new(1, -15, 0, 15)
		card.Size = imageSize(true)
		card:SetAttribute("Docked", true)
		if DEBUG_UI then print("[WeatherEventUI] Docking custom card (joined mid-event)") end
		return
	end

	local function dock()
		if token ~= generation then return end
		if custom then
			card:SetAttribute("Docked", true)
			if DEBUG_UI then print("[WeatherEventUI] Docking custom card") end
			tween(card, 0.48, {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -15, 0, 15),
				Size = imageSize(true),
			}, Enum.EasingStyle.Quart)
			return
		end
		tween(card, 0.42, {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14),
			Size = UDim2.fromOffset(300, 122),
		}, Enum.EasingStyle.Quart)
		tween(imageArea, 0.42, { Position = UDim2.fromOffset(0, 25), Size = UDim2.fromOffset(65, 65) })
		badge.Position = UDim2.fromOffset(76, 0)
		badge.Size = UDim2.new(1, -76, 0, 16)
		badge.TextSize = 10
		title.Position = UDim2.fromOffset(76, 17)
		title.Size = UDim2.new(1, -76, 0, 27)
		title.TextSize = 18
		description.Visible = false
		effectsLabel.Position = UDim2.fromOffset(76, 46)
		effectsLabel.Size = UDim2.new(1, -76, 0, 35)
		effectsLabel.TextSize = 11
		timer.Position = UDim2.fromOffset(76, 81)
		timer.Size = UDim2.new(1, -76, 0, 20)
		timer.TextSize = 13
	end

	task.spawn(function()
		if custom then
			scale.Scale = 0.9
			tween(scale, 0.28, { Scale = baseScale }, Enum.EasingStyle.Back).Completed:Wait()
			if token ~= generation then return end
		end
		if newEvent then
			-- Exactly three visible pulses for players present when this event started.
			for _ = 1, 3 do
				if token ~= generation then return end
				tween(scale, 0.28, { Scale = baseScale * 1.055 }, Enum.EasingStyle.Sine).Completed:Wait()
				if token ~= generation then return end
				if not custom then
					tween(stroke, 0.20, { Transparency = 0.55 }, Enum.EasingStyle.Sine).Completed:Wait()
					if token ~= generation then return end
				end
				tween(scale, 0.28, { Scale = baseScale }, Enum.EasingStyle.Sine).Completed:Wait()
				if token ~= generation then return end
				if not custom then
					tween(stroke, 0.20, { Transparency = 0.12 }, Enum.EasingStyle.Sine).Completed:Wait()
				end
			end
		else
			if not custom then
				scale.Scale = baseScale * 0.92
				tween(scale, 0.26, { Scale = baseScale }, Enum.EasingStyle.Back).Completed:Wait()
			end
		end
		dock()
	end)
end

local function refreshFromState()
	local phase = weatherState:GetAttribute("Phase")
	local eventId = weatherState:GetAttribute("EventId")
	local startedAt = weatherState:GetAttribute("StartedAt")
	local deadline = weatherState:GetAttribute("EndsAt")
	local definition = type(eventId) == "string" and definitions[eventId]
	local valid = phase == "Event" and type(eventId) == "string" and eventId ~= "" and type(startedAt) == "number"
		and type(deadline) == "number" and startedAt > 0 and deadline > startedAt
	if not valid then
		if activeCard then removeCard(phase == "Break") end
		hasInitialSnapshot = true
		return
	end
	local key = eventId .. ":" .. tostring(startedAt)
	if key == activeKey then
		endsAt = deadline
		hasInitialSnapshot = true
		return
	end
	local newEvent = hasInitialSnapshot
	hasInitialSnapshot = true
	if deadline <= workspace:GetServerTimeNow() then return end
	if not definition then
		local eventName = weatherState:GetAttribute("EventName")
		if type(eventName) ~= "string" or eventName == "" then eventName = eventId end
		definition = {
			DisplayName = eventName,
			Description = "An event is active in the kingdom.",
			DisplayEffects = {}, IsSecret = false,
		}
	end
	showEvent(definition, eventId, key, deadline, newEvent)
end

weatherState.AttributeChanged:Connect(function(attribute)
	if attribute ~= "Phase" and attribute ~= "EventId" and attribute ~= "StartedAt" and attribute ~= "EndsAt" then return end
	if refreshQueued then return end
	refreshQueued = true
	task.defer(function()
		refreshQueued = false
		refreshFromState()
	end)
end)
refreshFromState()

screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if activeCard then
		if activeCard:IsA("ImageLabel") then
			activeCard.Size = imageSize(activeCard:GetAttribute("Docked") == true)
		else
			local scale = activeCard:FindFirstChildOfClass("UIScale")
			if scale then scale.Scale = currentScale() end
		end
	end
end)

task.spawn(function()
	while screen.Parent do
		if countdownLabel then
			countdownLabel.Text = "Time Left: " .. formatTime(endsAt)
		end
		task.wait(0.25)
	end
end)
