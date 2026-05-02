local StateMachine = {}
StateMachine.__index = StateMachine

export type State = "Idle" | "Running" | "Stunned" | "Injured"

-- Definiere erlaubte Übergänge (Welcher State darf in welchen wechseln?)
-- Das verhindert Bugs (z.B. Rennen, während man eigentlich betäubt ist)
local ValidTransitions: { [State]: {State} } = {
    ["Idle"] = {"Running", "Stunned", "Injured"},
    ["Running"] = {"Idle", "Stunned", "Injured"},
    ["Stunned"] = {"Idle", "Injured"}, -- Aus Stunned kann man nicht direkt rennen
    ["Injured"] = {"Idle", "Stunned"}  -- Aus Injured muss man sich erst erholen (Idle)
}

export type StateMachine = typeof(setmetatable({} :: {
    Player: Player,
    CurrentState: State,
    _stateChangedBindable: BindableEvent,
    StateChanged: RBXScriptSignal,
}, StateMachine))

function StateMachine.new(player: Player): StateMachine
    local bindable = Instance.new("BindableEvent")
    
    local self = setmetatable({
        Player = player,
        CurrentState = "Idle",
        _stateChangedBindable = bindable,
        StateChanged = bindable.Event, -- Für externe Skripte (z.B. AnimationsController)
    }, StateMachine)
    
    return self
end

-- Prüft, ob ein Wechsel in den neuen Status erlaubt ist
function StateMachine:CanTransitionTo(newState: State): boolean
    if self.CurrentState == newState then return false end
    
    local allowed = ValidTransitions[self.CurrentState]
    if not allowed then return false end
    
    return table.find(allowed, newState) ~= nil
end

function StateMachine:ChangeState(newState: State): boolean
    if not self:CanTransitionTo(newState) then
        warn(`[StateMachine] Ungültiger Wechsel für {self.Player.Name}: {self.CurrentState} -> {newState}`)
        return false
    end
    
    local previousState = self.CurrentState
    self.CurrentState = newState
    
    -- Event feuern, damit andere Skripte reagieren können
    self._stateChangedBindable:Fire(previousState, newState)
    
    -- Interne Logik ausführen
    self:_OnStateChanged(previousState, newState)
    
    return true
end

-- Interne Logik: Was passiert bei einem State-Wechsel?
function StateMachine:_OnStateChanged(previousState: State, newState: State)
    local character = self.Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        -- Beispiel: Passe die Geschwindigkeit basierend auf dem Status an
        if newState == "Stunned" then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        elseif newState == "Running" then
            humanoid.WalkSpeed = 24
            humanoid.JumpPower = 50
        elseif newState == "Idle" then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        elseif newState == "Injured" then
            humanoid.WalkSpeed = 8
            humanoid.JumpPower = 0
        end
    end
end

-- Memory Leak Prävention
function StateMachine:Destroy()
    self._stateChangedBindable:Destroy()
    table.clear(self :: any)
end

return StateMachine