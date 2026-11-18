
--==============================================================
-- ROUBE OU MORRA V17 | Feito por Tales
-- Base V16 | Correcoes e organizacao por categorias
--==============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("RoubeOuMorraV17")
if old then old:Destroy() end

--==============================================================
-- CONFIGURACAO
--==============================================================

local SUPABASE_URL = "https://nqafhfadocgqkzboyxpp.supabase.co"
local COLLECTOR_TOKEN = "COLOQUE_SEU_TOKEN_ATUAL_AQUI"

local states = {
    ESPPlayers=false, ESPMonsters=false, ESPDucts=false,
    RemoveDoors=false, InstantCollection=false,
    Brightness=false, AntiFlash=false,
    DataCollector=false, AutoFarm=false
}

local rarityEnabled = {
    Common=false, Uncommon=false, Rare=false, Epic=false,
    Legendary=false, Mythic=false, Secret=false
}

local rarityColors = {
    Common=Color3.fromRGB(190,190,190),
    Uncommon=Color3.fromRGB(70,220,90),
    Rare=Color3.fromRGB(60,140,255),
    Epic=Color3.fromRGB(180,70,255),
    Legendary=Color3.fromRGB(255,190,30),
    Mythic=Color3.fromRGB(255,60,100),
    Secret=Color3.new(1,1,1)
}

local monsterNames = {
    "locust","hollow","rictus","wendell","mimic",
    "o vazio","o ritus","o gafanhoto","o fantasma materno",
    "o inquilino","sara","elden","the elder"
}

local highlights, labels = {}, {}
local hiddenParts, savedPrompts = {}, {}
local savedEffects, savedOverlays = {}, {}
local records, recordIndex = {}, {}
local sendQueue, queuedKeys, sentKeys = {}, {}, {}

local MAX_RECORDS = 12000
local MAX_COPY_CHARS = 12000

local sendBusy = false
local lastHttpStatus = "Aguardando envio"
local lastHttpBody = ""
local scanCount = 0
local startTime = os.clock()
local lastScan = "Nenhuma"
local sessionId = HttpService:GenerateGUID(false)

local gui, statusLabel, reportBox
local copyChunks = {}
local copyChunkIndex = 0

local sendRequest =
    (type(request) == "function" and request)
    or (type(http_request) == "function" and http_request)
    or (type(syn) == "table" and syn.request)

--==============================================================
-- UTILITARIOS
--==============================================================

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
        if plr.Character == model then return plr end
    end
end

local function isMonster(model)
    if not model or not model:IsA("Model") then return false end
    if getPlayerFromModel(model) then return false end
    if contains(model.Name, monsterNames) then return true end

    local ok, tags = pcall(function()
        return CollectionService:GetTags(model)
    end)

    if ok then
        for _, tag in ipairs(tags) do
            if contains(tag, {"monster","enemy","monstro","inimigo","creature"}) then
                return true
            end
        end
    end

    for _, key in ipairs({
        "IsMonster","Monster","IsEnemy","Enemy",
        "EntityType","NPCType","Role","CharacterType","MonsterName"
    }) do
        local value = model:GetAttribute(key)
        if value == true then return true end
        if type(value) == "string" and contains(value, {
            "monster","monstro","enemy","inimigo","creature","entidade"
        }) then return true end
    end

    return false
end

local function safeText(value)
    return tostring(value or "?")
end

--==============================================================
-- ESP
--==============================================================

local function getRarity(obj)
    for _, key in ipairs({"Rarity","Raridade"}) do
        local value = obj:GetAttribute(key)
        if type(value) == "string" then
            for rarity in pairs(rarityEnabled) do
                if value:lower() == rarity:lower() then return rarity end
            end
        end
    end
end

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

