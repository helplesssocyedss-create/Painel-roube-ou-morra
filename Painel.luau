--==============================================================
-- ROUBE OU MORRA V26 | Feito por Tales
-- ESP incremental | ClassificaÃ§Ã£o rigorosa de entidades
-- ProteÃ§Ã£o contra falsos positivos visuais | Coleta otimizada
-- OtimizaÃ§Ã£o de desempenho mobile
--==============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

for _,name in ipairs({"RoubeOuMorraV19","RoubeOuMorraV20","RoubeOuMorraV21","RoubeOuMorraV22","RoubeOuMorraV24","RoubeOuMorraV25","RoubeOuMorraV26"}) do
    local old = PlayerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

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

local highlights,labels = {},{}
local espFolder = Workspace:FindFirstChild("TalesESP_V26_Folder")
if not espFolder then
    espFolder = Instance.new("Folder")
    espFolder.Name = "TalesESP_V26_Folder"
    espFolder.Parent = Workspace
end
local hiddenParts,savedPrompts = {},{}
local savedEffects,savedOverlays = {},{}
local savedLighting = {}
local watchedFlashRoots = setmetatable({}, {__mode="k"})
local reportedFlashObjects = setmetatable({}, {__mode="k"})
local recentToolUseUntil = 0
local recentToolSpawnCount = 0
local lastActivatedToolName = ""
local lastToolActivatedAt = 0

local records,recordIndex = {},{}
local sentKeys,queuedKeys,sendQueue = {},{},{}
local MAX_RECORDS = 12000
local SEND_WORKERS = 3

local SUPABASE_URL = "https://nqafhfadocgqkzboyxpp.supabase.co"
local COLLECTOR_TOKEN = ""

local statusLabel,reportBox,tokenBox
local sendBusy = false
local lastHTTP = "Aguardando token"
local scanCount = 0
local startTime = os.clock()
local lastScan = "Nenhuma"
local lastDataScan = 0
local espBusy = false
local espGeneration = 0
local espCandidateList,espCandidateSet = {},setmetatable({}, {__mode="k"})
local espCacheBuilt = false
local espLastRefresh = 0
local farmGeneration = 0
local showPage

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
        if plr.Character==model then return plr end
    end
end

local knownEntityKinds = {
    tenant=true, hollow=true, locust=true, rictus=true, wendell=true,
    mimic=true, thetenant=true, thehollow=true, thelocust=true,
    therictus=true, thewendell=true
}

local function normalizedEntityKind(value)
    if type(value)~="string" then return nil end
    local normalized=string.lower(value):gsub("[%s_%-]","")
    if knownEntityKinds[normalized] then return normalized end
    return nil
end

local function hasExplicitEntityFlag(container)
    if not container then return false end
    for _,key in ipairs({"IsEntity","IsMonster","IsEnemy","Monster","Enemy"}) do
        local value=container:GetAttribute(key)
        if value==true or value==1 then return true end
        if type(value)=="string" then
            local v=string.lower(value)
            if v=="true" or v=="1" or v=="yes" then return true end
        end
    end
    for _,key in ipairs({"EntityKind","EntityType","EntitySelected","Role","TeamRole","CharacterType","NPCType","Class","CharacterClass"}) do
        if normalizedEntityKind(container:GetAttribute(key)) then return true end
    end
    return false
end

local function isMonster(model)
    if not model or not model:IsA("Model") then return false end

    local owner=getPlayerFromModel(model)
    -- Para personagens de jogadores, nÃ£o usamos nome, texto genÃ©rico, classe ou
    -- atributos de estado isolados. Exigimos uma marca explÃ­cita de entidade.
    if owner then
        if hasExplicitEntityFlag(model) or hasExplicitEntityFlag(owner) then
            return true
        end
        local ok,tags=pcall(function() return CollectionService:GetTags(model) end)
        if ok then
            for _,tag in ipairs(tags) do
                local t=string.lower(tostring(tag)):gsub("[%s_%-]","")
                if t=="entity" or t=="monster" or t=="enemy" or t=="isentity" then
                    return true
                end
            end
        end
        return false
    end

    if hasExplicitEntityFlag(model) then return true end

    local ok,tags=pcall(function() return CollectionService:GetTags(model) end)
    if ok then
        for _,tag in ipairs(tags) do
            if contains(tag,{"monster","enemy","monstro","inimigo","creature","entity"}) then
                return true
            end
        end
    end

    if contains(model.Name,monsterNames) then return true end

    -- Fallback por ValueBase somente para NPCs, nunca para personagens de Players.
    for _,obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BoolValue") and obj.Value
            and contains(obj.Name,{"monster","enemy","entity","monstro","inimigo"}) then
            return true
        elseif obj:IsA("StringValue")
            and contains(obj.Name,{"role","class","type","monster","entity","team"})
            and normalizedEntityKind(obj.Value) then
            return true
        end
    end
    return false
end

local function getEntityActivitySuffix(model)
    if not model then return "" end
    local state=tostring(model:GetAttribute("State") or "")
    local killing=model:GetAttribute("Killing")
    local lungeUntil=tonumber(model:GetAttribute("LungeUntil"))
    local now=os.time()
    if killing==true or tostring(killing):lower()=="true" then
        return " [ATAQUE]"
    end
    if lungeUntil and lungeUntil>now then return " [AVANCO]" end
    if state:lower()=="chase" or state:lower()=="hunt" then return " [PERSEGUINDO]" end
    return ""
end

local function getRarity(obj)
    for _,key in ipairs({"Rarity","Raridade"}) do
        local value = obj:GetAttribute(key)
        if type(value)=="string" then
            for rarity in pairs(rarityEnabled) do
                if value:lower()==rarity:lower() then return rarity end
            end
        end
    end
end

--==============================================================
-- ESP
--==============================================================

local function removeESP(obj)
    if highlights[obj] then
        pcall(function() highlights[obj]:Destroy() end)
        highlights[obj] = nil
    end
    if labels[obj] then
        pcall(function() labels[obj]:Destroy() end)
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

local function createESP(obj,color,textValue,small)
    if not obj or not obj.Parent then return end

    if not highlights[obj] or not highlights[obj].Parent then
        local h = Instance.new("Highlight")
        h.Name = "TalesESP_V26"
        h.Adornee = obj
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.Parent = espFolder
        highlights[obj] = h
    end

    local h = highlights[obj]
    h.Adornee = obj
    h.Enabled = true
    h.OutlineColor = color
    h.FillColor = color
    if h.Parent ~= espFolder then h.Parent = espFolder end

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
        bill.Name = "TalesESPLabel_V26"
        bill.AlwaysOnTop = true
        bill.Size = small and UDim2.fromOffset(118,18)
            or UDim2.fromOffset(104,16)
        bill.StudsOffset = Vector3.new(0,3,0)

        local txt = Instance.new("TextLabel")
        txt.Name = "TextLabel"
        txt.Size = UDim2.fromScale(1,1)
        txt.BackgroundTransparency = 1
        txt.TextScaled = false
        txt.TextSize = small and 10 or 10
        txt.TextTruncate = Enum.TextTruncate.AtEnd
        txt.Font = Enum.Font.GothamBold
        txt.TextStrokeTransparency = 0.2
        txt.Parent = bill

        bill.Parent = PlayerGui
        labels[obj] = bill
    end

    local bill = labels[obj]
    bill.Adornee = part
    bill.TextLabel.Text = textValue
    bill.TextLabel.TextColor3 = color
end

