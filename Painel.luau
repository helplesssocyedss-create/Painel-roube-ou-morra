
-- ROUBE OU MORRA V5
-- LocalScript / ambiente que suporte loadstring e HttpGet

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- LIMPAR VERSAO ANTERIOR
local old = playerGui:FindFirstChild("RoubeOuMorraV5")
if old then old:Destroy() end

local oldV4 = playerGui:FindFirstChild("RoubeOuMorraV4")
if oldV4 then oldV4:Destroy() end

-- ESTADOS
local states = {}
local highlights = {}
local tags = {}

local function normalize(value)
    return string.lower(tostring(value or ""))
end

-- IDENTIFICACAO DE MONSTROS
-- Sem lista fixa de nomes.
-- Usa atributos e equipe quando o jogo disponibiliza esses dados.

local function isMonster(model, plr)
    if not model then return false end

    if model:GetAttribute("IsMonster") == true then
        return true
    end

    if model:GetAttribute("Monster") == true then
        return true
    end

    local role = normalize(model:GetAttribute("Role"))
    local monsterName = normalize(model:GetAttribute("MonsterName"))

    if role:find("monster") or role:find("monstro") then
        return true
    end

    if monsterName ~= "" then
        return true
    end

    if plr and plr.Team then
        local teamName = normalize(plr.Team.Name)
        if teamName:find("monster") or teamName:find("monstro") then
            return true
        end
    end

    return false
end

-- INTERFACE
local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV5"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(285, 430)
frame.Position = UDim2.new(0.04, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(17, 17, 21)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(180, 20, 35)
header.BorderSizePixel = 0
header.Parent = frame

Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA V5"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(38, 38)
minimize.Position = UDim2.new(1, -42, 0, 2)
minimize.Text = "—"
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.BackgroundTransparency = 1
minimize.TextSize = 22
minimize.Parent = header

local restore = Instance.new("TextButton")
restore.Size = UDim2.fromOffset(48, 48)
restore.Position = UDim2.new(0, 15, 0.5, -24)
restore.Text = "RM"
restore.TextColor3 = Color3.new(1, 1, 1)
restore.Font = Enum.Font.GothamBold
restore.BackgroundColor3 = Color3.fromRGB(180, 20, 35)
restore.Visible = false
restore.Parent = gui

Instance.new("UICorner", restore).CornerRadius = UDim.new(1, 0)

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(0, 48)
content.Size = UDim2.new(1, 0, 1, -50)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
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

-- ARRASTAR PAINEL
local dragging = false
local dragStart
local startPos

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
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ESP
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

local function getPlayerFromCharacter(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then
            return plr
        end
    end
    return nil
end

local function getDisplayName(model, plr)
    if plr then
        return plr.DisplayName .. " (@" .. plr.Name .. ")"
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.DisplayName ~= "" then
        return humanoid.DisplayName
    end

    return model.Name
end

local function applyModel(model)
    if not model or not model.Parent then return end
    if not model:IsA("Model") then return end
    if model == player.Character then return end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    clearModel(model)

    local plr = getPlayerFromCharacter(model)
    local monster = isMonster(model, plr)

    -- NPCs são destacados em vermelho.
    -- Personagens de jogadores marcados como monstros também ficam vermelhos.
    -- Jogadores comuns ficam azuis.

    if monster or not plr then
        if states["ESP Monstro Vermelho"] then
            local h = Instance.new("Highlight")
            h.Name = "MonsterESP"
            h.Adornee = model
            h.FillColor = Color3.fromRGB(255, 0, 0)
            h.OutlineColor = Color3.fromRGB(255, 40, 40)
            h.FillTransparency = 0.25
            h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = gui
            highlights[model] = h
        end
    elseif plr and states["ESP Players"] then
        local h = Instance.new("Highlight")
        h.Name = "PlayerESP"
        h.Adornee = model
        h.FillColor = Color3.fromRGB(80, 150, 255)
        h.OutlineColor = Color3.new(1, 1, 1)
        h.FillTransparency = 0.65
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = gui
        highlights[model] = h
    end

    -- NOME DE JOGADORES E NPCs
    if states["ESP Nome"] then
        local head = model:FindFirstChild("Head")
        if head then
            local tag = Instance.new("BillboardGui")
            tag.Name = "ESPName"
            tag.Adornee = head
            tag.Size = UDim2.fromOffset(190, 30)
            tag.StudsOffset = Vector3.new(0, 2.8, 0)
            tag.AlwaysOnTop = true
            tag.Parent = gui

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1
            label.Text = getDisplayName(model, plr)
            label.TextColor3 = monster or not plr
                and Color3.fromRGB(255, 70, 70)
                or Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 0.15
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = tag

            tags[model] = tag
        end
    end
end

local function refreshAll()
    for model in pairs(highlights) do
        clearModel(model)
    end

    for model in pairs(tags) do
        clearModel(model)
    end

    local checked = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            checked[plr.Character] = true
            applyModel(plr.Character)
        end
    end

    -- Procura também NPCs e modelos de IA.
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not checked[obj] then
            if obj:FindFirstChildOfClass("Humanoid") then
                applyModel(obj)
            end
        end
    end
end

local function connectPlayer(plr)
    plr.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        refreshAll()
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    connectPlayer(plr)
end

Players.PlayerAdded:Connect(connectPlayer)

Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then
        clearModel(plr.Character)
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") then
        task.defer(function()
            if obj.Parent and obj:FindFirstChildOfClass("Humanoid") then
                applyModel(obj)
            end
        end)
    end
end)

-- ATUALIZACAO PERIODICA DO ESP
task.spawn(function()
    while gui.Parent do
        if states["ESP Players"]
        or states["ESP Monstro Vermelho"]
        or states["ESP Nome"] then
            refreshAll()
        end
        task.wait(1.5)
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
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    else
        for k, value in pairs(original) do
            Lighting[k] = value
        end
    end
end

-- STAMINA
local staminaGeneration = 0

local function stamina(v)
    staminaGeneration += 1
    local myGeneration = staminaGeneration

    if not v then return end

    task.spawn(function()
        while myGeneration == staminaGeneration do
            for _, obj in ipairs(player:GetDescendants()) do
                if (obj:IsA("NumberValue") or obj:IsA("IntValue"))
                and string.find(normalize(obj.Name), "stamina") then
                    local max = obj:GetAttribute("MaxValue")
                        or obj:GetAttribute("MaxStamina")

                    if max then
                        obj.Value = max
                    end
                end
            end

            task.wait(0.2)
        end
    end)
end

-- REMOVER PORTAS E DUTOS
local hidden = {}
local removeEnvironmentEnabled = false

local keywords = {
    "porta", "door", "duto", "vent",
    "hatch", "duct", "airvent"
}

local function hasEnvironmentName(obj)
    local current = obj

    -- Procura o nome da peça e também dos modelos-pai.
    for _ = 1, 6 do
        if not current then break end

        local name = normalize(current.Name)

        for _, keyword in ipairs(keywords) do
            if name:find(keyword, 1, true) then
                return true
            end
        end

        current = current.Parent
    end

    return false
end

local function hideEnvironmentPart(obj)
    if not obj:IsA("BasePart") then return end
    if not hasEnvironmentName(obj) then return end

    if not hidden[obj] then
        hidden[obj] = {
            transparency = obj.LocalTransparencyModifier,
            collision = obj.CanCollide
        }
    end

    obj.LocalTransparencyModifier = 1
    obj.CanCollide = false
end

local function removeDoors(v)
    removeEnvironmentEnabled = v

    if v then
        for _, obj in ipairs(workspace:GetDescendants()) do
            hideEnvironmentPart(obj)
        end
    else
        for obj, data in pairs(hidden) do
            if obj and obj.Parent then
                obj.LocalTransparencyModifier = data.transparency
                obj.CanCollide = data.collision
            end
            hidden[obj] = nil
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if removeEnvironmentEnabled and obj:IsA("BasePart") then
        task.defer(function()
            if obj.Parent then
                hideEnvironmentPart(obj)
            end
        end)
    end
end)

-- COLETA INSTANTANEA
local prompts = {}

local function instantCollection(v)
    for _, obj in ipairs(workspace:GetDescendants()) do
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

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt")
    and states["Coleta Instantânea"] then
        if prompts[obj] == nil then
            prompts[obj] = obj.HoldDuration
        end
        obj.HoldDuration = 0
    end
end)

