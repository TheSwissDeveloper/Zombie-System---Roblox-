local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Module = {}
Module.__index = Module

local Player = Players.LocalPlayer
local Character: Model = Player.Character or Player.CharacterAdded:Wait()
local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

function Module:OnStart()
	self:start()
end

function Module:start()
	Camera.CameraType = Enum.CameraType.Scriptable

	local pivot = Character:GetPivot()
	local position = pivot.Position + Vector3.new(0, 25, 0)

	Camera.CFrame =
		CFrame.new(position)
		* CFrame.Angles(math.rad(-90), 0, 0)

	
	self:InitalizePlay()
	
end

function Module:ClickedPlay()
	local tween = TweenService:Create(
		Camera,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = Character:GetPivot() + Vector3.new(-5,0,0)}
	)
	

	tween:Play()

	tween.Completed:Wait()
	
	local NewTween = TweenService:Create(
		Camera,
		TweenInfo.new(
			0.6,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{ FieldOfView = 70 }
	)

	NewTween:Play()

	
	Camera.CameraType = Enum.CameraType.Custom
	
end

function Module:InitalizePlay()
	Player.PlayerGui:WaitForChild("StartGui").Enabled = true
	
	Player.PlayerGui:WaitForChild("StartGui"):WaitForChild("Content"):WaitForChild("PlayButton").MouseButton1Click:Once(function()
		Player.PlayerGui:WaitForChild("StartGui").Enabled = false
		self:ClickedPlay()
	end)
end

return Module