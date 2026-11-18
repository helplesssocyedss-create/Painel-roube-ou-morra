--==============================================================
-- ROUBE OU MORRA V19 | Feito por Tales
-- Portas | ESP Dutos | Stamina | Coleta online e manual
--==============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("RoubeOuMorraV19")
if old then old:Destroy() end

local gui

local states = {
    ESPPlayers=false, ESPMonsters=false, ESPDucts=false,
    RemoveDoors=false, InstantCollection=false,
    Brightness=false, AntiFlash=false,
    DataCollector=false, AutoFarm=false,
    InfiniteStamina=false
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
local savedLighting = {}

local records, recordIndex = {}, {}
local sentKeys, queuedKeys, sendQueue = {}, {}, {}

local MAX_RECORDS = 12000
local statusLabel
local reportBox
local tokenBox
local sendBusy = false
local senderRunning = false
local lastHTTP = "Aguardando envio"
local scanCount = 0
local startTime = os.clock()
local lastScan = "Nenhuma"
local COLLECTOR_TOKEN = ""

local SUPABASE_URL = "https://nqafhfadocgqkzboyxpp.supabase.co"

local sendRequest =
    (type(request)=="function" and request)
    or (type(http_request)=="function" and http_request)
    or (type(syn)=="table" and syn.request)
    or (type(http)=="table" and http.request)

local sessionId
pcall(function()
    sessionId = HttpService:GenerateGUID(false)
end)
sessionId = sessionId or tostring(os.time()).."-"..tostring(math.random(100000,999999))

local function contains(value,list)
    value = string.lower(tostring(value or ""))
    for _,word in ipairs(list) do
        if string.find(value,string.lower(word),1,true) then
            return true
        end
    end
    return false
end

local function getPlayerFromModel(model)
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then
            return plr
        end
    end
end

local function isMonster(model)
    if not model or not model:IsA("Model") then return false end
    if getPlayerFromModel(model) then return false end

    if contains(model.Name,monsterNames) then return true end

    local ok,tags = pcall(function()
        return CollectionService:GetTags(model)
    end)

    if ok and tags then
        for _,tag in ipairs(tags) do
            if contains(tag,{"monster","enemy","monstro","inimigo","creature"}) then
                return true
            end
        end
    end

    for _,key in ipairs({
        "IsMonster","Monster","IsEnemy","Enemy",
        "EntityType","NPCType","Role","CharacterType","MonsterName"
    }) do
        local value = model:GetAttribute(key)
        if value == true then return true end
        if type(value)=="string" and contains(value,{
            "monster","monstro","enemy","inimigo","creature"
        }) then
            return true
        end
    end

    return false
end

local function getRarity(obj)
    for _,key in ipairs({"Rarity","Raridade"}) do
        local value = obj:GetAttribute(key)
        if type(value)=="string" then
            for rarity in pairs(rarityEnabled) do
                if value:lower()==rarity:lower() then
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
        h.FillTransparency = 0.88
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
        bill.Size = small and UDim2.fromOffset(155,24)
            or UDim2.fromOffset(185,30)
        bill.StudsOffset = Vector3.new(0,3,0)

        local txt = Instance.new("TextLabel")
        txt.Name = "TextLabel"
        txt.Size = UDim2.fromScale(1,1)
        txt.BackgroundTransparency = 1
        txt.TextScaled = true
        txt.Font = Enum.Font.GothamBold
        txt.TextStrokeTransparency = 0.2
        txt.Parent = bill

        bill.Parent = PlayerGui
        labels[obj] = bill
    end

    labels[obj].Adornee = part
    labels[obj].TextLabel.Text = textValue
    labels[obj].TextLabel.TextColor3 = color
end

-- Procura dutos pelo nome, tags, atributos e prompts.
-- Não depende apenas do nome do Model.
local function isDuctObject(obj)
    if not obj then return false end

    local current = obj
    for _=1,10 do
        if not current then break end

        if contains(current.Name,{"duct","duto","vent","airvent"}) then
            return true
        end

        for _,key in ipairs({"Type","ObjectType","Category","Kind"}) do
            local value = current:GetAttribute(key)
            if type(value)=="string"
                and contains(value,{"duct","duto","vent"}) then
                return true
            end
        end

        current = current.Parent
    end

    local ok,tags = pcall(function()
        return CollectionService:GetTags(obj)
    end)

    if ok and tags then
        for _,tag in ipairs(tags) do
            if contains(tag,{"duct","duto","vent"}) then
                return true
            end
        end
    end

    return false
end

local function hasDuctPrompt(obj)
    for _,item in ipairs(obj:GetDescendants()) do
        if item:IsA("ProximityPrompt") then
            if contains(item.ActionText.." "..item.ObjectText,{
                "duct","duto","vent","entrar","crawl"
            }) then
                return true
            end
        end
    end
    return false
end

local function isUsableDuct(obj)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return true end

    local foundPrompt = false

    for _,item in ipairs(obj:GetDescendants()) do
        if item:IsA("ProximityPrompt") and item.Enabled then
            foundPrompt = true

            local part = item.Parent
            if part and part:IsA("Attachment") then
                part = part.Parent
            end

            if part and part:IsA("BasePart") then
                local distance = (root.Position-part.Position).Magnitude
                local allowed = math.max(item.MaxActivationDistance*4,60)

                if distance <= allowed then
                    return true
                end
            end
        end
    end

    -- Dutos sem prompt também podem receber ESP.
    return not foundPrompt
end

local function refreshESP()
    local keep = {}

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            if isMonster(obj) then
                if states.ESPMonsters then
                    createESP(obj,Color3.fromRGB(255,35,35),obj.Name,false)
                    keep[obj] = true
                end
            else
                local plr = getPlayerFromModel(obj)
                if plr and plr~=player and states.ESPPlayers then
                    createESP(obj,Color3.fromRGB(40,140,255),plr.Name,false)
                    keep[obj] = true
                end
            end
        end

        if states.ESPDucts and (obj:IsA("Model") or obj:IsA("BasePart")) then
            if isDuctObject(obj) or hasDuctPrompt(obj) then
                if isUsableDuct(obj) then
                    createESP(obj,Color3.fromRGB(255,170,40),nil,true)
                    keep[obj] = true
                end
            end
        end

        if obj:IsA("Model") or obj:IsA("BasePart") then
            local rarity = getRarity(obj)
            local parentMonster = obj.Parent
                and obj.Parent:IsA("Model")
                and isMonster(obj.Parent)

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
                    obj.Name.." | "..tostring(weight).." | $"..tostring(price),
                    true
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
-- PORTAS E TAMPAS
--==============================================================

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

    pcall(function()
        part.LocalTransparencyModifier = 1
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
    end)
end

local function restoreDoors()
    for part,data in pairs(hiddenParts) do
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

local function isDoorPart(obj)
    local current = obj

    for _=1,10 do
        if not current then break end

        if contains(current.Name,{
            "fridge","refrigerator","geladeira","freezer","cooler"
        }) then
            return false
        end

        if contains(current.Name,{
            "door","porta","doorleaf","door_leaf",
            "hingeddoor","doorframe","doorpart"
        }) then
            return true
        end

        current = current.Parent
    end

    return false
end

local function isDuctCapPart(obj)
    local current = obj
    local inDuct = false
    local cap = false

    for _=1,10 do
        if not current then break end

        if contains(current.Name,{"duct","duto","vent"}) then
            inDuct = true
        end

        if contains(current.Name,{
            "hatch","cover","lid","tampa","escotilha",
            "ductdoor","ventdoor","door"
        }) then
            cap = true
        end

        current = current.Parent
    end

    return inDuct and cap
end

local function setDoors(enabled)
    states.RemoveDoors = enabled

    if not enabled then
        restoreDoors()
        return
    end

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart")
            and (isDoorPart(obj) or isDuctCapPart(obj)) then
            hidePart(obj)
        end
    end
end

-- Reaplica a colisão local frequentemente.
-- Isso combate alterações de estado feitas pelo jogo ao abrir/fechar.
local function refreshDoorCollision()
    if not states.RemoveDoors then return end

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart")
            and (isDoorPart(obj) or isDuctCapPart(obj)) then
            hidePart(obj)
        end
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if not obj or not obj.Parent then return end

        if states.RemoveDoors and obj:IsA("BasePart")
            and (isDoorPart(obj) or isDuctCapPart(obj)) then
            hidePart(obj)
        end

        if states.InstantCollection and obj:IsA("ProximityPrompt") then
            if savedPrompts[obj]==nil then
                savedPrompts[obj] = obj.HoldDuration
            end
            pcall(function()
                obj.HoldDuration = 0
            end)
        end
    end)