local function createESP(obj, color, textValue)
    if not obj or not obj.Parent then return end

    if not highlights[obj] then
        local h = Instance.new("Highlight")
        h.Name = "TalesESP"
        h.Adornee = obj
        h.FillTransparency = 0.85
        h.OutlineTransparency = 0
        h.Parent = PlayerGui
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
        local bill = Instance.new("BillboardGui")
        bill.Name = "TalesESPLabel"
        bill.AlwaysOnTop = true
        bill.Size = UDim2.fromOffset(185,30)
        bill.StudsOffset = Vector3.new(0,3,0)

        local txt = Instance.new("TextLabel")
        txt.Name = "TextLabel"
        txt.Size = UDim2.fromScale(1,1)
        txt.BackgroundTransparency = 1
        txt.TextScaled = true
        txt.Font = Enum.Font.GothamBold
        txt.TextStrokeTransparency = 0.2
        txt.TextColor3 = color
        txt.Parent = bill

        bill.Parent = PlayerGui
        labels[obj] = bill
    end

    labels[obj].Adornee = part
    labels[obj].TextLabel.Text = textValue
    labels[obj].TextLabel.TextColor3 = color
end

-- Verifica prompt habilitado, distancia e altura da entrada.
-- O contorno do duto nao recebe nome/label.
local function isUsableDuct(model)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = obj.Parent
            if part and part:IsA("Attachment") then
                part = part.Parent
            end

            if part and part:IsA("BasePart") then
                local distance = (part.Position-root.Position).Magnitude
                local vertical = math.abs(part.Position.Y-root.Position.Y)
                local limit = math.max(obj.MaxActivationDistance*3,30)

                if distance <= limit and vertical <= 12 then
                    return true
                end
            end
        end
    end

    return false
end

local function refreshESP()
    local keep = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            -- Monstros antes dos jogadores.
            if isMonster(obj) then
                if states.ESPMonsters then
                    createESP(obj,Color3.fromRGB(255,35,35),obj.Name)
                    keep[obj] = true
                end
            else
                local plr = getPlayerFromModel(obj)
                if plr and plr ~= player and states.ESPPlayers then
                    createESP(obj,Color3.fromRGB(40,140,255),plr.Name)
                    keep[obj] = true
                end
            end

            if states.ESPDucts and contains(obj.Name,{"duct","duto","vent"}) then
                if isUsableDuct(obj) then
                    createESP(obj,Color3.fromRGB(255,170,40),nil)
                    keep[obj] = true
                end
            end
        end

        if obj:IsA("Model") or obj:IsA("BasePart") then
            local rarity = getRarity(obj)
            local parentMonster =
                obj.Parent and obj.Parent:IsA("Model") and isMonster(obj.Parent)

            if rarity and rarityEnabled[rarity]
                and not (obj:IsA("Model") and isMonster(obj))
                and not parentMonster then

                local weight = obj:GetAttribute("Weight")
                    or obj:GetAttribute("Peso") or "?"
                local price = obj:GetAttribute("Value")
                    or obj:GetAttribute("Price")
                    or obj:GetAttribute("Valor") or "?"

                createESP(
                    obj,
                    rarityColors[rarity],
                    obj.Name.." | "..safeText(weight).." | $"..safeText(price)
                )
                keep[obj] = true
            end
        end
    end

    for obj in pairs(highlights) do
        if not keep[obj] then removeESP(obj) end
    end
end

--==============================================================
-- PORTAS E TAMPAS DE DUTOS
--==============================================================

local function isDoorPart(obj)
    local current = obj

    for _ = 1, 8 do
        if not current then break end

        if contains(current.Name, {
            "fridge","refrigerator","geladeira","freezer","cooler"
        }) then return false end

        if contains(current.Name, {
            "door","porta","doorleaf","door_leaf","hingeddoor"
        }) then return true end

        current = current.Parent
    end

    return false
end

local function isDuctCapPart(obj)
    local current = obj
    local inDuct, cap = false, false

    for _ = 1, 8 do
        if not current then break end

        if contains(current.Name,{"duct","duto","vent"}) then
            inDuct = true
        end

        if contains(current.Name,{
            "hatch","cover","lid","tampa","escotilha",
            "ductdoor","ventdoor"
        }) then
            cap = true
        end

        current = current.Parent
    end

    return inDuct and cap
end

local function hidePart(part)
    if not part or not part:IsA("BasePart") then return end

    if not hiddenParts[part] then
        hiddenParts[part] = {
            Transparency=part.Transparency,
            LocalTransparencyModifier=part.LocalTransparencyModifier,
            CanCollide=part.CanCollide,
            CanTouch=part.CanTouch,
            CanQuery=part.CanQuery
        }
    end

    pcall(function()
        part.LocalTransparencyModifier = 1
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
    end)
