-- One compact status line, coordinated with the existing Held/HUD layout.
local Players=game:GetService("Players")
local RS=game:GetService('ReplicatedStorage')
local W=require(script.Parent.GameplayWidgets)
local M={};M.__index=M
function M.new(root,screen,held,ctx)
 local self=setmetatable({Root=root,Screen=screen,Held=held,Connections={}},M)
 self.Frame=W.Surface(root,"AdventureStatus",UDim2.fromOffset(340,26),nil,"Paper");self.Frame.AnchorPoint=Vector2.new(.5,0)
 self.Text=W.Text(self.Frame,"",UDim2.new(1,-12,1,0),UDim2.fromOffset(6,0),12);self.Text.TextXAlignment=Enum.TextXAlignment.Center
 if ctx then local b=W.New('TextButton',{Name='TrackedObjective',Size=UDim2.fromScale(1,1),Text='',BackgroundTransparency=1},self.Frame);W.Bind(b,function()require(script.Parent.ActivityMenus).Section=self.Data and self.Data.Activities and self.Data.Activities.Route and 'Play'or 'Goals';ctx.Open('Challenges')end)end
 local player=Players.LocalPlayer
 for _,key in ipairs({"SearchStreakCount","SearchStreakBonus","LuckyTreeBoostPercent","LuckyTreeBoostExpiresAt"})do table.insert(self.Connections,player:GetAttributeChangedSignal(key):Connect(function()self:Update()end))end
 for _,key in ipairs({"ActiveMenu","AnnouncementActive","RewardRevealActive","OnboardingActive","ModalActive","LuckyPreviewActive"})do table.insert(self.Connections,screen:GetAttributeChangedSignal(key):Connect(function()self:Update()end))end
 table.insert(self.Connections,screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()self:Update()end))
 task.spawn(function()while self.Frame.Parent do self:Update();task.wait(1)end end)
 self:Update();return self
end
function M:Update()
 local p=Players.LocalPlayer;local count=p:GetAttribute("SearchStreakCount") or 0;local bonus=p:GetAttribute("SearchStreakBonus") or 0
 local seconds=math.max(0,math.ceil((p:GetAttribute("LuckyTreeBoostExpiresAt") or 0)-workspace:GetServerTimeNow()))
 local lines={}
 local d=self.Data;local a=d and d.Activities;local r=a and a.Route
 if r then
  local remaining=math.max(0,math.ceil(r.EndsAt-workspace:GetServerTimeNow()))
  table.insert(lines,string.format('%s • %d/%d • %s',r.Name,r.Progress,r.Target,r.Completed and 'CLAIM' or string.format('%d:%02d',math.floor(remaining/60),remaining%60)))
 elseif a then
  local biome=p:GetAttribute('CurrentBiome');local set=a.BiomeGoals and a.BiomeGoals[biome]
  if set then local complete=0;for _,g in ipairs(set.Entries)do if g.Progress>=g.Target then complete+=1 end end;table.insert(lines,biome..' Goals • '..complete..'/3'..(set.Claimed and ' ✓'or ''))end
 end
 local boosts={}
 for id,b in pairs(d and d.KingdomShop and d.KingdomShop.Active or {})do
  local left=math.max(0,math.ceil(b.ExpiresAt-workspace:GetServerTimeNow()))
  if left>0 then table.insert(boosts,id..' '..math.floor(left/60)..':'..string.format('%02d',left%60))end
 end
 table.sort(boosts)
 if seconds>0 then table.insert(boosts,string.format("Lucky +%d%% %d:%02d",p:GetAttribute("LuckyTreeBoostPercent") or 0,math.floor(seconds/60),seconds%60))end
 if #boosts>0 then
  local short=self.Screen.AbsoluteSize.X<700
  table.insert(lines,#boosts>(short and 1 or 2)and (#boosts..' active boosts • timers in Shop')or table.concat(boosts,' · '))
 end
 -- Shared progress uses spare space in this same compact HUD; an accepted route wins.
 if not r and #lines<2 then
  local world=RS:FindFirstChild('KingdomWorld');local ok,state=pcall(game.HttpService.JSONDecode,game.HttpService,world and world:GetAttribute('State')or '{}')
  local c=ok and state.Coop
  if c and c.EndsAt>workspace:GetServerTimeNow()then local left=math.ceil(c.EndsAt-workspace:GetServerTimeNow());table.insert(lines,string.format('Kingdom Goal • %d/%d • %d:%02d',c.Progress,c.Target,math.floor(left/60),left%60))end
 end
 if count>0 and #lines<2 then table.insert(lines,string.format("Search streak: %d • +%d%% Luck",count,math.floor(bonus*100+.5)))end
 local s=self.Screen;local size=s.AbsoluteSize
 self.Text.Text=table.concat(lines,"\n")
 self.Frame.Visible=#lines>0 and not s:GetAttribute("AnnouncementActive")and s:GetAttribute("ActiveMenu")=="" and not s:GetAttribute("RewardRevealActive") and not s:GetAttribute("OnboardingActive") and not s:GetAttribute("ModalActive") and not s:GetAttribute("LuckyPreviewActive")
 self.Frame.Size=UDim2.fromOffset(math.min(size.X-24,480),#lines>1 and 44 or 24)
 local compact=size.X<900 or size.Y<580
 local y=compact and (self.Held.Root.AbsolutePosition.Y-self.Root.AbsolutePosition.Y-self.Frame.Size.Y.Offset-4) or 76
 self.Frame.Position=UDim2.new(.5,0,0,y)
 self.Text.TextSize=compact and 10 or 12
end
function M:Destroy()for _,c in ipairs(self.Connections)do c:Disconnect()end;self.Frame:Destroy()end
return M
