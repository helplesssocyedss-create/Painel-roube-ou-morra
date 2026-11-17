
--========================================================
-- ROUBE OU MORRA V11 - PATCH DE CORRECOES
-- Feito por Tales
-- COLE ESTE BLOCO NO FINAL DA V10
--========================================================

-- IDENTIFICACAO AMPLIADA DE MONSTROS

isMonster = function(obj)
    if not obj or not obj:IsA("Model") then
        return false
    end

    if getPlayerFromModel(obj) then
        return false
    end

    if contains(obj.Name, monsterNames) then
        return true
    end

    local humanoid = obj:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return true
    end

    for _, attribute in ipairs({
        "IsMonster", "Monster", "IsEnemy",
        "Enemy", "EntityType", "NPCType"
    }) do
        local value = obj:GetAttribute(attribute)

        if value == true then
            return true
        end

        if type(value) == "string"
            and contains(value, {"monster", "enemy", "entity", "monstro"}) then
            return true
        end
    end

    return false
end

-- RARIDADE: PROCURA NO OBJETO E NO MODELO PAI

local function getAttributeFromParents(obj, names)
    local current = obj
    local depth = 0

    while current and depth < 6 do
        for _, name in ipairs(names) do
            local value = current:GetAttribute(name)
            if value ~= nil then
                return value
            end
        end

        current = current.Parent
        depth += 1
    end

    return nil
end

getRarity = function(obj)
    if not obj or isMonster(obj) then
        return nil
    end

    local value = lower(getAttributeFromParents(obj, {
        "Rarity", "Raridade", "ItemRarity",
        "ItemRaridade", "Tier", "RarityName"
    }))

    value = value:gsub("á", "a")
        :gsub("ã", "a")
        :gsub("é", "e")
        :gsub("í", "i")
        :gsub("ó", "o")

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

-- INFORMACOES DOS ITENS

local function getItemInfo(obj)
    local price = getAttributeFromParents(obj, {
        "Price", "Preco", "Preço", "Value",
        "Valor", "SellValue", "ItemValue"
    })

    local weight = getAttributeFromParents(obj, {
        "Weight", "Peso", "Kg", "Kilos",
        "Quilos", "Mass", "ItemWeight"
    })

    return price, weight
end

local function isItemObject(obj)
    if not obj then return false end
    if isMonster(obj) then return false end

    if getRarity(obj) then
        return true
    end

    return contains(obj.Name, knownItems)
end

-- ESP COM NOME, RARIDADE, PRECO E PESO

createESP = function(obj, color, labelText)
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
        h.Parent = playerGui
        highlights[obj] = h
    else
        highlights[obj].FillColor = color
        highlights[obj].OutlineColor = color
    end

    if states.ESPNames then
        local part = obj:IsA("Model")
            and (obj:FindFirstChild("Head")
            or obj:FindFirstChildWhichIsA("BasePart"))
            or obj

        if part and part:IsA("BasePart") then
            if not tags[obj] then
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "TalesName"
                billboard.Adornee = part
                billboard.Size = UDim2.fromOffset(220, 48)
                billboard.StudsOffset = Vector3.new(0, 3, 0)
                billboard.AlwaysOnTop = true

                local label = Instance.new("TextLabel")
                label.Name = "Label"
                label.Size = UDim2.fromScale(1, 1)
                label.BackgroundTransparency = 1
                label.TextColor3 = color
                label.TextStrokeTransparency = 0
                label.TextScaled = true
                label.TextWrapped = true
                label.Font = Enum.Font.GothamBold
                label.Parent = billboard

                billboard.Parent = playerGui
                tags[obj] = billboard
            end

            local label = tags[obj]:FindFirstChild("Label")
            if label then
                label.Text = labelText or obj.Name
                label.TextColor3 = color
            end
        end
    elseif tags[obj] then
        tags[obj]:Destroy()
        tags[obj] = nil
    end
end

-- ATUALIZACAO DAS ESPs

refreshESP = function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local p = getPlayerFromModel(obj)

            if p and p ~= player and states.ESPPlayers then
                createESP(obj, Color3.fromRGB(40,140,255), p.Name)

            elseif isMonster(obj) and states.ESPMonsters then
                createESP(obj, Color3.fromRGB(255,45,45),
                    obj.Name .. " [MONSTRO]")

            elseif states.ESPDucts and contains(obj.Name, {
                "duct", "duto", "vent"
            }) then
                createESP(obj, Color3.fromRGB(255,170,40),
                    obj.Name .. " [DUTO]")
            end
        end

        if obj:IsA("Model") or obj:IsA("BasePart") then
            local rarity = getRarity(obj)

            -- Evita marcar cada peca interna de um modelo.
            local parentModel = obj:IsA("BasePart")
                and obj:FindFirstAncestorOfClass("Model")

            if rarity and rarityEnabled[rarity]
                and not parentModel then

                local price, weight = getItemInfo(obj)
                local label = obj.Name .. " [" .. rarity .. "]"

                if price ~= nil then
                    label ..= " | Valor: " .. tostring(price)
                end

                if weight ~= nil then
                    label ..= " | Peso: " .. tostring(weight)
                end

                createESP(obj, rarityColors[rarity], label)
            end
        end
    end

    for obj in pairs(highlights) do
        local p = obj and getPlayerFromModel(obj)
        local monster = obj and isMonster(obj)
        local rarity = obj and getRarity(obj)

        local keep =
            (p and p ~= player and states.ESPPlayers)
            or (monster and states.ESPMonsters)
            or (rarity and rarityEnabled[rarity])
            or (states.ESPDucts and obj
                and contains(obj.Name, {"duct", "duto", "vent"}))

        if not keep then
            removeESP(obj)
        end
    end
