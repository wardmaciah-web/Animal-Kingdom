local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local Tween=game:GetService("TweenService")
local W=require(script.Parent.GameplayWidgets)
local Config=require(RS.Shared.Gameplay.Definitions.LuckyTreeDefinitions)
local Catalog=require(RS.Shared.Gameplay.IndexCatalog)
local Odds=require(RS.Shared.Gameplay.NormalTreeOdds)
local Format=require(RS.Shared.Gameplay.PetNumberFormat)
local M={}
local attemptIds={}
function M.Try(screen,prompt)
 local id=prompt:GetAttribute("LuckyEventId")
 attemptIds[id]=attemptIds[id] or game.HttpService:GenerateGUID(false)
 return require(screen.RemoteBridge).Request("LuckyTry",{EventId=id,RequestId=attemptIds[id]})
end
local function permitted(screen)
 local char=Players.LocalPlayer.Character;local h=char and char:FindFirstChildOfClass("Humanoid")
 return h and h.Health>0 and screen:GetAttribute("ActiveMenu")=="" and not screen:GetAttribute("RewardRevealActive") and not screen:GetAttribute("ModalActive")
end
local function chance(id)
 local total=0;for _,e in ipairs(Config.Categories)do total+=e.DropWeight end
 for _,e in ipairs(Config.Categories)do if e.Id==id then return Odds.Format(e.DropWeight/total).." chance per try"end end
end
local function promotion(petId)
 local sources=Catalog.SourcePools(petId)
 if #sources==0 then return "Lucky Tree exclusive!"end
 for _,pool in ipairs(sources)do if math.abs(Odds.Chance(pool,petId)-.01)<1e-10 then return "5× this pet's normal base odds! ("..pool.DisplayName..")"end end
 return "Special Lucky Tree reward!"
