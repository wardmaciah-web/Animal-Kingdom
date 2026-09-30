-- Route selection and validation for the existing ChallengeService coordinator.
-- Targets are authored normal trees and serializable walking positions, not assets.
local RS=game.ReplicatedStorage
local Http=game.HttpService
local Pathfinding=game:GetService('PathfindingService')
local Knit=require(RS.Packages.Knit)
local C=require(RS.Shared.Gameplay.Definitions.KingdomActivityDefinitions)
local Families=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions)
local Biomes=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Rarities=require(RS.Shared.Gameplay.Definitions.RarityDefinitions)
local Eggs=require(RS.Shared.Gameplay.Definitions.EggDefinitions)
local Weight=require(RS.Shared.Gameplay.PetWeight)
local Guard=require(script.Parent.GameplayGuard)
local M={};M.__index=M
local function service(id)return Knit.GetService(id)end
local function now()return workspace:GetServerTimeNow()end
local function vector(t)return Vector3.new(t[1],t[2],t[3])end
local function serialized(v)return {v.X,v.Y,v.Z}end
function M.new(owner)return setmetatable({Owner=owner,OfferAt=setmetatable({},{__mode='k'}),Accepting=setmetatable({},{__mode='k'}),Retargeting=setmetatable({},{__mode='k'})},M)end
function M:Candidates(biome,family,used)
 local list={}
 for tree,r in pairs(service('ResourceService'):GetRecords())do
  local id=tree:GetAttribute('RewardPoolId');local def=Families[id];local treeId=tree:GetAttribute('ActivityTreeId')
  if r.IsTree and r.Biome==biome and tree:IsDescendantOf(workspace)and def and treeId and (not family or family==id)and (not used or not used[treeId])then
   table.insert(list,{Tree=tree,Record=r,Family=def,Id=treeId})
  end
 end
 table.sort(list,function(a,b)return a.Id<b.Id end)
 return list
end
function M:WalkingPoint(candidate,from,player)
 local center=candidate.Record.InteractionPosition;local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={candidate.Tree,player.Character};params.RespectCanCollide=true
 local delta=from-center;delta=Vector3.new(delta.X,0,delta.Z);if delta.Magnitude<.1 then delta=Vector3.xAxis end
 for i=0,7 do
  local direction=CFrame.Angles(0,i*math.pi/4,0):VectorToWorldSpace(delta.Unit)
  local point=center+direction*8
  local hit=workspace:Raycast(point+Vector3.new(0,5,0),Vector3.new(0,-18,0),params)
  if hit and hit.Normal.Y>.8 then
   local destination=hit.Position+Vector3.new(0,2.8,0)
   if service('BiomeService'):AtPosition(destination)==candidate.Record.Biome then
    local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=8})
    local ok=pcall(path.ComputeAsync,path,from,destination)
    if ok and path.Status==Enum.PathStatus.Success then
     local length=0;local previous=from
     for _,wp in ipairs(path:GetWaypoints())do length+=(wp.Position-previous).Magnitude;previous=wp.Position end
     return hit.Position+Vector3.new(0,.15,0),length
    end
   end
  end
 end
end
-- Paw markers use open visible ground, not the normal search interaction offset.
-- Entire tree footprints are kept clear, including canopies on single-mesh trees.
local function outsideFootprint(point,cf,size,clearance)
 local localPoint=cf:PointToObjectSpace(Vector3.new(point.X,cf.Position.Y,point.Z))
 local dx=math.max(0,math.abs(localPoint.X)-size.X*.5)
 local dz=math.max(0,math.abs(localPoint.Z)-size.Z*.5)
 return math.sqrt(dx*dx+dz*dz)>=clearance
