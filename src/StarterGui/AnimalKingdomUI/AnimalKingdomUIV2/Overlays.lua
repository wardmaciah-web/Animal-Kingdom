local W=require(script.Parent.Components)
local T=W.Theme
local O={};O.__index=O
function O.new(screen,manager)
 local self=setmetatable({Screen=screen,Gui=screen:FindFirstAncestorWhichIsA('ScreenGui'),Manager=manager,Queue={},History={},Seen={},Showing=false},O)
 self.Root=W.New('Frame',{Name='Overlays',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=T.Layers.Modal},screen)
 -- Same shared queue, now a transparent typographic announcement rather than a tiny card.
 self.Toast=W.New('CanvasGroup',{Name='Toast',Size=UDim2.fromOffset(820,156),Position=UDim2.new(.5,0,0,86),AnchorPoint=Vector2.new(.5,0),BackgroundTransparency=1,GroupTransparency=1,Visible=false,ZIndex=T.Layers.Toast},self.Root)
 self.ToastScale=W.New('UIScale',{Scale=1},self.Toast)
 local function line(name,y,height,size,color)
  local label=W.Text(self.Toast,'',UDim2.new(1,-28,0,height),UDim2.fromOffset(14,y),size,color or Color3.new(1,1,1))
  label.Name=name;label.TextXAlignment=Enum.TextXAlignment.Center;label.TextStrokeColor3=Color3.fromRGB(20,29,26);label.TextStrokeTransparency=.12;label.ZIndex=T.Layers.Toast+2;return label
 end
 self.Shadow=line('TitleShadow',5,52,38,Color3.fromRGB(12,18,18));self.Shadow.TextTransparency=.4;self.Shadow.ZIndex=T.Layers.Toast
 self.Glow=line('TitleGlow',2,52,38);self.Glow.TextTransparency=.88;self.Glow.TextStrokeTransparency=.82;self.Glow.ZIndex=T.Layers.Toast+1
 W.New('UIStroke',{Color=T.Color.Gold,Thickness=5,Transparency=.8},self.Glow)
 self.ToastTitle=line('AnnouncementTitle',0,52,38);self.ToastTitle.Font=T.Font;self.Shadow.Font=T.Font;self.Glow.Font=T.Font
 self.ToastText=line('AnnouncementBody',54,60,21)
 self.ToastDetail=line('AnnouncementDetail',115,31,23,T.Color.Gold)
 self.Accent=W.New('Frame',{Name='Accent',Size=UDim2.fromOffset(120,3),Position=UDim2.new(.5,-60,0,49),BorderSizePixel=0,BackgroundColor3=T.Color.Gold,BackgroundTransparency=.18},self.Toast);W.Round(self.Accent,3)
 self.Fade=W.New('Frame',{Name='TravelFade',Size=UDim2.fromScale(1,1),BackgroundColor3=T.Color.GreenDark,BackgroundTransparency=1,Visible=false,ZIndex=T.Layers.Transition,BorderSizePixel=0},self.Root)
 self.TravelTitle=W.Heading(self.Fade,'',UDim2.new(1,-40,0,58),UDim2.new(0,20,.5,-29),30,T.Color.White);self.TravelTitle.TextXAlignment=Enum.TextXAlignment.Center
 W.Icon(self.Fade,'Leaf',UDim2.fromOffset(72,72),UDim2.new(.5,-36,.5,-108))
 return self
