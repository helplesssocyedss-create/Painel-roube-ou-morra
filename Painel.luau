
-- ROUBE OU MORRA V4
-- PAINEL COMPLETO - LOCAL SCRIPT

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("RoubeOuMorraV4")
if old then old:Destroy() end

local monsters = {
    ["o vazio"] = true,
    ["o ritus"] = true,
    ["o gafanhoto"] = true,
    ["o wendell"] = true,
    ["o fantasma materno"] = true,
    ["o inquilino"] = true
}

local function normalize(s)
    return string.lower(tostring(s or "")):match("^%s*(.-)%s*$")
end

local function isMonster(model, plr)
    local names = {
        model.Name,
        model:GetAttribute("Role"),
        model:GetAttribute("MonsterName")
    }

    if plr then
        table.insert(names, plr.Name)
        table.insert(names, plr.DisplayName)
    end

    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        table.insert(names, hum.DisplayName)
    end

    if model:GetAttribute("IsMonster") == true then
        return true
    end

    for _, name in ipairs(names) do
        if monsters[normalize(name)] then
            return true
        end
    end

    return false
end

-- INTERFACE

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV4"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(285,430)
frame.Position = UDim2.new(0.04,0,0.2,0)
frame.BackgroundColor3 = Color3.fromRGB(17,17,21)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner",frame).CornerRadius = UDim.new(0,12)

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,42)
header.BackgroundColor3 = Color3.fromRGB(180,20,35)
header.BorderSizePixel = 0
header.Parent = frame

Instance.new("UICorner",header).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-80,1,0)
title.Position = UDim2.fromOffset(10,0)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA V4"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(38,38)
minimize.Position = UDim2.new(1,-42,0,2)
minimize.Text = "—"
minimize.TextColor3 = Color3.new(1,1,1)
minimize.BackgroundTransparency = 1
minimize.TextSize = 22
minimize.Parent = header

local restore = Instance.new("TextButton")
restore.Size = UDim2.fromOffset(48,48)
restore.Position = UDim2.new(0,15,0.5,-24)
restore.Text = "RM"
restore.TextColor3 = Color3.new(1,1,1)
restore.Font = Enum.Font.GothamBold
restore.BackgroundColor3 = Color3.fromRGB(180,20,35)
restore.Visible = false
restore.Parent = gui

Instance.new("UICorner",restore).CornerRadius = UDim.new(1,0)

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(0,48)
content.Size = UDim2.new(1,0,1,-50)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
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

-- ARRASTAR

local dragging, dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,startPos.X.Offset+delta.X,
            startPos.Y.Scale,startPos.Y.Offset+delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ESTADOS E ESP

local states = {}
local highlights = {}
local tags = {}

local function clearModel(model)
    if highlights[model] then
        highlights[model]:Destroy()
        highlights[model] = nil
    end

    if tags[model] then
        tags[model]:Destroy()
        tags[model] = nil
    end
end

local function applyModel(model, plr)
    if not model or not model.Parent then return end

    clearModel(model)

    if plr == player then return end

    local monster = isMonster(model,plr)

    -- MONSTRO SEMPRE VERMELHO
    if monster then
        if states["ESP Monstro Vermelho"] then
            local h = Instance.new("Highlight")
            h.Name = "MonsterESP"
            h.Adornee = model
            h.FillColor = Color3.fromRGB(255,0,0)
            h.OutlineColor = Color3.fromRGB(255,0,0)
            h.FillTransparency = 0.25
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = gui
            highlights[model] = h
        end
        return
    end

    -- JOGADORES AZUIS
    if plr and states["ESP Players"] then
        local h = Instance.new("Highlight")
        h.Name = "PlayerESP"
        h.Adornee = model
        h.FillColor = Color3.fromRGB(80,150,255)
        h.OutlineColor = Color3.new(1,1,1)
        h.FillTransparency = 0.65
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = gui
        highlights[model] = h
    end

    if plr and states["ESP Nome"] then
        local head = model:FindFirstChild("Head")
        if head then
            local tag = Instance.new("BillboardGui")
            tag.Adornee = head
            tag.Size = UDim2.fromOffset(120,25)
            tag.StudsOffset = Vector3.new(0,2.5,0)
            tag.AlwaysOnTop = true
            tag.Parent = gui

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1,1)
            label.BackgroundTransparency = 1
            label.Text = plr.DisplayName
            label.TextColor3 = Color3.new(1,1,1)
            label.TextStrokeTransparency = 0.2
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = tag

            tags[model] = tag
        end
    end
