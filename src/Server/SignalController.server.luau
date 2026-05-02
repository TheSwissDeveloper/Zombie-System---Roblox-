-- Signal Lichter Steuerung für alle MeshParts mit Namen "Signal"
-- Signale blinken abwechselnd (Wechselblinker)

local function getAllSignalParts()
    local signalParts = {}
    for _, descendant in game.Workspace:GetDescendants() do
        if descendant:IsA("MeshPart") and descendant.Name == "Signal" then
            table.insert(signalParts, descendant)
        end
    end
    return signalParts
end

local function setupSignalPart(part)
    local light = part:FindFirstChildOfClass("PointLight")
    if not light then
        warn("Kein PointLight im Signal-Part gefunden: " .. part:GetFullName())
        return false
    end
    return true
end

-- Alle Signal-Parts initialisieren
local signalParts = getAllSignalParts()
local validParts = {}

for _, part in ipairs(signalParts) do
    if setupSignalPart(part) then
        table.insert(validParts, part)
    end
end

if #validParts == 0 then
    warn("Keine gültigen Signal-Parts mit PointLight gefunden!")
    return
end

if #validParts < 2 then
    warn("Es werden mindestens 2 Signal-Parts für Wechselblinker benötigt!")
    return
end

print(#validParts .. " Signal-Parts werden als Wechselblinker gesteuert")

-- Funktion zum Setzen des Zustands eines Signals
local function setSignalState(part, isOn)
    local light = part:FindFirstChildOfClass("PointLight")
    if light then
        light.Enabled = isOn
    end
    part.Material = isOn and Enum.Material.Neon or Enum.Material.SmoothPlastic
end

-- Hauptschleife für abwechselndes Blinken
local currentIndex = 0

while true do
    -- Alle Signale ausschalten
    for _, part in ipairs(validParts) do
        setSignalState(part, false)
    end
    
    -- Nächstes Signal einschalten
    currentIndex = (currentIndex % #validParts) + 1
    setSignalState(validParts[currentIndex], true)
    
    task.wait(0.3)
end