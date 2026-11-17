
--========================================================
-- ROUBE OU MORRA V10
-- MOD MENU - FEITO POR TALES
-- VERSAO EXPERIMENTAL DE TESTES
--========================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("RoubeOuMorraV10")
if old then old:Destroy() end

local CONFIG = {
    ScanInterval = 3,
    RefreshInterval = 2,
    MaxRecords = 12000,
    FarmDistance = 12
}

local states = {
    ESPPlayers = false,
    ESPMonsters = false,
    ESPNames = false,
    ESPDucts = false,
    Brightness = false,
    InfiniteStamina = false,
    RemoveDoors = false,
    InstantCollection = false,
    AutoFarm = false,
    DataCollector = false,
    AntiFlash = false,
    NormalVision = false
}

local rarityEnabled = {
    Common = false,
    Uncommon = false,
    Rare = false,
    Epic = false,
    Legendary = false,
    Mythic = false,
    Secret = false
}

local rarityColors = {
    Common = Color3.fromRGB(180,180,180),
    Uncommon = Color3.fromRGB(70,210,100),
    Rare = Color3.fromRGB(60,140,255),
    Epic = Color3.fromRGB(180,70,255),
    Legendary = Color3.fromRGB(255,190,40),
    Mythic = Color3.fromRGB(255,70,100),
    Secret = Color3.fromRGB(255,255,255)
}

local monsterNames = {
    "locust", "hollow", "rictus",
    "wendell", "mimic"
}

local knownItems = {
    "key", "chave", "screwdriver",
    "bateria", "battery", "phone",
    "laptop", "goldbar", "item"
}

local highlights = {}
local tags = {}
local hiddenParts = {}
local savedPrompts = {}
local savedEffects = {}
local savedFlashObjects = {}
local records = {}
local seenObjects = {}

local destroyed = false
local collectorRunning = false
local farmRunning = false
local startTime = os.clock()
local totalScans = 0
local lastScan = "Nunca"
local dataBox

local function lower(v)
    return string.lower(tostring(v or ""))
end

local function contains(value, list)
    value = lower(value)
    for _, word in ipairs(list) do
        if string.find(value, word, 1, true) then
            return true
        end
    end
    return false
end

local function safeGet(obj, property)
    local ok, value = pcall(function()
        return obj[property]
    end)
    return ok and value or nil
end

local function getCharacter()
    return player.Character
end

local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function isMonster(obj)
    return obj:IsA("Model") and contains(obj.Name, monsterNames)
end

local function getPlayerFromModel(model)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then
            return p
        end
    end
end

--========================================================
-- COLETA DE DADOS
--========================================================

local function addRecord(category, data)
    if #records >= CONFIG.MaxRecords then return end

    data.Category = category
    data.Time = os.date("%H:%M:%S")

    table.insert(records, data)
end

local function getAttributes(obj)
    local result = {}
    local ok, attrs = pcall(function()
        return obj:GetAttributes()
    end)

    if ok then
        for name, value in pairs(attrs) do
            result[name] = tostring(value)
        end
    end

    return result
end

local function scanObject(obj, eventName)
    if not obj then return end

    local ok, path = pcall(function()
        return obj:GetFullName()
    end)

    if not ok then return end

    local data = {
        Name = obj.Name,
        Class = obj.ClassName,
        Path = path,
        Event = eventName or "Detectado",
        Attributes = getAttributes(obj)
    }

    local category = "Objeto"

    if isMonster(obj) then
        category = "Monstro"
    elseif obj:IsA("ProximityPrompt") then
        category = "Interacao"
        data.ActionText = obj.ActionText
        data.ObjectText = obj.ObjectText
        data.HoldDuration = obj.HoldDuration
        data.MaxDistance = obj.MaxActivationDistance
        data.Enabled = obj.Enabled
    elseif contains(obj.Name, knownItems) then
        category = "Item"
    elseif obj:IsA("Model") then
        category = "Modelo"
    elseif obj:IsA("BasePart") then
        category = "Peca"
        data.Position = tostring(obj.Position)
    end

    data.Rarity = tostring(
        obj:GetAttribute("Rarity")
        or obj:GetAttribute("Raridade")
        or "Nao detectada"
    )

    data.Value = tostring(
        obj:GetAttribute("Value")
        or obj:GetAttribute("Valor")
        or "Nao detectado"
    )

    addRecord(category, data)