end)

--==============================================================
-- COLETA INSTANTÂNEA
--==============================================================

local function setInstant(enabled)
    states.InstantCollection = enabled

    if enabled then
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                if savedPrompts[obj]==nil then
                    savedPrompts[obj] = obj.HoldDuration
                end
                pcall(function()
                    obj.HoldDuration = 0
                end)
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

--==============================================================
-- COLETOR ONLINE
--==============================================================

local function queueReport(entry,key)
    if sentKeys[key] or queuedKeys[key] then return end

    table.insert(sendQueue,{
        record_key = key,
        payload = entry
    })

    queuedKeys[key] = true
end

local function getHTTPError(res,code)
    local body = tostring(res and res.Body or "")

    if code==401 or code==403 then
        return "Token recusado (HTTP "..code..")"
    elseif code==404 then
        return "Função ingest-report não encontrada (HTTP 404)"
    elseif code==429 then
        return "Limite de requisições atingido (HTTP 429)"
    elseif code>=500 then
        return "Erro no servidor Supabase (HTTP "..code..")"
    elseif code==0 then
        return "Falha de rede ou request()"
    end

    if body~="" then
        return "HTTP "..code..": "..string.sub(body,1,180)
    end

    return "Falha HTTP "..code
end

local function sendOne(item)
    if not sendRequest then
        return false,"Executor sem suporte a request()"
    end

    if COLLECTOR_TOKEN=="" then
        return false,"Informe o token do coletor no campo da página Dados"
    end

    local body = {
        session_id = sessionId,
        record_key = item.record_key,
        payload = item.payload
    }

    local ok,res = pcall(function()
        return sendRequest({
            Url = SUPABASE_URL.."/functions/v1/ingest-report",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["x-collector-token"] = COLLECTOR_TOKEN
            },
            Body = HttpService:JSONEncode(body)
        })
    end)

    if not ok then
        return false,"Erro request(): "..tostring(res)
    end

    local code = tonumber(res.StatusCode or res.Status) or 0

    if code>=200 and code<300 then
        return true,"HTTP "..code
    end

    if code==409 then
        return true,"Registro já existente"
    end

    return false,getHTTPError(res,code)