end

local function refreshAll()
    for model in pairs(highlights) do clearModel(model) end
    for model in pairs(tags) do clearModel(model) end

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            applyModel(plr.Character,plr)
        end
    end

    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and isMonster(obj,nil) then
            applyModel(obj,nil)
        end
    end
end

local function connectPlayer(plr)
    plr.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if plr ~= player then
            applyModel(character,plr)
        end
    end)
end

for _,plr in ipairs(Players:GetPlayers()) do
    connectPlayer(plr)
end

Players.PlayerAdded:Connect(connectPlayer)

Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then clearModel(plr.Character) end
end)

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") then
        task.defer(function()
            if obj.Parent and isMonster(obj,nil) then
                applyModel(obj,nil)
            end
        end)
    end
end)

-- ULTRA BRILHO

local original = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local function setBrightness(v)
    if v then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200,200,200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
    else
        for k,value in pairs(original) do
            Lighting[k] = value
        end
    end
end

-- STAMINA: DETECCAO LOCAL

local staminaRunning = false

local function stamina(v)
    staminaRunning = v
    if not v then return end

    task.spawn(function()
        while staminaRunning do
            for _,obj in ipairs(player:GetDescendants()) do
                if (obj:IsA("NumberValue") or obj:IsA("IntValue"))
                and string.find(string.lower(obj.Name),"stamina") then
                    local max = obj:GetAttribute("MaxValue")
                        or obj:GetAttribute("MaxStamina")
                    if max then obj.Value = max end
                end
            end
            task.wait(0.2)
        end
    end)
end

-- REMOVER PORTAS E DUTOS LOCALMENTE

local hidden = {}

local function removeDoors(v)
    if v then
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = string.lower(obj.Name)
                if string.find(n,"porta") or string.find(n,"door")
                or string.find(n,"duto") or string.find(n,"vent") then
                    hidden[obj] = {
                        transparency = obj.LocalTransparencyModifier,
                        collision = obj.CanCollide
                    }
                    obj.LocalTransparencyModifier = 1
                    obj.CanCollide = false
                end
            end
        end
    else
        for obj,data in pairs(hidden) do
            if obj.Parent then
                obj.LocalTransparencyModifier = data.transparency
                obj.CanCollide = data.collision
            end
            hidden[obj] = nil
        end
    end
end

-- COLETA INSTANTANEA: PROMPTS LOCAIS

local prompts = {}

local function instantCollection(v)
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if v then
                if prompts[obj] == nil then
                    prompts[obj] = obj.HoldDuration
                end
                obj.HoldDuration = 0
            elseif prompts[obj] ~= nil then
                obj.HoldDuration = prompts[obj]
                prompts[obj] = nil
            end
        end
    end
end

-- AUTO FARM: INTERACAO COM PROMPTS PROXIMOS

local farmRunning = false

local function autoFarm(v)
    farmRunning = v
    if not v then return end

    task.spawn(function()
        while farmRunning do
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                for _,obj in ipairs(workspace:GetDescendants()) do
                    if not farmRunning then break end

                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local part = obj.Parent
                        if part and part:IsA("Attachment") then
                            part = part.Parent
                        end

                        if part and part:IsA("BasePart") then
                            local dist = (root.Position-part.Position).Magnitude

                            if dist <= obj.MaxActivationDistance then
                                pcall(function()
                                    obj:InputHoldBegin()
                                    task.wait(0.15)
                                    obj:InputHoldEnd()
                                end)
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end

            task.wait(0.5)
        end
    end)
end

-- BOTÕES

local function createToggle(name,callback)
    states[name] = false

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.92,0,0,36)
    button.BackgroundColor3 = Color3.fromRGB(42,42,49)
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
            and Color3.fromRGB(170,25,40)
            or Color3.fromRGB(42,42,49)
    end)
end

createToggle("ESP Players",refreshAll)
createToggle("ESP Monstro Vermelho",refreshAll)
createToggle("ESP Nome",refreshAll)
createToggle("Ultra Brilho",setBrightness)
createToggle("Stamina Infinita",stamina)
createToggle("Remover Portas e Dutos",removeDoors)
createToggle("Coleta Instantânea",instantCollection)
createToggle("Auto Farm",autoFarm)

print("ROUBE OU MORRA V4 CARREGADO!")
