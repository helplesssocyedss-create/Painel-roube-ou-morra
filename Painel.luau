--========================================================
-- ROUBE OU MORRA V15
-- Feito por Tales
-- PAINEL ORGANIZADO | CORRECOES E MELHORIAS
--========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

--========================================================
-- CONFIGURACOES
--========================================================

local VERSION = "V15"
local MAX_RECORDS = 12000

local states = {
    ESPPlayers = false,
    ESPMonsters = false,
    ESPNames = false,
    ESPDucts = false,

    RemoveDoors = false,
    InstantCollection = false,

    Brightness = false,
    AntiFlash = false,

    DataCollector = false,
    AutoFarm = false
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
    Secret = Color3.fromRGB(255,255,255)
}

local monsterNames = {
    "locust",
    "hollow",
    "rictus",
    "wendell",
    "mimic",
    "o vazio",
    "o ritus",
    "o gafanhoto",
    "o fantasma materno",
    "o inquilino"
}

--========================================================
-- VARIAVEIS
--========================================================

local records = {}
local recordIndex = {}

local highlights = {}
local labels = {}

local hiddenParts = {}
local savedPrompts = {}
local savedLighting = {}
local savedEffects = {}

local scanCount = 0
local startTime = os.clock()
local lastScan = "Nenhuma"
local totalDiscovered = 0

local gui
local frame
local status
local reportBox

local activePage = nil
local pageFrames = {}
local tabButtons = {}

local connections = {}
local shuttingDown = false

--========================================================
-- FUNCOES GERAIS
--========================================================

local function safeCall(callback)
    local ok, result = pcall(callback)
    return ok, result
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

local function getRoot()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function updateStatus(message)
    if status and status.Parent then
        status.Text = tostring(message)
    end
end

