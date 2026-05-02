
local CollectionService = game:GetService("CollectionService")

local HAND_TARGET_TAG = "Character Hand Target"

local HandTargets = {}
HandTargets.targets = CollectionService:GetTagged(HAND_TARGET_TAG)

CollectionService:GetInstanceAddedSignal(HAND_TARGET_TAG):Connect(function(instance)
	table.insert(HandTargets.targets, instance)
end)

CollectionService:GetInstanceRemovedSignal(HAND_TARGET_TAG):Connect(function(instance)
	local index = table.find(HandTargets.targets, instance)
	if index then
		table.remove(HandTargets.targets, index)
	end
end)

return HandTargets