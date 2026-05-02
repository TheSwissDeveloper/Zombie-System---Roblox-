local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		CollectionService:AddTag(character, "Character")
	end)

	if player.Character then
		CollectionService:AddTag(player.Character, "Character")
	end
end)

for _, player in Players:GetPlayers() do
	if player.Character then
		CollectionService:AddTag(player.Character, "Character")
	end

	player.CharacterAdded:Connect(function(character)
		CollectionService:AddTag(character, "Character")
	end)
end