local function getPlayerFromModel(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then
            return plr
        end
    end

    return nil
end

local function getCamera()
    return Workspace.CurrentCamera
end

--========================================================
-- IDENTIFICACAO DE MONSTROS
--========================================================

local function isMonster(model)
    if not model or not model:IsA("Model") then
        return false
    end

    if contains(model.Name, monsterNames) then
        return true
    end

    local attributes = model:GetAttributes()

    for attr, value in pairs(attributes) do
        local lower = string.lower(attr)

        if lower == "ismonster"
            or lower == "monster"
            or lower == "isenemy"
            or lower == "enemy" then

            if value == true then
                return true
            end
        end

        if type(value) == "string"
            and contains(value, monsterNames) then
            return true
        end
    end

    return false
end

--========================================================
-- IDENTIFICACAO DE RARIDADE
--========================================================

local function getRarity(obj)
    for _, attr in ipairs({"Rarity","Raridade"}) do
        local value = obj:GetAttribute(attr)

        if type(value) == "string" then
            for rarity in pairs(rarityEnabled) do
                if string.lower(value) == string.lower(rarity) then
                    return rarity
                end
            end
        end
    end

    for _, child in ipairs(obj:GetChildren()) do
        if child:IsA("StringValue") then
            if child.Name == "Rarity"
                or child.Name == "Raridade" then

                for rarity in pairs(rarityEnabled) do
                    if string.lower(child.Value) == string.lower(rarity) then
                        return rarity
                    end
                end
            end
        end
    end

    return nil
end

--========================================================
-- ESP
--========================================================

local function removeESP(obj)
    if highlights[obj] then
        safeCall(function()
            highlights[obj]:Destroy()
        end)

        highlights[obj] = nil
    end

    if labels[obj] then
        safeCall(function()
            labels[obj]:Destroy()
        end)

        labels[obj] = nil
    end
end

local function createESP(obj, color, textValue, small)
    if not obj or not obj.Parent then
        return
    end

    if not highlights[obj] then
        local highlight = Instance.new("Highlight")

        highlight.Name = "TalesESP"
        highlight.Adornee = obj
        highlight.FillTransparency = 0.85
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = obj

        highlights[obj] = highlight
    end

    highlights[obj].OutlineColor = color
    highlights[obj].FillColor = color

    if not textValue then
        if labels[obj] then
            labels[obj]:Destroy()
            labels[obj] = nil
        end

        return
    end

    local part

    if obj:IsA("BasePart") then
        part = obj
    elseif obj:IsA("Model") then
        part = obj:FindFirstChild("HumanoidRootPart")
            or obj.PrimaryPart
            or obj:FindFirstChildWhichIsA("BasePart")
    end

    if not part then
        return
    end

    if not labels[obj] then
        local billboard = Instance.new("BillboardGui")

        billboard.Name = "TalesESPLabel"
        billboard.Adornee = part
        billboard.AlwaysOnTop = true
        billboard.Size = small
            and UDim2.fromOffset(150,24)
            or UDim2.fromOffset(190,30)

        billboard.StudsOffset = Vector3.new(0,3,0)

        local text = Instance.new("TextLabel")

        text.Name = "TextLabel"
        text.Size = UDim2.fromScale(1,1)
        text.BackgroundTransparency = 1
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.TextStrokeTransparency = 0.2
        text.Parent = billboard

        billboard.Parent = PlayerGui
        labels[obj] = billboard
    end

    local billboard = labels[obj]

    billboard.Adornee = part
    billboard.TextLabel.Text = tostring(textValue)
    billboard.TextLabel.TextColor3 = color
end

local function refreshESP()
    local keep = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do

        if obj:IsA("Model") then

            -- MONSTROS TEM PRIORIDADE SOBRE JOGADORES

            if states.ESPMonsters and isMonster(obj) then

                createESP(
                    obj,
                    Color3.fromRGB(255,35,35),
                    states.ESPNames and obj.Name or nil,
                    false
                )

                keep[obj] = true

            else
                local target = getPlayerFromModel(obj)

                if target
                    and target ~= player
                    and states.ESPPlayers then

                    createESP(
                        obj,
                        Color3.fromRGB(40,140,255),
                        states.ESPNames and target.Name or nil,
                        false
                    )

                    keep[obj] = true
                end
            end

            if states.ESPDucts
                and contains(obj.Name,{"duct","duto","vent"}) then

                createESP(
                    obj,
                    Color3.fromRGB(255,170,40),
                    obj.Name .. " [DUTO]",
                    true
                )

                keep[obj] = true
            end
        end

        if obj:IsA("Model") or obj:IsA("BasePart") then
            local rarity = getRarity(obj)

            if rarity and rarityEnabled[rarity] then

                local weight = obj:GetAttribute("Weight")
                    or obj:GetAttribute("Peso")
                    or "?"

                local price = obj:GetAttribute("Value")
                    or obj:GetAttribute("Price")
                    or obj:GetAttribute("Valor")
                    or "?"

                createESP(
                    obj,
                    rarityColors[rarity],
                    obj.Name
                        .. " | Peso: "
                        .. tostring(weight)
                        .. " | $"
                        .. tostring(price),
                    true
                )

                keep[obj] = true
            end
        end
    end

    for obj in pairs(highlights) do
        if not keep[obj] then
            removeESP(obj)
        end
    end
end

--========================================================
-- PORTAS E ESCOTILHAS
--========================================================

local function hidePart(part)
    if not part or not part:IsA("BasePart") then
        return
    end

    if not hiddenParts[part] then
        hiddenParts[part] = {
            Transparency = part.Transparency,
            LocalTransparencyModifier = part.LocalTransparencyModifier,
            CanCollide = part.CanCollide,
            CanTouch = part.CanTouch,
            CanQuery = part.CanQuery
        }
    end

    safeCall(function()
        part.LocalTransparencyModifier = 1
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
    end)
end

local function restoreDoors()
    for part, data in pairs(hiddenParts) do
        if part and part.Parent then
            safeCall(function()
                part.Transparency = data.Transparency
                part.LocalTransparencyModifier = data.LocalTransparencyModifier
                part.CanCollide = data.CanCollide
                part.CanTouch = data.CanTouch
                part.CanQuery = data.CanQuery
            end)
        end
    end

    table.clear(hiddenParts)
end

local function isDoorPart(obj)
    if not obj or not obj:IsA("BasePart") then
        return false
    end

    -- Porta identificada pelo proprio nome

    if contains(obj.Name,{"door","porta"}) then
        return true
    end

    -- Tampa de duto: somente partes identificadas como tampa

    local parent = obj.Parent
    local insideDuct = false

    for _ = 1,8 do
        if not parent then
            break
        end

        if contains(parent.Name,{"duct","duto","vent"}) then
            insideDuct = true
            break
        end

        parent = parent.Parent
    end

    if insideDuct then
        return contains(obj.Name,{
            "hatch",
            "cover",
            "lid",
            "tampa",
            "escotilha",
            "ductdoor",
            "ventdoor",
            "cap"
        })
    end

    return false
end

local function setDoors(enabled)
    states.RemoveDoors = enabled

    if not enabled then
        restoreDoors()
        updateStatus("Portas restauradas")
        return
    end

    local count = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isDoorPart(obj) then
            hidePart(obj)
            count += 1
        end
    end

    updateStatus("Partes ocultadas: " .. count)
end

--========================================================
-- COLETA INSTANTANEA
--========================================================

local function applyInstantPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return
    end

    if savedPrompts[prompt] == nil then
        savedPrompts[prompt] = prompt.HoldDuration
    end

    prompt.HoldDuration = 0
end

local function setInstant(enabled)
    states.InstantCollection = enabled

    if enabled then
        local count = 0

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                applyInstantPrompt(obj)
                count += 1
            end
        end

        updateStatus("Coleta instantanea ativa: " .. count)

    else
        for obj, duration in pairs(savedPrompts) do
            if obj and obj.Parent then
                safeCall(function()
                    obj.HoldDuration = duration
                end)
            end
        end

        table.clear(savedPrompts)

        updateStatus("Coleta instantanea desativada")
    end
end

--========================================================
-- ANTI-FLASH
--========================================================

local flashWords = {
    "flash",
    "flashbang",
    "blind",
    "blindness",
    "clarão",
    "claridade",
    "cegueira"
}

local function isFlashEffect(obj)
    if contains(obj.Name, flashWords) then
        return true
    end

    if obj:IsA("BlurEffect") then
        return true
    end

    return false
end

local function saveAndDisableEffect(obj)
    if not obj or not obj.Parent then
        return
    end

    if savedEffects[obj] then
        return
    end

    if obj:IsA("BlurEffect")
        or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("BloomEffect")
        or obj:IsA("DepthOfFieldEffect")
        or obj:IsA("SunRaysEffect") then

        if isFlashEffect(obj) then
            savedEffects[obj] = {
                Type = "Effect",
                Enabled = obj.Enabled
            }

            obj.Enabled = false
        end

    elseif obj:IsA("ScreenGui") then

        if contains(obj.Name,flashWords) then
            savedEffects[obj] = {
                Type = "ScreenGui",
                Enabled = obj.Enabled
            }

            obj.Enabled = false
        end

    elseif obj:IsA("Frame")
        or obj:IsA("ImageLabel")
        or obj:IsA("ImageButton") then

        if contains(obj.Name,flashWords) then
            savedEffects[obj] = {
                Type = "Visible",
                Visible = obj.Visible
            }

            obj.Visible = false
        end
    end
end

local function scanFlashEffects()
    if not states.AntiFlash then
        return
    end

    for _, obj in ipairs(Lighting:GetDescendants()) do
        saveAndDisableEffect(obj)
    end

    local camera = getCamera()

    if camera then
        for _, obj in ipairs(camera:GetDescendants()) do
            saveAndDisableEffect(obj)
        end
    end

    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        saveAndDisableEffect(obj)
    end
end

local function restoreFlashEffects()
    for obj, data in pairs(savedEffects) do
        if obj and obj.Parent then
            safeCall(function()
                if data.Type == "Effect" then
                    obj.Enabled = data.Enabled

                elseif data.Type == "ScreenGui" then
                    obj.Enabled = data.Enabled

                elseif data.Type == "Visible" then
                    obj.Visible = data.Visible
                end
            end)
        end
    end

    table.clear(savedEffects)
end

local function setAntiFlash(enabled)
    states.AntiFlash = enabled

    if enabled then
        scanFlashEffects()
        updateStatus("Anti-Flash experimental ativado")
    else
        restoreFlashEffects()
        updateStatus("Anti-Flash desativado")
    end
end

--========================================================
-- BRILHO
--========================================================

local function setBrightness(enabled)
    states.Brightness = enabled

    if enabled then
        savedLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            GlobalShadows = Lighting.GlobalShadows
        }

        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false

        updateStatus("Brilho ativado")

    else
        if savedLighting.Brightness ~= nil then
            Lighting.Brightness = savedLighting.Brightness
            Lighting.ClockTime = savedLighting.ClockTime
            Lighting.GlobalShadows = savedLighting.GlobalShadows
        end

        table.clear(savedLighting)

        updateStatus("Brilho restaurado")
    end