end
function M:PawClear(point,biome,player,candidates)
 local character=player.Character
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances=character and {character}or {};ray.RespectCanCollide=true
 local hit=workspace:Raycast(point+Vector3.new(0,7,0),Vector3.new(0,-16,0),ray)
 if not hit or hit.Normal.Y<.92 or hit.Material==Enum.Material.Water then return end
 local area=workspace:FindFirstChild(biome);local floor=area and area:FindFirstChild(biome..'Floor')
 if hit.Instance~=workspace.Terrain and hit.Instance~=floor then return end -- never a prop top or unnamed imported mesh
 local ground=hit.Position
 if service('BiomeService'):AtPosition(ground+Vector3.new(0,2.8,0))~=biome then return end
 -- Paw trails may not silently move into player plots, buildings or foliage.
 local name=hit.Instance:GetFullName():lower()
 for _,word in ipairs({'roof','cabin','building','rock','bush','playerplots','sanctuar','garden','water'})do if name:find(word,1,true)then return end end
 for _,candidate in ipairs(candidates or self:Candidates(biome))do
  local tree=candidate.Tree
  if tree:IsDescendantOf(workspace)then
   local cf,size;if tree:IsA('Model')then cf,size=tree:GetBoundingBox()else cf,size=tree.CFrame,tree.Size end
   if not outsideFootprint(ground,cf,size,5)then return end
  end
 end
 local query=OverlapParams.new();query.FilterType=Enum.RaycastFilterType.Exclude;query.FilterDescendantsInstances={hit.Instance,character};query.MaxParts=80
 for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(ground+Vector3.new(0,3.1,0)),Vector3.new(6,5.8,6),query))do
  if part.Transparency<.95 or part.CanCollide then return end
 end
 -- Reject a low visible prop/canopy overhead even when it has no collision.
 ray.RespectCanCollide=false
 local overhead=workspace:Raycast(ground+Vector3.new(0,.3,0),Vector3.new(0,14,0),ray)
 if overhead and overhead.Instance.Transparency<.95 then return end
 return ground+Vector3.new(0,.10,0)
end
function M:PawPoint(candidate,from,player,candidates,pawPoints)
 local cf,size;if candidate.Tree:IsA('Model')then cf,size=candidate.Tree:GetBoundingBox()else cf,size=candidate.Tree.CFrame,candidate.Tree.Size end
 local center=Vector3.new(cf.Position.X,candidate.Record.InteractionPosition.Y,cf.Position.Z)
 local direction=Vector3.new(from.X-center.X,0,from.Z-center.Z);direction=direction.Magnitude>.1 and direction.Unit or Vector3.xAxis
 local radius=math.sqrt(size.X*size.X+size.Z*size.Z)*.5+6
 for ring=0,2 do for i=0,15 do
  local offset=CFrame.Angles(0,i*math.pi/8,0):VectorToWorldSpace(direction)*(radius+ring*7)
  local point=self:PawClear(center+offset,candidate.Record.Biome,player,candidates)
  local separated=point and (Vector3.new(point.X,0,point.Z)-Vector3.new(from.X,0,from.Z)).Magnitude>=14
  if separated then for _,previous in ipairs(pawPoints or {})do if (point-previous).Magnitude<16 then separated=false;break end end end
  if point and separated then
   local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=8})
   local ok=pcall(path.ComputeAsync,path,from,point+Vector3.new(0,2.8,0))
   if ok and path.Status==Enum.PathStatus.Success then
    local length=0;local previous=from;for _,wp in ipairs(path:GetWaypoints())do length+=(wp.Position-previous).Magnitude;previous=wp.Position end
    return point,length
   end
  end
 end end
end
function M:Choose(player,biome,family,used,from,paw,pawPoints)
 local candidates=self:Candidates(biome,family,used)
 table.sort(candidates,function(a,b)return (a.Record.InteractionPosition-from).Magnitude<(b.Record.InteractionPosition-from).Magnitude end)
 for _,candidate in ipairs(candidates)do if candidate.Record.State=='AVAILABLE'then
  local pos,length
  if paw then pos,length=self:PawPoint(candidate,from,player,self:Candidates(biome),pawPoints)else pos,length=self:WalkingPoint(candidate,from,player)end
  if pos then return {TreeId=candidate.Id,FamilyId=candidate.Family.Id,Name=candidate.Family.DisplayName,Position=serialized(pos)},length end
 end end
 return nil
