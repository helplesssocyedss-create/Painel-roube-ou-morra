--========================================================
-- ROUBE OU MORRA V10
-- Mod Menu | LocalScript
-- Feito por Tales
--========================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--========================================================
-- CONFIGURAÇÕES
--========================================================

local CONFIG = {
    MaxRecords = 12000,
    ScanInterval = 5,
    AutoRefresh = 2,
    FarmDistance = 12,
    RarityLimit = 500
}

local states = {
    ESPPlayers = false,
    ESPMonsters = false,
    ESPNames = false,
    ESPDucts = false,
    ESPItems = false,
    ESPRarity = false,

    Brightness = false,
    InfiniteStamina = false,
    RemoveDoors = false,
    InstantCollection = false,
    AutoFarm = false,
    DataCollector = false
}

local rarityEnabled = {
    Common = true,
    Uncommon = true,
    Rare = true,
    Epic = true,
    Legendary = true,
    Mythic = true,
    Secret = true
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
    "thelocust",
    "locust",
    "thehollow",
    "hollow",
    "therictus",
    "rictus",
    "thewendell",
    "wendell",
    "mimic",
    "themimic"
}

local knownItems = {
    "key",
    "chave",
    "screwdriver",
    "chave de fenda",
    "item",
    "battery",
    "bateria"
}

local highlights = {}
local tags = {}
local hiddenParts = {}
local savedPrompts = {}
local collected = {}
local records = {}
local recordKeys = {}
local connections = {}

local collectorRunning = false
local startTime = os.clock()
local totalScans = 0
local lastScan = "Nunca"

local destroyed = false
local currentPage = "Principal"

--========================================================
-- UTILITÁRIOS
--========================================================

local function safeGet(object, property)
    local ok, value = pcall(function()
        return object[property]
    end)

    if ok then
        return value
    end

    return nil
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function contains(text, list)
    text = lower(text)

    for _, word in ipairs(list) do
        if string.find(text, lower(word), 1, true) then
            return true
        end
    end

    return false
end

local function getCharacter()
    return player.Character
end

local function getRoot()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function isMonster(model)
    if not model or not model:IsA("Model") then
        return false
    end

    return contains(model.Name, monsterNames)
end