end

--========================================================
-- COLETOR DE DADOS
--========================================================

local function serializeAttributes(obj)
    local attributes = obj:GetAttributes()
    local result = {}

    for key, value in pairs(attributes) do
        result[key] = tostring(value)
    end

    return result
end

local function makeRecord(obj)
    local entry = {
        Name = obj.Name,
        Class = obj.ClassName,
        Path = obj:GetFullName(),
        FirstSeen = os.date("%d/%m/%Y %H:%M:%S"),
        LastSeen = os.date("%d/%m/%Y %H:%M:%S"),
        SeenCount = 1
    }

    local attributes = serializeAttributes(obj)

    if next(attributes) then
        entry.Attributes = attributes
    end

    if obj:IsA("BasePart") then
        entry.Position = tostring(obj.Position)
        entry.Size = tostring(obj.Size)
        entry.Transparency = tostring(obj.Transparency)
        entry.CanCollide = tostring(obj.CanCollide)
    end

    if obj:IsA("ProximityPrompt") then
        entry.HoldDuration = tostring(obj.HoldDuration)
        entry.ActionText = obj.ActionText
        entry.ObjectText = obj.ObjectText
    end

    -- Identificacao de possiveis dados de estamina

    local lowerName = string.lower(obj.Name)

    if contains(lowerName,{
        "stamina",
        "resistance",
        "resistencia",
        "energy",
        "energia",
        "endurance"
    }) then
        entry.PossibleStaminaData = true
    end

    return entry