-- Identifica somente o prÃ³prio objeto duto, nÃ£o qualquer peÃ§a
-- que esteja prÃ³xima ou seja descendente dele.
local function isDuctRoot(obj)
    if not obj or not (obj:IsA("Model") or obj:IsA("BasePart")) then
        return false
    end

    if contains(obj.Name,{"duct","duto","vent","airvent"}) then
        return true
    end

    for _,key in ipairs({"Type","ObjectType","Category","Kind"}) do
        local value = obj:GetAttribute(key)
        if type(value)=="string"
            and contains(value,{"duct","duto","vent"}) then
            return true
        end
    end

    local ok,tags = pcall(function()
        return CollectionService:GetTags(obj)
    end)

    if ok then
        for _,tag in ipairs(tags) do
            if contains(tag,{"duct","duto","vent"}) then return true end
        end
    end

    return false
end

local espPending = false

local function registerESPCandidate(obj)
    if not obj or espCandidateSet[obj] then return end
    if obj:IsA("Model") or obj:IsA("BasePart") then
        espCandidateSet[obj] = true
        table.insert(espCandidateList,obj)
    end
end

local function buildESPCacheOnce()
    if espCacheBuilt then return end
    espCacheBuilt = true
    -- Uma varredura inicial Ãºnica; atualizaÃ§Ãµes seguintes sÃ£o incrementais.
    for index,obj in ipairs(Workspace:GetDescendants()) do
        registerESPCandidate(obj)
        if index%350==0 then task.wait() end
    end
end

local function refreshESP()
    if espBusy then
        espPending = true
        return
    end
    espGeneration += 1
    local generation = espGeneration
    espBusy = true

    task.spawn(function()
        local keep = {}

        if not states.ESPPlayers and not states.ESPMonsters
            and not states.ESPDucts then
            local anyRarity = false
            for _,v in pairs(rarityEnabled) do
                if v then anyRarity=true break end
            end

            if not anyRarity then
                clearESP()
                espBusy = false
                return
            end
        end

        buildESPCacheOnce()
        local candidates = espCandidateList

        for index,obj in ipairs(candidates) do
            if generation~=espGeneration then break end
            if not gui or not gui.Parent then break end

            if obj:IsA("Model") then
                local plr = getPlayerFromModel(obj)

                if plr and plr~=player and states.ESPMonsters and isMonster(obj) then
                    createESP(obj,Color3.fromRGB(255,35,35),plr.Name..getEntityActivitySuffix(obj),false)
                    keep[obj] = true
                elseif plr and plr~=player and states.ESPPlayers then
                    createESP(obj,Color3.fromRGB(40,140,255),plr.Name,false)
                    keep[obj] = true
                elseif states.ESPMonsters and isMonster(obj) then
                    local displayName=obj:GetAttribute("DisplayName")
                    or obj:GetAttribute("EntityKind")
                    or obj:GetAttribute("EntitySelected")
                    or obj.Name
                    createESP(obj,Color3.fromRGB(255,35,35),tostring(displayName)..getEntityActivitySuffix(obj),false)
                    keep[obj] = true
                end
            end

            if states.ESPDucts and isDuctRoot(obj) then
                createESP(obj,Color3.fromRGB(255,170,40),nil,true)
                keep[obj] = true
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
                        obj,rarityColors[rarity],
                        obj.Name.." | "..tostring(weight).." | $"..tostring(price),
                        true
                    )
                    keep[obj] = true
                end
            end

            if index%250==0 then task.wait() end
        end

        if generation==espGeneration then
            for obj in pairs(highlights) do
                if not keep[obj] or not obj.Parent then
                    removeESP(obj)
                end
            end
            for obj in pairs(labels) do
                if not keep[obj] or not obj.Parent then
                    removeESP(obj)
                end
            end
        end

        local compact={}
        for _,candidate in ipairs(espCandidateList) do
            if candidate and candidate.Parent then
                table.insert(compact,candidate)
            else
                espCandidateSet[candidate]=nil
            end
        end
        espCandidateList=compact

        espBusy = false

        if espPending or generation~=espGeneration then
            espPending = false
            task.defer(refreshESP)
        end
    end)
end

local espRefreshScheduled=false
Workspace.DescendantAdded:Connect(function(obj)
    registerESPCandidate(obj)
    if (states.ESPPlayers or states.ESPMonsters or states.ESPDucts)
        and (obj:IsA("Model") or obj:IsA("BasePart"))
        and not espRefreshScheduled then
        espRefreshScheduled=true
        task.delay(0.6,function()
            espRefreshScheduled=false
            if gui and gui.Parent then refreshESP() end
        end)
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if states.ESPPlayers then task.defer(refreshESP) end
    end)
end)

for _,plr in ipairs(Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function()
        if states.ESPPlayers then task.defer(refreshESP) end
    end)
end

local function setESP(key,enabled)
    states[key] = enabled

    if not enabled then
        local any = states.ESPPlayers or states.ESPMonsters or states.ESPDucts
        for _,v in pairs(rarityEnabled) do
            if v then any=true break end
        end

        if not any then
            espGeneration += 1
            clearESP()
            espBusy = false
            return
        end
    end

    refreshESP()
end

--==============================================================
-- PORTAS E TAMPAS (MANTIDO)
--==============================================================

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
        }) then return false end

        if contains(current.Name,{
            "door","porta","doorleaf","door_leaf",
            "hingeddoor","doorframe","doorpart"
        }) then return true end

        current = current.Parent
    end

    return false
end

local function isDuctCapPart(obj)
    local current = obj
    local inDuct,cap = false,false

    for _=1,10 do
        if not current then break end

        if contains(current.Name,{"duct","duto","vent"}) then
            inDuct = true
        end

        if contains(current.Name,{
            "hatch","cover","lid","tampa","escotilha",
            "ductdoor","ventdoor","door"
        }) then cap = true end

        current = current.Parent
    end

    return inDuct and cap
end

local function isTargetDoor(obj)
    return obj:IsA("BasePart")
        and (isDoorPart(obj) or isDuctCapPart(obj))
end

local function setDoors(enabled)
    states.RemoveDoors = enabled

    if not enabled then
        restoreDoors()
        return
    end

    for index,obj in ipairs(Workspace:GetDescendants()) do
        if isTargetDoor(obj) then hidePart(obj) end
        if index%300==0 then task.wait() end
    end
end

local function refreshDoorCollision()
    if not states.RemoveDoors then return end

    for part in pairs(hiddenParts) do
        if part and part.Parent then
            pcall(function()
                part.LocalTransparencyModifier = 1
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
            end)
        end
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if not obj or not obj.Parent then return end

        if states.RemoveDoors and isTargetDoor(obj) then
            hidePart(obj)
        end

        if states.InstantCollection and obj:IsA("ProximityPrompt") then
            if savedPrompts[obj]==nil then
                savedPrompts[obj] = obj.HoldDuration
            end
            pcall(function() obj.HoldDuration=0 end)
        end
    end)
end)

--==============================================================
-- COLETA INSTANTÃ‚NEA
--==============================================================

local function setInstant(enabled)
    states.InstantCollection = enabled

    if enabled then
        for index,obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                if savedPrompts[obj]==nil then savedPrompts[obj]=obj.HoldDuration end
                pcall(function() obj.HoldDuration=0 end)
            end
            if index%350==0 then task.wait() end
        end
    else
        for obj,duration in pairs(savedPrompts) do
            if obj and obj.Parent then
                pcall(function() obj.HoldDuration=duration end)
            end
        end
        table.clear(savedPrompts)
    end
end

--==============================================================
-- SUPABASE
--==============================================================

local function reportFingerprint(entry)
    local ok,encoded = pcall(function()
        return HttpService:JSONEncode(entry)
    end)
    if not ok then encoded = tostring(entry) end

    local hash = 7
    for i=1,#encoded do
        hash = (hash*31 + string.byte(encoded,i)) % 2147483647
    end
    return tostring(hash)
end

