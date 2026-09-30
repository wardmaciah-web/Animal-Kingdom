-- Bounds and placement for visual CLONES. Authored templates and world geometry stay intact.
local Geometry = {}
local EPSILON = 0.001

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Geometry.Number(value, fallback, minimum, maximum)
	return finite(value) and math.clamp(value, minimum, maximum) or fallback
end

function Geometry.Rotation(value)
	if typeof(value) == "CFrame" then
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
		if not (finite(x) and finite(y) and finite(z)
			and finite(r00) and finite(r01) and finite(r02)
			and finite(r10) and finite(r11) and finite(r12)
			and finite(r20) and finite(r21) and finite(r22)) then return CFrame.new() end
		return value.Rotation
	elseif typeof(value) == "Vector3" then
		return CFrame.Angles(
			math.rad(Geometry.Number(value.X, 0, -360, 360)),
			math.rad(Geometry.Number(value.Y, 0, -360, 360)),
			math.rad(Geometry.Number(value.Z, 0, -360, 360))
		)
	elseif finite(value) then
		return CFrame.Angles(0, math.rad(math.clamp(value, -360, 360)), 0)
	end
	return CFrame.new()
end

function Geometry.ContextRotation(definition, context)
	return Geometry.Rotation(definition and (definition[context .. "Rotation"] or definition.ModelRotation))
end

local function result(minimum, maximum)
	local corners = {}
	for _, x in ipairs({ minimum.X, maximum.X }) do
		for _, y in ipairs({ minimum.Y, maximum.Y }) do
			for _, z in ipairs({ minimum.Z, maximum.Z }) do
				table.insert(corners, Vector3.new(x, y, z))
			end
		end
	end
	return { Min = minimum, Max = maximum, Size = maximum - minimum, Center = (minimum + maximum) / 2, Corners = corners }
end

function Geometry.IsVisiblePart(part)
	return part:IsA("BasePart") and part.Transparency < 0.99 and part:GetAttribute("PetBoundsIgnore") ~= true
end

function Geometry.Measure(model, reference)
	reference = reference or model:GetPivot()
	local minimum = Vector3.new(math.huge, math.huge, math.huge)
	local maximum = -minimum
	local count = 0
	local parts = model:GetDescendants()
	if model:IsA("BasePart") then table.insert(parts, model) end
	for _, part in ipairs(parts) do
		if Geometry.IsVisiblePart(part) then
			local transform = reference:ToObjectSpace(part.CFrame)
			for _, x in ipairs({ -1, 1 }) do for _, y in ipairs({ -1, 1 }) do for _, z in ipairs({ -1, 1 }) do
				local point = transform:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2)
				if not finite(point.X) or not finite(point.Y) or not finite(point.Z) then return nil end
				minimum = minimum:Min(point)
				maximum = maximum:Max(point)
			end end end
			count += 1
		end
	end
	if count == 0 then return nil end
	local bounds = result(minimum, maximum)
	if math.min(bounds.Size.X, bounds.Size.Y, bounds.Size.Z) < EPSILON then return nil end
	return bounds
end

-- The projection of an axis-aligned box is its rotated center plus the absolute
-- rotation matrix times its half extents. This is exactly the eight-corner bound,
-- including pitch and roll, without allocating corner arrays in the frame loop.
local function rotatedExtents(bounds, rotation)
	local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = rotation:GetComponents()
	local center, size = bounds.Center, bounds.Size
	local x, y, z = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
	return Vector3.new(
		r00 * center.X + r01 * center.Y + r02 * center.Z,
		r10 * center.X + r11 * center.Y + r12 * center.Z,
		r20 * center.X + r21 * center.Y + r22 * center.Z
	), Vector3.new(
		math.abs(r00) * x + math.abs(r01) * y + math.abs(r02) * z,
		math.abs(r10) * x + math.abs(r11) * y + math.abs(r12) * z,
		math.abs(r20) * x + math.abs(r21) * y + math.abs(r22) * z
	)
end

function Geometry.RotateBounds(bounds, rotation)
	rotation = Geometry.Rotation(rotation)
	local center, half = rotatedExtents(bounds, rotation)
	return result(center - half, center + half)
end

function Geometry.GroundCFrame(bounds, surfacePosition, rotation, clearance, yOffset)
	rotation = Geometry.Rotation(rotation)
	local center, half = rotatedExtents(bounds, rotation)
	local gap = Geometry.Number(clearance, 0.04, 0, 0.5) + Geometry.Number(yOffset, 0, 0, 3)
	local pivotPosition = surfacePosition + Vector3.new(-center.X, half.Y - center.Y + gap, -center.Z)
	return CFrame.new(pivotPosition) * rotation
end

function Geometry.Normalize(model, definition, context)
	local bounds = Geometry.Measure(model)
	if not bounds then return nil end
	context = context or "Follower"
	local target = context == "Garden" and 3.2 or 2.8
	local multiplier = Geometry.Number(definition and definition[context .. "Scale"], 1, 0.25, 4)
	local ratio = target * multiplier / math.max(bounds.Size.X, bounds.Size.Y, bounds.Size.Z)
	model:ScaleTo(math.clamp(model:GetScale() * ratio, 0.0001, 10000))
	return Geometry.Measure(model)
end

function Geometry.Fit(model, limits, rotation, multiplier)
	local bounds = Geometry.Measure(model)
	if not bounds then return nil end
	local rotated = Geometry.RotateBounds(bounds, rotation)
	local fit = math.min(limits.X / rotated.Size.X, limits.Y / rotated.Size.Y, limits.Z / rotated.Size.Z)
	-- Exceptional overrides may shrink a pet, but never exceed the safe footprint.
	fit *= Geometry.Number(multiplier, 1, 0.25, 1)
	model:ScaleTo(math.clamp(model:GetScale() * fit, 0.0001, 10000))
	return Geometry.Measure(model)
end

return Geometry