end

local function updateRecord(obj)
    local path

    safeCall(function()
        path = obj:GetFullName()
    end)

    if not path then
        return
    end

    local key = obj.ClassName .. "|" .. path
    local existing = recordIndex[key]

    if existing then
        existing.LastSeen = os.date("%d/%m/%Y %H:%M:%S")
        existing.SeenCount += 1

        existing.Attributes = serializeAttributes(obj)

        if obj:IsA("BasePart") then
            existing.Position = tostring(obj.Position)
            existing.Size = tostring(obj.Size)
        end

        return
    end

    if #records >= MAX_RECORDS then
        return
    end

    local entry = makeRecord(obj)

    table.insert(records,entry)
    recordIndex[key] = entry

    totalDiscovered += 1
end

local function scanGame()
    scanCount += 1
    lastScan = os.date("%d/%m/%Y %H:%M:%S")

    local before = #records

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model")
            or obj:IsA("BasePart")
            or obj:IsA("ProximityPrompt")
            or obj:IsA("Folder")
            or obj:IsA("ValueBase") then

            safeCall(function()
                updateRecord(obj)
            end)
        end
    end

    local added = #records - before

    return #records, added
end

--========================================================
-- RELATORIO
--========================================================

local function exportData()
    local out = {}

    table.insert(out,"================================================")
    table.insert(out,"ROUBE OU MORRA " .. VERSION .. " - RELATORIO")
    table.insert(out,"Feito por Tales")
    table.insert(out,"Data: " .. os.date("%d/%m/%Y %H:%M:%S"))
    table.insert(out,"Tempo de coleta: " .. math.floor(os.clock()-startTime) .. " segundos")
    table.insert(out,"Varreduras realizadas: " .. scanCount)
    table.insert(out,"Registros acumulados: " .. #records)
    table.insert(out,"Novos objetos descobertos: " .. totalDiscovered)
    table.insert(out,"Ultima varredura: " .. lastScan)
    table.insert(out,"================================================")

    if #records == 0 then
        table.insert(out,"")
        table.insert(out,"Nenhum registro coletado.")
        table.insert(out,"Ative o coletor ou faca uma varredura.")
    end

    for i, entry in ipairs(records) do
        table.insert(out,"")
        table.insert(out,"--------------- REGISTRO " .. i .. " ---------------")

        table.insert(out,"Nome: " .. tostring(entry.Name))
        table.insert(out,"Classe: " .. tostring(entry.Class))
        table.insert(out,"Caminho: " .. tostring(entry.Path))
        table.insert(out,"Primeira aparicao: " .. tostring(entry.FirstSeen))
        table.insert(out,"Ultima aparicao: " .. tostring(entry.LastSeen))
        table.insert(out,"Visto: " .. tostring(entry.SeenCount) .. " vezes")

        if entry.Position then
            table.insert(out,"Posicao: " .. tostring(entry.Position))
        end

        if entry.Size then
            table.insert(out,"Tamanho: " .. tostring(entry.Size))
        end

        if entry.HoldDuration then
            table.insert(out,"HoldDuration: " .. tostring(entry.HoldDuration))
            table.insert(out,"ActionText: " .. tostring(entry.ActionText))
            table.insert(out,"ObjectText: " .. tostring(entry.ObjectText))
        end

        if entry.PossibleStaminaData then
            table.insert(out,"POSSIVEL DADO DE ESTAMINA/RESISTENCIA")
        end

        if entry.Attributes then
            table.insert(out,"Atributos:")

            for key, value in pairs(entry.Attributes) do
                table.insert(
                    out,
                    "  " .. tostring(key) .. " = " .. tostring(value)
                )
            end
        end
    end

    return table.concat(out,"\n")
end

local function copyReport()
    local report = exportData()

    -- O relatorio sempre fica disponivel na caixa de texto.

    if reportBox and reportBox.Parent then
        reportBox.Text = report
    end

    -- Tenta os metodos de clipboard disponiveis no executor.

    local clipboardFunction

    if type(setclipboard) == "function" then
        clipboardFunction = setclipboard

    elseif type(toclipboard) == "function" then
        clipboardFunction = toclipboard
    end

    if clipboardFunction then
        local ok = pcall(function()
            clipboardFunction(report)
        end)

        if ok then
            return true
        end
    end

    return false
end

--========================================================
-- INTERFACE
--========================================================

local old = PlayerGui:FindFirstChild("RoubeOuMorraV15")

if old then
    old:Destroy()
end

gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV15"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local scale = Instance.new("UIScale")
scale.Parent = gui

local function updateScale()
    local camera = getCamera()

    if not camera then
        return
    end

    local viewport = camera.ViewportSize
    local factor = math.min(
        viewport.X / 650,
        viewport.Y / 500,
        1
    )

    scale.Scale = math.max(factor,0.65)
end

updateScale()

--========================================================
-- JANELA PRINCIPAL
--========================================================

frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.fromOffset(620,450)
frame.Position = UDim2.new(0.5,-310,0.5,-225)
frame.BackgroundColor3 = Color3.fromRGB(17,17,21)
frame.BorderSizePixel = 0
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0,12)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(125,25,32)
frameStroke.Thickness = 1.5
frameStroke.Parent = frame