end

local function scanGame()
    if not states.DataCollector then return end

    totalScans += 1
    lastScan = os.date("%H:%M:%S")

    for _, root in ipairs({
        Workspace,
        player
    }) do
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if not seenObjects[obj] then
                    seenObjects[obj] = true
                    scanObject(obj, "Varredura")
                end
            end
        end)
    end

    local map = Workspace:GetAttribute("MapName")
        or Workspace:GetAttribute("CurrentMap")
        or "Nao detectado"

    addRecord("Partida", {
        Name = "Mapa atual",
        Map = tostring(map),
        Scans = totalScans
    })
end

local function exportData()
    local output = {
        "====================================",
        "ROUBE OU MORRA V10 - RELATORIO",
        "Feito por Tales",
        "Data: " .. os.date("%d/%m/%Y %H:%M:%S"),
        "Varreduras: " .. totalScans,
        "===================================="
    }

    for i, data in ipairs(records) do
        table.insert(output, "")
        table.insert(output, "REGISTRO " .. i)

        for key, value in pairs(data) do
            if type(value) == "table" then
                table.insert(output, key .. ":")
                for k, v in pairs(value) do
                    table.insert(output, "  " .. k .. " = " .. tostring(v))
                end
            else
                table.insert(output, key .. ": " .. tostring(value))
            end
        end
    end

    return table.concat(output, "\n")
end

local function copyData()
    local report = exportData()
    local clipboard = setclipboard or toclipboard

    if clipboard then
        local ok = pcall(clipboard, report)
        if ok then return true end
    end

    if dataBox then
        dataBox.Text = report
    end

    return false
end

-- Registra objetos que aparecem e desaparecem durante a partida.
Workspace.DescendantAdded:Connect(function(obj)
    if states.DataCollector then
        seenObjects[obj] = true
        scanObject(obj, "Apareceu")
    end
end)

Workspace.DescendantRemoving:Connect(function(obj)
    if states.DataCollector and seenObjects[obj] then
        addRecord("Evento", {
            Name = obj.Name,
            Event = "Desapareceu",
            Class = obj.ClassName
        })
        seenObjects[obj] = nil
    end
end)

--========================================================
-- ESP
--========================================================

local function removeESP(obj)
    if highlights[obj] then
        highlights[obj]:Destroy()
        highlights[obj] = nil
    end

    if tags[obj] then
        tags[obj]:Destroy()
        tags[obj] = nil
    end
end

local function createESP(obj, color, labelText)
    if not obj or not obj.Parent then return end
    if not obj:IsA("Model") and not obj:IsA("BasePart") then
        return
    end

    if not highlights[obj] then
        local h = Instance.new("Highlight")
        h.Name = "TalesESP"
        h.Adornee = obj
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.8
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = obj
        highlights[obj] = h
    else
        highlights[obj].FillColor = color
        highlights[obj].OutlineColor = color
    end

    if states.ESPNames and not tags[obj] then
        local part = obj:IsA("Model")
            and (obj:FindFirstChild("Head")
            or obj:FindFirstChildWhichIsA("BasePart"))
            or obj

        if part and part:IsA("BasePart") then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "TalesName"
            billboard.Adornee = part
            billboard.Size = UDim2.fromOffset(180, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1
            label.Text = labelText or obj.Name
            label.TextColor3 = color
            label.TextStrokeTransparency = 0
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = billboard

            billboard.Parent = playerGui
            tags[obj] = billboard
        end
    end
end

local function getRarity(obj)
    local value = lower(
        obj:GetAttribute("Rarity")
        or obj:GetAttribute("Raridade")
    )

    local aliases = {
        comum = "Common",
        common = "Common",
        incomum = "Uncommon",
        uncommon = "Uncommon",
        raro = "Rare",
        rare = "Rare",
        epico = "Epic",
        epic = "Epic",
        lendario = "Legendary",
        legendary = "Legendary",
        mitico = "Mythic",
        mythic = "Mythic",
        secreto = "Secret",
        secret = "Secret"
    }

    return aliases[value]
end

local function refreshESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local p = getPlayerFromModel(obj)

            if p and p ~= player and states.ESPPlayers then
                createESP(obj, Color3.fromRGB(40,140,255), p.Name)

            elseif isMonster(obj) and states.ESPMonsters then
                createESP(obj, Color3.fromRGB(255,45,45), obj.Name)

            elseif states.ESPDucts and contains(obj.Name, {
                "duct", "duto", "vent"
            }) then
                createESP(obj, Color3.fromRGB(255,170,40), obj.Name)
            end
        end

        if obj:IsA("Model") or obj:IsA("BasePart") then
            local rarity = getRarity(obj)

            if rarity and rarityEnabled[rarity] then
                createESP(
                    obj,
                    rarityColors[rarity],
                    obj.Name .. " [" .. rarity .. "]"
                )
            end
        end
    end

    for obj in pairs(highlights) do
        local p = getPlayerFromModel(obj)
        local monster = isMonster(obj)
        local rarity = getRarity(obj)

        local keep =
            (p and p ~= player and states.ESPPlayers)
            or (monster and states.ESPMonsters)
            or (rarity and rarityEnabled[rarity])
            or (states.ESPDucts and contains(obj.Name, {
                "duct", "duto", "vent"
            }))

        if not keep then
            removeESP(obj)
        end
    end
end

--========================================================
-- BRILHO NATURAL
--========================================================

local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    ExposureCompensation = Lighting.ExposureCompensation
}