end

local function flushReports()
    if sendBusy or #sendQueue==0 then return end

    if not sendRequest then
        lastHTTP = "Executor sem suporte a request()"
        if statusLabel then statusLabel.Text = lastHTTP end
        return
    end

    if COLLECTOR_TOKEN=="" then
        lastHTTP = "Token não informado"
        if statusLabel then statusLabel.Text = lastHTTP end
        return
    end

    sendBusy = true

    task.spawn(function()
        local sent = 0
        local failed = false

        -- Envio contínuo, sem esperar pela próxima varredura.
        while #sendQueue>0 and states.DataCollector do
            local item = table.remove(sendQueue,1)
            if not item then break end

            local ok,message = sendOne(item)

            if ok then
                sentKeys[item.record_key] = true
                queuedKeys[item.record_key] = nil
                sent += 1
                lastHTTP = message
            else
                table.insert(sendQueue,1,item)
                failed = true
                lastHTTP = message
                break
            end

            if statusLabel then
                statusLabel.Text =
                    "Enviados: "..sent
                    .." | Pendentes: "..#sendQueue
                    .." | "..lastHTTP
            end

            task.wait(0.15)
        end

        sendBusy = false

        if statusLabel then
            statusLabel.Text =
                "Envio online | Nesta rodada: "..sent
                .." | Pendentes: "..#sendQueue
                .." | "..lastHTTP
        end

        if failed then
            task.wait(3)
            if states.DataCollector and #sendQueue>0 then
                flushReports()
            end
        end
    end)
end

--==============================================================
-- VARREDURA
--==============================================================

