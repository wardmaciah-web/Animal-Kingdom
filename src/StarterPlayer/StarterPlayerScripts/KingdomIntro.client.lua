-- One local cinematic owner; no rewards, pet ownership or movement stats are changed.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local Lighting=game:GetService("Lighting")
local p=Players.LocalPlayer
local Camera=require(RS.Shared.Gameplay.CameraOwnership)
local running=false
local replay=Instance.new("BindableEvent");replay.Name="ReplayKingdomIntro";replay.Parent=p:WaitForChild("PlayerGui")
local function play()
 if running or Camera.Current() then return end
 local char=p.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
 if not root or not workspace.CurrentCamera then return end
 running=true;p:SetAttribute("KingdomIntroPlaying",true)
 local gui=Instance.new("ScreenGui");gui.Name="KingdomIntro";gui.ResetOnSpawn=false;gui.DisplayOrder=200;gui.IgnoreGuiInset=true;gui.Parent=p.PlayerGui
 local function text(name,content,pos,size)
  local x=Instance.new("TextLabel");x.Name=name;x.Text=content;x.Position=pos;x.Size=size;x.BackgroundTransparency=1;x.TextColor3=Color3.fromRGB(255,242,206);x.TextStrokeTransparency=.5;x.Font=Enum.Font.GothamBold;x.TextScaled=true;x.Parent=gui
  return x
 end
 local title=text("Title","THE KINGDOM AWAKENS",UDim2.fromScale(.15,.77),UDim2.fromScale(.7,.07))
 local subtitle=text("Subtitle","A little wonder waits in every leaf.",UDim2.fromScale(.2,.85),UDim2.fromScale(.6,.045))
 for _,y in ipairs({0,.94})do local bar=Instance.new("Frame");bar.BackgroundColor3=Color3.new();bar.BorderSizePixel=0;bar.Position=UDim2.fromScale(0,y);bar.Size=UDim2.fromScale(1,.06);bar.Parent=gui end
 local skip=Instance.new("TextButton");skip.Name="Skip";skip.Text="Skip Intro  •  B";skip.Font=Enum.Font.GothamBold;skip.TextSize=18;skip.TextColor3=Color3.fromRGB(255,242,206);skip.BackgroundColor3=Color3.fromRGB(25,58,44);skip.Size=UDim2.fromOffset(180,44);skip.AnchorPoint=Vector2.new(1,0);skip.Position=UDim2.new(1,-20,0,24);skip.Selectable=true;skip.Parent=gui
 local hud=p.PlayerGui:FindFirstChild("AnimalKingdomUI");local wasEnabled=hud and hud.Enabled
 if hud then hud.Enabled=false end
 local controls;pcall(function()controls=require(p.PlayerScripts:WaitForChild("PlayerModule",5)):GetControls();controls:Disable()end)
 CAS:BindActionAtPriority("KingdomIntroBlock",function()return Enum.ContextActionResult.Sink end,false,3000,unpack(Enum.PlayerActions:GetEnumItems()))
 local oldFov=workspace.CurrentCamera.FieldOfView
 local dof=Instance.new("DepthOfFieldEffect");dof.Name="IntroFocus";dof.FarIntensity=.12;dof.NearIntensity=0;dof.FocusDistance=70;dof.InFocusRadius=55;dof.Parent=Lighting
 local visual=Instance.new("Folder");visual.Name="KingdomIntroVisuals";visual.Parent=workspace
 local warmth=Instance.new("ColorCorrectionEffect");warmth.Name="IntroSunrise";warmth.TintColor=Color3.fromRGB(255,239,216);warmth.Brightness=.04;warmth.Parent=Lighting
 local fade=Instance.new("Frame");fade.Name="Transition";fade.Size=UDim2.fromScale(1,1);fade.BackgroundColor3=Color3.new();fade.BorderSizePixel=0;fade.ZIndex=5;fade.Parent=gui
 skip.ZIndex=6
 local done=false;local token;local connection
 local function cleanup(reason)
  if done then return end;done=true
  if connection then connection:Disconnect()end
  CAS:UnbindAction("KingdomIntroBlock");CAS:UnbindAction("KingdomIntroSkip")
  if controls then controls:Enable()end
  if hud and hud.Parent then hud.Enabled=wasEnabled end
  dof:Destroy();warmth:Destroy();visual:Destroy();gui:Destroy()
  if token then Camera.Release(token)end
  if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=oldFov end
  running=false;p:SetAttribute("KingdomIntroPlaying",false);p:SetAttribute("KingdomIntroResult",reason)
  local remote=RS:FindFirstChild("KingdomIntroComplete");if remote then remote:FireServer()end
 end
 local ok,err=xpcall(function()
  skip.Activated:Connect(function()cleanup("Skipped")end)
  CAS:BindActionAtPriority("KingdomIntroSkip",function(_,state)if state==Enum.UserInputState.Begin then cleanup("Skipped")end return Enum.ContextActionResult.Sink end,false,3100,Enum.KeyCode.ButtonB,Enum.KeyCode.Escape)
  local town=Vector3.new(-237,18,192);local meadow=Vector3.new(183,20,-88);local forest=Vector3.new(183,39,187)
  local tree=workspace:FindFirstChild("Forest") and workspace.Forest:FindFirstChild("SearchableTrees")
  tree=tree and tree:FindFirstChildWhichIsA("Model")
  local discovery=tree and tree:GetPivot().Position+Vector3.new(0,8,0)or forest
  if tree then local h=Instance.new("Highlight");h.Adornee=tree;h.FillColor=Color3.fromRGB(153,255,151);h.OutlineColor=Color3.fromRGB(255,224,118);h.FillTransparency=.88;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Parent=visual end
  local pet=RS:FindFirstChild("PetAssets")and RS.PetAssets:FindFirstChild("ForestTreeFrog")
  local petFocus=discovery+Vector3.new(0,1,17)
  local specimen
  if pet then specimen=pet:Clone();for _,x in specimen:GetDescendants()do if x:IsA("BasePart")then x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false elseif x:IsA("LuaSourceContainer")then x:Destroy()end end;specimen:ScaleTo(4);specimen:PivotTo(CFrame.new(petFocus));end
  local sanctuary=workspace:FindFirstChild("Sanctuaries");sanctuary=sanctuary and sanctuary:FindFirstChild(tostring(p.UserId))
  local home=sanctuary and sanctuary:IsA("Model")and sanctuary:GetPivot().Position or root.Position
  local shots={
   {5,town+Vector3.new(-65,70,80),town+Vector3.new(-35,45,45),town,"THE KINGDOM AWAKENS","A little wonder waits in every leaf."},
   {3.5,meadow+Vector3.new(-40,45,65),meadow+Vector3.new(-10,28,45),meadow,"THE LIVING KINGDOM","Follow the wind through the Meadow."},
   {3.5,forest+Vector3.new(-45,45,60),forest+Vector3.new(-15,30,40),forest,"THE LIVING KINGDOM","Discover the secrets of the Forest."},
   {8,discovery+Vector3.new(-18,10,45),discovery+Vector3.new(12,6,38),petFocus,"THE MAGIC OF DISCOVERY","Every search begins a new friendship."},
   {10,home+Vector3.new(-45,38,55),root.Position+Vector3.new(0,7,16),root.Position+Vector3.new(0,2,0),"ANIMAL KINGDOM","Your adventure begins."}
  }
  token=Camera.Acquire("KingdomIntro",function(c)if c then c.CameraType=Enum.CameraType.Scriptable;c.FieldOfView=60 end end,function()cleanup("Interrupted")end)
  local anchor=Instance.new("Part");anchor.Name="DiscoverySparkles";anchor.Size=Vector3.new(.1,.1,.1);anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Transparency=1;anchor.Position=petFocus;anchor.Parent=visual
  local spark=Instance.new("ParticleEmitter");spark.Texture="rbxasset://textures/particles/sparkles_main.dds";spark.Color=ColorSequence.new(Color3.fromRGB(154,255,172),Color3.fromRGB(255,219,113));spark.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.4),NumberSequenceKeypoint.new(1,0)});spark.Lifetime=NumberRange.new(1,2);spark.Speed=NumberRange.new(2,5);spark.SpreadAngle=Vector2.new(180,180);spark.LightEmission=.8;spark.Rate=0;spark.Parent=anchor
  local started=os.clock();local shown=false
  connection=Run.RenderStepped:Connect(function()
   local elapsed=os.clock()-started
   if elapsed>=30 then cleanup("Completed");return end
   local i=1;local t=elapsed
   while t>shots[i][1]and i<#shots do t-=shots[i][1];i+=1 end
   local s=shots[i];local a=math.clamp(t/s[1],0,1);a=a*a*(3-2*a)
   fade.BackgroundTransparency=math.clamp(math.min(t,s[1]-t)/.55,0,1)
   title.Text=s[5];subtitle.Text=s[6];p:SetAttribute("KingdomIntroScene",i)
   if specimen and i==4 then if not shown then shown=true;specimen.Parent=visual;spark:Emit(32) end;specimen:PivotTo(CFrame.new(petFocus+Vector3.new(0,math.sin(elapsed*2)*.25,0))*CFrame.Angles(0,elapsed*.45,0))end
   local c=workspace.CurrentCamera;if c then c.CFrame=CFrame.lookAt(s[2]:Lerp(s[3],a),s[4])end
  end)
  task.delay(32,function()cleanup("Completed")end)
 end,debug.traceback)
 if not ok then warn("[KingdomIntro] "..tostring(err));cleanup("Error")end
end
replay.Event:Connect(play)
task.spawn(function()
 local deadline=os.clock()+120
 repeat task.wait(.25)until (p:GetAttribute("IntroReady")==true and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and workspace.CurrentCamera)or os.clock()>deadline
 if p:GetAttribute("IntroReady")and(Run:IsStudio()or p:GetAttribute("IntroCompleted")~=true)then task.wait(2);play()end
end)
