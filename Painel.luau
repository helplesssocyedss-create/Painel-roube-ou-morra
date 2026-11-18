
--==============================================================
-- ROUBE OU MORRA V22 | Feito por Tales
-- Painel de desenvolvimento para experiência própria no Roblox Studio
-- ESP reativa | Etiquetas menores | Anti-Flash preparado
-- Estamina via RemoteEvent do servidor
--==============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "RoubeOuMorraV22"

local old = PlayerGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

local gui
local connections = {}

local states = {
    ESPPlayers = false,
    ESPMonsters = false,
    Brightness = false,
    AntiFlash = false,
    InfiniteStamina = false
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
    Common = Color3.fromRGB(190,190,190),
    Uncommon = Color3.fromRGB(70,220,90),
    Rare = Color3.fromRGB(60,140,255),
    Epic = Color3.fromRGB(180,70,255),
    Legendary = Color3.fromRGB(255,190,30),
    Mythic = Color3.fromRGB(255,60,100),
    Secret = Color3.new(1,1,1)
}

local monsterNames = {
    "locust", "hollow", "rictus", "wendell",
    "mimic", "o vazio", "o ritus", "o gafanhoto",
    "o fantasma materno", "o inquilino",
    "sara", "elden", "the elder"
}

local highlights = {}
local labels = {}
local savedLighting = {}
local savedEffects = {}
local savedOverlays = {}

local statusLabel
local showPage

local espGeneration = 0
local espRunning = false

local function track(connection)
    table.insert(connections, connection)
    return connection
end

local function contains(value, list)
    value = string.lower(tostring(value or ""))

    for _, word in ipairs(list) do
        if string.find(value, string.lower(word), 1, true) then
            return true
        end
    end

    return false
end