end
local Tween=game:GetService('TweenService')
local accents={LuckyTree=Color3.fromRGB(190,244,144),HotTree=Color3.fromRGB(255,177,79),Paw=Color3.fromRGB(151,239,223),Journey=Color3.fromRGB(255,224,146),Secret=Color3.fromRGB(230,176,255),Record=Color3.fromRGB(255,214,116),Rush=Color3.fromRGB(167,224,255),Adventure=Color3.fromRGB(181,236,181)}
local function decorate(item)
 local text=item.Message;local category=item.Category or ''
 if not item.Title then
  if category=='LuckyTree'then item.Title='LUCKY TREE'
  elseif category=='HotTree'then item.Title='HOT TREE'
  elseif category=='Shop'then item.Title='KINGDOM SHOP RESTOCK'
  elseif category=='Coop'then item.Title='KINGDOM GOAL COMPLETE'
  elseif category=='Mastery'or text:lower():find('mastery')then item.Title='MASTERY MILESTONE'
  elseif category=='Achievement'then
   if text:find('Secret')then item.Title='SECRET PET';item.Category='Secret'
   elseif text:lower():find('weight record')then item.Title='MAJOR WEIGHT RECORD';item.Category='Record';item.Priority=math.max(item.Priority,78)
   elseif text:lower():find('streak')then item.Title='SEARCH STREAK MILESTONE';item.Category='Record';item.Priority=math.max(item.Priority,72)
   elseif text:find('Legendary')then item.Title='LEGENDARY FIND'
   elseif text:find('Mythical')then item.Title='MYTHICAL FIND'
   else item.Title='KINGDOM DISCOVERY'end
  elseif category=='Rate'then item.Title='NEW SERVER RECORD';item.Category='Record';item.Priority=math.max(item.Priority,75)
  elseif category=='Invitation'then item.Title=text:find('Paw')and 'PAWPRINT HUNT'or 'TREE RUSH';item.Category=text:find('Paw')and 'Paw'or 'Rush'
  elseif category=='Cosmetic'then item.Title='A MOMENT IN THE KINGDOM'
  elseif item.Kind=='Error'then item.Title='ONE MOMENT'
  else item.Title='KINGDOM UPDATE';item.Compact=true end
 end
 item.Accent=accents[item.Category]or T.Color.Gold
 return item
end
function O:LayoutNotice(item)
 local size=self.Screen.AbsoluteSize;local small=size.X<700 or size.Y<500
 local width=math.min(size.X-28,900);local title=small and math.clamp(width/14,25,32)or math.clamp(size.X/43,32,42)
 local body=small and 16 or math.clamp(size.X/80,18,24)
 self.Toast.Size=UDim2.fromOffset(width,small and 136 or 160);self.Toast.Position=UDim2.new(.5,0,0,small and 10 or 82)
 for _,label in ipairs({self.ToastTitle,self.Shadow,self.Glow})do label.Text=item.Title;label.TextSize=title end
 self.ToastText.Text=item.Subtitle or item.Message;self.ToastText.TextSize=body
 self.ToastDetail.Text=item.Detail or '';self.ToastDetail.TextSize=small and 19 or 24
 self.ToastDetail.TextColor3=item.Accent;self.Accent.BackgroundColor3=item.Accent
 self.Glow.TextColor3=item.Accent;self.Glow.UIStroke.Color=item.Accent
 self.ToastText.Position=UDim2.fromOffset(14,small and 48 or 54);self.ToastText.Size=UDim2.new(1,-28,0,small and 50 or 60)
 self.ToastDetail.Position=UDim2.fromOffset(14,small and 101 or 115)
 for _,label in ipairs({self.ToastTitle,self.Shadow,self.Glow,self.ToastDetail,self.Accent})do label.Visible=not item.Compact end
 if item.Compact then self.Toast.Size=UDim2.fromOffset(math.min(width,640),54);self.ToastText.Position=UDim2.fromOffset(14,4);self.ToastText.Size=UDim2.new(1,-28,1,-8);self.ToastText.TextSize=small and 16 or 19 end
 self.Toast:SetAttribute('AnnouncementId',item.Id);self.Toast:SetAttribute('Priority',item.Priority);self.Toast:SetAttribute('Title',item.Title)
end
function O:AnimateNotice(enter)
 if self.NoticeTween then self.NoticeTween:Cancel()end
 local reduced=W.Motion.Reduced();local duration=reduced and .12 or enter and .18 or .5
 self.NoticeTween=Tween:Create(self.Toast,TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{GroupTransparency=enter and 0 or 1});self.NoticeTween:Play()
 if self.ScaleTween then self.ScaleTween:Cancel()end
 if enter then
  self.ToastScale.Scale=reduced and 1 or .9
  self.ScaleTween=Tween:Create(self.ToastScale,TweenInfo.new(reduced and .01 or .18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=reduced and 1 or 1.05});self.ScaleTween:Play()
  self.ScaleTween.Completed:Once(function(state)if state==Enum.PlaybackState.Completed and self.Toast.Parent then self.ScaleTween=Tween:Create(self.ToastScale,TweenInfo.new(.16,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Scale=1});self.ScaleTween:Play()end end)
 end
