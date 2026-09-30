-- Temporary Studio-only fixture. Never mapped into the place. Finish restores copy.
local K=require(game.ReplicatedStorage.Packages.Knit);K.OnStart():await()
local p=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait();local profiles=K.GetService('ProfileService');profiles:WaitUntilProfileLoaded(p)
local profile=profiles.Profiles[p];assert(game:GetService('RunService'):IsStudio()and profile.is_mock)
local original=profile.Data;local cf=p.Character:GetPivot();local H=game.HttpService
local d=H:JSONDecode(H:JSONEncode(original));d.TutorialCompleted=true;d.Currencies.Coins=100000;d.Currencies.FriendshipTokens=100;d.UnlockedBiomes.Forest=true;d.Activities={};d.KingdomShop={};profile.Data=d
local c=K.GetService('ChallengeService');c:Ensure(p);c.Activities:Ensure(p)
local function publish()K.GetService('PetService'):Publish(p);for key in pairs(d)do K.GetService('PlayerDataService'):Publish(p,key)end end
publish()
local command=Instance.new('BindableFunction');command.Name='AKUIFixture';command.Parent=workspace
local root=p.Character.HumanoidRootPart
command.OnInvoke=function(action,id)
 if action=='Town'then local anchor=workspace.KingdomTownInteractions:FindFirstChild(id);root.CFrame=CFrame.lookAt(anchor.Position+Vector3.new(0,1,6),anchor.Position);root.Anchored=false;return tostring(anchor.Position)end
 if action=='Meadow'then local candidate=c.Activities.Routes:Candidates('Meadow','Meadow_Shakeable_01')[1];root.CFrame=CFrame.new(candidate.Record.InteractionPosition+Vector3.new(8,1,0));return true end
 if action=='Paw'then return c.Activities.Routes:Accept(p,'Paw','Meadow')end
 if action=='PawTarget'then local r=d.Activities.Route;local pos=Vector3.new(unpack(r.Targets[r.Progress+1].Position));root.CFrame=CFrame.new(pos+Vector3.new(0,3,0));return r.Progress end
 if action=='Hot'then local tree=c.Activities.Routes:Candidates('Meadow','Meadow_Shakeable_01')[1].Tree;return c.Activities.World:StartHot(id,tree)end
 if action=='Lucky'then K.GetService('LuckyTreeService'):EndEvent();return K.GetService('LuckyTreeService'):Spawn(id)end
 if action=='Data'then return {Coins=d.Currencies.Coins,Shop=d.KingdomShop,Route=d.Activities.Route,Pets=#d.Pets,InGarden=p:GetAttribute('InGarden')}end
 if action=='Restore'then
  K.GetService('LuckyTreeService'):EndEvent();c.Activities.World:ClearHot();profile.Data=original;K.GetService('PetService'):Publish(p);for key in pairs(original)do K.GetService('PlayerDataService'):Publish(p,key)end;p.Character:PivotTo(cf);command:Destroy();return true
 end
end
command:Invoke('Town','Activities');workspace:SetAttribute('AKUIFixtureReady',true)