local function scanGame()
    scanCount += 1
    lastScan = os.date("%d/%m/%Y %H:%M:%S")

    local added,updated = 0,0

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart")
            or obj:IsA("ProximityPrompt") then

            local ok,path = pcall(function()
                return obj:GetFullName()
            end)

            path = ok and path or obj.Name

            local key = obj.ClassName.."|"..path

            local entry = {
                Name = obj.Name,
                Class = obj.ClassName,
                Path = path
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
                entry.Size = tostring(obj.Size)
            elseif obj:IsA("ProximityPrompt") then
                entry.HoldDuration = obj.HoldDuration
                entry.ActionText = obj.ActionText
                entry.ObjectText = obj.ObjectText
                entry.Enabled = obj.Enabled
                entry.MaxActivationDistance = obj.MaxActivationDistance
            end

            if recordIndex[key] then
                records[recordIndex[key]] = entry
                updated += 1
            elseif #records<MAX_RECORDS then
                table.insert(records,entry)
                recordIndex[key] = #records
                added += 1
            end

            queueReport(entry,key)
        end
    end

    return added,updated
end

--==============================================================
-- RELATÓRIO MANUAL INTEGRAL
--==============================================================

local function exportData()
    local out = {
        "========================================",
        "ROUBE OU MORRA V19 - RELATORIO",
        "Feito por Tales",
        "Data: "..os.date("%d/%m/%Y %H:%M:%S"),
        "Tempo de coleta: "..math.floor(os.clock()-startTime).." segundos",
        "Varreduras: "..scanCount,
        "Registros acumulados: "..#records,
        "Ultima varredura: "..lastScan,
        "========================================"
    }

    for i,e in ipairs(records) do
        table.insert(out,"\nREGISTRO "..i)

        for k,v in pairs(e) do
            if type(v)=="table" then
                table.insert(out,tostring(k)..":")
                for sk,sv in pairs(v) do
                    table.insert(out,"  "..tostring(sk).." = "..tostring(sv))
                end
            else
                table.insert(out,tostring(k)..": "..tostring(v))
            end
        end
    end

    if #records==0 then
        table.insert(out,"Nenhum registro coletado.")
    end

    return table.concat(out,"\n")
end

local function copyFullReport()
    local full = exportData()

    if reportBox then
        reportBox.Text = full
    end

    local clipboard =
        (type(setclipboard)=="function" and setclipboard)
        or (type(toclipboard)=="function" and toclipboard)

    if clipboard then
        local ok,err = pcall(clipboard,full)

        if ok then
            if statusLabel then
                statusLabel.Text =
                    "Relatório integral copiado: "
                    ..#full.." caracteres | "
                    ..#records.." registros"
            end
        else
            if statusLabel then
                statusLabel.Text =
                    "Clipboard falhou: "..tostring(err)
                    .." | Use o campo e selecione todo o texto"
            end
        end
    else
        if statusLabel then
            statusLabel.Text =
                "Relatório integral no campo. Toque nele, selecione tudo e copie."
        end
    end
end

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
        for k,v in pairs(savedLighting) do
            pcall(function()
                Lighting[k] = v
            end)
        end
        table.clear(savedLighting)
    end
end

--==============================================================
-- ANTI-FLASH
--==============================================================

local function effectLooksLikeFlash(obj)
    return contains(obj.Name,{
        "flash","blind","flashbang","clarão",
        "stunflash","whiteout","flash_effect","blindness"
    })
end

local function isInsideShop(obj)
    local current = obj

    for _=1,10 do
        if not current then break end
        if contains(current.Name,{"shop","store","loja","market"}) then
            return true
        end
        current = current.Parent
    end

    return false
end

local function inspectFlashObject(obj)
    if not states.AntiFlash or not obj or isInsideShop(obj) then
        return
    end

    if (obj:IsA("BlurEffect")
        or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("BloomEffect"))
        and effectLooksLikeFlash(obj) then

        if savedEffects[obj]==nil then
            savedEffects[obj] = obj.Enabled
        end

        pcall(function()
            obj.Enabled = false
        end)
    end

    if obj:IsA("Frame") or obj:IsA("ImageLabel") then
        local size = obj.AbsoluteSize
        local screen = PlayerGui.AbsoluteSize

        if screen.X>0 and screen.Y>0
            and size.X>=screen.X*0.80
            and size.Y>=screen.Y*0.80 then

            local white = false

            if obj:IsA("Frame") then
                local c = obj.BackgroundColor3
                white = c.R>0.82 and c.G>0.82 and c.B>0.82
                    and obj.BackgroundTransparency<0.35
            else
                white = obj.ImageTransparency<0.25
            end

            if white then
                if savedOverlays[obj]==nil then
                    savedOverlays[obj] = obj.Visible
                end
                pcall(function()
                    obj.Visible = false
                end)
            end
        end
    end
end

local function inspectFlashRoot(root)
    if not root then return end
    for _,obj in ipairs(root:GetDescendants()) do
        inspectFlashObject(obj)
    end
end

local function setAntiFlash(enabled)
    states.AntiFlash = enabled

    if enabled then
        inspectFlashRoot(Lighting)
        inspectFlashRoot(PlayerGui)
        inspectFlashRoot(Workspace.CurrentCamera)
    else
        for obj,value in pairs(savedEffects) do
            if obj and obj.Parent then
                pcall(function()
                    obj.Enabled = value
                end)
            end
        end
        table.clear(savedEffects)

        for obj,value in pairs(savedOverlays) do
            if obj and obj.Parent then
                pcall(function()
                    obj.Visible = value
                end)
            end
        end
        table.clear(savedOverlays)
    end
end

Lighting.DescendantAdded:Connect(function(obj)
    task.defer(function() inspectFlashObject(obj) end)
end)

PlayerGui.DescendantAdded:Connect(function(obj)
    task.defer(function() inspectFlashObject(obj) end)
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if states.AntiFlash then
        inspectFlashRoot(Workspace.CurrentCamera)
    end
end)

--==============================================================
-- STAMINA
--==============================================================

local staminaOriginals = {}
local staminaModuleTable
local staminaPatched = {}

local function isStaminaName(name)
    return contains(name,{
        "stamina","sprint","energy","energia",
        "resist","endurance","folego","fôlego"
    })
end

local function patchStaminaTable(tbl,depth)
    if type(tbl)~="table" or depth>7 then return end

    for key,value in pairs(tbl) do
        if type(value)=="number" and isStaminaName(tostring(key)) then
            pcall(function()
                tbl[key] = 999999
            end)
        elseif type(value)=="table" then
            patchStaminaTable(value,depth+1)
        end
    end
end

local function patchFunctionUpvalues(fn)
    if type(fn)~="function" then return end

    local dbg = debug
    if not dbg or type(dbg.getupvalue)~="function" then
        return
    end

    for index=1,100 do
        local ok,name,value = pcall(dbg.getupvalue,fn,index)

        if not ok or name==nil then
            break
        end

        if type(value)=="number" and isStaminaName(tostring(name)) then
            if type(dbg.setupvalue)=="function" then
                pcall(dbg.setupvalue,fn,index,999999)
            end
        elseif type(value)=="table" then
            patchStaminaTable(value,0)
        elseif type(value)=="function" then
            if not staminaPatched[value] then
                staminaPatched[value] = true
                patchFunctionUpvalues(value)
            end
        end
    end
end

local function rememberAndSetValue(obj)
    if not obj then return end

    if obj:IsA("NumberValue") or obj:IsA("IntValue") then
        if staminaOriginals[obj]==nil then
            staminaOriginals[obj] = obj.Value
        end

        pcall(function()
            obj.Value = 999999
        end)
    end
end

local function findStaminaObjects()
    local found = {}

    for _,obj in ipairs(player:GetDescendants()) do
        if isStaminaName(obj.Name) then
            table.insert(found,obj)
            rememberAndSetValue(obj)
        end
    end

    local scripts = player:FindFirstChild("PlayerScripts")
    local module = scripts and scripts:FindFirstChild("SprintStamina")

    if module and module:IsA("ModuleScript") then
        local ok,result = pcall(require,module)

        if ok then
            if type(result)=="table" then
                staminaModuleTable = result
                patchStaminaTable(result,0)

                for _,value in pairs(result) do
                    if type(value)=="function" then
                        patchFunctionUpvalues(value)
                    end
                end
            elseif type(result)=="function" then
                patchFunctionUpvalues(result)
            end

            table.insert(found,module)
        end
    end

    local hud = player:FindFirstChild("PlayerGui")
        and player.PlayerGui:FindFirstChild("StaminaHUD")

    if hud then
        table.insert(found,hud)
    end

    return found
end

local function setInfiniteStamina(enabled)
    states.InfiniteStamina = enabled

    if enabled then
        findStaminaObjects()
    else
        for obj,value in pairs(staminaOriginals) do
            if obj and obj.Parent then
                pcall(function()
                    obj.Value = value
                end)
            end
        end

        table.clear(staminaOriginals)
        table.clear(staminaPatched)
        staminaModuleTable = nil
    end
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
        while generation==farmGeneration and gui and gui.Parent do
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                for _,obj in ipairs(Workspace:GetDescendants()) do
                    if generation~=farmGeneration then break end

                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local part = obj.Parent

                        if part and part:IsA("Attachment") then
                            part = part.Parent
                        end

                        if part and part:IsA("BasePart")
                            and (root.Position-part.Position).Magnitude
                                <= obj.MaxActivationDistance then

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
gui.Name = "RoubeOuMorraV19"
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
title.Text = "ROUBE OU MORRA V19  |  Feito por Tales"
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

local restore = Instance.new("TextButton")
restore.Size = UDim2.fromOffset(38,38)
restore.Position = UDim2.new(0,16,0.5,-19)
restore.Text = "R"
restore.TextColor3 = Color3.new(1,1,1)
restore.Font = Enum.Font.GothamBold
restore.TextSize = 15
restore.BackgroundColor3 = Color3.fromRGB(135,18,30)
restore.Visible = false
restore.Parent = gui
Instance.new("UICorner",restore).CornerRadius = UDim.new(0,10)

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
    for n,p in pairs(pages) do
        p.Visible = n==name
    end

    for n,b in pairs(pageButtons) do
        b.BackgroundColor3 = n==name
            and Color3.fromRGB(135,22,36)
            or Color3.fromRGB(42,42,49)
    end
end

local function addSection(page,textValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-6,0,27)
    label.BackgroundColor3 = Color3.fromRGB(65,18,26)
    label.TextColor3 = Color3.fromRGB(255,220,220)
    label.Text = textValue
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = page
    Instance.new("UICorner",label).CornerRadius = UDim.new(0,5)
end

local function addButton(page,textValue,callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-6,0,34)
    b.BackgroundColor3 = Color3.fromRGB(43,43,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = textValue
    b.TextSize = 12
    b.Font = Enum.Font.Gotham
    b.Parent = page
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function addToggle(page,name,key,callback,targetTable)
    targetTable = targetTable or states

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-6,0,36)
    b.BackgroundColor3 = Color3.fromRGB(43,43,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = "  "..name
    b.TextSize = 12
    b.Font = Enum.Font.Gotham
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Parent = page
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)

    local track = Instance.new("Frame")
    track.Name = "ToggleTrack"
    track.Size = UDim2.fromOffset(36,20)
    track.Position = UDim2.new(1,-46,0.5,-10)
    track.BackgroundColor3 = Color3.fromRGB(90,90,98)
    track.BorderSizePixel = 0
    track.Parent = b
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Name = "ToggleKnob"
    knob.Size = UDim2.fromOffset(16,16)
    knob.Position = UDim2.new(0,2,0.5,-8)
    knob.BackgroundColor3 = Color3.fromRGB(245,245,245)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local function draw(on)
        b.BackgroundColor3 = on
            and Color3.fromRGB(35,105,65)
            or Color3.fromRGB(43,43,50)

        track.BackgroundColor3 = on
            and Color3.fromRGB(30,155,85)
            or Color3.fromRGB(90,90,98)

        knob.Position = on
            and UDim2.new(1,-18,0.5,-8)
            or UDim2.new(0,2,0.5,-8)
    end

    draw(targetTable[key]==true)

    b.MouseButton1Click:Connect(function()
        local nextState = not targetTable[key]
        targetTable[key] = nextState
        draw(nextState)

        if callback then
            local ok,err = pcall(callback,nextState)
            if not ok then
                warn("[V19] "..name..": "..tostring(err))
                if statusLabel then
                    statusLabel.Text = "Erro em "..name..": "..tostring(err)
                end
            end
        end
    end)

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

-- PRINCIPAL
addSection(pMain,"ROUBE OU MORRA V19")
addButton(pMain,"Painel atualizado | Feito por Tales",function() end)
addButton(pMain,"Acesse as categorias ao lado para configurar os recursos",function() end)

-- ESP
addSection(pESP,"ESP DE JOGADORES E ENTIDADES")
addToggle(pESP,"ESP Jogadores","ESPPlayers",refreshESP)
addToggle(pESP,"ESP Monstros","ESPMonsters",refreshESP)
addToggle(pESP,"ESP Dutos (contorno sem nome)","ESPDucts",refreshESP)

addSection(pESP,"ESP DE ITENS POR RARIDADE")

for _,rarity in ipairs({
    "Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret"
}) do
    addToggle(pESP,"ESP "..rarity,rarity,refreshESP,rarityEnabled)
end

-- AMBIENTE
addSection(pEnv,"MAPA E VISIBILIDADE")
addToggle(pEnv,"Remover Portas e Tampas de Dutos","RemoveDoors",setDoors)
addToggle(pEnv,"Brilho","Brightness",setBrightness)
addToggle(pEnv,"Anti-Flash","AntiFlash",setAntiFlash)

-- COLETA
addSection(pCollect,"COLETA")
addToggle(pCollect,"Coleta Instantânea","InstantCollection",setInstant)
addToggle(pCollect,"Auto Farm (prompts no alcance)","AutoFarm",setAutoFarm)
addToggle(pCollect,"Stamina Infinita (experimental)","InfiniteStamina",setInfiniteStamina)

-- DADOS
addSection(pData,"COLETOR AUTOMÁTICO DA PARTIDA")

addToggle(pData,"Coletor automático durante a partida","DataCollector",function(enabled)
    if enabled then
        local a = scanGame()
        if statusLabel then
            statusLabel.Text = "Coleta ativa | Novos: "..a
                .." | Total: "..#records
                .." | Pendentes: "..#sendQueue
        end
        flushReports()
    else
        if statusLabel then
            statusLabel.Text = "Coleta automática pausada"
        end
    end
end)

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-6,0,45)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255,205,120)
statusLabel.Text = "Coletor parado"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextWrapped = true
statusLabel.Parent = pData

