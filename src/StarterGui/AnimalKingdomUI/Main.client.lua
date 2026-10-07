local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Input=game:GetService('UserInputService')
local Gui=game:GetService('GuiService')
local Knit=require(RS.Packages.Knit)
local V2=script.Parent.AnimalKingdomUIV2
local W=require(V2.Components)
local Bridge=require(script.Parent.RemoteBridge)
local PetMenus=require(script.Parent.PetMenus)
local NumberFormat=require(RS.Shared.Gameplay.PetNumberFormat)
local Progression=require(script.Parent.ProgressionMenus)
local Garden=require(script.Parent.GardenMenus)
local Plot=require(script.Parent.PlotMenu)
local Hatch=require(script.Parent.HatchPresentation)
local Sounds=require(RS.Shared.Gameplay.PresentationSounds)
local screen=script.Parent;local player=Players.LocalPlayer
screen:SetAttribute('ProductionUI',true);screen:SetAttribute('Version','2.2.0');screen:SetAttribute('ActiveMenu','')
screen:SetAttribute('UIHidden',false) -- Session presentation only; never written to profile data.
screen.IgnoreGuiInset=false;screen.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;screen.ClipToDeviceSafeArea=true;screen.DisplayOrder=40
local connections={};local function connect(signal,fn)local c=signal:Connect(fn);table.insert(connections,c);return c end
local data,controller;local ctx={Request=Bridge.Request};local manager,hud,overlays,heldBar,quick,tutorial;local resize
local root=W.New('Frame',{Name='Interface',Size=UDim2.fromScale(1,1),BackgroundTransparency=1},screen)
-- Keep the restore control outside the interface it hides.
local visibilityControl=W.New('Frame',{Name='UIVisibilityControl',Size=UDim2.fromOffset(76,44),BackgroundTransparency=1,ZIndex=W.Theme.Layers.HUD},screen)
local uiToggle=W.Button(visibilityControl,'Hide UI',UDim2.fromScale(1,1),nil,function()ctx.SetUIHidden(not screen:GetAttribute('UIHidden'))end,W.Color.Wood)
uiToggle.Name='ToggleUI';uiToggle.TextSize=12
local function visibilityRequired()
 return screen:GetAttribute('OnboardingActive')or screen:GetAttribute('RewardRevealActive')or screen:GetAttribute('ModalActive')or(screen:GetAttribute('ActiveMenu')or '')~=''
end
function ctx.SetUIHidden(hidden)
 hidden=hidden==true and not visibilityRequired()
 local changed=screen:GetAttribute('UIHidden')~=hidden
 screen:SetAttribute('UIHidden',hidden);root.Visible=not hidden;uiToggle.Text=hidden and 'Show UI'or 'Hide UI'
 if hidden then
  if tutorial then tutorial.Pointer:Clear()end
  if Gui.SelectedObject and Gui.SelectedObject:IsDescendantOf(root)or Input:GetLastInputType().Name:find('Gamepad')then Gui.SelectedObject=uiToggle end
 end
 if changed and manager and not visibilityRequired()then manager:Focus(manager.Nav,'ToggleUI')end
end
local function updateVisibility()
 if visibilityRequired()then ctx.SetUIHidden(false)end
 visibilityControl.Visible=not visibilityRequired()
