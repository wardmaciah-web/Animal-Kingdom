local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local EventDefinitions = require(ReplicatedStorage.Shared.EventDefinitions)

-- Production timings apply to automatic AND administrator-started events.
-- Fast cycles belong in the test scheduler, never in the shipped service.
local TEST_MODE = false
local BREAK_DURATION = 5 * 60
local EVENT_DURATION = 7 * 60

local WeatherEventService = Knit.CreateService({ Name = "WeatherEventService", Client = {} })
local random = Random.new()
local timerVersion = 0
local started = false
local stateFolder

WeatherEventService.CurrentPhase = "Break"
WeatherEventService.CurrentEventId = ""
WeatherEventService.CurrentEventStartTime = 0
WeatherEventService.CurrentEventEndTime = 0
WeatherEventService.BreakEndTime = 0
WeatherEventService.PreviousAutomaticEventId = nil
WeatherEventService.AutomaticEventsPaused = false
WeatherEventService.QueuedEventId = ""
WeatherEventService.QueueRevision = 0

local function durationFor(definition)
	return definition.Duration or EVENT_DURATION
end

local function publishState(self)
	-- The folder is created before the first transition; its attributes are the join snapshot.
	stateFolder:SetAttribute("Phase", self.CurrentPhase)
	stateFolder:SetAttribute("EventId", self.CurrentEventId)
	stateFolder:SetAttribute("EventName", self.CurrentEventId ~= "" and EventDefinitions[self.CurrentEventId].DisplayName or "")
	stateFolder:SetAttribute("StartedAt", self.CurrentEventStartTime)
	stateFolder:SetAttribute("EndsAt", self.CurrentEventEndTime)
	stateFolder:SetAttribute("BreakEndsAt", self.BreakEndTime)
	stateFolder:SetAttribute("AutomaticPaused", self.AutomaticEventsPaused)
	stateFolder:SetAttribute("QueuedEventId", self.QueuedEventId)
	stateFolder:SetAttribute("QueueRevision", self.QueueRevision)
	stateFolder:SetAttribute("TestMode", TEST_MODE)
	stateFolder:SetAttribute("BreakDuration", BREAK_DURATION)
	stateFolder:SetAttribute("EventDuration", EVENT_DURATION)
end

local function invalidateTimer()
	timerVersion += 1
	return timerVersion
end

function WeatherEventService:OnEventStarted(_definition)
	-- Future server-side effects attach here.
end

function WeatherEventService:OnEventEnded(_definition)
	-- Future server-side cleanup attaches here.
end

function WeatherEventService:GetCurrentState()
	return {
		Phase = self.CurrentPhase,
		EventId = self.CurrentEventId,
		EventName = self.CurrentEventId ~= "" and EventDefinitions[self.CurrentEventId].DisplayName or "",
		StartedAt = self.CurrentEventStartTime,
		EndsAt = self.CurrentEventEndTime,
		BreakEndsAt = self.BreakEndTime,
		AutomaticPaused = self.AutomaticEventsPaused,
		QueuedEventId = self.QueuedEventId,
		QueueRevision = self.QueueRevision,
	}
end

function WeatherEventService:SelectRandomAutomaticEvent()
	local totalWeight = 0
	for id, definition in pairs(EventDefinitions) do
		if definition.IsAutomatic and id ~= self.PreviousAutomaticEventId and definition.Weight > 0 then
			totalWeight += definition.Weight
		end
	end
	assert(totalWeight > 0, "No eligible automatic weather events")
	local roll = random:NextInteger(1, totalWeight)
	for id, definition in pairs(EventDefinitions) do
		if definition.IsAutomatic and id ~= self.PreviousAutomaticEventId and definition.Weight > 0 then
			roll -= definition.Weight
			if roll <= 0 then
				return id
			end
		end
	end
	error("Automatic weather event selection failed")
end

function WeatherEventService:StartBreak()
	assert(started, "WeatherEventService has not started")
	local version = invalidateTimer()
	self.CurrentPhase = "Break"
	self.CurrentEventId = ""
	self.CurrentEventStartTime = 0
	self.CurrentEventEndTime = 0
	self.BreakEndTime = workspace:GetServerTimeNow() + BREAK_DURATION
	publishState(self)
	print("[WeatherEventService] Break started - " .. BREAK_DURATION .. " seconds")
	task.delay(BREAK_DURATION, function()
		if version ~= timerVersion or self.CurrentPhase ~= "Break" then return end
		self.BreakEndTime = 0
		publishState(self)
		if not self.AutomaticEventsPaused then
			self:_StartAutomaticEvent()
		end
	end)
