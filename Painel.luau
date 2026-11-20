--==============================================================
-- ROUBE OU MORRA V40 | Feito por Tales
-- ESP incremental com limite de renderização | Classificação rigorosa de entidades
-- Anti-Flash preservado | V40: filtro de dutos no piso, raridades ampliadas e diagnósticos transparentes
-- Resistência (barra fina) registrada apenas como referência visual separada
-- Limites defensivos para desempenho mobile e tipografia padronizada | V40: filtro geométrico de dutos e raridades ampliadas
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

for _,name in ipairs({"RoubeOuMorraV19","RoubeOuMorraV20","RoubeOuMorraV21","RoubeOuMorraV22","RoubeOuMorraV24","RoubeOuMorraV25","RoubeOuMorraV26","RoubeOuMorraV27","RoubeOuMorraV28","RoubeOuMorraV29","RoubeOuMorraV30","RoubeOuMorraV31","RoubeOuMorraV33","RoubeOuMorraV34","RoubeOuMorraV35","RoubeOuMorraV36","RoubeOuMorraV37","RoubeOuMorraV38","RoubeOuMorraV39","RoubeOuMorraV40"}) do
    local old = PlayerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local gui

local states = {
    ESPPlayers=false, ESPMonsters=false, ESPDucts=false,
    RemoveDoors=false, InstantCollection=false,
    Brightness=false, AntiFlash=false,
    DataCollector=false, AutoFarm=false,
    InfiniteStamina=false, AutoJump=false, PlayerInvisible=false, AssistantIA=false
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
local previousESPFolder = Workspace:FindFirstChild("TalesESP_V26_Folder")
if previousESPFolder then previousESPFolder:Destroy() end
local previousV27ESPFolder = Workspace:FindFirstChild("TalesESP_V27_Folder")
if previousV27ESPFolder then previousV27ESPFolder:Destroy() end
local previousV28ESPFolder = Workspace:FindFirstChild("TalesESP_V28_Folder")
if previousV28ESPFolder then previousV28ESPFolder:Destroy() end
local previousV29ESPFolder = Workspace:FindFirstChild("TalesESP_V29_Folder")
if previousV29ESPFolder then previousV29ESPFolder:Destroy() end
local previousV30ESPFolder = Workspace:FindFirstChild("TalesESP_V30_Folder")
if previousV30ESPFolder then previousV30ESPFolder:Destroy() end
local previousV31ESPFolder = Workspace:FindFirstChild("TalesESP_V31_Folder")
if previousV31ESPFolder then previousV31ESPFolder:Destroy() end
local previousV36ESPFolder = Workspace:FindFirstChild("TalesESP_V36_Folder")
if previousV36ESPFolder then previousV36ESPFolder:Destroy() end
local previousV37ESPFolder = Workspace:FindFirstChild("TalesESP_V37_Folder")
if previousV37ESPFolder then previousV37ESPFolder:Destroy() end
local previousV38ESPFolder = Workspace:FindFirstChild("TalesESP_V38_Folder")
if previousV38ESPFolder then previousV38ESPFolder:Destroy() end
local previousV39ESPFolder = Workspace:FindFirstChild("TalesESP_V39_Folder")
if previousV39ESPFolder then previousV39ESPFolder:Destroy() end
local espFolder = Workspace:FindFirstChild("TalesESP_V40_Folder")
if not espFolder then
    espFolder = Instance.new("Folder")
    espFolder.Name = "TalesESP_V40_Folder"
    espFolder.Parent = Workspace
end
local hiddenParts,savedPrompts = {},{}
local savedEffects,savedOverlays = {},{}
local savedLighting = {}
local watchedFlashRoots = setmetatable({}, {__mode="k"})
local reportedFlashObjects = setmetatable({}, {__mode="k"})
local watchedFlashObjects = setmetatable({}, {__mode="k"})
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
-- Limites defensivos para manter o ESP utilizável em dispositivos móveis.
-- Alvos muito distantes não recebem Highlight/label; o cache continua incremental.
local MAX_ESP_OBJECTS = 90
local MAX_ESP_DISTANCE = 450
local farmGeneration = 0
local showPage
local toggleDrawers={}
local watchFlashRoot, inspectFlashRoot

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

local characterOwners=setmetatable({}, {__mode="k"})
local function registerPlayerCharacter(plr,char)
    if char then characterOwners[char]=plr end
end
for _,plr in ipairs(Players:GetPlayers()) do
    registerPlayerCharacter(plr,plr.Character)
    plr.CharacterAdded:Connect(function(char) registerPlayerCharacter(plr,char) end)
    plr.CharacterRemoving:Connect(function(char) characterOwners[char]=nil end)
end
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char) registerPlayerCharacter(plr,char) end)
    plr.CharacterRemoving:Connect(function(char) characterOwners[char]=nil end)
end)
Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then characterOwners[plr.Character]=nil end
end)

local function getPlayerFromModel(model)
    local owner=characterOwners[model]
    if owner and owner.Parent==Players then return owner end
    -- Fallback raro para personagens que já existiam antes da conexão.
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr.Character==model then
            characterOwners[model]=plr
            return plr
        end
    end
end