end
function O:Notify(payload)
 payload=type(payload)=='table'and table.clone(payload)or {Message=payload,Priority=60}
 if type(payload.Message)~='string'or payload.Message==''then return end
 local at=workspace:GetServerTimeNow();for id,t in pairs(self.Seen)do if at-t>900 then self.Seen[id]=nil end end
 payload.Id=payload.Id or(payload.Message..':'..math.floor(at/8))
 if self.Seen[payload.Id]then return end;self.Seen[payload.Id]=at
 payload.Message=payload.Message:gsub('Not Enough Coins','Not enough Forest Coins!'):gsub('Not enough Coins','Not enough Forest Coins!')
 payload.Priority=payload.Priority or 30;payload.At=at;payload.ExpiresAt=payload.ExpiresAt or at+90;decorate(payload)
 table.insert(self.History,1,{Message=payload.Title..' • '..payload.Message..(payload.Detail and ' • '..payload.Detail or ''),At=os.time()});if #self.History>30 then table.remove(self.History)end
 if payload.CoalesceKey then
  for i=#self.Queue,1,-1 do if self.Queue[i].CoalesceKey==payload.CoalesceKey then table.remove(self.Queue,i)end end
  if self.Current and self.Current.CoalesceKey==payload.CoalesceKey and not payload.Complete and not self.Current.Complete then
   self.Current=payload;self:LayoutNotice(payload);self.NoticeUntil=math.min(os.clock()+3.5,(self.NoticeStarted or os.clock())+7);return
  end
 end
 table.insert(self.Queue,payload);table.sort(self.Queue,function(a,b)return a.Priority==b.Priority and a.At<b.At or a.Priority>b.Priority end)
 if #self.Queue>12 then table.remove(self.Queue)end
 if self.Showing then return end;self.Showing=true
 task.spawn(function()
  while self.Root.Parent and #self.Queue>0 do
   local gui=self.Gui;local index=1
   if gui and gui:GetAttribute('OnboardingActive')then for i,candidate in ipairs(self.Queue)do if not candidate.World and candidate.Priority>=70 then index=i;break end end end
   local item=self.Queue[index]
   local function blocked(candidate)return gui and(gui:GetAttribute('RewardRevealActive')or gui:GetAttribute('ModalActive')or candidate.Category=='LuckyTree'and gui:GetAttribute('LuckyAssetsReady')==false or gui:GetAttribute('OnboardingActive')and(candidate.World or candidate.Priority<70))end
   if item.ExpiresAt<=workspace:GetServerTimeNow()then table.remove(self.Queue,index);continue end
   if blocked(item)then task.wait(.15);continue end
   table.remove(self.Queue,index);self.Current=item;self:LayoutNotice(item);self.Toast.Visible=true;if gui then gui:SetAttribute('AnnouncementActive',true)end;self:AnimateNotice(true)
   self.NoticeStarted=os.clock();self.NoticeUntil=os.clock()+(item.Compact and 2.4 or item.Priority>=90 and 5.5 or item.Complete and 5 or item.Priority>=30 and 4 or 3)
   local interrupted=false
   repeat
    task.wait(.05)
    local current=self.Current or item;self:LayoutNotice(current)
    self.Glow.TextTransparency=W.Motion.Reduced()and .93 or .89+.045*math.sin((os.clock()-self.NoticeStarted)*3)
    if blocked(current)then self.Toast.Visible=false;if gui then gui:SetAttribute('AnnouncementActive',false)end;table.insert(self.Queue,1,current);interrupted=true;break end
    -- Critical events can take the next slot after the current message had time to register.
    if self.Queue[1]and self.Queue[1].Priority>=90 and current.Priority<70 and os.clock()-self.NoticeStarted>1.4 then break end
   until os.clock()>=self.NoticeUntil or not self.Root.Parent
   if not self.Root.Parent then break end
   if not interrupted then self:AnimateNotice(false);task.wait(W.Motion.Reduced()and .12 or .5)end
   self.Toast.Visible=false;if gui then gui:SetAttribute('AnnouncementActive',false)end;self.Current=nil;task.wait(.3)
  end
  self.Showing=false
 end)
