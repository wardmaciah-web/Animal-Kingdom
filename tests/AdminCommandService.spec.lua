return function(loadSource)
	local function signal()
		local listeners={}
		return {Connect=function(_,callback) table.insert(listeners,callback);return {Disconnect=function() end} end,
			Fire=function(_,...) for _,callback in ipairs(listeners) do callback(...) end end}
	end
	local now=1000
	local players={PlayerAdded=signal(),PlayerRemoving=signal(),MaxPlayers=8}
	local admin={Name="Admin",DisplayName="Admin",UserId=1,Parent=players,CharacterRemoving=signal()}
	local target={Name="Target",DisplayName="Target",UserId=2,Parent=players,CharacterRemoving=signal()}
	local outsider={Name="Normal",DisplayName="Normal",UserId=3,Parent=players,CharacterRemoving=signal()}
	local roster={admin,target,outsider}
	function players:GetPlayers() return roster end
	function players:GetPlayerByUserId(id) for _,player in ipairs(roster) do if player.UserId==id and player.Parent==self then return player end end end
	local respawns=0
	function target:LoadCharacterAsync() respawns+=1 end
	local authorized,inside=true,true
	local yieldAuthorization, yieldFilter=false,false
	local weatherAdmin={ActionRecorded={Event=signal()}}
	function weatherAdmin:IsAuthorized(player)
		if yieldAuthorization then coroutine.yield("authorizing") end
		return authorized and player==admin
	end
	function weatherAdmin:IsInsideRoom() return inside end
	local weather={QueueRevision=0,QueuedEventId="",CurrentEventId="RainyDay"}
	function weather:QueueEvent(id) self.QueuedEventId=id;self.QueueRevision+=1;return true end
	function weather:ClearQueue() self.QueuedEventId="";self.QueueRevision+=1 end
	local resets=0
	function weather:EmergencyReset() resets+=1;self:ClearQueue() end
	function weather:GetCurrentState() return {QueuedEventId=self.QueuedEventId} end
	local remotes={}
	for _,name in ipairs({"AdminCommandRequest","AdminCommandResponse","AdminCommandState","GlobalAnnouncement","AdminCameraControl"}) do
		local remote={OnServerEvent=signal(),sent={},broadcasts={}}
		function remote:IsA(class) return class=="RemoteEvent" end
		function remote:FireClient(player,payload) table.insert(self.sent,{player,payload}) end
		function remote:FireAllClients(payload) table.insert(self.broadcasts,payload) end
		remotes[name]=remote
	end
	function remotes:FindFirstChild(name) return self[name] end
	function remotes:WaitForChild(name) return assert(self[name]) end
	local defs={Destinations={{Id="Meadow",DisplayName="MEADOW"},{Id="AdminRoom",DisplayName="ADMIN ROOM"}},MaxAnnouncementCharacters=150,ActivityLimit=20,ConfirmationLifetime=15}
	local events={RainyDay={DisplayName="Rainy Day"},MeteorShower={DisplayName="Meteor Shower"}}
	local moves={}
	local teleports={}
	for _,name in ipairs({"ToPlayer","ToPlot","ToDestination"}) do teleports[name]=function(...) table.insert(moves,{name,...});return true end end
	local values={Definitions=defs,Events=events,Policy=loadSource("RequestPolicy",{os={clock=function() return now end}}),ActivityLog=loadSource("ActivityLog"),Teleports=teleports,RoomPanels={}}
	values.PlotStatus={GetSnapshot=function() return {Available=true,Claimed=1,Total=5},{} end,GetPlayerPlot=function() return nil end}
	values.Knit={CreateService=function(service) return service end,GetService=function(name) return name=="WeatherAdminService" and weatherAdmin or weather end}
	local storage={Packages={Knit="Knit"},Shared={AdminCommandDefinitions="Definitions",EventDefinitions="Events"}}
	function storage:WaitForChild(name) if name=="WeatherState" then return {} end;assert(name=="AnimalKingdomRemotes");return remotes end
	local filterFail,revokeOnFilter=false,false
	local services={Players=players,ReplicatedStorage=storage,ServerScriptService={AdminCommandCenter={RequestPolicy="Policy",PlotStatus="PlotStatus",Teleports="Teleports",RoomPanels="RoomPanels",ActivityLog="ActivityLog"}}}
	local tokenIndex=0
	services.HttpService={GenerateGUID=function() tokenIndex+=1;return string.format("%036d",tokenIndex) end}
	services.TextService={FilterStringAsync=function(_,text,userId)
		assert(userId==admin.UserId)
		if yieldFilter then coroutine.yield("filtering") end
		if filterFail then error("Filter down") end
		if revokeOnFilter then authorized=false end
		return {GetNonChatStringForBroadcastAsync=function() return "[filtered] "..text end}
	end}
	local fakeOs=table.clone(os);fakeOs.clock=function() return now end
	local module=loadSource("AdminCommandService",{
		game={GetService=function(_,name) return assert(services[name],name) end},
		require=function(name) return assert(values[name],name) end,
		workspace={GetServerTimeNow=function() return now end},time=function() return 10 end,
		os=fakeOs,task={spawn=function() end},Enum={TextFilterContext={PublicChat="PublicChat"}},
		warn=function(message) error(message) end,
	})
	module:KnitInit();module:KnitStart()
	local function send(player,payload)
		now+=1
		remotes.AdminCommandRequest.OnServerEvent:Fire(player,payload)
	end
	local function latest() return remotes.AdminCommandResponse.sent[#remotes.AdminCommandResponse.sent][2] end
	for _,action in ipairs({{Action="EmergencyReset"},{Action="RespawnPlayer",TargetUserId=2},{Action="BringPlayer",TargetUserId=2},{Action="Announce",Message="unsafe"}}) do send(outsider,action) end
	assert(resets==0 and respawns==0 and #moves==0 and #remotes.GlobalAnnouncement.broadcasts==0 and #remotes.AdminCommandResponse.sent==0)
	send(admin,{Action="RespawnPlayer",TargetUserId=2})
	assert(latest().Kind=="Confirm" and respawns==0)
	local token=latest().Token
	send(admin,{Action="Confirm",Token=token,TargetUserId=3})
	assert(respawns==0)
	send(admin,{Action="Confirm",Token=token});assert(respawns==1)
	send(admin,{Action="Confirm",Token=token});assert(respawns==1,"Confirmation replay")
	send(admin,{Action="EmergencyReset"});token=latest().Token
	now+=16;send(admin,{Action="Confirm",Token=token});assert(resets==0,"Expired reset")
	send(admin,{Action="EmergencyReset"});token=latest().Token
	send(admin,{Action="Confirm",Token=token});assert(resets==1)
	weather:QueueEvent("RainyDay")
	send(admin,{Action="QueueEvent",EventId="MeteorShower"});token=latest().Token
	assert(weather.QueuedEventId=="RainyDay")
	weather:ClearQueue()
	send(admin,{Action="Confirm",Token=token});assert(weather.QueuedEventId=="","Changed queue overwritten")
	send(admin,{Action="QueueEvent",EventId="MeteorShower"});assert(weather.QueuedEventId=="MeteorShower")
	send(admin,{Action="QueueEvent",EventId="RainyDay"});token=latest().Token
	send(admin,{Action="Confirm",Token=token});assert(weather.QueuedEventId=="RainyDay")
	target.Parent=nil;send(admin,{Action="BringPlayer",TargetUserId=2});assert(#moves==0)
	target.Parent=players;send(admin,{Action="BringPlayer",TargetUserId=2});assert(#moves==1 and moves[1][2]==target and moves[1][3]==admin)
	inside=false;send(admin,{Action="BringPlayer",TargetUserId=2});assert(#moves==1)
	send(admin,{Action="Teleport",Destination="AdminRoom"});assert(#moves==2)
	inside=true
	send(admin,{Action="Announce",Message="Welcome to Animal Kingdom!"})
	assert(#remotes.GlobalAnnouncement.broadcasts==1 and remotes.GlobalAnnouncement.broadcasts[1].Message=='[Admin] "Admin": "[filtered] Welcome to Animal Kingdom!"')
	send(admin,{Action="GetState"})
	local activity=remotes.AdminCommandState.sent[#remotes.AdminCommandState.sent][2].Activity
	assert(activity[1].Message==remotes.GlobalAnnouncement.broadcasts[1].Message,"Announcement feed and broadcast must use identical formatting")
	send(admin,{Action="Announce",Message="too soon"});assert(#remotes.GlobalAnnouncement.broadcasts==1)
	now+=6;filterFail=true;send(admin,{Action="Announce",Message="filter failure"});assert(#remotes.GlobalAnnouncement.broadcasts==1)
	now+=6;filterFail=false;revokeOnFilter=true;send(admin,{Action="Announce",Message="revoked"});assert(#remotes.GlobalAnnouncement.broadcasts==1)
	-- An earlier authorization lookup can finish while a later accepted request
	-- is waiting for text filtering. It must recheck the per-player busy guard.
	authorized=true;revokeOnFilter=false;yieldAuthorization=true
	local awaitingAuthorization=coroutine.create(function() send(admin,{Action="GetState"}) end)
	local ok,stage=coroutine.resume(awaitingAuthorization)
	assert(ok and stage=="authorizing")
	yieldAuthorization=false;yieldFilter=true;now+=6
	local filtering=coroutine.create(function() send(admin,{Action="Announce",Message="concurrency check"}) end)
	ok,stage=coroutine.resume(filtering)
	assert(ok and stage=="filtering")
	local states=#remotes.AdminCommandState.sent
	assert(coroutine.resume(awaitingAuthorization))
	assert(#remotes.AdminCommandState.sent==states,"Yielding authorization bypassed the busy request guard")
	yieldFilter=false
	assert(coroutine.resume(filtering))
	print("PASS admin concurrency: authorization resumes into an already busy player without executing a second action")
	print("PASS actual server dispatcher: non-admin denial, bound/expiring/single-use confirmations, queue revision race, target departure, room boundary, filtered broadcast, fail-closed filtering, post-filter reauthorization")
end