end
function M:Offer(player,id,biome)
 local d=service('PlayerDataService'):Get(player);local families=Families.ByBiome[biome]
 if not d or not families or not Biomes.IsContentReady(biome)or not d.UnlockedBiomes[biome]then return end
 local base=families[1].Cost;local a=d.Activities;local isPaw=id=='Paw'or id=='PawFinale';local variant=id:match('^Rush:(.+)$')
 local def=variant and C.Rush[variant];local offer={Id=id,Biome=biome,CostBudget=0,Eligible=true}
 if isPaw then
  offer.Name=id=='Paw'and 'Hidden Pawprint Hunt'or 'Pawprint Tree Finale';offer.Seconds=C.Paw.Seconds
  offer.Description='Discover six pawprints in order.';offer.Rewards={Coins=C.Paw.Coins[biome],FriendshipTokens=1}
  if id=='PawFinale'then
   offer.CostBudget=base;offer.Description..=' Then search '..families[1].DisplayName..' at its normal price. That one successful search gets +10% higher weight-band weighting per band step.'
  end
  if (a.PawReadyAt or 0)>now()then offer.Eligible=false;offer.Reason='Another trail is available in '..math.ceil(a.PawReadyAt-now())..'s.'end
 elseif id=='Adventure'then
  offer.Name=biome..' Adventure';offer.Seconds=C.Adventure.Seconds;offer.CostBudget=base*4
  offer.Description='Search '..families[1].DisplayName..', then find a 1.25× base-weight pet, then place a '..biome..' pet in Sanctuary. Weight finds depend on chance.'
  offer.Rewards={Coins=C.Adventure.Coins[biome],FriendshipTokens=C.Adventure.Tokens}
  if a.CompletedAdventures[biome]==d.DailyChallenges.PeriodStart then offer.Eligible=false;offer.Reason='Completed for this daily period.'
  elseif (d.SanctuaryCapacity or 0)<1 then offer.Eligible=false;offer.Reason='Your Sanctuary needs a usable display slot first.'end
 elseif def then
  offer.Name=def.Name;offer.Seconds=def.Seconds;offer.Variant=variant
  if variant=='Tour'or variant=='NoRepeat'or variant=='Species'then
   local n=variant=='Tour'and 5 or variant=='NoRepeat'and 4 or 3
   local names={};for i=1,n do offer.CostBudget+=families[i].Cost;table.insert(names,families[i].DisplayName)end
   offer.Description=(variant=='Tour'and 'Search in this order: 'or variant=='Species'and 'Find three distinct species; follow these dedicated sources: 'or 'Search four different families: ')..table.concat(names,' → ')
  else
   offer.CostBudget=base*def.BudgetSearches
   offer.Description=variant=='Speed'and ('Search five different '..families[1].DisplayName..' trees.')or variant=='Heavy'and ('Find a pet at least '..def.Ratio..'× its base weight.')or 'Find a Rare or better pet.'
   if variant=='Rarity'then
    local supported=false;for _,pid in ipairs(families[1].PetIds)do if Rarities[Pets[pid].Rarity].Order>=def.Rarity then supported=true end end
    if not supported then return end
   end
   if variant=='Heavy'then
    local supported=false;for _,pid in ipairs(families[1].PetIds)do if Weight.Maximum(Pets[pid])>=def.Ratio then supported=true end end
    if not supported then return end
   end
  end
  if def.Random and variant~='Species'then offer.Description..=' Optional chance challenge; success is not guaranteed. Budget shown covers '..def.BudgetSearches..' searches, not a guarantee.'end
  offer.Rewards={Coins=math.min(750,math.floor(offer.CostBudget*.10)),FriendshipTokens=2}
 else return end
 if not d.TutorialCompleted then offer.Eligible=false;offer.Reason='Finish your tutorial first.'
 elseif d.Currencies.Coins<offer.CostBudget then offer.Eligible=false;offer.Reason='Build a '..tostring(offer.CostBudget)..'-coin search budget, or choose the free Paw Hunt.'
 elseif (not isPaw or id=='PawFinale')and not service('PetService'):HasSpace(player,variant=='Speed'and 5 or variant=='Tour'and 5 or variant=='NoRepeat'and 4 or variant=='Species'and 3 or 1)then offer.Eligible=false;offer.Reason='Make room for the route’s normal pet rewards.'end
 if offer.Eligible and player:GetAttribute('CurrentBiome')~=biome then offer.Description..=' Travel to '..biome..' to begin.'end
 return offer
end
function M:Offers(player)
 local list={}
 for _,biome in ipairs({'Meadow','Forest'})do
  for _,id in ipairs({'Paw','PawFinale','Adventure'})do local offer=self:Offer(player,id,biome);if offer and (id~='PawFinale'or math.floor(now()/C.Schedule.PublicInterval)%3==0)then table.insert(list,offer)end end
  for _,variant in ipairs(C.RushOrder)do local offer=self:Offer(player,'Rush:'..variant,biome);if offer then table.insert(list,offer)end end
 end
 return list