local function getPlayerFromModel(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then
            return plr
        end
    end

    return nil
end

--========================================================
-- COLETOR DE DADOS
--========================================================

local function addRecord(category, data)
    if #records >= CONFIG.MaxRecords then
        return
    end

    local key = category .. "|" .. tostring(data.Path or data.Name)

    if recordKeys[key] then
        return
    end

    recordKeys[key] = true
    data.Category = category
    data.Time = os.date("%H:%M:%S")

    table.insert(records, data)
end

local function getAttributes(object)
    local result = {}

    local ok, attributes = pcall(function()
        return object:GetAttributes()
    end)

    if ok then
        for name, value in pairs(attributes) do
            result[name] = tostring(value)
        end
    end

    return result
end

local function scanObject(object)
    if not object or not object.Parent then
        return
    end

    local fullPath = object:GetFullName()
    local className = object.ClassName

    local data = {
        Name = object.Name,
        Class = className,
        Path = fullPath,
        Attributes = getAttributes(object)
    }

    local category = "Objeto"

    if isMonster(object) then
        category = "Monstro"
    elseif object:IsA("ProximityPrompt") then
        category = "Interação"

        data.ActionText = safeGet(object, "ActionText")
        data.ObjectText = safeGet(object, "ObjectText")
        data.HoldDuration = safeGet(object, "HoldDuration")
        data.MaxDistance = safeGet(object, "MaxActivationDistance")
        data.Enabled = safeGet(object, "Enabled")
    elseif contains(object.Name, knownItems) then
        category = "Item"
    elseif object:IsA("Model") then
        category = "Modelo"
    elseif object:IsA("BasePart") then
        category = "Peça"
    end

    local rarity = object:GetAttribute("Rarity")
        or object:GetAttribute("Raridade")

    local value = object:GetAttribute("Value")
        or object:GetAttribute("Valor")

    local weight = object:GetAttribute("Weight")
        or object:GetAttribute("Peso")

    if rarity then data.Rarity = tostring(rarity) end
    if value then data.Value = tostring(value) end
    if weight then data.Weight = tostring(weight) end

    addRecord(category, data)
end

local function scanGame()
    if not states.DataCollector then
        return
    end

    totalScans += 1
    lastScan = os.date("%H:%M:%S")

    local roots = {
        Workspace,
        ReplicatedStorage,
        player
    }

    for _, root in ipairs(roots) do
        pcall(function()
            scanObject(root)

            for _, object in ipairs(root:GetDescendants()) do
                scanObject(object)
            end
        end)
    end

    local mapName = Workspace:GetAttribute("MapName")
        or Workspace:GetAttribute("CurrentMap")
        or "Não detectado"

    addRecord("Partida", {
        Name = "Mapa atual",
        Map = tostring(mapName),
        Path = "Workspace"
    })
end

local function exportData()
    local lines = {}

    table.insert(lines, "====================================")
    table.insert(lines, "ROUBE OU MORRA V10 - COLETA DE DADOS")
    table.insert(lines, "Feito por Tales")
    table.insert(lines, "====================================")
    table.insert(lines, "Data: " .. os.date("%d/%m/%Y %H:%M:%S"))
    table.insert(lines, "Registros: " .. #records)
    table.insert(lines, "Varreduras: " .. totalScans)
    table.insert(lines, "")

    for index, data in ipairs(records) do
        table.insert(lines, "----- REGISTRO " .. index .. " -----")

        for key, value in pairs(data) do
            if key == "Attributes" then
                table.insert(lines, "Attributes:")

                for attribute, attributeValue in pairs(value) do
                    table.insert(lines,
                        "  " .. attribute .. " = " .. tostring(attributeValue))
                end
            else
                table.insert(lines,
                    tostring(key) .. ": " .. tostring(value))
            end
        end
    end

    return table.concat(lines, "\n")
end

local function copyData()
    local report = exportData()

    local clipboardFunction = setclipboard or toclipboard

    if clipboardFunction then
        local ok = pcall(clipboardFunction, report)

        if ok then
            return true, "Dados copiados!"
        end
    end

    if dataBox then
        dataBox.Text = report
    end

    return false, "Clipboard indisponível. Relatório exibido na caixa."
end

--========================================================
-- ESP
--========================================================

local function removeESP(object)
    if highlights[object] then
        highlights[object]:Destroy()
        highlights[object] = nil
    end

    if tags[object] then
        tags[object]:Destroy()
        tags[object] = nil
    end
end

local function createESP(object, color, nameText)
    if not object or not object.Parent then
        return
    end

    if not object:IsA("Model") and not object:IsA("BasePart") then
        return
    end

    if not highlights[object] then
        local highlight = Instance.new("Highlight")
        highlight.Name = "TalesESP"
        highlight.Adornee = object
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = 0.75
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = object

        highlights[object] = highlight
    else
        highlights[object].FillColor = color
        highlights[object].OutlineColor = color
    end

    if states.ESPNames and not tags[object] then
        local adornee = object:IsA("Model")
            and (object:FindFirstChild("Head")
            or object:FindFirstChildWhichIsA("BasePart"))
            or object

        if adornee and adornee:IsA("BasePart") then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "TalesName"
            billboard.Adornee = adornee
            billboard.Size = UDim2.fromOffset(180, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1
            label.Text = nameText or object.Name
            label.TextColor3 = color
            label.TextStrokeTransparency = 0
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = billboard

            billboard.Parent = playerGui
            tags[object] = billboard
        end
    end
end

local function refreshESP()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("Model") then
            local plr = getPlayerFromModel(object)

            if plr and plr ~= player and states.ESPPlayers then
                createESP(object, Color3.fromRGB(40,140,255), plr.Name)

            elseif isMonster(object) and states.ESPMonsters then
                createESP(object, Color3.fromRGB(255,45,45), object.Name)

            elseif states.ESPDucts and contains(object.Name, {
                "duct", "duto", "vent"
            }) then
                createESP(object, Color3.fromRGB(255,170,40), object.Name)

            elseif states.ESPItems and contains(object.Name, knownItems) then
                createESP(object, Color3.fromRGB(60,255,150), object.Name)
            end
        end
    end

    if not states.ESPPlayers and not states.ESPMonsters
        and not states.ESPDucts and not states.ESPItems then

        for object in pairs(highlights) do
            removeESP(object)
        end
    end
end

--========================================================
-- ESP DE RARIDADE
--========================================================

local function getRarity(object)
    local rarity = object:GetAttribute("Rarity")
        or object:GetAttribute("Raridade")

    if not rarity then
        return nil
    end

    local value = lower(rarity)

    for name in pairs(rarityColors) do
        if value == lower(name) then
            return name
        end
    end

    return nil
end

local function refreshRarity()
    if not states.ESPRarity then
        return
    end

    local count = 0

    for _, object in ipairs(Workspace:GetDescendants()) do
        if count >= CONFIG.RarityLimit then
            break
        end

        if object:IsA("Model") or object:IsA("BasePart") then
            local rarity = getRarity(object)

            if rarity and rarityEnabled[rarity] then
                createESP(object, rarityColors[rarity],
                    object.Name .. " [" .. rarity .. "]")
                count += 1
            end
        end
    end
end

--========================================================
-- BRILHO
--========================================================

local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows
}

local function setBrightness(enabled)
    states.Brightness = enabled

    if enabled then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.GlobalShadows = originalLighting.GlobalShadows
    end
end

--========================================================
-- STAMINA
--========================================================

local staminaConnection

local function setStamina(enabled)
    states.InfiniteStamina = enabled

    if staminaConnection then
        staminaConnection:Disconnect()
        staminaConnection = nil
    end

    if enabled then
        staminaConnection = RunService.Heartbeat:Connect(function()
            local character = getCharacter()

            if not character then return end

            for _, object in ipairs(character:GetDescendants()) do
                if object:IsA("NumberValue")
                    and contains(object.Name, {"stamina", "energia"}) then

                    pcall(function()
                        object.Value = object.Value + 1
                    end)
                end
            end
        end)
    end
end

--========================================================
-- REMOVER PORTAS E DUTOS
--========================================================

local function setDoors(enabled)
    states.RemoveDoors = enabled

    if enabled then
        for _, object in ipairs(Workspace:GetDescendants()) do
            if object:IsA("BasePart")
                and contains(object.Name, {
                    "door", "porta", "duct", "duto"
                }) then

                if hiddenParts[object] == nil then
                    hiddenParts[object] = {
                        Transparency = object.Transparency,
                        CanCollide = object.CanCollide
                    }
                end

                object.LocalTransparencyModifier = 1
                object.CanCollide = false
            end
        end
    else
        for object, data in pairs(hiddenParts) do
            if object and object.Parent then
                object.LocalTransparencyModifier = 0
                object.CanCollide = data.CanCollide
            end
        end

        table.clear(hiddenParts)
    end
end

--========================================================
-- COLETA INSTANTÂNEA
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
            else
                if savedPrompts[prompt] ~= nil then
                    pcall(function()
                        prompt.HoldDuration = savedPrompts[prompt]
                    end)

                    savedPrompts[prompt] = nil
                end
            end
        end
    end
end

--========================================================
-- AUTO FARM EXPERIMENTAL
--========================================================

local farmRunning = false

local function setAutoFarm(enabled)
    states.AutoFarm = enabled
    farmRunning = enabled

    if not enabled then return end

    task.spawn(function()
        while farmRunning and not destroyed do
            local root = getRoot()

            if root then
                local nearestPrompt
                local nearestDistance = CONFIG.FarmDistance

                for _, prompt in ipairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt")
                        and prompt.Enabled then

                        local part = prompt.Parent

                        if part and part:IsA("BasePart") then
                            local distance =
                                (root.Position - part.Position).Magnitude

                            if distance < nearestDistance then
                                nearestDistance = distance
                                nearestPrompt = prompt
                            end
                        end
                    end
                end

                if nearestPrompt then
                    pcall(function()
                        fireproximityprompt(nearestPrompt)
                    end)
                end
            end

            task.wait(1)
        end
    end)
end

--========================================================
-- INTERFACE
--========================================================

local old = playerGui:FindFirstChild("RoubeOuMorraV10")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV10"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(650, 430)
main.Position = UDim2.new(0.5, -325, 0.5, -215)
main.BackgroundColor3 = Color3.fromRGB(13,13,17)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(160,35,45)
stroke.Thickness = 1.5
stroke.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,58)
header.BackgroundColor3 = Color3.fromRGB(23,15,18)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0,12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-100,0,28)
title.Position = UDim2.fromOffset(18,7)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA V10"
title.TextColor3 = Color3.fromRGB(255,70,80)
title.Font = Enum.Font.GothamBlack
title.TextSize = 19
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local credit = Instance.new("TextLabel")
credit.Size = UDim2.new(1,-100,0,18)
credit.Position = UDim2.fromOffset(19,33)
credit.BackgroundTransparency = 1
credit.Text = "Feito por Tales"
credit.TextColor3 = Color3.fromRGB(155,155,165)
credit.Font = Enum.Font.Gotham
credit.TextSize = 11
credit.TextXAlignment = Enum.TextXAlignment.Left
credit.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(35,35)
close.Position = UDim2.new(1,-47,0,11)
close.BackgroundColor3 = Color3.fromRGB(120,30,40)
close.Text = "X"
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBold
close.TextSize = 15
close.Parent = header