end

local function restoreDoors()
    for part, data in pairs(hiddenParts) do
        if part and part.Parent then
            pcall(function()
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

local function setDoors(enabled)
    states.RemoveDoors = enabled

    if not enabled then
        restoreDoors()
        return
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (isDoorPart(obj) or isDuctCapPart(obj)) then
            hidePart(obj)
        end
    end
end

--==============================================================
-- COLETA INSTANTANEA
--==============================================================

local function setInstant(enabled)
    states.InstantCollection = enabled

    if enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                if savedPrompts[obj] == nil then
                    savedPrompts[obj] = obj.HoldDuration
                end
                obj.HoldDuration = 0
            end
        end
    else
        for obj, duration in pairs(savedPrompts) do
            if obj and obj.Parent then
                pcall(function() obj.HoldDuration = duration end)
            end
        end
        table.clear(savedPrompts)
    end
end

--==============================================================
-- COLETOR / RELATORIOS
--==============================================================

local function queueReport(entry, key)
    if sentKeys[key] or queuedKeys[key] then return end

    table.insert(sendQueue,{
        record_key=key,
        payload=entry
    })

    queuedKeys[key] = true
end

local function scanGame()
    scanCount += 1
    lastScan = os.date("%d/%m/%Y %H:%M:%S")

    local added, updated = 0, 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart")
            or obj:IsA("ProximityPrompt") then

            local ok, path = pcall(function()
                return obj:GetFullName()
            end)
            path = ok and path or obj.Name

            local key = obj.ClassName.."|"..path
            local entry = {
                Name=obj.Name,
                Class=obj.ClassName,
                Path=path
            }

            local attrs = obj:GetAttributes()
            if next(attrs) then
                entry.Attributes = {}
                for k,v in pairs(attrs) do
                    entry.Attributes[k] = tostring(v)
                end
            end

            if obj:IsA("BasePart") then
                entry.Position = tostring(obj.Position)
                entry.CanCollide = tostring(obj.CanCollide)
            end

            if recordIndex[key] then
                records[recordIndex[key]] = entry
                updated += 1
            elseif #records < MAX_RECORDS then
                table.insert(records,entry)
                recordIndex[key] = #records
                added += 1
            end

            queueReport(entry,key)
        end
    end

    return added, updated
end

local function flushReports()
    if sendBusy or #sendQueue == 0 then return end

    if not sendRequest then
        lastHttpStatus = "ERRO: executor sem request()"
        lastHttpBody = "Este executor nao disponibilizou request/http_request."
        return
    end

    if COLLECTOR_TOKEN == "" or COLLECTOR_TOKEN == "COLOQUE_SEU_COLLECTOR_TOKEN_AQUI" then
        lastHttpStatus = "ERRO: token nao configurado"
        lastHttpBody = "Configure o COLLECTOR_TOKEN no inicio do script."
        return
    end

    sendBusy = true

    task.spawn(function()
        local sent = 0
        local failed = 0

        for _ = 1, math.min(10,#sendQueue) do
            local item = table.remove(sendQueue,1)

            local body = {
                session_id=sessionId,
                record_key=item.record_key,
                payload=item.payload
            }

            local ok, response = pcall(function()
                return sendRequest({
                    Url=SUPABASE_URL.."/functions/v1/ingest-report",
                    Method="POST",
                    Headers={
                        ["Content-Type"]="application/json",
                        ["x-collector-token"]=COLLECTOR_TOKEN
                    },
                    Body=HttpService:JSONEncode(body)
                })
            end)

            local code = 0
            local responseBody = ""

            if ok and type(response) == "table" then
                code = tonumber(response.StatusCode or response.Status) or 0
                responseBody = tostring(response.Body or response.body or "")
            elseif not ok then
                responseBody = tostring(response)
            end

            lastHttpStatus = "HTTP "..tostring(code)
            lastHttpBody = responseBody

            if ok and code >= 200 and code < 300 then
                sent += 1
                sentKeys[item.record_key] = true
                queuedKeys[item.record_key] = nil
            else
                failed += 1
                table.insert(sendQueue,1,item)
                break
            end
        end

        sendBusy = false

        if statusLabel then
            statusLabel.Text =
                "Envio: "..lastHttpStatus..
                " | Enviados: "..sent..
                " | Pendentes: "..#sendQueue..
                (failed > 0 and " | Falha - veja diagnostico" or "")
        end
    end)
end

local function exportData()
    local out = {
        "========================================",
        "ROUBE OU MORRA V17 - RELATORIO",
        "Feito por Tales",
        "Data: "..os.date("%d/%m/%Y %H:%M:%S"),
        "Tempo: "..math.floor(os.clock()-startTime).." segundos",
        "Varreduras: "..scanCount,
        "Registros: "..#records,
        "Ultima varredura: "..lastScan,
        "Sessao: "..sessionId,
        "========================================"
    }

    for i, entry in ipairs(records) do
        table.insert(out,"\nREGISTRO "..i)

        for k,v in pairs(entry) do
            if type(v) == "table" then
                table.insert(out,tostring(k)..":")
                for sk,sv in pairs(v) do
                    table.insert(out,"  "..tostring(sk).." = "..tostring(sv))
                end
            else
                table.insert(out,tostring(k)..": "..tostring(v))
            end
        end
    end

    if #records == 0 then
        table.insert(out,"Nenhum registro coletado.")
    end

    return table.concat(out,"\n")
end

local function makeCopyChunks()
    local full = exportData()
    copyChunks = {}
    copyChunkIndex = 0

    local startAt = 1
    while startAt <= #full do
        local finishAt = math.min(startAt+MAX_COPY_CHARS-1,#full)

        -- Evita cortar no meio de uma linha quando possivel.
        if finishAt < #full then
            local newline = string.find(full,"\n",finishAt,true)
            if newline and newline-finishAt < 500 then
                finishAt = newline
            end
        end

        table.insert(copyChunks,full:sub(startAt,finishAt))
        startAt = finishAt+1
    end

    if #copyChunks == 0 then
        copyChunks = {"Relatorio vazio."}
    end

    return #copyChunks
end

local function copyText(text)
    if type(setclipboard) == "function" then
        return pcall(setclipboard,text)
    end
    if type(toclipboard) == "function" then
        return pcall(toclipboard,text)
    end
    return false
end

local function copyNextChunk()
    if #copyChunks == 0 then
        makeCopyChunks()
    end

    copyChunkIndex += 1

    if copyChunkIndex > #copyChunks then
        copyChunkIndex = 1
    end

    local content = copyChunks[copyChunkIndex]
    local ok = copyText(content)

    if reportBox then reportBox.Text = content end

    return ok, copyChunkIndex, #copyChunks
end

--==============================================================
-- BRILHO
--==============================================================

local savedLighting = {}

local function setBrightness(enabled)
    states.Brightness = enabled

    if enabled then
        savedLighting = {
            Brightness=Lighting.Brightness,
            ClockTime=Lighting.ClockTime,
            GlobalShadows=Lighting.GlobalShadows,
            Ambient=Lighting.Ambient,
            OutdoorAmbient=Lighting.OutdoorAmbient
        }

        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200,200,200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
    else
        for key,value in pairs(savedLighting) do
            pcall(function() Lighting[key] = value end)
        end
        table.clear(savedLighting)
    end
end

--==============================================================
-- ANTI-FLASH
--==============================================================

local function looksLikeFlash(obj)
    return contains(obj.Name,{
        "flash","blind","flashbang","whiteout",
        "stunflash","flashscreen","flashoverlay","clarão"
    })
end

local function disableFlashEffect(obj)
    if not states.AntiFlash then return end

    if obj:IsA("BlurEffect")
        or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("BloomEffect") then

        if looksLikeFlash(obj) then
            if savedEffects[obj] == nil then
                savedEffects[obj] = obj.Enabled
            end
            pcall(function() obj.Enabled = false end)
        end
    end

    -- Desativa apenas overlays nomeados como flash/cegueira.
    -- Nao remove botoes nem itens da loja.
    if obj:IsA("Frame") or obj:IsA("ImageLabel") then
        if looksLikeFlash(obj) then
            if savedOverlays[obj] == nil then
                savedOverlays[obj] = obj.Visible
            end
            pcall(function() obj.Visible = false end)
        end
    end
end

local function setAntiFlash(enabled)
    states.AntiFlash = enabled

    if enabled then
        local roots = {Lighting,Workspace.CurrentCamera,PlayerGui}

        for _,root in ipairs(roots) do
            if root then
                for _,obj in ipairs(root:GetDescendants()) do
                    disableFlashEffect(obj)
                end
            end
        end
    else
        for obj,value in pairs(savedEffects) do
            if obj and obj.Parent then
                pcall(function() obj.Enabled = value end)
            end
        end

        for obj,value in pairs(savedOverlays) do
            if obj and obj.Parent then
                pcall(function() obj.Visible = value end)
            end
        end

        table.clear(savedEffects)
        table.clear(savedOverlays)
    end
end

--==============================================================
-- STAMINA - DIAGNOSTICO
--==============================================================

local function staminaReport()
    local found = {}

    for _,obj in ipairs(player:GetDescendants()) do
        local name = obj.Name:lower()

        if name:find("stamina",1,true)
            or name:find("resist",1,true)
            or name:find("energia",1,true)
            or name:find("endurance",1,true) then

            local value = obj.ClassName

            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                value = tostring(obj.Value)
            end

            table.insert(found,obj:GetFullName().." = "..value)
        end
    end

    return #found > 0 and table.concat(found,"\n")
        or "Nenhum valor local de stamina/resistencia encontrado."
end

--==============================================================
-- AUTO FARM
--==============================================================

local farmGeneration = 0

local function setAutoFarm(enabled)
    states.AutoFarm = enabled
    farmGeneration += 1

    local generation = farmGeneration
    if not enabled then return end

    task.spawn(function()
        while generation == farmGeneration and gui and gui.Parent do
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                for _,obj in ipairs(Workspace:GetDescendants()) do
                    if generation ~= farmGeneration then break end

                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local part = obj.Parent

                        if part and part:IsA("Attachment") then
                            part = part.Parent
                        end

                        if part and part:IsA("BasePart")
                            and (root.Position-part.Position).Magnitude <= obj.MaxActivationDistance then

                            pcall(function()
                                obj:InputHoldBegin()
                                task.wait(0.12)
                                obj:InputHoldEnd()
                            end)

                            task.wait(0.25)
                        end
                    end
                end
            end

            task.wait(0.45)
        end
    end)
end

--==============================================================
-- INTERFACE
--==============================================================

gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV17"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(650,440)
main.Position = UDim2.new(0.5,-325,0.5,-220)
main.BackgroundColor3 = Color3.fromRGB(17,17,21)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner",main).CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke",main)
stroke.Color = Color3.fromRGB(125,20,30)
stroke.Thickness = 1.5

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,48)
header.BackgroundColor3 = Color3.fromRGB(105,15,25)
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner",header).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-95,1,0)
title.Position = UDim2.fromOffset(16,0)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA V17  |  Feito por Tales"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(38,34)
minimize.Position = UDim2.new(1,-44,0,7)
minimize.Text = "—"
minimize.TextSize = 22
minimize.Font = Enum.Font.GothamBold
minimize.TextColor3 = Color3.new(1,1,1)
minimize.BackgroundColor3 = Color3.fromRGB(65,12,20)
minimize.Parent = header
Instance.new("UICorner",minimize).CornerRadius = UDim.new(0,7)

-- Quadradinho compacto para restaurar.
local restore = Instance.new("TextButton")
restore.Size = UDim2.fromOffset(42,42)
restore.Position = UDim2.new(0,14,0.5,-21)
restore.Text = "R"
restore.TextColor3 = Color3.new(1,1,1)
restore.Font = Enum.Font.GothamBold
restore.TextSize = 16
restore.BackgroundColor3 = Color3.fromRGB(135,18,30)
restore.Visible = false
restore.Parent = gui
Instance.new("UICorner",restore).CornerRadius = UDim.new(0,12)

local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.fromOffset(10,58)
sidebar.Size = UDim2.new(0,150,1,-68)
sidebar.BackgroundColor3 = Color3.fromRGB(23,23,28)
sidebar.BorderSizePixel = 0
sidebar.Parent = main
Instance.new("UICorner",sidebar).CornerRadius = UDim.new(0,8)

local sideLayout = Instance.new("UIListLayout",sidebar)
sideLayout.Padding = UDim.new(0,7)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(170,58)
content.Size = UDim2.new(1,-180,1,-68)
content.BackgroundColor3 = Color3.fromRGB(22,22,27)
content.BorderSizePixel = 0
content.Parent = main
Instance.new("UICorner",content).CornerRadius = UDim.new(0,8)

local pages, pageButtons = {}, {}
local currentPage

local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1,-16,1,-16)
    page.Position = UDim2.fromOffset(8,8)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new()
    page.Visible = false
    page.Parent = content

    local list = Instance.new("UIListLayout",page)
    list.Padding = UDim.new(0,7)
    list.SortOrder = Enum.SortOrder.LayoutOrder

    pages[name] = page
    return page
