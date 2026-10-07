local T=require(script.Parent.Theme)
local Motion=require(script.Parent.Motion)
local Sounds=require(game:GetService('ReplicatedStorage').Shared.Gameplay.PresentationSounds)
local W={Color=T.Color,Theme=T,Motion=Motion,Activators=setmetatable({},{__mode='k'})}
function W.New(class,props,parent)
 local o=Instance.new(class);for k,v in pairs(props or {}) do o[k]=v end;o.Parent=parent;return o
end
function W.Round(p,r) return W.New('UICorner',{CornerRadius=UDim.new(0,r or T.Radius.Button)},p) end
function W.Stroke(p,color,width) return W.New('UIStroke',{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=color or T.Color.Line,Thickness=width or 1.5},p) end
function W.Gradient(p,top,bottom) return W.New('UIGradient',{Color=ColorSequence.new(top,bottom),Rotation=90},p) end
function W.Text(p,text,size,pos,fontSize,color)
 return W.New('TextLabel',{Name='Label',BackgroundTransparency=1,Text=tostring(text or ''),Size=size or UDim2.new(1,0,0,32),Position=pos or UDim2.new(),TextColor3=color or T.Color.Ink,TextSize=fontSize or 16,Font=T.Body,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0},p)
end
function W.Heading(p,text,size,pos,fontSize,color)
 local l=W.Text(p,text,size,pos,fontSize or 24,color);l.Font=T.Font;return l
end
function W.Image(p,image,size,pos)
 return W.New('ImageLabel',{Name='Artwork',BackgroundTransparency=1,Image=image,Size=size or UDim2.fromScale(1,1),Position=pos or UDim2.new(),ScaleType=Enum.ScaleType.Fit},p)
end
function W.Icon(p,id,size,pos)
 local i=T.Icons[id] or T.Icons.Leaf
 local o=W.Image(p,T.Assets.Icons,size,pos);o.Name='Icon_'..id
 -- Roblox image uploads normalize the atlas to 1024 square.
 o.ImageRectOffset=Vector2.new((i%4)*256+7,math.floor(i/4)*256+7);o.ImageRectSize=Vector2.new(242,242)
 return o
end
function W.Skin(p,kind)
 local image=W.Image(p,kind=='Wood' and T.Assets.Wood or T.Assets.Paper)
 image.Name='Surface';image.ZIndex=0;image.ScaleType=Enum.ScaleType.Slice
 image.SliceCenter=Rect.new(150,150,874,874);image.SliceScale=kind=='Wood' and .2 or .14
 image.ImageTransparency=kind=='Wood' and .9 or .92
 p.BackgroundTransparency=0;p.BackgroundColor3=kind=='Wood' and T.Color.WoodDark or T.Color.Panel
 W.Round(p,T.Radius.Panel);W.Stroke(p,kind=='Wood' and T.Color.Gold or T.Color.Line,1)
 W.Gradient(p,kind=='Wood' and T.Color.Wood or T.Color.Card,kind=='Wood' and T.Color.WoodDark or T.Color.Panel)
 return image
end
function W.Surface(p,name,size,pos,kind)
 local frame=W.New('Frame',{Name=name,Size=size,Position=pos or UDim2.new(),BackgroundTransparency=1,BorderSizePixel=0},p)
 W.Skin(frame,kind or 'Paper');return frame
end
function W.Decorate(p)
 local a=W.Icon(p,'Leaf',UDim2.fromOffset(58,58),UDim2.fromOffset(-14,-14));a.Rotation=-25
 local b=W.Icon(p,'Leaf',UDim2.fromOffset(58,58),UDim2.new(1,-42,1,-43));b.Rotation=135
 W.Icon(p,'Flower',UDim2.fromOffset(27,27),UDim2.fromOffset(12,-5))
 W.Icon(p,'Flower',UDim2.fromOffset(25,25),UDim2.new(1,-17,1,-20))