--========================================================
-- BARRA SUPERIOR
--========================================================

local top = Instance.new("Frame")
top.Size = UDim2.new(1,0,0,48)
top.BackgroundColor3 = Color3.fromRGB(105,18,25)
top.BorderSizePixel = 0
top.Parent = frame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0,12)
topCorner.Parent = top

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-105,1,0)
title.Position = UDim2.fromOffset(14,0)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA " .. VERSION .. "  |  TALES"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(34,30)
minimize.Position = UDim2.new(1,-78,0,9)
minimize.BackgroundColor3 = Color3.fromRGB(65,15,20)
minimize.Text = "-"
minimize.TextColor3 = Color3.new(1,1,1)
minimize.TextSize = 22
minimize.Font = Enum.Font.GothamBold
minimize.Parent = top

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34,30)
close.Position = UDim2.new(1,-39,0,9)
close.BackgroundColor3 = Color3.fromRGB(145,25,32)
close.Text = "X"
close.TextColor3 = Color3.new(1,1,1)
close.TextSize = 14
close.Font = Enum.Font.GothamBold
close.Parent = top

local minimized = false

minimize.MouseButton1Click:Connect(function()
    minimized = not minimized

    for _, child in ipairs(frame:GetChildren()) do
        if child ~= top and child ~= frameCorner and child ~= frameStroke then
            child.Visible = not minimized
        end
    end

    frame.Size = minimized
        and UDim2.fromOffset(620,48)
        or UDim2.fromOffset(620,450)

    minimize.Text = minimized and "+" or "-"
end)

--========================================================
-- MENU LATERAL
--========================================================

local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.fromOffset(0,48)
sidebar.Size = UDim2.new(0,145,1,-48)
sidebar.BackgroundColor3 = Color3.fromRGB(23,23,28)
sidebar.BorderSizePixel = 0
sidebar.Parent = frame

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0,7)
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0,12)
sidebarPadding.PaddingLeft = UDim.new(0,8)
sidebarPadding.PaddingRight = UDim.new(0,8)
sidebarPadding.Parent = sidebar

--========================================================
-- AREA DAS PAGINAS
--========================================================

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(153,55)
content.Size = UDim2.new(1,-161,1,-63)
content.BackgroundTransparency = 1
content.Parent = frame

local function createPage(name)
    local page = Instance.new("ScrollingFrame")

    page.Name = name
    page.Size = UDim2.fromScale(1,1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(150,35,42)
    page.CanvasSize = UDim2.new()
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0,8)
    padding.PaddingLeft = UDim.new(0,8)
    padding.PaddingRight = UDim.new(0,8)
    padding.PaddingBottom = UDim.new(0,12)
    padding.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    pageFrames[name] = page

    return page
end

local function showPage(name)
    activePage = name

    for pageName, page in pairs(pageFrames) do
        page.Visible = pageName == name
    end

    for tabName, tab in pairs(tabButtons) do
        tab.BackgroundColor3 = tabName == name
            and Color3.fromRGB(125,25,32)
            or Color3.fromRGB(42,42,49)
    end
end

--========================================================
-- ELEMENTOS DAS PAGINAS
--========================================================

local function section(parent, text)
    local label = Instance.new("TextLabel")

    label.Size = UDim2.new(1,-5,0,27)
    label.BackgroundColor3 = Color3.fromRGB(75,20,26)
    label.Text = "  " .. text
    label.TextColor3 = Color3.fromRGB(255,225,225)
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = label

    return label
end

local function button(parent, text, callback, color)
    local b = Instance.new("TextButton")

    b.Size = UDim2.new(1,-5,0,34)
    b.BackgroundColor3 = color or Color3.fromRGB(43,43,51)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = text
    b.TextSize = 12
    b.Font = Enum.Font.Gotham
    b.AutoButtonColor = true
    b.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = b

    b.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    return b
