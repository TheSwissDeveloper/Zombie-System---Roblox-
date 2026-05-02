local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SLIDING_DOOR_TAG = "Sliding Door"

local CONFIG = {
	maxCameraDistance = 175,
}

local activeDoors = {}

local function isCameraDistance(doorModel)
	local sensor = doorModel:FindFirstChild("Sensor")
	if not sensor then return false end

	local camera = Workspace.CurrentCamera
	if not camera then return false end

	return (camera.CFrame.Position - sensor.Position).Magnitude < CONFIG.maxCameraDistance
end

local function getCFrameLeft(doorModel, opened)
	local closedCFrame = doorModel:GetAttribute("ClosedCFrameLeft")
	if not closedCFrame then return nil end

	local openingDistance = doorModel:GetAttribute("OpeningDistance") or 3

	if opened then
		return closedCFrame * CFrame.new(0, 0, openingDistance)
	else
		return closedCFrame
	end
end

local function getCFrameRight(doorModel, opened)
	local closedCFrame = doorModel:GetAttribute("ClosedCFrameRight")
	if not closedCFrame then return nil end

	local openingDistance = doorModel:GetAttribute("OpeningDistance") or 3

	if opened then
		return closedCFrame * CFrame.new(0, 0, -openingDistance)
	else
		return closedCFrame
	end
end

local function onTriggered(doorModel, isTriggered)
	local data = activeDoors[doorModel]
	if not data then return end

	if data.animationConnection then
		data.animationConnection:Disconnect()
		data.animationConnection = nil
	end

	if data.lockConnection then
		data.lockConnection:Disconnect()
		data.lockConnection = nil
	end

	if not isCameraDistance(doorModel) then
		return
	end

	local left = doorModel:FindFirstChild("Left")
	local right = doorModel:FindFirstChild("Right")
	if not left or not right then return end

	local leftMain = left:FindFirstChild("Main")
	local rightMain = right:FindFirstChild("Main")
	if not leftMain or not rightMain then return end

	local startCFrameLeft = leftMain.CFrame
	local startCFrameRight = rightMain.CFrame

	local endCFrameLeft = getCFrameLeft(doorModel, isTriggered)
	local endCFrameRight = getCFrameRight(doorModel, isTriggered)

	if not endCFrameLeft or not endCFrameRight then return end

	local openingDuration = doorModel:GetAttribute("OpeningDuration") or 1
	local startTime = doorModel:GetAttribute("StartTime") or 0
	local endTime = startTime + openingDuration

	data.animationConnection = RunService.Heartbeat:Connect(function()
		local currentTime = Workspace:GetServerTimeNow()

		if currentTime <= startTime then
			return
		end

		local remaining = endTime - currentTime
		local alpha = math.clamp(1 - remaining / openingDuration, 0, 1)
		alpha = TweenService:GetValue(alpha, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

		leftMain.CFrame = startCFrameLeft:Lerp(endCFrameLeft, alpha)
		rightMain.CFrame = startCFrameRight:Lerp(endCFrameRight, alpha)

		if currentTime >= endTime then
			if data.animationConnection then
				data.animationConnection:Disconnect()
				data.animationConnection = nil
			end

			data.lockConnection = RunService.Heartbeat:Connect(function()
				leftMain.CFrame = endCFrameLeft
				rightMain.CFrame = endCFrameRight
			end)
		end
	end)
end

local function setupDoor(doorModel)
	if activeDoors[doorModel] then
		return
	end

	local left = doorModel:FindFirstChild("Left")
	local right = doorModel:FindFirstChild("Right")
	local sensor = doorModel:FindFirstChild("Sensor")

	if not left or not right or not sensor then
		return
	end

	activeDoors[doorModel] = {
		animationConnection = nil,
		lockConnection = nil,
	}

	doorModel:GetAttributeChangedSignal("IsTriggered"):Connect(function()
		local isTriggered = doorModel:GetAttribute("IsTriggered")
		onTriggered(doorModel, isTriggered)
	end)
end

local function cleanupDoor(doorModel)
	local data = activeDoors[doorModel]
	if data then
		if data.animationConnection then
			data.animationConnection:Disconnect()
		end
		if data.lockConnection then
			data.lockConnection:Disconnect()
		end
		activeDoors[doorModel] = nil
	end
end

for _, doorModel in CollectionService:GetTagged(SLIDING_DOOR_TAG) do
	task.spawn(setupDoor, doorModel)
end

CollectionService:GetInstanceAddedSignal(SLIDING_DOOR_TAG):Connect(function(doorModel)
	setupDoor(doorModel)
end)

CollectionService:GetInstanceRemovedSignal(SLIDING_DOOR_TAG):Connect(function(doorModel)
	cleanupDoor(doorModel)
end)