local function getPlayerFromModel(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then
            return plr
        end
    end
end

local function isMonster(model)
    if not model or not model:IsA("Model") then
        return false
    end

    if getPlayerFromModel(model) then
        return false
    end

    if contains(model.Name, monsterNames) then
        return true
    end

    for _, tag in ipairs(CollectionService:GetTags(model)) do
        if contains(tag, {
            "monster", "enemy", "monstro",
            "inimigo", "creature"
        }) then
            return true
        end
    end

    for _, key in ipairs({
        "IsMonster", "Monster", "IsEnemy",
        "Enemy", "EntityType", "NPCType"
    }) do
        local value = model:GetAttribute(key)

        if value == true then
            return true
        end

        if type(value) == "string"
            and contains(value, {
                "monster", "monstro", "enemy",
                "inimigo", "creature"
            }) then
            return true
        end
    end

    return false
end

local function getRarity(obj)
    for _, key in ipairs({"Rarity", "Raridade"}) do
        local value = obj:GetAttribute(key)

        if type(value) == "string" then
            for rarity in pairs(rarityEnabled) do
                if value:lower() == rarity:lower() then
                    return rarity
                end
            end
        end
    end
end

--==============================================================
-- ESP
--==============================================================

local function removeESP(obj)
    local h = highlights[obj]
    local label = labels[obj]

    if h then
        pcall(function() h:Destroy() end)
        highlights[obj] = nil
    end

    if label then
        pcall(function() label:Destroy() end)
        labels[obj] = nil
    end
end

local function clearESP()
    for obj in pairs(highlights) do
        removeESP(obj)
    end

    for obj in pairs(labels) do
        removeESP(obj)
    end
end

local function getAdorneePart(obj)
    if obj:IsA("BasePart") then
        return obj
    end

    return obj:FindFirstChild("HumanoidRootPart")
        or obj.PrimaryPart
        or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function createESP(obj, color, textValue)
    if not obj or not obj.Parent then
        return
    end

    local h = highlights[obj]

    if not h or not h.Parent then
        if h then
            pcall(function() h:Destroy() end)
        end

        h = Instance.new("Highlight")
        h.Name = "TalesESP_V22"
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency = 0.90
        h.OutlineTransparency = 0
        h.Parent = PlayerGui

        highlights[obj] = h
    end

    h.Adornee = obj
    h.Enabled = true
    h.OutlineColor = color
    h.FillColor = color

    if not textValue then
        if labels[obj] then
            labels[obj]:Destroy()
            labels[obj] = nil
        end
        return
    end

    local part = getAdorneePart(obj)
    if not part then return end

    local bill = labels[obj]

    if not bill or not bill.Parent then
        if bill then
            pcall(function() bill:Destroy() end)
        end

        bill = Instance.new("BillboardGui")
        bill.Name = "TalesESPLabel_V22"
        bill.AlwaysOnTop = true
        bill.Size = UDim2.fromOffset(112, 17)
        bill.StudsOffset = Vector3.new(0, 2.6, 0)
        bill.MaxDistance = 500
        bill.Parent = PlayerGui

        local txt = Instance.new("TextLabel")
        txt.Name = "TextLabel"
        txt.Size = UDim2.fromScale(1, 1)
        txt.BackgroundTransparency = 1
        txt.TextScaled = false
        txt.TextSize = 11
        txt.Font = Enum.Font.GothamBold
        txt.TextStrokeTransparency = 0.25
        txt.TextTruncate = Enum.TextTruncate.AtEnd
        txt.Parent = bill

        labels[obj] = bill
    end

    bill.Adornee = part
    bill.Enabled = true

    local txt = bill:FindFirstChild("TextLabel")
    if txt then
        txt.Text = textValue
        txt.TextColor3 = color
    end
end

local function hasAnyESP()
    if states.ESPPlayers or states.ESPMonsters then
        return true
    end

    for _, enabled in pairs(rarityEnabled) do
        if enabled then return true end
    end

    return false
end

local function updateOne(obj)
    if not obj or not obj.Parent then
        removeESP(obj)
        return
    end

    if obj:IsA("Model") then
        local plr = getPlayerFromModel(obj)

        if plr and plr ~= player and states.ESPPlayers then
            createESP(
                obj,
                Color3.fromRGB(40,140,255),
                plr.DisplayName or plr.Name
            )
            return
        end

        if states.ESPMonsters and isMonster(obj) then
            createESP(
                obj,
                Color3.fromRGB(255,35,35),
                obj.Name
            )
            return
        end
    end

    if obj:IsA("Model") or obj:IsA("BasePart") then
        local rarity = getRarity(obj)

        if rarity and rarityEnabled[rarity] then
            local weight = obj:GetAttribute("Weight")
                or obj:GetAttribute("Peso") or "?"

            local price = obj:GetAttribute("Value")
                or obj:GetAttribute("Price")
                or obj:GetAttribute("Valor") or "?"

            createESP(
                obj,
                rarityColors[rarity],
                obj.Name .. " | " .. tostring(weight)
                    .. " | $" .. tostring(price)
            )
            return
        end
    end

    removeESP(obj)
end

local function refreshESP()
    espGeneration += 1
    local generation = espGeneration

    if espRunning then
        return
    end

    espRunning = true

    task.spawn(function()
        if not hasAnyESP() then
            clearESP()
            espRunning = false
            return
        end

        local descendants = Workspace:GetDescendants()

        for index, obj in ipairs(descendants) do
            if generation ~= espGeneration then
                break
            end

            if not gui or not gui.Parent then
                break
            end

            updateOne(obj)

            if index % 150 == 0 then
                task.wait()
            end
        end

        espRunning = false

        if generation ~= espGeneration then
            task.defer(refreshESP)
        end
    end)
end

local function setESP(key, enabled)
    states[key] = enabled

    if not hasAnyESP() then
        espGeneration += 1
        clearESP()
        return
    end

    refreshESP()
end

track(Workspace.DescendantAdded:Connect(function(obj)
    if hasAnyESP() then
        task.defer(function()
            updateOne(obj)

            if obj:IsA("Model") then
                for _, child in ipairs(obj:GetDescendants()) do
                    updateOne(child)
                end
            end
        end)
    end
end))

track(Workspace.DescendantRemoving:Connect(function(obj)
    removeESP(obj)
end))

local function bindPlayer(plr)
    if plr == player then return end

    track(plr.CharacterAdded:Connect(function(character)
        task.defer(function()
            if states.ESPPlayers then
                updateOne(character)
            end
        end)
    end))

    if plr.Character then
        updateOne(plr.Character)
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    bindPlayer(plr)
end

track(Players.PlayerAdded:Connect(bindPlayer))

track(Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then
        removeESP(plr.Character)
    end
end))