end

local function toggle(parent, name, key, callback)
    local b

    local function updateText()
        b.Text = name .. "   [" .. (states[key] and "ON" or "OFF") .. "]"

        b.BackgroundColor3 = states[key]
            and Color3.fromRGB(105,35,42)
            or Color3.fromRGB(43,43,51)
    end

    b = button(parent,name .. " [OFF]",function()
        states[key] = not states[key]

        if callback then
            callback(states[key])
        end

        updateText()
    end)

    updateText()

    return b
end

local function rarityToggle(parent, rarity)
    local b

    local function updateText()
        b.Text = "ESP " .. rarity .. " [" ..
            (rarityEnabled[rarity] and "ON" or "OFF") .. "]"

        b.BackgroundColor3 = rarityEnabled[rarity]
            and rarityColors[rarity]
            or Color3.fromRGB(43,43,51)

        b.TextColor3 = rarityEnabled[rarity]
            and Color3.fromRGB(20,20,20)
            or Color3.new(1,1,1)
    end

    b = button(parent,"ESP " .. rarity .. " [OFF]",function()
        rarityEnabled[rarity] = not rarityEnabled[rarity]

        updateText()
        refreshESP()
    end)

    updateText()

    return b
end

local function createTab(name)
    local b = Instance.new("TextButton")

    b.Size = UDim2.new(1,0,0,35)
    b.BackgroundColor3 = Color3.fromRGB(42,42,49)
    b.Text = name
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.Parent = sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = b

    tabButtons[name] = b

    b.MouseButton1Click:Connect(function()
        showPage(name)
    end)

    return b
end

--========================================================
-- CRIACAO DAS PAGINAS
--========================================================

local homePage = createPage("Principal")
local espPage = createPage("ESP")
local itemsPage = createPage("Itens")
local worldPage = createPage("Mundo")
local reportPage = createPage("Relatorio")
local settingsPage = createPage("Configuracoes")

createTab("Principal")
createTab("ESP")
createTab("Itens")
createTab("Mundo")
createTab("Relatorio")
createTab("Configuracoes")

--========================================================
-- PAGINA PRINCIPAL
--========================================================

section(homePage,"PAINEL PRINCIPAL")

local welcome = Instance.new("TextLabel")
welcome.Size = UDim2.new(1,-5,0,65)
welcome.BackgroundColor3 = Color3.fromRGB(28,28,34)
welcome.Text = "ROUBE OU MORRA " .. VERSION ..
    "\nPainel experimental criado por Tales"
welcome.TextColor3 = Color3.new(1,1,1)
welcome.TextSize = 13
welcome.Font = Enum.Font.GothamBold
welcome.Parent = homePage

local welcomeCorner = Instance.new("UICorner")
welcomeCorner.CornerRadius = UDim.new(0,7)
welcomeCorner.Parent = welcome

section(homePage,"ATALHOS")

toggle(homePage,"Coleta Instantanea","InstantCollection",setInstant)
toggle(homePage,"Remover Portas","RemoveDoors",setDoors)
toggle(homePage,"Brilho","Brightness",setBrightness)
toggle(homePage,"Anti-Flash","AntiFlash",setAntiFlash)

button(homePage,"ATUALIZAR TODOS OS ESP",function()
    refreshESP()
    updateStatus("ESP atualizado")
end)

--========================================================
-- PAGINA ESP
--========================================================

section(espPage,"ESP DE JOGADORES E MONSTROS")

toggle(espPage,"ESP Jogadores","ESPPlayers",refreshESP)
toggle(espPage,"ESP Monstros","ESPMonsters",refreshESP)
toggle(espPage,"Mostrar Nomes","ESPNames",refreshESP)
toggle(espPage,"ESP Dutos","ESPDucts",refreshESP)

button(espPage,"ATUALIZAR ESP",function()
    refreshESP()
    updateStatus("ESP atualizado")
end)

--========================================================
-- PAGINA ITENS
--========================================================

section(itemsPage,"ESP POR RARIDADE")

for _, rarity in ipairs({
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
    "Secret"
}) do
    rarityToggle(itemsPage,rarity)
end

button(itemsPage,"ATUALIZAR ESP DE ITENS",function()
    refreshESP()
    updateStatus("ESP de itens atualizado")
end)

--========================================================
-- PAGINA MUNDO
--========================================================

section(worldPage,"INTERACAO COM O MAPA")

toggle(worldPage,"Remover Portas e Tampas","RemoveDoors",setDoors)
toggle(worldPage,"Coleta Instantanea","InstantCollection",setInstant)