end
for _,key in ipairs({'OnboardingActive','RewardRevealActive','ModalActive','ActiveMenu'})do connect(screen:GetAttributeChangedSignal(key),updateVisibility)end
local panel=W.Surface(root,'Screens',UDim2.fromOffset(1150,650),UDim2.fromScale(.5,.47),'Wood');panel.AnchorPoint=Vector2.new(.5,.5);panel.ZIndex=W.Theme.Layers.Menu;panel.Visible=false;W.Decorate(panel)
local parchment=W.Surface(panel,'Parchment',UDim2.new(1,-26,1,-26),UDim2.fromOffset(13,13),'Paper')
local header=W.Surface(panel,'ScreenHeader',UDim2.new(1,-54,0,61),UDim2.fromOffset(27,15),'Wood')
local headerIcon=W.Icon(header,'Biomes',UDim2.fromOffset(47,47),UDim2.fromOffset(12,6))
local title=W.Heading(header,'',UDim2.new(1,-140,1,0),UDim2.fromOffset(70,0),27,W.Color.White)
local close=W.Button(header,'×',UDim2.fromOffset(43,43),UDim2.new(1,-54,0,9),function()ctx.Close()end,W.Color.Red);close.Name='CloseMenu';close.TextSize=31
local content=W.Scroll(panel,'Content',UDim2.new(1,-62,1,-110),UDim2.fromOffset(31,88));ctx.Content=content
local menus={Pets=PetMenus.Pets,Index=PetMenus.Index,Garden=Garden.Render,Biomes=Progression.Biomes,Challenges=require(script.Parent.ActivityMenus).Render,Shop=Plot.Shop,Upgrades=Progression.Upgrades,Settings=Progression.Settings}
local rendering=false;local queued=false
local function render()
 if not manager.Active or not panel.Parent then return end
 if rendering then return end;rendering=true
 ctx.Data=data;ctx.ActiveName=manager.Active
 local selected=Gui.SelectedObject;ctx.SelectedName=selected and selected:IsDescendantOf(content) and selected.Name or nil
 local old=content.CanvasPosition;Garden.Close();content:ClearAllChildren()
 title.Text=({Challenges='Activities',Shop='Kingdom Shop'})[manager.Active]or manager.Active
 local icon=W.Theme.Icons[manager.Active] or 0;headerIcon.ImageRectOffset=Vector2.new(icon%4*256+7,math.floor(icon/4)*256+7)
 if not data then
  W.List(content);W.Empty(content,'Loading '..manager.Active..'…','Your kingdom is connecting. This will update when your profile is ready.')
  W.Button(content,'Try connecting again',UDim2.new(1,-8,0,46),nil,function()if controller then controller:RequestToUpdateData()end end)
 else
  local ok,err=pcall(menus[manager.Active],ctx)
  if not ok then
   warn('[AnimalKingdomUIV2] '..manager.Active..': '..tostring(err));content:ClearAllChildren();W.List(content);W.Empty(content,'This page could not load','Your progress is safe. Close this page and try again.');W.Button(content,'Try again',UDim2.new(1,-8,0,46),nil,function()ctx.Refresh()end)
  end
 end
 content.CanvasPosition=old;rendering=false;manager:Focus(panel,ctx.SelectedName)
 screen:SetAttribute('UIRenderCount',(screen:GetAttribute('UIRenderCount') or 0)+1)
end
function ctx.Refresh()
 if queued then return end;queued=true;task.defer(function()queued=false;if screen.Parent then render()end end)
end
hud=require(V2.HUD).new(root,function(name)
 if name=='Updates'then ctx.ShowUpdates()elseif name=='Profile'then ctx.ShowProfile()elseif name=='Friends'then ctx.InviteFriends()elseif name=='WeatherDetails'then ctx.ShowWeather()else ctx.Open(name)end
end)
heldBar=require(script.Parent.HeldPetsBar).new(root,function(pet)if quick then quick:Select(pet)end end)
function ctx.ViewPet(pet)if pet then ctx.Request('Equip',{UID=pet.UID,Equipped=true})end end
-- Include the sibling Held bar in the normal HUD's controller navigation graph.
manager=require(V2.MenuManager).new(screen,panel,root,function(name)
 ctx.ActiveName=name;if name=='Pets' or name=='Index'then PetMenus.DetailMode=false end;hud:Select(name);if resize then resize()end;if quick then quick:Close()end;content.CanvasPosition=Vector2.zero;render();Sounds.Play('UIOpen',screen)
end,function()
 ctx.ActiveName=nil;Garden.Close();content:ClearAllChildren();hud:Select(nil);if resize then resize()end;Sounds.Play('UIClose',screen)
end)
ctx.Manager=manager
quick=require(script.Parent.HeldPetActions).new(root,screen,heldBar,manager)
function ctx.Open(name)name=({Activities='Challenges',Daily='Challenges',KingdomShop='Shop'})[name]or name;if menus[name] then manager:Open(name)end end
function ctx.Close()manager:Close()end
manager.BackScreen=function(name)if name=='Pets' or name=='Index' then return PetMenus.Back(ctx)end;return name=='Garden' and Garden.Back(ctx)end
ctx.ActiveName=nil
overlays=require(V2.Overlays).new(root,manager)
ctx.Notify=function(message)overlays:Notify(message)end
local presentationNotice=W.New('BindableEvent',{Name='PresentationNotice'},screen);connect(presentationNotice.Event,ctx.Notify)
function ctx.CloseOverlay()return overlays:Close()end
manager.BackOverlay=function()if ctx.RevealBack then ctx.RevealBack();return true end;if quick:Close()then return true end;return overlays:Close()end
function ctx.Confirm(titleText,body,callback)
 overlays:Modal(titleText,body,{{Text='Cancel',Color=W.Color.Wood,Callback=function()overlays:Close()end},{Text='Confirm',Callback=function()overlays:Close();callback()end}})