end

local function showPage(name)
    currentPage = name

    for n,p in pairs(pages) do
        p.Visible = (n == name)
    end

    for n,b in pairs(pageButtons) do
        b.BackgroundColor3 = (n == name)
            and Color3.fromRGB(135,22,36)
            or Color3.fromRGB(42,42,49)
    end
end

local function addSection(page,text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-6,0,27)
    label.BackgroundColor3 = Color3.fromRGB(65,18,26)
    label.TextColor3 = Color3.fromRGB(255,220,220)
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = page
    Instance.new("UICorner",label).CornerRadius = UDim.new(0,5)
end

local function addButton(page,text,callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-6,0,32)
    b.BackgroundColor3 = Color3.fromRGB(43,43,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = text
    b.TextSize = 12
    b.Font = Enum.Font.Gotham
    b.Parent = page
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function addToggle(page,name,key,callback)
    local track,knob,b

    b = addButton(page,"  "..name,function()
        states[key] = not states[key]
        local on = states[key]

        b.BackgroundColor3 = on
            and Color3.fromRGB(35,125,75)
            or Color3.fromRGB(43,43,50)

        track.BackgroundColor3 = on
            and Color3.fromRGB(30,155,85)
            or Color3.fromRGB(90,90,98)

        knob.Position = on
            and UDim2.new(1,-16,0.5,-7)
            or UDim2.new(0,2,0.5,-7)

        if callback then
            local ok,err = pcall(callback,on)
            if not ok then warn("[V17] "..name..": "..tostring(err)) end
        end
    end)

    b.TextXAlignment = Enum.TextXAlignment.Left

    track = Instance.new("Frame")
    track.Name = "ToggleTrack"
    track.Size = UDim2.fromOffset(34,18)
    track.Position = UDim2.new(1,-44,0.5,-9)
    track.BackgroundColor3 = Color3.fromRGB(90,90,98)
    track.BorderSizePixel = 0
    track.Parent = b
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    knob = Instance.new("Frame")
    knob.Name = "ToggleKnob"
    knob.Size = UDim2.fromOffset(14,14)
    knob.Position = UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(245,245,245)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    return b
end

local function addNav(name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-12,0,36)
    b.BackgroundColor3 = Color3.fromRGB(42,42,49)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = name
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = sidebar
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)

    b.MouseButton1Click:Connect(function()
        showPage(name)
    end)

    pageButtons[name] = b
