local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes

local Module = {}
Module.__index = Module

local ToServerEvents = {
	ConsumeStamina = Remotes["0000-2222-1111-3333"],
}

local ToClientEvents = {

}

local ToServerFunctions = {

}

local ToClientFunctions = {

}


function Module:GetEvent(Name: string)
	if ToServerEvents[Name] then
		return ToServerEvents[Name]
	elseif ToClientEvents[Name] then
		return ToClientEvents[Name]
	else
		print("No RemoteEvent with the Name: [", Name, "] found!")
		return nil
	end

end

function Module:GetFunction(Name: string)
	if ToServerFunctions[Name] then
		return ToServerFunctions[Name]
	elseif ToClientFunctions[Name] then
		return ToClientFunctions[Name]
	else
		print("No RemoteFunction with the Name: [", Name, "] found!")
		return nil
	end
end

return Module