
--========================================================
-- ROUBE OU MORRA V14
-- Feito por Tales
-- BASE: V13 ORIGINAL
-- ATUALIZACAO: PORTAS, DUTOS E RELATORIO
--========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("RoubeOuMorraV13")
if old then old:Destroy() end

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
    "locust","hollow","rictus","wendell","mimic",
    "o vazio","o ritus","o gafanhoto",
    "o fantasma materno","o inquilino"
}

local records = {}
local recordIndex = {}
local highlights = {}
local labels = {}
local hiddenParts = {}
local savedPrompts = {}
local savedLighting = {}

local scanCount = 0
local startTime = os.clock()
local lastScan = "Nenhuma"
local MAX_RECORDS = 12000

local status
local reportBox

--========================================================
-- FUNCOES AUXILIARES
--========================================================

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

local function getPlayerFromModel(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then
            return plr
        end
    end
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

    local attributes = {
        "IsMonster","Monster","IsEnemy","Enemy",
        "EntityType","NPCType","Role",
        "CharacterType","MonsterName"
    }

    for _, attr in ipairs(attributes) do
        local value = model:GetAttribute(attr)

        if value == true then
            return true
        end

        if type(value) == "string" and contains(value,{
            "monster","monstro","enemy",
            "inimigo","creature","entidade"
        }) then
            return true
        end
    end

    for _, child in ipairs(model:GetChildren()) do
        if contains(child.Name,{
            "monster","monstro","enemy","inimigo"
        }) then
            return true
        end

        for _, attr in ipairs(attributes) do
            local value = child:GetAttribute(attr)

            if value == true then
                return true
            end

            if type(value) == "string" and contains(value,{
                "monster","monstro","enemy","inimigo"
            }) then
                return true
            end
        end
    end

    return false
end

--========================================================
-- RARIDADES
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

    return nil
end

--========================================================
-- ESP
--========================================================

local function removeESP(obj)
    if highlights[obj] then
        highlights[obj]:Destroy()
        highlights[obj] = nil
    end

    if labels[obj] then
        labels[obj]:Destroy()
        labels[obj] = nil
    end
end

local function createESP(obj,color,textValue,small)
    if not obj or not obj.Parent then return end

    if not highlights[obj] then
        local h = Instance.new("Highlight")
        h.Name = "TalesESP"
        h.Adornee = obj
        h.FillTransparency = 0.85
        h.OutlineTransparency = 0
        h.Parent = obj
        highlights[obj] = h
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

    local part = obj:IsA("BasePart") and obj
        or obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChildWhichIsA("BasePart")

    if not part then return end

    if not labels[obj] then
        local gui = Instance.new("BillboardGui")
        gui.Name = "TalesESPLabel"
        gui.Adornee = part
        gui.AlwaysOnTop = true
        gui.Size = small and UDim2.fromOffset(130,22)
            or UDim2.fromOffset(180,30)
        gui.StudsOffset = Vector3.new(0,3,0)

        local txt = Instance.new("TextLabel")
        txt.Name = "TextLabel"
        txt.Size = UDim2.fromScale(1,1)
        txt.BackgroundTransparency = 1
        txt.TextScaled = true
        txt.Font = Enum.Font.GothamBold
        txt.TextStrokeTransparency = 0.2
        txt.Parent = gui

        gui.Parent = PlayerGui
        labels[obj] = gui
    end

    labels[obj].Adornee = part
    labels[obj].TextLabel.Text = textValue
    labels[obj].TextLabel.TextColor3 = color
end

local function refreshESP()
    local keep = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            -- Monstro sempre tem prioridade sobre jogador.
            if isMonster(obj) then
                if states.ESPMonsters then
                    createESP(
                        obj,
                        Color3.fromRGB(255,35,35),
                        states.ESPNames and obj.Name or nil,
                        false
                    )
                    keep[obj] = true
                end
            else
                local target = getPlayerFromModel(obj)

                if target and target ~= player and states.ESPPlayers then
                    createESP(
                        obj,
                        Color3.fromRGB(40,140,255),
                        states.ESPNames and target.Name or nil,
                        false
                    )
                    keep[obj] = true
                end
            end

            if states.ESPDucts and contains(obj.Name,{
                "duct","duto","vent"
            }) then
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

            if rarity and rarityEnabled[rarity]
                and not isMonster(obj) then

                local weight = obj:GetAttribute("Weight")
                    or obj:GetAttribute("Peso") or "?"

                local price = obj:GetAttribute("Value")
                    or obj:GetAttribute("Price")
                    or obj:GetAttribute("Valor") or "?"

                createESP(
                    obj,
                    rarityColors[rarity],
                    obj.Name .. " | " .. tostring(weight)
                        .. " | $" .. tostring(price),
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
-- V14: NAO REMOVE PAREDES LATERAIS DOS DUTOS
--========================================================

local function hidePart(part)
    if not part or not part:IsA("BasePart") then return end

    if not hiddenParts[part] then
        hiddenParts[part] = {
            Transparency = part.Transparency,
            LocalTransparencyModifier = part.LocalTransparencyModifier,
            CanCollide = part.CanCollide,
            CanTouch = part.CanTouch,
            CanQuery = part.CanQuery
        }
    end

    part.LocalTransparencyModifier = 1
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
end

local function restoreDoors()
    for part,data in pairs(hiddenParts) do
        if part and part.Parent then
            pcall(function()
                part.Transparency = data.Transparency
                part.LocalTransparencyModifier =
                    data.LocalTransparencyModifier
                part.CanCollide = data.CanCollide
                part.CanTouch = data.CanTouch
                part.CanQuery = data.CanQuery
            end)
        end
    end

    table.clear(hiddenParts)
end

local doorNames = {"door","porta"}

local ductCapNames = {
    "hatch","cover","lid","tampa",
    "escotilha","ductdoor","ventdoor","cap"
}

local function isDoorPart(obj)
    if not obj or not obj:IsA("BasePart") then
        return false
    end

    -- Procura a porta no proprio objeto ou em seus modelos ancestrais.
    local current = obj
    local depth = 0

    while current and depth < 8 do
        if contains(current.Name,doorNames) then
            return true
        end

        current = current.Parent
        depth += 1
    end

    return false
end

local function isDuctCapPart(obj)
    if not obj or not obj:IsA("BasePart") then
        return false
    end

    local current = obj
    local insideDuct = false
    local capFound = false
    local depth = 0

    while current and depth < 8 do
        if contains(current.Name,{
            "duct","duto","vent"
        }) then
            insideDuct = true
        end

        if contains(current.Name,ductCapNames) then
            capFound = true
        end

        current = current.Parent
        depth += 1
    end

    return insideDuct and capFound
end

local function setDoors(enabled)
    states.RemoveDoors = enabled

    if not enabled then
        restoreDoors()
        return
    end

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if isDoorPart(obj) or isDuctCapPart(obj) then
                hidePart(obj)
            end
        end
    end
end

--========================================================
-- COLETA INSTANTANEA
--========================================================

local function setInstant(enabled)
    states.InstantCollection = enabled

    if enabled then
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                if savedPrompts[obj] == nil then
                    savedPrompts[obj] = obj.HoldDuration
                end

                obj.HoldDuration = 0
            end
        end
    else
        for obj,duration in pairs(savedPrompts) do
            if obj and obj.Parent then
                pcall(function()
                    obj.HoldDuration = duration
                end)
            end
        end

        table.clear(savedPrompts)
    end
end

--========================================================
-- MONITORAMENTO DE NOVOS OBJETOS
--========================================================

local workspaceConnection

workspaceConnection = Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if not obj or not obj.Parent then return end

        if states.RemoveDoors and obj:IsA("BasePart") then
            if isDoorPart(obj) or isDuctCapPart(obj) then
                hidePart(obj)
            end
        end

        if states.InstantCollection
            and obj:IsA("ProximityPrompt") then

            if savedPrompts[obj] == nil then
                savedPrompts[obj] = obj.HoldDuration
            end

            obj.HoldDuration = 0
        end
    end)
end)