local knownEntityKinds = {
    tenant=true, hollow=true, locust=true, rictus=true, wendell=true,
    mimic=true, wraith=true, maternalwraith=true, thetenant=true, thehollow=true,
    thelocust=true, therictus=true, thewendell=true, thematernalwraith=true
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
    for _,key in ipairs({"EntityKind","EntityType","Role","TeamRole","CharacterType","NPCType","Class","CharacterClass"}) do
        if normalizedEntityKind(container:GetAttribute(key)) then return true end
    end
    return false
end

local function isMonster(model)
    if not model or not model:IsA("Model") then return false end

    local owner=getPlayerFromModel(model)
    -- Para personagens de jogadores, não usamos nome, texto genérico, classe ou
    -- atributos de estado isolados. Exigimos uma marca explícita de entidade.
    if owner then
        -- Em personagem de Player, seleção de entidade/loadout nunca prova transformação.
        -- Exigimos marcador booleano de estado atual no Character ou no Player.
        local function truthy(value)
            if value==true or value==1 then return true end
            if type(value)=="string" then
                local v=string.lower(value)
                return v=="true" or v=="1" or v=="yes"
            end
            return false
        end
        local inLobby=truthy(model:GetAttribute("InLobby")) or truthy(owner:GetAttribute("InLobby"))
        local inMatch=model:GetAttribute("InMatch")
        if inMatch==nil then inMatch=owner:GetAttribute("InMatch") end
        if inLobby and inMatch~=nil and not truthy(inMatch) then return false end
        local function currentFlag(container)
            if not container then return false end
            for _,key in ipairs({"IsMonster","IsEntity","IsEnemy","Monster","Enemy"}) do
                if truthy(container:GetAttribute(key)) then return true end
            end
            return false
        end
        if currentFlag(model) or currentFlag(owner) then return true end
        -- EntityKind/EntityType no Character são aceitos como estado efetivo replicado;
        -- EntitySelected no Player é deliberadamente ignorado.
        for _,key in ipairs({"EntityKind","EntityType","CurrentEntityKind"}) do
            if normalizedEntityKind(model:GetAttribute(key)) then return true end
        end
        local ok,tags=pcall(function() return CollectionService:GetTags(model) end)
        if ok then
            for _,tag in ipairs(tags) do
                local t=string.lower(tostring(tag)):gsub("[%s_%-]","")
                if t=="entity" or t=="monster" or t=="enemy" or t=="isentity" then return true end
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

    -- Sem GetDescendants() aqui: a classificação precisa ser barata por chamada.
    -- Marcadores ValueBase relevantes são observados separadamente pelo coletor.
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

local function normalizeRarityText(value)
    local textValue=string.lower(tostring(value or ""))
    textValue=textValue:gsub("[%s_%-]","")
    return textValue
end

local function getRarity(obj)
    -- A raridade pode estar no Model, na peça principal ou em um ValueBase
    -- próximo. Procura somente alguns ancestrais para evitar varreduras caras.
    local current=obj
    for _=1,6 do
        if not current then break end
        for _,key in ipairs({"Rarity","Raridade","ItemRarity","RarityName","Tier"}) do
            local value=current:GetAttribute(key)
            if type(value)=="string" then
                local normalized=normalizeRarityText(value)
                for rarity in pairs(rarityEnabled) do
                    if normalized==normalizeRarityText(rarity)
                        or normalized:find(normalizeRarityText(rarity),1,true) then
                        return rarity
                    end
                end
            end
        end
        for _,child in ipairs(current:GetChildren()) do
            if child:IsA("StringValue") and contains(child.Name,{"rarity","raridade","tier"}) then
                local normalized=normalizeRarityText(child.Value)
                for rarity in pairs(rarityEnabled) do
                    if normalized==normalizeRarityText(rarity)
                        or normalized:find(normalizeRarityText(rarity),1,true) then
                        return rarity
                    end
                end
            end
        end
        current=current.Parent
    end
    return nil
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
        h.Name = "TalesESP_V29"
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
        bill.Name = "TalesESPLabel_V29"
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

-- Identifica somente o próprio objeto duto, não qualquer peça
-- que esteja próxima ou seja descendente dele.
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
local refreshESP

local rarityWatchSet=setmetatable({}, {__mode="k"})
local function registerESPCandidate(obj)
    if not obj then return end

    -- Observa metadados também em objetos ainda sem raridade. Alguns itens recebem
    -- o atributo depois de serem parentados no Workspace.
    if (obj:IsA("Model") or obj:IsA("BasePart")) and not rarityWatchSet[obj] then
        rarityWatchSet[obj]=true
        for _,attributeName in ipairs({"Rarity","Raridade","ItemRarity","RarityName","Tier"}) do
            obj:GetAttributeChangedSignal(attributeName):Connect(function()
                if getRarity(obj) then
                    registerESPCandidate(obj)
                end
                if gui and gui.Parent and refreshESP then task.defer(refreshESP) end
            end)
        end
    end

    if espCandidateSet[obj] then return end
    local eligible=false
    if obj:IsA("Model") then
        local isPlayerModel=getPlayerFromModel(obj)~=nil
        local hasHumanoid=obj:FindFirstChildOfClass("Humanoid")~=nil
        -- Dutos-modelo entram no cache próprio sem alterar a classificação
        -- de jogadores ou monstros.
        eligible=isPlayerModel or hasHumanoid or isMonster(obj) or isDuctRoot(obj) or getRarity(obj)~=nil
        if not eligible then
            for _,desc in ipairs(obj:GetChildren()) do
                if desc:IsA("ValueBase") and contains(desc.Name,{"rarity","raridade","tier"}) then
                    eligible=true
                    break
                end
            end
        end
    elseif obj:IsA("BasePart") then
        -- Não guardar cada peça do mapa: somente dutos e itens com raridade explícita.
        eligible=isDuctRoot(obj) or getRarity(obj)~=nil
    end
    if eligible then
        espCandidateSet[obj]=true
        table.insert(espCandidateList,obj)
    end
end

local function buildESPCacheOnce()
    if espCacheBuilt then return end
    espCacheBuilt = true
    -- Uma varredura inicial única; atualizações seguintes são incrementais.
    for index,obj in ipairs(Workspace:GetDescendants()) do
        registerESPCandidate(obj)
        if index%350==0 then task.wait() end
    end
end

local function getESPWorldPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local root = obj:FindFirstChild("HumanoidRootPart")
            or obj.PrimaryPart
            or obj:FindFirstChildWhichIsA("BasePart")
        if root and root:IsA("BasePart") then return root.Position end
        local ok, pivot = pcall(function() return obj:GetPivot() end)
        if ok then return pivot.Position end
    end
    return nil
end

-- V40: validação geométrica do duto. O contorno só é desenhado quando
-- a parte inferior do objeto está próxima de um piso alcançável; dutos no teto
-- e peças suspensas são descartados. O resultado fica em cache por pouco tempo.
local ductGroundCache=setmetatable({}, {__mode="k"})
local function isGroundAccessibleDuct(obj)
    if not obj or not obj.Parent then return false end
    local cached=ductGroundCache[obj]
    if cached and os.clock()-cached.time<1.5 then return cached.ok end

    local center,size
    if obj:IsA("BasePart") then
        center=obj.Position
        size=obj.Size
    elseif obj:IsA("Model") then
        local ok,cf,bounds=pcall(function() return obj:GetBoundingBox() end)
        if not ok then return false end
        center=cf.Position
        size=bounds
    else
        return false
    end

    local cf
    if obj:IsA("BasePart") then
        cf=obj.CFrame
    else
        local ok,bboxCF=pcall(function() return obj:GetBoundingBox() end)
        if not ok then return false end
        cf=bboxCF
    end
    local verticalHalf=math.abs(cf.RightVector.Y)*size.X*0.5
        +math.abs(cf.UpVector.Y)*size.Y*0.5
        +math.abs(cf.LookVector.Y)*size.Z*0.5
    local bottomY=center.Y-verticalHalf
    local origin=Vector3.new(center.X,bottomY+0.45,center.Z)
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    local ductContainer=obj
    local ancestor=obj.Parent
    for _=1,6 do
        if not ancestor or ancestor==Workspace then break end
        if ancestor:IsA("Model") and isDuctRoot(ancestor) then
            ductContainer=ancestor
            break
        end
        ancestor=ancestor.Parent
    end
    local exclusions={ductContainer,espFolder}
    if player.Character then table.insert(exclusions,player.Character) end
    params.FilterDescendantsInstances=exclusions
    params.IgnoreWater=true

    local hit=Workspace:Raycast(origin,Vector3.new(0,-3.25,0),params)
    local ok=hit~=nil and hit.Distance<=2.35
    ductGroundCache[obj]={ok=ok,time=os.clock()}
    return ok
end

refreshESP = function()
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
        local renderedCount = 0
        local ductRenderedCount = 0
        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local myPosition = myRoot and myRoot.Position or nil

        for index,obj in ipairs(candidates) do
            if generation~=espGeneration then break end
            if not gui or not gui.Parent then break end

            local worldPosition = getESPWorldPosition(obj)
            local withinDistance = not myPosition or not worldPosition
                or (worldPosition-myPosition).Magnitude <= MAX_ESP_DISTANCE
            local canRender = renderedCount < MAX_ESP_OBJECTS and withinDistance

            if canRender and obj:IsA("Model") then
                local plr = getPlayerFromModel(obj)

                if plr and plr~=player and states.ESPMonsters and isMonster(obj) then
                    createESP(obj,Color3.fromRGB(255,35,35),plr.Name..getEntityActivitySuffix(obj),false)
                    keep[obj] = true
                    renderedCount += 1
                elseif plr and plr~=player and states.ESPPlayers then
                    createESP(obj,Color3.fromRGB(40,140,255),plr.Name,false)
                    keep[obj] = true
                    renderedCount += 1
                elseif states.ESPMonsters and isMonster(obj) then
                    local displayName=obj:GetAttribute("DisplayName")
                    or obj:GetAttribute("EntityKind")
                    or obj:GetAttribute("EntitySelected")
                    or obj.Name
                    createESP(obj,Color3.fromRGB(255,35,35),tostring(displayName)..getEntityActivitySuffix(obj),false)
                    keep[obj] = true
                    renderedCount += 1
                end
            end

            -- O ESP de dutos usa orçamento separado: excesso de jogadores/monstros
            -- não impede que os dutos próximos sejam destacados.
            if withinDistance and ductRenderedCount<MAX_ESP_OBJECTS
                and states.ESPDucts and isDuctRoot(obj)
                and isGroundAccessibleDuct(obj) then
                createESP(obj,Color3.fromRGB(255,170,40),nil,true)
                keep[obj] = true
                ductRenderedCount += 1
            end

            if canRender and renderedCount < MAX_ESP_OBJECTS
                and (obj:IsA("Model") or obj:IsA("BasePart")) then
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
                    renderedCount += 1
                end
            end

            if index%180==0 then task.wait() end
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
    local ancestor=obj.Parent
    for _=1,5 do
        if not ancestor or ancestor==Workspace then break end
        if ancestor:IsA("Model") or ancestor:IsA("BasePart") then
            registerESPCandidate(ancestor)
        end
        ancestor=ancestor.Parent
    end
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
-- COLETA INSTANTÂNEA
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

local function assistantReportIsRelevant(entry)
    if type(entry)~="table" then return false end
    local event=string.lower(tostring(entry.Event or ""))
    local name=string.lower(tostring(entry.Name or ""))
    local path=string.lower(tostring(entry.Path or ""))
    local blob=event.." "..name.." "..path

    -- Assistente IA mantém a coleta seletiva, agora cobrindo stamina, movimento,
    -- obstáculos, pulo, visibilidade e observações de monstros/alvos.
    if event=="localnumericcandidatesnapshot" or event=="staminacontext"
        or event=="staminahudtreesample" or event=="staminahudsample"
        or event=="movementobstaclesnapshot" or event=="jumpstatesample"
        or event=="visibilitystatesample" or event=="monstertargetobservation" then return true end
    if contains(blob,{"stamina","sprint","holdendstamina","energy","endurance","folego","fôlego",
        "jump","pulo","obstacle","obstaculo","obstáculo","collision","colisao","colisão",
        "raycast","humanoidstate","jumpheight","jumppower","invisible","invisibility","stealth",
        "visibility","visible","target","aggro","detection","detect","sight","vision","monster","monstro"}) then return true end
    return false
end

local function queueReport(entry,key)
    if not states.DataCollector then return end
    -- Assistente IA mantém a coleta seletiva para os sistemas investigados.
    if states.AssistantIA and not assistantReportIsRelevant(entry) then return end

    -- A mesma instância pode mudar de estado; cada versão do conteúdo recebe
    -- uma chave própria, em vez de bloquear para sempre pelo caminho.
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

    if code==409 then return true,"Registro já existente" end

    if code==401 or code==403 then
        return false,"Token recusado (HTTP "..code..")"
    elseif code==404 then
        return false,"Função ingest-report não encontrada (404)"
    elseif code==429 then
        return false,"Limite de requisições (429)"
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
        lastHTTP = "Token não informado"
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

local assistantTargetedScan
local movementAndVisibilitySnapshot

local function scanGame()
    if states.AssistantIA and assistantTargetedScan then return assistantTargetedScan("AssistantScan") end
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
-- V29: MONITORAMENTO DIRECIONADO DE PERSONAGENS, STATS E EVENTOS
--==============================================================

local watchedPlayers = setmetatable({}, {__mode="k"})
local watchedCharacters = setmetatable({}, {__mode="k"})
local watchedTools = setmetatable({}, {__mode="k"})
local watchedStats = setmetatable({}, {__mode="k"})
local statLastReport = setmetatable({}, {__mode="k"})
local eventSequence = 0
local lastStaminaSample = 0
local lastHudSample = 0
local lastNumericCandidateSample = 0
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
        elseif obj:IsA("ImageLabel") then
            entry.Image=obj.Image
            entry.ImageColor3=tostring(obj.ImageColor3)
            entry.ImageTransparency=obj.ImageTransparency
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
        InMatch=tostring(player:GetAttribute("InMatch")),
        InLobby=tostring(player:GetAttribute("InLobby")),
        Spectating=tostring(player:GetAttribute("Spectating")),
        PlayerAttributes={},CharacterAttributes={}
    }
    local numericAttributeCandidates={}
    for k,val in pairs(player:GetAttributes()) do
        data.PlayerAttributes[k]=tostring(val)
        if type(val)=="number" then
            table.insert(numericAttributeCandidates,{Owner="Player",Name=k,Value=val,
                NameSuggestsStamina=contains(k,{"stamina","sprint","energy","folego","fôlego"})})
        end
    end
    if char then
        for k,val in pairs(char:GetAttributes()) do
            data.CharacterAttributes[k]=tostring(val)
            if type(val)=="number" then
                table.insert(numericAttributeCandidates,{Owner="Character",Name=k,Value=val,
                    NameSuggestsStamina=contains(k,{"stamina","sprint","energy","folego","fôlego"})})
            end
        end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then
            data.Health=hum.Health
            data.WalkSpeed=hum.WalkSpeed
            data.MoveDirection=tostring(hum.MoveDirection)
            data.HumanoidState=tostring(hum:GetState())
        end
        local statValues={}
        local function isStaminaCandidate(obj)
            return obj and obj:IsA("ValueBase") and contains(obj.Name,{
                "stamina","sprint","holdendstamina","energy","resist","endurance","folego","fôlego"
            })
        end
        for _,obj in ipairs(char:GetDescendants()) do
            if isStaminaCandidate(obj) then
                local ok,value=pcall(function() return obj.Value end)
                if ok then statValues[safePath(obj)]=tostring(value) end
            end
        end
        local scripts=player:FindFirstChild("PlayerScripts")
        if scripts then
            for _,obj in ipairs(scripts:GetDescendants()) do
                if isStaminaCandidate(obj) then
                    local ok,value=pcall(function() return obj.Value end)
                    if ok then statValues[safePath(obj)]=tostring(value) end
                end
            end
        end
        data.CharacterValues=statValues
    end

    -- V37: procura valores numéricos locais mesmo quando o nome não contém
    -- "stamina". Isso permite correlacionar os valores com correr/parar.
    -- A resistência (barra fina) é tratada como recurso distinto, não como estamina.
    if now-lastNumericCandidateSample>=2 then
        lastNumericCandidateSample=now
        local roots={}
        if char then table.insert(roots,char) end
        local scripts=player:FindFirstChild("PlayerScripts")
        local backpack=player:FindFirstChild("Backpack")
        if scripts then table.insert(roots,scripts) end
        if backpack then table.insert(roots,backpack) end
        table.insert(roots,PlayerGui)
        table.insert(roots,player)
        local candidates={}
        local seenCandidates={}
        local totalVisited=0
        for _,root in ipairs(roots) do
            local objects={root}
            if root==player then
                for _,child in ipairs(root:GetChildren()) do table.insert(objects,child) end
            else
                for _,desc in ipairs(root:GetDescendants()) do table.insert(objects,desc) end
            end
            for _,obj in ipairs(objects) do
                totalVisited+=1
                if totalVisited>1800 then break end
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    if not seenCandidates[obj] and #candidates<120 then
                        seenCandidates[obj]=true
                        local value
                        pcall(function() value=obj.Value end)
                        table.insert(candidates,{
                            Name=obj.Name,Class=obj.ClassName,Path=safePath(obj),
                            Value=value,ValueString=tostring(value),
                            NameSuggestsStamina=contains(obj.Name,{"stamina","sprint","energy","folego","fôlego"}),
                            NameSuggestsResistance=contains(obj.Name,{"resist","endurance"})
                        })
                    end
                end
            end
            if totalVisited>1800 then break end
        end
        queueReport({Event="LocalNumericCandidateSnapshot",Reason=reason or "Sample",
            InMatch=tostring(player:GetAttribute("InMatch")),InLobby=tostring(player:GetAttribute("InLobby")),
            Movement=char and char:FindFirstChildOfClass("Humanoid")
                and tostring(char:FindFirstChildOfClass("Humanoid").MoveDirection) or "NoCharacter",
            Candidates=candidates,NumericAttributes=numericAttributeCandidates,Visited=totalVisited,
            CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ")},
            "LocalNumericCandidateSnapshot|"..tostring(math.floor(now/2)))
    end

    -- A barra pode ser apenas visual. Durante corrida/parada, compara alguns
    -- elementos de HUD e relata mudanças de tamanho/cor/texto sem assumir nomes.
    if reason=="Running" or reason=="Stopped" then
        if now-lastHudSample>=1.5 then
            lastHudSample=now
            local changed=0
            local staminaHud=PlayerGui:FindFirstChild("StaminaHUD")
            local hudObjects={}
            if staminaHud then
                table.insert(hudObjects,staminaHud)
                for _,descendant in ipairs(staminaHud:GetDescendants()) do
                    table.insert(hudObjects,descendant)
                end
            end
            local hudTree={}
            for _,obj in ipairs(hudObjects) do
                local candidate=obj:IsA("Frame") or obj:IsA("ImageLabel")
                    or (obj:IsA("TextLabel") and tonumber(obj.Text)~=nil)
                if candidate then
                    local signature=tostring(obj.Size).."|"..tostring(obj.Visible)
                    local colorInfo=""
                    if obj:IsA("Frame") then
                        colorInfo=tostring(obj.BackgroundColor3).."|"..tostring(obj.BackgroundTransparency)
                    elseif obj:IsA("ImageLabel") then
                        colorInfo=tostring(obj.ImageColor3).."|"..tostring(obj.ImageTransparency)
                    elseif obj:IsA("TextLabel") then
                        colorInfo=obj.Text
                    end
                    signature=signature.."|"..colorInfo
                    if #hudTree<24 then
                        table.insert(hudTree,{Path=safePath(obj),Class=obj.ClassName,
                            Size=tostring(obj.Size),AbsoluteSize=tostring(obj.AbsoluteSize),
                            Visible=tostring(obj.Visible),Visual=colorInfo})
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
            if #hudTree>0 then
                queueReport({Event="StaminaHUDTreeSample",Reason=reason,Objects=hudTree,
                    CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ")},
                    "StaminaHUDTreeSample|"..tostring(math.floor(now*2)))
            end
        end
    end

    queueReport(data,"StaminaContext|"..tostring(reason).."|"..tostring(math.floor(os.clock()*2)))
end

local roleSnapshot

local function watchStatObject(obj,source)
    if not obj or not obj:IsA("ValueBase") or watchedStats[obj] then return end
    local isNumeric=obj:IsA("NumberValue") or obj:IsA("IntValue")
    local staminaNamed=contains(obj.Name,{
        "stamina","sprint","holdendstamina","energy","resist","endurance","folego","fôlego"
    })
    local roleNamed=contains(obj.Name,{
        "role","entity","monster","enemy","team","class","type","flash"
    })
    local named=staminaNamed or roleNamed
    if not named or (isNumeric and not staminaNamed and not roleNamed) then return end
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

-- Varredura coordenada pela Assistente IA: não percorre Workspace inteiro nem captura
-- todos os GuiObjects/BaseParts. Prioriza estados de jogadores e amostras de stamina.
assistantTargetedScan = function(reason)
    scanCount += 1
    lastScan = os.date("%d/%m/%Y %H:%M:%S")
    local before=#records
    if states.DataCollector then
        staminaSnapshot(reason or "AssistantFocusedScan")
        movementAndVisibilitySnapshot(reason or "AssistantFocusedScan")
    end
    lastDataScan=os.clock()
    return math.max(0,#records-before),0
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
    -- Percorre apenas contêineres e Models: não inspeciona cada peça/objeto do mapa.
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

    -- Sem depender do nome: objetos que surgem logo após ativar uma ferramenta
    -- são candidatos a projétil/artefato lançado. Limite evita capturar o mapa inteiro.
    if states.DataCollector and os.clock()<=recentToolUseUntil
        and recentToolSpawnCount<24
        and (obj:IsA("Model") or obj:IsA("BasePart")) then
        recentToolSpawnCount+=1
        makeObjectReport(obj,"ObjectSpawnedAfterToolUse")
    end
end)

--==============================================================
-- RELATÓRIO MANUAL INTEGRAL
--==============================================================

local function exportData()
    local out = {
        "========================================",
        "ROUBE OU MORRA V40 - RELATORIO",
        "Investigação focada de estamina e candidatos numéricos locais",
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
        statusLabel.Text = "Gerando relatório completo..."
    end

    task.spawn(function()
        -- Se ainda não existe nenhum registro, faz uma coleta manual.
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
                        "Relatório copiado! "
                        ..#full.." caracteres | "
                        ..#records.." registros"
                end
            else
                if statusLabel then
                    statusLabel.Text =
                        "Relatório exibido abaixo. Clipboard: "..tostring(err)
                end
            end
        else
            if statusLabel then
                statusLabel.Text =
                    "Relatório exibido abaixo. Selecione o texto para copiar."
            end
        end
    end)
end

--==============================================================
-- BRILHO
--==============================================================
local savedBrightnessEffects = setmetatable({}, {__mode="k"})
local watchedBrightnessRoots = setmetatable({}, {__mode="k"})
local watchedBrightnessEffects = setmetatable({}, {__mode="k"})
local brightnessApplying = false

local function isBrightnessEffect(obj)
    return obj and (
        obj:IsA("BlurEffect")
        or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("BloomEffect")
        or obj:IsA("DepthOfFieldEffect")
        or obj:IsA("SunRaysEffect")
    )
end

local function suppressBrightnessEffect(obj)
    if not states.Brightness or not isBrightnessEffect(obj) or not obj.Parent then return end
    if savedBrightnessEffects[obj]==nil then
        local antiFlashOriginal=savedEffects[obj]
        savedBrightnessEffects[obj]=antiFlashOriginal~=nil and antiFlashOriginal or obj.Enabled
    end
    pcall(function() obj.Enabled=false end)
    if not watchedBrightnessEffects[obj] then
        watchedBrightnessEffects[obj]=true
        obj:GetPropertyChangedSignal("Enabled"):Connect(function()
            if states.Brightness and obj.Parent and obj.Enabled then
                pcall(function() obj.Enabled=false end)
            end
        end)
    end
end

local function watchBrightnessRoot(root)
    if not root or watchedBrightnessRoots[root] then return end
    watchedBrightnessRoots[root]=true
    for _,obj in ipairs(root:GetDescendants()) do
        suppressBrightnessEffect(obj)
    end
    root.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if states.Brightness and obj and obj.Parent then
                suppressBrightnessEffect(obj)
            end
        end)
    end)
end

local function enforceBrightness()
    if not states.Brightness or brightnessApplying then return end
    brightnessApplying=true
    pcall(function()
        Lighting.Brightness=3
        Lighting.ClockTime=14
        Lighting.GlobalShadows=false
        Lighting.Ambient=Color3.fromRGB(200,200,200)
        Lighting.OutdoorAmbient=Color3.fromRGB(200,200,200)
        Lighting.FogStart=0
        Lighting.FogEnd=100000
        Lighting.FogColor=Color3.fromRGB(200,200,200)
    end)
    brightnessApplying=false
end

for _,property in ipairs({
    "Brightness","ClockTime","GlobalShadows","Ambient","OutdoorAmbient",
    "FogStart","FogEnd","FogColor"
}) do
    Lighting:GetPropertyChangedSignal(property):Connect(function()
        if states.Brightness then
            task.defer(enforceBrightness)
        end
    end)
end

local function setBrightness(enabled)
    states.Brightness=enabled==true

    if states.Brightness then
        if not next(savedLighting) then
            savedLighting={
                Brightness=Lighting.Brightness,
                ClockTime=Lighting.ClockTime,
                GlobalShadows=Lighting.GlobalShadows,
                Ambient=Lighting.Ambient,
                OutdoorAmbient=Lighting.OutdoorAmbient,
                FogStart=Lighting.FogStart,
                FogEnd=Lighting.FogEnd,
                FogColor=Lighting.FogColor
            }
        end
        watchBrightnessRoot(Lighting)
        watchBrightnessRoot(Workspace.CurrentCamera)
        enforceBrightness()
    else
        for obj,value in pairs(savedBrightnessEffects) do
            if obj and obj.Parent then
                pcall(function() obj.Enabled=value end)
            end
        end
        table.clear(savedBrightnessEffects)
        for k,v in pairs(savedLighting) do
            pcall(function() Lighting[k]=v end)
        end
        table.clear(savedLighting)
    end
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if states.Brightness then
        watchBrightnessRoot(Workspace.CurrentCamera)
    end
end)

