-- The ChallengeService coordinator's in-memory server activity state. No datastore.
local RS=game.ReplicatedStorage
local Players=game:GetService('Players')
local H=game.HttpService
local Knit=require(RS.Packages.Knit)
local C=require(RS.Shared.Gameplay.Definitions.KingdomActivityDefinitions)
local Families=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions)
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Rarities=require(RS.Shared.Gameplay.Definitions.RarityDefinitions)
local P=require(RS.Shared.Gameplay.KingdomProgress)
local F=require(RS.Shared.Gameplay.PetNumberFormat)
local M={};M.__index=M
local function service(id)return Knit.GetService(id)end
local function now()return workspace:GetServerTimeNow()end
function M.new(owner)
 local folder=RS:FindFirstChild('KingdomWorld')or Instance.new('Folder');folder.Name='KingdomWorld';folder.Parent=RS
 local self=setmetatable({Owner=owner,Folder=folder,Records={},PublicIndex=0,HotIndex=0,GoalIndex=0,MicroIndex=0,NextPublic=now()+C.Schedule.FirstInvitation,NextHot=now()+C.Schedule.FirstInvitation,NextMicro=now()+C.Schedule.MicroInterval,LastPublish=0,PendingDeliveries={}},M)
 game:BindToClose(function()
  local deadline=os.clock()+20
  repeat
   local pending=false
   for _,entry in pairs(self.PendingDeliveries)do if entry.State~='Delivered'then pending=true;self:SendDelivery(entry,true)end end
   if not pending then break end;task.wait(.25)
  until os.clock()>deadline
 end)
 return self
end
function M:Announce(id,message,priority,category)
 service('NotificationService'):Announce(id,message,priority,category)
end
function M:Eligible()
 local list={}
 for p,profile in pairs(service('ProfileService').Profiles)do if p.Parent==Players and p:GetAttribute('ProfileReady')and profile.Data.TutorialCompleted then table.insert(list,p)end end
 table.sort(list,function(a,b)return a.UserId<b.UserId end);return list
end
function M:SearchEffects(tree,familyId)
 local h=self.Hot;if not h or h.Tree~=tree or h.EndsAt<=now()then return {}end
 local def=C.Hot[h.Variant];local f=Families[familyId]
 return {HotId=h.Id,Luck=def.Luck,WeightBias=def.WeightBias,Cooldown=def.Cooldown,Mastery=def.Mastery,BonusCoins=def.CoinFraction and f and math.min(def.CoinCap,math.floor(f.Cost*def.CoinFraction))or 0}
end
function M:ClearHot()
 local h=self.Hot
 if h and h.Tree.Parent then
  for _,key in ipairs({'HotTreeId','HotTreeVariant','HotTreeEndsAt','HotTreeDescription'})do h.Tree:SetAttribute(key,nil)end
 end
 self.Hot=nil
