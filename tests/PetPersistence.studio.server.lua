local K=require(game.ReplicatedStorage.Packages.Knit)
local p=game.Players:GetPlayers()[1]
local profile=K.GetService('ProfileService').Profiles[p]
assert(profile.is_mock==true,'Never write live profiles from this test')
local expected={}
for _,pet in ipairs(profile.Data.Pets)do expected[pet.UID]={Weight=pet.Weight,Location=pet.Location,Slot=pet.LocationSlot}end
local saved=false
local connection=profile.OnAfterSave:Connect(function()saved=true end)
profile:Save()
local deadline=os.clock()+15
repeat task.wait(.1)until saved or os.clock()>deadline
connection:Disconnect();assert(saved,'Mock save did not finish')
local loaded=assert(profile.ProfileStore.Mock:GetAsync(profile.Key))
require(game.ReplicatedStorage.Shared.Gameplay.ProfileMigrations).Apply(loaded.Data,function()error('Existing UID must persist')end)
local count=0
for _,pet in ipairs(loaded.Data.Pets)do
 local was=assert(expected[pet.UID]);assert(pet.Weight==was.Weight and pet.Location==was.Location and pet.LocationSlot==was.Slot,'Persisted individual changed');count+=1
end
assert(count==#profile.Data.Pets)
return {MockOnly=true,Store=profile.ProfileStore.Name,SavedOwnedPets=count,PetDataVersion=loaded.Data.PetDataVersion,WeightAndLocationsPersisted=true,Method='Existing active mock profile Save, Mock:GetAsync, then migration. No new datastore or live write.'}