end
function O:Close()
 if not self.Dialog then return false end
 self.Dialog:Destroy();self.Dialog=nil;self.Manager:SetModal(nil);return true
end
function O:Modal(title,body,actions)
 self:Close()
 local shade=W.New('TextButton',{Name='ModalShade',Text='',Size=UDim2.fromScale(1,1),BackgroundColor3=T.Color.WoodDark,BackgroundTransparency=.4,BorderSizePixel=0,AutoButtonColor=false,Selectable=false,Active=true,ZIndex=T.Layers.Modal},self.Root)
 self.Dialog=shade
 local card=W.Surface(shade,'ModalCard',UDim2.new(.9,0,.8,0),UDim2.fromScale(.5,.48),'Wood');card.AnchorPoint=Vector2.new(.5,.5);W.New('UISizeConstraint',{MaxSize=Vector2.new(540,350)},card)
 local paper=W.Surface(card,'Parchment',UDim2.new(1,-18,1,-18),UDim2.fromOffset(9,9),'Paper');W.Decorate(card)
 W.Heading(paper,title,UDim2.new(1,-40,0,44),UDim2.fromOffset(20,14),25)
 W.Text(paper,body,UDim2.new(1,-40,1,-156),UDim2.fromOffset(20,65),16).Name='BodyText'
 for i,a in ipairs(actions or {}) do W.Button(paper,a.Text,UDim2.new(1/#actions,-28,0,46),UDim2.new((i-1)/#actions,14,1,-65),a.Callback,a.Color) end
 W.Motion.ModalOpen(card);self.Manager:SetModal(shade);return paper
end
function O:ShowHistory()
 local paper=self:Modal('Kingdom updates','',{{Text='Continue',Callback=function()self:Close()end}})
 paper.BodyText.Visible=false
 local scroll=W.Scroll(paper,'NotificationHistory',UDim2.new(1,-32,1,-133),UDim2.fromOffset(16,58));W.List(scroll)
 if #self.History==0 then W.Text(scroll,'No updates yet. Your latest discoveries and rewards will appear here.',UDim2.new(1,-10,0,70),nil,14)
 else for _,entry in ipairs(self.History)do local label=W.Text(scroll,entry.Message,UDim2.new(1,-10,0,40),nil,14);label.AutomaticSize=Enum.AutomaticSize.Y end end
end
function O:FinishTravel(key,success)
 if not self.Travelling or self.TravelKey~=key or self.TravelFinishing then return end
 self.TravelFinishing=true
 local token=self.Travelling
 task.delay(success and .2 or .05,function()
  if self.Travelling~=token or not self.Fade.Parent then return end
  require(game.ReplicatedStorage.Shared.Gameplay.CameraOwnership).RestorePlayer()
  W.Motion.Tween(self.Fade,'ModalClose',{BackgroundTransparency=1})
  W.Motion.Tween(self.TravelTitle,'ModalClose',{TextTransparency=1})
  task.delay(.2,function()if self.Travelling==token then self.Fade.Visible=false;self.Travelling=nil;self.TravelKey=nil;self.TravelFinishing=nil end end)
 end)
end
function O:Travel(key,title,callback)
 if self.Travelling then return false end
 local token={};self.Travelling=token;self.TravelKey=key;self.TravelFinishing=false
 self.Fade.Visible=true;self.Fade.Active=true;self.TravelTitle.Text=title or 'Travelling…';self.TravelTitle.TextTransparency=0
 W.Motion.Tween(self.Fade,'ModalOpen',{BackgroundTransparency=.035})
 task.delay(.2,function()
  if self.Travelling~=token then return end
  local ok,accepted=pcall(callback)
  if not ok or accepted==false then self:FinishTravel(key,false)end
 end)
 task.delay(6,function()if self.Travelling==token then self:FinishTravel(key,false);self:Notify('Travel is taking longer than expected. Please try again.')end end)
 return true
end
return O
