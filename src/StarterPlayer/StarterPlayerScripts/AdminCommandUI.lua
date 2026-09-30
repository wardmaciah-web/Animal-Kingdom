local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = require(ReplicatedStorage.Shared.EventDefinitions)
local Definitions = require(ReplicatedStorage.Shared.AdminCommandDefinitions)
local UI = {}
local C = {Navy=Color3.fromRGB(8,24,48),Card=Color3.fromRGB(17,40,68),Blue=Color3.fromRGB(25,125,255),Cyan=Color3.fromRGB(65,210,255),White=Color3.fromRGB(245,248,252),Muted=Color3.fromRGB(173,196,220),Red=Color3.fromRGB(224,102,111)}
UI.Colors = C

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,radius or 8)
	corner.Parent = object
end

function UI.Label(parent, text, x, y, w, h, size, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(x,y)
	label.Size = UDim2.fromOffset(w,h)
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextScaled = false
	label.TextSize = size or 18
	label.TextColor3 = color or C.White
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = false
	label.RichText = false
	label.Parent = parent
	return label
end

function UI.Button(parent, text, x, y, w, h, callback, color)
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(x,y)
	button.Size = UDim2.fromOffset(w,h)
	button.BackgroundColor3 = color or C.Blue
	button.Text = text
	button.TextColor3 = C.White
	button.Font = Enum.Font.GothamMedium
	button.TextScaled = false
	button.TextSize = 18
	button.TextWrapped = true
	button.TextXAlignment = Enum.TextXAlignment.Center
	button.TextYAlignment = Enum.TextYAlignment.Center
	button.RichText = false
	button.Parent = parent
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft=UDim.new(0,6);padding.PaddingRight=UDim.new(0,6)
	padding.PaddingTop=UDim.new(0,3);padding.PaddingBottom=UDim.new(0,3);padding.Parent=button
	round(button)
	button.Activated:Connect(callback)
	return button
end

local function scroll(parent,x,y,w,h)
	local frame = Instance.new("ScrollingFrame")
	frame.Position = UDim2.fromOffset(x,y)
	frame.Size = UDim2.fromOffset(w,h)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ScrollBarThickness = 5
	frame.ScrollBarImageColor3 = C.Cyan
	frame.ScrollingDirection = Enum.ScrollingDirection.Y
	frame.CanvasSize = UDim2.new()
	frame.Parent = parent
	return frame
end

local function surface(playerGui, part, title)
	local old = playerGui:FindFirstChild("AK_Admin_" .. part.Name)
	if old then old:Destroy() end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "AK_Admin_" .. part.Name
	gui.Adornee = part
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	-- Equal pixel density across all six screens. Short center panels use
	-- compact rows instead of shrinking/stretching a taller layout.
	local width = 900
	local height = width * part.Size.Y / part.Size.X
	gui.CanvasSize = Vector2.new(width,height)
	gui.LightInfluence = 0
	gui.MaxDistance = 160
	gui.AlwaysOnTop = false
	gui.Active = true
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1,1)
	frame.BackgroundColor3 = C.Navy
	frame.Parent = gui
	round(frame,12)
	local stroke = Instance.new("UIStroke")
	stroke.Color=C.Cyan; stroke.Thickness=2; stroke.Parent=frame
	local heading=UI.Label(frame,"ANIMAL KINGDOM  /  " .. title,20,8,width-40,34,26,C.Cyan)
	heading.Font=Enum.Font.GothamBold
	heading.TextXAlignment=Enum.TextXAlignment.Center
	local line = Instance.new("Frame")
	line.Position=UDim2.fromOffset(20,45); line.Size=UDim2.fromOffset(width-40,2); line.BorderSizePixel=0; line.BackgroundColor3=C.Blue; line.Parent=frame
	return gui,frame,width,height
end

