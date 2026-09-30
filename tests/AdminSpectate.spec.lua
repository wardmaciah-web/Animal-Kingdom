return function(loadSource)
	local humanoid={}
	local player={CharacterAdded={Connect=function() end},Character={FindFirstChildOfClass=function() return humanoid end}}
	local camera={CameraType="Custom",CameraSubject={}}
	local module=loadSource("AdminSpectate",{
		game={GetService=function() return {LocalPlayer=player} end},
		workspace={CurrentCamera=camera},
		Enum={CameraType={Custom="Custom",Scriptable="Scriptable"}},
	})
	local stops=0
	local session=module.new(function() stops+=1 end)
	session.active=true
	session:Stop(true,false)
	assert(camera.CameraSubject==humanoid and camera.CameraType=="Custom")
	local mapSubject={}
	camera.CameraType="Scriptable";camera.CameraSubject=mapSubject
	session.active=true
	session:Stop(true,false)
	assert(camera.CameraType=="Scriptable" and camera.CameraSubject==mapSubject,"Late spectate stop overwrote Phase 1 map camera")
	assert(stops==2)
	print("PASS spectate handoff: restores own humanoid; late stop preserves Phase 1 map camera")
end