end
function M.Attach(screen,prompt,gui,button,actionText,kind)
 local biome=prompt:GetAttribute("LuckyBiome");local def=Config.Biomes[biome];if not def then return function()end end
 local panel=W.Surface(screen,"LuckyRewards",UDim2.fromOffset(278,274),nil,"Paper");panel.ZIndex=6;panel.Visible=false;panel.Active=true
 local header=W.Heading(panel,string.upper(biome).." LUCKY TREE",UDim2.new(1,-12,0,26),UDim2.fromOffset(6,4),17)
 local subtitle=W.Text(panel,"Three tries. One reward per try.",UDim2.new(1,-12,0,19),UDim2.fromOffset(6,31),12)
 local used=W.Text(panel,"0/3 used",UDim2.new(1,-12,0,20),UDim2.fromOffset(6,50),12)
 local secret=W.PetPreview(panel,{PetId=def.SecretPetId,Mutation="Normal",Level=1},UDim2.fromOffset(56,56),UDim2.fromOffset(6,75),true)
 secret.ImageColor3=Color3.new(0,0,0) -- tint only this cloned viewport, never the template
 local coin=W.Icon(panel,"Coins",UDim2.fromOffset(45,45),UDim2.fromOffset(11,147));coin.ImageColor3=Color3.new(0,0,0)
 -- A tiny bottle drawn with existing UI primitives, never a mesh/art download.
 local bottle=W.New("Frame",{Name="LuckPotion",Size=UDim2.fromOffset(29,35),Position=UDim2.fromOffset(18,211),BackgroundColor3=W.Color.Green,BorderSizePixel=0},panel);W.Round(bottle,8)
 W.New("Frame",{Size=UDim2.fromOffset(14,8),Position=UDim2.new(.5,-7,0,-6),BackgroundColor3=W.Color.Wood,BorderSizePixel=0},bottle)
 local secretText=W.Text(panel,"Secret Pet\n"..chance("Secret"),UDim2.new(1,-75,0,40),UDim2.fromOffset(68,75),13)
 local promo=W.Text(panel,promotion(def.SecretPetId),UDim2.new(1,-75,0,25),UDim2.fromOffset(68,116),11,W.Color.Red)
 local coinsText=W.Text(panel,Format.Number(def.Coins).." Forest Coins\n"..chance("Coins"),UDim2.new(1,-75,0,45),UDim2.fromOffset(68,147),13)
 local luckText=W.Text(panel,string.format("%s Luck — +%d%%\nLasts 5:00 • %s",biome,math.floor((def.LuckMultiplier-1)*100+.5),chance("Luck")),UDim2.new(1,-75,0,55),UDim2.fromOffset(68,204),12)
 local connections={};local destroyed=false;local hovered=false;local leaveAt=0
 local function connect(signal,fn)table.insert(connections,signal:Connect(fn))end
 local function enter()hovered=true end
 local function leave()hovered=false;leaveAt=os.clock()+.4 end
 connect(gui.MouseEnter,enter);connect(gui.MouseLeave,leave);connect(panel.MouseEnter,enter);connect(panel.MouseLeave,leave)
 connect(button.SelectionGained,enter);connect(button.SelectionLost,leave)
 local function update()
  if destroyed or not panel.Parent then return end
  local p=Players.LocalPlayer;local id=prompt:GetAttribute("LuckyEventId")
  local count=p:GetAttribute("LuckyTreeEventId")==id and (p:GetAttribute("LuckyTreeTriesUsed") or 0) or 0
  used.Text=count.."/"..Config.Attempts.." used";actionText.Text=count>=Config.Attempts and ("All tries used • "..Config.Attempts.."/"..Config.Attempts) or "TRY YOUR LUCK\n"..count.."/"..Config.Attempts.." used"
  local nearby=prompt.Parent and prompt.Enabled and gui.Visible
  local show=nearby and permitted(screen) and (Input.TouchEnabled or kind==Enum.ProximityPromptInputType.Gamepad or hovered or os.clock()<leaveAt)
  panel.Visible=show==true;screen:SetAttribute("LuckyPreviewActive",panel.Visible)
  local size=screen.AbsoluteSize;local compact=size.X<900 or size.Y<580;local portrait=compact and size.X<500;local landscape=compact and size.Y<580 and not portrait
  if compact then
   local width=portrait and math.min(254,size.X-120) or 248
   local height=156
   panel.Size=UDim2.fromOffset(width,height)
   local held=screen:FindFirstChild("HeldPets",true)
   local heldTop=held and held.AbsolutePosition.Y-screen.AbsolutePosition.Y or size.Y-95
   local top=math.min(portrait and 140 or 143,heldTop-height-4)
   panel.Position=portrait and UDim2.new(1,-width-8,0,top) or UDim2.new(.5,12,0,math.max(56,top))
   header.Size=UDim2.new(1,-10,0,18);header.Position=UDim2.fromOffset(5,2);header.TextSize=12
   subtitle.Position=UDim2.fromOffset(5,21);subtitle.Size=UDim2.new(1,-10,0,13);subtitle.TextSize=10
   used.Position=UDim2.fromOffset(5,35);used.Size=UDim2.new(1,-10,0,14);used.TextSize=10
   secret.Size=UDim2.fromOffset(32,32);secret.Position=UDim2.fromOffset(3,50)
   secretText.Position=UDim2.fromOffset(39,49);secretText.Size=UDim2.new(1,-43,0,28);secretText.TextSize=10
   promo.Position=UDim2.fromOffset(39,76);promo.Size=UDim2.new(1,-43,0,16);promo.TextSize=10
   coin.Size=UDim2.fromOffset(28,28);coin.Position=UDim2.fromOffset(5,94)
   coinsText.Position=UDim2.fromOffset(39,94);coinsText.Size=UDim2.new(1,-43,0,28);coinsText.TextSize=10
   bottle.Size=UDim2.fromOffset(18,23);bottle.Position=UDim2.fromOffset(10,130)
   luckText.Position=UDim2.fromOffset(39,124);luckText.Size=UDim2.new(1,-43,0,30);luckText.TextSize=10
   if landscape then
    width=math.min(450,size.X-260);height=108;top=54
    panel.Size=UDim2.fromOffset(width,height);panel.Position=UDim2.new(1,-width-8,0,top)
    local cell=(width-16)/3
    header.Size=UDim2.new(1,-76,0,18);subtitle.Size=UDim2.new(1,-10,0,12)
    used.Position=UDim2.new(1,-70,0,4);used.Size=UDim2.fromOffset(65,15)
    secret.Position=UDim2.fromOffset(8+cell/2-12,34);secret.Size=UDim2.fromOffset(24,24)
    secretText.Position=UDim2.fromOffset(8,58);secretText.Size=UDim2.fromOffset(cell,26)
    promo.Position=UDim2.fromOffset(8,84);promo.Size=UDim2.fromOffset(cell,22)
    coin.Position=UDim2.fromOffset(8+cell*1.5-12,34);coin.Size=UDim2.fromOffset(24,24)
    coinsText.Position=UDim2.fromOffset(8+cell,60);coinsText.Size=UDim2.fromOffset(cell,36)
    bottle.Position=UDim2.fromOffset(8+cell*2.5-9,37);bottle.Size=UDim2.fromOffset(18,21)
    luckText.Position=UDim2.fromOffset(8+cell*2,60);luckText.Size=UDim2.fromOffset(cell,44)
   end
   if show then
    gui:SetAttribute("LuckyFixedPosition",true)
    gui.Position=portrait and UDim2.fromOffset(56,top+height/2) or UDim2.fromOffset(122,top+height/2)
    gui.Size=portrait and UDim2.fromOffset(96,106) or UDim2.fromOffset(220,88)
    if not portrait and not landscape then
     panel.Position=UDim2.new(1,-width-8,.5,-height/2)
     gui.Position=UDim2.fromOffset(size.X-width-140,size.Y/2)
    end
    if not portrait then
     button.Position=UDim2.fromOffset(12,16);button.Size=UDim2.fromOffset(48,48)
     actionText.Position=UDim2.fromOffset(72,37);actionText.Size=UDim2.new(1,-82,0,32);actionText.TextSize=12
     local title=gui:FindFirstChild("LuckyPromptTitle",true);if title then title.Visible=true end
    end
    if portrait then button.Position=UDim2.fromOffset(24,6);button.Size=UDim2.fromOffset(44,40);actionText.Position=UDim2.fromOffset(4,52);actionText.Size=UDim2.new(1,-8,0,48);actionText.TextSize=11
     local title=gui:FindFirstChild("LuckyPromptTitle",true);if title then title.Visible=false end
    end
   else gui:SetAttribute("LuckyFixedPosition",false)end
  else
   gui.Size=UDim2.fromOffset(252,88);button.Size=UDim2.fromOffset(48,48);button.Position=UDim2.fromOffset(12,16)
   actionText.Position=UDim2.fromOffset(72,37);actionText.Size=UDim2.new(1,-82,0,32);actionText.TextSize=12
   local title=gui:FindFirstChild("LuckyPromptTitle",true);if title then title.Visible=true end
   header.Size=UDim2.new(1,-12,0,26);header.Position=UDim2.fromOffset(6,4);header.TextSize=17
   subtitle.Position=UDim2.fromOffset(6,31);subtitle.Size=UDim2.new(1,-12,0,19);subtitle.TextSize=12
   used.Position=UDim2.fromOffset(6,50);used.Size=UDim2.new(1,-12,0,20);used.TextSize=12
   secret.Size=UDim2.fromOffset(56,56);secret.Position=UDim2.fromOffset(6,75)
   secretText.Position=UDim2.fromOffset(68,75);secretText.Size=UDim2.new(1,-75,0,40);secretText.TextSize=13
   promo.Position=UDim2.fromOffset(68,116);promo.Size=UDim2.new(1,-75,0,25);promo.TextSize=11
   coin.Size=UDim2.fromOffset(45,45);coin.Position=UDim2.fromOffset(11,147)
   coinsText.Position=UDim2.fromOffset(68,147);coinsText.Size=UDim2.new(1,-75,0,45);coinsText.TextSize=13
   bottle.Size=UDim2.fromOffset(29,35);bottle.Position=UDim2.fromOffset(18,211)
   luckText.Position=UDim2.fromOffset(68,204);luckText.Size=UDim2.new(1,-75,0,55);luckText.TextSize=12
   panel.Size=UDim2.fromOffset(278,274);panel.Position=UDim2.new(1,-292,.5,-137);gui:SetAttribute("LuckyFixedPosition",false)
  end
 end
 connect(Players.LocalPlayer:GetAttributeChangedSignal("LuckyTreeTriesUsed"),update)
 connect(screen:GetPropertyChangedSignal("AbsoluteSize"),update)
 task.spawn(function()while not destroyed and panel.Parent do update();task.wait(.1)end end)
 update()
 return function()
  destroyed=true;for _,c in ipairs(connections)do c:Disconnect()end;panel:Destroy();screen:SetAttribute("LuckyPreviewActive",false);gui:SetAttribute("LuckyFixedPosition",false)
 end
