
--DBR = DELETE Before RELEASE





local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Module = {}
Module.__index = Module
--//..  ``
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
--..
local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
--//..  ``
local CurrentSpeed = 16
local dsB = 2
local dsA = 8
local DefaultSpeed = 16
local osA = 25
local osB = 50
local osC = 200

-- Geschwindigkeitsstufen in einer Tabelle
local SpeedLevels = {dsB, dsA, DefaultSpeed, osA, osB, osC}
local CurrentSpeedIndex = 3 -- Startet bei DefaultSpeed (16)

function Module:OnStart()
	warn("--[DevMovement]--", ":init...")

	--//..  ``
	Module:start()
	Module.Listener()
end

function Module:start()
	-- Setze die Startgeschwindigkeit
	Humanoid.WalkSpeed = SpeedLevels[CurrentSpeedIndex]
	CurrentSpeed = SpeedLevels[CurrentSpeedIndex]
end

function Module.Listener()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end

		-- Pfeiltaste Rechts: Geschwindigkeit erhöhen
		if input.KeyCode == Enum.KeyCode.F6 then
			if CurrentSpeedIndex < #SpeedLevels then
				CurrentSpeedIndex = CurrentSpeedIndex + 1
				CurrentSpeed = SpeedLevels[CurrentSpeedIndex]
				Humanoid.WalkSpeed = CurrentSpeed
				print("Geschwindigkeit erhöht auf:", CurrentSpeed)
			else
				print("Maximale Geschwindigkeit erreicht!")
			end
		end

		-- Pfeiltaste Links: Geschwindigkeit verringern
		if input.KeyCode == Enum.KeyCode.F5 then
			if CurrentSpeedIndex > 1 then
				CurrentSpeedIndex = CurrentSpeedIndex - 1
				CurrentSpeed = SpeedLevels[CurrentSpeedIndex]
				Humanoid.WalkSpeed = CurrentSpeed
				print("Geschwindigkeit verringert auf:", CurrentSpeed)
			else
				print("Minimale Geschwindigkeit erreicht!")
			end
		end

		-- Pfeiltaste Unten: Zurück auf Standardgeschwindigkeit
		if input.KeyCode == Enum.KeyCode.Down then
			CurrentSpeedIndex = 3 -- Index für DefaultSpeed
			CurrentSpeed = SpeedLevels[CurrentSpeedIndex]
			Humanoid.WalkSpeed = CurrentSpeed
			print("Geschwindigkeit zurückgesetzt auf Standard:", CurrentSpeed)
		end
	end)
end

return Module