end
function M:StartHot(variant,selected)
 self:ClearHot()
 local options={};local eligible=self:Eligible();local allowed={}
 for _,p in ipairs(eligible)do local d=service('PlayerDataService'):Get(p);for _,biome in ipairs({'Meadow','Forest'})do if d.UnlockedBiomes[biome]then allowed[biome]=true end end end
 for tree,r in pairs(service('ResourceService'):GetRecords())do if r.IsTree and r.State=='AVAILABLE'and allowed[r.Biome]and Families[tree:GetAttribute('RewardPoolId')]and tree:IsDescendantOf(workspace)then table.insert(options,tree)end end
 table.sort(options,function(a,b)return a:GetAttribute('ActivityTreeId')<b:GetAttribute('ActivityTreeId')end)
 local tree=selected or options[#options>0 and (self.HotIndex%#options+1)or 1]
 if not tree or not table.find(options,tree)then return false,'No eligible normal tree.'end
 if not C.Hot[variant]then return false,'Unknown Hot Tree modifier.'end
 self.Hot={Id=H:GenerateGUID(false),Variant=variant,Tree=tree,TreeId=tree:GetAttribute('ActivityTreeId'),FamilyId=tree:GetAttribute('RewardPoolId'),Biome=tree:GetAttribute('BiomeId'),EndsAt=now()+C.Schedule.HotSeconds}
 tree:SetAttribute('HotTreeId',self.Hot.Id);tree:SetAttribute('HotTreeVariant',variant);tree:SetAttribute('HotTreeEndsAt',self.Hot.EndsAt);tree:SetAttribute('HotTreeDescription',C.Hot[variant].Description)
 return true
end
function M:StartGoal(kind)
 local eligible=self:Eligible();if #eligible==0 then return end
 self.GoalIndex+=1;kind=kind or ({'Search','Collect','Rarity','Families','Garden','Heavy'})[(self.GoalIndex-1)%6+1]
 local n=math.clamp(#eligible,1,12);local goal={Id='Coop:'..H:GenerateGUID(false),Kind=kind,Progress=0,Contributors={},SeenFamilies={},EndsAt=now()+C.Schedule.CoopSeconds,ParticipantsAtStart=n,Rewards={Coins=200,FriendshipTokens=3}}
 local settings={Search={12*n,2,'Search normal trees'},Rarity={2*n,1,'Find Rare or better pets'},Heavy={2*n,1,'Find pets at least 1.35× base weight'},Collect={1000*n,100,'Collect Sanctuary Coins'},Garden={n,1,'Complete Garden expeditions'}}
 if kind=='Families'then
  local available={};for _,p in ipairs(eligible)do local d=service('PlayerDataService'):Get(p);for _,f in ipairs(Families.Ordered)do if d.UnlockedBiomes[f.Biome]and f.Cost then available[f.Id]=true end end end
  local total=0;for _ in pairs(available)do total+=1 end
  settings.Families={math.min(total,3+math.ceil(n/2)),1,'Search distinct named tree families together'}
 end
 local s=settings[kind];if not s then return end
 goal.Target=s[1];goal.Minimum=s[2];goal.Text=s[3];goal.MinimumText='Contribute at least '..s[2]..' to qualify • 200 Forest Coins + 3 Friendship Tokens each'
 self.Coop=goal
end
function M:Deliver(userId,g)
 local id=g.Id..':'..userId
 if self.PendingDeliveries[id]then return end
 local entry={UserId=userId,State='Pending',RetryAt=0,GoalEndsAt=g.EndsAt,Message={Kind='KingdomCoop',Id=id,GoalId=g.Id,Coins=g.Rewards.Coins,Tokens=g.Rewards.FriendshipTokens,CreatedAt=now(),ExpiresAt=now()+7*86400}}
 self.PendingDeliveries[id]=entry;self:SendDelivery(entry)
end
function M:SendDelivery(entry,closing)
 if entry.State=='Delivered'or entry.State=='Sending'or not closing and entry.RetryAt>now()then return end
 entry.State='Sending'
 task.spawn(function()
  -- ProfileStore's existing message inbox carries the exact receipt to another
  -- server or an offline profile. Never load or replace another active profile.
  local ok,result=pcall(service('ProfileService').QueueKingdomReward,service('ProfileService'),entry.UserId,entry.Message)
  if not ok or not result then
   entry.State='Pending';entry.RetryAt=now()+10
   warn('[KingdomGoal] Delivery pending '..entry.Message.Id)
  else entry.State='Delivered' end
 end)
end
function M:ProgressGoal(player,event,detail)
 local g=self.Coop;if not g or g.Completed or g.EndsAt<=now()then return end
 local amount=0;local userId=tostring(player.UserId);local c=g.Contributors[userId]or {Amount=0,Families={}}
 if g.Kind=='Search'and event=='Search'then amount=1
 elseif g.Kind=='Rarity'and event=='Search'and detail.Rarity>=3 then amount=1
 elseif g.Kind=='Heavy'and event=='Search'and detail.Ratio>=1.35 then amount=1
 elseif g.Kind=='Collect'and event=='Collect'then amount=detail.Amount
 elseif g.Kind=='Garden'and event=='Garden'then amount=1
 elseif g.Kind=='Families'and event=='Search'then
  if not c.Families[detail.FamilyId]then c.Families[detail.FamilyId]=true;c.Amount+=1 end
  if not g.SeenFamilies[detail.FamilyId]then g.SeenFamilies[detail.FamilyId]=true;amount=1 end
 end
 if amount<=0 and c.Amount==0 then return end
 if g.Kind~='Families'then c.Amount+=amount end
 g.Contributors[userId]=c;g.Progress=math.min(g.Target,g.Progress+amount)
 player:SetAttribute('KingdomGoalContribution',c.Amount)
 if g.Progress>=g.Target then
  g.Completed=true
  for uid,contribution in pairs(g.Contributors)do if contribution.Amount>=g.Minimum then self:Deliver(tonumber(uid),g)end end
  self:Announce(g.Id,'Kingdom Goal complete! Qualifying contributors each have a reward to claim in Activities.',80,'Coop')
 end
end
function M:Record(player,event,id,detail)
 if event~='Search'and event~='Acquisition'then return end
 local def=Pets[detail.PetId];if not def then return end
 local records=self.Records;local name=player.DisplayName;local source=Families[detail.FamilyId]
 local sourceName=source and source.DisplayName or detail.Source=='LuckyTree'and (detail.Biome..' Lucky Tree')or 'a companion reward'
 local message=name..' found a '..F.Weight(detail.Weight)..' '..def.Rarity..' '..def.DisplayName..' from '..sourceName..'!'
 local previous=records.Heaviest;local meaningfulWeight=false
 if not previous or detail.Weight>previous.Value then
  meaningfulWeight=detail.Weight>=25 and (not previous or detail.Weight>=previous.Value*1.20)
  records.Heaviest={Value=detail.Weight,Text=name..' • '..def.DisplayName..' • '..F.Weight(detail.Weight)}
 end
 local rarity=Rarities[def.Rarity].Order
 if not records.Rarest or rarity>records.Rarest.Value then records.Rarest={Value=rarity,Text=name..' • '..def.Rarity..' '..def.DisplayName..' • '..F.Weight(detail.Weight)}end
 local streak=service('ProgressionService'):GetStreak(player)
 local significantStreak=false
 if not records.Streak or streak>records.Streak.Value then
  significantStreak=streak>=10 and streak%10==0
  records.Streak={Value=streak,Text=name..' • '..streak..' successful searches'}
 end
 if rarity>=5 or meaningfulWeight or significantStreak then
  if meaningfulWeight then message..=' New server weight record.'end
  if significantStreak and rarity<5 and not meaningfulWeight then message=name..' reached a '..streak..'-search streak!'end
  self:Announce('Award:'..id,message,rarity==7 and 95 or rarity>=5 and 65 or 40,'Achievement')
 end
end
function M:Committed(player,d,a,event,id,detail)
 self:ProgressGoal(player,event,detail);self:Record(player,event,id,detail)
end
function M:Rates()
 local best
 for p,profile in pairs(service('ProfileService').Profiles)do if p.Parent==Players and p:GetAttribute('ProfileReady')then
  local d=profile.Data;local rate=service('SanctuaryService'):GetIncome(d)
  rate*=service('EventModifierService'):GetCoinMultiplier()
  if P.Active(d,'Blessing',now())then rate*=1.15 end
  if not best or rate>best.Value then best={UserId=p.UserId,Value=rate,Text=p.DisplayName..' • '..F.Income(rate)}end
 end end
 self.Records.CurrentIncome=best
 if best and best.Value>0 and (not self.Records.PeakIncome or best.Value>self.Records.PeakIncome.Value)then
  local old=self.Records.PeakIncome;self.Records.PeakIncome=table.clone(best)
  if best.Value>=100 and (not old or best.Value>=old.Value*1.25)then self:Announce('Rate:'..best.UserId..':'..math.floor(best.Value),best.Text..' — highest Sanctuary rate observed in this server.',35,'Rate')end
 end
end
function M:Tick()
 local t=now();local eligible=self:Eligible()
 -- Retry independently of the current goal, including after it has expired.
 for id,entry in pairs(self.PendingDeliveries)do
  if entry.State=='Delivered'and entry.GoalEndsAt<t or entry.Message.ExpiresAt<t then self.PendingDeliveries[id]=nil
  else self:SendDelivery(entry)end
 end
 if self.Hot and (self.Hot.EndsAt<=t or not self.Hot.Tree:IsDescendantOf(workspace))then self:ClearHot()end
 if #eligible>0 and t>=self.NextHot then self.HotIndex+=1;self:StartHot(C.HotOrder[(self.HotIndex-1)%#C.HotOrder+1]);self.NextHot=t+C.Schedule.HotInterval end
 if #eligible>0 and t>=self.NextPublic then
  self.PublicIndex+=1;local paw=self.PublicIndex%2==1
  self.Invitation={Id=H:GenerateGUID(false),Kind=paw and 'Paw'or 'Rush',Variant=not paw and C.RushOrder[(math.floor(self.PublicIndex/2)-1)%#C.RushOrder+1]or nil,EndsAt=t+C.Schedule.InvitationSeconds}
  self.NextPublic=t+C.Schedule.PublicInterval
  self:Announce('Invitation:'..self.Invitation.Id,paw and 'A free Pawprint Hunt is available in Activities.'or 'A Tree Rush challenge is available in Activities. Normal search costs apply.',10,'Invitation')
 end
 if self.Invitation and self.Invitation.EndsAt<=t then self.Invitation=nil end
 if not self.Coop or self.Coop.EndsAt<=t then self:StartGoal()end
 if self.Coop and self.Coop.Completed then for uid,c in pairs(self.Coop.Contributors)do if c.Amount>=self.Coop.Minimum then self:Deliver(tonumber(uid),self.Coop)end end end
 local weather=service('WeatherEventService'):GetCurrentState()
 local lucky=eligible[1]and service('LuckyTreeService'):GetState(eligible[1])
 if self.Micro and (self.Micro.EndsAt<=t or weather.Phase=='Event'or lucky and lucky.Active)then self.Micro=nil end
 if #eligible>0 and t>=self.NextMicro and not self.Micro and weather.Phase~='Event'and not(lucky and lucky.Active)then
  self.MicroIndex+=1;local def=C.Micro[(self.MicroIndex-1)%#C.Micro+1]
  self.Micro={Id=def.Id,Biome=def.Biome,EndsAt=t+def.Seconds};self.NextMicro=t+C.Schedule.MicroInterval
  self:Announce('Micro:'..t,def.Message,5,'Cosmetic')
 end
 if t-self.LastPublish>=3 then
  self.LastPublish=t;self:Rates()
  local hot=self.Hot and {Id=self.Hot.Id,Variant=self.Hot.Variant,TreeId=self.Hot.TreeId,FamilyId=self.Hot.FamilyId,Biome=self.Hot.Biome,EndsAt=self.Hot.EndsAt}
  local g=self.Coop;local coop=g and {Id=g.Id,Text=g.Text,Progress=g.Progress,Target=g.Target,EndsAt=g.EndsAt,Completed=g.Completed,MinimumText=g.MinimumText}
  self.Folder:SetAttribute('State',H:JSONEncode({Invitation=self.Invitation,Hot=hot,Coop=coop,Records=self.Records,Micro=self.Micro}))
 end
end
return M