--==============================================================
-- BRILHO
--==============================================================

local function setBrightness(enabled)
    states.Brightness = enabled

    if enabled then
        if not next(savedLighting) then
            savedLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient
            }
        end

        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200,200,200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
    else
        for key, value in pairs(savedLighting) do
            pcall(function()
                Lighting[key] = value
            end)
        end

        table.clear(savedLighting)
    end
end

--==============================================================
-- ANTI-FLASH V22
-- Identificação por tag ou atributo do seu próprio projeto.
--==============================================================

local function isFlashEffect(obj)
    if not obj then return false end

    if CollectionService:HasTag(obj, "FlashbangEffect")
        or CollectionService:HasTag(obj, "AntiFlashEffect") then
        return true
    end

    if obj:GetAttribute("FlashbangEffect") == true
        or obj:GetAttribute("AntiFlashEffect") == true then
        return true
    end

    local name = string.lower(obj.Name)

    return string.find(name, "flashbang", 1, true) ~= nil
        or string.find(name, "flash_effect", 1, true) ~= nil
        or string.find(name, "blindness", 1, true) ~= nil
end

local function inspectFlashObject(obj)
    if not states.AntiFlash or not obj then
        return
    end

    if isFlashEffect(obj) then
        if obj:IsA("PostEffect") then
            if savedEffects[obj] == nil then
                savedEffects[obj] = obj.Enabled
            end

            obj.Enabled = false

        elseif obj:IsA("GuiObject") then
            if savedOverlays[obj] == nil then
                savedOverlays[obj] = obj.Visible
            end

            obj.Visible = false
        end
    end
end

local function inspectFlashRoot(root)
    if not root then return end

    inspectFlashObject(root)

    for _, obj in ipairs(root:GetDescendants()) do
        inspectFlashObject(obj)
    end
end

local function setAntiFlash(enabled)
    states.AntiFlash = enabled

    if enabled then
        inspectFlashRoot(Lighting)
        inspectFlashRoot(PlayerGui)

        for _, obj in ipairs(CollectionService:GetTagged("FlashbangEffect")) do
            inspectFlashObject(obj)
        end
    else
        for obj, value in pairs(savedEffects) do
            if obj and obj.Parent then
                pcall(function()
                    obj.Enabled = value
                end)
            end
        end

        for obj, value in pairs(savedOverlays) do
            if obj and obj.Parent then
                pcall(function()
                    obj.Visible = value
                end)
            end
        end

        table.clear(savedEffects)
        table.clear(savedOverlays)
    end
end

track(Lighting.DescendantAdded:Connect(function(obj)
    task.defer(function()
        inspectFlashObject(obj)
    end)
end))

track(PlayerGui.DescendantAdded:Connect(function(obj)
    task.defer(function()
        inspectFlashObject(obj)
    end)
end))

--==============================================================
-- ESTAMINA V22
-- A alteração real deve ser validada no servidor.
-- RemoteEvent esperado:
-- ReplicatedStorage.V22_SetInfiniteStamina
--==============================================================

local staminaRemote =
    ReplicatedStorage:FindFirstChild("V22_SetInfiniteStamina")

local function setInfiniteStamina(enabled)
    states.InfiniteStamina = enabled

    if not staminaRemote or not staminaRemote:IsA("RemoteEvent") then
        states.InfiniteStamina = false

        if statusLabel then
            statusLabel.Text =
                "Estamina: falta configurar V22_SetInfiniteStamina no servidor."
        end

        return
    end

    staminaRemote:FireServer(enabled)

    if statusLabel then
        statusLabel.Text = enabled
            and "Pedido de estamina enviado ao servidor."
            or "Estamina infinita desativada."
    end
end

--==============================================================
-- INTERFACE
--==============================================================

gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(560, 390)
main.Position = UDim2.new(0.5, -280, 0.5, -195)
main.BackgroundColor3 = Color3.fromRGB(17,17,21)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(125,20,30)
stroke.Thickness = 1.5

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,44)
header.BackgroundColor3 = Color3.fromRGB(105,15,25)
header.BorderSizePixel = 0
header.Parent = main

