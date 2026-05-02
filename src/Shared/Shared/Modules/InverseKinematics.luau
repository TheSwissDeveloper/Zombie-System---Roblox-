
local InverseKinematics = {}

function InverseKinematics.solve(originCFrame, targetPosition, upperLength, lowerLength, additionalRange)
	local localTarget = originCFrame:PointToObjectSpace(targetPosition)
	local direction = localTarget.Unit
	local distance = localTarget.Magnitude

	if upperLength + lowerLength + additionalRange < distance then
		return nil
	end


	local cross = Vector3.new(0, 0, -1):Cross(direction)
	local angle = math.acos(-direction.Z)
	local targetCFrame = originCFrame * CFrame.fromAxisAngle(cross, angle)

	if distance < math.max(lowerLength, upperLength) - math.min(lowerLength, upperLength) then
		return {
			targetCFrame * CFrame.new(0, 0, math.max(lowerLength, upperLength) - math.min(lowerLength, upperLength) - distance),
			-math.pi / 2,
			math.pi
		}
	end

	if upperLength + lowerLength < distance then
		return {
			targetCFrame,
			math.pi / 2,
			0
		}
	end


	local shoulderAngle = -math.acos(
		(-lowerLength^2 + upperLength^2 + distance^2) / (2 * upperLength * distance)
	)

	local elbowAngle = math.acos(
		(lowerLength^2 - upperLength^2 + distance^2) / (2 * lowerLength * distance)
	)

	return {
		targetCFrame,
		shoulderAngle + math.pi / 2,
		elbowAngle - shoulderAngle
	}
end

return InverseKinematics