Instance.new("UICorner", close).CornerRadius = UDim.new(0,8)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.fromOffset(0,58)
sidebar.Size = UDim2.new(0,155,1,-58)
sidebar.BackgroundColor3 = Color3.fromRGB(17,17,22)
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(155,58)
content.Size = UDim2.new(1,-155,1,-58)
content.BackgroundTransparency = 1
content.Parent = main

local pages = {}
local buttons = {}

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
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0,0,0,
            layout.AbsoluteContentSize.Y + 15)
    end)

    pages[name] = page
    return page
end

local function showPage(name)
    currentPage = name

    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end

    for buttonName, button in pairs(buttons) do
        button.BackgroundColor3 = buttonName == name
            and Color3.fromRGB(120,30,40)
            or Color3.fromRGB(28,28,35)
    end
end

local pageNames = {
    "Principal",
    "ESP",
    "Auto Farm",
    "Coleta de Dados",
    "Informação da Partida",
    "Configuração Extra",
    "Raridade de Itens"
}

for index, name in ipairs(pageNames) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,-16,0,39)
    button.Position = UDim2.fromOffset(8,8 + (index-1)*46)
    button.BackgroundColor3 = Color3.fromRGB(28,28,35)
    button.Text = name
    button.TextColor3 = Color3.fromRGB(235,235,240)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 11
    button.Parent = sidebar

    Instance.new("UICorner", button).CornerRadius = UDim.new(0,7)

    buttons[name] = button
    button.MouseButton1Click:Connect(function()
        showPage(name)
    end)