button(worldPage,"RESTAURAR PORTAS",function()
    states.RemoveDoors = false
    restoreDoors()
    updateStatus("Portas restauradas")
end)

button(worldPage,"RESTAURAR PROMPTS",function()
    states.InstantCollection = false

    for obj, duration in pairs(savedPrompts) do
        if obj and obj.Parent then
            safeCall(function()
                obj.HoldDuration = duration
            end)
        end
    end

    table.clear(savedPrompts)
    updateStatus("Prompts restaurados")
end)

section(worldPage,"ESTAMINA E RESISTENCIA")

button(worldPage,"PROCURAR DADOS DE ESTAMINA",function()
    local found = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if contains(obj.Name,{
            "stamina",
            "resistance",
            "resistencia",
            "energy",
            "energia",
            "endurance"
        }) then
            updateRecord(obj)
            found += 1
        end
    end

    updateStatus("Possiveis dados encontrados: " .. found)
end)

--========================================================
-- PAGINA RELATORIO
--========================================================

section(reportPage,"COLETOR DE DADOS")

local collectorToggle = toggle(
    reportPage,
    "Coleta Automatica de Dados",
    "DataCollector",
    function(enabled)
        updateStatus(enabled
            and "Coletor automatico ativado"
            or "Coletor automatico pausado")
    end
)

button(reportPage,"FAZER VARREDURA AGORA",function()
    local count, added = scanGame()

    if reportBox then
        reportBox.Text = exportData()
    end

    updateStatus(
        "Registros: " .. count ..
        " | Novos: " .. added
    )
end)

button(reportPage,"ATUALIZAR RELATORIO",function()
    if reportBox then
        reportBox.Text = exportData()
    end

    updateStatus("Relatorio atualizado")
end)

button(reportPage,"COPIAR RELATORIO",function()
    local copied = copyReport()

    if copied then
        updateStatus("Relatorio enviado para area de transferencia")
    else
        updateStatus("Clipboard indisponivel: selecione o texto e copie")
    end
end)

button(reportPage,"LIMPAR RELATORIO",function()
    table.clear(records)
    table.clear(recordIndex)

    totalDiscovered = 0
    scanCount = 0
    lastScan = "Nenhuma"

    if reportBox then
        reportBox.Text = ""
    end

    updateStatus("Relatorio limpo")
end)

reportBox = Instance.new("TextBox")
reportBox.Name = "ReportBox"
reportBox.Size = UDim2.new(1,-5,0,230)
reportBox.BackgroundColor3 = Color3.fromRGB(11,11,15)
reportBox.TextColor3 = Color3.fromRGB(230,230,230)
reportBox.PlaceholderText = "Os dados coletados aparecerao aqui..."
reportBox.PlaceholderColor3 = Color3.fromRGB(130,130,130)
reportBox.Text = ""
reportBox.TextSize = 10
reportBox.Font = Enum.Font.Code
reportBox.TextWrapped = false
reportBox.TextXAlignment = Enum.TextXAlignment.Left
reportBox.TextYAlignment = Enum.TextYAlignment.Top
reportBox.ClearTextOnFocus = false
reportBox.MultiLine = true
reportBox.TextEditable = true
reportBox.Parent = reportPage

local reportCorner = Instance.new("UICorner")
reportCorner.CornerRadius = UDim.new(0,6)
reportCorner.Parent = reportBox

section(reportPage,"INFORMACOES")

status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-5,0,36)
status.BackgroundColor3 = Color3.fromRGB(30,30,36)
status.TextColor3 = Color3.fromRGB(255,200,100)
status.Text = "Painel iniciado"
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.Parent = reportPage

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0,6)
statusCorner.Parent = status

--========================================================
-- PAGINA CONFIGURACOES
--========================================================

section(settingsPage,"CONFIGURACOES")

button(settingsPage,"RESTAURAR TODAS AS FUNCOES",function()
    states.RemoveDoors = false
    states.InstantCollection = false
    states.Brightness = false
    states.AntiFlash = false

    restoreDoors()

    for obj, duration in pairs(savedPrompts) do
        if obj and obj.Parent then
            safeCall(function()
                obj.HoldDuration = duration
            end)
        end
    end

    table.clear(savedPrompts)

    restoreFlashEffects()

    if savedLighting.Brightness ~= nil then
        Lighting.Brightness = savedLighting.Brightness
        Lighting.ClockTime = savedLighting.ClockTime
        Lighting.GlobalShadows = savedLighting.GlobalShadows
    end

    table.clear(savedLighting)

    for obj in pairs(highlights) do
        removeESP(obj)
    end

    for _, page in pairs(pageFrames) do
        for _, child in ipairs(page:GetChildren()) do
            if child:IsA("TextButton") then
                -- Os botoes mantem seus estados individuais.
            end
        end
    end

    updateStatus("Funcoes restauradas")
end)