local function queueReport(entry,key)
    if not states.DataCollector then return end

    -- A mesma instÃ¢ncia pode mudar de estado; cada versÃ£o do conteÃºdo recebe
    -- uma chave prÃ³pria, em vez de bloquear para sempre pelo caminho.
    local versionedKey = tostring(key).."|"..reportFingerprint(entry)
    if sentKeys[versionedKey] or queuedKeys[versionedKey] then return end

    table.insert(sendQueue,{
        record_key=versionedKey,
        payload=entry
    })
    queuedKeys[versionedKey] = true
end

local function sendOne(item)
    if not sendRequest then
        return false,"Executor sem suporte a request()"
    end

    if COLLECTOR_TOKEN=="" then
        return false,"Informe o token do coletor"
    end

    local body = {
        session_id=sessionId,
        record_key=item.record_key,
        payload=item.payload
    }

    local ok,res = pcall(function()
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

    if not ok then
        return false,"Erro request(): "..tostring(res)
    end

    res = res or {}
    local code = tonumber(res.StatusCode or res.Status) or 0
    local responseBody = tostring(res.Body or "")

    if code>=200 and code<300 then
        return true,"HTTP "..code
    end

    if code==409 then return true,"Registro jÃ¡ existente" end

    if code==401 or code==403 then
        return false,"Token recusado (HTTP "..code..")"
    elseif code==404 then
        return false,"FunÃ§Ã£o ingest-report nÃ£o encontrada (404)"
    elseif code==429 then
        return false,"Limite de requisiÃ§Ãµes (429)"
    elseif code>=500 then
        return false,"Supabase HTTP "..code..": "..responseBody
    end

    return false,"Falha HTTP "..code..": "..responseBody
end

local function flushReports()
    if sendBusy or #sendQueue==0 then return end
    if not sendRequest then
        lastHTTP = "Executor sem suporte a request()"
        if statusLabel then statusLabel.Text=lastHTTP end
        return
    end
    if COLLECTOR_TOKEN=="" then
        lastHTTP = "Token nÃ£o informado"
        if statusLabel then statusLabel.Text=lastHTTP end
        return
    end

    sendBusy = true
    task.spawn(function()
        local sentThisRound = 0
        local failedMessage = nil
        local finishedWorkers = 0
        local stopWorkers = false

        local function worker()
            while states.DataCollector and not stopWorkers do
                local item = table.remove(sendQueue,1)
                if not item then break end

                local ok,message = sendOne(item)
                if ok then
                    sentKeys[item.record_key] = true
                    queuedKeys[item.record_key] = nil
                    sentThisRound += 1
                    lastHTTP = message
                else
                    table.insert(sendQueue,1,item)
                    failedMessage = message
                    lastHTTP = message
                    stopWorkers = true
                    break
                end

                if statusLabel then
                    statusLabel.Text =
                        "Enviados: "..sentThisRound
                        .." | Pendentes: "..#sendQueue
                        .." | "..lastHTTP
                end
                task.wait(0.03)
            end
            finishedWorkers += 1
        end

        local workerCount = math.min(SEND_WORKERS,#sendQueue)
        for _=1,workerCount do task.spawn(worker) end
        while finishedWorkers<workerCount do task.wait(0.05) end

        sendBusy = false
        if statusLabel then
            statusLabel.Text =
                "Envio online | Rodada: "..sentThisRound
                .." | Pendentes: "..#sendQueue
                .." | "..(failedMessage or lastHTTP)
        end

        if failedMessage and states.DataCollector then
            task.wait(8)
            if states.DataCollector then flushReports() end
        elseif #sendQueue>0 and states.DataCollector then
            task.defer(flushReports)
        end
    end)
end

--==============================================================
-- COLETA DE DADOS
--==============================================================

local function scanGame()
    scanCount += 1
    lastScan = os.date("%d/%m/%Y %H:%M:%S")
    local added,updated = 0,0
    local visited = {}

    local function shouldCapture(obj,rootName)
        if obj:IsA("Tool") or obj:IsA("Explosion") or obj:IsA("Humanoid")
            or obj:IsA("ProximityPrompt") then return true end
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then return true end
        if obj:IsA("BoolValue") or obj:IsA("StringValue") then
            return contains(obj.Name,{"role","entity","monster","stamina","sprint","energy","resist","endurance","flash"})
        end
        if obj:IsA("Model") and obj==player.Character then return true end
        if obj:IsA("GuiObject") then return true end
        local attrs = obj:GetAttributes()
        for key in pairs(attrs) do
            if contains(key,{"stamina","sprint","energy","resist","endurance","entity","monster","role","flash"}) then
                return true
            end
        end
        return false
    end

    local function capture(obj,rootName)
        if not obj or visited[obj] or not shouldCapture(obj,rootName) then return end
        visited[obj]=true
        local ok,path=pcall(function() return obj:GetFullName() end)
        path=ok and path or (rootName.."/"..obj.Name)
        local key=obj.ClassName.."|"..path
        local entry={
            Event="TargetedObjectSnapshot",
            Name=obj.Name,Class=obj.ClassName,Path=path,
            Root=rootName,CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
        local attrs=obj:GetAttributes()
        if next(attrs) then
            entry.Attributes={}
            for k,val in pairs(attrs) do entry.Attributes[k]=tostring(val) end
        end
        if obj:IsA("ValueBase") then
            pcall(function() entry.Value=tostring(obj.Value) end)
        elseif obj:IsA("Tool") then
            entry.ToolTip=obj.ToolTip
            entry.RequiresHandle=obj.RequiresHandle
        elseif obj:IsA("ProximityPrompt") then
            entry.HoldDuration=obj.HoldDuration
            entry.ActionText=obj.ActionText
            entry.ObjectText=obj.ObjectText
            entry.Enabled=obj.Enabled
        elseif obj:IsA("Explosion") then
            entry.Position=tostring(obj.Position)
            entry.BlastRadius=obj.BlastRadius
        elseif obj:IsA("Humanoid") then
            entry.Health=obj.Health
            entry.MaxHealth=obj.MaxHealth
            entry.WalkSpeed=obj.WalkSpeed
            entry.MoveDirection=tostring(obj.MoveDirection)
            entry.FloorMaterial=tostring(obj.FloorMaterial)
        elseif obj:IsA("GuiObject") then
            entry.Visible=obj.Visible
            entry.Size=tostring(obj.Size)
            entry.AbsoluteSize=tostring(obj.AbsoluteSize)
            if obj:IsA("Frame") then
                entry.BackgroundColor3=tostring(obj.BackgroundColor3)
                entry.BackgroundTransparency=obj.BackgroundTransparency
            elseif obj:IsA("TextLabel") then
                entry.Text=obj.Text
            elseif obj:IsA("ImageLabel") then
                entry.Image=obj.Image
                entry.ImageColor3=tostring(obj.ImageColor3)
                entry.ImageTransparency=obj.ImageTransparency
            end
        end

        if recordIndex[key] then
            records[recordIndex[key]]=entry
            updated+=1
        elseif #records<MAX_RECORDS then
            table.insert(records,entry)
            recordIndex[key]=#records
            added+=1
        end
        queueReport(entry,key)
    end

    local roots={}
    local function addRoot(root,label)
        if root then table.insert(roots,{object=root,label=label}) end
    end
    addRoot(player,"Player")
    addRoot(player.Character,"Character")
    addRoot(player:FindFirstChildOfClass("PlayerScripts"),"PlayerScripts")
    addRoot(player:FindFirstChildOfClass("Backpack") or player:FindFirstChild("Backpack"),"Backpack")
    addRoot(PlayerGui,"PlayerGui")
    addRoot(Lighting,"Lighting")
    addRoot(Workspace.CurrentCamera,"Camera")

    for _,rootInfo in ipairs(roots) do
        local root=rootInfo.object
        capture(root,rootInfo.label)
        for index,obj in ipairs(root:GetDescendants()) do
            capture(obj,rootInfo.label)
            if index%250==0 then task.wait() end
        end
    end

    local function addPlayerSnapshot(plr)
        local char=plr.Character
        local data={
            Event="PlayerSnapshot",PlayerName=plr.Name,UserId=plr.UserId,
            Team=plr.Team and plr.Team.Name or "",
            Character=char and char.Name or "",
            IsLocalPlayer=(plr==player),
            IsMonster=char and isMonster(char) or false,
            CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ"),
            PlayerAttributes={},CharacterAttributes={}
        }
        for k,val in pairs(plr:GetAttributes()) do data.PlayerAttributes[k]=tostring(val) end
        if char then
            for k,val in pairs(char:GetAttributes()) do data.CharacterAttributes[k]=tostring(val) end
            local hum=char:FindFirstChildOfClass("Humanoid")
            if hum then
                data.Health=hum.Health
                data.MaxHealth=hum.MaxHealth
                data.WalkSpeed=hum.WalkSpeed
                data.MoveDirection=tostring(hum.MoveDirection)
                data.HumanoidState=tostring(hum:GetState())
            end
        end
        local key="PlayerSnapshot|"..tostring(plr.UserId)
        local idx=recordIndex[key]
        if idx then records[idx]=data
        elseif #records<MAX_RECORDS then
            table.insert(records,data)
            recordIndex[key]=#records
            added+=1
        end
        queueReport(data,key)
    end
    for _,plr in ipairs(Players:GetPlayers()) do pcall(addPlayerSnapshot,plr) end

    lastDataScan=os.clock()
    return added,updated
end

--==============================================================
-- V26: MONITORAMENTO DIRECIONADO DE PERSONAGENS, STATS E EVENTOS
--==============================================================

local watchedPlayers = setmetatable({}, {__mode="k"})
local watchedCharacters = setmetatable({}, {__mode="k"})
local watchedTools = setmetatable({}, {__mode="k"})
local watchedStats = setmetatable({}, {__mode="k"})
local statLastReport = setmetatable({}, {__mode="k"})
local eventSequence = 0
local lastStaminaSample = 0
local lastHudSample = 0
local hudVisualState = setmetatable({}, {__mode="k"})

local function safePath(obj)
    local ok,path=pcall(function() return obj:GetFullName() end)
    return ok and path or (obj and obj.Name or "unknown")
end

local function makeObjectReport(obj,eventName)
    if not obj then return end
    local entry={
        Event=eventName or "ObjectObserved",
        Name=obj.Name,Class=obj.ClassName,Path=safePath(obj),
        CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ"),Attributes={}
    }
    pcall(function()
        for k,val in pairs(obj:GetAttributes()) do entry.Attributes[k]=tostring(val) end
    end)
    if obj:IsA("Tool") then
        entry.ToolTip=obj.ToolTip
        entry.RequiresHandle=obj.RequiresHandle
        entry.ParentPath=safePath(obj.Parent)
    elseif obj:IsA("Explosion") then
        entry.Position=tostring(obj.Position)
        entry.BlastRadius=obj.BlastRadius
        entry.BlastPressure=obj.BlastPressure
    elseif obj:IsA("ValueBase") then
        pcall(function() entry.Value=tostring(obj.Value) end)
    elseif obj:IsA("Humanoid") then
        entry.Health=obj.Health
        entry.MaxHealth=obj.MaxHealth
        entry.WalkSpeed=obj.WalkSpeed
        entry.MoveDirection=tostring(obj.MoveDirection)
        entry.State=tostring(obj:GetState())
    elseif obj:IsA("GuiObject") then
        entry.Visible=obj.Visible
        entry.Size=tostring(obj.Size)
        entry.AbsoluteSize=tostring(obj.AbsoluteSize)
        if obj:IsA("Frame") then
            entry.BackgroundColor3=tostring(obj.BackgroundColor3)
            entry.BackgroundTransparency=obj.BackgroundTransparency
        elseif obj:IsA("TextLabel") then
            entry.Text=obj.Text
        end
    end
    if eventName=="ObjectSpawnedAfterToolUse"
        or eventName=="FlashVisualEffectDetected"
        or eventName=="VisualEffectAfterToolActivation"
        or eventName=="FullScreenWhiteFlashOverlayDetected" then
        entry.RecentToolName=lastActivatedToolName
        entry.SecondsSinceToolActivation=lastToolActivatedAt>0
            and (os.clock()-lastToolActivatedAt) or nil
    end
    eventSequence+=1
    local key="Event|"..tostring(eventSequence).."|"..entry.Event.."|"..entry.Path
    queueReport(entry,key)
end

local function staminaSnapshot(reason)
    local now=os.clock()
    if now-lastStaminaSample<0.75 then return end
    lastStaminaSample=now
    local char=player.Character
    local data={
        Event="StaminaContext",
        Reason=reason or "Sample",
        CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ"),
        PlayerAttributes={},CharacterAttributes={}
    }
    for k,val in pairs(player:GetAttributes()) do data.PlayerAttributes[k]=tostring(val) end
    if char then
        for k,val in pairs(char:GetAttributes()) do data.CharacterAttributes[k]=tostring(val) end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then
            data.Health=hum.Health
            data.WalkSpeed=hum.WalkSpeed
            data.MoveDirection=tostring(hum.MoveDirection)
            data.HumanoidState=tostring(hum:GetState())
        end
        local statValues={}
        for _,obj in ipairs(char:GetDescendants()) do
            if (obj:IsA("NumberValue") or obj:IsA("IntValue"))
                or (obj:IsA("ValueBase") and contains(obj.Name,{
                    "stamina","sprint","energy","resist","endurance","folego","fÃ´lego"
                })) then
                local ok,value=pcall(function() return obj.Value end)
                if ok then statValues[safePath(obj)]=tostring(value) end
            end
        end
        local scripts=player:FindFirstChild("PlayerScripts")
        if scripts then
            for _,obj in ipairs(scripts:GetDescendants()) do
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    local ok,value=pcall(function() return obj.Value end)
                    if ok then statValues[safePath(obj)]=tostring(value) end
                end
            end
        end
        data.CharacterValues=statValues
    end

    -- A barra pode ser apenas visual. Durante corrida/parada, compara alguns
    -- elementos de HUD e relata mudanÃ§as de tamanho/cor/texto sem assumir nomes.
    if reason=="Running" or reason=="Stopped" then
        if now-lastHudSample>=1.5 then
            lastHudSample=now
            local changed=0
            for _,obj in ipairs(PlayerGui:GetDescendants()) do
                local candidate=obj:IsA("Frame") or obj:IsA("ImageLabel")
                    or (obj:IsA("TextLabel") and tonumber(obj.Text)~=nil)
                if candidate then
                    local signature=tostring(obj.Size).."|"..tostring(obj.Visible)
                    if obj:IsA("Frame") then
                        signature=signature.."|"..tostring(obj.BackgroundColor3)
                            .."|"..tostring(obj.BackgroundTransparency)
                    elseif obj:IsA("ImageLabel") then
                        signature=signature.."|"..tostring(obj.ImageColor3)
                            .."|"..tostring(obj.ImageTransparency)
                    elseif obj:IsA("TextLabel") then
                        signature=signature.."|"..obj.Text
                    end
                    local previous=hudVisualState[obj]
                    hudVisualState[obj]=signature
                    if previous and previous~=signature and changed<8 then
                        changed+=1
                        local hudEntry={
                            Event="HUDVisualChangedDuringRun",
                            Reason=reason,Path=safePath(obj),Name=obj.Name,
                            Class=obj.ClassName,Previous=previous,Current=signature,
                            CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ")
                        }
                        queueReport(hudEntry,"HUDChange|"..safePath(obj).."|"..tostring(math.floor(now*2)))
                    end
                end
            end
        end
    end

    queueReport(data,"StaminaContext|"..tostring(reason).."|"..tostring(math.floor(os.clock()*2)))
end

local roleSnapshot

local function watchStatObject(obj,source)
    if not obj or not obj:IsA("ValueBase") or watchedStats[obj] then return end
    local isNumeric=obj:IsA("NumberValue") or obj:IsA("IntValue")
    local named=contains(obj.Name,{
        "stamina","sprint","energy","resist","endurance","folego","fÃ´lego",
        "role","entity","monster","enemy","team","class","type","flash"
    })
    if not isNumeric and not named then return end
    watchedStats[obj]=true
    makeObjectReport(obj,isNumeric and "NumericStatObserved" or "NamedStateObserved")
    obj.Changed:Connect(function()
        if contains(obj.Name,{"role","entity","monster","enemy","team","class","type"}) then
            local current=obj.Parent
            while current and not current:IsA("Model") do current=current.Parent end
            local owner=current and getPlayerFromModel(current)
            if owner and roleSnapshot then
                roleSnapshot(owner,"RoleValueChanged:"..obj.Name)
            end
            if states.ESPMonsters then task.defer(refreshESP) end
        end
        if not states.DataCollector then return end
        local now=os.clock()
        if now-(statLastReport[obj] or 0)<0.35 then return end
        statLastReport[obj]=now
        makeObjectReport(obj,isNumeric and "NumericStatChanged" or "NamedStateChanged")
    end)
end

roleSnapshot = function(plr,reason)
    if not plr then return end
    local char=plr.Character
    local roleData={
        Event="RoleOrCharacterChanged",
        Reason=reason or "Update",
        PlayerName=plr.Name,
        UserId=plr.UserId,
        Team=plr.Team and plr.Team.Name or "",
        CharacterName=char and char.Name or "",
        IsLocalPlayer=(plr==player),
        IsMonster=char and isMonster(char) or false,
        CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ"),
        PlayerAttributes={},
        CharacterAttributes={}
    }
    for k,val in pairs(plr:GetAttributes()) do
        roleData.PlayerAttributes[k]=tostring(val)
    end
    if char then
        for k,val in pairs(char:GetAttributes()) do
            roleData.CharacterAttributes[k]=tostring(val)
        end
        local markers={}
        for _,obj in ipairs(char:GetDescendants()) do
            if obj:IsA("StringValue") or obj:IsA("BoolValue") then
                if contains(obj.Name,{"role","class","type","monster","monstro","team"}) then
                    local ok,value=pcall(function() return obj.Value end)
                    if ok then markers[obj.Name]=tostring(value) end
                end
            end
        end
        roleData.RoleValues=markers
    end
    local key="RoleState|"..tostring(plr.UserId)
    local idx=recordIndex[key]
    if idx then records[idx]=roleData
    elseif #records<MAX_RECORDS then
        table.insert(records,roleData)
        recordIndex[key]=#records
    end
    queueReport(roleData,key)
    if states.ESPMonsters then task.defer(refreshESP) end
    if states.DataCollector then task.defer(flushReports) end
end

local function watchTool(tool)
    if not tool or not tool:IsA("Tool") or watchedTools[tool] then return end
    watchedTools[tool]=true
    makeObjectReport(tool,"ToolObserved")

    tool.Equipped:Connect(function()
        makeObjectReport(tool,"ToolEquipped")
        if states.DataCollector then staminaSnapshot("ToolEquipped") flushReports() end
    end)
    tool.Unequipped:Connect(function()
        makeObjectReport(tool,"ToolUnequipped")
        if states.DataCollector then flushReports() end
    end)
    tool.Activated:Connect(function()
        recentToolUseUntil=os.clock()+8
        recentToolSpawnCount=0
        lastActivatedToolName=tool.Name
        lastToolActivatedAt=os.clock()
        makeObjectReport(tool,"ToolActivated")
        if states.DataCollector then
            staminaSnapshot("ToolActivated")
            flushReports()
        end
    end)
end

local watchFlashRoot, inspectFlashRoot

local function watchCharacter(char,plr)
    if not char or watchedCharacters[char] then return end
    watchedCharacters[char]=true
    roleSnapshot(plr,"CharacterAttached")

    char.AttributeChanged:Connect(function(attributeName)
        roleSnapshot(plr,"CharacterAttributeChanged:"..tostring(attributeName))
        if plr==player then staminaSnapshot("CharacterAttributeChanged:"..tostring(attributeName)) end
    end)

    local hum=char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid",5)
    if hum and hum:IsA("Humanoid") then
        hum.AttributeChanged:Connect(function(attributeName)
            if plr==player then
                makeObjectReport(hum,"HumanoidAttributeChanged:"..tostring(attributeName))
                staminaSnapshot("HumanoidAttributeChanged:"..tostring(attributeName))
            end
        end)
        hum.Died:Connect(function()
            makeObjectReport(hum,"HumanoidDied")
            roleSnapshot(plr,"HumanoidDied")
        end)
        hum.Running:Connect(function(speed)
            if plr==player and states.DataCollector then
                staminaSnapshot(speed>0 and "Running" or "Stopped")
            end
        end)
        hum.StateChanged:Connect(function(_,newState)
            roleSnapshot(plr,"HumanoidState:"..tostring(newState))
            if plr==player and states.DataCollector then
                staminaSnapshot("HumanoidState:"..tostring(newState))
            end
        end)
    end

    char.DescendantAdded:Connect(function(obj)
        if obj:IsA("Tool") then watchTool(obj) end
        if obj:IsA("ValueBase") then watchStatObject(obj,"Character") end
        if obj:IsA("Model") or obj:IsA("Humanoid") then
            roleSnapshot(plr,"CharacterDescendantAdded:"..obj.Name)
        end
    end)

    for _,obj in ipairs(char:GetDescendants()) do
        if obj:IsA("Tool") then watchTool(obj) end
        if obj:IsA("ValueBase") then watchStatObject(obj,"Character") end
    end
    if plr==player then
        staminaSnapshot("CharacterWatched")
        if states.AntiFlash or states.DataCollector then
            watchFlashRoot(char)
            inspectFlashRoot(char)
        end
    end
end

local function watchPlayer(plr)
    if not plr or watchedPlayers[plr] then return end
    watchedPlayers[plr]=true
    plr.CharacterAdded:Connect(function(char)
        watchCharacter(char,plr)
        roleSnapshot(plr,"CharacterAdded")
        if states.DataCollector then flushReports() end
    end)
    plr:GetPropertyChangedSignal("Team"):Connect(function()
        roleSnapshot(plr,"TeamChanged")
    end)
    plr.AttributeChanged:Connect(function(attributeName)
        roleSnapshot(plr,"PlayerAttributeChanged:"..tostring(attributeName))
        if plr==player then staminaSnapshot("PlayerAttributeChanged:"..tostring(attributeName)) end
    end)
    plr.DescendantAdded:Connect(function(obj)
        if obj:IsA("Tool") then watchTool(obj) end
        if obj:IsA("ValueBase") then watchStatObject(obj,"Player") end
    end)
    if plr.Character then watchCharacter(plr.Character,plr) end
    local backpack=plr:FindFirstChild("Backpack") or plr:WaitForChild("Backpack",3)
    if backpack then
        for _,obj in ipairs(backpack:GetChildren()) do
            if obj:IsA("Tool") then watchTool(obj) end
        end
        backpack.ChildAdded:Connect(function(obj)
            if obj:IsA("Tool") then watchTool(obj) end
        end)
    end
    local scripts=plr:FindFirstChild("PlayerScripts")
    if scripts then
        for _,obj in ipairs(scripts:GetDescendants()) do
            if obj:IsA("ValueBase") then watchStatObject(obj,"PlayerScripts") end
        end
        scripts.DescendantAdded:Connect(function(obj)
            if obj:IsA("ValueBase") then watchStatObject(obj,"PlayerScripts") end
        end)
    end
    roleSnapshot(plr,"PlayerObserved")
end

for _,obj in ipairs(PlayerGui:GetDescendants()) do
    if obj:IsA("ValueBase") then watchStatObject(obj,"PlayerGui") end
end
PlayerGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("ValueBase") then watchStatObject(obj,"PlayerGui") end
end)

for _,plr in ipairs(Players:GetPlayers()) do watchPlayer(plr) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(plr)
    if states.DataCollector then
        local entry={Event="PlayerRemoving",PlayerName=plr.Name,UserId=plr.UserId}
        eventSequence+=1
        queueReport(entry,"PlayerRemoving|"..tostring(eventSequence))
        task.defer(flushReports)
    end
end)

local watchedEntityModels=setmetatable({}, {__mode="k"})
local entityDiscoveryDone=false

local function watchEntityModel(model)
    if not model or not model:IsA("Model") or watchedEntityModels[model] then return end
    watchedEntityModels[model]=true
    local function checkEntity(reason)
        if isMonster(model) then
            makeObjectReport(model,reason or "EntityModelDetected")
            if states.ESPMonsters then task.defer(refreshESP) end
        end
    end
    checkEntity("EntityModelDetected")
    model.AttributeChanged:Connect(function(attributeName)
        checkEntity("EntityAttributeChanged:"..tostring(attributeName))
    end)
    for _,obj in ipairs(model:GetDescendants()) do
        if obj:IsA("ValueBase") then watchStatObject(obj,"EntityModel") end
    end
    model.DescendantAdded:Connect(function(obj)
        if obj:IsA("ValueBase") then watchStatObject(obj,"EntityModel") end
        if obj:IsA("Humanoid") then checkEntity("EntityHumanoidAdded") end
    end)
end

local function discoverExistingEntities()
    if entityDiscoveryDone then return end
    entityDiscoveryDone=true
    -- Percorre apenas contÃªineres e Models: nÃ£o inspeciona cada peÃ§a/objeto do mapa.
    local visited=0
    local lastYield=0
    local function walk(container,depth)
        if not container or depth>14 then return end
        for _,child in ipairs(container:GetChildren()) do
            if child:IsA("Model") then
                watchEntityModel(child)
                visited+=1
            end
            if child:IsA("Folder") or child:IsA("Model") then
                walk(child,depth+1)
            end
            if visited-lastYield>=100 then
                lastYield=visited
                task.wait()
            end
        end
    end
    walk(Workspace,0)
end

Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") then
        watchEntityModel(obj)
    end
    if obj:IsA("Explosion") then
        makeObjectReport(obj,"ExplosionCreated")
        if states.DataCollector then task.defer(flushReports) end
        return
    end

    if obj:IsA("Tool") then watchTool(obj) end

    -- Sem depender do nome: objetos que surgem logo apÃ³s ativar uma ferramenta
    -- sÃ£o candidatos a projÃ©til/artefato lanÃ§ado. Limite evita capturar o mapa inteiro.
    if states.DataCollector and os.clock()<=recentToolUseUntil
        and recentToolSpawnCount<24
        and (obj:IsA("Model") or obj:IsA("BasePart")) then
        recentToolSpawnCount+=1
        makeObjectReport(obj,"ObjectSpawnedAfterToolUse")
    end
end)

