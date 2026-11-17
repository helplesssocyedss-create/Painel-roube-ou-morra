
-- =========================================
-- FUNCOES EXTRAS V4
-- =========================================

local CollectionService = game:GetService("CollectionService")
local farmRunning = false
local staminaRunning = false

-- NOMES PARA IDENTIFICACAO
local function containsName(name, words)
    name = string.lower(name or "")

    for _, word in ipairs(words) do
        if string.find(name, word, 1, true) then
            return true
        end
    end

    return false
end

-- =========================================
-- 1. STAMINA INFINITA
-- =========================================

local function findStaminaValues()
    local results = {}

    for _, obj in ipairs(player:GetDescendants()) do
        if (obj:IsA("NumberValue") or obj:IsA("IntValue"))
        and containsName(obj.Name, {
            "stamina", "energy", "energia", "fôlego", "folego"
        }) then
            table.insert(results, obj)
        end
    end

    return results
end

local function infiniteStamina(enabled)
    staminaRunning = enabled

    if not enabled then return end

    task.spawn(function()
        while staminaRunning do
            for _, value in ipairs(findStaminaValues()) do
                if value.Parent then
                    local maximum =
                        value:GetAttribute("MaxValue")
                        or value:GetAttribute("MaxStamina")

                    if maximum then
                        value.Value = maximum
                    end
                end
            end

            task.wait(0.15)
        end
    end)
end

-- =========================================
-- 2. REMOVER PORTAS E DUTOS
-- =========================================

local hiddenParts = {}

local doorWords = {
    "porta", "door", "duto", "vent",
    "duct", "hatch"
}

local function removeDoors(enabled)
    if enabled then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart")
            and containsName(obj.Name, doorWords) then

                if not hiddenParts[obj] then
                    hiddenParts[obj] = {
                        Transparency = obj.LocalTransparencyModifier,
                        CanCollide = obj.CanCollide
                    }
                end

                obj.LocalTransparencyModifier = 1
                obj.CanCollide = false
            end
        end
    else
        for obj, original in pairs(hiddenParts) do
            if obj.Parent then
                obj.LocalTransparencyModifier =
                    original.Transparency

                obj.CanCollide = original.CanCollide
            end

            hiddenParts[obj] = nil
        end
    end
end

-- =========================================
-- 3. COLETA INSTANTANEA
-- =========================================

local originalPrompts = {}

local function instantCollection(enabled)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then

            if enabled then
                if not originalPrompts[obj] then
                    originalPrompts[obj] = obj.HoldDuration
                end

                obj.HoldDuration = 0
            else
                if originalPrompts[obj] ~= nil then
                    obj.HoldDuration = originalPrompts[obj]
                    originalPrompts[obj] = nil
                end
            end
        end
    end
end

-- =========================================
-- 4. AUTO FARM
-- =========================================

local collectingWords = {
    "coletar", "coleta", "pegar",
    "collect", "pickup", "pick up",
    "item", "resource", "recurso"
}

local function getPromptPosition(prompt)
    local parent = prompt.Parent

    if not parent then return nil end

    if parent:IsA("Attachment") then
        return parent.WorldPosition
    end

    if parent:IsA("BasePart") then
        return parent.Position
    end

    local part = parent:FindFirstChildWhichIsA(
        "BasePart", true
    )

    return part and part.Position
end

local function autoFarm(enabled)
    farmRunning = enabled

    if not enabled then return end

    task.spawn(function()
        while farmRunning do
            local character = player.Character
            local root = character and
                character:FindFirstChild("HumanoidRootPart")

            if root then
                for _, prompt in ipairs(
                    workspace:GetDescendants()
                ) do
                    if not farmRunning then break end

                    if prompt:IsA("ProximityPrompt")
                    and prompt.Enabled
                    and containsName(
                        prompt.ActionText .. " " ..
                        prompt.ObjectText,
                        collectingWords
                    ) then

                        local position = getPromptPosition(prompt)

                        if position then
                            local distance =
                                (root.Position - position).Magnitude

                            if distance <= prompt.MaxActivationDistance then
                                pcall(function()
                                    prompt:InputHoldBegin()
                                    task.wait(0.1)
                                    prompt:InputHoldEnd()
                                end)

                                task.wait(0.3)
                            end
                        end
                    end
                end
            end

            task.wait(0.5)
        end
    end)
end

-- =========================================
-- CRIAR OS QUATRO BOTOES
-- =========================================

createToggle("Stamina Infinita", function(v)
    infiniteStamina(v)
end)

createToggle("Remover Portas e Dutos", function(v)
    removeDoors(v)
end)

createToggle("Coleta Instantânea", function(v)
    instantCollection(v)
end)

createToggle("Auto Farm", function(v)
    autoFarm(v)
end)

-- =========================================
-- FIM DAS FUNCOES EXTRAS
-- =========================================