local tokenLabel = Instance.new("TextLabel")
tokenLabel.Size = UDim2.new(1,-6,0,22)
tokenLabel.BackgroundTransparency = 1
tokenLabel.Text = "Token do coletor online:"
tokenLabel.TextColor3 = Color3.fromRGB(230,230,230)
tokenLabel.TextSize = 12
tokenLabel.Font = Enum.Font.GothamBold
tokenLabel.TextXAlignment = Enum.TextXAlignment.Left
tokenLabel.Parent = pData

tokenBox = Instance.new("TextBox")
tokenBox.Size = UDim2.new(1,-6,0,34)
tokenBox.BackgroundColor3 = Color3.fromRGB(10,10,13)
tokenBox.TextColor3 = Color3.new(1,1,1)
tokenBox.PlaceholderText = "Cole aqui o token atual do coletor"
tokenBox.Text = ""
tokenBox.TextSize = 11
tokenBox.ClearTextOnFocus = false
tokenBox.Parent = pData
Instance.new("UICorner",tokenBox).CornerRadius = UDim.new(0,6)

addButton(pData,"APLICAR TOKEN E TESTAR ENVIO",function()
    COLLECTOR_TOKEN = tokenBox.Text:gsub("^%s+",""):gsub("%s+$","")

    if COLLECTOR_TOKEN=="" then
        statusLabel.Text = "Token vazio. Cole o token atual primeiro."
        return
    end

    statusLabel.Text = "Token aplicado. Tentando enviar a fila..."
    flushReports()
end)