--==============================================================
-- RELATÃ“RIO MANUAL INTEGRAL
--==============================================================

local function exportData()
    local out = {
        "========================================",
        "ROUBE OU MORRA V26 - RELATORIO",
        "Monitoramento de personagem/funÃ§Ã£o e eventos replicados",
        "Feito por Tales",
        "Data: "..os.date("%d/%m/%Y %H:%M:%S"),
        "Tempo de coleta: "..math.floor(os.clock()-startTime).." segundos",
        "Varreduras: "..scanCount,
        "Registros acumulados: "..#records,
        "Pendentes online: "..#sendQueue,
        "Ultima varredura: "..lastScan,
        "========================================"
    }

    for i,e in ipairs(records) do
        table.insert(out,"\nREGISTRO "..i)

        local keys = {}
        for k in pairs(e) do table.insert(keys,k) end
        table.sort(keys)

        for _,k in ipairs(keys) do
            local v = e[k]

            if type(v)=="table" then
                table.insert(out,tostring(k)..":")
                local subkeys = {}
                for sk in pairs(v) do table.insert(subkeys,sk) end
                table.sort(subkeys)

                for _,sk in ipairs(subkeys) do
                    table.insert(out,"  "..tostring(sk).." = "..tostring(v[sk]))
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
    if showPage then showPage("Dados") end

    if statusLabel then
        statusLabel.Text = "Gerando relatÃ³rio completo..."
    end

    task.spawn(function()
        -- Se ainda nÃ£o existe nenhum registro, faz uma coleta manual.
        if #records==0 then
            scanGame()
        end

        local full = exportData()

        if reportBox then
            reportBox.Visible = true
            reportBox.Text = full
            reportBox.CursorPosition = 1
            reportBox:CaptureFocus()
            reportBox.SelectionStart = 1
            reportBox.CursorPosition = #full+1
        end

        local clipboard =
            (type(setclipboard)=="function" and setclipboard)
            or (type(toclipboard)=="function" and toclipboard)

        if clipboard then
            local ok,err = pcall(clipboard,full)

            if ok then
                if statusLabel then
                    statusLabel.Text =
                        "RelatÃ³rio copiado! "
                        ..#full.." caracteres | "
                        ..#records.." registros"
                end
            else
                if statusLabel then
                    statusLabel.Text =
                        "RelatÃ³rio exibido abaixo. Clipboard: "..tostring(err)
                end
            end
        else
            if statusLabel then
                statusLabel.Text =
                    "RelatÃ³rio exibido abaixo. Selecione o texto para copiar."
            end
        end
    end)
