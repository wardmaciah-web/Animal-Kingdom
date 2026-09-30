local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UI = require(script.Parent:WaitForChild("AdminCommandUI"))
local Spectate = require(script.Parent:WaitForChild("AdminSpectate"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("AnimalKingdomRemotes")
local request = remotes:WaitForChild("AdminCommandRequest")
local response = remotes:WaitForChild("AdminCommandResponse")
local stateRemote = remotes:WaitForChild("AdminCommandState")
local cameraRemote = remotes:WaitForChild("AdminCameraControl")
local weatherState = ReplicatedStorage:WaitForChild("WeatherState")

local screen = Instance.new("ScreenGui")
screen.Name="AK_AdminCommands"
screen.ResetOnSpawn=false
screen.DisplayOrder=90
screen.Enabled=false
screen.Parent=playerGui
local C=UI.Colors
local status=UI.Label(screen,"",0,0,620,42,18,C.White)
status.TextWrapped=true
status.AnchorPoint=Vector2.new(0.5,1)
status.Position=UDim2.new(0.5,0,1,-80)
status.BackgroundColor3=C.Navy
status.BackgroundTransparency=0.06
status.TextXAlignment=Enum.TextXAlignment.Center
status.Visible=false
local noticeVersion=0
local function notify(message,success)
	noticeVersion+=1
	local version=noticeVersion
	status.Text=message
	status.TextColor3=success and C.White or C.Red
	status.Visible=true
	task.delay(5,function() if noticeVersion==version then status.Visible=false end end)
end
local lastSent=-math.huge
local function send(payload)
	if os.clock()-lastSent < 0.4 then return false end
	lastSent=os.clock()
	request:FireServer(payload)
	return true
end
local gameUI=playerGui:WaitForChild('AnimalKingdomUI')
local W=require(gameUI.AnimalKingdomUIV2.Components)
local adminTravel=false
local returnButton=W.Button(screen,"Admin Room",UDim2.fromOffset(128,44),nil,function()
 local travel=gameUI:FindFirstChild('PresentationTravel')
 if travel then
  adminTravel=true
  travel:Fire('AdminRoom','Admin Room',function()return send({Action='Teleport',Destination='AdminRoom'})end)
 else send({Action='Teleport',Destination='AdminRoom'})end
end,W.Color.Wood)
returnButton.AnchorPoint=Vector2.new(1,1)
returnButton.Position=UDim2.new(1,-14,0,72)
returnButton.AnchorPoint=Vector2.new(1,0)
returnButton.Size=UDim2.fromOffset(128,44)
returnButton.Text="Admin Room"
returnButton.TextSize=12
returnButton.Visible=false
local stopButton
local spectate=Spectate.new(function(notifyServer)
	if stopButton then stopButton.Visible=false end
	if notifyServer then
		-- Cleanup must not be dropped by a recent UI click's local debounce.
		task.delay(0.4,function() request:FireServer({Action="StopSpectating"}) end)
	end
end)
stopButton=UI.Button(screen,"STOP SPECTATING",0,0,260,44,function() spectate:Stop(true,true) end)
stopButton.AnchorPoint=Vector2.new(0.5,1)
stopButton.Position=UDim2.new(0.5,0,1,-22)
stopButton.Visible=false

local shade=Instance.new("Frame")
shade.Name="Confirmation"
shade.Size=UDim2.fromScale(1,1)
shade.BackgroundColor3=Color3.new(0,0,0)
shade.BackgroundTransparency=0.35
shade.Visible=false
shade.Active=true
shade.ZIndex=10
shade.Parent=screen
local dialog=Instance.new("Frame")
dialog.AnchorPoint=Vector2.new(0.5,0.5)
dialog.Position=UDim2.fromScale(0.5,0.5)
dialog.Size=UDim2.fromOffset(540,250)
dialog.BackgroundColor3=C.Navy
dialog.ZIndex=11
dialog.Parent=shade
local dialogCorner=Instance.new("UICorner");dialogCorner.CornerRadius=UDim.new(0,14);dialogCorner.Parent=dialog
local dialogStroke=Instance.new("UIStroke");dialogStroke.Color=C.Cyan;dialogStroke.Thickness=2;dialogStroke.Parent=dialog
local prompt=UI.Label(dialog,"",24,20,492,150,23)
prompt.TextWrapped=true
prompt.TextXAlignment=Enum.TextXAlignment.Center
prompt.ZIndex=12
local token
local confirm=UI.Button(dialog,"CONFIRM",24,185,234,43,function()
	local current=token
	if current and send({Action="Confirm",Token=current}) then
		token=nil;shade.Visible=false
	end
end)
confirm.ZIndex=12
local cancel=UI.Button(dialog,"CANCEL",282,185,234,43,function() token=nil;shade.Visible=false end,C.Card)
cancel.ZIndex=12
-- Keep the confirmation legible on smaller displays.
local dialogScale=Instance.new("UIScale");dialogScale.Parent=dialog
local mounted, panelFolder, latest
local function resize()
	local camera=workspace.CurrentCamera
	if camera then
		dialogScale.Scale=math.min(1,(camera.ViewportSize.X-32)/540,(camera.ViewportSize.Y-32)/250)
		status.Size=UDim2.fromOffset(math.min(620,camera.ViewportSize.X-32),42)
        local compact=camera.ViewportSize.Y<580 or camera.ViewportSize.X<900
        returnButton.Visible=latest~=nil and latest.Authorized==true and not latest.InRoom and not compact and gameUI:GetAttribute('ActiveMenu')=='' and not gameUI:GetAttribute('RewardRevealActive')
        returnButton.Position=UDim2.new(1,-14,0,292)
	end
end

gameUI:GetAttributeChangedSignal('ActiveMenu'):Connect(resize)
gameUI:GetAttributeChangedSignal('RewardRevealActive'):Connect(resize)
gameUI:GetAttributeChangedSignal('CompactLayout'):Connect(resize)

local function updatePanels()
	local room=workspace:FindFirstChild("WeatherAdminRoom")
	local folder=room and room:FindFirstChild("AdminCommandCenter")
	if folder~=panelFolder then
		if mounted then mounted:Destroy();mounted=nil end
		panelFolder=folder
	end
	if latest and latest.Authorized and folder and not mounted then mounted=UI.Mount(playerGui,folder,send,notify) end
	if mounted and latest then mounted:Update(latest);mounted:Tick(weatherState) end
end
stateRemote.OnClientEvent:Connect(function(state)
	if type(state)~="table" then return end
	latest=state
	screen.Enabled=state.Authorized==true
	resize()
	if not state.Authorized or not state.InRoom then
		token=nil;shade.Visible=false
		spectate:Stop(true,false)
	end
	updatePanels()
end)
response.OnClientEvent:Connect(function(payload)
	if type(payload)~="table" then return end
	if payload.Kind=="Result" then
        if adminTravel then adminTravel=false;local finish=gameUI:FindFirstChild('PresentationTravelFinished');if finish then finish:Fire('AdminRoom',payload.Success)end end
        notify(payload.Message,payload.Success)
	elseif payload.Kind=="Confirm" then
		token=payload.Token;prompt.Text=payload.Title;shade.Visible=true
		local current=token
		task.delay(payload.Lifetime or 15,function()
			if token==current then token=nil;shade.Visible=false;notify("CONFIRMATION EXPIRED",false) end
		end)
	elseif payload.Kind=="SpectateStart" then
		spectate:Start(payload.TargetUserId,payload.Position)
		stopButton.Visible=true
	elseif payload.Kind=="SpectateStop" then
		spectate:Stop(true,false)
	end
end)
cameraRemote.OnClientEvent:Connect(function(command)
	if command=="Open" then spectate:Stop(false,true) end
end)
player.CharacterAdded:Connect(function() token=nil;shade.Visible=false end)
local elapsed=0
RunService.Heartbeat:Connect(function(delta)
	elapsed+=delta
	if elapsed<0.25 then return end
	elapsed=0
	resize()
	if mounted then mounted:Tick(weatherState) end
end)
request:FireServer({Action="GetState"})
