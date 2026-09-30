
local function signal() local callbacks={} return {Connect=function(_,f) table.insert(callbacks,f) end,Fire=function(_,...) for _,f in ipairs(callbacks)do f(...)end end} end
local function connect(s,f)s:Connect(f)end
local objects={}
local function n(class,props,parent) local o={ClassName=class,Name=class,Parent=parent};for k,v in pairs(props or {})do o[k]=v end;table.insert(objects,o);return o end
local C={padding=function()end,corner=function()end,stroke=function()end}
C.card=function(parent,name,size,color)return n('Frame',{Name=name,Size=size,BackgroundColor3=color},parent)end
C.scroller=function(parent,name,pos,size)return n('ScrollingFrame',{Name=name,Position=pos,Size=size},parent)end
C.text=function(parent,props)return n('TextLabel',props,parent)end
C.button=function(parent,name,text,color,size)return n('TextButton',{Name=name,Text=text,BackgroundColor3=color,Size=size,Activated=signal()},parent)end
local T={Teal=1,White=2,Muted=3,Green=4,Red=5,Blue=6,Yellow=7,Ink=8}
local UDim2={new=function(...)return {...}end,fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end}
local Vector2={new=function(...)return {...}end}
local UDim={new=function(...)return {...}end}
local Color3={fromRGB=function(...)return {...}end}
local Enum={TextXAlignment={Left=1},FillDirection={Horizontal=1},VerticalAlignment={Center=1},Font={GothamBold=1}}
local screen={Parent=true};local hud={Visible=true};local showUI={Visible=false};local activeWindow
local function registerWindow(name)return {Name=name}end
local requests={};local Bridge={Request=function(action,payload)table.insert(requests,{action,payload})end}
local endpoint
local remotes={FindFirstChild=function(_,name)return name=='UIRequest' and endpoint or nil end}
local storage={DescendantAdded=signal(),DescendantRemoving=signal(),FindFirstChild=function(_,name)return name=='AnimalKingdomRemotes' and remotes or nil end}
local game={GetService=function(_,name)assert(name=='ReplicatedStorage');return storage end}
local task={defer=function(f)f()end}
do
	local content=registerWindow("Settings","SETTINGS",T.Teal)
	local scroll=C.scroller(content,"SettingsScroll",UDim2.fromOffset(0,0),UDim2.fromScale(1,1));n("UIListLayout",{Padding=UDim.new(0,10)},scroll);C.padding(scroll,4,10,4,10)
	local storage=game:GetService("ReplicatedStorage")
	local function endpointAvailable()
		local remotes=storage:FindFirstChild("AnimalKingdomRemotes")
		local endpoint=remotes and remotes:FindFirstChild("UIRequest")
		return endpoint~=nil and endpoint:IsA("RemoteEvent")
	end
	local pending=C.text(scroll,{Name="ComingSoon",Size=UDim2.new(1,-8,0,34),Text="Settings and codes — coming soon",TextColor3=T.Muted,TextSize=14,LayoutOrder=-1})
	local pendingControls={}
	local function registerPending(button,refresh)
		table.insert(pendingControls,function(available)
			button.Interactable=available;button.Active=available;button.Selectable=available
			refresh(available)
		end)
	end
	local states={Music=true,["Sound Effects"]=true,["Pet Effects"]=true,["Other Players' Pets"]=true,["Screen Shake"]=true,Notifications=true}
	for label,value in pairs(states) do
		local row=C.card(scroll,label,UDim2.new(1,-8,0,58),T.White);C.text(row,{Position=UDim2.fromOffset(16,0),Size=UDim2.new(1,-130,1,0),Text=label,TextXAlignment=Enum.TextXAlignment.Left,TextSize=16})
		local toggle=C.button(row,"Toggle",value and "ON" or "OFF",value and T.Green or T.Red,UDim2.fromOffset(86,38));toggle.AnchorPoint=Vector2.new(1,.5);toggle.Position=UDim2.new(1,-10,.5,0)
		registerPending(toggle,function(available)
			toggle.Text=available and (states[label] and "ON" or "OFF") or "SOON"
			toggle.BackgroundColor3=available and (states[label] and T.Green or T.Red) or T.Muted
		end)
		connect(toggle.Activated,function()
			if not endpointAvailable() then return end
			states[label]=not states[label];toggle.Text=states[label] and "ON" or "OFF";toggle.BackgroundColor3=states[label] and T.Green or T.Red
			Bridge.Request("UpdateSetting",{Setting=label,Value=states[label]})
		end)
	end
	local graphics=C.card(scroll,"Graphics",UDim2.new(1,-8,0,74),Color3.fromRGB(230,249,247));C.text(graphics,{Position=UDim2.fromOffset(16,0),Size=UDim2.new(.35,0,1,0),Text="GRAPHICS",TextXAlignment=Enum.TextXAlignment.Left,TextSize=16})
	local levels=n("Frame",{Position=UDim2.new(.35,0,0,0),Size=UDim2.new(.65,-12,1,0),BackgroundTransparency=1},graphics);n("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,8)},levels)
	for _,level in ipairs({"LOW","MEDIUM","HIGH"}) do
		local b=C.button(levels,level,level,level=="MEDIUM" and T.Teal or T.Blue,UDim2.new(.31,0,0,38));b.TextSize=12
		registerPending(b,function(available) b.BackgroundColor3=available and (level=="MEDIUM" and T.Teal or T.Blue) or T.Muted end)
		connect(b.Activated,function() if endpointAvailable() then Bridge.Request("UpdateSetting",{Setting="Graphics",Value=level}) end end)
	end
	local hide=C.button(scroll,"HideUI","HIDE UI",T.Muted,UDim2.new(1,-8,0,48));connect(hide.Activated,function() hud.Visible=false;showUI.Visible=true;if activeWindow then activeWindow.Close(true) end end)
	local redeem=C.card(scroll,"RedeemCode",UDim2.new(1,-8,0,88),Color3.fromRGB(255,246,220));C.padding(redeem,10)
	local code=n("TextBox",{Name="Code",Size=UDim2.new(.68,-6,0,50),BackgroundColor3=T.White,PlaceholderText="Enter redeem code",Text="",TextColor3=T.Ink,TextSize=16,Font=Enum.Font.GothamBold,ClearTextOnFocus=false},redeem);C.corner(code,12);C.stroke(code,3);C.padding(code,12)
	local redeemButton=C.button(redeem,"Redeem","REDEEM",T.Yellow,UDim2.new(.32,-6,0,50));redeemButton.Position=UDim2.new(.68,6,0,0)
	registerPending(redeemButton,function(available)
		redeemButton.Text=available and "REDEEM" or "SOON";redeemButton.BackgroundColor3=available and T.Yellow or T.Muted
		code.TextEditable=available;code.PlaceholderText=available and "Enter redeem code" or "Codes coming soon"
	end)
	connect(redeemButton.Activated,function()
		if not endpointAvailable() then return end
		Bridge.Request("RedeemCode",{Code=code.Text});code.Text=""
	end)
	local function refreshAvailability()
		if not screen.Parent then return end
		local available=endpointAvailable();pending.Visible=not available
		for _,refresh in ipairs(pendingControls) do refresh(available) end
	end
	local function endpointChanged(object)
		if object.Name=="UIRequest" or object.Name=="AnimalKingdomRemotes" then task.defer(refreshAvailability) end
	end
	connect(storage.DescendantAdded,endpointChanged);connect(storage.DescendantRemoving,endpointChanged)
	refreshAvailability()
end


local function find(name,parent)local matches={} for _,o in ipairs(objects)do if o.Name==name and (not parent or o.Parent.Name==parent)then table.insert(matches,o)end end;assert(#matches==1,name);return matches[1]end
local toggle=find('Toggle','Music');local redeem=find('Redeem');local code=find('Code');local notice=find('ComingSoon');local low=find('LOW')
assert(not toggle.Interactable and not low.Interactable and not redeem.Interactable and not code.TextEditable and notice.Visible)
code.Text='KEEP';toggle.Activated:Fire();low.Activated:Fire();redeem.Activated:Fire()
assert(#requests==0 and code.Text=='KEEP' and toggle.Text=='SOON','Missing endpoint accepted a no-op action')
find('HideUI').Activated:Fire();assert(not hud.Visible and showUI.Visible,'Working hide/show flow disabled')
endpoint={Name='UIRequest',IsA=function(_,class)return class=='RemoteEvent'end};storage.DescendantAdded:Fire(endpoint)
assert(toggle.Interactable and low.Interactable and redeem.Interactable and code.TextEditable and not notice.Visible)
toggle.Activated:Fire();assert(toggle.Text=='OFF' and requests[#requests][1]=='UpdateSetting' and requests[#requests][2].Value==false)
low.Activated:Fire();assert(requests[#requests][2].Setting=='Graphics' and requests[#requests][2].Value=='LOW')
redeem.Activated:Fire();assert(requests[#requests][1]=='RedeemCode' and requests[#requests][2].Code=='KEEP' and code.Text=='')
local removed=endpoint;endpoint=nil;storage.DescendantRemoving:Fire(removed)
local count=#requests;code.Text='PRESERVE';toggle.Activated:Fire();redeem.Activated:Fire();assert(#requests==count and code.Text=='PRESERVE' and not toggle.Interactable and notice.Visible)
endpoint={Name='UIRequest',IsA=function()return false end};storage.DescendantAdded:Fire(endpoint);assert(not redeem.Interactable,'Wrong-class endpoint enabled controls')
print('PASS Settings UX: absent/wrong-type endpoint disables settings, graphics and codes; blocked clicks preserve text/state; Hide UI works; real RemoteEvent enables requests; removal disables again')