end

--==============================================================
-- BRILHO
--==============================================================
local function setBrightness(enabled)
    states.Brightness = enabled

    if enabled then
        if not next(savedLighting) then
            savedLighting = {
                Brightness=Lighting.Brightness,
                ClockTime=Lighting.ClockTime,
                GlobalShadows=Lighting.GlobalShadows,
                Ambient=Lighting.Ambient,
                OutdoorAmbient=Lighting.OutdoorAmbient
            }
        end

        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200,200,200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
    else
        for k,v in pairs(savedLighting) do
            pcall(function() Lighting[k]=v end)
        end
        table.clear(savedLighting)
    end
end

--==============================================================
-- ANTI-FLASH V26
--==============================================================

local function effectLooksLikeFlash(obj)
    return contains(obj.Name,{
        "flash","blind","flashbang","clarÃ£o",
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
    if (not states.AntiFlash and not states.DataCollector)
        or not obj or isInsideShop(obj) then
        return
    end

    local flashEffect = false

    if obj:IsA("BlurEffect")
        or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("BloomEffect") then

        flashEffect = effectLooksLikeFlash(obj)

        -- Efeitos com nome genÃ©rico sÃ³ sÃ£o considerados flash durante a janela
        -- curta apÃ³s ativaÃ§Ã£o de ferramenta; brilho alto sozinho nÃ£o Ã© evidÃªncia.
        if not flashEffect and obj:IsA("ColorCorrectionEffect")
            and os.clock()<=recentToolUseUntil then
            pcall(function()
                flashEffect = obj.Brightness>0.65
                    or obj.Contrast>0.65 or obj.Saturation < -0.75
            end)
        end
    end

    local visualClass=obj:IsA("BlurEffect")
        or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect")
    local recentVisualCandidate=visualClass and os.clock()<=recentToolUseUntil

    if (flashEffect or recentVisualCandidate) then
        if states.DataCollector and not reportedFlashObjects[obj] then
            reportedFlashObjects[obj]=true
            makeObjectReport(obj,flashEffect and "FlashVisualEffectDetected"
                or "VisualEffectAfterToolActivation")
        end
    end

    if flashEffect then
        if states.AntiFlash then
            if savedEffects[obj]==nil then savedEffects[obj] = obj.Enabled end
            pcall(function() obj.Enabled=false end)
        end
    end

    if obj:IsA("Frame") or obj:IsA("ImageLabel") then
        local size = obj.AbsoluteSize
        local camera=Workspace.CurrentCamera
        local screen = camera and camera.ViewportSize or Vector2.new(0,0)

        if screen.X>0 and screen.Y>0
            and size.X>=screen.X*0.88
            and size.Y>=screen.Y*0.88 then

            local white = false

            if obj:IsA("Frame") then
                local c = obj.BackgroundColor3
                white = c.R>0.88 and c.G>0.88 and c.B>0.88
                    and obj.BackgroundTransparency<0.25
            elseif obj:IsA("ImageLabel") then
                local c=obj.ImageColor3
                white=c.R>0.88 and c.G>0.88 and c.B>0.88
                    and obj.ImageTransparency<0.25
            end

            if white then
                if states.DataCollector and not reportedFlashObjects[obj] then
                    reportedFlashObjects[obj]=true
                    makeObjectReport(obj,"FullScreenWhiteFlashOverlayDetected")
                end
                if states.AntiFlash and (effectLooksLikeFlash(obj)
                    or os.clock()<=recentToolUseUntil) then
                    if savedOverlays[obj]==nil then savedOverlays[obj] = obj.Visible end
                    pcall(function() obj.Visible=false end)
                end
            end
        end
    end
end

inspectFlashRoot = function(root)
    if not root then return end
    for index,obj in ipairs(root:GetDescendants()) do
        inspectFlashObject(obj)
        if index%300==0 then task.wait() end
    end
end

watchFlashRoot = function(root)
    if not root or watchedFlashRoots[root] then return end
    watchedFlashRoots[root] = true

    root.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if obj and obj.Parent then
                inspectFlashObject(obj)
                if obj:IsA("GuiObject") then
                    task.delay(0.15,function()
                        if obj and obj.Parent then inspectFlashObject(obj) end
                    end)
                end
            end
        end)
    end)