-- AUTO FARM
local farmGeneration = 0

local function autoFarm(v)
    farmGeneration += 1
    local myGeneration = farmGeneration

    if not v then return end

    task.spawn(function()
        while myGeneration == farmGeneration do
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if myGeneration ~= farmGeneration then break end

                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local part = obj.Parent

                        if part and part:IsA("Attachment") then
                            part = part.Parent
                        end

                        if part and part:IsA("BasePart") then
                            local dist = (root.Position - part.Position).Magnitude

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

-- BOTOES
local function createToggle(name, callback)
    states[name] = false

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.92, 0, 0, 36)
    button.BackgroundColor3 = Color3.fromRGB(42, 42, 49)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Text = name .. " [OFF]"
    button.Parent = content

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)

    button.MouseButton1Click:Connect(function()
        local nextState = not states[name]

        -- CORRECAO: atualizar o estado ANTES do callback.
        states[name] = nextState

        local ok, err = pcall(function()
            callback(nextState)
        end)

        if not ok then
            states[name] = not nextState
            warn(name .. ": " .. tostring(err))
            button.Text = name .. (states[name] and " [ON]" or " [OFF]")
            return
        end

        button.Text = name .. (nextState and " [ON]" or " [OFF]")
        button.BackgroundColor3 = nextState
            and Color3.fromRGB(170, 25, 40)
            or Color3.fromRGB(42, 42, 49)
    end)
end

createToggle("ESP Players", refreshAll)
createToggle("ESP Monstro Vermelho", refreshAll)
createToggle("ESP Nome", refreshAll)
createToggle("Ultra Brilho", setBrightness)
createToggle("Stamina Infinita", stamina)
createToggle("Remover Portas e Dutos", removeDoors)
createToggle("Coleta Instantânea", instantCollection)
createToggle("Auto Farm", autoFarm)

print("ROUBE OU MORRA V5 CARREGADO!")
