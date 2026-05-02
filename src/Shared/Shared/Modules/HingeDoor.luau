local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Sounds = require(game.ReplicatedStorage.Assets.Sounds)

local HINGE_DOOR_TAG = "Hinge Door"
local HAND_TARGET_TAG = "Character Hand Target"
local ANGLE_THRESHOLD = 3

local activeDoors = {}

local function setupDoor(doorModel)
	if activeDoors[doorModel] then
		return
	end

	local door = doorModel:FindFirstChild("Door")
	local frame = doorModel:FindFirstChild("Frame")

	if not door or not frame then
		warn("HingeDoor: Missing Door or Frame in", doorModel:GetFullName())
		return
	end

	local doorMainPart = door:FindFirstChild("MainPart")

	if not doorMainPart then
		warn("HingeDoor: Missing MainPart in Door")
		return
	end

	local hingeConstraint = doorMainPart:FindFirstChild("HingeConstraint")
	local springConstraint = doorMainPart:FindFirstChild("SpringConstraint")

	if not hingeConstraint or not springConstraint then
		warn("HingeDoor: Missing HingeConstraint or SpringConstraint")
		return
	end

	for _, part in frame:GetDescendants() do
		if part:IsA("BasePart") then
			local canCollide = part:GetAttribute("CanCollide")
			local transparency = part:GetAttribute("Transparency")

			part.CanCollide = type(canCollide) == "boolean" and canCollide or false
			part.Transparency = type(transparency) == "number" and transparency or 0
		end
	end

	local clientDoor = door:Clone()
	clientDoor.Name = "ClientDoor"
	clientDoor.Parent = doorModel

	local clientMainPart = clientDoor.MainPart

	for _, part in clientDoor:GetDescendants() do
		if part:IsA("BasePart") then
			local canCollide = part:GetAttribute("CanCollide")
			local transparency = part:GetAttribute("Transparency")
			local isDoorknob = part:GetAttribute("IsDoorknob")

			part.CanCollide = type(canCollide) == "boolean" and canCollide or false
			part.Transparency = type(transparency) == "number" and transparency or 0

			if isDoorknob == true then
				part:AddTag(HAND_TARGET_TAG)
			end

			part.Anchored = false

			if part ~= clientMainPart then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = clientMainPart
				weld.Part1 = part
				weld.Parent = clientMainPart
			end
		end
	end

	clientMainPart.HingeConstraint.Enabled = true
	clientMainPart.SpringConstraint.Enabled = true

	local openSoundName = doorModel:GetAttribute("OpenSound") or "HDoorOpen"
	local closeSoundName = doorModel:GetAttribute("CloseSound") or "HDoorClose"

	local openSound = Sounds[openSoundName]:Clone()
	openSound.Parent = clientMainPart

	local closeSound = Sounds[closeSoundName]:Clone()
	closeSound.Parent = clientMainPart

	activeDoors[doorModel] = {
		hinge = clientMainPart.HingeConstraint,
		openSound = openSound,
		closeSound = closeSound,
		isOpened = false,
	}
end

local function cleanupDoor(doorModel)
	local data = activeDoors[doorModel]
	if data then
		local clientDoor = doorModel:FindFirstChild("ClientDoor")
		if clientDoor then
			clientDoor:Destroy()
		end
		activeDoors[doorModel] = nil
	end
end

for _, doorModel in CollectionService:GetTagged(HINGE_DOOR_TAG) do
	task.spawn(setupDoor, doorModel)
end

CollectionService:GetInstanceAddedSignal(HINGE_DOOR_TAG):Connect(function(doorModel)
	setupDoor(doorModel)
end)

CollectionService:GetInstanceRemovedSignal(HINGE_DOOR_TAG):Connect(function(doorModel)
	cleanupDoor(doorModel)
end)

RunService.Heartbeat:Connect(function()
	for doorModel, data in activeDoors do
		local currentAngle = math.abs(data.hinge.CurrentAngle)

		if currentAngle > ANGLE_THRESHOLD and not data.isOpened then
			data.isOpened = true
			data.openSound:Play()
		elseif currentAngle <= ANGLE_THRESHOLD and data.isOpened then
			data.isOpened = false
			data.closeSound:Play()
		end
	end
end)

return {
	setupDoor = setupDoor,
	cleanupDoor = cleanupDoor,
	activeDoors = activeDoors,
}