end

for _, name in ipairs(pageNames) do
    createPage(name)
end

--========================================================
-- COMPONENTES
--========================================================

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

local function makeButton(page, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,-5,0,38)
    button.BackgroundColor3 = Color3.fromRGB(34,34,43)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(240,240,245)
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.Parent = page

    Instance.new("UICorner", button).CornerRadius = UDim.new(0,7)

    button.MouseButton1Click:Connect(callback)
    return button
end

local function makeToggle(page, text, key, callback)
    local button
    button = makeButton(page, text .. "  [OFF]", function()
        states[key] = not states[key]

        button.Text = text .. (states[key] and "  [ON]" or "  [OFF]")
        button.BackgroundColor3 = states[key]
            and Color3.fromRGB(105,30,40)
            or Color3.fromRGB(34,34,43)

        if callback then
            callback(states[key])
        end
    end)

    return button
end

local function makeCheck(page, text, initial, callback)
    local value = initial

    local button = makeButton(page,
        text .. (value and "  [✓]" or "  [ ]"), function()

        value = not value

        button.Text = text .. (value and "  [✓]" or "  [ ]")

        if callback then
            callback(value)
        end
    end)

    return button
end

local function makeInfo(page, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-5,0,35)
    label.BackgroundColor3 = Color3.fromRGB(25,25,32)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200,200,210)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextWrapped = true
    label.Parent = page

    Instance.new("UICorner", label).CornerRadius = UDim.new(0,7)

    return label