end
function M:Accept(player,id,biome)
 if self.Accepting[player]then return false,'A route is already being checked.'end
 local d,a=self.Owner:Ensure(player);if not d then return false,'Profile is loading.'end
 if a.Route then return false,'Finish or abandon your current guided activity first.'end
 local offer=self:Offer(player,id,biome)
 if not offer or not offer.Eligible then return false,offer and offer.Reason or 'Activity unavailable.'end
 local root=Guard.Alive(player)
 if not root or service('BiomeService'):AtPosition(root.Position)~=biome then return false,'Travel to '..biome..' through Biomes, then accept this route.'end
 self.Accepting[player]=true
 local ok,routeOrError=xpcall(function()
  local route={Id=Http:GenerateGUID(false),Template=id,Name=offer.Name,Biome=biome,Progress=0,Target=1,Targets={},SeenTrees={},SeenSpecies={},SeenFamilies={},Rewards=offer.Rewards,CostBudget=offer.CostBudget,Summary=offer.Description,Step=1}
  local variant=offer.Variant;local families=Families.ByBiome[biome];local from=root.Position;local used={};local distance=0;local pawPoints={}
  local n=1
  if id=='Paw'or id=='PawFinale'then n=6;route.Kind='Paw';route.Target=id=='PawFinale'and 7 or 6
  elseif id=='Adventure'then route.Kind='Adventure';route.Target=3
  else route.Kind='Rush';route.Variant=variant;route.Target=C.Rush[variant].Target;n=(variant=='Speed'or variant=='Tour')and 5 or variant=='NoRepeat'and 4 or variant=='Species'and 3 or 1 end
  for i=1,n do
   local family
   if route.Kind~='Paw'then family=(variant=='Tour'or variant=='NoRepeat'or variant=='Species')and families[i].Id or families[1].Id end
   local target,length=self:Choose(player,biome,family,used,from,route.Kind=='Paw',pawPoints)
   if not target then error('No reachable ready '..(family and Families[family].DisplayName or biome)..' tree. Try again when nearby trees return.',0)end
   used[target.TreeId]=true;table.insert(route.Targets,target);if route.Kind=='Paw'then table.insert(pawPoints,vector(target.Position))end;from=vector(target.Position)+Vector3.new(0,2.8,0);distance+=length
  end
  if id=='PawFinale'then
   local target=self:Choose(player,biome,families[1].Id,{},from)
   if not target then error('The finale tree is temporarily unavailable.',0)end;table.insert(route.Targets,target)
  end
  -- Leave generous time for five actual reveals, prompts and ordinary walking.
  local minimum=distance/12+(route.Kind=='Paw'and 30 or n*8)+20
  if minimum>offer.Seconds then error('This reachable route is too long for its timer. Move closer to the trees and try again.',0)end
  route.AcceptedAt=now();route.EndsAt=now()+offer.Seconds;route.Distance=distance
  return route
 end,debug.traceback)
 self.Accepting[player]=nil
 if not ok then return false,tostring(routeOrError):match('^[^\n]+')end
 -- Pathfinding yields. Revalidate live profile, budget and route before accepting.
 return service('PetService'):Transaction(player,function()
  local current,activity=self.Owner:Ensure(player);local refreshed=self:Offer(player,id,biome)
  if current~=d or activity.Route or not refreshed or not refreshed.Eligible then return false,'Your state changed while checking the route. Please try again.'end
  activity.Route=routeOrError
  if routeOrError.Kind=='Paw'then activity.PawReadyAt=now()+C.Paw.Cooldown end
  self.Owner:Publish(player);return true,'Activity accepted. Follow the current target.'
 end)
end
function M:Discover(player,id,index)
 return service('PetService'):Transaction(player,function()
  local d,a=self.Owner:Ensure(player);local r=a and a.Route;local root=Guard.Alive(player)
  if not r or r.Id~=id or r.Kind~='Paw'or r.Completed or index~=r.Progress+1 or index>6 or r.EndsAt<=now()then return false,'That pawprint is not your current trail target.'end
  if not d.TutorialCompleted or not service('BiomeService'):IsUnlocked(player,r.Biome)then return false,'Trail unavailable.'end
  local target=r.Targets[index]
  if not root or not target or (root.Position-vector(target.Position)).Magnitude>9 then return false,'Walk closer to your next pawprint.'end
  r.Progress+=1
  if r.Progress==6 and r.Template=='PawFinale'then
   a.Finale={RunId=r.Id,FamilyId=r.Targets[7].FamilyId,ExpiresAt=r.EndsAt}
   r.Summary='Trail complete. Search '..r.Targets[7].Name..' at its normal price for the finale; the one-use weight benefit is consumed only on success.'
  elseif r.Progress==r.Target then r.Completed=true end
  self.Owner:Publish(player);return true,r.Completed and 'Trail complete! Claim your reward in Activities.'or 'Pawprint found. Follow the next direction.'
 end)
