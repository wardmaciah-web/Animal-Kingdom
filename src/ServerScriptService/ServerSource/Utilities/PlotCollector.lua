-- Presentation/physical entry for PlotService's existing accumulator collection.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Locator=require(game:GetService('ServerScriptService').PlotLocator)
local Format=require(RS.Shared.Gameplay.PetNumberFormat)
local CurrencyDefs=require(RS.Shared.Gameplay.Definitions.CurrencyDefinitions)
local Sounds=require(RS.Shared.Gameplay.PresentationSounds)
local Tween=game:GetService('TweenService')
local M={}
function M.Start(service,dataService)
 local collectors={}
 local function refresh(plot,entry)
  local owner=Players:GetPlayerByUserId(plot:GetAttribute('OwnerUserId') or 0)
  local data=owner and dataService:Get(owner)
  local stored=data and math.floor(data.UncollectedSanctuaryCoins or 0) or 0
  local room=data and math.max(0,CurrencyDefs.Coins.MaxBalance-data.Currencies.Coins) or 0
  local amount=math.min(stored,room)
  entry.Pad:SetAttribute('CollectibleCoins',amount)
  entry.Pad:SetAttribute('OwnerUserId',owner and owner.UserId or 0)
  entry.Label.Text=(amount>=1 and 'READY' or 'EMPTY')..' • '..Format.Number(amount)..' Forest Coins'
  if stored>=1 and room<1 then entry.Label.Text..='\nCoin capacity reached' end
  entry.Pad.Color=amount>=1 and Color3.fromRGB(96,137,69) or Color3.fromRGB(116,86,54)
 end
 local function bind(plot)
  if collectors[plot] then return end
  local cf,size=Locator.getBounds(plot);if not cf then return end
  local pad=plot:FindFirstChild('IncomeCollector')
  if pad then return end -- Never overwrite an authored object of uncertain provenance.
  pad=Instance.new('Part');pad.Name='IncomeCollector';pad.Size=Vector3.new(10,.35,7)
  pad.CFrame=cf*CFrame.new(0,size.Y/2+.175,-size.Z*.30)
  pad.Anchored=true;pad.CanCollide=false;pad.CanTouch=true;pad.Material=Enum.Material.Wood;pad.Parent=plot
  local gui=Instance.new('BillboardGui');gui.Name='IncomeStatus';gui.Size=UDim2.fromOffset(260,58);gui.StudsOffsetWorldSpace=Vector3.new(0,3,0);gui.MaxDistance=70;gui.Parent=pad
  local label=Instance.new('TextLabel');label.Name='Balance';label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(243,225,182);label.TextColor3=Color3.fromRGB(72,48,30);label.Font=Enum.Font.GothamBold;label.TextSize=15;label.TextWrapped=true;label.Parent=gui
  local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,10);corner.Parent=label
  local stroke=Instance.new('UIStroke');stroke.Color=Color3.fromRGB(112,76,41);stroke.Thickness=3;stroke.Parent=label
  local feedback=Instance.new('TextLabel');feedback.Name='Collected';feedback.Size=UDim2.new(1,0,0,28);feedback.Position=UDim2.fromScale(0,-.5);feedback.BackgroundTransparency=1;feedback.TextColor3=Color3.fromRGB(255,218,104);feedback.Font=Enum.Font.GothamBold;feedback.TextSize=22;feedback.Text='';feedback.Parent=gui
  local entry={Pad=pad,Label=label,Feedback=feedback,Sequence=0};collectors[plot]=entry
  pad.Touched:Connect(function(hit)
   local character=hit:FindFirstAncestorOfClass('Model');local player=character and Players:GetPlayerFromCharacter(character)
   if not player then return end
   local ok,result=service:TouchCollector(player,plot,pad)
   if not ok then return end
   refresh(plot,entry);entry.Sequence+=1;local sequence=entry.Sequence
   feedback.Text='+'..Format.Number(result.Amount);feedback.TextTransparency=0
   Sounds.Play('UIClaim',pad)
   Tween:Create(feedback,TweenInfo.new(1.2),{TextTransparency=1}):Play()
   task.delay(1.3,function()if entry.Sequence==sequence then feedback.Text='' end end)
  end)
  plot:GetAttributeChangedSignal('OwnerUserId'):Connect(function()refresh(plot,entry)end)
  refresh(plot,entry)
 end
 local profiles=require(RS.Packages.Knit).GetService('ProfileService')
 profiles.UpdateSpecificData:Connect(function(player,path)
  local key=type(path)=='table' and path[1] or path
  if key=='UncollectedSanctuaryCoins' or key=='Currencies' then local plot=service:GetPlot(player);if collectors[plot] then refresh(plot,collectors[plot]) end end
 end)
 task.spawn(function()
  while true do
   for _,plot in ipairs(Locator.getPlots())do bind(plot);if collectors[plot] then refresh(plot,collectors[plot])end end
   task.wait(2)
  end
 end)
end
return M