end

--========================================================
-- PÁGINA PRINCIPAL
--========================================================

local principal = pages["Principal"]

section(principal, "PAINEL PRINCIPAL")

makeInfo(principal,
    "Bem-vindo ao ROUBE OU MORRA V10. Painel desenvolvido por Tales.")

makeInfo(principal,
    "Use o menu lateral para acessar ESP, farm, coleta e configurações.")

local statusLabel = makeInfo(principal, "Status: Painel iniciado")

makeButton(principal, "ATUALIZAR ESP", function()
    refreshESP()
    refreshRarity()
end)

--========================================================
-- PÁGINA ESP
--========================================================

local espPage = pages["ESP"]

section(espPage, "ESP DE JOGADORES E MONSTROS")

makeToggle(espPage, "ESP Players Azul", "ESPPlayers")
makeToggle(espPage, "ESP Monstros Vermelho", "ESPMonsters")
makeToggle(espPage, "ESP Nome", "ESPNames")
makeToggle(espPage, "ESP Dutos", "ESPDucts")
makeToggle(espPage, "ESP Itens e Chaves", "ESPItems")

makeInfo(espPage,
    "Jogadores usam azul. Monstros usam vermelho.")

--========================================================
-- PÁGINA AUTO FARM
--========================================================

local farmPage = pages["Auto Farm"]

section(farmPage, "AUTOMAÇÃO")

makeToggle(farmPage, "Auto Farm Experimental", "AutoFarm", setAutoFarm)

makeToggle(farmPage, "Coleta Instantânea",
    "InstantCollection", setInstantCollection)

makeInfo(farmPage,
    "O Auto Farm procura prompts próximos. Priorização por raridade, fuga de monstros, mochila e saída ainda dependem da estrutura real do jogo.")

--========================================================
-- PÁGINA COLETA DE DADOS
--========================================================

local dataPage = pages["Coleta de Dados"]

section(dataPage, "COLETOR DE DADOS")

