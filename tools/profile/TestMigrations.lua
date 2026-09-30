-- Run in Studio Edit context with _G.ProfileRepairFixture set to a read-only Data copy.
local module=game.ReplicatedStorage.Shared.Gameplay.ProfileMigrations:Clone()
module.Name='ProfileMigrationRegression_TEMP';module.Parent=game.ServerStorage
local M=require(module)
local results={}
local function copy(v) if type(v)~='table' then return v end local t={}for k,x in pairs(v) do t[k]=copy(x) end return t end
local function same(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for k,v in pairs(a) do if not same(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
local protected={'Currencies','ForestCoins','FriendshipTokens','Pets','OwnedPets','PetIndex','NumNomIndex','UnlockedBiomes','DisplayedPetIds','UncollectedSanctuaryCoins','SanctuaryIncomeUpdatedAt','PlotProgression','GardenExpeditions','GardenCosmetics','UnlockedDecorations'}
local function safe(v,seen)
 local t=typeof(v)
 if t=='nil' or t=='string' or t=='boolean' then return true end
 if t=='number' then return v==v and math.abs(v)<math.huge end
 if t~='table' then return false end
 seen=seen or {};if seen[v] then return false end;seen[v]=true
 for k,c in pairs(v) do if (type(k)~='string' and type(k)~='number') or not safe(c,seen) then return false end end
 seen[v]=nil;return true
end
local seq=0;local function guid() seq+=1;return 'fixture-uid-'..seq end
local function test(name,fn)
 local ok,err=xpcall(fn,debug.traceback);table.insert(results,{name=name,pass=ok,error=not ok and err or nil})
end
local real=assert(_G.ProfileRepairFixture,'Missing saved snapshot fixture')
test('Existing v3 save: all protected fields unchanged',function()
 local d=copy(real);M.Apply(d,guid)
 for _,k in protected do assert(same(real[k],d[k]),'Changed protected field '..k) end
 assert(d.DataVersion==3 and safe(d))
end)
test('Migration is idempotent for existing v3 save',function()
 local d=copy(real);M.Apply(d,guid);local once=copy(d);M.Apply(d,guid);assert(same(once,d))
end)
test('Old v2 profile with no Garden fields defaults safely',function()
 local d=copy(real);d.DataVersion=2;d.SchemaVersion=2;d.GardenExpeditions=nil;d.GardenCosmetics=nil;d.Currencies.GardenHarvest=nil
 M.Apply(d,guid);assert(d.Currencies.GardenHarvest==0 and next(d.GardenExpeditions)==nil and next(d.GardenCosmetics)==nil)
 for _,k in protected do if k~='Currencies' and k~='GardenExpeditions' and k~='GardenCosmetics' then assert(same(real[k],d[k]),'Changed '..k) end end
 assert(d.Currencies.Coins==real.Currencies.Coins and d.Currencies.FriendshipTokens==real.Currencies.FriendshipTokens)
 local once=copy(d);M.Apply(d,guid);assert(same(once,d) and safe(d))
end)
test('Legacy v0 currency, pets and sanctuary preserved',function()
 local pet={PetId='LegacyUnknownSpecies',UniquePetId='legacy-pet',Level=4,XP=8,Mutation='Normal',Shiny=false,Prismatic=false,Favorite=true,Locked=true}
 local d={ForestCoins=4321,FriendshipTokens=9,OwnedPets={pet},NumNomIndex={LegacyUnknownSpecies=true},UnlockedBiomes={Forest=true},DisplayedPetIds={'legacy-pet'},UncollectedSanctuaryCoins=123}
 M.Apply(d,guid);assert(d.Currencies.Coins==4321 and d.Currencies.FriendshipTokens==9 and #d.Pets==1)
 assert(d.Pets[1].UID=='legacy-pet' and d.NumNomIndex.LegacyUnknownSpecies and d.UnlockedBiomes.Forest and d.UncollectedSanctuaryCoins==123)
 assert(d.Pets[1].Favorite and d.Pets[1].Locked and d.Currencies.GardenHarvest==0 and safe(d))
end)
test('Valid Garden trips, cosmetics and extra fields survive',function()
 local d=copy(real);d.GardenExpeditions={};d.GardenCosmetics={FlowerCrown=true,UnknownFutureCosmetic=true,Unowned=false}
 for i=1,8 do d.GardenExpeditions[i]={UID='future-'..i,PetId='FutureSpecies',ReadyAt=123456+i,Duration=100000,StartedAt=23456+i,DurationId='FutureDuration',TripId='stable-'..i,FutureField={Keep=true}} end
 local before=copy(d.GardenExpeditions);M.Apply(d,guid);assert(same(before,d.GardenExpeditions) and d.GardenCosmetics.UnknownFutureCosmetic and d.GardenCosmetics.Unowned==false)
 local once=copy(d);M.Apply(d,guid);assert(same(once,d) and safe(d))
end)
test('Malformed optional Garden fields archived without blocking',function()
 local d=copy(real);d.GardenExpeditions='legacy-bad-shape';d.GardenCosmetics='old-cosmetic-format';M.Apply(d,guid)
 assert(d.RecoveryData.GardenMigration.GardenExpeditions=='legacy-bad-shape' and d.RecoveryData.GardenMigration.GardenCosmetics=='old-cosmetic-format')
 assert(d.ForestCoins==real.ForestCoins and #d.Pets==#real.Pets and safe(d))
 local once=copy(d);M.Apply(d,guid);assert(same(once,d))
end)
test('Malformed trip entries recovered; missing trip IDs default stably',function()
 local d=copy(real);d.GardenExpeditions={'malformed',{UID='old-trip',PetId='FutureSpecies',Duration=60,ReadyAt=1000}}
 M.Apply(d,guid);assert(#d.GardenExpeditions==1 and d.GardenExpeditions[1].StartedAt==940 and d.GardenExpeditions[1].TripId=='old-trip:940:60')
 assert(d.RecoveryData.GardenMigration.InvalidExpeditions['1']=='malformed');local once=copy(d);M.Apply(d,guid);assert(same(once,d) and safe(d))
end)
test('Unsafe optional Garden recovery values are serialized',function()
 local d=copy(real);d.Currencies.GardenHarvest=0/0;d.GardenCosmetics={FlowerCrown=true,Bad=workspace};d.GardenExpeditions={Vector3.new(1,2,3)}
 M.Apply(d,guid);assert(safe(d) and d.GardenCosmetics.FlowerCrown and d.Currencies.GardenHarvest==0)
end)
test('Future profile is rejected before any mutation',function()
 local d=copy(real);d.DataVersion=4;local before=copy(d);local ok,err=pcall(M.Apply,d,guid)
 assert(not ok and tostring(err):find('saved=4, supported=3',1,true) and same(before,d))
end)
module:Destroy()
_G.ProfileMigrationTestResults=results
return game:GetService('HttpService'):JSONEncode(results)
