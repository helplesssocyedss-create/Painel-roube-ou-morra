
--========================================================
-- ROUBE OU MORRA V12
-- Feito por Tales
-- CORRECOES: MONSTROS E PORTAS/ESCOTILHAS
-- INSERIR ANTES DE: -- INTERFACE
--========================================================

-- IDENTIFICACAO DE MONSTROS

local function hasMonsterSignal(model)
    if not model or not model:IsA("Model") then
        return false
    end

    if contains(model.Name, monsterNames) then
        return true
    end

    local attributes = {
        "IsMonster", "Monster", "IsEnemy",
        "Enemy", "EntityType", "NPCType",
        "Role", "CharacterType"
    }

    for _, attribute in ipairs(attributes) do
        local value = model:GetAttribute(attribute)

        if value == true then
            return true
        end

        if type(value) == "string"
            and contains(value, {
                "monster", "enemy", "entity",
                "monstro", "inimigo", "creature"
            }) then
            return true
        end
    end

    -- Procura sinais nos objetos internos.
    local checked = 0

    for _, child in ipairs(model:GetDescendants()) do
        checked += 1
        if checked > 100 then break end

        if contains(child.Name, {
            "monster", "monstro", "enemy",
            "inimigo", "creature"
        }) then
            return true
        end

        for _, attribute in ipairs(attributes) do
            local value = child:GetAttribute(attribute)

            if value == true then
                return true
            end

            if type(value) == "string"
                and contains(value, {
                    "monster", "enemy", "monstro",
                    "inimigo", "creature"
                }) then
                return true
            end
        end
    end

    return false
end

isMonster = function(obj)
    return hasMonsterSignal(obj)
end

-- ESP: MONSTRO TEM PRIORIDADE SOBRE PLAYER

refreshESP = function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            if isMonster(obj) and states.ESPMonsters then
                createESP(
                    obj,
                    Color3.fromRGB(255, 35, 35),
                    obj.Name .. " [MONSTRO]"
                )

            else
                local p = getPlayerFromModel(obj)

                if p and p ~= player and states.ESPPlayers then
                    createESP(
                        obj,
                        Color3.fromRGB(40, 140, 255),
                        p.Name
                    )
                end
            end

            if states.ESPDucts and contains(obj.Name, {
                "duct", "duto", "vent"
            }) then
                createESP(
                    obj,
                    Color3.fromRGB(255, 170, 40),
                    obj.Name .. " [DUTO]"
                )
            end
        end

        -- Preserva ESP de raridades.
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if not isMonster(obj) then
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
    end

    for obj in pairs(highlights) do
        local p = getPlayerFromModel(obj)
        local monster = isMonster(obj)
        local rarity = getRarity(obj)

        local isDuct = states.ESPDucts
            and contains(obj.Name, {"duct", "duto", "vent"})

        local keep =
            (monster and states.ESPMonsters)
            or (not monster and p and p ~= player
                and states.ESPPlayers)
            or (not monster and rarity
                and rarityEnabled[rarity])
            or isDuct

        if not keep then
            removeESP(obj)
        end
    end
end

-- PORTAS E ESCOTILHA DO DUTO

local function hasDuctAncestor(obj)
    local current = obj.Parent
    local depth = 0

    while current and depth < 7 do
        if contains(current.Name, {
            "duct", "duto", "vent"
        }) then
            return true
        end

        current = current.Parent
        depth += 1
    end

    return false
end

local function isDoorContainer(obj)
    if not obj then return false end

    if contains(obj.Name, {
        "door", "porta"
    }) then
        return true
    end

    -- A tampa deve estar dentro de um duto.
    if hasDuctAncestor(obj) and contains(obj.Name, {
        "hatch", "cover", "lid",
        "tampa", "escotilha",
        "ventdoor", "ductdoor",
        "door", "porta", "panel"
    }) then
        return true
    end

    return false
end

local function hideDoorContainer(obj)
    if not obj then return end

    if obj:IsA("BasePart") then
        hidePart(obj)
        return
    end

    for _, part in ipairs(obj:GetDescendants()) do
        if part:IsA("BasePart") then
            hidePart(part)
        end
    end
end

local function restoreHiddenParts()
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

setDoors = function(enabled)
    states.RemoveDoors = enabled

    if not enabled then
        restoreHiddenParts()
        return
    end

    -- Primeiro procura portas e escotilhas específicas.
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if isDoorContainer(obj) then
                hideDoorContainer(obj)
            end
        end
    end
end

-- Acompanha novas peças replicadas.

Workspace.DescendantAdded:Connect(function(obj)
    if not states.RemoveDoors then return end

    task.defer(function()
        if not obj or not obj.Parent then return end

        local current = obj
        local depth = 0

        while current and depth < 8 do
            if isDoorContainer(current) then
                hideDoorContainer(current)
                return
            end

            current = current.Parent
            depth += 1
        end
    end)
end)

print("ROUBE OU MORRA V12 - CORRECOES CARREGADAS")
print("Feito por Tales")