local function setBrightness(enabled)
    states.Brightness = enabled

    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(105,105,105)
        Lighting.OutdoorAmbient = Color3.fromRGB(125,125,125)
        Lighting.ExposureCompensation = 0.15
        Lighting.GlobalShadows = true
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.ExposureCompensation =
            originalLighting.ExposureCompensation
    end
end

--========================================================
-- ANTI-FLASH E VISAO NORMAL
--========================================================

local function changeVisualEffects(enabled, mode)
    local words

    if mode == "flash" then
        words = {"flash", "flashback", "blind", "clarão"}
    else
        words = {"entityvision", "entity_vision", "darkvision",
            "monster vision", "visaoentidade"}
    end

    if enabled then
        for _, obj in ipairs(Lighting:GetDescendants()) do
            if (obj:IsA("BlurEffect")
                or obj:IsA("ColorCorrectionEffect")
                or obj:IsA("BloomEffect")) and contains(obj.Name, words) then

                if savedEffects[obj] == nil then
                    savedEffects[obj] = obj.Enabled
                end

                obj.Enabled = false
            end
        end
    else
        for obj, value in pairs(savedEffects) do
            if obj and obj.Parent then
                pcall(function()
                    obj.Enabled = value
                end)
            end
            savedEffects[obj] = nil
        end
    end
end

local function setAntiFlash(enabled)
    states.AntiFlash = enabled
    changeVisualEffects(enabled, "flash")
end

local function setNormalVision(enabled)
    states.NormalVision = enabled
    changeVisualEffects(enabled, "vision")
end

--========================================================
-- ESTAMINA INFINITA EXPERIMENTAL
--========================================================

local staminaConnection

local function setStamina(enabled)
    states.InfiniteStamina = enabled

    if staminaConnection then
        staminaConnection:Disconnect()
        staminaConnection = nil
    end

    if not enabled then return end

    staminaConnection = RunService.Heartbeat:Connect(function()
        local roots = {
            player,
            getCharacter()
        }

        for _, root in ipairs(roots) do
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    if (obj:IsA("NumberValue")
                        or obj:IsA("IntValue"))
                        and contains(obj.Name, {"stamina", "energia"}) then

                        pcall(function()
                            local maximum =
                                obj:GetAttribute("MaxValue")
                                or obj:GetAttribute("MaxStamina")
                                or 100

                            obj.Value = maximum
                        end)
                    end
                end
            end
        end
    end)
end

--========================================================
-- REMOVER PORTAS E DUTOS
--========================================================

local function hidePart(obj)
    if not obj:IsA("BasePart") then return end

    if hiddenParts[obj] == nil then
        hiddenParts[obj] = {
            Transparency = obj.Transparency,
            LocalTransparencyModifier = obj.LocalTransparencyModifier,
            CanCollide = obj.CanCollide,
            CanTouch = obj.CanTouch,
            CanQuery = obj.CanQuery
        }
    end

    obj.LocalTransparencyModifier = 1
    obj.CanCollide = false
end

