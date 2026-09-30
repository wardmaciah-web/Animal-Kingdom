local RoomPanels = {}
local panelNames = {"PlayerControl", "ServerStatus", "Announcements", "Teleports", "EventQueue", "ActivityLog"}

local function preserveReadableCameraTitles(room)
	-- The live place also has CameraPanelTitles, which recreates legacy labels
	-- after room construction. Replace only its text; retain camera parts,
	-- SurfaceGui faces, ClickDetectors, and all camera behavior.
	local function replace(object)
		if not object:IsA("TextLabel") or object:GetAttribute("ReadableAdminTitle") then return end
		local surface = object.Parent
		local wall = room:FindFirstChild("CameraWallPanels")
		if not surface or not surface:IsA("SurfaceGui") or not wall or not object:IsDescendantOf(wall) then return end
		local label = Instance.new("TextLabel")
		label.Name = object.Name
		label:SetAttribute("ReadableAdminTitle", true)
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = object.Text
		label.TextColor3 = object.TextColor3
		label.Font = Enum.Font.GothamBold
		label.TextScaled = false
		label.TextSize = 24
		label.TextWrapped = false
		label.RichText = false
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.ZIndex = object.ZIndex
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = label
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 12
		object:Destroy()
		label.Parent = surface
	end
	local connection = room.DescendantAdded:Connect(function(object)
		-- Wait until the creator finishes assigning the label's text and style.
		task.defer(function() if object.Parent then replace(object) end end)
	end)
	room.Destroying:Once(function() connection:Disconnect() end)
	for _, object in ipairs(room:GetDescendants()) do replace(object) end
end

function RoomPanels.Attach(room)
	if room:FindFirstChild("AdminCommandCenter") then return room.AdminCommandCenter end
	local floor = room:FindFirstChild("Floor")
	local back = room:FindFirstChild("BackWall")
	if not floor or not floor:IsA("BasePart") or not back or not back:IsA("BasePart") then
		return nil, "Existing WeatherAdminRoom Floor/BackWall references are unavailable"
	end
	-- The inspected room has unused rear wall space. Derive placement from its
	-- actual floor/wall; leave the camera wall, event controls, and arrival pad alone.
	local folder = Instance.new("Folder")
	folder.Name = "AdminCommandCenter"
	local width = math.min(42, (floor.Size.X - 32) / 3)
	local height = math.min(14, (back.Size.Y - 10) / 2)
	if width < 24 or height < 10 then folder:Destroy(); return nil, "Admin room has insufficient rear wall space" end
	local spacing = (floor.Size.X - 14) / 3
	for index, name in ipairs(panelNames) do
		local column = (index - 1) % 3 - 1
		local row = math.floor((index - 1) / 3)
		-- The existing StatusPanel occupies the rear center at height 10.5.
		-- Stack the center pair above it; side panels retain their full height.
		local panelHeight = column == 0 and 10 or height
		local elevation = column == 0 and (row == 0 and 30 or 18) or (row == 0 and 28 or 11)
		local position = floor.CFrame:PointToWorldSpace(Vector3.new(column * spacing, floor.Size.Y/2 + elevation, floor.Size.Z/2 - 2.2))
		local panel = Instance.new("Part")
		panel.Name = name
		panel.Size = Vector3.new(width, panelHeight, 0.35)
		panel.CFrame = CFrame.lookAt(position, position - floor.CFrame.ZVector)
		panel.Color = Color3.fromRGB(8,24,48)
		panel.Material = Enum.Material.SmoothPlastic
		panel.Anchored = true
		panel.CanCollide = false
		panel.CanTouch = false
		panel.Parent = folder
	end
	folder.Parent = room
	preserveReadableCameraTitles(room)
	return folder
end

return RoomPanels
