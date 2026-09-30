local W=require(script.Parent.Components)
local RightHudButton=require(script.Parent.RightHudButton)
local T=W.Theme
local H={};H.__index=H
function H.new(screen,open)
 local self=setmetatable({},H)
 self.Root=W.New('Frame',{Name='HUD',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=T.Layers.HUD},screen)
 self.Brand=W.Surface(self.Root,'Brand',UDim2.fromOffset(224,96),UDim2.fromOffset(14,8),'Wood');W.Decorate(self.Brand)
 self.Logo=W.Heading(self.Brand,'Animal\nKingdom',UDim2.new(1,-16,1,-18),UDim2.fromOffset(8,5),33,T.Color.White);self.Logo.TextXAlignment=Enum.TextXAlignment.Center;self.Logo.TextStrokeColor3=T.Color.WoodDark;self.Logo.TextStrokeTransparency=.1
 self.Context=W.Surface(self.Root,'WorldContext',UDim2.fromOffset(224,32),UDim2.fromOffset(14,104),'Paper')
 self.ContextText=W.Text(self.Context,'Town • Clear skies',UDim2.new(1,-16,1,0),UDim2.fromOffset(8,0),12);self.ContextText.TextXAlignment=Enum.TextXAlignment.Center
 local contextButton=W.New('TextButton',{Name='WeatherDetails',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=''},self.Context);W.Bind(contextButton,function()open('WeatherDetails')end)
 self.Currencies=W.New('Frame',{Name='Currencies',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,12),Size=UDim2.fromOffset(510,56),BackgroundTransparency=1},self.Root)
 self.Counters={}
 for i,id in ipairs({'Coins','FriendshipTokens'}) do
  local pill,value=W.CurrencyPill(self.Currencies,id,UDim2.new(.5,-6,1,0),UDim2.new((i-1)*.5,3,0,0));self.Counters[id]=value
 end
 self.Navigation=W.Scroll(self.Root,'Navigation',UDim2.fromOffset(936,92),UDim2.new(.5,0,1,-10));self.Navigation.AnchorPoint=Vector2.new(.5,1);self.Navigation.ScrollingDirection=Enum.ScrollingDirection.X;self.Navigation.AutomaticCanvasSize=Enum.AutomaticSize.X;self.Navigation.ScrollBarThickness=0;self.Navigation.ClipsDescendants=false
 self.NavLayout=W.New('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},self.Navigation)
 self.Buttons={}
 for i,name in ipairs({'Pets','Index','Garden','Biomes','Challenges','Upgrades','Settings'}) do
  local b=W.WoodButton(self.Navigation,name,name,UDim2.fromOffset(108,80),nil,function()open(name)end);b.LayoutOrder=i;self.Buttons[name]=b
  if name=='Challenges' then local label=b:FindFirstChild('Label');if label then label.Text='Activities'end end
 end
 self.Utilities=W.New('Frame',{Name='Utilities',Position=UDim2.new(0,16,.34,0),Size=UDim2.fromOffset(76,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},self.Root)
 self.UtilityLayout=W.New('UIListLayout',{Padding=UDim.new(0,T.SideAction.Gap),SortOrder=Enum.SortOrder.LayoutOrder},self.Utilities)
 self.Shop=W.SideActionButton(self.Utilities,'Shop','Shop',UDim2.fromOffset(76,78),nil,function()open('Shop')end);self.Shop.LayoutOrder=1
 self.SetChallengeBadge=W.NotificationBadge(self.Buttons.Challenges)
 self.HeaderActions=W.New('Frame',{Name='HeaderActions',Position=UDim2.new(1,-216,0,218),Size=UDim2.fromOffset(202,64),BackgroundTransparency=1},self.Root)
 W.New('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,T.SideAction.Gap),SortOrder=Enum.SortOrder.LayoutOrder},self.HeaderActions)
 for i,item in ipairs({{'Friends','FriendshipTokens'},{'Updates','Leaf'},{'Profile','Crown'}})do
  local b=RightHudButton.new(self.HeaderActions,item[1],item[2],function()open(item[1])end);b.LayoutOrder=i
 end
 self.Hint=W.Surface(self.Root,'Kindness',UDim2.fromOffset(190,52),UDim2.new(1,-208,1,-74),'Paper')
 local text=W.Text(self.Hint,'Small steps.\nA brighter kingdom.',UDim2.new(1,-16,1,-8),UDim2.fromOffset(8,4),14);text.TextXAlignment=Enum.TextXAlignment.Center
 return self
end
function H:LayoutNavigation(portrait)
 if self.NavPortrait==portrait then return end
 self.NavPortrait=portrait;self.NavLayout:Destroy()
 if portrait then
  self.NavLayout=W.New('UIGridLayout',{CellSize=UDim2.new(.25,-7,0,48),CellPadding=UDim2.fromOffset(5,7),FillDirectionMaxCells=4,SortOrder=Enum.SortOrder.LayoutOrder},self.Navigation)
  self.Navigation.AutomaticCanvasSize=Enum.AutomaticSize.None;self.Navigation.CanvasSize=UDim2.new();self.Navigation.ScrollingEnabled=false
 else
  self.NavLayout=W.New('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},self.Navigation)
  self.Navigation.AutomaticCanvasSize=Enum.AutomaticSize.X;self.Navigation.ScrollingEnabled=true
 end
 self.Navigation.CanvasPosition=Vector2.zero
end
function H:Resize(size,touch)
 self.LastSize=size;self.Touch=touch
 local compact=size.Y<580 or size.X<900
 self.Compact=compact
 local portrait=compact and size.X<500;self:LayoutNavigation(portrait)
 self.Brand.Size=UDim2.fromOffset(compact and 142 or 224,compact and 52 or 96)
 self.Brand.Position=UDim2.fromOffset(12,compact and 2 or 8);self.Logo.TextSize=compact and 19 or 33
 self.Logo.Size=UDim2.new(1,-12,1,compact and -6 or -18);self.Logo.Position=UDim2.fromOffset(6,compact and 3 or 5)
 self.Context.Position=UDim2.fromOffset(12,compact and 53 or 104);self.Context.Size=UDim2.fromOffset(compact and 142 or 224,compact and 24 or 32);self.ContextText.TextSize=compact and 10 or 12
 self.Currencies.Size=UDim2.fromOffset(compact and math.min(350,size.X-250) or math.min(510,size.X*.42),compact and 48 or 56)
 self.Currencies.Position=UDim2.new(compact and .6 or .5,0,0,compact and 3 or 12)
 self.Currencies.AnchorPoint=Vector2.new(.5,0)
 for _,pill in ipairs(self.Currencies:GetChildren())do
  local icon=pill:FindFirstChild('Icon_'..pill.Name);if icon then icon.Size=UDim2.fromOffset(compact and 36 or 50,compact and 36 or 50);icon.Position=UDim2.fromOffset(4,compact and 6 or 3)end
  for _,label in ipairs(pill:GetChildren())do if label:IsA('TextLabel')then
   label.Position=UDim2.fromOffset(compact and 43 or 60,label.Name=='Value'and 20 or 6);label.Size=UDim2.new(1,compact and -49 or -66,0,label.Name=='Value'and 28 or 16);label.TextSize=label.Name=='Value'and(compact and 18 or 23)or 11
  end end
 end
 for _,v in pairs(self.Counters) do v.TextSize=compact and 18 or 23 end
 if compact then
  self.Navigation.AnchorPoint=Vector2.new(.5,0);self.Navigation.Position=UDim2.new(.5,-28,0,82);self.Navigation.Size=UDim2.new(1,-104,0,57);self.Navigation.ClipsDescendants=true
  if not portrait then self.NavLayout.Padding=UDim.new(0,5)end
  for _,b in pairs(self.Buttons) do b.Size=UDim2.fromOffset(72,48);local l=b:FindFirstChild('Label');if l then l.TextSize=11 end end
  self.Utilities.Position=UDim2.new(1,-68,0,3);self.Utilities.Size=UDim2.fromOffset(56,0);self.Shop.Size=UDim2.fromOffset(56,49)
  if size.X<500 then
   self.Currencies.AnchorPoint=Vector2.zero;self.Currencies.Position=UDim2.fromOffset(12,82);self.Currencies.Size=UDim2.fromOffset(size.X-92,54)
   local navTop=144
   self.Navigation.Position=UDim2.new(.5,0,0,navTop);self.Navigation.Size=UDim2.new(1,-24,0,112)
   for _,pill in ipairs(self.Currencies:GetChildren())do
    local icon=pill:FindFirstChild('Icon_'..pill.Name);if icon then icon.Size=UDim2.fromOffset(30,30);icon.Position=UDim2.fromOffset(4,12)end
    for _,label in ipairs(pill:GetChildren())do if label:IsA('TextLabel')then label.Position=UDim2.fromOffset(37,label.Name=='Value'and 24 or 8);label.Size=UDim2.new(1,-42,0,label.Name=='Value'and 22 or 17);label.TextSize=label.Name=='Value'and 16 or 8 end end
   end
  else self.Currencies.AnchorPoint=Vector2.new(.5,0)end
 else
  local width=math.min(936,size.X-(touch and 340 or 340))
  self.Navigation.AnchorPoint=Vector2.new(.5,1);self.Navigation.Position=UDim2.new(.5,0,1,-10);self.Navigation.Size=UDim2.fromOffset(width,92);self.Navigation.ClipsDescendants=false
  self.NavLayout.Padding=UDim.new(0,7)
  for _,b in pairs(self.Buttons) do b.Size=UDim2.fromOffset(math.floor((width-61)/7),80);local l=b:FindFirstChild('Label');if l then l.TextSize=15 end end
  self.Utilities.Position=UDim2.new(0,16,.3,0);self.Utilities.Size=UDim2.fromOffset(76,0);self.Shop.Size=UDim2.fromOffset(76,78)
 end
 -- On landscape phones, leave the existing utility stack and jump control clear.
 local actionsTop=compact and (portrait and self.Navigation.Position.Y.Offset+self.Navigation.Size.Y.Offset+12 or 144) or 218
 self.HeaderActions.Position=UDim2.new(1,compact and not portrait and -286 or -216,0,actionsTop)
 self.HeaderActions.Visible=self.ActiveName==nil
 local inMenu=compact and self.ActiveName~=nil
 self.Brand.Visible=not inMenu;self.Context.Visible=not inMenu;self.Currencies.Visible=not inMenu;self.Utilities.Visible=not inMenu
 if inMenu then
  self.Navigation.Position=UDim2.new(.5,0,0,0);self.Navigation.Size=UDim2.new(1,-24,0,portrait and 112 or 56)
 end
 self.Hint.Visible=not compact and size.X>1500
end
function H:Select(name) self.ActiveName=name;if self.LastSize then self:Resize(self.LastSize,self.Touch)end;for id,b in pairs(self.Buttons) do W.Selected(b,id==name) end;W.Selected(self.Shop,name=='Shop') end
function H:Update(data)
 for id,label in pairs(self.Counters) do W.Motion.CounterChange(label,(data.Currencies or {})[id] or 0,W.Format) end
 local counts={Daily=0,Weekly=0};local defs=require(game.ReplicatedStorage.Shared.Gameplay.Definitions.ChallengeDefinitions)
 for kind,list in pairs(defs)do local state=kind=='Daily'and data.Activities and data.Activities.LegacyDaily or data[kind..'Challenges'];for _,def in ipairs(list)do local entry=state and state.Entries and state.Entries[def.Id];if entry and not entry.Claimed and entry.Progress>=def.Target then counts[kind]+=1 end end end
 local contracts=0;for _,e in ipairs(data.Contracts and data.Contracts.Entries or {})do if type(e)=="table" and e.Progress>=e.Target then contracts+=1 end end
 local a=data.Activities or {};local activities=0;local P=require(game.ReplicatedStorage.Shared.Gameplay.KingdomProgress)
 for _,e in pairs(a.Pending or {})do activities+=1 end
 if a.Route and a.Route.Completed then activities+=1 end
 if a.Mission and a.Mission.Progress>=a.Mission.Target then activities+=1 end
 if a.Journey and not a.Journey.Claimed and P.Complete(a.Journey.Entries)then activities+=1 end
 for _,set in pairs(a.BiomeGoals or {})do if not set.Claimed and P.Complete(set.Entries)then activities+=1 end end
 for _,def in ipairs(defs.Weekly)do local e=a.LegacyWeekly and a.LegacyWeekly.Entries[def.Id];if e and not e.Claimed and e.Progress>=def.Target then activities+=1 end end
 self.SetChallengeBadge(counts.Daily+counts.Weekly+contracts+activities)
end
return H
