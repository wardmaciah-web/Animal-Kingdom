local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Http=game:GetService('HttpService')
local W=require(script.Parent.GameplayWidgets)
local C=require(RS.Shared.Gameplay.Definitions.KingdomActivityDefinitions)
local Legacy=require(RS.Shared.Gameplay.Definitions.ChallengeDefinitions)
local P=require(RS.Shared.Gameplay.KingdomProgress)
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local M={Section='Play'}
local function decode(value)local ok,r=pcall(Http.JSONDecode,Http,value or '{}');return ok and r or {}end
local function reward(r)return W.Format(r.Coins or 0)..' Forest Coins'..((r.FriendshipTokens or 0)>0 and (' + '..r.FriendshipTokens..' Friendship Tokens')or '')end
local function card(ctx,id,title,body,button,action,disabled)
 local c=W.Card(ctx.Content,ctx.Narrow and 206 or 150);c.Name=id
 W.Heading(c,title,UDim2.new(ctx.Narrow and 1 or .70,-28,0,38),UDim2.fromOffset(14,10),17)
 W.Text(c,body,UDim2.new(ctx.Narrow and 1 or .70,-28,0,ctx.Narrow and 88 or 86),UDim2.fromOffset(14,50),12,W.Color.Muted)
 if button then
  local b=W.Button(c,button,ctx.Narrow and UDim2.new(1,-28,0,44)or UDim2.new(.30,-20,0,46),ctx.Narrow and UDim2.new(0,14,1,-54)or UDim2.new(.70,6,.5,-23),action)
  b.Name='Action_'..id;W.Disabled(b,disabled==true)
 end
 return c