Instance.new("UICorner", header).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-60,1,0)
title.Position = UDim2.fromOffset(14,0)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA V22 | Tales"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(34,30)
minimize.Position = UDim2.new(1,-40,0,7)
minimize.Text = "—"
minimize.TextSize = 20
minimize.Font = Enum.Font.GothamBold
minimize.TextColor3 = Color3.new(1,1,1)
minimize.BackgroundColor3 = Color3.fromRGB(65,12,20)
minimize.Parent = header

Instance.new("UICorner", minimize).CornerRadius = UDim.new(0,7)

local restore = Instance.new("TextButton")
restore.Size = UDim2.fromOffset(40,40)
restore.Position = UDim2.new(0,15,0.5,-20)
restore.Text = "V22"
restore.TextColor3 = Color3.new(1,1,1)
restore.Font = Enum.Font.GothamBold
restore.TextSize = 12
restore.BackgroundColor3 = Color3.fromRGB(135,18,30)
restore.Visible = false
restore.Parent = gui

Instance.new("UICorner", restore).CornerRadius = UDim.new(0,10)

local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.fromOffset(9,53)
sidebar.Size = UDim2.new(0,125,1,-62)
sidebar.BackgroundColor3 = Color3.fromRGB(23,23,28)
sidebar.BorderSizePixel = 0
sidebar.Parent = main

Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,8)

local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding = UDim.new(0,6)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(143,53)
content.Size = UDim2.new(1,-152,1,-62)
content.BackgroundColor3 = Color3.fromRGB(22,22,27)
content.BorderSizePixel = 0
content.Parent = main

Instance.new("UICorner", content).CornerRadius = UDim.new(0,8)

local pages = {}
local pageButtons = {}

local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1,-14,1,-14)
    page.Position = UDim2.fromOffset(7,7)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new()
    page.Visible = false
    page.Parent = content

    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0,6)
    list.SortOrder = Enum.SortOrder.LayoutOrder

    pages[name] = page
    return page
end

showPage = function(name)
    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end

    for pageName, button in pairs(pageButtons) do
        button.BackgroundColor3 =
            pageName == name
            and Color3.fromRGB(135,22,36)
            or Color3.fromRGB(42,42,49)
    end
end

local function addSection(page, textValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-5,0,25)
    label.BackgroundColor3 = Color3.fromRGB(65,18,26)
    label.TextColor3 = Color3.fromRGB(255,220,220)
    label.Text = textValue
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = page

    Instance.new("UICorner", label).CornerRadius = UDim.new(0,5)
end

local function addButton(page, textValue, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-5,0,32)
    b.BackgroundColor3 = Color3.fromRGB(43,43,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = textValue
    b.TextSize = 11
    b.Font = Enum.Font.Gotham
    b.Parent = page

    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(callback)

    return b
end

local function addToggle(page, name, key, callback, target)
    target = target or states

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-5,0,33)
    b.BackgroundColor3 = Color3.fromRGB(43,43,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = "  " .. name
    b.TextSize = 11
    b.Font = Enum.Font.Gotham
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Parent = page

    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)

    local trackFrame = Instance.new("Frame")
    trackFrame.Size = UDim2.fromOffset(34,18)
    trackFrame.Position = UDim2.new(1,-42,0.5,-9)
    trackFrame.BackgroundColor3 = Color3.fromRGB(90,90,98)
    trackFrame.BorderSizePixel = 0
    trackFrame.Parent = b

    Instance.new("UICorner", trackFrame).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14,14)
    knob.Position = UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = trackFrame

    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local function draw(on)
        b.BackgroundColor3 = on
            and Color3.fromRGB(35,105,65)
            or Color3.fromRGB(43,43,50)

        trackFrame.BackgroundColor3 = on
            and Color3.fromRGB(30,155,85)
            or Color3.fromRGB(90,90,98)

        knob.Position = on
            and UDim2.new(1,-16,0.5,-7)
            or UDim2.new(0,2,0.5,-7)
    end

    draw(target[key] == true)

    b.MouseButton1Click:Connect(function()
        local nextState = not target[key]
        target[key] = nextState

        if callback then
            local ok, err = pcall(callback, nextState)

            if not ok then
                warn("[V22] " .. name .. ": " .. tostring(err))
            end
        end

        draw(target[key] == true)
    end)

    return b
end