--========================================================
-- COLETOR DE DADOS
-- V14: ACUMULA REGISTROS DURANTE A PARTIDA
--========================================================

local function scanGame()
    scanCount += 1
    lastScan = os.date("%d/%m/%Y %H:%M:%S")

    local added = 0
    local updated = 0

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model")
            or obj:IsA("BasePart")
            or obj:IsA("ProximityPrompt") then

            local path = obj:GetFullName()
            local key = obj.ClassName .. "|" .. path

            local entry = {
                Name = obj.Name,
                Class = obj.ClassName,
                Path = path
            }

            local attrs = obj:GetAttributes()

            if next(attrs) then
                entry.Attributes = {}

                for attr,value in pairs(attrs) do
                    entry.Attributes[attr] = tostring(value)
                end
            end

            if obj:IsA("BasePart") then
                entry.Position = tostring(obj.Position)
                entry.CanCollide = tostring(obj.CanCollide)
            end

            if obj:IsA("ProximityPrompt") then
                entry.HoldDuration = tostring(obj.HoldDuration)
                entry.ActionText = obj.ActionText
                entry.ObjectText = obj.ObjectText
            end

            if recordIndex[key] then
                records[recordIndex[key]] = entry
                updated += 1
            elseif #records < MAX_RECORDS then
                table.insert(records,entry)
                recordIndex[key] = #records
                added += 1
            end
        end
    end

    return added,updated