end
local function heading(ctx,text)W.Heading(ctx.Content,text,UDim2.new(1,-8,0,30),nil,18)end
local function goalSet(ctx,set,title,coins,tokens)
 if not set then return end
 local lines={};local completed=0
 for _,g in ipairs(set.Entries)do if g.Progress>=g.Target then completed+=1 end;table.insert(lines,(g.Progress>=g.Target and '✓ 'or '')..g.Text..' • '..W.Format(g.Progress)..'/'..W.Format(g.Target))end
 table.insert(lines,reward({Coins=coins,FriendshipTokens=tokens}))
 card(ctx,set.Id,title..' • '..completed..'/'..#set.Entries,table.concat(lines,'\n'),set.Claimed and 'Claimed ✓'or completed==#set.Entries and 'Claim reward'or 'In progress',function()ctx.Request('ActivityClaim',{Id=set.Id})end,set.Claimed or completed<#set.Entries)
end
function M.Play(ctx)
 local a=ctx.Data.Activities or {};local r=a.Route
 if r then
  local remaining=math.max(0,math.ceil(r.EndsAt-workspace:GetServerTimeNow()))
  card(ctx,'ActiveRoute',r.Name,(r.Summary or '')..'\n'..(r.Progress or 0)..'/'..r.Target..' • '..math.floor(remaining/60)..':'..string.format('%02d',remaining%60)..' remaining\n'..reward(r.Rewards)..(r.Waiting and '\n'..r.Waiting or ''),r.Completed and 'Claim reward'or 'Abandon',function()
   if r.Completed then ctx.Request('ActivityClaim',{Id=r.Id})else ctx.Confirm('Abandon activity?','Earned pets are kept. The completion reward requires finishing this route.',function()ctx.Request('ActivityAbandon',{Kind='Route',Id=r.Id})end)end
  end)
 end
 local offers=decode(Players.LocalPlayer:GetAttribute('ActivityOffers'))
 if not ctx.Short then W.Text(ctx.Content,'Choose one guided route. Normal tree searches still cost their displayed Forest Coins and award their normal pets.',UDim2.new(1,-8,0,54),nil,13,W.Color.Muted)end
 for _,offer in ipairs(offers)do
  local body=offer.Description..'\n'..math.floor(offer.Seconds/60)..':'..string.format('%02d',offer.Seconds%60)..' • '..reward(offer.Rewards)
  if offer.CostBudget>0 then body..='\nNormal search budget: '..W.Format(offer.CostBudget)..' Forest Coins'else body..='\nFree exploration' end
  if not offer.Eligible then body..='\n'..(offer.Reason or 'Unavailable')end
  card(ctx,'Offer_'..offer.Biome..'_'..offer.Id,offer.Name..' • '..offer.Biome,body,'Accept',function()ctx.Request('ActivityAccept',{Id=offer.Id,Biome=offer.Biome})end,not offer.Eligible or r~=nil)
 end
 local world=RS:FindFirstChild('KingdomWorld');local shared=world and decode(world:GetAttribute('State'))or {}
 if shared.Coop then local c=shared.Coop;card(ctx,'KingdomGoal','Cooperative Kingdom Goal',c.Text..'\n'..c.Progress..'/'..c.Target..' • '..math.max(0,math.ceil((c.EndsAt-workspace:GetServerTimeNow())/60))..' min remaining\n'..(c.MinimumText or ''),nil)end
end
function M.Goals(ctx)
 local a=ctx.Data.Activities or {}
 if a.Journey then goalSet(ctx,a.Journey,'Daily Kingdom Journey',C.Journey.Coins,C.Journey.Tokens)end
 heading(ctx,'Biome goals')
 for _,b in ipairs({'Meadow','Forest'})do goalSet(ctx,a.BiomeGoals and a.BiomeGoals[b],b..' Goals',C.BiomeGoals.Coins[b],C.BiomeGoals.Tokens)end
 heading(ctx,'Pet mission')
 local m=a.Mission
 if m then
  local name=Pets[m.PetId]and Pets[m.PetId].DisplayName or 'Companion'
  card(ctx,'PetMission',name..' • '..m.Progress..'/'..m.Target,m.Text..'\nReward: '..m.XP..' XP for this exact pet.',m.Progress>=m.Target and 'Claim pet XP'or 'Abandon mission',function()
   if m.Progress>=m.Target then ctx.Request('MissionClaim',{Id=m.Id})else ctx.Confirm('Abandon pet mission?','Your pet and its existing XP are kept.',function()ctx.Request('ActivityAbandon',{Kind='Mission',Id=m.Id})end)end
  end)
 else
  local uid=ctx.Data.ActiveHeldPetUID;local pet=uid and require(RS.Shared.Gameplay.PetLocations).Find(ctx.Data,uid)
  W.Text(ctx.Content,pet and ('Mission pet: '..Pets[pet.PetId].DisplayName..' • currently held')or 'Hold the exact pet you want to progress, then choose its mission.',UDim2.new(1,-8,0,42),nil,13)
  for _,row in ipairs({{'HeldSearch','Search eight trees while held'},{'Garden','Complete one Garden expedition'},{'Visits','Visit Meadow and Forest while held'},{'DisplayedCollect','Collect 500 coins while displayed'}})do
   local b=W.Button(ctx.Content,row[2]..' • 100 pet XP',UDim2.new(1,-8,0,44),nil,function()ctx.Request('MissionStart',{UID=uid,Kind=row[1]})end);b.Name='Mission_'..row[1];W.Disabled(b,not pet)
  end
 end
 heading(ctx,'Contracts')
 for _,e in ipairs(ctx.Data.Contracts and ctx.Data.Contracts.Entries or {})do if type(e)=='table'then
  card(ctx,'Contract_'..e.Id,e.Description,e.Progress..'/'..e.Target..' • '..reward({Coins=e.Coins,FriendshipTokens=e.Tokens}),e.Progress>=e.Target and 'Claim reward'or 'In progress',function()ctx.Request('ClaimChallenge',{Period='Contracts',Id=e.Id})end,e.Progress<e.Target)
 end end
 for id,e in pairs(a.Pending or {})do card(ctx,'Pending_'..id,e.Label,reward(e.Rewards),'Claim reward',function()ctx.Request('ActivityClaim',{Id=id})end)end
 heading(ctx,'Weekly challenges')
 for _,def in ipairs(Legacy.Weekly)do
  local e=ctx.Data.WeeklyChallenges.Entries and ctx.Data.WeeklyChallenges.Entries[def.Id]
  if e then card(ctx,'Weekly_'..def.Id,def.DisplayName:gsub('Hatch (%d+) eggs','Find %1 companions'),W.Format(e.Progress)..'/'..W.Format(def.Target)..' • '..reward({Coins=def.Coins,FriendshipTokens=def.Tokens}),e.Claimed and 'Claimed ✓'or 'Claim reward',function()ctx.Request('ClaimChallenge',{Period='Weekly',Id=def.Id})end,e.Claimed or e.Progress<def.Target)end
 end
 local old=a.LegacyDaily and a.LegacyDaily.Entries or {};local any=false
 for _,def in ipairs(Legacy.Daily)do local e=old[def.Id];if e and not e.Claimed then
  if not any then heading(ctx,'Retained Daily progress');any=true end
  card(ctx,'Legacy_'..def.Id,def.DisplayName:gsub('Hatch (%d+) eggs','Find %1 companions'),W.Format(e.Progress)..'/'..def.Target..' • '..reward({Coins=def.Coins,FriendshipTokens=def.Tokens}),e.Progress>=def.Target and 'Claim legacy reward'or 'In progress',function()ctx.Request('ClaimChallenge',{Period='LegacyDaily',Id=def.Id})end,e.Progress<def.Target)
 end end
 local weekly=a.LegacyWeekly and a.LegacyWeekly.Entries or {};local first=true
 for _,def in ipairs(Legacy.Weekly)do local e=weekly[def.Id];if e and not e.Claimed then
  if first then heading(ctx,'Retained Weekly progress');first=false end
  card(ctx,'LegacyWeekly_'..def.Id,def.DisplayName:gsub('Hatch (%d+) eggs','Find %1 companions'),W.Format(e.Progress)..'/'..def.Target..' • '..reward({Coins=def.Coins,FriendshipTokens=def.Tokens}),e.Progress>=def.Target and 'Claim legacy reward'or 'In progress',function()ctx.Request('ClaimChallenge',{Period='LegacyWeekly',Id=def.Id})end,e.Progress<def.Target)
 end end
end
function M.Records(ctx)
 local world=RS:FindFirstChild('KingdomWorld');local state=world and decode(world:GetAttribute('State'))or {}
 W.Text(ctx.Content,'Records belong to this server session. They reset when the server closes.',UDim2.new(1,-8,0,40),nil,13,W.Color.Muted)
 for _,row in ipairs({{'Heaviest','Heaviest pet found'},{'Rarest','Rarest acquisition'},{'CurrentIncome','Current Sanctuary-rate leader'},{'PeakIncome','Highest Sanctuary rate observed'},{'Streak','Longest observed search streak'}})do
  local r=state.Records and state.Records[row[1]]
  card(ctx,'Record_'..row[1],row[2],r and r.Text or 'No qualifying record yet.',nil)
 end
end
function M.Render(ctx)
 W.List(ctx.Content)
 local bar=W.New('Frame',{Name='ActivitySections',Size=UDim2.new(1,-8,0,46),BackgroundTransparency=1},ctx.Content)
 for i,name in ipairs({'Play','Goals','Records'})do
  local b=W.Button(bar,name:upper(),UDim2.new(1/3,-8,1,0),UDim2.fromScale((i-1)/3,0),function()M.Section=name;ctx.Refresh()end,M.Section==name and W.Color.Green or W.Color.Wood);b.Name='Activities_'..name
 end
 M[M.Section](ctx)
end
return M
