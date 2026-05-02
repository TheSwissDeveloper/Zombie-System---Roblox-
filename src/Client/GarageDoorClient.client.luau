local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GARAGE_DOOR_TAG = "Garage Door"

local CONFIG = {
	maxCameraDistance = 250,
}

local activeDoors = {}

local function isCameraDistance(doorModel)
	local main = doorModel:FindFirstChild("Main")
	if not main then return false end
	local camera = Workspace.CurrentCamera
	if not camera then return false end
	return (camera.CFrame.Position - main.Position).Magnitude < CONFIG.maxCameraDistance
end

local function onTriggered(doorModel, isTriggered)
	print("🔔 onTriggered CALLED!", doorModel.Name, "Triggered:", isTriggered)

	local data = activeDoors[doorModel]
	if not data then 
		warn("❌ No data for door!")
		return 
	end

	if data.animationConnection then
		data.animationConnection:Disconnect()
		data.animationConnection = nil
		print("   Stopped old animation")
	end

	if data.lockConnection then
		data.lockConnection:Disconnect()
		data.lockConnection = nil
		print("   Stopped old lock")
	end

	local inRange = isCameraDistance(doorModel)
	print("   Camera in range:", inRange)

	if not inRange then
		print("   ⚠️ Too far from camera, skipping animation")
		return
	end

	local main = doorModel:FindFirstChild("Main")
	local movingParts = doorModel:FindFirstChild("MovingParts")

	if not main or not movingParts then 
		warn("❌ Missing main or movingParts!")
		return 
	end

	local opened = main:FindFirstChild("Opened")
	local closed = main:FindFirstChild("Closed")

	if not opened or not closed then 
		warn("❌ Missing opened or closed!")
		return 
	end

	local movingMain = movingParts:FindFirstChild("Main")
	if not movingMain then 
		warn("❌ Missing movingMain!")
		return 
	end

	print("✅ All parts found")
	print("   MovingMain Anchored:", movingMain.Anchored)
	print("   MovingMain CanCollide:", movingMain.CanCollide)

	-- ✅ WICHTIG: Unanchor!
	movingMain.Anchored = false

	local startCFrame = movingMain.CFrame
	local endCFrame = isTriggered and opened.WorldCFrame or closed.WorldCFrame

	print("   Start Pos:", startCFrame.Position)
	print("   End Pos:", endCFrame.Position)
	print("   Distance:", (endCFrame.Position - startCFrame.Position).Magnitude)

	local openingDuration = doorModel:GetAttribute("OpeningDuration") or 2.25
	local startTime = doorModel:GetAttribute("StartTime") or 0
	local endTime = startTime + openingDuration

	print("   Duration:", openingDuration)
	print("   Start Time:", startTime)
	print("   End Time:", endTime)
	print("   Server Time Now:", Workspace:GetServerTimeNow())

	local frameCount = 0

	data.animationConnection = RunService.Heartbeat:Connect(function()
		frameCount = frameCount + 1

		local currentTime = Workspace:GetServerTimeNow()

		if currentTime <= startTime then
			if frameCount % 30 == 0 then
				print("   ⏳ Waiting for start time...")
			end
			return
		end

		local remaining = endTime - currentTime
		local alpha = math.clamp(1 - remaining / openingDuration, 0, 1)
		alpha = TweenService:GetValue(alpha, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

		local newCFrame = startCFrame:Lerp(endCFrame, alpha)
		movingMain.CFrame = newCFrame

		if frameCount % 10 == 0 or alpha == 0 or alpha >= 0.99 then
			print(string.format("   🎬 Frame %d | Alpha: %.3f | Y: %.1f", 
				frameCount, alpha, newCFrame.Position.Y))
		end

		if currentTime >= endTime then
			print("✅ Animation complete!")

			if data.animationConnection then
				data.animationConnection:Disconnect()
				data.animationConnection = nil
			end

			data.lockConnection = RunService.Heartbeat:Connect(function()
				movingMain.CFrame = endCFrame
			end)
		end
	end)

	print("🎬 Animation started!")
end

local function setupDoor(doorModel)
	print("📋 Setup door:", doorModel.Name)

	if activeDoors[doorModel] then
		print("   Already active")
		return
	end

	local main = doorModel:WaitForChild("Main")
	local movingParts = doorModel:WaitForChild("MovingParts")

	if not main or not movingParts then
		warn("❌ Missing parts for", doorModel.Name)
		return
	end

	activeDoors[doorModel] = {
		animationConnection = nil,
		lockConnection = nil,
	}

	print("✅ Door registered:", doorModel.Name)

	-- ✅ Prüfe initial state
	local isTriggered = doorModel:GetAttribute("IsTriggered")
	print("   Initial IsTriggered:", isTriggered)

	doorModel:GetAttributeChangedSignal("IsTriggered"):Connect(function()
		local newTriggered = doorModel:GetAttribute("IsTriggered")
		print("🚨 ATTRIBUTE CHANGED! IsTriggered:", newTriggered)
		onTriggered(doorModel, newTriggered)
	end)
end

local function cleanupDoor(doorModel)
	print("🗑️ Cleanup door:", doorModel.Name)
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

print("🚪 Garage Door Client initializing...")

for _, doorModel in CollectionService:GetTagged(GARAGE_DOOR_TAG) do
	task.spawn(setupDoor, doorModel)
end

CollectionService:GetInstanceAddedSignal(GARAGE_DOOR_TAG):Connect(function(doorModel)
	setupDoor(doorModel)
end)

CollectionService:GetInstanceRemovedSignal(GARAGE_DOOR_TAG):Connect(function(doorModel)
	cleanupDoor(doorModel)
end)

print("✅ Garage Door Client ready")