local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Sounds = require(game.ReplicatedStorage.Assets.Sounds)

local SLIDING_DOOR_TAG = "Sliding Door"

local CONFIG = {
	triggerStartDelay = 0.1,
	checkInterval = 0.25,
	openedWaitTime = 0.5,
}

local activeDoors = {}

local function setupWelds(doorSide)
	local mainPart = doorSide:FindFirstChild("Main")
	if not mainPart then return end

	for _, part in doorSide:GetDescendants() do
		if part:IsA("BasePart") and part ~= mainPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = mainPart
			weld.Part1 = part
			weld.Parent = mainPart
			part.Anchored = false
		end
	end
end

local function isSensorTriggered(doorModel, overlapParams)
	local sensor = doorModel:FindFirstChild("Sensor")
	if not sensor then return false end

	local filterList = {}

	local vehicles = Workspace:FindFirstChild("Vehicles")
	if vehicles then
		table.insert(filterList, vehicles)
	end

	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(filterList, player.Character)
		end
	end

	overlapParams.FilterDescendantsInstances = filterList

	local parts = Workspace:GetPartBoundsInBox(sensor.CFrame, sensor.Size, overlapParams)
	return #parts > 0
end

local function setupDoor(doorModel)
	if activeDoors[doorModel] then
		return
	end

	local left = doorModel:FindFirstChild("Left")
	local right = doorModel:FindFirstChild("Right")
	local sensor = doorModel:FindFirstChild("Sensor")

	if not left or not right or not sensor then
		warn("SlidingDoor: Missing Left, Right or Sensor in", doorModel:GetFullName())
		return
	end

	local leftMain = left:FindFirstChild("Main")
	local rightMain = right:FindFirstChild("Main")

	if not leftMain or not rightMain then
		warn("SlidingDoor: Missing Main in Left or Right")
		return
	end

	doorModel:SetAttribute("ClosedCFrameLeft", leftMain.CFrame)
	doorModel:SetAttribute("ClosedCFrameRight", rightMain.CFrame)
	doorModel:SetAttribute("IsTriggered", false)
	doorModel:SetAttribute("StartTime", 0)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.RespectCanCollide = true
	overlapParams.MaxParts = 1

	local openSoundName = doorModel:GetAttribute("OpenSound") or "SlidingDoorOpen"
	local closeSoundName = doorModel:GetAttribute("CloseSound") or "SlidingDoorClose"

	local openSound = Sounds[openSoundName]:Clone()
	openSound.Parent = sensor

	local closeSound = Sounds[closeSoundName]:Clone()
	closeSound.Parent = sensor

	setupWelds(left)
	setupWelds(right)

	activeDoors[doorModel] = {
		overlapParams = overlapParams,
		openSound = openSound,
		closeSound = closeSound,
		openedAt = 0,
	}
end

local function cleanupDoor(doorModel)
	activeDoors[doorModel] = nil
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

while true do
	task.wait(CONFIG.checkInterval)

	for doorModel, data in activeDoors do
		local openingDuration = doorModel:GetAttribute("OpeningDuration") or 1
		local startTime = doorModel:GetAttribute("StartTime") or 0
		local currentlyTriggered = doorModel:GetAttribute("IsTriggered")
		local now = Workspace:GetServerTimeNow()

		local animationEndTime = startTime + openingDuration
		local isAnimating = now < animationEndTime

		local isTriggered = isSensorTriggered(doorModel, data.overlapParams)

		if currentlyTriggered == isTriggered then
			if currentlyTriggered and not isAnimating then
				data.openedAt = now
			end
			continue
		end

		if isTriggered then
			-- ÖFFNEN: Kann Schließen unterbrechen (sofort)
			local newStartTime = now + CONFIG.triggerStartDelay
			doorModel:SetAttribute("StartTime", newStartTime)
			doorModel:SetAttribute("IsTriggered", true)
			data.openSound:Play()
		else
			-- SCHLIESSEN: Warte bis komplett offen + Wartezeit
			if isAnimating then
				continue
			end

			if now - data.openedAt < CONFIG.openedWaitTime then
				continue
			end

			local newStartTime = now + CONFIG.triggerStartDelay
			doorModel:SetAttribute("StartTime", newStartTime)
			doorModel:SetAttribute("IsTriggered", false)
			data.closeSound:Play()
		end
	end
end