reportBox = Instance.new("TextBox")
reportBox.Size = UDim2.new(1,-6,0,190)
reportBox.BackgroundColor3 = Color3.fromRGB(10,10,13)
reportBox.TextColor3 = Color3.new(1,1,1)
reportBox.PlaceholderText = "O relatório integral aparecerá aqui..."
reportBox.Text = ""
reportBox.TextSize = 10
reportBox.TextWrapped = false
reportBox.TextXAlignment = Enum.TextXAlignment.Left
reportBox.TextYAlignment = Enum.TextYAlignment.Top
reportBox.ClearTextOnFocus = false
reportBox.MultiLine = true
reportBox.Parent = pData
Instance.new("UICorner",reportBox).CornerRadius = UDim.new(0,6)

addButton(pData,"COPIAR RELATÓRIO INTEIRO",copyFullReport)

addButton(pData,"ATUALIZAR E ENVIAR AGORA",function()
    local a = scanGame()
    flushReports()

    statusLabel.Text = "Varredura concluída | Novos: "..a
        .." | Registros: "..#records
        .." | Pendentes: "..#sendQueue
end)

addButton(pData,"LIMPAR RELATÓRIO LOCAL",function()
    table.clear(records)
    table.clear(recordIndex)
    table.clear(sentKeys)
    table.clear(queuedKeys)
    table.clear(sendQueue)

    scanCount = 0
    startTime = os.clock()
    lastScan = "Nenhuma"

    reportBox.Text = ""
    statusLabel.Text = "Relatório local limpo"
end)

