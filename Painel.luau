
-- ROUBE OU MORRA MOD MENU V3
-- Roblox Studio - LocalScript
-- Recursos visuais locais

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("RoubeOuMorraV3")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV3"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(285, 430)
frame.Position = UDim2.new(0.04, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(17,17,21)
frame.Parent = gui

Instance.new("UICorner",frame).CornerRadius =
    UDim.new(0,12)

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,42)
header.BackgroundColor3 = Color3.fromRGB(180,20,35)
header.Parent = frame

Instance.new("UICorner",header).CornerRadius =
    UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-85,1,0)
title.Position = UDim2.fromOffset(10,0)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA V3"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(38,38)
minimize.Position = UDim2.new(1,-42,0,2)
minimize.Text = "—"
minimize.TextSize = 22
minimize.TextColor3 = Color3.new(1,1,1)
minimize.BackgroundTransparency = 1
minimize.Parent = header

local restore = Instance.new("TextButton")
restore.Size = UDim2.fromOffset(48,48)
restore.Position = UDim2.new(0,15,0.5,-24)
restore.Text = "RM"
restore.TextColor3 = Color3.new(1,1,1)
restore.TextSize = 16
restore.Font = Enum.Font.GothamBold
restore.BackgroundColor3 = Color3.fromRGB(180,20,35)
restore.Visible = false
restore.Parent = gui
Instance.new("UICorner",restore).CornerRadius =
    UDim.new(1,0)

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(0,48)
content.Size = UDim2.new(1,0,1,-50)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.CanvasSize = UDim2.fromOffset(0,430)
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

-- ARRASTAR MENU
local UserInputService = game:GetService("UserInputService")
local dragging, dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ESTADOS
local states = {}
local connections = {}
local highlights = {}
local nameTags = {}

local function clearESP(plr)
    if highlights[plr] then
        highlights[plr]:Destroy()
        highlights[plr] = nil
    end

    if nameTags[plr] then
        nameTags[plr]:Destroy()
        nameTags[plr] = nil
    end
end

-- ESP DE JOGADORES
local function updatePlayerESP(plr)
    clearESP(plr)

    if plr == player then return end

    local character = plr.Character
    if not character then return end

    if states["ESP Players"] then
        local h = Instance.new("Highlight")
        h.Adornee = character
        h.FillColor = Color3.fromRGB(80,150,255)
        h.FillTransparency = 0.65
        h.OutlineColor = Color3.new(1,1,1)
        h.OutlineTransparency = 0
        h.Parent = character
        highlights[plr] = h
    end

    if states["ESP Nome"] then
        local head = character:FindFirstChild("Head")
        if head then
            local tag = Instance.new("BillboardGui")
            tag.Adornee = head
            tag.Size = UDim2.fromOffset(100,20)
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

            nameTags[plr] = tag
        end
    end
end

local function refreshPlayers()
    for _,plr in ipairs(Players:GetPlayers()) do
        updatePlayerESP(plr)
    end
end

local function addPlayer(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        updatePlayerESP(plr)
    end)
end

for _,plr in ipairs(Players:GetPlayers()) do
    addPlayer(plr)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(clearESP)

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
    states[name] = false

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.92,0,0,36)
    button.BackgroundColor3 = Color3.fromRGB(42,42,49)
    button.TextColor3 = Color3.new(1,1,1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Text = name.." [OFF]"
    button.Parent = content

    Instance.new("UICorner",button).CornerRadius =
        UDim.new(0,7)

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
            and Color3.fromRGB(170,25,40)
            or Color3.fromRGB(42,42,49)
    end)
end

createToggle("ESP Nome",function(v)
    refreshPlayers()
end)

createToggle("ESP Players",function(v)
    refreshPlayers()
end)

createToggle("ESP Monstro Vermelho",function(v)
    warn("Configure o nome do modelo do monstro no jogo.")
end)

createToggle("Stamina Infinita",function(v)
    warn("Requer integração com o sistema de stamina do servidor.")
end)

createToggle("Remover Portas e Dutos",function(v)
    warn("Requer os nomes das portas e dutos do mapa.")
end)

createToggle("Coleta Instantânea",function(v)
    warn("Requer integração com o sistema de coleta.")
end)

createToggle("Ultra Brilho",function(v)
    setBrightness(v)
end)

createToggle("Auto Farm",function(v)
    warn("Requer integração com os mapas, itens e IA do monstro.")
end)

print("ROUBE OU MORRA V3 carregado!")
