-- Only the nearest physical slot on this player's display offers an action.
-- The existing request remote still validates the exact pets and distance on the server.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Collection=game:GetService('CollectionService')
local Run=game:GetService('RunService')
local Knit=require(RS.Packages.Knit)
local Locations=require(RS.Shared.Gameplay.PetLocations)
local player=Players.LocalPlayer
local screen=player.PlayerGui:WaitForChild('AnimalKingdomUI')
local Bridge=require(screen.RemoteBridge)
local prompts,connections={},{}
local data
local function add(prompt)
 if not prompt:IsA('ProximityPrompt') or prompts[prompt] then return end
 prompt.Enabled=false
 prompts[prompt]=prompt.Triggered:Connect(function()
  if not data or prompt:GetAttribute('OwnerUserId')~=player.UserId then return end
  local held=Locations.Find(data,data.ActiveHeldPetUID)
  if held and held.Location~='Held' then held=nil end
  local slotId=prompt:GetAttribute('SlotId')
  local displayed=Locations.At(data,'Sanctuary',slotId)
  Bridge.Request('SwapSanctuary',{HeldSlot=held and held.LocationSlot or 0,SanctuarySlot=slotId,HeldUID=held and held.UID or '',SanctuaryUID=displayed and displayed.UID or ''})
 end)
end
local function remove(prompt)
 local c=prompts[prompt];if c then c:Disconnect();prompts[prompt]=nil end
end
connections[#connections+1]=Collection:GetInstanceAddedSignal('SanctuaryPetSlotPrompt'):Connect(add)
connections[#connections+1]=Collection:GetInstanceRemovedSignal('SanctuaryPetSlotPrompt'):Connect(remove)
for _,prompt in ipairs(Collection:GetTagged('SanctuaryPetSlotPrompt'))do add(prompt)end
Knit.OnStart():andThen(function()
 local controller=Knit.GetController('DataController');data=controller:GetPlayerData()
 connections[#connections+1]=controller.Changed:Connect(function(_,snapshot)data=snapshot end)
end)
local elapsed=0
connections[#connections+1]=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 local current=player.PlayerGui:FindFirstChild('AnimalKingdomUI')
 if current and current~=screen and current:FindFirstChild('RemoteBridge')then screen=current;Bridge=require(screen.RemoteBridge)end
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local held=data and Locations.Find(data,data.ActiveHeldPetUID)
 local allowed=root and data and screen.Parent and screen:GetAttribute('ActiveMenu')==''
  and not screen:GetAttribute('RewardRevealActive') and not screen:GetAttribute('ModalActive')
 local nearest,distance=nil,9
 if allowed then
  for prompt in pairs(prompts)do
   local anchor=prompt.Parent
   if anchor and anchor:IsA('BasePart') and prompt:GetAttribute('OwnerUserId')==player.UserId then
    local d=(root.Position-anchor.Position).Magnitude
    if d<distance and (held or Locations.At(data,'Sanctuary',prompt:GetAttribute('SlotId'))) then nearest,distance=prompt,d end
   end
  end
 end
 for prompt in pairs(prompts)do
  prompt.Enabled=prompt==nearest
  if prompt==nearest then prompt.ActionText=Locations.At(data,'Sanctuary',prompt:GetAttribute('SlotId')) and (held and 'SWAP' or 'PICK UP') or 'PLACE' end
 end
end)
script.Destroying:Once(function()
 for _,c in ipairs(connections)do c:Disconnect()end
 for prompt in pairs(prompts)do remove(prompt)end
end)
