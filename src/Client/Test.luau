local TestModule = {}
TestModule.__index = TestModule

export type TestModule = {
    Player: Player;
}

function TestModule.new(p: Player): TestModule
    local self = setmetatable({
        Player = p,
    }, TestModule)

    return self
end

return TestModule