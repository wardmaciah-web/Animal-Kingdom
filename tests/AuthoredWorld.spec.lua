return function(loadSource)
	local instances = {}
	local frameMeta = {}
	local function frame(x, y, z, yaw)
		return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,Yaw=yaw or 0}, frameMeta)
	end
	function frameMeta.__mul(a, b)
		local c, s = math.cos(a.Yaw), math.sin(a.Yaw)
		return frame(a.X+c*b.X+s*b.Z, a.Y+b.Y, a.Z-s*b.X+c*b.Z, a.Yaw+b.Yaw)
	end
	local function instance(class, name)
		local object = {ClassName=class, Name=name, children={}, attributes={}}
		setmetatable(object, {__newindex=function(self,key,value)
			if key=="Parent" and value then value.children[self.Name]=self end
			rawset(self,key,value)
		end})
		function object:IsA(wanted) return self.ClassName==wanted or (wanted=="BasePart" and (self.ClassName=="Part" or self.ClassName=="SpawnLocation")) end
		function object:FindFirstChild(childName) return self.children[childName] end
		function object:GetAttribute(key) return self.attributes[key] end
		function object:SetAttribute(key, value) self.attributes[key]=value end
		function object:GetDescendants()
			local all={}
			local function visit(root) for _,child in pairs(root.children) do table.insert(all,child);visit(child) end end
			visit(self);return all
		end
		table.insert(instances,object)
		return object
	end
	local workspace=instance("Workspace", "Workspace")
	local world=instance("Model", "World");workspace.children.World=world
	local blockout=instance("Model", "BiomeBlockout");world.children.BiomeBlockout=blockout
	local platform=instance("Part", "Platform");blockout.children.Platform=platform
	local spawn=instance("SpawnLocation", "MeadowSpawn");spawn.Enabled=true;blockout.children.MeadowSpawn=spawn
	local prompt=instance("ProximityPrompt", "Prompt");prompt.Enabled=true;blockout.children.Prompt=prompt
	local region=instance("Model", "Meadow");workspace.children.Meadow=region
	local floor=instance("Part", "MeadowFloor");region.children.MeadowFloor=floor
	floor.Transparency=0;floor.CanCollide=true
	local playerReads, backgroundLoops=0,0
	local players={GetPlayers=function() playerReads+=1;return {} end}
	local config={Biomes={{Id="Meadow"}}}
	local values={Knit={CreateService=function(service) return service end},Config=config,Shakeables={},Pets={},Mutations={},NumNoms={},Guard={}}
	local storage={Packages={Knit="Knit"},SharedSource={Datas={AnimalKingdomConfig="Config",ShakeableDatabase="Shakeables",PetDatabase="Pets",MutationDatabase="Mutations",NumNomDatabase="NumNoms"}}}
	local environment={
		game={GetService=function(_,name) return name=="Players" and players or storage end},
		workspace=workspace,require=function(name) return assert(values[name],name) end,
		Vector2={new=function(x,y) return {X=x,Y=y} end},Color3={fromRGB=function() return {} end},
		Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end},CFrame={new=frame},
		Enum={Material=setmetatable({},{__index=function(_,key) return key end}),SurfaceType={Smooth="Smooth"}},
		Instance={new=function(class) return instance(class,class) end},Random={new=function() return {} end},
		task={spawn=function() backgroundLoops+=1 end},
		script={Parent={Parent={Utilities={GameplayGuard="Guard"}}}},print=function() end,
	}
	local service=loadSource("WorldService",environment)
	service.BuildStaticBiomes=function() error("Authored map invoked legacy world generator") end
	service:KnitStart()
	assert(service.AuthoredMap==true and playerReads==0,"Authored map created legacy player sanctuary scaffold")
	assert(world.children.BiomeBlockout==blockout,"Portable source fallback was deleted")
	assert(blockout.attributes.EditorReferenceOnly and platform.Transparency==1 and platform.CanCollide==false and platform.CanQuery==false and platform.CanTouch==false,"Legacy floor interferes with authored world")
	assert(spawn.Enabled==false and prompt.Enabled==false,"Hidden legacy interactions remain enabled")
	assert(floor.CanCollide and floor.Transparency==0,"Authored floor was modified")
	local runtime=false
	for _,object in ipairs(instances) do if object.Parent==world and object.Name=="Runtime" then runtime=true end end
	assert(runtime,"Authored map lost its runtime container")
	loadSource("NumNomService",environment):KnitStart()
	assert(backgroundLoops==0,"Authored map started prototype collectible loop")
	local ground=instance("Part","AnimalKingdomConcreteGround");workspace.children.AnimalKingdomConcreteGround=ground
	ground.Size={X=1329.33740234375,Y=1,Z=1352.2706298828125};ground.CFrame=frame(-337.8204650878906,7.328930854797363,248.02099609375)
	service:EnsurePerimeterBoundary()
	local perimeter=assert(workspace.children.AK_AuditPerimeter)
	local count=0
	for _,wall in pairs(perimeter.children) do
		count+=1
		assert(wall.Size.Y==6 and wall.Anchored and wall.CanCollide and wall.CanTouch==false and wall.Transparency==0)
		assert(math.abs(wall.CFrame.Y-wall.Size.Y/2-7.828930854797363)<.00001,"Boundary bottom does not meet support top")
	end
	assert(count==4,"Expected exactly four boundary walls")
	local before=#instances
	service:EnsurePerimeterBoundary()
	assert(#instances==before,"Repeated boundary install duplicated instances")
	assert(math.abs(perimeter.children.East.CFrame.X+perimeter.children.East.Size.X/2-(ground.CFrame.X+ground.Size.X/2))<.00001,"East edge moved outside support")
	assert(perimeter.children.North.Size.X==ground.Size.X and perimeter.children.East.Size.Z==ground.Size.Z-6,"Boundary corners have gaps")
	ground.CFrame=frame(-337.8204650878906,7.328930854797363,248.02099609375,math.pi/2)
	service:EnsurePerimeterBoundary()
	assert(math.abs(perimeter.children.East.CFrame.X-ground.CFrame.X)<.00001 and math.abs(perimeter.children.East.CFrame.Z-(ground.CFrame.Z-(ground.Size.X-3)/2))<.00001,"Rotated ground did not rotate boundary")
	local foreign=instance("Folder","AK_AuditPerimeter");workspace.children.AK_AuditPerimeter=foreign
	environment.warn=function() end
	service:EnsurePerimeterBoundary()
	assert(workspace.children.AK_AuditPerimeter==foreign and next(foreign.children)==nil,"Unmanaged boundary content was changed")
	print("AuthoredWorld.spec: four visible safe-edge walls, support height/corner fit, idempotence, rotation, unmanaged content preserved")
	-- A source-only build still uses its portable mapped fallback.
	workspace.children.Meadow=nil
	local fallback=loadSource("WorldService",environment)
	local generated=false
	fallback.BuildStaticBiomes=function(_,target) generated=target==world end
	fallback:BuildWorld()
	assert(generated and not fallback.AuthoredMap,"Source-only map fallback was removed")
	print("AuthoredWorld.spec: authored geometry preserved; fallback isolated; prototype loops disabled; portable fallback retained")
end
