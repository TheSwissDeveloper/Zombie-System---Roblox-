local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Module = {}
Module.__index = Module

local player = Players.LocalPlayer

function Module:OnStart()
	Module.construct()
end

function Module.construct()
	local self = setmetatable({}, Module)
	
	self.character = player.Character or player.CharacterAdded:Wait()
	self.lastUsed = 0
	self.canRun = true
	self.holdRun = false
	
	self.originalJumpHeight = nil
	
	self.runConn = nil
	self.runTween = false
	
	player.CharacterAdded:Connect(function(character)
		self.character = character
		self.originalJumpHeight = character:WaitForChild("Humanoid").JumpHeight
	end)
	
	return self
end

function Module:start()
	self:RunListener()
end

function Module:RunListener()
	self.runConn = UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		
	end)
end

return Module