end

local pMain = makePage("Principal")
local pESP = makePage("ESP")
local pEnv = makePage("Ambiente")
local pCollect = makePage("Coleta")
local pData = makePage("Dados")
local pConfig = makePage("Configurações")

for _,name in ipairs({
    "Principal","ESP","Ambiente","Coleta","Dados","Configurações"
}) do
    addNav(name)
end

-- PRINCIPAL: somente informacoes, sem funcoes.
addSection(pMain,"ROUBE OU MORRA")
local welcome = Instance.new("TextLabel")
welcome.Size = UDim2.new(1,-8,0,90)
welcome.BackgroundTransparency = 1
welcome.TextColor3 = Color3.fromRGB(235,220,220)
welcome.TextWrapped = true
welcome.TextSize = 14
welcome.Font = Enum.Font.Gotham
welcome.Text = "Painel V17 carregado.\nFeito por Tales.\nUse as categorias ao lado para acessar cada recurso."
welcome.Parent = pMain

-- ESP: todos os ESP ficam somente nesta categoria.
addSection(pESP,"ESP DE JOGADORES E ENTIDADES")
addToggle(pESP,"ESP Jogadores","ESPPlayers",refreshESP)
addToggle(pESP,"ESP Monstros","ESPMonsters",refreshESP)
addToggle(pESP,"ESP Dutos - somente acessiveis","ESPDucts",refreshESP)