button(settingsPage,"FECHAR PAINEL",function()
    gui:Destroy()
end)

--========================================================
-- NAVEGACAO INICIAL
--========================================================

showPage("Principal")

--========================================================
-- ARRASTAR PAINEL
--========================================================

local dragging = false
local dragStart
local startPosition

top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = frame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
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
-- BOTAO DE FECHAR
--========================================================

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

--========================================================
-- MONITORAMENTO DE OBJETOS NOVOS
--========================================================

connections.DescendantAdded = Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if not obj or not obj.Parent or shuttingDown then
            return
        end

        if states.RemoveDoors and isDoorPart(obj) then
            hidePart(obj)
        end

        if states.InstantCollection and obj:IsA("ProximityPrompt") then
            applyInstantPrompt(obj)
        end

        if states.DataCollector then
            if obj:IsA("Model")
                or obj:IsA("BasePart")
                or obj:IsA("ProximityPrompt")
                or obj:IsA("ValueBase") then

                safeCall(function()
                    updateRecord(obj)
                end)
            end
        end
    end)
end)

--========================================================
-- MONITORAMENTO CONTINUO
--========================================================

task.spawn(function()
    while gui.Parent and not shuttingDown do

        if states.ESPPlayers
            or states.ESPMonsters
            or states.ESPDucts then

            safeCall(refreshESP)

        else
            for obj in pairs(highlights) do
                removeESP(obj)
            end
        end

        task.wait(2)
    end
end)

--========================================================
-- COLETOR AUTOMATICO
--========================================================

task.spawn(function()
    while gui.Parent and not shuttingDown do

        if states.DataCollector then
            local ok, count, added = pcall(scanGame)

            if ok then
                updateStatus(
                    "Coletor ativo | Registros: "
                    .. tostring(count)
                    .. " | Novos: "
                    .. tostring(added)
                )
            end
        end

        task.wait(3)
    end
end)

--========================================================
-- MONITORAMENTO ANTI-FLASH
--========================================================

task.spawn(function()
    while gui.Parent and not shuttingDown do

        if states.AntiFlash then
            safeCall(scanFlashEffects)
        end

        task.wait(0.5)
    end
end)

--========================================================
-- MANTER PORTAS OCULTAS
--========================================================

task.spawn(function()
    while gui.Parent and not shuttingDown do

        if states.RemoveDoors then
            for part in pairs(hiddenParts) do
                if part and part.Parent then
                    safeCall(function()
                        part.LocalTransparencyModifier = 1
                        part.CanCollide = false
                        part.CanTouch = false
                        part.CanQuery = false
                    end)
                else
                    hiddenParts[part] = nil
                end
            end
        end

        task.wait(0.25)
    end
end)

--========================================================
-- MANTER COLETA INSTANTANEA
--========================================================

task.spawn(function()
    while gui.Parent and not shuttingDown do

        if states.InstantCollection then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    if savedPrompts[obj] == nil then
                        savedPrompts[obj] = obj.HoldDuration
                    end

                    if obj.HoldDuration ~= 0 then
                        obj.HoldDuration = 0
                    end
                end
            end
        end

        task.wait(1)
    end
end)

--========================================================
-- LIMPEZA
--========================================================

local function cleanup()
    if shuttingDown then
        return
    end

    shuttingDown = true

    states.RemoveDoors = false
    states.InstantCollection = false
    states.Brightness = false
    states.AntiFlash = false

    restoreDoors()
    restoreFlashEffects()

    for obj, duration in pairs(savedPrompts) do
        if obj and obj.Parent then
            safeCall(function()
                obj.HoldDuration = duration
            end)
        end
    end

    table.clear(savedPrompts)

    if savedLighting.Brightness ~= nil then
        safeCall(function()
            Lighting.Brightness = savedLighting.Brightness
            Lighting.ClockTime = savedLighting.ClockTime
            Lighting.GlobalShadows = savedLighting.GlobalShadows
        end)
    end

    for obj in pairs(highlights) do
        removeESP(obj)
    end

    for obj, connection in pairs(connections) do
        if connection then
            safeCall(function()
                connection:Disconnect()
            end)
        end
    end

    table.clear(connections)
end

gui.Destroying:Connect(cleanup)

--========================================================
-- FINALIZACAO
--========================================================

print("================================================")
print("ROUBE OU MORRA " .. VERSION .. " CARREGADO")
print("Feito por Tales")
print("Coletor de dados: pronto")
print("Relatorio acumulativo: pronto")
print("ESP: pronto")
print("Portas e coleta: pronto")
print("Anti-Flash: experimental")
print("================================================")
