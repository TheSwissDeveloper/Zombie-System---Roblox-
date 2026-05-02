local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Sounds = require(game.ReplicatedStorage.Assets.Sounds)

local GARAGE_DOOR_TAG = "Garage Door"

local CONFIG = {
	triggerStartDelay = 0.1,
	checkInterval = 0.25,
	openColor = Color3.fromRGB(0, 255, 0),
	closeColor = Color3.fromRGB(255, 0, 0),
	remoteControlAttribute = "HasRemoteControl",
}

local TEAMS = {
	Citizen = "Citizen",
	Prisoner = "Prisoner",
}

local activeDoors = {}

local function setupWelds(movingParts)
	local mainPart = movingParts:FindFirstChild("Main")
	if not mainPart then 
		warn("setupWelds: Main nicht gefunden in", movingParts:GetFullName())
		return 
	end

	print("=== Setup Welds für", movingParts:GetFullName(), "===")
	print("MainPart:", mainPart.Name, "Anchored:", mainPart.Anchored)

	-- ✅ Prüfe direkte Kinder UND Descendants
	for _, part in movingParts:GetDescendants() do
		if part:IsA("BasePart") and part ~= mainPart then
			print("Gefunden:", part:GetFullName(), "ClassName:", part.ClassName)

			-- ✅ WICHTIG: Main muss anchored sein!
			if not mainPart.Anchored then
				warn("WARNUNG: MainPart ist nicht anchored!")
				mainPart.Anchored = true
			end

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = mainPart
			weld.Part1 = part
			weld.Parent = mainPart
			weld.Name = "Weld_" .. part.Name

			part.Anchored = false
			print("✅ Weld erstellt:", weld.Name)
		end
	end

	-- ✅ Zähle wie viele Welds erstellt wurden
	local weldCount = 0
	for _, child in mainPart:GetChildren() do
		if child:IsA("WeldConstraint") then
			weldCount = weldCount + 1
		end
	end
	print("Total Welds:", weldCount)
end

local function getOpenLights(doorModel)
	local lights = {}
	for _, part in doorModel:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "OpenLight" then
			table.insert(lights, part)
		end
	end
	return lights
end

local function getVehicleFromDescendant(part)
	local current = part
	while current.Parent and current.Parent ~= game do
		current = current.Parent
		if current.Parent == Workspace:FindFirstChild("Vehicles") then
			return current
		end
	end
	return nil
end

local function isSensorTriggered(doorModel, overlapParams)
	local main = doorModel:FindFirstChild("Main")
	if not main then return false end

	local openForPlayers = doorModel:GetAttribute("OpenForPlayers")
	local openForCitizen = doorModel:GetAttribute("OpenForCitizen")

	local filterList = {}

	local vehicles = Workspace:FindFirstChild("Vehicles")
	if vehicles then
		table.insert(filterList, vehicles)
	end

	if openForPlayers then
		for _, character in CollectionService:GetTagged("Character") do
			table.insert(filterList, character)
		end
	end

	overlapParams.FilterDescendantsInstances = filterList

	local parts = Workspace:GetPartBoundsInBox(main.CFrame, main.Size, overlapParams)

	if not openForCitizen then
		for _, part in parts do
			local vehicle = getVehicleFromDescendant(part)
			if vehicle then
				local player = Players:FindFirstChild(vehicle.Name)
				if player then
					local isNotCitizenOrPrisoner = player.Team and 
						player.Team.Name ~= TEAMS.Citizen and 
						player.Team.Name ~= TEAMS.Prisoner

					local isAdminVehicle = vehicle:GetAttribute("IsAdminVehicle") == true

					local hasRemoteControl = false
					if player.Team and player.Team.Name == TEAMS.Citizen then
						hasRemoteControl = player:GetAttribute(CONFIG.remoteControlAttribute) == true
					end

					if isNotCitizenOrPrisoner or isAdminVehicle or hasRemoteControl then
						return true
					end
				end
			end
		end
		return false
	else
		return #parts > 0
	end
end

local function setupDoor(doorModel)
	if activeDoors[doorModel] then
		return
	end

	local main = doorModel:FindFirstChild("Main")
	local movingParts = doorModel:FindFirstChild("MovingParts")

	if not main or not movingParts then
		warn("GarageDoor: Missing Main or MovingParts in", doorModel:GetFullName())
		return
	end

	local opened = main:FindFirstChild("Opened")
	local closed = main:FindFirstChild("Closed")

	if not opened or not closed then
		warn("GarageDoor: Missing Opened or Closed attachment in Main")
		return
	end

	local movingMain = movingParts:FindFirstChild("Main")
	if not movingMain then
		warn("GarageDoor: Missing Main in MovingParts")
		return
	end

	if doorModel:GetAttribute("OpeningDuration") == nil then
		doorModel:SetAttribute("OpeningDuration", 2.25)
	end
	if doorModel:GetAttribute("OpenForPlayers") == nil then
		doorModel:SetAttribute("OpenForPlayers", true)
	end
	if doorModel:GetAttribute("OpenForCitizen") == nil then
		doorModel:SetAttribute("OpenForCitizen", true)
	end
	doorModel:SetAttribute("IsTriggered", false)
	doorModel:SetAttribute("StartTime", 0)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.RespectCanCollide = false  -- ✅ FIX
	overlapParams.MaxParts = 0  -- ✅ FIX (0 = unbegrenzt)

	local openSound = Sounds.GarageDoorOpen:Clone()
	openSound.Parent = main

	local closeSound = Sounds.GarageDoorClose:Clone()
	closeSound.Parent = main

	setupWelds(movingParts)

	activeDoors[doorModel] = {
		overlapParams = overlapParams,
		openSound = openSound,
		closeSound = closeSound,
		openLights = getOpenLights(doorModel),
	}
end

local function cleanupDoor(doorModel)
	activeDoors[doorModel] = nil
end

for _, doorModel in CollectionService:GetTagged(GARAGE_DOOR_TAG) do
	task.spawn(setupDoor, doorModel)
end

CollectionService:GetInstanceAddedSignal(GARAGE_DOOR_TAG):Connect(function(doorModel)
	setupDoor(doorModel)
end)

CollectionService:GetInstanceRemovedSignal(GARAGE_DOOR_TAG):Connect(function(doorModel)
	cleanupDoor(doorModel)
end)

while true do
	task.wait(CONFIG.checkInterval)

	for doorModel, data in activeDoors do
		local openingDuration = doorModel:GetAttribute("OpeningDuration") or 2.25
		local startTime = doorModel:GetAttribute("StartTime") or 0
		local now = Workspace:GetServerTimeNow()

		if startTime + openingDuration > now then
			continue
		end

		local isTriggered = isSensorTriggered(doorModel, data.overlapParams)
		local currentlyTriggered = doorModel:GetAttribute("IsTriggered")

		if currentlyTriggered == isTriggered then
			continue
		end

		local newStartTime = now + CONFIG.triggerStartDelay
		doorModel:SetAttribute("StartTime", newStartTime)
		doorModel:SetAttribute("IsTriggered", isTriggered)

		if isTriggered then
			data.openSound:Play()
		else
			data.closeSound:Play()
		end

		for _, light in data.openLights do
			light.Color = isTriggered and CONFIG.openColor or CONFIG.closeColor
		end
	end
end