local function setDoors(enabled)
    states.RemoveDoors = enabled

    if enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if contains(obj.Name, {
                "door", "porta", "duct", "duto", "vent"
            }) then
                hidePart(obj)
            end
        end
    else
        for obj, data in pairs(hiddenParts) do
            if obj and obj.Parent then
                pcall(function()
                    obj.Transparency = data.Transparency
                    obj.LocalTransparencyModifier =
                        data.LocalTransparencyModifier
                    obj.CanCollide = data.CanCollide
                    obj.CanTouch = data.CanTouch
                    obj.CanQuery = data.CanQuery
                end)
            end
        end

        table.clear(hiddenParts)
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if states.RemoveDoors and obj:IsA("BasePart")
        and contains(obj.Name, {
            "door", "porta", "duct", "duto", "vent"
        }) then
        task.defer(hidePart, obj)
    end

    if states.InstantCollection and obj:IsA("ProximityPrompt") then
        savedPrompts[obj] = obj.HoldDuration
        obj.HoldDuration = 0
    end
end)

--========================================================
-- COLETA INSTANTANEA
--========================================================

local function setInstantCollection(enabled)
    states.InstantCollection = enabled

    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if enabled then
                if savedPrompts[prompt] == nil then
                    savedPrompts[prompt] = prompt.HoldDuration
                end

                pcall(function()
                    prompt.HoldDuration = 0
                end)
            elseif savedPrompts[prompt] ~= nil then
                pcall(function()
                    prompt.HoldDuration = savedPrompts[prompt]
                end)

                savedPrompts[prompt] = nil
            end
        end
    end
end

--========================================================
-- AUTO FARM EXPERIMENTAL
--========================================================

local function setAutoFarm(enabled)
    states.AutoFarm = enabled
    farmRunning = enabled

    if not enabled then return end

    task.spawn(function()
        while farmRunning and not destroyed do
            local root = getRoot()
            local nearest
            local nearestDistance = CONFIG.FarmDistance

            if root then
                for _, prompt in ipairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                        local part = prompt.Parent

                        if part and part:IsA("BasePart") then
                            local distance =
                                (root.Position - part.Position).Magnitude

                            if distance < nearestDistance then
                                nearestDistance = distance
                                nearest = prompt
                            end
                        end
                    end
                end
            end

            if nearest and typeof(fireproximityprompt) == "function" then
                pcall(fireproximityprompt, nearest)
            end

            task.wait(1)
        end
    end)
end

--========================================================
-- INTERFACE
--========================================================

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV10"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(650, 440)
main.Position = UDim2.new(0.5,-325,0.5,-220)
main.BackgroundColor3 = Color3.fromRGB(13,13,17)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner",main).CornerRadius = UDim.new(0,12)

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(160,35,45)
outline.Thickness = 1.5
outline.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,58)
header.BackgroundColor3 = Color3.fromRGB(23,15,18)
header.BorderSizePixel = 0
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-140,0,27)
title.Position = UDim2.fromOffset(16,5)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA V10"
title.TextColor3 = Color3.fromRGB(255,70,80)
title.Font = Enum.Font.GothamBlack
title.TextSize = 19
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local credit = Instance.new("TextLabel")
credit.Size = UDim2.new(1,-140,0,18)
credit.Position = UDim2.fromOffset(17,33)
credit.BackgroundTransparency = 1
credit.Text = "Feito por Tales"
credit.TextColor3 = Color3.fromRGB(155,155,165)
credit.Font = Enum.Font.Gotham
credit.TextSize = 11
credit.TextXAlignment = Enum.TextXAlignment.Left
credit.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(35,32)
minimize.Position = UDim2.new(1,-85,0,12)
minimize.Text = "_"
minimize.TextColor3 = Color3.new(1,1,1)
minimize.BackgroundColor3 = Color3.fromRGB(65,35,40)
minimize.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(35,32)
close.Position = UDim2.new(1,-43,0,12)
close.Text = "X"
close.TextColor3 = Color3.new(1,1,1)
close.BackgroundColor3 = Color3.fromRGB(120,30,40)
close.Parent = header

Instance.new("UICorner",minimize).CornerRadius = UDim.new(0,7)
Instance.new("UICorner",close).CornerRadius = UDim.new(0,7)