end
function M:Committed(player,d,a,event,detail)
 local r=a.Route;if not r or r.Completed or r.EndsAt<=now()then return end
 if r.Kind=='Paw'then
  if r.Progress==6 and r.Template=='PawFinale'and event=='Search'and detail.FamilyId==r.Targets[7].FamilyId and detail.OneUseRunId==r.Id then r.Progress=7;r.Completed=true end
 elseif r.Kind=='Adventure'then
  if r.Step==1 and event=='Search'and detail.FamilyId==r.Targets[1].FamilyId then r.Step=2;r.Progress=1
  elseif r.Step==2 and event=='Search'and detail.Biome==r.Biome and detail.Ratio>=C.Adventure.Ratio then r.Step=3;r.Progress=2
  elseif r.Step==3 and event=='Place'and detail.Biome==r.Biome then r.Progress=3;r.Completed=true;a.CompletedAdventures[r.Biome]=d.DailyChallenges.PeriodStart end
 elseif event=='Search'and detail.Biome==r.Biome then
  local v=r.Variant;local target=r.Targets[math.min(r.Progress+1,#r.Targets)]
  if v=='Heavy'then if detail.Ratio>=C.Rush.Heavy.Ratio then r.Progress=1 end
  elseif v=='Rarity'then if detail.Rarity>=C.Rush.Rarity.Rarity then r.Progress=1 end
  elseif v=='Species'then if not r.SeenSpecies[detail.PetId]then r.SeenSpecies[detail.PetId]=true;r.Progress+=1 end
  elseif v=='NoRepeat'then if not r.SeenFamilies[detail.FamilyId]then r.SeenFamilies[detail.FamilyId]=true;r.Progress+=1 end
  elseif v=='Tour'then if target and detail.FamilyId==target.FamilyId then r.Progress+=1 end
  elseif v=='Speed'then if target and detail.TreeId==target.TreeId and not r.SeenTrees[detail.TreeId]then r.SeenTrees[detail.TreeId]=true;r.Progress+=1 end end
  if r.Progress>=r.Target then r.Completed=true end
 end
 if r.Completed then r.Summary='Completed! Ordinary search pets are already yours. Claim the activity reward in Activities.'end
end
function M:Tick(player,d,a)
 local t=now()
 if t-(self.OfferAt[player]or 0)>=10 then
  self.OfferAt[player]=t;player:SetAttribute('ActivityOffers',Http:JSONEncode(self:Offers(player)))
 end
 local r=a.Route
 if not r or r.Completed then return end
 if r.Kind=='Paw'and r.Progress<6 then
  local index=r.Progress+1;local target=r.Targets[index]
  if target and not self.Retargeting[player]and not self:PawClear(vector(target.Position),r.Biome,player)then
   self.Retargeting[player]=true
   task.spawn(function()
    local root=Guard.Alive(player);local replacement=root and self:Choose(player,r.Biome,nil,{},root.Position,true)
    self.Retargeting[player]=nil
    if a.Route==r and r.Progress+1==index then
     if replacement then target.Position=replacement.Position;r.Waiting=nil else r.Waiting='Finding open ground for the next pawprint. Your progress is kept.'end
     self.Owner:Publish(player)
    end
   end)
  end
  return
 end
 if r.Kind=='Adventure'and r.Step==3 then return end
 local index=r.Kind=='Adventure'and 1 or math.min(r.Progress+1,#r.Targets);local target=r.Targets[index]
 if not target then return end
 local found
 for _,candidate in ipairs(self:Candidates(r.Biome,target.FamilyId))do
  local ownAccepted=candidate.Record.State=='SHAKING'and candidate.Record.Player==player
  if candidate.Id==target.TreeId and (candidate.Record.State=='AVAILABLE'or ownAccepted)and not r.SeenTrees[candidate.Id]then found=true;break end
 end
 if found then if r.Waiting then r.Waiting=nil;self.Owner:Publish(player)end;return end
 -- Cheap equivalent retarget: only authored records in the same family, preserve
 -- route progress. Acceptance already verified the walking neighborhood. Never
 -- point at a destroyed Instance or replay a searched copy for Speed Search.
 local replacement
 for _,candidate in ipairs(self:Candidates(r.Biome,target.FamilyId,r.SeenTrees))do if candidate.Record.State=='AVAILABLE'then replacement=candidate;break end end
 if replacement and not self.Retargeting[player]then
  self.Retargeting[player]=true
  task.spawn(function()
   local root=Guard.Alive(player);local pos=root and self:WalkingPoint(replacement,root.Position,player)
   if a.Route==r then
    self.Retargeting[player]=nil
    if pos then target.TreeId=replacement.Id;target.Position=serialized(pos);r.Waiting=nil else r.Waiting='Waiting for a reachable copy of '..target.Name..'. Progress is kept.'end
    self.Owner:Publish(player)
   else self.Retargeting[player]=nil end
  end)
 elseif not replacement and not r.Waiting then r.Waiting='Waiting for '..target.Name..' to return. Progress is kept.';self.Owner:Publish(player)end
end
return M