addSection(pESP,"ESP DE ITENS POR RARIDADE")
for _,rarity in ipairs({
    "Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret"
}) do
    local b
    b = addButton(pESP,"ESP "..rarity.." [OFF]",function()
        rarityEnabled[rarity] = not rarityEnabled[rarity]
        b.Text = "ESP "..rarity..
            (rarityEnabled[rarity] and " [ON]" or " [OFF]")
        b.BackgroundColor3 = rarityEnabled[rarity]
            and Color3.fromRGB(100,35,120)
            or Color3.fromRGB(43,43,50)
        refreshESP()
    end)
end

-- AMBIENTE: portas, brilho e Anti-Flash.
addSection(pEnv,"MAPA E VISIBILIDADE")
addToggle(pEnv,"Remover Portas e Tampas de Dutos","RemoveDoors",setDoors)
addToggle(pEnv,"Brilho","Brightness",setBrightness)
addToggle(pEnv,"Anti-Flash","AntiFlash",setAntiFlash)

-- COLETA: recursos de interacao.
addSection(pCollect,"RECURSOS DE COLETA")
addToggle(pCollect,"Coleta Instantânea","InstantCollection",setInstant)
addToggle(pCollect,"Auto Farm - prompts no alcance","AutoFarm",setAutoFarm)

