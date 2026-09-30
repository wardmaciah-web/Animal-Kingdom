-- Run as a temporary LocalScript in Studio Play. This tests layout calculations;
-- it does not emulate touch hardware, a notch, controller input, or a Lucky world tree.
assert(game:GetService('RunService'):IsStudio())
local player=game.Players.LocalPlayer
local real=player.PlayerGui:WaitForChild('AnimalKingdomUI')
local W=require(real.GameplayWidgets)
local copy=game.StarterGui.AnimalKingdomUI.LuckyTreePresentation:Clone();copy.Name='QA_LuckyModule';copy.Parent=real
local M=require(copy)
local outer=Instance.new('ScreenGui');outer.Name='AK_QA_Layout';outer.IgnoreGuiInset=false;outer.DisplayOrder=100;outer.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;outer.Parent=player.PlayerGui
local screen=W.New('Frame',{Name='Device',Size=UDim2.fromOffset(375,630),Position=UDim2.fromOffset(20,20),BackgroundTransparency=.15,BackgroundColor3=Color3.fromRGB(45,57,46)},outer)
screen:SetAttribute('ActiveMenu','')
local held=W.New('Frame',{Name='HeldPets',AnchorPoint=Vector2.new(.5,1),BackgroundColor3=W.Color.Wood},screen)
W.Text(held,'Held slots — protected region',UDim2.fromScale(1,1),nil,12,W.Color.White)
local gui=W.New('Frame',{Name='QAPrompt',Size=UDim2.fromOffset(252,88),Position=UDim2.fromScale(.5,.4),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=W.Color.Wood,Visible=true},screen)
local button=W.Button(gui,'E',UDim2.fromOffset(48,48),UDim2.fromOffset(12,16),function()end)
local action=W.Text(gui,'TRY YOUR LUCK',UDim2.new(1,-82,0,32),UDim2.fromOffset(72,37),12,W.Color.White)
local a=Instance.new('Attachment');a.Name='QA_PreviewFixture';a.Parent=player.Character.HumanoidRootPart
local prompt=Instance.new('ProximityPrompt');prompt.Name='QA_PreviewOnly';prompt.Style=Enum.ProximityPromptStyle.Custom;prompt.MaxActivationDistance=0;prompt:SetAttribute('LuckyBiome','Forest');prompt:SetAttribute('LuckyEventId','QA_LAYOUT');prompt.Parent=a
local cleanup
local function rect(o)return {X=o.AbsolutePosition.X-screen.AbsolutePosition.X,Y=o.AbsolutePosition.Y-screen.AbsolutePosition.Y,W=o.AbsoluteSize.X,H=o.AbsoluteSize.Y}end
local function overlaps(a,b)return a.X<b.X+b.W and a.X+a.W>b.X and a.Y<b.Y+b.H and a.Y+a.H>b.Y end
local result={layouts={},violations={}}
for _,device in ipairs({{320,532},{375,630},{667,339},{430,850},{768,980},{1366,732},{1920,1044}})do
 if cleanup then cleanup()end
 local x,y=unpack(device);screen.Size=UDim2.fromOffset(x,y)
 local compact=x<900 or y<580;local portrait=compact and x<500
 held.Size=UDim2.fromOffset(portrait and x-24 or compact and math.max(310,math.min(430,x-300)) or 540,compact and 86 or 96)
 held.Position=UDim2.new(.5,0,1,portrait and -150 or compact and -4 or -108)
 gui.Position=UDim2.fromScale(.5,.4);gui.Size=UDim2.fromOffset(252,88)
 task.wait(.1)
 cleanup=M.Attach(screen,prompt,gui,button,action,Enum.ProximityPromptInputType.Gamepad)
 task.wait(.25)
 local panel=screen.LuckyRewards;local pr,gr,hr=rect(panel),rect(gui),rect(held)
 local bad={}
 if overlaps(pr,gr)then table.insert(bad,'prompt overlap')end
 if overlaps(pr,hr) or overlaps(gr,hr)then table.insert(bad,'Held overlap')end
 if pr.X<0 or pr.Y<0 or pr.X+pr.W>x or pr.Y+pr.H>y then table.insert(bad,'offscreen')end
 if compact then
  for _,control in ipairs({{X=0,Y=y-150,W=180,H=150},{X=x-180,Y=y-150,W=180,H=150}})do
   if overlaps(pr,control) or overlaps(gr,control)then table.insert(bad,'touch control reserve overlap')end
  end
 end
 local texts={}
 for _,label in ipairs(panel:GetDescendants())do if label:IsA('TextLabel') and label.Visible and label.Text~='Loading companion…'then
  table.insert(texts,label.Text)
  if label.TextBounds.Y>label.AbsoluteSize.Y+1 or label.TextBounds.X>label.AbsoluteSize.X+1 then table.insert(bad,'text clipping: '..label.Text)end
 end end
 table.insert(result.layouts,{Width=x,Height=y,Panel=pr,Prompt=gr,Held=hr,Texts=texts,Issues=bad})
 for _,issue in ipairs(bad)do table.insert(result.violations,x..'×'..y..': '..issue)end
end
-- Desktop hover was exercised separately with actual mouse input. Focus here is a layout fixture.
script:SetAttribute('Result',game.HttpService:JSONEncode(result))
local finish=Instance.new('BindableEvent');finish.Name='Cleanup';finish.Parent=script
finish.Event:Connect(function()if cleanup then cleanup()end;copy:Destroy();a:Destroy();outer:Destroy();script:Destroy()end)