end

local function setAntiFlash(enabled)
    states.AntiFlash = enabled

    if enabled then
        watchFlashRoot(Lighting)
        watchFlashRoot(PlayerGui)
        watchFlashRoot(player.Character)
        watchFlashRoot(Workspace.CurrentCamera)

        inspectFlashRoot(Lighting)
        inspectFlashRoot(PlayerGui)
        inspectFlashRoot(player.Character)
        inspectFlashRoot(Workspace.CurrentCamera)
    else
        for obj,value in pairs(savedEffects) do
            if obj and obj.Parent then
                pcall(function() obj.Enabled=value end)
            end
        end
        table.clear(savedEffects)

        for obj,value in pairs(savedOverlays) do
            if obj and obj.Parent then
                pcall(function() obj.Visible=value end)
            end
        end
        table.clear(savedOverlays)
    end
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if states.AntiFlash or states.DataCollector then
        local camera = Workspace.CurrentCamera
        watchFlashRoot(camera)
        inspectFlashRoot(camera)
    end
end)

player.CharacterAdded:Connect(function(char)
    if states.AntiFlash then
        task.wait(1)
        watchFlashRoot(char)
        inspectFlashRoot(char)
    end
end)

--==============================================================
-- STAMINA V26: DIAGNÃ“STICO DIRECIONADO E ALTERAÃ‡ÃƒO LOCAL LIMITADA
--==============================================================

