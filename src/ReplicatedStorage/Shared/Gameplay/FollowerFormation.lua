-- Pure layout and timing rules shared by the renderer and development checks.
local Formation = {FollowSpeed=12,TurnSpeed=9,VelocityLead=.065}

function Formation.Alpha(speed, dt)
	return 1 - math.exp(-speed * math.max(dt, 0))
end

function Formation.Offset(index, count, spacing)
	spacing = math.max(spacing or 3.5, 2.5)
	if count == 1 then return 0, 4.5 end
	if count == 2 then return (index - 1.5) * spacing, 4.5 end
	if count == 3 then
		if index == 1 then return 0, 4.5 end
		return (index - 2.5) * spacing, 4.5 + spacing
	end
	local row = math.floor((index - 1) / 3)
	local columns = math.min(3, count - row * 3)
	local column = (index - 1) % 3
	return (column - (columns - 1) / 2) * spacing, 4.5 + row * spacing
end

function Formation.Phase(uid)
	local value = 0
	for i = 1, #uid do value = (value * 31 + string.byte(uid, i)) % 65521 end
	return value / 65521 * math.pi * 2
end

return Formation