end
function W.Bind(b,callback,presentation)
 W.Activators[b]=callback;b.Selectable=true;b.AutoButtonColor=false
 -- Studio-only bridge exercises existing callbacks during MCP visual QA.
 if game:GetService('RunService'):IsStudio()then
  local qa=Instance.new('BindableFunction');qa.Name='AKStudioActivate'
  qa.OnInvoke=function()if not b.Active or b:GetAttribute('Pending')or b:GetAttribute('Disabled')then return false end;if callback then callback()end;return true end
  qa.Parent=b
 end
 local focus=presentation and presentation.Focus
 if not focus and not (presentation and presentation.FocusManaged) then
  Motion.Scale(b)
  focus=W.New('Frame',{Name='Focus',Size=UDim2.new(1,6,1,6),Position=UDim2.fromOffset(-3,-3),BackgroundTransparency=1,Visible=false,ZIndex=8},b)
  W.Round(focus,12);W.Stroke(focus,T.Color.Gold,3)
 end
 b.SelectionImageObject=W.New('ImageLabel',{BackgroundTransparency=1,Image='',Size=UDim2.fromScale(1,1)},nil)
 b.SelectionGained:Connect(function()if focus then focus.Visible=true end;if presentation then presentation.FocusChanged(true)end end)
 b.SelectionLost:Connect(function()if focus then focus.Visible=false end;if presentation then presentation.FocusChanged(false);presentation.Press(false)end end)
 b.MouseEnter:Connect(function()if b.Active then if presentation then presentation.Hover(true)else Motion.ButtonHover(b,true)end;Sounds.Play('UIHover',b) end end)
 b.MouseLeave:Connect(function()if presentation then presentation.Hover(false);presentation.Press(false)else Motion.ButtonHover(b,false)end end)
 if presentation then
  local function isPress(input)return input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonA end
  b.InputBegan:Connect(function(input)if isPress(input)and b.Active and not b:GetAttribute('Disabled')and not b:GetAttribute('Pending')then presentation.Press(true)end end)
  b.InputEnded:Connect(function(input)if isPress(input)then presentation.Press(false)end end)
 end
 b.Activated:Connect(function()
  if not b.Active or b:GetAttribute('Pending') or b:GetAttribute('Disabled') then return end
  if presentation then presentation.Activate()else Motion.ButtonPress(b)end;Sounds.Play('UIClick',b)
  W.CurrentButton=b
  local ok,err=pcall(function()if callback then callback()end end)
  W.CurrentButton=nil
  if not ok then warn('[UIAction] '..tostring(err))end
 end)
 b.Destroying:Once(function()W.Activators[b]=nil;if W.CurrentButton==b then W.CurrentButton=nil end;if b.SelectionImageObject then b.SelectionImageObject:Destroy() end end)
 return b
end
function W.Button(p,text,size,pos,callback,color)
 local c=color or T.Color.Green
 local b=W.New('TextButton',{Name=text:gsub('[^%w]',''):sub(1,48),Size=size or UDim2.fromOffset(120,44),Position=pos or UDim2.new(),Text=text,BackgroundColor3=c,TextColor3=T.Color.White,TextSize=15,Font=T.Font,TextWrapped=true,TextStrokeColor3=T.Color.WoodDark,TextStrokeTransparency=.65,BorderSizePixel=0},p)
 W.Round(b,12);W.Stroke(b,c:Lerp(T.Color.WoodDark,.45),2);W.Gradient(b,Color3.new(1,1,1),Color3.fromRGB(185,200,171));return W.Bind(b,callback)
end
function W.WoodButton(p,name,icon,size,pos,callback)
 local b=W.New('ImageButton',{Name='Nav_'..name,Size=size,Position=pos or UDim2.new(),BackgroundTransparency=1,Image=T.Assets.Wood,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(150,150,874,874),SliceScale=.17},p)
 local selected=W.New('Frame',{Name='Selected',Size=UDim2.new(1,-10,1,-10),Position=UDim2.fromOffset(5,4),BackgroundColor3=T.Color.Green,BorderSizePixel=0,Visible=false},b);W.Round(selected,15);W.Stroke(selected,T.Color.Gold,2.5);W.Gradient(selected,Color3.fromRGB(216,255,180),Color3.fromRGB(106,166,75))
 W.Icon(b,icon or name,UDim2.new(1,-28,.65,-4),UDim2.fromOffset(14,5))
 local l=W.Heading(b,name,UDim2.new(1,-6,.29,0),UDim2.new(0,3,.68,-2),16,T.Color.White);l.TextXAlignment=Enum.TextXAlignment.Center;l.TextStrokeColor3=T.Color.WoodDark;l.TextStrokeTransparency=.15
 b.ImageTransparency=.88;b.BackgroundTransparency=0;b.BackgroundColor3=T.Color.WoodDark;W.Round(b,14);W.Stroke(b,T.Color.Gold,1)
 W.Bind(b,callback);return b
end
function W.SideActionButton(p,name,icon,size,pos,callback,options)
 return require(script.Parent.SideActionButton).new(W,p,name,icon,size,pos,callback,options)
end
function W.Selected(b,on) local s=b:FindFirstChild('Selected');if s then s.Visible=on end;b:SetAttribute('Selected',on) end
function W.Disabled(b,value)
 b:SetAttribute('Disabled',value);b.Active=not value;b.Selectable=not value
 -- Composite side controls keep a transparent hit target in every state.
 b.BackgroundTransparency=b:GetAttribute('Component')=='SideActionButton'and 1 or (value and .4 or 0)