local function addNav(name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-10,0,33)
    b.BackgroundColor3 = Color3.fromRGB(42,42,49)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = name
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = sidebar

    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)

    b.MouseButton1Click:Connect(function()
        showPage(name)
    end)

    pageButtons[name] = b
end

local pMain = makePage("Principal")
local pESP = makePage("ESP")
local pEnv = makePage("Ambiente")
local pCollect = makePage("Coleta")
local pConfig = makePage("Configurações")

for _, name in ipairs({
    "Principal", "ESP", "Ambiente",
    "Coleta", "Configurações"
}) do
    addNav(name)
end

-- PRINCIPAL

addSection(pMain, "ROUBE OU MORRA V22")
addButton(pMain, "Painel de desenvolvimento | Feito por Tales", function() end)

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-5,0,55)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255,205,120)
statusLabel.Text = "V22 carregada."
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextWrapped = true
statusLabel.Parent = pMain

-- ESP

addSection(pESP, "ESP DE JOGADORES E ENTIDADES")

addToggle(pESP, "ESP Jogadores", "ESPPlayers", function(v)
    setESP("ESPPlayers", v)
end)

addToggle(pESP, "ESP Monstros", "ESPMonsters", function(v)
    setESP("ESPMonsters", v)
end)

addSection(pESP, "ESP DE ITENS POR RARIDADE")

for _, rarity in ipairs({
    "Common", "Uncommon", "Rare", "Epic",
    "Legendary", "Mythic", "Secret"
}) do
    addToggle(pESP, "ESP " .. rarity, rarity, function()
        refreshESP()
    end, rarityEnabled)
end

-- AMBIENTE

addSection(pEnv, "VISIBILIDADE")

addToggle(pEnv, "Brilho", "Brightness", setBrightness)
addToggle(pEnv, "Anti-Flash", "AntiFlash", setAntiFlash)

-- COLETA / TESTES

addSection(pCollect, "TESTES DO PERSONAGEM")

addToggle(
    pCollect,
    "Estamina infinita (servidor)",
    "InfiniteStamina",
    setInfiniteStamina
)

addButton(pCollect, "Verificar RemoteEvent de estamina", function()
    staminaRemote = ReplicatedStorage:FindFirstChild(
        "V22_SetInfiniteStamina"
    )

    if staminaRemote and staminaRemote:IsA("RemoteEvent") then
        statusLabel.Text = "RemoteEvent encontrado."
    else
        statusLabel.Text =
            "RemoteEvent não encontrado. Configure no servidor."
    end

    showPage("Principal")
end)

-- CONFIGURAÇÕES

addSection(pConfig, "DIAGNÓSTICO")

addButton(pConfig, "Atualizar ESP agora", function()
    refreshESP()
    statusLabel.Text = "Atualização da ESP solicitada."
    showPage("Principal")
end)

addButton(pConfig, "Restaurar brilho e Anti-Flash", function()
    setBrightness(false)
    setAntiFlash(false)
    statusLabel.Text = "Configurações visuais restauradas."
end)

addButton(pConfig, "Limpar ESP", function()
    espGeneration += 1
    clearESP()
    statusLabel.Text = "ESP limpa."
end)

addButton(pConfig, "Fechar painel", function()
    gui:Destroy()
end)

showPage("Principal")

--==============================================================
-- ARRASTAR E MINIMIZAR
--==============================================================

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

minimize.MouseButton1Click:Connect(function()
    main.Visible = false
    restore.Visible = true
end)

restore.MouseButton1Click:Connect(function()
    main.Visible = true
    restore.Visible = false
end)

--==============================================================
-- RECUPERAÇÃO PERIÓDICA DA ESP
--==============================================================

task.spawn(function()
    while gui and gui.Parent do
        if hasAnyESP() and not espRunning then
            refreshESP()
        end

        task.wait(1)
    end
end)

--==============================================================
-- LIMPEZA
--==============================================================

gui.Destroying:Connect(function()
    espGeneration += 1

    clearESP()
    setBrightness(false)
    setAntiFlash(false)

    if states.InfiniteStamina and staminaRemote then
        pcall(function()
            staminaRemote:FireServer(false)
        end)
    end

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(connections)
end)

print("ROUBE OU MORRA V22 CARREGADA | Feito por Tales")
