
-- ROUBE OU MORRA - MOD MENU V2
-- LocalScript / Roblox Studio

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local old = player.PlayerGui:FindFirstChild("RoubeOuMorraMenu")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraMenu"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 340)
frame.Position = UDim2.new(0.05, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(18,18,22)
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius =
    UDim.new(0,12)

-- CABEÇALHO
local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,45)
header.BackgroundColor3 = Color3.fromRGB(180,20,35)
header.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-45,1,0)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.Parent = header

-- MINIMIZAR
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(40,40)
minimize.Position = UDim2.new(1,-42,0,2)
minimize.BackgroundTransparency = 1
minimize.Text = "-"
minimize.TextColor3 = Color3.new(1,1,1)
minimize.TextSize = 28
minimize.Parent = header

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(0,50)
content.Size = UDim2.new(1,0,1,-50)
content.BackgroundTransparency = 1
content.Parent = frame

local minimized = false

minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    frame.Size = minimized
        and UDim2.fromOffset(280,45)
        or UDim2.fromOffset(280,340)
    minimize.Text = minimized and "+" or "-"
end)

-- ESP
local espNames = false
local espPlayers = false
local ultraBright = false

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

local function updatePlayer(plr)
    if plr == player then return end

    clearESP(plr)

    local character = plr.Character
    if not character then return end

    if espPlayers then
        local h = Instance.new("Highlight")
        h.FillTransparency = 1
        h.OutlineColor = Color3.new(1,1,1)
        h.OutlineTransparency = 0
        h.Adornee = character
        h.Parent = character
        highlights[plr] = h
    end

    if espNames then
        local head = character:FindFirstChild("Head")
        if head then
            local billboard = Instance.new("BillboardGui")
            billboard.Size = UDim2.fromOffset(150,35)
            billboard.StudsOffset = Vector3.new(0,2.5,0)
            billboard.AlwaysOnTop = true
            billboard.Adornee = head
            billboard.Parent = gui

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1,1)
            label.BackgroundTransparency = 1
            label.Text = plr.DisplayName
            label.TextColor3 = Color3.new(1,1,1)
            label.TextStrokeTransparency = 0
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = billboard

            nameTags[plr] = billboard
        end
    end
end

local function refreshESP()
    for _,plr in ipairs(Players:GetPlayers()) do
        updatePlayer(plr)
    end
end

local function setupPlayer(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        updatePlayer(plr)
    end)
end

for _,plr in ipairs(Players:GetPlayers()) do
    setupPlayer(plr)
end

Players.PlayerAdded:Connect(function(plr)
    setupPlayer(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    clearESP(plr)
end)

-- BRILHO
local originalLighting = {
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
        for property,value in pairs(originalLighting) do
            Lighting[property] = value
        end
    end
end

-- BOTÕES
local function createButton(name, callback, index)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.9,0,0,32)
    button.Position = UDim2.new(0.05,0,0,(index-1)*37)
    button.BackgroundColor3 = Color3.fromRGB(45,45,52)
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Text = name.." [OFF]"
    button.Parent = content

    Instance.new("UICorner",button).CornerRadius =
        UDim.new(0,7)

    local active = false

    button.MouseButton1Click:Connect(function()
        active = not active

        local success,err = pcall(function()
            callback(active)
        end)

        if not success then
            active = false
            warn("Erro em "..name..": "..tostring(err))
        end

        button.Text = name..(active and " [ON]" or " [OFF]")
        button.BackgroundColor3 = active
            and Color3.fromRGB(170,25,40)
            or Color3.fromRGB(45,45,52)
    end)
end

createButton("ESP Nome",function(v)
    espNames = v
    refreshESP()
end,1)

createButton("ESP Players Branco",function(v)
    espPlayers = v
    refreshESP()
end,2)

createButton("Ultra Brilho",function(v)
    ultraBright = v
    setBrightness(v)
end,3)

print("Roube ou Morra V2 carregado!")