-- DADOS: envio e exportacao.
addSection(pData,"COLETOR AUTOMATICO DA PARTIDA")

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-6,0,42)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255,205,120)
statusLabel.Text = "Coletor parado"
statusLabel.TextWrapped = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.Parent = pData

reportBox = Instance.new("TextBox")
reportBox.Size = UDim2.new(1,-6,0,170)
reportBox.BackgroundColor3 = Color3.fromRGB(10,10,13)
reportBox.TextColor3 = Color3.new(1,1,1)
reportBox.PlaceholderText = "Relatorio ou parte copiada aparecera aqui..."
reportBox.Text = ""
reportBox.TextSize = 10
reportBox.TextWrapped = false
reportBox.TextXAlignment = Enum.TextXAlignment.Left
reportBox.TextYAlignment = Enum.TextYAlignment.Top
reportBox.ClearTextOnFocus = false
reportBox.MultiLine = true
reportBox.Parent = pData
Instance.new("UICorner",reportBox).CornerRadius = UDim.new(0,6)

addToggle(pData,"Coletor automatico durante a partida","DataCollector",function(enabled)
    if enabled then
        local added = scanGame()
        flushReports()
        statusLabel.Text =
            "Coleta ativa | Novos: "..added..
            " | Total: "..#records..
            " | Pendentes: "..#sendQueue
    else
        statusLabel.Text = "Coleta automatica pausada"
    end
end)

addButton(pData,"ATUALIZAR RELATORIO MANUAL",function()
    reportBox.Text = exportData()
    statusLabel.Text = "Relatorio atualizado localmente: "..#records.." registros"
end)

addButton(pData,"PREPARAR COPIA EM PARTES",function()
    local total = makeCopyChunks()
    statusLabel.Text =
        "Relatorio dividido em "..total..
        " partes. Use COPIAR PROXIMA PARTE."
    reportBox.Text = copyChunks[1]
end)

addButton(pData,"COPIAR PROXIMA PARTE",function()
    local ok,part,total = copyNextChunk()

    if ok then
        statusLabel.Text =
            "Parte "..part.." de "..total.." copiada."
    else
        statusLabel.Text =
            "Clipboard indisponivel. Selecione o texto exibido e copie."
    end
end)