local staminaOriginals = {}
local function isStaminaName(name)
    return contains(name,{
        "stamina","sprint","energy","energia",
        "resist","endurance","folego","fÃ´lego"
    })
end

local function findStaminaObjects()
    local found={}
    local searchRoots={player}
    if player.Character then table.insert(searchRoots,player.Character) end
    local scripts=player:FindFirstChild("PlayerScripts")
    if scripts then table.insert(searchRoots,scripts) end
    local backpack=player:FindFirstChild("Backpack")
    if backpack then table.insert(searchRoots,backpack) end
    table.insert(searchRoots,PlayerGui)

    local seen={}
    for _,root in ipairs(searchRoots) do
        for _,obj in ipairs(root:GetDescendants()) do
            local candidate=isStaminaName(obj.Name)
            if not candidate then
                for key in pairs(obj:GetAttributes()) do
                    if isStaminaName(key) then candidate=true break end
                end
            end
            if candidate and not seen[obj] then
                seen[obj]=true
                table.insert(found,obj)
                -- SÃ³ altera NumberValue/IntValue explicitamente identificados.
                -- NÃ£o faz require() nem modifica upvalues de mÃ³dulos desconhecidos.
                if states.InfiniteStamina
                    and (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
                    if staminaOriginals[obj]==nil then staminaOriginals[obj]=obj.Value end
                    pcall(function() obj.Value=999999 end)
                end
            end
        end
    end
    local hud=PlayerGui:FindFirstChild("StaminaHUD")
    if hud and not seen[hud] then table.insert(found,hud) end
    return found
end

local function setInfiniteStamina(enabled)
    states.InfiniteStamina = enabled

    if enabled then
        findStaminaObjects()
    else
        for obj,value in pairs(staminaOriginals) do
            if obj and obj.Parent then
                pcall(function() obj.Value=value end)
            end
        end
        table.clear(staminaOriginals)
    end
end

--==============================================================
-- AUTO FARM
--==============================================================

local promptCache={}
local promptSet=setmetatable({}, {__mode="k"})
local promptCacheBuilt=false

local function registerPrompt(obj)
    if obj and obj:IsA("ProximityPrompt") and not promptSet[obj] then
        promptSet[obj]=true
        table.insert(promptCache,obj)
    end
end

Workspace.DescendantAdded:Connect(registerPrompt)

local function buildPromptCacheOnce()
    if promptCacheBuilt then return end
    promptCacheBuilt=true
    for index,obj in ipairs(Workspace:GetDescendants()) do
        registerPrompt(obj)
        if index%400==0 then task.wait() end
    end
end

local function setAutoFarm(enabled)
    states.AutoFarm=enabled
    farmGeneration+=1
    local generation=farmGeneration
    if not enabled then return end

    task.spawn(function()
        buildPromptCacheOnce()
        while generation==farmGeneration and gui and gui.Parent do
            local char=player.Character
            local root=char and char:FindFirstChild("HumanoidRootPart")
            if root then
                for index,obj in ipairs(promptCache) do
                    if generation~=farmGeneration then break end
                    if obj and obj.Parent and obj.Enabled then
                        local part=obj.Parent
                        if part and part:IsA("Attachment") then part=part.Parent end
                        if part and part:IsA("BasePart")
                            and (root.Position-part.Position).Magnitude<=obj.MaxActivationDistance then
                            pcall(function()
                                obj:InputHoldBegin()
                                task.wait(0.12)
                                obj:InputHoldEnd()
                            end)
                            task.wait(0.25)
                        end
                    end
                    if index%100==0 then task.wait() end
                end
            end
            task.wait(1.5)
        end
    end)
end

--==============================================================
-- INTERFACE
--==============================================================

gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV26"
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
title.Text = "ROUBE OU MORRA V26  |  Feito por Tales"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(38,34)
minimize.Position = UDim2.new(1,-44,0,7)
minimize.Text = "â€”"
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

local pages,pageButtons = {},{}

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

showPage = function(name)
    for n,p in pairs(pages) do p.Visible=n==name end

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
                warn("[V26] "..name..": "..tostring(err))
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
    b.MouseButton1Click:Connect(function() showPage(name) end)
    pageButtons[name] = b
end

local pMain = makePage("Principal")
local pESP = makePage("ESP")
local pEnv = makePage("Ambiente")
local pCollect = makePage("Coleta")
local pData = makePage("Dados")
local pConfig = makePage("ConfiguraÃ§Ãµes")

for _,name in ipairs({
    "Principal","ESP","Ambiente","Coleta","Dados","ConfiguraÃ§Ãµes"
}) do
    addNav(name)
end

-- PRINCIPAL
addSection(pMain,"ROUBE OU MORRA V26 | Feito por Tales")
addButton(pMain,"Painel atualizado | Feito por Tales",function() end)
addButton(pMain,"Acesse as categorias ao lado para configurar os recursos",function() end)

-- ESP
addSection(pESP,"ESP DE JOGADORES E ENTIDADES")
addToggle(pESP,"ESP Jogadores","ESPPlayers",function(v) setESP("ESPPlayers",v) end)
addToggle(pESP,"ESP Monstros","ESPMonsters",function(v) setESP("ESPMonsters",v) end)
addToggle(pESP,"ESP Dutos (contorno sem nome)","ESPDucts",function(v) setESP("ESPDucts",v) end)

addSection(pESP,"ESP DE ITENS POR RARIDADE")
for _,rarity in ipairs({
    "Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret"
}) do
    addToggle(pESP,"ESP "..rarity,rarity,function()
        refreshESP()
    end,rarityEnabled)
end

-- AMBIENTE
addSection(pEnv,"MAPA E VISIBILIDADE")
addToggle(pEnv,"Remover Portas e Tampas de Dutos","RemoveDoors",setDoors)
addToggle(pEnv,"Brilho","Brightness",setBrightness)
addToggle(pEnv,"Anti-Flash","AntiFlash",setAntiFlash)

-- COLETA
addSection(pCollect,"COLETA")
addToggle(pCollect,"Coleta InstantÃ¢nea","InstantCollection",setInstant)
addToggle(pCollect,"Auto Farm (prompts no alcance)","AutoFarm",setAutoFarm)
addToggle(pCollect,"Stamina Infinita (experimental - apenas valores locais identificados)","InfiniteStamina",setInfiniteStamina)

-- DADOS
addSection(pData,"COLETOR AUTOMÃTICO DA PARTIDA")
addButton(pData,"V26: estamina, entidades, ferramentas, projÃ©teis e clarÃµes",function()
    statusLabel.Text = "Cliente: coleta somente dados replicados/visÃ­veis; valores do servidor nÃ£o sÃ£o acessÃ­veis."
end)

addToggle(pData,"Coletor automÃ¡tico durante a partida","DataCollector",function(enabled)
    if enabled then
        statusLabel.Text = "Iniciando coleta direcionada..."
        watchFlashRoot(Lighting)
        watchFlashRoot(PlayerGui)
        watchFlashRoot(player.Character)
        watchFlashRoot(Workspace.CurrentCamera)
        discoverExistingEntities()
        inspectFlashRoot(Lighting)
        inspectFlashRoot(PlayerGui)
        inspectFlashRoot(player.Character)
        inspectFlashRoot(Workspace.CurrentCamera)
        local a = scanGame()
        statusLabel.Text =
            "Coleta ativa | Novos: "..a
            .." | Total: "..#records
            .." | Pendentes: "..#sendQueue
        flushReports()
    else
        statusLabel.Text = "Coleta automÃ¡tica pausada"
    end
end)

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-6,0,58)
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
tokenBox.PlaceholderText = "Cole o valor salvo em COLLECTOR_TOKEN"
tokenBox.Text = ""
tokenBox.TextSize = 11
tokenBox.ClearTextOnFocus = false
tokenBox.Parent = pData
Instance.new("UICorner",tokenBox).CornerRadius = UDim.new(0,6)

