local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Knit=require(RS.Packages.Knit)
local Service=Knit.CreateService({Name="NotificationService",Client={}})
local pending=setmetatable({},{__mode="k"})
local worldQueue,worldSeen={},{}
local nextWorld=0;local categoryAt={}
function Service:Announce(id,message,priority,category)
 if type(id)~="string"or type(message)~="string"or #message>500 then return false end
 local time=workspace:GetServerTimeNow()
 if worldSeen[id]then return false end
 for _,item in ipairs(worldQueue)do if item.Id==id then
  if (priority or 20)>=item.Priority then item.Message=message;item.Priority=priority or 20 end
  return true
 end end
 table.insert(worldQueue,{Id=id,Message=message,Priority=priority or 20,Category=category or "World",ExpiresAt=time+120,At=time})
 table.sort(worldQueue,function(a,b)return a.Priority==b.Priority and a.At<b.At or a.Priority>b.Priority end)
 if #worldQueue>12 then table.remove(worldQueue)end
 return true
end
function Service:Send(player,message,kind)
 local folder=RS:FindFirstChild("AnimalKingdomRemotes");local remote=folder and folder:FindFirstChild("GameplayNotice")
 if remote and player.Parent==Players then remote:FireClient(player,{Message=message,Kind=kind or "Info"}) end
end
function Service:KnitStart()
 task.spawn(function()while true do
  task.wait(.5);local time=workspace:GetServerTimeNow()
  for id,at in pairs(worldSeen)do if time-at>900 then worldSeen[id]=nil end end
  for i=#worldQueue,1,-1 do if worldQueue[i].ExpiresAt<=time then table.remove(worldQueue,i)end end
  if time>=nextWorld and #worldQueue>0 then
   local item=table.remove(worldQueue,1);local delay=({Achievement=20,Rate=90,Invitation=120,Cosmetic=240})[item.Category]or 5
   if time-(categoryAt[item.Category]or -math.huge)>=delay or item.Priority>=90 then
    local remote=RS:FindFirstChild('AnimalKingdomRemotes')and RS.AnimalKingdomRemotes:FindFirstChild('GlobalAnnouncement')
    if remote then remote:FireAllClients(item);worldSeen[item.Id]=time;categoryAt[item.Category]=time;nextWorld=time+8 end
   end
  end
 end end)
 Knit.GetService("EconomyService").Changed:Connect(function(player,currency,amount)
  if amount<=0 then return end
  local batch=pending[player]
  if not batch then
   batch={};pending[player]=batch
   task.delay(.4,function()
    if pending[player]~=batch then return end
    pending[player]=nil
    for id,total in pairs(batch) do self:Send(player,"+"..tostring(total).." "..(id=="FriendshipTokens" and "Friendship Tokens" or id),"Currency") end
   end)
  end
  batch[currency]=(batch[currency] or 0)+amount
 end)
 -- The existing personal reveal already labels discoveries. Do not toast the
 -- same acquisition over its reveal and the shared accomplishment announcement.
 Knit.GetService("ChallengeService").Completed:Connect(function(player,name) self:Send(player,"Challenge Complete! "..name,"Challenge") end)
end
return Service