end
function M.LayoutAnnouncement(screen,banner)
 local size=screen.AbsoluteSize;local compact=size.X<900 or size.Y<580
 if compact and size.X<500 then
  -- Temporarily occupies the brand area, above currencies and navigation.
  banner.Position=UDim2.fromOffset(8,2);banner.Size=UDim2.fromOffset(size.X-84,74);banner.TextSize=12
 elseif compact then
  banner.Position=UDim2.fromOffset(160,54);banner.Size=UDim2.fromOffset(size.X-240,26);banner.TextSize=12
 else
  local width=math.min(720,size.X-500)
  banner.Position=UDim2.fromOffset((size.X-width)/2,106);banner.Size=UDim2.fromOffset(width,44);banner.TextSize=17
 end
 return compact and size.X<500
end
function M.Start(screen)
 local remote=RS:WaitForChild("AnimalKingdomRemotes"):WaitForChild("LuckyTreeState")
 local seen,queued;local stopped=false;local banner;local hiddenBrand={};local assetsReady=false
 -- Preload actual replicated MeshParts, not bare mesh IDs (which Roblox can
 -- interpret as image requests). These stored models have no gameplay scripts.
 task.spawn(function()
  local targets,proxies,expected={},{},{}
  local function addTexture(id)
   if id=="" or expected[id]then return end
   expected[id]=true;local proxy=Instance.new("ImageLabel");proxy.Image=id
   table.insert(targets,proxy);table.insert(proxies,proxy)
  end
  local ok,issue=pcall(function()
   for _,biome in ipairs({"Meadow","Forest"})do
    local def=Config.Biomes[biome];local template=game
    for name in string.gmatch(def.TemplatePath or "","[^.]+")do template=template:WaitForChild(name,15);assert(template,"Lucky template not replicated")end
    assert(template~=game and template:IsA("Model"),"Lucky template unavailable")
    table.insert(targets,template)
    for _,part in ipairs(template:GetDescendants())do
     if part:IsA("MeshPart")then expected[part.MeshId]=true;addTexture(part.TextureID)
     elseif part:IsA("SurfaceAppearance")then
      for _,property in ipairs({"ColorMap","NormalMap","MetalnessMap","RoughnessMap"})do
       local readable,id=pcall(function()return part[property.."Content"].Uri end)
       if readable and id then addTexture(id)end
      end
     end
    end
    local petOK,why=require(RS.Shared.Gameplay.PetAssetLoading).Preload(def.SecretPetId)
    assert(petOK,why)
   end
   local loaded={}
   game:GetService("ContentProvider"):PreloadAsync(targets,function(id,status)loaded[id]=status==Enum.AssetFetchStatus.Success end)
   for id in pairs(expected)do assert(loaded[id],"Lucky asset failed to load: "..id)end
  end)
  for _,proxy in ipairs(proxies)do proxy:Destroy()end
  if not stopped then assetsReady=ok;screen:SetAttribute("LuckyAssetsReady",ok)end
  if not ok then warn("[LuckyTrees] "..tostring(issue))end
 end)
 -- Reuse the shared announcement queue, including late joiners. The server
 -- and client use the same event ID so a spawn can only display once.
 local connection=remote.OnClientEvent:Connect(function(state)
  if state.PendingRequestId then attemptIds[state.EventId]=state.PendingRequestId end
  if not state.Active or seen==state.EventId then return end
  seen=state.EventId
  screen:WaitForChild("PresentationNotice"):Fire({
   Id="LuckySpawn:"..state.EventId,World=true,Category="LuckyTree",Priority=100,ExpiresAt=state.EndsAt,
   Message="A Lucky Tree has appeared in "..state.Biome.."! Three free tries each • 5% Secret / 40% Coins / 55% Luck.",
  })
 end)
 local completed=require(screen.RemoteBridge).Completed:Connect(function(payload)
  local result=payload.Result
  if payload.Action=="LuckyTry" and payload.Success and type(result)=="table" and attemptIds[result.LuckyEventId]==result.LuckyRequestId then attemptIds[result.LuckyEventId]=nil end
 end)
 remote:FireServer()
 return function()stopped=true;connection:Disconnect();completed:Disconnect()end
end
return M