local reopen = Instance.new("TextButton")
reopen.Size = UDim2.fromOffset(110,38)
reopen.Position = UDim2.new(0,15,0.5,0)
reopen.Text = "ABRIR PAINEL"
reopen.TextColor3 = Color3.new(1,1,1)
reopen.BackgroundColor3 = Color3.fromRGB(120,30,40)
reopen.Visible = false
reopen.Parent = gui
Instance.new("UICorner",reopen).CornerRadius = UDim.new(0,8)

minimize.MouseButton1Click:Connect(function()
    main.Visible = false
    reopen.Visible = true
end)

reopen.MouseButton1Click:Connect(function()
    main.Visible = true
    reopen.Visible = false
end)

local sidebar = Instance.new("ScrollingFrame")
sidebar.Position = UDim2.fromOffset(0,58)
sidebar.Size = UDim2.new(0,155,1,-58)
sidebar.BackgroundColor3 = Color3.fromRGB(17,17,22)
sidebar.BorderSizePixel = 0
sidebar.ScrollBarThickness = 3
sidebar.CanvasSize = UDim2.new(0,0,0,0)
sidebar.Parent = main

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0,6)
sideLayout.Parent = sidebar

sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sidebar.CanvasSize = UDim2.new(0,0,0,sideLayout.AbsoluteContentSize.Y+12)
end)

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(155,58)
content.Size = UDim2.new(1,-155,1,-58)
content.BackgroundTransparency = 1
content.Parent = main

local pages = {}
local pageButtons = {}

local pageNames = {
    "Principal",
    "ESP Jogadores e Monstros",
    "ESP Items",
    "Auto Farm",
    "Coleta de Dados",
    "Informação da Partida",
    "Configurações"
}

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1,-20,1,-20)
    page.Position = UDim2.fromOffset(10,10)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(180,45,55)
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.Visible = false
    page.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,8)
    layout.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+15)
    end)

    pages[name] = page
end

for _, name in ipairs(pageNames) do
    createPage(name)

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,-12,0,38)
    button.BackgroundColor3 = Color3.fromRGB(28,28,35)
    button.Text = name
    button.TextColor3 = Color3.fromRGB(235,235,240)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 10
    button.Parent = sidebar
    Instance.new("UICorner",button).CornerRadius = UDim.new(0,7)

    pageButtons[name] = button
    button.MouseButton1Click:Connect(function()
        for n,p in pairs(pages) do
            p.Visible = n == name
        end

        for n,b in pairs(pageButtons) do
            b.BackgroundColor3 = n == name
                and Color3.fromRGB(120,30,40)
                or Color3.fromRGB(28,28,35)
        end
    end)
end

local function section(page, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-5,0,28)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255,85,95)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = page
end

local function info(page, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-5,0,35)
    label.BackgroundColor3 = Color3.fromRGB(25,25,32)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200,200,210)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextWrapped = true
    label.Parent = page
    Instance.new("UICorner",label).CornerRadius = UDim.new(0,7)
    return label
end

local function makeButton(page, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,-5,0,38)
    button.BackgroundColor3 = Color3.fromRGB(34,34,43)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(240,240,245)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.Parent = page
    Instance.new("UICorner",button).CornerRadius = UDim.new(0,7)
    button.MouseButton1Click:Connect(callback)
    return button
end

-- Switches animados: cinza desligado, verde ligado.

local function makeToggle(page, text, key, callback, initial)
    states[key] = initial or false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-5,0,42)
    row.BackgroundColor3 = Color3.fromRGB(25,25,32)
    row.Parent = page
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-85,1,0)
    label.Position = UDim2.fromOffset(10,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235,235,240)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(48,24)
    track.Position = UDim2.new(1,-58,0.5,-12)
    track.BackgroundColor3 = Color3.fromRGB(75,75,80)
    track.Parent = row
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18,18)
    knob.Position = UDim2.fromOffset(3,3)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.Parent = track
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local hitbox = Instance.new("TextButton")
    hitbox.Size = UDim2.fromScale(1,1)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.Parent = row

    local function render(animated)
        local enabled = states[key]
        local color = enabled
            and Color3.fromRGB(45,185,90)
            or Color3.fromRGB(75,75,80)

        local position = enabled
            and UDim2.fromOffset(27,3)
            or UDim2.fromOffset(3,3)

        if animated then
            TweenService:Create(track,
                TweenInfo.new(0.18),{BackgroundColor3=color}):Play()
            TweenService:Create(knob,
                TweenInfo.new(0.18),{Position=position}):Play()
        else
            track.BackgroundColor3 = color
            knob.Position = position
        end
    end

    hitbox.MouseButton1Click:Connect(function()
        states[key] = not states[key]
        render(true)

        if callback then
            callback(states[key])
        end
    end)

    render(false)
    return row