addButton(pData,"APLICAR TOKEN E ENVIAR FILA",function()
    COLLECTOR_TOKEN = tokenBox.Text:gsub("^%s+",""):gsub("%s+$","")

    if COLLECTOR_TOKEN=="" then
        statusLabel.Text = "Token vazio. Cole o valor do segredo."
        return
    end

    statusLabel.Text = "Token aplicado. Tentando enviar..."
    flushReports()
end)

reportBox = Instance.new("TextBox")
reportBox.Size = UDim2.new(1,-6,0,210)
reportBox.BackgroundColor3 = Color3.fromRGB(10,10,13)
reportBox.TextColor3 = Color3.new(1,1,1)
reportBox.PlaceholderText = "O relatÃ³rio completo aparecerÃ¡ aqui..."
reportBox.Text = ""
reportBox.TextSize = 10
reportBox.TextWrapped = false
reportBox.TextXAlignment = Enum.TextXAlignment.Left
reportBox.TextYAlignment = Enum.TextYAlignment.Top
reportBox.ClearTextOnFocus = false
reportBox.MultiLine = true
reportBox.TextEditable = true
reportBox.Parent = pData
Instance.new("UICorner",reportBox).CornerRadius = UDim.new(0,6)

addButton(pData,"GERAR E COPIAR RELATÃ“RIO INTEIRO",copyFullReport)

addButton(pData,"ATUALIZAR E ENVIAR AGORA",function()
    statusLabel.Text = "Atualizando dados..."
    local a = scanGame()
    flushReports()

    statusLabel.Text =
        "Varredura concluÃ­da | Novos: "..a
        .." | Registros: "..#records
        .." | Pendentes: "..#sendQueue
end)

addButton(pData,"LIMPAR RELATÃ“RIO LOCAL",function()
    table.clear(records)
    table.clear(recordIndex)
    table.clear(sentKeys)
    table.clear(queuedKeys)
    table.clear(sendQueue)

    scanCount = 0
    startTime = os.clock()
    lastScan = "Nenhuma"
    lastDataScan = 0

    reportBox.Text = ""
    statusLabel.Text = "RelatÃ³rio local limpo"
end)

-- CONFIGURAÃ‡Ã•ES
addSection(pConfig,"DIAGNÃ“STICO E CONFIGURAÃ‡Ã•ES")

addButton(pConfig,"VERIFICAR CAMINHOS DE STAMINA",function()
    local found = findStaminaObjects()

    local lines = {
        "DIAGNÃ“STICO DE STAMINA V26",
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
    statusLabel.Text = "DiagnÃ³stico de stamina concluÃ­do"
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
-- ATUALIZAÃ‡ÃƒO OTIMIZADA
--==============================================================

task.spawn(function()
    local lastDoor = 0
    local lastStamina = 0

    while gui and gui.Parent do
        local now = os.clock()

        -- ESP Ã© atualizado por ativaÃ§Ã£o, troca de personagem e novos objetos.
        -- NÃ£o existe mais varredura periÃ³dica do mapa inteiro.

        if states.RemoveDoors and now-lastDoor>=1.0 then
            refreshDoorCollision()
            lastDoor = now
        end

        if states.InfiniteStamina and now-lastStamina>=10 then
            findStaminaObjects()
            lastStamina = now
        end

        -- Anti-Flash Ã© orientado a eventos: evita varrer toda a interface a cada 0,5s.

        if states.DataCollector and now-lastDataScan>=30 then
            local a = scanGame()

            if statusLabel and not sendBusy then
                statusLabel.Text =
                    "Coleta ativa | Novos: "..a
                    .." | Total: "..#records
                    .." | Pendentes: "..#sendQueue
                    .." | "..lastHTTP
            end

            flushReports()
        end

        task.wait(0.25)
    end
end)

--==============================================================
-- LIMPEZA
--==============================================================

gui.Destroying:Connect(function()
    farmGeneration += 1
    espGeneration += 1

    restoreDoors()
    setInstant(false)
    setBrightness(false)
    setAntiFlash(false)
    setInfiniteStamina(false)
    clearESP()

    for obj,bill in pairs(labels) do
        if bill then bill:Destroy() end
        labels[obj] = nil
    end
end)