function UI.Mount(playerGui, folder, send, notify)
	local self = {surfaces={}, selected=nil, state=nil, rosterKey=nil, eventId=nil}
	local frames = {}
	local widths = {}
	local heights = {}
	local titles = {PlayerControl="PLAYER CONTROL",ServerStatus="SERVER STATUS",Announcements="ANNOUNCEMENTS",Teleports="TELEPORTS",EventQueue="EVENT QUEUE",ActivityLog="ACTIVITY LOG"}
	for _, name in ipairs(Definitions.Panels) do
		local gui, frame, width, height = surface(playerGui,folder:WaitForChild(name),titles[name])
		table.insert(self.surfaces,gui)
		frames[name] = frame
		widths[name] = width
		heights[name] = height
	end
	local playerList = scroll(frames.PlayerControl,20,57,365,224)
	local selectedLabel = UI.Label(frames.PlayerControl,"SELECT A PLAYER",404,56,475,34,18,C.Muted)
	local playerActions = {{"TELEPORT TO PLAYER","TeleportToPlayer"},{"SPECTATE PLAYER","SpectatePlayer"},{"TELEPORT TO PLOT","TeleportToPlot"},{"RETURN PLAYER TO PLOT","ReturnPlayerToPlot"},{"BRING PLAYER","BringPlayer"},{"RESPAWN PLAYER","RespawnPlayer"},{"STOP SPECTATING","StopSpectating"}}
	local rowButtons = {}
	local function highlight()
		for id, button in pairs(rowButtons) do button.BackgroundColor3 = id == self.selected and C.Blue or C.Card end
		local selected
		for _, entry in ipairs(self.state and self.state.Players or {}) do if entry.UserId == self.selected then selected=entry; break end end
		selectedLabel.Text = selected and ("SELECTED: " .. selected.Username) or "SELECT A PLAYER"
	end
	for index, action in ipairs(playerActions) do
		UI.Button(frames.PlayerControl,action[1],404+((index-1)%2)*242,98+math.floor((index-1)/2)*46,232,39,function()
			if action[2] == "StopSpectating" then send({Action=action[2]}); return end
			if not self.selected then notify("SELECT A PLAYER FIRST",false); return end
			send({Action=action[2],TargetUserId=self.selected})
		end,action[2] == "RespawnPlayer" and C.Card or nil)
	end
	local statusLabels = {}
	local statusWidth=(widths.ServerStatus-60)/3
	local statusHeight=(heights.ServerStatus-87)/2
	for index, title in ipairs({"PLAYERS","UPTIME","CURRENT EVENT","TIME LEFT","CLAIMED PLOTS","AUTOMATIC WEATHER"}) do
		local x=20+((index-1)%3)*(statusWidth+10)
		local y=57+math.floor((index-1)/3)*(statusHeight+10)
		local card=Instance.new("Frame")
		card.BackgroundColor3=C.Card;card.Position=UDim2.fromOffset(x,y);card.Size=UDim2.fromOffset(statusWidth,statusHeight);card.Parent=frames.ServerStatus;round(card)
		UI.Label(card,title,14,4,statusWidth-28,23,18,C.Muted)
		statusLabels[title]=UI.Label(card,"—",14,28,statusWidth-28,statusHeight-30,26,C.White)
	end
	local announcement = Instance.new("TextBox")
	announcement.Position=UDim2.fromOffset(20,62);announcement.Size=UDim2.fromOffset(860,134)
	announcement.BackgroundColor3=C.Card;announcement.TextColor3=C.White;announcement.PlaceholderColor3=C.Muted
	announcement.Font=Enum.Font.GothamMedium;announcement.TextScaled=false;announcement.TextSize=22;announcement.TextWrapped=true;announcement.ClearTextOnFocus=false
	announcement.TextXAlignment=Enum.TextXAlignment.Left;announcement.TextYAlignment=Enum.TextYAlignment.Top
	announcement.MultiLine=true;announcement.Text="";announcement.PlaceholderText="Message everyone in this server…";announcement.Parent=frames.Announcements;round(announcement)
	local padding=Instance.new("UIPadding")
	padding.PaddingLeft=UDim.new(0,16);padding.PaddingRight=UDim.new(0,16);padding.PaddingTop=UDim.new(0,12);padding.PaddingBottom=UDim.new(0,12);padding.Parent=announcement
	local countLabel=UI.Label(frames.Announcements,"0 / 150 characters",20,204,360,27,18,C.Muted)
	announcement:GetPropertyChangedSignal("Text"):Connect(function()
		local count=utf8.len(announcement.Text) or #announcement.Text
		countLabel.Text=count .. " / 150 characters"
		countLabel.TextColor3=count > 150 and C.Red or C.Muted
	end)
	UI.Button(frames.Announcements,"SEND ANNOUNCEMENT",450,224,430,52,function()
		local count=utf8.len(announcement.Text)
		if not count or count>150 or not announcement.Text:match("%S") then notify("ENTER A MESSAGE OF 1–150 CHARACTERS",false);return end
		send({Action="Announce",Message=announcement.Text})
	end)
	UI.Label(frames.Announcements,"Visible to everyone in this server",20,241,415,32,18,C.Muted)
	for index, destination in ipairs(Definitions.Destinations) do
		UI.Button(frames.Teleports,destination.DisplayName,20+((index-1)%3)*290,60+math.floor((index-1)/3)*45,280,38,function()
			send({Action="Teleport",Destination=destination.Id})
		end,C.Card)
	end
	local eventListWidth=math.floor(widths.EventQueue*0.36)
	local detailX=eventListWidth+40
	local detailWidth=widths.EventQueue-detailX-20
	local eventList=scroll(frames.EventQueue,20,58,eventListWidth,heights.EventQueue-72)
	local eventIds={}
	for id in pairs(Events) do table.insert(eventIds,id) end
	table.sort(eventIds,function(a,b) return Events[a].DisplayName<Events[b].DisplayName end)
	local eventButtons={}
	for index,id in ipairs(eventIds) do
		eventButtons[id]=UI.Button(eventList,Events[id].DisplayName,0,(index-1)*40,eventListWidth-14,34,function()
			self.eventId=id
			for key,button in pairs(eventButtons) do button.BackgroundColor3=key==id and C.Blue or C.Card end
		end,C.Card)
	end
	eventList.CanvasSize=UDim2.fromOffset(0,#eventIds*40)
	UI.Label(frames.EventQueue,"QUEUED EVENT",detailX,52,detailWidth,23,18,C.Muted)
	local queuedLabel=UI.Label(frames.EventQueue,"None",detailX,75,detailWidth,30,24)
	local queueButtonWidth=(detailWidth-12)/2
	UI.Button(frames.EventQueue,"QUEUE EVENT",detailX,109,queueButtonWidth,36,function()
		if not self.eventId then notify("SELECT AN EVENT FIRST",false);return end
		send({Action="QueueEvent",EventId=self.eventId})
	end)
	UI.Button(frames.EventQueue,"CLEAR QUEUE",detailX+queueButtonWidth+12,109,queueButtonWidth,36,function() send({Action="ClearQueue"}) end,C.Card)
	UI.Label(frames.EventQueue,"Current event continues • Pause holds queue",detailX,148,detailWidth,23,16,C.Muted)
	UI.Button(frames.EventQueue,"EMERGENCY WEATHER RESET",detailX,175,detailWidth,32,function() send({Action="EmergencyReset"}) end,C.Card)
	local logs=scroll(frames.ActivityLog,20,59,860,220)
	local logText=UI.Label(logs,"No admin activity yet",0,0,842,220,20,C.White)
	logText.TextWrapped=true
	logText.TextYAlignment=Enum.TextYAlignment.Top

	function self:Update(state)
		self.state=state
		for _,gui in ipairs(self.surfaces) do gui.Enabled=state.Authorized and state.InRoom end
		local keys={}
		local selectedExists=false
		for _,entry in ipairs(state.Players or {}) do
			table.insert(keys,entry.UserId..":"..entry.Username..":"..entry.DisplayName..":"..entry.Plot)
			if entry.UserId==self.selected then selectedExists=true end
		end
		if not selectedExists then self.selected=nil end
		local key=table.concat(keys,"|")
		if key~=self.rosterKey then
			self.rosterKey=key
			for _,button in pairs(rowButtons) do button:Destroy() end
			rowButtons={}
			for index,entry in ipairs(state.Players or {}) do
				local caption=entry.Username.."\nDisplay: "..entry.DisplayName.."\nID: "..entry.UserId.."\nPlot: "..(entry.Plot~="" and entry.Plot or "NO PLOT ASSIGNED")
				local button=UI.Button(playerList,caption,0,(index-1)*104,351,98,function() self.selected=entry.UserId;highlight() end,C.Card)
				button.TextSize=18
				button.TextXAlignment=Enum.TextXAlignment.Left
				rowButtons[entry.UserId]=button
			end
			playerList.CanvasSize=UDim2.fromOffset(0,#(state.Players or {})*104)
		end
		highlight()
		statusLabels.PLAYERS.Text=string.format("%d / %d",#(state.Players or {}),state.MaxPlayers or 0)
		local plots=state.Plots
		statusLabels["CLAIMED PLOTS"].Text=plots and plots.Available and string.format("%d / %d",plots.Claimed,plots.Total) or "Unavailable"
		local queueId=state.Weather and state.Weather.QueuedEventId
		queuedLabel.Text=queueId and Events[queueId] and Events[queueId].DisplayName or "None"
		local lines={}
		for _,entry in ipairs(state.Activity or {}) do
			-- Announcements already contain their authoritative username.
			local text=entry.Message:sub(1,8)=="[Admin] " and entry.Message or (entry.Username.." "..entry.Message)
			table.insert(lines,os.date("!%H:%M",entry.Time).."  "..text)
		end
		logText.Text=#lines>0 and table.concat(lines,"\n\n") or "No admin activity yet"
		-- AutomaticSize measures wrapped messages rather than clipping longer entries.
		logText.Size=UDim2.fromOffset(842,0)
		logText.AutomaticSize=Enum.AutomaticSize.Y
		logs.AutomaticCanvasSize=Enum.AutomaticSize.Y
	end
	function self:Tick(weatherState)
		if not self.state then return end
		local now=workspace:GetServerTimeNow()
		local seconds=math.max(0,math.floor(now-(self.state.ServerStartedAt or now)))
		statusLabels.UPTIME.Text=string.format("%02d:%02d:%02d",math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
		local isEvent=weatherState:GetAttribute("Phase")=="Event"
		statusLabels["CURRENT EVENT"].Text=isEvent and (weatherState:GetAttribute("EventName") or "Event") or "Break"
		local deadline=weatherState:GetAttribute(isEvent and "EndsAt" or "BreakEndsAt") or 0
		local left=math.max(0,math.ceil(deadline-now))
		statusLabels["TIME LEFT"].Text=string.format("%02d:%02d",math.floor(left/60),left%60)
		statusLabels["AUTOMATIC WEATHER"].Text=weatherState:GetAttribute("AutomaticPaused") and "Paused" or "Running"
	end
	function self:Destroy() for _,gui in ipairs(self.surfaces) do gui:Destroy() end end
	return self
end

return UI