end

--========================================================
-- PAGINA PRINCIPAL
--========================================================

local principal = pages["Principal"]
section(principal,"PAINEL PRINCIPAL")
info(principal,"ROUBE OU MORRA V10 - Feito por Tales")
info(principal,"Versao experimental para testes. Algumas funcoes dependem do jogo.")

local statusLabel = info(principal,"Status: Painel iniciado")

makeButton(principal,"ATUALIZAR ESP",function()
    refreshESP()
end)

--========================================================
-- ESP JOGADORES E MONSTROS
--========================================================

local espPage = pages["ESP Jogadores e Monstros"]
section(espPage,"LOCALIZACAO")

makeToggle(espPage,"ESP Jogadores - Azul","ESPPlayers",refreshESP)
makeToggle(espPage,"ESP Monstros - Vermelho","ESPMonsters",refreshESP)
makeToggle(espPage,"Mostrar Nomes","ESPNames",refreshESP)
makeToggle(espPage,"ESP Dutos - Laranja","ESPDucts",refreshESP)

info(espPage,"Jogadores em azul, monstros em vermelho e dutos em laranja.")

--========================================================
-- ESP ITEMS POR RARIDADE
--========================================================

local rarityPage = pages["ESP Items"]
section(rarityPage,"FILTROS INDEPENDENTES")

local rarityLabels = {
    Common = "Comum",
    Uncommon = "Incomum",
    Rare = "Raro",
    Epic = "Epico",
    Legendary = "Lendario",
    Mythic = "Mitico",
    Secret = "Secreto"
}

for _, rarity in ipairs({
    "Common","Uncommon","Rare","Epic",
    "Legendary","Mythic","Secret"
}) do
    local key = rarity

    makeToggle(rarityPage,rarityLabels[key],
        "Rarity_"..key,function(enabled)
            rarityEnabled[key] = enabled
            refreshESP()
        end,false)
end

info(rarityPage,"Cada raridade possui seu proprio interruptor e cor.")

--========================================================
-- AUTO FARM
--========================================================

local farmPage = pages["Auto Farm"]
section(farmPage,"AUTOMACAO")

makeToggle(farmPage,"Coleta Instantanea",
    "InstantCollection",setInstantCollection)

makeToggle(farmPage,"Auto Farm Experimental",
    "AutoFarm",setAutoFarm)

info(farmPage,"O Auto Farm procura interacoes proximas. Nao possui ainda desvio inteligente de monstros.")

--========================================================
-- COLETA DE DADOS
--========================================================

local dataPage = pages["Coleta de Dados"]
section(dataPage,"COLETOR CENTRAL")

makeToggle(dataPage,"Ativar Coleta de Dados",
    "DataCollector",function(enabled)
        collectorRunning = enabled

        if enabled then
            task.spawn(function()
                while collectorRunning and not destroyed do
                    scanGame()
                    task.wait(CONFIG.ScanInterval)
                end
            end)
        end
    end)

makeButton(dataPage,"FAZER VARREDURA AGORA",function()
    states.DataCollector = true
    scanGame()
    statusLabel.Text = "Varredura realizada"
end)

makeButton(dataPage,"COPIAR RELATORIO",function()
    local success = copyData()
    statusLabel.Text = success and "Relatorio copiado!" or "Relatorio exibido abaixo."
end)

makeButton(dataPage,"LIMPAR DADOS",function()
    table.clear(records)
    table.clear(seenObjects)
    totalScans = 0
    lastScan = "Nunca"
    statusLabel.Text = "Dados limpos"
end)

dataBox = Instance.new("TextBox")
dataBox.Size = UDim2.new(1,-5,0,180)
dataBox.BackgroundColor3 = Color3.fromRGB(20,20,26)
dataBox.TextColor3 = Color3.fromRGB(220,220,225)
dataBox.PlaceholderText = "Relatorio da partida..."
dataBox.Text = ""
dataBox.TextSize = 10
dataBox.Font = Enum.Font.Code
dataBox.TextXAlignment = Enum.TextXAlignment.Left
dataBox.TextYAlignment = Enum.TextYAlignment.Top
dataBox.TextWrapped = false
dataBox.ClearTextOnFocus = false
dataBox.MultiLine = true
dataBox.Parent = dataPage