-- CONFIGURAÇÕES
addSection(pConfig,"DIAGNÓSTICO E CONFIGURAÇÕES")

addButton(pConfig,"VERIFICAR CAMINHOS DE STAMINA",function()
    local found = findStaminaObjects()

    local lines = {
        "DIAGNÓSTICO DE STAMINA V19",
        "PlayerScripts.SprintStamina",
        "PlayerScripts.StaminaHUD",
        "PlayerScripts.EnergyDrink",
        "PlayerGui.StaminaHUD",
        "PlayerGui.EnergyDrink",
        "Shop.Panel.Frame.CanvasGroup.Stamina",
        "Shop.Panel.Frame.CanvasGroup.EntityStamina",
        ""
    }

    for _,obj in ipairs(found) do
        table.insert(lines,obj:GetFullName().." ["..obj.ClassName.."]")
    end

    if #found==0 then
        table.insert(lines,"Nenhum objeto localizado.")
    end

    reportBox.Text = table.concat(lines,"\n")
    statusLabel.Text = "Diagnóstico de stamina concluído"
    showPage("Dados")
end)

addButton(pConfig,"RESTAURAR PORTAS E EFEITOS",function()
    setDoors(false)
    setAntiFlash(false)
    setBrightness(false)
    setInfiniteStamina(false)
    statusLabel.Text = "Valores locais restaurados"
end)

