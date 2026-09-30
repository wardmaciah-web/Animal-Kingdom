-- Studio mock fixtures at base weight; no reward simulation, grants, boosts or live saves.
-- Run after Live.server.lua completes. Fixtures never overwrite any real saved pet.
assert(game:GetService('RunService'):IsStudio())
local K=require(game.ReplicatedStorage.Packages.Knit);K.OnStart():await()
local p=game.Players:GetPlayers()[1];local profile=K.GetService('ProfileService').Profiles[p]
assert(profile and profile.is_mock and p:GetAttribute('ProfileDataMode')=='StudioMockSnapshot')
local function copy(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=copy(x)end return r end
local original=copy(profile.Data);local cf=p.Character:GetPivot();local G=game.ReplicatedStorage.Shared.Gameplay
local P=K.GetService('PetService');local S=K.GetService('SanctuaryService');local Plot=K.GetService('PlotService');local D=K.GetService('PlayerDataService')
local Defs=require(G.Definitions.PetDefinitions);local M=require(G.ProfileMigrations);local Stats=require(G.PetStats)
local result={Rows={},Checks=0};local function check(v,s)assert(v,s);result.Checks+=1 end
local scenarios={
 {Name='Weakest starter, zero coins',Pets={{'MeadowFieldMouse',1}},Seconds=100,Target=250},
 {Name='Several starters',Pets={{'MeadowFieldMouse',5}},Seconds=5,Target=500},
 {Name='Developed Meadow',Pets={{'MeadowChick',2},{'MeadowRedSquirrel',3},{'MeadowGoat',3},{'MeadowDaisyHedgehog',2}},Seconds=5,Target=8500},
 {Name='New Forest, Meadow plus two Raccoons',Pets={{'MeadowChick',2},{'MeadowRedSquirrel',3},{'MeadowGoat',3},{'MeadowDaisyHedgehog',2},{'ForestRaccoon',2}},Seconds=5,Target=10000},
 {Name='Developed Forest, three typical pets per tier',Pets={{'ForestRaccoon',3},{'ForestBlackBearCub',3},{'ForestSkunk',3},{'ForestBadger',3},{'ForestRiverOtter',3}},Seconds=5,Target=50000},
}
local ok,err=xpcall(function()
 K.GetService('WeatherEventService'):PauseAutomaticEvents()
 K.GetService('WeatherEventService'):EndCurrentEvent()
 K.GetService('WeatherEventService'):StartBreak()
 for n,scenario in ipairs(scenarios)do
  workspace:SetAttribute('AKEconomyPacingStage',scenario.Name)
  local d=M.Apply(copy(require(game.ReplicatedStorage.SharedSource.Datas.ProfileTemplate)),function()error('Empty template needs no UID')end)
  d.Currencies.Coins=0;d.ForestCoins=0;d.TutorialCompleted=true;d.SanctuaryIncomeUpdatedAt=workspace:GetServerTimeNow()
  profile.Data=d;K.GetService('ChallengeService'):Ensure(p);P:Publish(p);S:Accrue(p)
  local rate=0
  for _,row in ipairs(scenario.Pets)do for _=1,row[2]do
   local def=Defs[row[1]];local i=#d.Pets+1;local uid='pacing-fixture-'..n..'-'..i
   check(require(game.ServerScriptService.ServerSource.Utilities.MeadowSanctuaryDisplay).GetSlot(p,i)~=nil,'Real physical slot')
   local pet={UID=uid,UniquePetId=uid,PetId=def.PetId,Weight=def.BaseWeight,Location='Sanctuary',LocationSlot=i,Level=1,XP=0,Mutation='Normal',Shiny=false,Prismatic=false,Favorite=false,Locked=false,AcquiredAt=0,AwardProgressApplied=true}
   table.insert(d.Pets,pet);rate+=Stats.Income(pet)
  end end
  P:Publish(p);for key in pairs(d)do D:Publish(p,key)end
  check(Plot:Teleport(p),'Free plot travel at zero balance');p.Character.HumanoidRootPart.Anchored=true
  check(S:GetIncome(d)==rate and d.SanctuaryIncomePerSecond==rate,'Displayed income sums all pets')
  S:Accrue(p);local start=d.SanctuaryIncomeUpdatedAt;local initial=d.Currencies.Coins+d.UncollectedSanctuaryCoins
  if n==1 then
   while d.Currencies.Coins<250 and workspace:GetServerTimeNow()-start<110 do task.wait(.25);Plot:Collect(p)end
   check(d.Currencies.Coins>=250,'Weakest zero-balance starter funds another search')
  else task.wait(scenario.Seconds);check(Plot:Collect(p),'Fixture earns and collects')end
  S:Accrue(p);local elapsed=d.SanctuaryIncomeUpdatedAt-start
  local earned=d.Currencies.Coins+d.UncollectedSanctuaryCoins-initial
  table.insert(result.Rows,{Name=scenario.Name,Count=#d.Pets,Rate=rate,Elapsed=elapsed,Earned=earned,Collected=d.Currencies.Coins,Target=scenario.Target,CalculatedSeconds=scenario.Target/rate})
  check(math.abs(earned-rate*elapsed)<rate*.25,'Measured earnings match elapsed time and displayed rate')
 end
end,debug.traceback)
profile.Data=original;P:Publish(p);for key in pairs(original)do D:Publish(p,key)end
K.GetService('WeatherEventService'):ResumeAutomaticEvents()
if p.Character then p.Character.HumanoidRootPart.Anchored=false;p.Character:PivotTo(cf)end
result.Passed=ok;result.Error=not ok and err or nil;result.RestoredOriginalMock=true
workspace:SetAttribute('AKEconomyPacing',game.HttpService:JSONEncode(result))
workspace:SetAttribute('AKEconomyPacingStage',ok and 'Complete' or 'Failed')
if not ok then warn(err)end