end
function W.Card(parent,height)
 return W.Surface(parent,'Card',UDim2.new(1,-8,0,height),nil,'Paper')
end
function W.List(p) return W.New('UIListLayout',{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},p) end
function W.Grid(p,minWidth,height,gap)
 local grid=W.New('UIGridLayout',{CellPadding=UDim2.fromOffset(gap or 12,gap or 12),SortOrder=Enum.SortOrder.LayoutOrder},p)
 local function resize()
  local w=math.max(100,p.AbsoluteSize.X-24);local columns=math.max(1,math.floor((w+(gap or 12))/(minWidth+(gap or 12))))
  grid.CellSize=UDim2.fromOffset(math.floor((w-(columns-1)*(gap or 12))/columns),height)
 end
 resize();local c=p:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize);grid.Destroying:Once(function()c:Disconnect()end);return grid
end
function W.Scroll(p,name,size,pos)
 local s=W.New('ScrollingFrame',{Name=name,Size=size,Position=pos or UDim2.new(),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=4,ScrollBarImageColor3=T.Color.Muted,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,ElasticBehavior=Enum.ElasticBehavior.WhenScrollable},p)
 W.New('UIPadding',{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,8)},s);return s
end
function W.Format(v)
 v=tonumber(v) or 0
 for _,u in ipairs({{1e12,'T'},{1e9,'B'},{1e6,'M'},{1e3,'K'}}) do if v>=u[1] then return string.format('%.1f%s',v/u[1],u[2]) end end
 return tostring(math.floor(v))
end
function W.Rate(value)return math.abs(value or 0)<1000 and string.format('%g',value or 0)or W.Format(value)end
function W.Empty(p,title,body)
 local c=W.Card(p,142);W.Icon(c,'Leaf',UDim2.fromOffset(56,56),UDim2.fromOffset(12,18));W.Heading(c,title,UDim2.new(1,-94,0,44),UDim2.fromOffset(78,16),21);W.Text(c,body or '',UDim2.new(1,-32,0,55),UDim2.fromOffset(16,73),14,T.Color.Muted);return c
end
function W.PetPreview(p,pet,size,pos,silhouette) return require(script.Parent.Viewport).Pet(p,pet,size,pos,silhouette) end
function W.Viewport(p,model,size,pos) return require(script.Parent.Viewport).Model(p,model,size,pos) end
function W.SearchBar(p,value,changed)
 local bar=W.Surface(p,'SearchBar',UDim2.new(1,0,0,T.Size.Button),nil,'Paper')
 local box=W.New('TextBox',{Name='SearchInput',Size=UDim2.new(1,-66,1,-8),Position=UDim2.fromOffset(14,4),Text=value or '',PlaceholderText='Search companions…',ClearTextOnFocus=false,BackgroundTransparency=1,Font=T.Body,TextSize=T.Size.Body,TextColor3=T.Color.Ink,PlaceholderColor3=T.Color.Muted,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},bar)
 local apply=W.Button(bar,'Go',UDim2.fromOffset(44,44),UDim2.new(1,-47,0,1),function()changed(box.Text)end,T.Color.Wood);apply.Name='ApplySearch';apply.TextSize=13
 box.FocusLost:Connect(function()changed(box.Text)end)
 return bar,box
end
function W.ProgressBar(p,value,size,pos)
 local track=W.New('Frame',{Name='Progress',Size=size,Position=pos or UDim2.new(),BackgroundColor3=T.Color.Line,BorderSizePixel=0},p);W.Round(track,5)
 local fill=W.New('Frame',{Name='Fill',Size=UDim2.fromScale(0,1),BackgroundColor3=T.Color.Green,BorderSizePixel=0},track);W.Round(fill,5);Motion.ProgressChange(fill,value);return track,fill
end
function W.RarityBadge(p,rarity,size,pos)
 local def=T.Rarities[rarity] or T.Rarities.Common
 local b=W.New('Frame',{Name='RarityBadge',Size=size or UDim2.fromOffset(126,26),Position=pos or UDim2.new(),BackgroundColor3=def.Color:Lerp(T.Color.Card,.78),BorderSizePixel=0},p);W.Round(b,10);W.Stroke(b,def.Color,1)
 local text=W.Heading(b,rarity,UDim2.fromScale(1,1),nil,13,T.Color.Ink);text.TextXAlignment=Enum.TextXAlignment.Center;return b