addButton(pConfig,"FECHAR PAINEL",function()
    gui:Destroy()
end)

showPage("Principal")

--==============================================================
-- ARRASTAR / MINIMIZAR
--==============================================================

local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType==Enum.UserInputType.MouseMovement
        or input.UserInputType==Enum.UserInputType.Touch
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
    if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
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
-- ATUALIZAÇÃO AUTOMÁTICA
--==============================================================

task.spawn(function()
    while gui and gui.Parent do
        if states.ESPPlayers or states.ESPMonsters or states.ESPDucts then
            refreshESP()
        else
            local anyRarity = false

            for _,enabled in pairs(rarityEnabled) do
                if enabled then
                    anyRarity = true
                    break
                end
            end

            if anyRarity then refreshESP() end
        end

        if states.RemoveDoors then
            refreshDoorCollision()
        end

        if states.AntiFlash then
            inspectFlashRoot(Lighting)
            inspectFlashRoot(PlayerGui)
            inspectFlashRoot(Workspace.CurrentCamera)
        end

        if states.InfiniteStamina then
            findStaminaObjects()
        end

        if states.DataCollector then
            local a = scanGame()

            if not sendBusy then
                flushReports()
            end

            if statusLabel and not sendBusy then
                statusLabel.Text =
                    "Coleta ativa | Novos: "..a
                    .." | Total: "..#records
                    .." | Pendentes: "..#sendQueue
                    .." | "..lastHTTP
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
    setInfiniteStamina(false)

    for obj in pairs(highlights) do
        removeESP(obj)
    end

    for obj,bill in pairs(labels) do
        if bill then bill:Destroy() end
        labels[obj] = nil
    end
end)

print("ROUBE OU MORRA V19 CARREGADO | Feito por Tales")
