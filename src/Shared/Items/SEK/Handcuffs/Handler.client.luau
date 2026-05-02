local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tool = script.Parent
local localPlayer = Players.LocalPlayer
local prompts = {}
local currentTarget = nil

local function onEquipped()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local character = player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp and not hrp:FindFirstChild("HandcuffSystem") then
					local prompt = Instance.new("ProximityPrompt")
					prompt.Name = "HandcuffSystem"
					prompt.ObjectText = player.Name
					prompt.ActionText = "Festnehmen"
					prompt.HoldDuration = 4
					prompt.RequiresLineOfSight = false
					prompt.MaxActivationDistance = 6
					prompt.Parent = hrp
					prompt.Triggered:Connect(function()
						
						if player:GetAttribute("Cuffed") then return end
						if not player:GetAttribute("Crime") then return end
						currentTarget = player
						ReplicatedStorage.CuffSystem.Remotes.Communication:FireServer({
							Target = player,
							Type = "Cuff"
						})
						
						prompt.Enabled = false
						
					end)

					table.insert(prompts, prompt)
				end
			end
		end
	end
end

local function onUnequipped()
	if currentTarget then
		ReplicatedStorage.CuffSystem.Remotes.Communication:FireServer({
			Target = currentTarget,
			Type = "Uncuff"
		})
		currentTarget = nil
	end

	for _, prompt in ipairs(prompts) do
		if prompt and prompt.Parent then
			prompt:Destroy()
		end
	end
	table.clear(prompts)
end

Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)


Players.LocalPlayer.ChildAdded:Connect(function(child: Instance) 
	if child.Name == "CuffedPlayer" then
		local CuffedPlayer: ObjectValue = child
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "HandcuffSystem"
		prompt.ObjectText = CuffedPlayer.Value.Name
		prompt.ActionText = "Inhaftieren"
		prompt.HoldDuration = 1
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 6
		prompt.Parent = workspace.Jail.JailInteractive
		prompt.Triggered:Connect(function(player: Player) 
			ReplicatedStorage.CuffSystem.Remotes.Communication:FireServer({
				Target = player:FindFirstChild("CuffedPlayer").Value,
				Type = "Jail"
			})
		end)
	end	
end)

Players.LocalPlayer.ChildRemoved:Connect(function(child: Instance) 
	if child.Name == "CuffedPlayer" then
		if workspace.Jail.JailInteractive:FindFirstChild("HandcuffSystem") then
			workspace.Jail.JailInteractive.HandCuffSystem:Destroy()
		end
	end	
end)