--========================================================
-- INFORMACAO DA PARTIDA
--========================================================

local infoPage = pages["Informação da Partida"]
section(infoPage,"RESUMO DA PARTIDA")

local mapLabel = info(infoPage,"Mapa: Nao detectado")
local monsterLabel = info(infoPage,"Monstros: 0")
local itemLabel = info(infoPage,"Itens: 0")
local promptLabel = info(infoPage,"Interacoes: 0")
local playerLabel = info(infoPage,"Jogadores: 0")
local timeLabel = info(infoPage,"Tempo de partida: 0")
local scanLabel = info(infoPage,"Varreduras: 0")

makeButton(infoPage,"ATUALIZAR RESUMO",function()
    local monsters = 0
    local items = 0
    local prompts = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isMonster(obj) then monsters += 1 end
        if contains(obj.Name,knownItems) then items += 1 end
        if obj:IsA("ProximityPrompt") then prompts += 1 end
    end

    mapLabel.Text = "Mapa: " .. tostring(
        Workspace:GetAttribute("MapName")
        or Workspace:GetAttribute("CurrentMap")
        or "Nao detectado"
    )

    monsterLabel.Text = "Monstros: " .. monsters
    itemLabel.Text = "Itens: " .. items
    promptLabel.Text = "Interacoes: " .. prompts
    playerLabel.Text = "Jogadores: " .. #Players:GetPlayers()
    timeLabel.Text = "Tempo de partida: "
        .. math.floor(os.clock()-startTime) .. " segundos"
    scanLabel.Text = "Varreduras: " .. totalScans
end)

--========================================================
-- CONFIGURACOES
--========================================================

local configPage = pages["Configurações"]
section(configPage,"VISUAL E JOGADOR")

makeToggle(configPage,"Brilho Natural",
    "Brightness",setBrightness)

makeToggle(configPage,"Estamina Infinita Experimental",
    "InfiniteStamina",setStamina)

makeToggle(configPage,"Anti-Flash",
    "AntiFlash",setAntiFlash)

makeToggle(configPage,"Visao Normal da Entidade",
    "NormalVision",setNormalVision)

makeToggle(configPage,"Remover Portas e Dutos",
    "RemoveDoors",setDoors)

info(configPage,"O brilho natural tenta reduzir a escuridao sem deixar a tela branca.")

--========================================================
-- ARRASTAR PAINEL
--========================================================

local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--========================================================
-- LIMPEZA
--========================================================

local function cleanup()
    destroyed = true
    collectorRunning = false
    farmRunning = false

    if staminaConnection then
        staminaConnection:Disconnect()
        staminaConnection = nil
    end

    for obj in pairs(highlights) do
        removeESP(obj)
    end

    for obj, data in pairs(hiddenParts) do
        if obj and obj.Parent then
            pcall(function()
                obj.Transparency = data.Transparency
                obj.LocalTransparencyModifier =
                    data.LocalTransparencyModifier
                obj.CanCollide = data.CanCollide
                obj.CanTouch = data.CanTouch
                obj.CanQuery = data.CanQuery
            end)
        end
    end

    for prompt, duration in pairs(savedPrompts) do
        if prompt and prompt.Parent then
            pcall(function()
                prompt.HoldDuration = duration
            end)
        end
    end

    for obj, enabled in pairs(savedEffects) do
        if obj and obj.Parent then
            pcall(function()
                obj.Enabled = enabled
            end)
        end
    end

    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.Ambient = originalLighting.Ambient
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.ExposureCompensation =
        originalLighting.ExposureCompensation
end

close.MouseButton1Click:Connect(function()
    cleanup()
    gui:Destroy()
end)

gui.Destroying:Connect(cleanup)

--========================================================
-- ATUALIZACAO AUTOMATICA
--========================================================

task.spawn(function()
    while gui.Parent and not destroyed do
        pcall(refreshESP)
        task.wait(CONFIG.RefreshInterval)
    end
end)

pages["Principal"].Visible = true
pageButtons["Principal"].BackgroundColor3 =
    Color3.fromRGB(120,30,40)

print("ROUBE OU MORRA V10 - Feito por Tales")
print("Painel experimental carregado.")
