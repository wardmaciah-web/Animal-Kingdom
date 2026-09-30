-- Run with tests/run_admin_command_tests.py and a Luau CLI executable.
return function(loadSource)
	local policy = loadSource("RequestPolicy")
	local definitions = {Destinations={{Id="Meadow"},{Id="AdminRoom"}}, MaxAnnouncementCharacters=150}
	local events = {RainyDay={DisplayName="Rainy Day",Duration=420,Weight=10,IsAutomatic=true}, MeteorShower={DisplayName="Meteor Shower",Duration=420,Weight=5,IsAutomatic=true}, Void={DisplayName="Void",Duration=420,Weight=0,IsAutomatic=false}}
	local admin, outsider = {}, {}
	local now = 1000
	local allowed, forget = policy.new(function(player) return player==admin end, definitions, events, function() return now end)
	local valid = {
		{Action="GetState"}, {Action="StopSpectating"}, {Action="ClearQueue"}, {Action="EmergencyReset"},
		{Action="Teleport",Destination="Meadow"}, {Action="QueueEvent",EventId="MeteorShower"},
		{Action="Announce",Message="Welcome to Animal Kingdom!"}, {Action="Confirm",Token=string.rep("a",36)},
	}
	for _, action in ipairs({"TeleportToPlayer","SpectatePlayer","TeleportToPlot","ReturnPlayerToPlot","BringPlayer","RespawnPlayer"}) do table.insert(valid,{Action=action,TargetUserId=-2}) end
	for _, payload in ipairs(valid) do
		now+=1
		assert(not allowed(outsider,payload),"Non-admin admitted: "..payload.Action)
		assert(allowed(admin,payload),"Admin rejected: "..payload.Action)
		assert(not allowed(admin,payload),"Rate limit bypass: "..payload.Action)
	end
	for _, payload in ipairs({
		{}, {Action="Wipe"}, {Action="Teleport",Destination="Unknown"},
		{Action="Teleport",Destination="Meadow",CFrame={1,2,3}}, {Action="QueueEvent",EventId="FakeEvent"},
		{Action="BringPlayer",TargetUserId=0/0}, {Action="BringPlayer",TargetUserId=math.huge},
		{Action="BringPlayer",TargetUserId=2.5}, {Action="BringPlayer",TargetUserId="2"},
		{Action="Announce",Message=""}, {Action="Announce",Message=" \t\n "},
		{Action="Announce",Message=string.rep("x",151)}, {Action="Announce",Message=string.char(255)},
		{Action="Confirm",Token="bad"}, {Action="EmergencyReset",Confirmed=true},
	}) do now+=1;assert(not allowed(admin,payload),"Malformed payload accepted") end
	now+=1;assert(not allowed(admin,{Action="GetState"},"extra"),"Extra argument accepted")
	assert(policy.SanitizeMessage(" \tHello\nworld! ",150)=="Hello world!")
	assert(policy.SanitizeMessage(utf8.char(0x200B,0x00A0,0x3000),150)==nil)
	assert(policy.SanitizeMessage(string.rep("é",150),150)~=nil)
	assert(policy.SanitizeMessage(string.rep("é",151),150)==nil)
	forget(admin);assert(allowed(admin,{Action="GetState"}))
	print("PASS request security: all 14 actions, non-admin denial, malformed inputs, Unicode length, extra arguments, rate limits")

	local ActivityLog = loadSource("ActivityLog")
	local log = ActivityLog.new(20)
	for index=1,30 do log:Add({Name="Admin",UserId=1},"Action "..index) end
	local snapshot=log:Snapshot()
	assert(#snapshot==20 and snapshot[1].Message=="Action 30" and snapshot[20].Message=="Action 11")
	snapshot[1].Message="Changed"
	assert(log:Snapshot()[1].Message=="Action 30")
	print("PASS activity log: bounded to 20 entries; independent snapshots")

	local scheduler, clock, ended = {},1000,{}
	local state = {attributes={}}
	function state:SetAttribute(name,value) self.attributes[name]=value end
	function state:IsA(name) return name=="Folder" end
	local storage = {Packages={Knit="Knit"},Shared={EventDefinitions="Events"}}
	function storage:FindFirstChild(name) return name=="WeatherState" and state or nil end
	local weatherEnv = {
		game={GetService=function(_,name) assert(name=="ReplicatedStorage");return storage end},
		require=function(name) if name=="Knit" then return {CreateService=function(service) return service end} else assert(name=="Events");return events end end,
		Random={new=function() return {NextInteger=function() return 1 end} end},
		workspace={GetServerTimeNow=function() return clock end},
		task={delay=function(seconds,callback) table.insert(scheduler,{At=clock+seconds,Run=callback}) end},
		print=function() end,
	}
	local weather = loadSource("WeatherEventService",weatherEnv)
	function weather:OnEventEnded(definition) table.insert(ended,definition.DisplayName) end
	local function advance(seconds)
		local target=clock+seconds
		while true do
			table.sort(scheduler,function(a,b) return a.At<b.At end)
			if not scheduler[1] or scheduler[1].At>target then break end
			local item=table.remove(scheduler,1);clock=item.At;item.Run()
		end
		clock=target
	end
	weather:Start()
	assert(weather.CurrentPhase=="Break")
	assert(weather.BreakEndTime-clock==300 and state.attributes.TestMode==false)
	weather:StartEvent("RainyDay")
	local oldDeadline=weather.CurrentEventEndTime
	assert(oldDeadline-clock==420,"Admin event did not use production duration")
	assert(weather:QueueEvent("MeteorShower"))
	assert(weather.CurrentEventId=="RainyDay" and weather.CurrentEventEndTime==oldDeadline)
	advance(420)
	assert(weather.CurrentEventId=="MeteorShower" and weather.QueuedEventId=="" and #ended==1)
	assert(state.attributes.QueuedEventId=="" and state.attributes.EventId=="MeteorShower")
	weather:QueueEvent("Void");weather:ClearQueue();advance(420)
	assert(weather.CurrentPhase=="Break")
	advance(300)
	assert(weather.CurrentPhase=="Event" and events[weather.CurrentEventId].IsAutomatic)
	weather:StartEvent("RainyDay");weather:QueueEvent("MeteorShower");weather:PauseAutomaticEvents()
	advance(720)
	assert(weather.CurrentPhase=="Break" and weather.QueuedEventId=="MeteorShower" and weather.BreakEndTime==0)
	weather:ResumeAutomaticEvents()
	assert(weather.CurrentEventId=="MeteorShower" and weather.QueuedEventId=="")
	weather:QueueEvent("Void")
	local count=#ended
	weather:EmergencyReset()
	assert(weather.CurrentPhase=="Break" and weather.QueuedEventId=="" and not weather.AutomaticEventsPaused and #ended==count+1)
	advance(300)
	assert(weather.CurrentPhase=="Event" and events[weather.CurrentEventId].IsAutomatic)
	weather:StartEvent("RainyDay");advance(5);weather:StartEvent("Void");advance(415)
	assert(weather.CurrentEventId=="Void","Stale timer ended a newer event")
	advance(5);assert(weather.CurrentPhase=="Break")
	assert(not weather:QueueEvent("Missing"))
	print("PASS authoritative weather: production 300/420 timing, TEST_MODE off, admin duration, queue transition, queue clear, pause/resume, reset, cycle continuation, stale timer cancellation")

	local function plot(name,claimed,owner)
		return {Name=name,GetAttribute=function(_,key) if key=="Claimed" then return claimed elseif key=="OwnerUserId" then return owner end end}
	end
	local plots={plot("Plot1",true,42),plot("Plot2",false,0)}
	local plotStatus=loadSource("PlotStatus",{
		script={Parent={Parent={PlotLocator="PlotLocator"}}},
		require=function() return {getPlots=function() return plots end} end,
	})
	local stats=plotStatus.GetSnapshot()
	assert(stats.Available and stats.Total==2 and stats.Claimed==1)
	assert(plotStatus.GetPlayerPlot({UserId=42})==plots[1])
	assert(plotStatus.GetPlayerPlot({UserId=99})==nil)
	plots={plot("Unknown",nil,nil)}
	assert(not plotStatus.GetSnapshot().Available,"Uninitialized ownership was guessed")
	print("PASS plot integration: authoritative owner lookup, accurate counts, missing data unavailable")
end