end

local function exportData()
    local out = {
        "========================================",
        "ROUBE OU MORRA V14 - RELATORIO",
        "Feito por Tales",
        "Data: " .. os.date("%d/%m/%Y %H:%M:%S"),
        "Tempo de coleta: " ..
            tostring(math.floor(os.clock()-startTime)) .. " segundos",
        "Total de varreduras: " .. tostring(scanCount),
        "Total de registros acumulados: " .. tostring(#records),
        "Ultima varredura: " .. tostring(lastScan),
        "========================================"
    }

    for i,entry in ipairs(records) do
        table.insert(out,"")
        table.insert(out,"REGISTRO " .. i)

        for key,value in pairs(entry) do
            if type(value) == "table" then
                table.insert(out,tostring(key) .. ":")

                for subkey,subvalue in pairs(value) do
                    table.insert(out,
                        "  " .. tostring(subkey) ..
                        " = " .. tostring(subvalue))
                end
            else
                table.insert(out,
                    tostring(key) .. ": " .. tostring(value))
            end
        end
    end

    if #records == 0 then
        table.insert(out,"Nenhum registro coletado.")
    end

    return table.concat(out,"\n")
end

local function copyReport()
    local report = exportData()

    if reportBox then
        reportBox.Text = report
    end

    local clipboard

    pcall(function()
        if type(setclipboard) == "function" then
            clipboard = setclipboard
        elseif type(toclipboard) == "function" then
            clipboard = toclipboard
        end
    end)

    if clipboard then
        local success = pcall(clipboard,report)
        return success
    end

    return false
end

--========================================================
-- INTERFACE ORIGINAL V13
--========================================================

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV13"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(330,490)
frame.Position = UDim2.new(0.5,-165,0.5,-245)
frame.BackgroundColor3 = Color3.fromRGB(20,20,24)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,38)
title.BackgroundColor3 = Color3.fromRGB(125,20,25)
title.Text = "ROUBE OU MORRA V14 | Feito por Tales"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(8,45)
scroll.Size = UDim2.new(1,-16,1,-53)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,5)
layout.Parent = scroll

local function button(text,callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-5,0,31)
    b.BackgroundColor3 = Color3.fromRGB(48,48,55)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = text
    b.TextSize = 13
    b.Font = Enum.Font.Gotham
    b.Parent = scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,6)
    c.Parent = b

    b.MouseButton1Click:Connect(callback)
    return b
end

local function toggle(name,key,callback)
    local b

    b = button(name .. ": OFF",function()
        states[key] = not states[key]
        b.Text = name .. ": " ..
            (states[key] and "ON" or "OFF")

        if callback then
            callback(states[key])
        end
    end)
end

local function rarityToggle(rarity)
    local b

    b = button("ESP " .. rarity .. ": OFF",function()
        rarityEnabled[rarity] = not rarityEnabled[rarity]

        b.Text = "ESP " .. rarity .. ": " ..
            (rarityEnabled[rarity] and "ON" or "OFF")

        refreshESP()
    end)
end

toggle("ESP Jogadores","ESPPlayers",refreshESP)
toggle("ESP Monstros","ESPMonsters",refreshESP)
toggle("Mostrar Nomes","ESPNames",refreshESP)
toggle("ESP Dutos","ESPDucts",refreshESP)

