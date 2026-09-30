local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraDefinitions = require(ReplicatedStorage.Shared.AdminCameraDefinitions)

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("AnimalKingdomRemotes"):WaitForChild("AdminCameraControl")
local points = workspace:WaitForChild("AK_AdminCameraPoints")
local ids = {}
local labels = {}
for _, definition in ipairs(CameraDefinitions) do
	if type(definition.DisplayName) == "string" and definition.DisplayName:match("%S") then
		table.insert(ids, definition.Id)
		table.insert(labels, definition.DisplayName)
	end
end
local indices = {}
for index, id in ipairs(ids) do indices[id] = index end

local Ownership=require(ReplicatedStorage.Shared.Gameplay.CameraOwnership)
local cameraToken
local activeIndex
local deathConnection
local pointConnection
local roomConnection
local gui = Instance.new("ScreenGui")
gui.Name = "AK_AdminCameraOverlay"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100 -- Camera exit must remain above the gameplay navigation.
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.Name = "CameraBar"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -28)
bar.Size = UDim2.fromOffset(490, 112)
bar.BackgroundColor3 = Color3.fromRGB(8, 24, 48)
bar.BackgroundTransparency = 0.08
bar.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = bar
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(65, 210, 255)
stroke.Thickness = 2
stroke.Parent = bar

local title = Instance.new("TextLabel")
title.Name = "CameraName"
title.Size = UDim2.new(1, -20, 0, 53)
title.Position = UDim2.fromOffset(10, 5)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(245, 248, 252)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = bar

local function button(name, text, x, width)
	local item = Instance.new("TextButton")
	item.Name = name
	item.Text = text
	item.Size = UDim2.fromOffset(width, 34)
	item.Position = UDim2.fromOffset(x, 66)
	item.BackgroundColor3 = Color3.fromRGB(25, 125, 255)
	item.TextColor3 = Color3.new(1, 1, 1)
	item.Font = Enum.Font.GothamBold
	item.TextSize = 14
	item.Parent = bar
	local rounding = Instance.new("UICorner")
	rounding.CornerRadius = UDim.new(0, 6)
	rounding.Parent = item
	return item
end
local previous = button("Previous", "PREVIOUS", 15, 140)
local nextButton = button("Next", "NEXT", 175, 140)
local exitButton = button("ExitCamera", "EXIT CAMERA", 335, 140)

local function disconnectWatchers()
	if deathConnection then deathConnection:Disconnect(); deathConnection = nil end
	if pointConnection then pointConnection:Disconnect(); pointConnection = nil end
	if roomConnection then roomConnection:Disconnect(); roomConnection = nil end
end

local function restoreCamera()
	local wasActive = activeIndex ~= nil
	activeIndex = nil
	gui.Enabled = false
	disconnectWatchers()
 if cameraToken then Ownership.Release(cameraToken);cameraToken=nil else Ownership.RestorePlayer() end
	if wasActive then print("[WeatherAdminCamera] Returning to player camera") end
end

local function showCamera(id)
	local index = indices[id]
	if not index then return end
	local point = points:FindFirstChild(id)
	if not point or not point:IsA("BasePart") then restoreCamera(); return end
	if cameraToken then Ownership.Release(cameraToken);cameraToken=nil end
 activeIndex = index
	title.Text = "CAMERA\n" .. labels[index]
	gui.Enabled = true
 cameraToken=Ownership.Acquire("AdminCamera",function(camera)
  if camera then camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=point.CFrame end
 end,function()activeIndex=nil;gui.Enabled=false;disconnectWatchers()end)
	if not pointConnection then
		pointConnection = points.ChildRemoved:Connect(function(removed)
			if activeIndex and removed.Name == ids[activeIndex] then restoreCamera() end
		end)
	end
	if not deathConnection then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then deathConnection = humanoid.Died:Connect(restoreCamera) end
	end
	if not roomConnection then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			roomConnection = root:GetPropertyChangedSignal("CFrame"):Connect(function()
				local offset = root.Position - Vector3.new(0, 25000, 0)
				if math.abs(offset.X) >= 82 or offset.Y < -2 or offset.Y >= 38 or math.abs(offset.Z) >= 50 then
					restoreCamera()
				end
			end)
		end
	end
end

local function cycle(step)
	if not activeIndex then return end
	for offset = 1, #ids do
		local index = (activeIndex - 1 + step * offset) % #ids + 1
		if points:FindFirstChild(ids[index]) then
			remote:FireServer("Select", ids[index])
			return
		end
	end
end
previous.MouseButton1Click:Connect(function() cycle(-1) end)
nextButton.MouseButton1Click:Connect(function() cycle(1) end)
exitButton.MouseButton1Click:Connect(function()
	if activeIndex then
		restoreCamera()
		remote:FireServer("Exit")
	end
end)
remote.OnClientEvent:Connect(function(command, id)
	if command == "Open" then showCamera(id)
	elseif command == "Close" then restoreCamera() end
end)
player.CharacterAdded:Connect(restoreCamera)