end
function ctx.ShowUpdates()overlays:ShowHistory()end
function ctx.ShowProfile()
 if not data then ctx.Notify('Your profile is still loading.');return end
 local count=0;for _ in pairs(data.PetIndex)do count+=1 end
 overlays:Modal(player.DisplayName.."'s kingdom",#data.Pets..' companions • '..count..' discoveries\nDecoration capacity '..(25+data.PlotProgression.Level*5)..' • '..#data.DisplayedPetIds..' pets displayed',{{Text='Continue',Callback=function()overlays:Close()end}})
end
function ctx.InviteFriends()
 task.spawn(function()
  local social=game:GetService('SocialService');local ok,allowed=pcall(function()return social:CanSendGameInviteAsync(player)end)
  if ok and allowed then local opened=pcall(function()social:PromptGameInvite(player)end);if not opened then ctx.Notify('Invites are unavailable right now.')end
  else ctx.Notify('Invites are available when playing Animal Kingdom in Roblox.')end
 end)
end
function ctx.ShowWeather()
 local state=RS.WeatherState;local definition=require(RS.Shared.EventDefinitions)[state:GetAttribute('EventId')]
 local active=state:GetAttribute('Phase')=='Event'and definition
 local body=active and (definition.Description..'\n'..table.concat(definition.DisplayEffects or {},' • '))or 'A peaceful moment in the kingdom.'
 overlays:Modal(active and definition.DisplayName or 'Clear skies',body,{{Text='Continue',Callback=function()overlays:Close()end}})
end
function ctx.Travel(name)
 Hatch.Cleanup()
 overlays:Travel(name,name,function()
  local remote=RS.AnimalKingdomRemotes:FindFirstChild('TeleportToBiome')
  if remote then remote:FireServer(name);ctx.Close();return true else ctx.Notify('Travel is still connecting.');return false end
 end)
end
function ctx.PlotTravel()Hatch.Cleanup();overlays:Travel('TeleportPlot','Your Sanctuary',function()local sent=ctx.Request('TeleportPlot',{});if sent then ctx.Close()end;return sent end)end
function ctx.GardenTravel(action)
 Hatch.Cleanup()
 overlays:Travel(action,action=='VisitGarden' and 'Your Garden' or 'Animal Kingdom',function()local sent=ctx.Request(action,{});if sent then ctx.Close()end;return sent end)
end
local travelEvent=W.New('BindableEvent',{Name='PresentationTravel'},screen)
local travelFinished=W.New('BindableEvent',{Name='PresentationTravelFinished'},screen)
connect(travelEvent.Event,function(key,destination,request)
 if key=='VisitGarden' or key=='ReturnGarden'then ctx.GardenTravel(key)
 elseif type(request)=='function'then Hatch.Cleanup();overlays:Travel(key,destination,request)end
end)
connect(travelFinished.Event,function(key,success)overlays:FinishTravel(key,success)end)
tutorial=require(script.Parent.TutorialGuidance).new(root,screen,ctx,heldBar,quick)
resize=function()
 local size=screen.AbsoluteSize;hud:Resize(size,Input.TouchEnabled);ctx.Compact=hud.Compact;ctx.Narrow=size.X<600;ctx.Short=size.Y<520
 visibilityControl.Size=UDim2.fromOffset(ctx.Compact and 56 or 76,44)
 visibilityControl.Position=ctx.Compact and UDim2.new(1,-68,0,58)or UDim2.new(0,16,.3,86)
 updateVisibility()
 screen:SetAttribute('CompactLayout',ctx.Compact)
 heldBar:Resize(size,manager.Active,screen:GetAttribute('RewardRevealActive'))
 if ctx.Compact then
  panel.AnchorPoint=Vector2.new(.5,0);panel.Position=UDim2.new(.5,0,0,size.X<500 and 114 or 58);panel.Size=UDim2.new(1,-18,1,size.X<500 and -120 or -64)
  header.Position=UDim2.fromOffset(12,6);header.Size=UDim2.new(1,-24,0,44);title.TextSize=21
  close.Position=UDim2.new(1,-47,0,1);headerIcon.Size=UDim2.fromOffset(34,34)
  content.Position=UDim2.fromOffset(16,56);content.Size=UDim2.new(1,-32,1,-66)
  overlays.Toast.Position=UDim2.new(.5,0,0,115)
 else
  local available=size.Y-214;local height=math.min(730,available)
  panel.AnchorPoint=Vector2.new(.5,0);panel.Position=UDim2.new(.5,10,0,96+(available-height)/2);panel.Size=UDim2.fromOffset(math.min(1190,size.X-230),height)
  header.Position=UDim2.fromOffset(27,15);header.Size=UDim2.new(1,-54,0,61);title.TextSize=27
  close.Position=UDim2.new(1,-54,0,9);headerIcon.Size=UDim2.fromOffset(47,47)
  content.Position=UDim2.fromOffset(31,88);content.Size=UDim2.new(1,-62,1,-110)
  overlays.Toast.Position=UDim2.new(.5,0,0,78)
 end
 local inset=screen:GetAttribute('OnboardingActive') and 70 or 0
 hud.Root.Position=UDim2.fromOffset(0,ctx.Compact and inset or 0);hud.Root.Size=UDim2.new(1,0,1,ctx.Compact and -inset or 0)
 panel.Position+=UDim2.fromOffset(0,inset);panel.Size-=UDim2.fromOffset(0,inset)
 if manager.Active then ctx.Refresh()end
end
connect(screen:GetAttributeChangedSignal('OnboardingActive'),resize)
connect(screen:GetPropertyChangedSignal('AbsoluteSize'),resize);connect(screen:GetAttributeChangedSignal('RewardRevealActive'),resize);resize()
local weather=RS:WaitForChild('WeatherState')
local function contextUpdate()
 local id=weather:GetAttribute('Phase')=='Event' and weather:GetAttribute('EventId') or 'Clear skies'
 local def=require(RS.Shared.EventDefinitions)[id]
 hud.ContextText.Text=(player:GetAttribute('InGarden') and 'Garden' or player:GetAttribute('CurrentBiome') or 'Town')..' • '..(def and def.DisplayName or id)
end
connect(weather.AttributeChanged,contextUpdate);connect(player:GetAttributeChangedSignal('CurrentBiome'),contextUpdate);connect(player:GetAttributeChangedSignal('InGarden'),contextUpdate);contextUpdate()
connect(player:GetAttributeChangedSignal('CurrentBiome'),function()if ctx.ActiveName=='Biomes' then ctx.Refresh()end end)
local stopLuckyPresentation=require(script.Parent.LuckyTreePresentation).Start(screen)
local adventureStatus=require(script.Parent.AdventureStatus).new(root,screen,heldBar,ctx)
local activityPresentation=require(script.Parent.ActivityPresentation).new(ctx,screen)
local relevant={Pets={Pets=true,Activities=true,ActiveHeldPetUID=true,EquippedPets=true,DisplayedPetIds=true,PetStorageCapacity=true,MaxEquippedPets=true},Index={PetIndex=true,IndexRewards=true,NormalTreeModifiers=true,TreeMastery=true,WeightRecords=true},Garden={GardenExpeditions=true,GardenCosmetics=true,GardenCrops=true,GardenUpgrades=true,GardenBoosts=true,Pets=true,EquippedPets=true},Biomes={UnlockedBiomes=true,Currencies=true,BiomeMastery=true,PetIndex=true},Upgrades={Upgrades=true,PlotProgression=true},Challenges={Activities=true,DailyChallenges=true,WeeklyChallenges=true,Contracts=true,Pets=true,ActiveHeldPetUID=true},Settings={Settings=true},Shop={KingdomShop=true,Items=true,PlotProgression=true}}
local heldQueued=false
local function updateData(key,snapshot)
 if not screen.Parent or not root.Parent then return end
 data=snapshot;ctx.Data=data;if not data then return end
 activityPresentation:Update(data);quick:Update(data);tutorial:Update(data);adventureStatus.Data=data;adventureStatus:Update()
 if (not key or key=='Pets' or key=='HeldPetSlots' or key=='ActiveHeldPetUID') and not heldQueued then
  heldQueued=true
  task.defer(function()
   heldQueued=false
   if not screen.Parent or not heldBar.Root.Parent then return end
   local selected=Gui.SelectedObject;local preferred=selected and selected.Name
   if heldBar:Update(data) and not manager.Active and not manager.Modal and not manager.Popover and not screen:GetAttribute('RewardRevealActive') then manager:Focus(manager.Nav,preferred)end
  end)
 end
 if not key or key=='Currencies' or key=='DailyChallenges' or key=='WeeklyChallenges' or key=='Contracts' then hud:Update(data)end
 if not key or key=='Settings' then player:SetAttribute('AKReducedMotion',data.Settings.ReducedMotion);player:SetAttribute('AKShowOtherPets',data.Settings.ShowOtherPets)end
 local active=manager.Active
 if active and (not key or relevant[active] and relevant[active][key])then ctx.Refresh()end
end
Knit.OnStart():andThen(function()
 controller=Knit.GetController('DataController');connect(controller.Changed,updateData);updateData(nil,controller:GetPlayerData())
end):catch(function(err)warn('[AnimalKingdomUIV2] '..tostring(err));ctx.Notify('Your kingdom could not connect. Try rejoining.')end)
local remotes=RS:WaitForChild('AnimalKingdomRemotes')
task.spawn(function()
 local physical=remotes:WaitForChild('OpenKingdomRoute',30)
 if physical and screen.Parent then connect(physical.OnClientEvent,function(route)if route=='Shop'or route=='Challenges'or route=='Index'or route=='Biomes'then ctx.Open(route)end end)end
 local stock=RS:WaitForChild('KingdomShopStock',30)
 if stock and screen.Parent then connect(stock:GetAttributeChangedSignal('Rotation'),function()Sounds.Play('Restock',screen);if ctx.ActiveName=='Shop'then ctx.Refresh()end end)end
end)
connect(remotes:WaitForChild('TeleportToBiome').OnClientEvent,function(name,success,message)overlays:FinishTravel(name,success);if not success then ctx.Notify(message or 'This destination is not available yet.')end end)
connect(remotes:WaitForChild('GameplayNotice').OnClientEvent,function(payload)
 payload.Priority=payload.Kind=='Error'and 90 or payload.Kind=='Currency'and 10 or 30
 ctx.Notify(payload)
end)
local successText={Favorite='Favorites updated!',Lock='Companion protection updated.',Upgrade='Upgrade purchased!',UnlockBiome='Biome unlocked!',ShopBuy='Purchase complete!',ClaimChallenge='Challenge reward claimed!',ClaimIndex='Discovery reward claimed!',BuyGardenSupply='Garden supply activated!',UpgradeGarden='Garden upgraded!'}
connect(Bridge.Completed,function(payload)
 if payload.Action=='PetAssetsLoaded'then return end
 local result=payload.Result
 if payload.Action=='VisitGarden' or payload.Action=='ReturnGarden' or payload.Action=='TeleportPlot' then overlays:FinishTravel(payload.Action,payload.Success)end
 if not payload.Success then ctx.Notify(type(result)=='string' and result or 'Action unavailable. Please try again.');return end
 if type(result)=='table' and result.Kind=='PetsSold' then ctx.Notify('Sold '..result.Count..' pets for '..NumberFormat.Number(result.Total)..' Forest Coins.');Sounds.Play('UIClaim',screen)
 elseif type(result)=='table' and result.Kind=='Hatch' then ctx.Close();task.delay(result.PresentationDelay or 0,function()if screen.Parent then Hatch.Play(screen,result,data and data.Settings.ReducedMotion,ctx)end end)
 elseif type(result)=='table' and result.Kind=='LuckyReward' then task.delay(result.PresentationDelay or 0,function()if screen.Parent then ctx.Notify(result.Text);Sounds.Play('LuckyTree',screen)end end)
 elseif type(result)=='table' and result.Kind=='DeleteConfirmation' then
  overlays:Modal('Release this companion?','This permanently removes the companion from your inventory.',{{Text='Cancel',Color=W.Color.Wood,Callback=function()overlays:Close()end},{Text='Delete pet',Color=W.Color.Red,Callback=function()overlays:Close();ctx.Request('Delete',{UID=result.UID,Token=result.Token})end}})
 elseif type(result)=='table' and (result.Kind=='GardenClaim' or result.Kind=='GardenRecall' or result.Kind=='GardenClaimAll')then
  local lines={};for _,crop in ipairs(result.Crops or {})do table.insert(lines,'+'..tostring(crop.Amount)..' '..tostring(crop.Name))end
  overlays:Modal('Harvest complete!','+'..tostring(result.Amount)..' Harvest\n\n'..table.concat(lines,'  •  '),{{Text='Continue',Callback=function()overlays:Close()end}});Sounds.Play('UIClaim',screen)
 elseif type(result)=='table' and result.Kind=='GardenStarted' then ctx.Notify('Your companion is off to forage!');Sounds.Play('Garden',screen)
 elseif type(result)=='table' and result.Kind=='KingdomPurchase'then ctx.Notify(result.Text);Sounds.Play('UIPurchase',screen)
 elseif type(result)=='table' and (result.Kind=='GardenVisit' or result.Kind=='GardenReturn')then ctx.Notify(result.Kind=='GardenVisit' and 'Welcome to your Garden!' or 'Welcome back to the kingdom!')
 elseif type(result)=='string' then if payload.Action~='ActivityAccept'and payload.Action~='PawDiscover'then ctx.Notify(result)end
 elseif successText[payload.Action] then ctx.Notify(successText[payload.Action])end
 if payload.Action=='ClaimMastery'then Sounds.Play('Mastery',screen)end
 if payload.Action=='Equip'or payload.Action=='SelectHeldPet'or payload.Action=='SanctuarySwap'then Sounds.Play('PetSelect',screen)end
 if payload.Action=='UnlockBiome' then Sounds.Play('UIUnlock',screen)elseif payload.Action=='Upgrade' or payload.Action=='ShopBuy' then Sounds.Play('UIPurchase',screen)end
end)
local disposed=false
local function dispose()
 if disposed then return end;disposed=true
 stopLuckyPresentation();activityPresentation:Destroy();adventureStatus:Destroy();tutorial:Destroy();quick:Destroy();Hatch.Cleanup();Garden.Close();manager:Destroy();for _,c in ipairs(connections)do c:Disconnect()end
end
script.Destroying:Once(dispose)
-- A deferred Destroying callback on a destroyed LocalScript may never run.
-- Retire its observers before a rebuilt ScreenGui receives later profile updates.
connect(game:GetService('RunService').Heartbeat,function()if not screen.Parent then dispose()end end)