for rarity in pairs(rarityEnabled) do
    rarityToggle(rarity)
end

toggle("Remover Portas e Tampas","RemoveDoors",setDoors)
toggle("Coleta Instantanea","InstantCollection",setInstant)

toggle("Brilho","Brightness",function(enabled)
    if enabled then
        savedLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            GlobalShadows = Lighting.GlobalShadows
        }

        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        if savedLighting.Brightness ~= nil then
            Lighting.Brightness = savedLighting.Brightness
            Lighting.ClockTime = savedLighting.ClockTime
            Lighting.GlobalShadows = savedLighting.GlobalShadows
        end
    end
end)

toggle("Anti-Flash Experimental","AntiFlash",function(enabled)
    if enabled then
        for _,effect in ipairs(Lighting:GetDescendants()) do
            if effect:IsA("BlurEffect")
                or effect:IsA("ColorCorrectionEffect") then

                if contains(effect.Name,{
                    "flash","blind","flashbang","clarão"
                }) then
                    effect.Enabled = false
                end
            end
        end
    end
end)

--========================================================
-- RELATORIO: CONTROLES CRIADOS ANTES DOS CALLBACKS
--========================================================

status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-5,0,25)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(255,200,100)
status.Text = "Painel iniciado"
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.Parent = scroll

reportBox = Instance.new("TextBox")
reportBox.Size = UDim2.new(1,-5,0,150)
reportBox.BackgroundColor3 = Color3.fromRGB(12,12,15)
reportBox.TextColor3 = Color3.new(1,1,1)
reportBox.PlaceholderText = "O relatorio aparecera aqui..."
reportBox.Text = ""
reportBox.TextSize = 10
reportBox.TextWrapped = false
reportBox.TextXAlignment = Enum.TextXAlignment.Left
reportBox.TextYAlignment = Enum.TextYAlignment.Top
reportBox.ClearTextOnFocus = false
reportBox.MultiLine = true
reportBox.Parent = scroll

button("FAZER VARREDURA AGORA",function()
    local added,updated = scanGame()

    reportBox.Text = exportData()
    status.Text = "Novos: " .. added ..
        " | Atualizados: " .. updated ..
        " | Total: " .. #records
end)

button("COPIAR RELATORIO",function()
    reportBox.Text = exportData()

    if copyReport() then
        status.Text = "Relatorio enviado para area de transferencia"
    else
        status.Text = "Clipboard indisponivel: copie pelo campo de texto"
    end
end)

button("LIMPAR RELATORIO",function()
    table.clear(records)
    table.clear(recordIndex)

    scanCount = 0
    startTime = os.clock()
    lastScan = "Nenhuma"

    reportBox.Text = ""
    status.Text = "Relatorio limpo"
end)

--========================================================
-- ARRASTAR PAINEL
--========================================================

local dragging = false
local dragStart
local startPosition

title.InputBegan:Connect(function(input)
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
-- ATUALIZACAO DO ESP
--========================================================

task.spawn(function()
    while gui.Parent do
        if states.ESPPlayers
            or states.ESPMonsters
            or states.ESPDucts then

            pcall(refreshESP)
        else
            for obj in pairs(highlights) do
                removeESP(obj)
            end
        end

        task.wait(2)
    end
end)

--========================================================
-- COLETA AUTOMATICA DO RELATORIO
--========================================================

task.spawn(function()
    while gui.Parent do
        if states.DataCollector then
            pcall(function()
                scanGame()
                if reportBox then
                    reportBox.Text = exportData()
                end
            end)
        end

        task.wait(3)
    end
end)

--========================================================
-- LIMPEZA
--========================================================

gui.Destroying:Connect(function()
    restoreDoors()
    setInstant(false)

    if workspaceConnection then
        workspaceConnection:Disconnect()
    end

    for obj in pairs(highlights) do
        removeESP(obj)
    end

    for obj in pairs(labels) do
        if labels[obj] then
            labels[obj]:Destroy()
        end
    end

    if savedLighting.Brightness ~= nil then
        Lighting.Brightness = savedLighting.Brightness
        Lighting.ClockTime = savedLighting.ClockTime
        Lighting.GlobalShadows = savedLighting.GlobalShadows
    end
end)

print("ROUBE OU MORRA V14 carregada - Feito por Tales")