end
function W.LockedOverlay(p)
 local lock=W.Surface(p,'Locked',UDim2.fromOffset(48,48),UDim2.new(.5,-24,.5,-24),'Paper')
 local hoop=W.New('Frame',{Size=UDim2.fromOffset(18,20),Position=UDim2.fromOffset(15,7),BackgroundTransparency=1},lock);W.Round(hoop,8);W.Stroke(hoop,T.Color.Ink,4)
 local body=W.New('Frame',{Size=UDim2.fromOffset(30,23),Position=UDim2.fromOffset(9,20),BackgroundColor3=T.Color.Ink,BorderSizePixel=0},lock);W.Round(body,5)
 W.Heading(body,'•',UDim2.fromScale(1,1),nil,20,T.Color.Gold).TextXAlignment=Enum.TextXAlignment.Center;return lock
end
function W.CurrencyPill(parent,id,size,pos)
 local pill=W.Surface(parent,id,size,pos,'Wood')
 W.Icon(pill,id,UDim2.fromOffset(50,50),UDim2.fromOffset(4,3))
 W.Text(pill,T.CurrencyName(id),UDim2.new(1,-66,0,16),UDim2.fromOffset(60,6),11,T.Color.Panel)
 local value=W.Heading(pill,'…',UDim2.new(1,-66,0,28),UDim2.fromOffset(60,20),23,T.Color.White);value.Name='Value'
 return pill,value
end
function W.NotificationBadge(parent)
 if parent:GetAttribute('Component')=='SideActionButton'then return require(script.Parent.SideActionButton).Badge(W,parent)end
 local badge=W.New('Frame',{Name='NotificationBadge',Size=UDim2.fromOffset(25,25),Position=UDim2.new(1,-23,0,0),BackgroundColor3=T.Color.Red,BorderSizePixel=0,Visible=false,ZIndex=9},parent)
 W.Round(badge,20);W.Stroke(badge,T.Color.Panel,2)
 local label=W.Heading(badge,'',UDim2.fromScale(1,1),nil,13,T.Color.White);label.TextXAlignment=Enum.TextXAlignment.Center
 return function(count)badge.Visible=count>0;label.Text=count>9 and '9+' or tostring(count)end
end
function W.Tooltip(button,body)
 local tooltip
 local function hide()if tooltip then tooltip:Destroy();tooltip=nil end end
 local function show()
  hide();local gui=button:FindFirstAncestorOfClass('ScreenGui');if not gui or not button.Visible then return end
  tooltip=W.Surface(gui,'Tooltip',UDim2.fromOffset(256,66),nil,'Paper');tooltip.ZIndex=T.Layers.Tooltip
  local x=math.clamp(button.AbsolutePosition.X-gui.AbsolutePosition.X,8,math.max(8,gui.AbsoluteSize.X-264))
  local y=button.AbsolutePosition.Y-gui.AbsolutePosition.Y-74
  if y<8 then y=button.AbsolutePosition.Y-gui.AbsolutePosition.Y+button.AbsoluteSize.Y+8 end
  tooltip.Position=UDim2.fromOffset(x,math.clamp(y,8,math.max(8,gui.AbsoluteSize.Y-74)))
  W.Text(tooltip,body,UDim2.new(1,-24,1,-16),UDim2.fromOffset(12,8),13)
 end
 button.MouseEnter:Connect(show);button.MouseLeave:Connect(hide);button.SelectionGained:Connect(show);button.SelectionLost:Connect(hide);button.Activated:Connect(hide);button.Destroying:Once(hide)
 return hide
end
-- Named components share the same primitives and visual authority.
W.WoodFrame=function(p,n,s,pos)return W.Surface(p,n,s,pos,'Wood')end
W.ParchmentPanel=function(p,n,s,pos)return W.Surface(p,n,s,pos,'Paper')end
W.WoodHeader=W.WoodFrame;W.WoodTab=W.WoodButton
W.BottomNavButton=W.WoodButton;W.SideNavButton=W.SideActionButton
W.GreenPrimaryButton=W.Button
W.CreamSecondaryButton=function(p,t,s,pos,fn)local b=W.Button(p,t,s,pos,fn,T.Color.Card);b.TextColor3=T.Color.Ink;b.TextStrokeTransparency=1;return b end
W.RedCloseButton=function(p,s,pos,fn)return W.Button(p,'×',s,pos,fn,T.Color.Red)end
W.PetCard=W.Card;W.IndexCard=W.Card;W.BiomeCard=W.Card;W.GardenCard=W.Card;W.ChallengeRow=W.Card;W.ShopCard=W.Card;W.UpgradeCard=W.Card
W.ViewportCard=W.PetPreview
return W
