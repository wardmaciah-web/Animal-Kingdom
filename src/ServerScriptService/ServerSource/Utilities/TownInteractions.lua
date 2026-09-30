-- Technical anchors outside inspected existing Town landmarks. No art/collision
-- or building transforms are changed. Both entries open the existing menu route.
local RS=game.ReplicatedStorage
local Knit=require(RS.Packages.Knit)
local Guard=require(script.Parent.GameplayGuard)
local M={}
M.Entries={
 {Id='Shop',Landmark='AK_RUNTIME_GeneralStoreVisual',Position=Vector3.new(-289,11.5,254),Action='BROWSE SHOP',Name='Kingdom Shop',Route='Shop'},
 {Id='Activities',Landmark='Rewards_Visual',Position=Vector3.new(-200,11.5,245),Action='VIEW ACTIVITIES',Name='Activities • Rewards building',Route='Challenges'},
 {Id='Index',Landmark='MarketStand1_Visual',Position=Vector3.new(-219,11.5,139),Action='VIEW INDEX',Name='Collection stand',Route='Index'},
 {Id='Biomes',Landmark='TownWelcomeSign',Position=Vector3.new(-238,11.5,266),Action='VIEW BIOMES',Name='Town travel point',Route='Biomes'},
 {Id='Garden',Landmark='MarketStand2_Visual',Position=Vector3.new(-261,11.5,143),Action='VISIT GARDEN',Name='Garden stand',Route='Garden'},
}
function M.Get(id)
 local folder=workspace:FindFirstChild('KingdomTownInteractions');local anchor=folder and folder:FindFirstChild(id)
 return anchor and anchor:IsA('BasePart')and anchor
end
function M.Near(player,id,distance)
 local anchor=M.Get(id);local root=Guard.Alive(player)
 return anchor~=nil and root~=nil and (root.Position-anchor.Position).Magnitude<=distance
end
function M.Start()
 local folder=workspace:FindFirstChild('KingdomTownInteractions')or Instance.new('Folder');folder.Name='KingdomTownInteractions';folder.Parent=workspace
 local remotes=RS:WaitForChild('AnimalKingdomRemotes')
 local open=remotes:FindFirstChild('OpenKingdomRoute')or Instance.new('RemoteEvent');open.Name='OpenKingdomRoute';open.Parent=remotes
 for _,entry in ipairs(M.Entries)do
  local landmark=workspace:FindFirstChild(entry.Landmark)
  if not landmark then warn('[TownInteractions] Missing existing landmark '..entry.Landmark);continue end
  if M.Get(entry.Id)then continue end
  local anchor=Instance.new('Part');anchor.Name=entry.Id;anchor.Size=Vector3.one*.2;anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false;anchor.Position=entry.Position;anchor:SetAttribute('ExistingLandmark',landmark:GetFullName());anchor.Parent=folder
  local prompt=Instance.new('ProximityPrompt');prompt.Name='TownPrompt';prompt.ActionText=entry.Action;prompt.ObjectText=entry.Name;prompt.MaxActivationDistance=12;prompt.HoldDuration=.15;prompt.RequiresLineOfSight=false;prompt:SetAttribute('MenuRoute',entry.Route);prompt.Parent=anchor
  prompt.Triggered:Connect(function(player)
   if not Guard.RateLimit(player,'TownPrompt',.8)or not M.Near(player,entry.Id,14)then return end
   if entry.Route=='Garden'then
    local ok,result=Knit.GetService('GardenExpeditionService'):VisitGarden(player)
    remotes.GameplayFeedback:FireClient(player,{Action='VisitGarden',Success=ok==true,Result=result})
   else open:FireClient(player,entry.Route)end
  end)
 end
end
return M