makeToggle(dataPage, "Ativar Coletor", "DataCollector", function(enabled)
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

makeButton(dataPage, "FAZER VARREDURA AGORA", function()
    scanGame()
end)

makeButton(dataPage, "COPIAR COLETA", function()
    local success, message = copyData()
    statusLabel.Text = message
end)

makeButton(dataPage, "LIMPAR DADOS", function()
    table.clear(records)
    table.clear(recordKeys)
    totalScans = 0
    lastScan = "Nunca"
end)

makeInfo(dataPage,
    "Coleta objetos, modelos, peças, monstros, itens, prompts, caminhos e atributos replicados ao cliente.")

dataBox = Instance.new("TextBox")
dataBox.Size = UDim2.new(1,-5,0,180)
dataBox.BackgroundColor3 = Color3.fromRGB(20,20,26)
dataBox.TextColor3 = Color3.fromRGB(220,220,225)
dataBox.PlaceholderText = "Relatório aparecerá aqui se a cópia não estiver disponível."
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
-- INFORMAÇÃO DA PARTIDA
--========================================================

local infoPage = pages["Informação da Partida"]

section(infoPage, "INFORMAÇÕES DETECTADAS")

local mapLabel = makeInfo(infoPage, "Mapa: Não detectado")
local monsterLabel = makeInfo(infoPage, "Monstros: 0")
local itemLabel = makeInfo(infoPage, "Itens: 0")
local promptLabel = makeInfo(infoPage, "Interações: 0")
local backpackLabel = makeInfo(infoPage, "Mochila: Não detectada")
local timeLabel = makeInfo(infoPage, "Tempo de sessão: 0 segundos")
local scanLabel = makeInfo(infoPage, "Varreduras: 0")

makeButton(infoPage, "ATUALIZAR INFORMAÇÕES", function()
    local monsters = 0
    local items = 0
    local prompts = 0

    for _, object in ipairs(Workspace:GetDescendants()) do
        if isMonster(object) then
            monsters += 1
        end

        if contains(object.Name, knownItems) then
            items += 1
        end

        if object:IsA("ProximityPrompt") then
            prompts += 1
        end
    end

    local map = Workspace:GetAttribute("MapName")
        or Workspace:GetAttribute("CurrentMap")
        or "Não detectado"

    mapLabel.Text = "Mapa: " .. tostring(map)
    monsterLabel.Text = "Monstros: " .. monsters
    itemLabel.Text = "Itens: " .. items
    promptLabel.Text = "Interações: " .. prompts
    backpackLabel.Text = "Mochila: Não detectada"
    timeLabel.Text = "Tempo de sessão: "
        .. math.floor(os.clock() - startTime) .. " segundos"
    scanLabel.Text = "Varreduras: " .. totalScans
end)

--========================================================
-- CONFIGURAÇÃO EXTRA
--========================================================

local extraPage = pages["Configuração Extra"]

section(extraPage, "CONFIGURAÇÕES")

makeToggle(extraPage, "Ultra Brilho", "Brightness", setBrightness)

makeToggle(extraPage, "Stamina Infinita Experimental",
    "InfiniteStamina", setStamina)

makeToggle(extraPage, "Remover Portas e Dutos",
    "RemoveDoors", setDoors)

makeInfo(extraPage,
    "Algumas alterações locais podem não ser aceitas pelo servidor.")

--========================================================
-- PÁGINA DE RARIDADE
--========================================================

local rarityPage = pages["Raridade de Itens"]

section(rarityPage, "ESP DE RARIDADE")

makeToggle(rarityPage, "ESP de Raridade", "ESPRarity", function()
    refreshRarity()
end)

for _, rarity in ipairs({
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
    "Secret"
}) do
    makeCheck(rarityPage, rarity, true, function(value)
        rarityEnabled[rarity] = value

        for object in pairs(highlights) do
            local objectRarity = getRarity(object)

            if objectRarity == rarity and not value then
                removeESP(object)
            end
        end

        if value and states.ESPRarity then
            refreshRarity()
        end
    end)
end

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
-- ATUALIZAÇÃO AUTOMÁTICA
--========================================================

task.spawn(function()
    while gui.Parent and not destroyed do
        pcall(refreshESP)
        pcall(refreshRarity)

        task.wait(CONFIG.AutoRefresh)
    end
end)

--========================================================
-- ENCERRAMENTO
--========================================================

local function cleanup()
    destroyed = true
    collectorRunning = false
    farmRunning = false

    if staminaConnection then
        staminaConnection:Disconnect()
    end

    for object in pairs(highlights) do
        removeESP(object)
    end

    for object, data in pairs(hiddenParts) do
        if object and object.Parent then
            object.LocalTransparencyModifier = 0
            object.CanCollide = data.CanCollide
        end
    end

    for prompt, duration in pairs(savedPrompts) do
        if prompt and prompt.Parent then
            pcall(function()
                prompt.HoldDuration = duration
            end)
        end
    end

    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.GlobalShadows = originalLighting.GlobalShadows
end

gui.Destroying:Connect(cleanup)

showPage("Principal")

print("ROUBE OU MORRA V10 carregado - Feito por Tales")