end

-- PORTAS E DUTOS: PERCORRE MODELOS E PECAS INTERNAS

local function matchesDoorOrDuct(obj)
    return obj and contains(obj.Name, {
        "door", "porta", "duct", "duto", "vent"
    })
end

local function hideContainer(obj)
    if not obj then return end

    if obj:IsA("BasePart") then
        hidePart(obj)
        return
    end

    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") then
            hidePart(child)
        end
    end
end

setDoors = function(enabled)
    states.RemoveDoors = enabled

    if enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if matchesDoorOrDuct(obj) then
                hideContainer(obj)
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

-- NOVAS PECAS DENTRO DE PORTAS E DUTOS

Workspace.DescendantAdded:Connect(function(obj)
    if not states.RemoveDoors then return end

    task.defer(function()
        if not obj or not obj.Parent then return end

        if obj:IsA("BasePart") then
            local current = obj
            local depth = 0

            while current and depth < 8 do
                if matchesDoorOrDuct(current) then
                    hidePart(obj)
                    break
                end

                current = current.Parent
                depth += 1
            end
        elseif matchesDoorOrDuct(obj) then
            hideContainer(obj)
        end
    end)
end)

-- COLETOR: MONSTROS E ITENS COM CLASSIFICACAO MELHORADA

scanObject = function(obj, eventName)
    if not obj then return end

    local ok, path = pcall(function()
        return obj:GetFullName()
    end)

    if not ok then return end

    local category = "Objeto"

    if isMonster(obj) then
        category = "Monstro"
    elseif obj:IsA("ProximityPrompt") then
        category = "Interacao"
    elseif isItemObject(obj) then
        category = "Item"
    elseif obj:IsA("Model") then
        category = "Modelo"
    elseif obj:IsA("BasePart") then
        category = "Peca"
    end

    local price, weight = getItemInfo(obj)

    local data = {
        Name = obj.Name,
        Class = obj.ClassName,
        Path = path,
        Event = eventName or "Detectado",
        Attributes = getAttributes(obj),
        Rarity = tostring(getRarity(obj) or "Nao detectada"),
        Price = tostring(price or "Nao detectado"),
        Weight = tostring(weight or "Nao detectado")
    }

    if obj:IsA("ProximityPrompt") then
        data.ActionText = obj.ActionText
        data.ObjectText = obj.ObjectText
        data.HoldDuration = obj.HoldDuration
        data.MaxDistance = obj.MaxActivationDistance
        data.Enabled = obj.Enabled
    end

    if obj:IsA("BasePart") then
        data.Position = tostring(obj.Position)
    end

    addRecord(category, data)
end

-- RELATORIO REAL NA CAIXA DE TEXTO

exportData = function()
    local output = {
        "====================================",
        "ROUBE OU MORRA V11 - RELATORIO",
        "Feito por Tales",
        "Data: " .. os.date("%d/%m/%Y %H:%M:%S"),
        "Varreduras: " .. tostring(totalScans),
        "Registros: " .. tostring(#records),
        "===================================="
    }

    local counts = {
        Monstro = 0,
        Item = 0,
        Interacao = 0
    }

    for _, data in ipairs(records) do
        if counts[data.Category] ~= nil then
            counts[data.Category] += 1
        end
    end

    table.insert(output, "MONSTROS REGISTRADOS: " .. counts.Monstro)
    table.insert(output, "ITENS REGISTRADOS: " .. counts.Item)
    table.insert(output, "INTERACOES: " .. counts.Interacao)

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
                table.insert(output,
                    key .. ": " .. tostring(value))
            end
        end
    end

    return table.concat(output, "\n")
end

copyData = function()
    local report = exportData()

    if dataBox then
        dataBox.Text = report
    end

    local clipboard = setclipboard or toclipboard

    if clipboard then
        local ok = pcall(clipboard, report)
        if ok then
            return true
        end
    end

    return false
end

print("ROUBE OU MORRA V11 - PATCH ATIVO")
print("Feito por Tales")
