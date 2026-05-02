local soundsFolder = game.ReplicatedStorage:WaitForChild("Sounds")

local Sounds = {}

for _, sound in soundsFolder:GetChildren() do
	if sound:IsA("Sound") then
		Sounds[sound.Name] = sound
	end
end

return Sounds