--==============================================================
-- ANTI-FLASH V29 | EFEITOS E OVERLAY CONHECIDOS
--==============================================================

local function effectLooksLikeFlash(obj)
    if not obj then return false end
    local name=string.lower(tostring(obj.Name or ""))
    if name=="flashblur" or name=="flashburn" then return true end
    return contains(name,{
        "flash","blind","flashbang","clarão",
        "stunflash","whiteout","flash_effect","blindness",
        "flashblur","flashburn","blackout","black_out","apagao","apagão",
        "darkness","disorient","desorient","disintegr","desintegr",
        "desync","desincron","dizzy","confusion","distortion"
    })
end

local function isInsideShop(obj)
    local current=obj
    for _=1,10 do
        if not current then break end
        if contains(current.Name,{"shop","store","loja","market"}) then return true end
        current=current.Parent
    end
    return false
end

local function isKnownRarityFlashOverlay(obj)
    if not obj or not (obj:IsA("Frame") or obj:IsA("ImageLabel")) then return false end
    local ok,path=pcall(function() return obj:GetFullName() end)
    if not ok then return false end
    local suffix="PlayerGui.RarityBoard.Frame.Frame"
    if string.sub(path,-#suffix)~=suffix then return false end
    local camera=Workspace.CurrentCamera
    local screen=camera and camera.ViewportSize or Vector2.new(0,0)
    local size=obj.AbsoluteSize
    if screen.X<=0 or screen.Y<=0 or size.X<screen.X*0.88 or size.Y<screen.Y*0.88 then
        return false
    end
    if obj:IsA("Frame") then
        local c=obj.BackgroundColor3
        return c.R>0.88 and c.G>0.88 and c.B>0.88 and obj.BackgroundTransparency<0.25
    end
    local c=obj.ImageColor3
    return c.R>0.88 and c.G>0.88 and c.B>0.88 and obj.ImageTransparency<0.25
end

local function isFlashGuiOverlay(obj)
    if not obj or not (obj:IsA("Frame") or obj:IsA("ImageLabel")) then return false end
    local current=obj.Parent
    local inKnownFlashGui=false
    for _=1,12 do
        if not current then break end
        if current:IsA("ScreenGui") and contains(current.Name,{
            "flashbang","nullflash","blackout","black_out","apagao","apagão",
            "darkness","blind","disorient","desorient","disintegr","desintegr",
            "desync","desincron","dizzy","confusion","distortion"
        }) then
            inKnownFlashGui=true
            break
        end
        current=current.Parent
    end
    if not inKnownFlashGui then return false end
    local camera=Workspace.CurrentCamera
    local screen=camera and camera.ViewportSize or Vector2.new(0,0)
    local size=obj.AbsoluteSize
    if screen.X<=0 or screen.Y<=0 or size.X<screen.X*0.80 or size.Y<screen.Y*0.80 then
        return false
    end
    -- A habilidade pode aplicar uma tela branca ou escura; a identificação
    -- confiável aqui é o ScreenGui conhecido + cobertura quase total da tela.
    if obj:IsA("Frame") then
        return obj.BackgroundTransparency<0.98
    end
    return obj.ImageTransparency<0.98
end

local function isInsideFlashGui(obj)
    local current=obj
    for _=1,12 do
        if not current then break end
        if current:IsA("ScreenGui") and contains(current.Name,{
            "flashbang","nullflash","blackout","black_out","apagao","apagão",
            "darkness","blind","disorient","desorient","disintegr","desintegr",
            "desync","desincron","dizzy","confusion","distortion"
        }) then
            return true
        end
        current=current.Parent
    end
    return false
end

local function suppressFlashObject(obj)
    if not obj or not obj.Parent then return end
    if obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") then
        if effectLooksLikeFlash(obj) then
            if savedEffects[obj]==nil then
                local brightnessOriginal=savedBrightnessEffects[obj]
                savedEffects[obj]=brightnessOriginal~=nil and brightnessOriginal or obj.Enabled
            end
            pcall(function() obj.Enabled=false end)
        end
    elseif obj:IsA("Frame") or obj:IsA("ImageLabel") then
        if isKnownRarityFlashOverlay(obj) or isFlashGuiOverlay(obj) then
            if savedOverlays[obj]==nil then savedOverlays[obj]=obj.Visible end
            pcall(function() obj.Visible=false end)
        end
    end
end

local function watchFlashObject(obj)
    if not obj or watchedFlashObjects[obj] then return end
    local target=effectLooksLikeFlash(obj) or isKnownRarityFlashOverlay(obj)
        or isInsideFlashGui(obj)
    if not target then return end
    watchedFlashObjects[obj]=true
    if obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") then
        obj:GetPropertyChangedSignal("Enabled"):Connect(function()
            if states.AntiFlash and obj.Parent and obj.Enabled then suppressFlashObject(obj) end
        end)
    elseif obj:IsA("GuiObject") then
        local function recheck()
            if states.AntiFlash and obj.Parent and obj.Visible then suppressFlashObject(obj) end
        end
        obj:GetPropertyChangedSignal("Visible"):Connect(recheck)
        if obj:IsA("Frame") then
            obj:GetPropertyChangedSignal("BackgroundTransparency"):Connect(recheck)
            obj:GetPropertyChangedSignal("BackgroundColor3"):Connect(recheck)
        elseif obj:IsA("ImageLabel") then
            obj:GetPropertyChangedSignal("ImageTransparency"):Connect(recheck)
            obj:GetPropertyChangedSignal("ImageColor3"):Connect(recheck)
        end
        obj:GetPropertyChangedSignal("AbsoluteSize"):Connect(recheck)
        obj:GetPropertyChangedSignal("Size"):Connect(recheck)
    end
end

local function inspectFlashObject(obj)
    if (not states.AntiFlash and not states.DataCollector) or not obj or isInsideShop(obj) then return end
    local flashEffect=effectLooksLikeFlash(obj)
    local knownOverlay=isKnownRarityFlashOverlay(obj)
    local flashGuiOverlay=isFlashGuiOverlay(obj)
    local insideFlashGui=isInsideFlashGui(obj)
    local visualClass=obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect")
    local recentVisualCandidate=visualClass and os.clock()<=recentToolUseUntil

    if (flashEffect or knownOverlay or flashGuiOverlay or recentVisualCandidate
        or (insideFlashGui and obj:IsA("GuiObject"))) and states.DataCollector
        and not reportedFlashObjects[obj] then
        reportedFlashObjects[obj]=true
        local eventName=(knownOverlay or flashGuiOverlay) and "FullScreenWhiteFlashOverlayDetected"
            or (flashEffect and "FlashVisualEffectDetected"
            or ((insideFlashGui and obj:IsA("GuiObject")) and "FlashGuiChildObserved"
            or "VisualEffectAfterToolActivation"))
        makeObjectReport(obj,eventName)
    end

    if states.AntiFlash then
        if insideFlashGui or flashEffect or knownOverlay then watchFlashObject(obj) end
        if flashEffect or knownOverlay or flashGuiOverlay then suppressFlashObject(obj) end
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
    if states.Brightness then
        watchBrightnessRoot(Workspace.CurrentCamera)
    end
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
-- STAMINA V37: COLETA FOCADA EM VALORES NUMÉRICOS LOCAIS
--==============================================================

local staminaOriginals = {}
local function isStaminaName(name)
    return contains(name,{
        "stamina","sprint","holdendstamina","energy","energia",
        "resist","endurance","folego","fôlego"
    })
end

local function isWritableStaminaValue(name)
    local normalized=string.lower(tostring(name or "")):gsub("[%s_%-]","")
    -- Não confundir UpgradeStamina/UpgradeSprint com a barra atual.
    return normalized=="stamina" or normalized=="currentstamina"
        or normalized=="staminacurrent" or normalized=="staminavalue"
        or normalized=="sprintstamina" or normalized=="currentsprintstamina"
        or normalized=="staminaamount" or normalized=="staminapool"
        or normalized=="currentenergy" or normalized=="energycurrent"
        or normalized=="energyvalue" or normalized=="currentstaminaamount"
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
        local objects={root}
        for _,descendant in ipairs(root:GetDescendants()) do
            table.insert(objects,descendant)
        end
        for _,obj in ipairs(objects) do
            local candidate=isStaminaName(obj.Name)
            if not candidate then
                for key in pairs(obj:GetAttributes()) do
                    if isStaminaName(key) then candidate=true break end
                end
            end
            if candidate and not seen[obj] then
                seen[obj]=true
                table.insert(found,obj)
                -- Só altera valores locais com nome de stamina ATUAL conhecido.
                -- UpgradeStamina/UpgradeSprint são níveis, não a barra de energia.
                -- Não faz require() nem modifica upvalues de módulos desconhecidos.
                if states.InfiniteStamina and isWritableStaminaValue(obj.Name)
                    and (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
                    if staminaOriginals[obj]==nil then staminaOriginals[obj]=obj.Value end
                    pcall(function() obj.Value=999999 end)
                end
            end
        end
    end
    local hud=PlayerGui:FindFirstChild("StaminaHUD")
    if hud and not seen[hud] then table.insert(found,hud) end
    -- O relatório identificou a barra visual exata. Ela é observada, nunca
    -- forçada para 100%, pois pode ser apenas apresentação do valor do servidor.
    if hud then
        local frame=hud:FindFirstChild("Frame")
        local fill=frame and frame:FindFirstChild("Frame")
        if fill and fill:IsA("GuiObject") then
            local scale=fill.Size.X.Scale
            if states.DataCollector then
                local data={Event="StaminaHUDSample",Path=safePath(fill),
                    FillScale=scale,Visible=fill.Visible,
                    CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ")}
                queueReport(data,"StaminaHUDSample|"..tostring(math.floor(os.clock()*2)))
            end
        end
    end
    return found
end

local function setInfiniteStamina(enabled)
    states.InfiniteStamina = enabled

    if enabled then
        local found=findStaminaObjects()
        if statusLabel then
            statusLabel.Text="Estamina experimental: "..tostring(#found).." objetos candidatos observados. O efeito real ainda depende do valor controlado pelo servidor."
        end
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
-- V39 | ASSISTENTE IA: FILTROS, PULO ADAPTATIVO E VISIBILIDADE LOCAL
--==============================================================
local autoJumpGeneration=0
local lastAutoJumpAt=0
local lastMovementReportAt=0
local savedLocalTransparency=setmetatable({}, {__mode="k"})
local savedBaseTransparency=setmetatable({}, {__mode="k"})
local savedVisualEnabled=setmetatable({}, {__mode="k"})
local savedHumanoidDisplay=setmetatable({}, {__mode="k"})
local invisibleDescendantConnection=nil

movementAndVisibilitySnapshot = function(reason)
    if not states.DataCollector then return end
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if hum then
        local jumpData={Event="JumpStateSample",Reason=tostring(reason or "Periodic"),
            State=tostring(hum:GetState()),FloorMaterial=tostring(hum.FloorMaterial),
            JumpPower=hum.JumpPower,JumpHeight=hum.JumpHeight,UseJumpPower=hum.UseJumpPower,
            WalkSpeed=hum.WalkSpeed,MoveDirection=tostring(hum.MoveDirection),
            Health=hum.Health,PlatformStand=hum.PlatformStand,
            CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ")}
        if root then
            jumpData.Position=tostring(root.Position)
            jumpData.AssemblyLinearVelocity=tostring(root.AssemblyLinearVelocity)
        end
        queueReport(jumpData,"JumpStateSample|"..tostring(math.floor(os.clock()/3)))
    end
    local visibility={Event="VisibilityStateSample",Reason=tostring(reason or "Periodic"),
        LocalInvisible=states.PlayerInvisible==true,ServerStealthConfirmed=false,
        VisibilityMode="ClientVisualOnly_ServerAIIntegrationRequired",
        PlayerAttributes={},CharacterAttributes={},CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ")}
    pcall(function() for k,v in pairs(player:GetAttributes()) do
        if contains(k,{"invis","visible","stealth","hide","detect","sight"}) then visibility.PlayerAttributes[k]=tostring(v) end
    end end)
    if char then pcall(function() for k,v in pairs(char:GetAttributes()) do
        if contains(k,{"invis","visible","stealth","hide","detect","sight"}) then visibility.CharacterAttributes[k]=tostring(v) end
    end end) end
    queueReport(visibility,"VisibilityStateSample|"..tostring(math.floor(os.clock()/5)))

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player and plr.Character and isMonster(plr.Character) then
            local model=plr.Character
            local hum2=model:FindFirstChildOfClass("Humanoid")
            local targetData={Event="MonsterTargetObservation",MonsterName=plr.Name,
                MonsterPath=safePath(model),Attributes={},CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ")}
            pcall(function() for k,v in pairs(model:GetAttributes()) do
                if contains(k,{"target","aggro","detect","vision","sight","attack","chase","player"}) then targetData.Attributes[k]=tostring(v) end
            end end)
            if hum2 then targetData.State=tostring(hum2:GetState()) end
            queueReport(targetData,"MonsterTargetObservation|"..tostring(plr.UserId).."|"..tostring(math.floor(os.clock()/5)))
        end
    end
end

local function applyLocalInvisibleToObject(obj,enabled)
    if not obj then return end
    if obj:IsA("BasePart") then
        if enabled then
            if savedLocalTransparency[obj]==nil then
                savedLocalTransparency[obj]=obj.LocalTransparencyModifier
            end
            if savedBaseTransparency[obj]==nil then
                savedBaseTransparency[obj]=obj.Transparency
            end
            pcall(function()
                obj.LocalTransparencyModifier=1
                obj.Transparency=1
            end)
        else
            local oldLocal=savedLocalTransparency[obj]
            local oldTransparency=savedBaseTransparency[obj]
            if oldLocal~=nil then pcall(function() obj.LocalTransparencyModifier=oldLocal end) end
            if oldTransparency~=nil then pcall(function() obj.Transparency=oldTransparency end) end
            savedLocalTransparency[obj]=nil
            savedBaseTransparency[obj]=nil
        end
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        if enabled then
            if savedLocalTransparency[obj]==nil then savedLocalTransparency[obj]=obj.Transparency end
            pcall(function() obj.Transparency=1 end)
        else
            local old=savedLocalTransparency[obj]
            if old~=nil then pcall(function() obj.Transparency=old end) end
            savedLocalTransparency[obj]=nil
        end
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
        or obj:IsA("BillboardGui") or obj:IsA("SurfaceGui")
        or obj:IsA("Highlight") then
        if enabled then
            if savedVisualEnabled[obj]==nil then savedVisualEnabled[obj]=obj.Enabled end
            pcall(function() obj.Enabled=false end)
        else
            local old=savedVisualEnabled[obj]
            if old~=nil then pcall(function() obj.Enabled=old end) end
            savedVisualEnabled[obj]=nil
        end
    end
end

local function setPlayerInvisible(enabled)
    states.PlayerInvisible=enabled==true
    local char=player.Character
    if invisibleDescendantConnection then
        invisibleDescendantConnection:Disconnect()
        invisibleDescendantConnection=nil
    end
    if not char then return end

    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then
        if states.PlayerInvisible then
            if savedHumanoidDisplay[hum]==nil then
                savedHumanoidDisplay[hum]=hum.DisplayDistanceType
            end
            pcall(function()
                hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
                hum.NameDisplayDistance=0
                hum.HealthDisplayDistance=0
            end)
        else
            local old=savedHumanoidDisplay[hum]
            if old~=nil then pcall(function() hum.DisplayDistanceType=old end) end
            savedHumanoidDisplay[hum]=nil
        end
    end

    for _,obj in ipairs(char:GetDescendants()) do
        applyLocalInvisibleToObject(obj,states.PlayerInvisible)
    end
    if states.PlayerInvisible then
        invisibleDescendantConnection=char.DescendantAdded:Connect(function(obj)
            if states.PlayerInvisible then applyLocalInvisibleToObject(obj,true) end
        end)
        -- Alguns scripts do jogo reescrevem Transparency durante animações/equipamentos.
        -- Reaplica a ocultação em intervalos curtos, sem fazer trabalho por frame.
        task.spawn(function()
            while states.PlayerInvisible and player.Character==char and char.Parent do
                for _,obj in ipairs(char:GetDescendants()) do
                    applyLocalInvisibleToObject(obj,true)
                end
                local currentHum=char:FindFirstChildOfClass("Humanoid")
                if currentHum then
                    pcall(function()
                        currentHum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
                        currentHum.NameDisplayDistance=0
                        currentHum.HealthDisplayDistance=0
                    end)
                end
                task.wait(0.3)
            end
        end)
    end
    if states.DataCollector then
        movementAndVisibilitySnapshot(states.PlayerInvisible and "LocalFullAvatarConcealmentEnabled" or "LocalFullAvatarConcealmentDisabled")
    end
end

local function getWorldVerticalHalfExtent(part)
    local cf=part.CFrame
    local size=part.Size
    return math.abs(cf.RightVector.Y)*size.X*0.5
        +math.abs(cf.UpVector.Y)*size.Y*0.5
        +math.abs(cf.LookVector.Y)*size.Z*0.5
end

local function isCharacterPart(part,localCharacter)
    local ancestor=part
    while ancestor and ancestor~=Workspace do
        if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then
            return true
        end
        ancestor=ancestor.Parent
    end
    return part:IsDescendantOf(localCharacter)
end

local function isDuctRelated(part)
    local current=part
    for _=1,12 do
        if not current or current==Workspace then break end
        if isDuctRoot(current) or contains(current.Name,{"ventinside","vententrance","ventcorner","duct","duto","airvent"}) then
            return true
        end
        current=current.Parent
    end
    return false
end

local function isWallLikeObstacle(part)
    local current=part
    for _=1,8 do
        if not current or current==Workspace then break end
        if contains(current.Name,{"wall","parede","wallpart","side wall"}) then
            return true
        end
        current=current.Parent
    end
    local size=part.Size
    local thinSide=math.min(size.X,size.Z)
    local longSide=math.max(size.X,size.Z)
    -- Filtra paredes genéricas sem bloquear móveis que tenham volume de subida.
    return size.Y>=5.5 and thinSide<=1.5 and longSide>=5.5
end

local function getObstacleContainer(part)
    local current=part.Parent
    while current and current~=Workspace do
        if current:IsA("Model") and not current:FindFirstChildOfClass("Humanoid")
            and not contains(current.Name,{"activemap","workspace","maproot"}) then
            return current
        end
        current=current.Parent
    end
    return part
end

local function setAutoJump(enabled)
    states.AutoJump=enabled==true
    autoJumpGeneration+=1
    local generation=autoJumpGeneration
    if not enabled then return end

    task.spawn(function()
        local rayParams=RaycastParams.new()
        rayParams.FilterType=Enum.RaycastFilterType.Exclude
        rayParams.IgnoreWater=true
        local topParams=RaycastParams.new()
        topParams.FilterType=Enum.RaycastFilterType.Include
        topParams.IgnoreWater=true

        -- JumpPower do jogo está replicado como 0 e JumpHeight como 2.
        -- Isso faz a V36 calcular alcance 0 e limitar o salto a um pulinho.
        -- A V38 calcula o impulso pela altura real do obstáculo, sem usar
        -- JumpPower=0 como se fosse a capacidade física máxima do personagem.
        local MAX_ASSIST_OBSTACLE_HEIGHT=14.5
        local MAX_ASSIST_VERTICAL_SPEED=82
        local MIN_ASSIST_VERTICAL_SPEED=38
        local lastObstacle=nil
        local sameObstacleAttempts=0

        while generation==autoJumpGeneration and gui and gui.Parent do
            local char=player.Character
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            local root=char and char:FindFirstChild("HumanoidRootPart")
            if char and hum and root and hum.Health>0 and not hum.Sit and not hum.PlatformStand then
                rayParams.FilterDescendantsInstances={char,espFolder}
                local move=hum.MoveDirection
                local velocity=root.AssemblyLinearVelocity
                local horizontalVelocity=Vector3.new(velocity.X,0,velocity.Z)
                local directionVector=Vector3.new(move.X,0,move.Z)

                -- Quando o jogador fica travado encostado no móvel, MoveDirection
                -- pode cair para zero. Nesse caso usa a velocidade e, por último,
                -- a direção frontal do personagem para continuar a assist\u00eancia.
                -- Não usa a direção do olhar quando o jogador está parado:
                -- isso causava pulos ao apenas encostar/raspar em paredes.
                if directionVector.Magnitude<0.12 and horizontalVelocity.Magnitude>1.35 then
                    directionVector=horizontalVelocity
                end

                local grounded=hum.FloorMaterial~=Enum.Material.Air
                    and math.abs(velocity.Y)<10
                local activelyMoving=directionVector.Magnitude>=0.12
                if activelyMoving then
                    local direction=directionVector.Unit
                    local footY=root.Position.Y-(hum.HipHeight+root.Size.Y*0.5)
                    -- Raios em várias alturas e dist\u00e2ncias; inclui a região baixa
                    -- para caixas e a região do tronco para armários/estantes.
                    local rayHeights={-1.75,-0.95,-0.15,0.55}
                    local rayDistances={3.8,5.8}
                    local bestHit=nil
                    for _,height in ipairs(rayHeights) do
                        for _,distance in ipairs(rayDistances) do
                            local origin=root.Position+Vector3.new(0,height,0)
                            local hit=Workspace:Raycast(origin,direction*distance,rayParams)
                            if hit and hit.Instance and hit.Instance:IsA("BasePart")
                                and hit.Instance.CanCollide
                                and not isCharacterPart(hit.Instance,char)
                                and not isDuctRelated(hit.Instance)
                                and not isWallLikeObstacle(hit.Instance)
                                and direction:Dot(hit.Normal)<-0.12 then
                                if not bestHit or hit.Distance<bestHit.Distance then
                                    bestHit=hit
                                end
                            end
                        end
                    end

                    if bestHit then
                        local obstacle=bestHit.Instance
                        local obstacleContainer=getObstacleContainer(obstacle)
                        -- Segurança adicional: se o raycast atingir qualquer peça do
                        -- conjunto do duto, não tenta saltar dentro da passagem.
                        if isDuctRelated(obstacleContainer) or isDuctRelated(obstacle) then
                            bestHit=nil
                        end
                        if bestHit then
                        topParams.FilterDescendantsInstances={obstacleContainer}
                        local boxCF,boxSize
                        if obstacleContainer:IsA("Model") then
                            local ok,cf,size=pcall(function() return obstacleContainer:GetBoundingBox() end)
                            if ok then boxCF,boxSize=cf,size end
                        end
                        local topY=nil
                        local fallbackTop=obstacle.Position.Y+getWorldVerticalHalfExtent(obstacle)
                        if boxCF and boxSize then
                            fallbackTop=boxCF.Position.Y+getWorldVerticalHalfExtent({CFrame=boxCF,Size=boxSize})
                        end
                        local topOrigin=Vector3.new(bestHit.Position.X,fallbackTop+10,bestHit.Position.Z)
                        local topHit=Workspace:Raycast(topOrigin,Vector3.new(0,-160,0),topParams)
                        if topHit then topY=topHit.Position.Y end
                        if not topY then topY=fallbackTop end

                        local obstacleHeight=topY-footY
                        local gravity=math.max(Workspace.Gravity,1)
                        local configuredJumpPower=tonumber(hum.JumpPower) or 0
                        local configuredJumpHeight=tonumber(hum.JumpHeight) or 0
                        local reportedJumpHeight=0
                        if configuredJumpPower>1 then
                            reportedJumpHeight=(configuredJumpPower*configuredJumpPower)/(2*gravity)
                        elseif configuredJumpHeight>0 then
                            reportedJumpHeight=configuredJumpHeight
                        end
                        -- O jogo informa JumpPower=0 em 844/844 amostras e
                        -- JumpHeight=2 na maioria. Esse número não representa
                        -- o impulso que o cliente consegue aplicar diretamente.
                        local heightValid=obstacleHeight>=0.35
                            and obstacleHeight<=MAX_ASSIST_OBSTACLE_HEIGHT
                        local horizontalSpeed=horizontalVelocity.Magnitude
                        local triggerDistance=math.clamp(3.0+horizontalSpeed*0.12,3.2,5.2)
                        local closeEnough=bestHit.Distance<=triggerDistance

                        -- Exige espaço acima e à frente do topo. Em dutos/locais baixos,
                        -- a verificação impede a IA de tentar um salto sem altura livre.
                        local clearanceOrigin=Vector3.new(bestHit.Position.X,topY+0.35,bestHit.Position.Z)
                        local forwardClearance=Workspace:Raycast(clearanceOrigin,direction*2.0,rayParams)
                        local overheadClearance=Workspace:Raycast(clearanceOrigin,Vector3.new(0,2.5,0),rayParams)
                        local forwardIsSameObject=forwardClearance==nil or forwardClearance.Instance==obstacle
                            if forwardClearance and obstacleContainer:IsA("Model") then
                                forwardIsSameObject=forwardClearance.Instance:IsDescendantOf(obstacleContainer)
                            end
                        local clearanceOK=forwardIsSameObject and overheadClearance==nil

                        local readyState=hum:GetState()
                        local canAttempt=readyState~=Enum.HumanoidStateType.Jumping
                            and readyState~=Enum.HumanoidStateType.Freefall
                        local retryAvailable=(obstacleContainer~=lastObstacle or sameObstacleAttempts<3)
                        local shouldJump=heightValid and closeEnough and clearanceOK
                            and grounded and activelyMoving and canAttempt and retryAvailable
                            and os.clock()-lastAutoJumpAt>=0.72

                        -- Energia vertical necessária para ultrapassar o topo com
                        -- margem. A V36 usava JumpPower=0 como limite inferior e
                        -- acabava aplicando somente ~32 studs/s (salto de ~2,7 studs).
                        local requiredVelocity=0
                        if heightValid then
                            requiredVelocity=math.sqrt(2*gravity*(obstacleHeight+1.15))
                            requiredVelocity=math.clamp(requiredVelocity,
                                MIN_ASSIST_VERTICAL_SPEED,MAX_ASSIST_VERTICAL_SPEED)
                        end

                        if shouldJump then
                            lastAutoJumpAt=os.clock()
                            if obstacleContainer==lastObstacle then
                                sameObstacleAttempts+=1
                            else
                                lastObstacle=obstacleContainer
                                sameObstacleAttempts=1
                            end
                            -- Preserva X/Z exatamente como estão: evita o impulso
                            -- horizontal que fazia o avatar ser jogado para trás.
                            pcall(function()
                                hum.Jump=true
                                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                                local current=root.AssemblyLinearVelocity
                                root.AssemblyLinearVelocity=Vector3.new(
                                    current.X,math.max(current.Y,requiredVelocity),current.Z)
                            end)
                        elseif bestHit.Distance>triggerDistance+1.0 or obstacleContainer~=lastObstacle then
                            lastObstacle=nil
                            sameObstacleAttempts=0
                        end

                        if states.DataCollector and (shouldJump or os.clock()-lastMovementReportAt>=0.9) then
                            queueReport({Event="MovementObstacleSnapshot",Assistant="Assistente IA V39",
                                ObstacleName=obstacle.Name,ObstacleClass=obstacle.ClassName,
                                ObstaclePath=safePath(obstacle),ObstaclePosition=tostring(bestHit.Position),
                                ObstacleDistance=bestHit.Distance,ObstacleHeight=obstacleHeight,
                                TriggerDistance=triggerDistance,EstimatedJumpVelocity=requiredVelocity,
                                EstimatedTopReachable=heightValid,HeadClearance=clearanceOK,
                                JumpTriggered=shouldJump,HumanoidState=tostring(hum:GetState()),
                                MoveDirection=tostring(move),HorizontalSpeed=horizontalSpeed,
                                AvailableJumpHeight=reportedJumpHeight,
                                ConfiguredJumpPower=configuredJumpPower,
                                ConfiguredJumpHeight=configuredJumpHeight,
                                RetryCount=sameObstacleAttempts,
                                MaxAssistObstacleHeight=MAX_ASSIST_OBSTACLE_HEIGHT,
                                CapturedAt=os.date("!%Y-%m-%dT%H:%M:%SZ")},
                                "MovementObstacleSnapshotV39|"..safePath(obstacle).."|"..tostring(math.floor(os.clock()*2)))
                            lastMovementReportAt=os.clock()
                        end
                        end -- bestHit válido após filtros de duto
                    else
                        lastObstacle=nil
                        sameObstacleAttempts=0
                    end
                end
            end

            if states.DataCollector and os.clock()-lastMovementReportAt>=5 then
                lastMovementReportAt=os.clock()
                movementAndVisibilitySnapshot("MovementPeriodicV39")
            end
            task.wait(0.055)
        end
    end)
end

player.CharacterAdded:Connect(function(char)
    if invisibleDescendantConnection then
        invisibleDescendantConnection:Disconnect()
        invisibleDescendantConnection=nil
    end
    task.wait(0.5)
    if states.PlayerInvisible then setPlayerInvisible(true) end
    if states.DataCollector then movementAndVisibilitySnapshot("CharacterRespawned") end
end)

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
-- ASSISTENTE IA | CONTROLADOR CENTRAL
--==============================================================

local function setAssistant(enabled)
    states.AssistantIA=enabled==true
    if states.AssistantIA then
        states.DataCollector=true
        if toggleDrawers.DataCollector then toggleDrawers.DataCollector(true) end
        statusLabel.Text="Assistente IA ativa: iniciando observação e assistência de movimento..."
        setAutoJump(true)
        if toggleDrawers.AutoJump then toggleDrawers.AutoJump(true) end
        for _,plr in ipairs(Players:GetPlayers()) do
            if roleSnapshot then roleSnapshot(plr,"AssistantIAStarted") end
        end
        watchFlashRoot(Lighting)
        watchFlashRoot(PlayerGui)
        watchFlashRoot(player.Character)
        watchFlashRoot(Workspace.CurrentCamera)
        discoverExistingEntities()
        setAntiFlash(true)
        if toggleDrawers.AntiFlash then toggleDrawers.AntiFlash(true) end
        inspectFlashRoot(Lighting)
        inspectFlashRoot(PlayerGui)
        inspectFlashRoot(player.Character)
        inspectFlashRoot(Workspace.CurrentCamera)
        if assistantTargetedScan then assistantTargetedScan("AssistantIAStarted") end
        flushReports()
        statusLabel.Text="Assistente IA ativa | Coleta seletiva e assistência de movimento ligadas | Módulos liberados"
    else
        -- Desliga os módulos dependentes e restaura o que foi alterado localmente.
        states.DataCollector=false
        if toggleDrawers.DataCollector then toggleDrawers.DataCollector(false) end
        for rarity in pairs(rarityEnabled) do
            rarityEnabled[rarity]=false
            local draw=toggleDrawers["rarity:"..rarity]
            if draw then draw(false) end
        end
        states.ESPPlayers=false; states.ESPMonsters=false; states.ESPDucts=false
        states.RemoveDoors=false; states.InstantCollection=false; states.Brightness=false
        states.AntiFlash=false; states.AutoFarm=false; states.InfiniteStamina=false
        states.AutoJump=false; states.PlayerInvisible=false
        if toggleDrawers.ESPPlayers then toggleDrawers.ESPPlayers(false) end
        if toggleDrawers.ESPMonsters then toggleDrawers.ESPMonsters(false) end
        if toggleDrawers.ESPDucts then toggleDrawers.ESPDucts(false) end
        if toggleDrawers.RemoveDoors then toggleDrawers.RemoveDoors(false) end
        if toggleDrawers.InstantCollection then toggleDrawers.InstantCollection(false) end
        if toggleDrawers.Brightness then toggleDrawers.Brightness(false) end
        if toggleDrawers.AntiFlash then toggleDrawers.AntiFlash(false) end
        if toggleDrawers.AutoFarm then toggleDrawers.AutoFarm(false) end
        if toggleDrawers.InfiniteStamina then toggleDrawers.InfiniteStamina(false) end
        if toggleDrawers.AutoJump then toggleDrawers.AutoJump(false) end
        if toggleDrawers.PlayerInvisible then toggleDrawers.PlayerInvisible(false) end
        setESP("ESPPlayers",false); setESP("ESPMonsters",false); setESP("ESPDucts",false)
        setDoors(false); setInstant(false); setAntiFlash(false); setBrightness(false)
        setAutoFarm(false); setInfiniteStamina(false); setAutoJump(false); setPlayerInvisible(false)
        clearESP()
        statusLabel.Text="Assistente IA desligada | Todos os módulos subordinados foram bloqueados e desligados"
        showPage("Principal")
    end
end

--==============================================================
-- INTERFACE
--==============================================================

gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV40"
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
header.Name = "Header"
header.Size = UDim2.new(1,0,0,48)
header.BackgroundColor3 = Color3.fromRGB(105,15,25)
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner",header).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-95,1,0)
title.Position = UDim2.fromOffset(16,0)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA V40  |  Feito por Tales"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Name = "Minimize"
minimize.Size = UDim2.fromOffset(38,34)
minimize.Position = UDim2.new(1,-44,0,7)
minimize.Text = "-"
minimize.TextSize = 22
minimize.Font = Enum.Font.GothamBold
minimize.TextColor3 = Color3.new(1,1,1)
minimize.BackgroundColor3 = Color3.fromRGB(65,12,20)
minimize.Parent = header
Instance.new("UICorner",minimize).CornerRadius = UDim.new(0,7)

local restore = Instance.new("TextButton")
restore.Name = "Restore"
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
    if name~="Principal" and not states.AssistantIA then
        name="Principal"
        if statusLabel then statusLabel.Text="Ative a Assistente IA na página Principal para liberar os módulos." end
    end
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

local function addButton(page,textValue,callback,allowWithoutAssistant)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-6,0,34)
    b.BackgroundColor3 = Color3.fromRGB(43,43,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = textValue
    b.TextSize = 12
    b.Font = Enum.Font.Gotham
    b.Parent = page
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function()
        if not states.AssistantIA and not allowWithoutAssistant then
            if statusLabel then statusLabel.Text="Assistente IA desligada: módulo bloqueado." end
            return
        end
        if callback then callback() end
    end)
    return b
end

local function addToggle(page,name,key,callback,targetTable,allowWithoutAssistant)
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
    toggleDrawers[targetTable==states and key or ("rarity:"..key)]=draw

    b.MouseButton1Click:Connect(function()
        if not states.AssistantIA and not allowWithoutAssistant then
            if statusLabel then statusLabel.Text="Assistente IA desligada: ative-a na página Principal." end
            return
        end
        local nextState = not targetTable[key]
        targetTable[key] = nextState
        draw(nextState)

        if callback then
            local ok,err = pcall(callback,nextState)
            if not ok then
                warn("[V29] "..name..": "..tostring(err))
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
        if name~="Principal" and not states.AssistantIA then
            if statusLabel then statusLabel.Text="Ative a Assistente IA para liberar as categorias." end
            showPage("Principal")
            return
        end
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

-- PRINCIPAL: a Assistente IA é a única opção desta página.
addSection(pMain,"CENTRAL DE CONTROLE | ASSISTENTE IA")
addToggle(pMain,"Assistente IA","AssistantIA",function(v)
    setAssistant(v)
end,states,true)
local assistantInfo=Instance.new("TextLabel")
assistantInfo.Size=UDim2.new(1,-8,0,48)
assistantInfo.BackgroundTransparency=1
assistantInfo.TextColor3=Color3.fromRGB(215,215,225)
assistantInfo.TextWrapped=true
assistantInfo.TextYAlignment=Enum.TextYAlignment.Top
assistantInfo.Font=Enum.Font.Gotham
assistantInfo.TextSize=12
assistantInfo.Text="Coordena a coleta seletiva, o pulo assistido e a análise de stamina, movimento e visibilidade."
assistantInfo.Parent=pMain

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
addToggle(pEnv,"Pulo automático","AutoJump",setAutoJump)
addToggle(pEnv,"Ocultar personagem (visual local)","PlayerInvisible",setPlayerInvisible)
local invisibleInfo=Instance.new("TextLabel")
invisibleInfo.Size=UDim2.new(1,-8,0,44)
invisibleInfo.BackgroundTransparency=1
invisibleInfo.TextColor3=Color3.fromRGB(220,190,150)
invisibleInfo.TextWrapped=true
invisibleInfo.TextYAlignment=Enum.TextYAlignment.Top
invisibleInfo.Font=Enum.Font.Gotham
invisibleInfo.TextSize=11
invisibleInfo.Text="Oculta o avatar somente na sua tela. Não altera a detecção dos monstros no servidor; isso exige suporte do código do jogo."
invisibleInfo.Parent=pEnv

-- COLETA
addSection(pCollect,"COLETA")
addToggle(pCollect,"Coleta Instantânea","InstantCollection",setInstant)
addToggle(pCollect,"Auto Farm (prompts no alcance)","AutoFarm",setAutoFarm)
addToggle(pCollect,"Estamina Infinita","InfiniteStamina",setInfiniteStamina)

-- DADOS
addSection(pData,"COLETOR AUTOMÁTICO DA PARTIDA")
addButton(pData,"V40: filtro de dutos no piso, raridades ampliadas e diagnóstico honesto",function()
    statusLabel.Text = "Cliente: coleta somente dados replicados/visíveis; valores do servidor não são acessíveis."
end)

addToggle(pData,"Coletor automático durante a partida","DataCollector",function(enabled)
    if states.AssistantIA and not enabled then
        states.DataCollector=true
        if toggleDrawers.DataCollector then toggleDrawers.DataCollector(true) end
        statusLabel.Text="A coleta prioritária é coordenada pela Assistente IA e permanece ativa enquanto ela estiver ligada."
        return
    end
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
        statusLabel.Text = "Coleta automática pausada"
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
reportBox.PlaceholderText = "O relatório completo aparecerá aqui..."
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

addButton(pData,"GERAR E COPIAR RELATÓRIO INTEIRO",copyFullReport)

addButton(pData,"ATUALIZAR E ENVIAR AGORA",function()
    statusLabel.Text = "Atualizando dados..."
    local a = scanGame()
    flushReports()

    statusLabel.Text =
        "Varredura concluída | Novos: "..a
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
    lastDataScan = 0

    reportBox.Text = ""
    statusLabel.Text = "Relatório local limpo"
end)

-- CONFIGURAÇÕES
addSection(pConfig,"CONFIGURAÇÕES EXTRAS | MODO STREAMER")
local streamerInfo=Instance.new("TextLabel")
streamerInfo.Size=UDim2.new(1,-8,0,82)
streamerInfo.BackgroundTransparency=1
streamerInfo.TextColor3=Color3.fromRGB(220,190,150)
streamerInfo.TextWrapped=true
streamerInfo.TextYAlignment=Enum.TextYAlignment.Top
streamerInfo.Font=Enum.Font.Gotham
streamerInfo.TextSize=11
streamerInfo.Text="O Roblox não oferece a este script um controle confiável para excluir seletivamente painel e ESP da gravação/espelhamento enquanto você continua vendo tudo. Ocultar localmente também esconderia de você. Por isso, esta versão não simula uma proteção que não consegue garantir."
streamerInfo.Parent=pConfig
addButton(pConfig,"VER LIMITAÇÃO DO MODO STREAMER",function()
    statusLabel.Text="Modo Streamer: ocultação seletiva na captura não é suportada de forma confiável por um script cliente."
    showPage("Configurações")
end)

addSection(pConfig,"DIAGNÓSTICO E CONFIGURAÇÕES")

addButton(pConfig,"VERIFICAR CAMINHOS DE STAMINA",function()
    local found = findStaminaObjects()

    local lines = {
        "DIAGNÓSTICO DE STAMINA V40",
        "HUD observado: PlayerGui.StaminaHUD (amostragem dos elementos internos)",
        "Resistência e Stamina são tratadas separadamente; a barra visual não prova o valor real.",
        "A coleta agora registra até 24 elementos da HUD para distinguir as duas barras.",
        "Valores controlados pelo servidor não podem ser garantidos por alteração local.",
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
        local detail=obj:GetFullName().." ["..obj.ClassName.."]"
        if obj:IsA("ValueBase") then
            local ok,value=pcall(function() return obj.Value end)
            if ok then detail=detail.." = "..tostring(value) end
        end
        table.insert(lines,detail)
        local attrs=obj:GetAttributes()
        for key,value in pairs(attrs) do
            if isStaminaName(key) or key=="UpgradeStamina" or key=="UpgradeSprint" or key=="Skills" then
                table.insert(lines,"  atributo "..key.." = "..tostring(value))
            end
        end
    end

    -- Mostra também valores numéricos locais que podem ter nomes não óbvios,
    -- sem alterar nenhum deles. Isso ajuda a descobrir qual acompanha a HUD.
    local roots={player,player.Character,player:FindFirstChild("PlayerScripts"),player:FindFirstChild("Backpack"),PlayerGui}
    local listed={}
    for _,root in ipairs(roots) do
        if root then
            for _,obj in ipairs(root:GetDescendants()) do
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    if not listed[obj] then
                        listed[obj]=true
                        local line=obj:GetFullName().." = "..tostring(obj.Value)
                        if isStaminaName(obj.Name) then
                            table.insert(lines,"CANDIDATO NUMÉRICO: "..line)
                        end
                    end
                end
            end
        end
    end
    table.insert(lines,"")
    table.insert(lines,"HoldEndStamina é observado, mas não é alterado: ainda não foi confirmado como estamina atual.")
    table.insert(lines,"A barra HUD é somente visual; não prova o valor de stamina usado pelo servidor.")
    table.insert(lines,"Teste automático de jogo: NÃO EXECUTADO (o script precisa ser testado dentro da partida).")
    table.insert(lines,"Stamina infinita real: NÃO CONFIRMADA; valores locais não garantem alteração do estado no servidor.")

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
end,true)

-- Padronização tipográfica: evita mistura de fontes, RichText inesperado e cortes
-- inconsistentes nos rótulos/controles, inclusive no botão de minimizar.
for _,uiObject in ipairs(gui:GetDescendants()) do
    if uiObject:IsA("TextLabel") or uiObject:IsA("TextButton") or uiObject:IsA("TextBox") then
        pcall(function()
            uiObject.RichText = false
            uiObject.TextScaled = false
            if uiObject:IsA("TextBox") and uiObject==reportBox then
                uiObject.Font = Enum.Font.Code
                uiObject.TextWrapped = true
                uiObject.TextYAlignment = Enum.TextYAlignment.Top
            else
                if uiObject.Name=="TextLabel" and uiObject.Parent and uiObject.Parent.Name=="Header" then
                    uiObject.Font = Enum.Font.GothamBold
                elseif uiObject:IsA("TextButton") and (uiObject.Parent==sidebar or uiObject.Name=="Minimize" or uiObject.Name=="Restore") then
                    uiObject.Font = Enum.Font.GothamBold
                else
                    uiObject.Font = Enum.Font.Gotham
                end
                if uiObject:IsA("TextButton") then
                    uiObject.TextWrapped = false
                    uiObject.TextTruncate = Enum.TextTruncate.AtEnd
                elseif uiObject:IsA("TextLabel") then
                    uiObject.TextWrapped = false
                    uiObject.TextTruncate = Enum.TextTruncate.AtEnd
                end
            end
        end)
    end
end

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
-- ATUALIZAÇÃO OTIMIZADA
--==============================================================

task.spawn(function()
    local lastDoor = 0
    local lastStamina = 0
    local lastMovement = 0

    while gui and gui.Parent do
        local now = os.clock()

        -- ESP é atualizado por ativação, troca de personagem e novos objetos.
        -- Não existe mais varredura periódica do mapa inteiro.

        if states.RemoveDoors and now-lastDoor>=1.0 then
            refreshDoorCollision()
            lastDoor = now
        end

        if states.InfiniteStamina and now-lastStamina>=2 then
            findStaminaObjects()
            lastStamina = now
        end
        if states.DataCollector and now-lastMovement>=8 then
            movementAndVisibilitySnapshot("PeriodicFocusedObservation")
            lastMovement = now
        end

        -- Anti-Flash é orientado a eventos: evita varrer toda a interface a cada 0,5s.

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
    setAntiFlash(false)
    setBrightness(false)
    setInfiniteStamina(false)
    setAutoJump(false)
    setPlayerInvisible(false)
    clearESP()

    for obj,bill in pairs(labels) do
        if bill then bill:Destroy() end
        labels[obj] = nil
    end
end)
