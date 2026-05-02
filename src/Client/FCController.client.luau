-- FreeCam Controller

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local GROUP_ID = 35715257
local RANKS = {"Moderator", "Ingame Moderator"}

local function hasPermission()
	return LocalPlayer:IsInGroup(GROUP_ID) and table.find(RANKS, LocalPlayer:GetRoleInGroup(GROUP_ID)) ~= nil
end

if hasPermission() then
	local freecam = ReplicatedStorage:FindFirstChild("Freecam")
	if freecam then
		freecam:Clone().Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end