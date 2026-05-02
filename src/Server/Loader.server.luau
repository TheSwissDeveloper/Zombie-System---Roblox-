local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local BLACKLIST = {
	"PlayerId",
	"URL",
	"Cmdr",
}

local ANCESTOR_BLACKLIST = {
	"Cmdr",
	"CmdrClient",
}

local LoadedModules = {}

local function IsBlacklisted(name: string): boolean
	return table.find(BLACKLIST, name) ~= nil
end

local function HasBlacklistedAncestor(instance: Instance): boolean
	local current = instance.Parent

	while current and current ~= ServerStorage do
		if table.find(ANCESTOR_BLACKLIST, current.Name) then
			return true
		end
		current = current.Parent
	end

	return false
end

for _, child in pairs(ServerStorage.Modules:GetDescendants()) do
	if child:IsA("ModuleScript") then
		-- Name Blacklist
		if IsBlacklisted(child.Name) then
			warn("[ModuleLoader] Skipped (blacklisted):", child.Name)
			continue
		end

		-- Ancestor Blacklist
		if HasBlacklistedAncestor(child) then
			warn("[ModuleLoader] Skipped (ancestor blacklisted):", child:GetFullName())
			continue
		end

		local success, result = pcall(require, child)
		if success then
			LoadedModules[child.Name] = result
		else
			warn("[ModuleLoader] Fehler beim Laden:", child.Name, result)
		end
	end
end

for name, modul in pairs(LoadedModules) do
	if type(modul.Init) == "function" then
		modul:Init()
	end
end

for name, modul in pairs(LoadedModules) do
	print(name)
	if type(modul.OnStart) == "function" then
		modul:OnStart()
	end
end

function GetService(name)
	return LoadedModules[name]
end
