local function cool(value: number)
	assert(typeof(value) == "number", "Cooldown must be a number!")
	local lastCall = 0
	
	return function()
		local now = tick()
		
		
		if now - lastCall < value then
			return false
		end
		
		lastCall = now
		return true
	end
end

return cool