addButton(pData,"VER DIAGNOSTICO DO ENVIO",function()
    reportBox.Text =
        "STATUS: "..lastHttpStatus..
        "\n\nRESPOSTA DO SERVIDOR:\n"..lastHttpBody..
        "\n\nPENDENTES: "..#sendQueue..
        "\nENVIADOS NESTA SESSAO: "..tostring((function()
            local n=0
            for _ in pairs(sentKeys) do n+=1 end
            return n
        end)())

    statusLabel.Text = "Diagnostico exibido no campo de texto."
end)

addButton(pData,"LIMPAR RELATORIO LOCAL",function()
    table.clear(records)
    table.clear(recordIndex)
    table.clear(copyChunks)
    copyChunkIndex = 0
    scanCount = 0
    startTime = os.clock()
    lastScan = "Nenhuma"
    reportBox.Text = ""
    statusLabel.Text = "Registros locais limpos. Fila de envio preservada."
end)

-- CONFIGURACOES E DIAGNOSTICO.
addSection(pConfig,"DIAGNOSTICO E CONFIGURACOES")

addButton(pConfig,"VERIFICAR VALORES DE STAMINA",function()
    reportBox.Text = staminaReport()
    statusLabel.Text = "Diagnostico local concluido."
    showPage("Dados")
end)

addButton(pConfig,"RESTAURAR PORTAS E EFEITOS",function()
    setDoors(false)
    setAntiFlash(false)
    setBrightness(false)
    statusLabel.Text = "Valores locais restaurados."
end)

addButton(pConfig,"FECHAR PAINEL",function()
    gui:Destroy()
end)

showPage("Principal")

--==============================================================
-- ARRASTAR E MINIMIZAR
--==============================================================

local dragging = false
local dragStart, startPosition

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
        local delta = input.Position-dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset+delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset+delta.Y
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
-- NOVOS OBJETOS E ATUALIZACAO
--==============================================================

Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if not obj or not obj.Parent then return end

        if states.RemoveDoors and obj:IsA("BasePart")
            and (isDoorPart(obj) or isDuctCapPart(obj)) then
            hidePart(obj)
        end

        if states.InstantCollection and obj:IsA("ProximityPrompt") then
            if savedPrompts[obj] == nil then
                savedPrompts[obj] = obj.HoldDuration
            end
            obj.HoldDuration = 0
        end
    end)
end)

local function watchFlashRoot(root)
    if not root then return end

    root.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if states.AntiFlash then
                disableFlashEffect(obj)
            end
        end)
    end)
end

watchFlashRoot(Lighting)
watchFlashRoot(PlayerGui)

task.spawn(function()
    while gui and gui.Parent do
        if states.ESPPlayers or states.ESPMonsters or states.ESPDucts then
            refreshESP()
        else
            local anyRarity = false
            for _,enabled in pairs(rarityEnabled) do
                if enabled then anyRarity = true break end
            end

            if anyRarity then
                refreshESP()
            end
        end

        if states.RemoveDoors then
            for _,obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart")
                    and (isDoorPart(obj) or isDuctCapPart(obj)) then
                    hidePart(obj)
                end
            end
        end

        if states.AntiFlash then
            setAntiFlash(true)
        end

        if states.DataCollector then
            local added = scanGame()
            flushReports()

            if statusLabel and not sendBusy then
                statusLabel.Text =
                    "Coleta ativa | Novos: "..added..
                    " | Total: "..#records..
                    " | Pendentes: "..#sendQueue..
                    " | "..lastHttpStatus
            end
        end

        task.wait(states.DataCollector and 8 or 1.5)
    end
end)

--==============================================================
-- LIMPEZA
--==============================================================

gui.Destroying:Connect(function()
    farmGeneration += 1

    restoreDoors()
    setInstant(false)
    setBrightness(false)
    setAntiFlash(false)

    for obj in pairs(highlights) do
        removeESP(obj)
    end

    for obj,bill in pairs(labels) do
        if bill then bill:Destroy() end
        labels[obj] = nil
    end
end)

print("ROUBE OU MORRA V17 CARREGADO | Feito por Tales")