end

function WeatherEventService:StartEvent(eventId, isAutomatic)
	assert(started, "WeatherEventService has not started")
	local definition = EventDefinitions[eventId]
	assert(definition, "Unknown weather event: " .. tostring(eventId))
	if isAutomatic then
		assert(definition.IsAutomatic, "Secret events cannot start automatically")
	end
	local version = invalidateTimer()
	if self.CurrentPhase == "Event" then
		local oldDefinition = EventDefinitions[self.CurrentEventId]
		print("[WeatherEventService] Ending event: " .. oldDefinition.DisplayName)
		self:OnEventEnded(oldDefinition)
	end
	local now = workspace:GetServerTimeNow()
	local duration = durationFor(definition)
	self.CurrentPhase = "Event"
	self.CurrentEventId = eventId
	self.CurrentEventStartTime = now
	self.CurrentEventEndTime = now + duration
	self.BreakEndTime = 0
	if isAutomatic then
		self.PreviousAutomaticEventId = eventId
	end
	publishState(self)
	print("[WeatherEventService] Starting event: " .. definition.DisplayName .. " - " .. duration .. " seconds")
	self:OnEventStarted(definition)
	task.delay(duration, function()
		if version ~= timerVersion or self.CurrentPhase ~= "Event" then return end
		self:EndCurrentEvent()
	end)
end

function WeatherEventService:_StartAutomaticEvent()
	if self.AutomaticEventsPaused or self.CurrentPhase ~= "Break" then return end
	if self:_StartQueuedEvent() then return end
	self:StartRandomAutomaticEvent()
end

function WeatherEventService:QueueEvent(eventId)
	if type(eventId) ~= "string" or not EventDefinitions[eventId] then return false end
	self.QueuedEventId = eventId
	self.QueueRevision += 1
	publishState(self)
	return true
end

function WeatherEventService:ClearQueue()
	self.QueuedEventId = ""
	self.QueueRevision += 1
	publishState(self)
end

function WeatherEventService:_StartQueuedEvent()
	local eventId = self.QueuedEventId
	if eventId == "" then return false end
	-- Consume before starting so callbacks cannot replay the queued event.
	self.QueuedEventId = ""
	self.QueueRevision += 1
	self:StartEvent(eventId)
	return true
end

function WeatherEventService:StartRandomAutomaticEvent()
	local eventId = self:SelectRandomAutomaticEvent()
	self:StartEvent(eventId, true)
	return eventId
end

function WeatherEventService:EndCurrentEvent()
	if not started or self.CurrentPhase ~= "Event" then return end
	invalidateTimer()
	local definition = EventDefinitions[self.CurrentEventId]
	print("[WeatherEventService] Ending event: " .. definition.DisplayName)
	self:OnEventEnded(definition)
	-- Explicitly queued events follow the current event immediately. An automatic
	-- pause holds the queue until automatic weather is resumed.
	self.CurrentPhase = "Break"
	if not self.AutomaticEventsPaused and self:_StartQueuedEvent() then return end
	self:StartBreak()
end

function WeatherEventService:EmergencyReset()
	invalidateTimer()
	if self.CurrentPhase == "Event" then
		self:OnEventEnded(EventDefinitions[self.CurrentEventId])
	end
	self.QueuedEventId = ""
	self.QueueRevision += 1
	self.AutomaticEventsPaused = false
	-- Publishing Break invokes the existing client visual cleanup; its normal
	-- timer restarts the cycle. No Lighting objects are touched here.
	self:StartBreak()
end

function WeatherEventService:PauseAutomaticEvents()
	if self.AutomaticEventsPaused then return end
	self.AutomaticEventsPaused = true
	publishState(self)
	print("[WeatherEventService] Automatic events paused")
end

function WeatherEventService:ResumeAutomaticEvents()
	if not self.AutomaticEventsPaused then return end
	self.AutomaticEventsPaused = false
	publishState(self)
	print("[WeatherEventService] Automatic events resumed")
	if self.CurrentPhase == "Break" and self.BreakEndTime == 0 then
		self:_StartAutomaticEvent()
	end
end

function WeatherEventService:Start()
	if started then return end
	started = true
	stateFolder = ReplicatedStorage:FindFirstChild("WeatherState")
	if not stateFolder then
		stateFolder = Instance.new("Folder")
		stateFolder.Name = "WeatherState"
	end
	assert(stateFolder:IsA("Folder"), "WeatherState must be a Folder")
	self:StartBreak()
	stateFolder.Parent = ReplicatedStorage
end

function WeatherEventService:KnitStart()
	self:Start()
end

return WeatherEventService
