
-- ROUBE OU MORRA V4
-- Roblox Studio - LocalScript

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")

local old = guiParent:FindFirstChild("RoubeOuMorraV4")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV4"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 370)
frame.Position = UDim2.new(0.05, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(18,18,22)
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,44)
header.BackgroundColor3 = Color3.fromRGB(175,25,40)
header.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-90,1,0)
title.Position = UDim2.fromOffset(10,0)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA V4"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(40,40)
minimize.Position = UDim2.new(1,-42,0,2)
minimize.Text = "-"
minimize.TextSize = 25
minimize.TextColor3 = Color3.new(1,1,1)
minimize.BackgroundTransparency = 1
minimize.Parent = header

local restore = Instance.new("TextButton")
restore.Size = UDim2.fromOffset(48,48)
restore.Position = UDim2.new(0,15,0.5,-24)
restore.Text = "RM"
restore.TextColor3 = Color3.new(1,1,1)
restore.BackgroundColor3 = Color3.fromRGB(175,25,40)
restore.Visible = false
restore.Parent = gui
Instance.new("UICorner",restore).CornerRadius = UDim.new(1,0)

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(0,50)
content.Size = UDim2.new(1,0,1,-55)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.CanvasSize = UDim2.fromOffset(0,400)
content.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,7)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = content

minimize.MouseButton1Click:Connect(function()
    frame.Visible = false
    restore.Visible = true
end)

restore.MouseButton1Click:Connect(function()
    frame.Visible = true
    restore.Visible = false
end)

-- ESTADOS
local states = {
    ["ESP Nome"] = false,
    ["ESP Players"] = false,
    ["ESP Monstro"] = false,
    ["Ultra Brilho"] = false
}

local playerHighlights = {}
local playerNames = {}
local monsterHighlights = {}

local function clearPlayerESP(plr)
    if playerHighlights[plr] then
        playerHighlights[plr]:Destroy()
        playerHighlights[plr] = nil
    end

    if playerNames[plr] then
        playerNames[plr]:Destroy()
        playerNames[plr] = nil
    end
end

-- IMPORTANTE:
-- Configure o atributo IsMonster = true
-- no modelo do monstro no Roblox Studio.

local function isMonster(character)
    return character
        and character:GetAttribute("IsMonster") == true
end

local function updatePlayerESP(plr)
    clearPlayerESP(plr)

    if plr == player then return end

    local character = plr.Character
    if not character then return end

    -- Impede ESP de jogador no monstro
    if isMonster(character) then return end

    if states["ESP Players"] then
        local h = Instance.new("Highlight")
        h.Adornee = character
        h.FillColor = Color3.fromRGB(80,150,255)
        h.FillTransparency = 0.65
        h.OutlineColor = Color3.new(1,1,1)
        h.OutlineTransparency = 0
        h.Parent = gui

        playerHighlights[plr] = h
    end

    if states["ESP Nome"] then
        local head = character:FindFirstChild("Head")

        if head then
            local tag = Instance.new("BillboardGui")
            tag.Adornee = head
            tag.Size = UDim2.fromOffset(100,18)
            tag.StudsOffset = Vector3.new(0,2.3,0)
            tag.AlwaysOnTop = true
            tag.Parent = gui

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1,1)
            label.BackgroundTransparency = 1
            label.Text = plr.DisplayName
            label.TextColor3 = Color3.new(1,1,1)
            label.TextStrokeTransparency = 0.3
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = tag

            playerNames[plr] = tag
        end
    end
end

local function refreshPlayers()
    for _,plr in ipairs(Players:GetPlayers()) do
        updatePlayerESP(plr)
    end
end

local function refreshMonster()
    for model,h in pairs(monsterHighlights) do
        h:Destroy()
        monsterHighlights[model] = nil
    end

    if not states["ESP Monstro"] then return end

    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isMonster(obj) then
            local h = Instance.new("Highlight")
            h.Adornee = obj
            h.FillColor = Color3.fromRGB(255,0,0)
            h.FillTransparency = 0.75
            h.OutlineColor = Color3.fromRGB(255,0,0)
            h.OutlineTransparency = 0
            h.Parent = gui

            monsterHighlights[obj] = h
        end
    end
end

local function refreshAll()
    refreshPlayers()
    refreshMonster()
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        updatePlayerESP(plr)
    end)
end)

Players.PlayerRemoving:Connect(clearPlayerESP)

for _,plr in ipairs(Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        updatePlayerESP(plr)
    end)
end

-- ULTRA BRILHO
local original = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local function setBrightness(enabled)
    if enabled then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200,200,200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
    else
        for property,value in pairs(original) do
            Lighting[property] = value
        end
    end
end

-- BOTÕES
local function createToggle(name, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.92,0,0,35)
    button.BackgroundColor3 = Color3.fromRGB(45,45,52)
    button.TextColor3 = Color3.new(1,1,1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Text = name.." [OFF]"
    button.Parent = content

    Instance.new("UICorner",button).CornerRadius = UDim.new(0,7)

    button.MouseButton1Click:Connect(function()
        local nextState = not states[name]

        local ok,err = pcall(function()
            callback(nextState)
        end)

        if not ok then
            warn(name..": "..tostring(err))
            return
        end

        states[name] = nextState
        button.Text = name..(nextState and " [ON]" or " [OFF]")
        button.BackgroundColor3 = nextState
            and Color3.fromRGB(175,25,40)
            or Color3.fromRGB(45,45,52)
    end)
end

createToggle("ESP Nome",function(v)
    states["ESP Nome"] = v
    refreshPlayers()
end)

createToggle("ESP Players",function(v)
    states["ESP Players"] = v
    refreshPlayers()
end)

createToggle("ESP Monstro",function(v)
    states["ESP Monstro"] = v
    refreshMonster()
end)

createToggle("Ultra Brilho",function(v)
    setBrightness(v)
end)

print("ROUBE OU MORRA V4 carregado!")
