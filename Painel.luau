
--==================================================
-- ROUBE OU MORRA V9
-- Mod Menu | LocalScript
-- Base V5 | Funções preservadas
--==================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("RoubeOuMorraV8")
if old then old:Destroy() end

local old = playerGui:FindFirstChild("RoubeOuMorraV9")
if old then old:Destroy() end

local states = {}
local highlights = {}
local tags = {}
local ductESP = {}
local hidden = {}
local prompts = {}
local itemESP = {}
local rarityESP = {}

local function norm(v)
    return string.lower(tostring(v or ""))
        :gsub("_", " ")
        :gsub("%-", " ")
        :gsub("%s+", " ")
        :gsub("^%s*(.-)%s*$", "%1")
end

--==================================================
-- MONSTROS
--==================================================

local monsterNames = {
    ["the locust"] = true,
    ["locust"] = true,
    ["the hollow"] = true,
    ["hollow"] = true,
    ["the rictus"] = true,
    ["rictus"] = true,
    ["the wendell"] = true,
    ["wendell"] = true,
    ["mimic"] = true,
    ["the mimic"] = true
}

local function isMonster(model, plr)
    if not model or plr then return false end

    if model:GetAttribute("IsMonster") == true
    or model:GetAttribute("Monster") == true then
        return true
    end

    local names = {
        model.Name,
        model:GetAttribute("MonsterName"),
        model:GetAttribute("Role"),
        model:GetAttribute("EntityType")
    }

    for _, name in ipairs(names) do
        local n = norm(name)

        if monsterNames[n]
        or n:find("monster", 1, true)
        or n:find("monstro", 1, true)
        or n:find("entity", 1, true) then
            return true
        end
    end

    local team = plr and plr.Team
    if team then
        local n = norm(team.Name)
        if n:find("monster", 1, true)
        or n:find("monstro", 1, true) then
            return true
        end
    end

    return false
end

local function playerFromCharacter(model)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then
            return p
        end
    end
end

local function clearModel(model)
    if highlights[model] then
        highlights[model]:Destroy()
        highlights[model] = nil
    end

    if tags[model] then
        tags[model]:Destroy()
        tags[model] = nil
    end
end

local function applyModel(model)
    if not model or not model.Parent
    or not model:IsA("Model")
    or model == player.Character then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local plr = playerFromCharacter(model)
    local monster = isMonster(model, plr)

    if not plr and not monster then return end

    clearModel(model)

    if monster and states["ESP Monstro Vermelho"] then
        local h = Instance.new("Highlight")
        h.Name = "MonsterESP"
        h.Adornee = model
        h.FillColor = Color3.fromRGB(255, 0, 0)
        h.OutlineColor = Color3.fromRGB(255, 35, 35)
        h.FillTransparency = 0.35
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = gui
        highlights[model] = h

    elseif plr and states["ESP Players"] then
        local h = Instance.new("Highlight")
        h.Name = "PlayerESP"
        h.Adornee = model
        h.FillColor = Color3.fromRGB(50, 130, 255)
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.FillTransparency = 0.65
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = gui
        highlights[model] = h
    end

    if states["ESP Nome"] then
        local head = model:FindFirstChild("Head")
        if not head then
            head = model:FindFirstChild("HumanoidRootPart")
        end

        if head then
            local tag = Instance.new("BillboardGui")
            tag.Name = "ESPName"
            tag.Adornee = head
            tag.Size = UDim2.fromOffset(180, 30)
            tag.StudsOffset = Vector3.new(0, 3, 0)
            tag.AlwaysOnTop = true
            tag.Parent = gui

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1

            -- SOMENTE NOME DE EXIBIÇÃO
            label.Text = plr and plr.DisplayName
                or model.Name

            label.TextColor3 = monster
                and Color3.fromRGB(255, 60, 60)
                or Color3.new(1, 1, 1)

            label.TextStrokeTransparency = 0.1
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = tag

            tags[model] = tag
        end
    end
end

local function refreshAll()
    for model in pairs(highlights) do
        clearModel(model)
    end

    for model in pairs(tags) do
        clearModel(model)
    end

    local checked = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            checked[p.Character] = true
            applyModel(p.Character)
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not checked[obj] then
            applyModel(obj)
        end
    end
end

--==================================================
-- INTERFACE
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV9"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(285, 450)
frame.Position = UDim2.new(0.04, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(17, 17, 21)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius =
    UDim.new(0, 12)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(180, 20, 35)
header.BorderSizePixel = 0
header.Parent = frame

Instance.new("UICorner", header).CornerRadius =
    UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "ROUBE OU MORRA V9"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(38, 38)
minimize.Position = UDim2.new(1, -42, 0, 2)
minimize.Text = "—"
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.BackgroundTransparency = 1
minimize.TextSize = 22
minimize.Parent = header

local restore = Instance.new("TextButton")
restore.Size = UDim2.fromOffset(48, 48)
restore.Position = UDim2.new(0, 15, 0.5, -24)
restore.Text = "RM"
restore.TextColor3 = Color3.new(1, 1, 1)
restore.Font = Enum.Font.GothamBold
restore.BackgroundColor3 = Color3.fromRGB(180, 20, 35)
restore.Visible = false
restore.Parent = gui

Instance.new("UICorner", restore).CornerRadius =
    UDim.new(1, 0)

local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(0, 48)
content.Size = UDim2.new(1, 0, 1, -50)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = content

minimize.MouseButton1Click:Connect(function()
    frame.Visible = false
    restore.Visible = true
end)

restore.MouseButton1Click:Connect(function()
    frame.Visible = true
    restore.Visible = false
end)

local dragging = false
local dragStart
local startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--==================================================
-- ULTRA BRILHO
--==================================================

local original = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local function setBrightness(v)
    if v then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    else
        for k, value in pairs(original) do
            Lighting[k] = value
        end
    end
end

--==================================================
-- STAMINA
--==================================================

local staminaGeneration = 0

local function stamina(v)
    staminaGeneration += 1
    local generation = staminaGeneration

    if not v then return end

    task.spawn(function()
        while generation == staminaGeneration do
            for _, obj in ipairs(player:GetDescendants()) do
                if obj:IsA("NumberValue")
                or obj:IsA("IntValue") then

                    local n = norm(obj.Name)

                    if n:find("stamina", 1, true) then
                        local max =
                            obj:GetAttribute("MaxValue")
                            or obj:GetAttribute("MaxStamina")

                        if not max then
                            local parent = obj.Parent

                            if parent then
                                max = parent:GetAttribute("MaxStamina")
                            end
                        end

                        obj.Value = max or 100000
                    end
                end
            end

            task.wait(0.1)
        end
    end)
end

--==================================================
-- PORTAS E DUTOS
--==================================================

local removeEnvironmentEnabled = false

local doorNames = {
    ["door"] = true,
    ["double door"] = true,
    ["door double"] = true,
    ["porta"] = true,
    ["porta dupla"] = true
}

local function isDoorPart(obj)
    local current = obj

    for _ = 1, 4 do
        if not current then break end

        local n = norm(current.Name)

        if doorNames[n]
        or n:find("door", 1, true)
        or n:find("porta", 1, true) then
            return true
        end

        current = current.Parent
    end

    return false
end

local function hideEnvironmentPart(obj)
    if not obj:IsA("BasePart") then return end
    if not isDoorPart(obj) then return end

    if not hidden[obj] then
        hidden[obj] = {
            transparency = obj.LocalTransparencyModifier,
            collision = obj.CanCollide
        }
    end

    obj.LocalTransparencyModifier = 1
    obj.CanCollide = false
end

local function removeDoors(v)
    removeEnvironmentEnabled = v

    if v then
        for _, obj in ipairs(workspace:GetDescendants()) do
            hideEnvironmentPart(obj)
        end
    else
        for obj, data in pairs(hidden) do
            if obj and obj.Parent then
                obj.LocalTransparencyModifier = data.transparency
                obj.CanCollide = data.collision
            end
            hidden[obj] = nil
        end
    end
end

--==================================================
-- ESP DUTOS
-- Apenas modelos de duto identificados
--==================================================

local function isDuct(obj)
    if not obj:IsA("Model") then return false end

    local n = norm(obj.Name)

    return n:find("duto", 1, true) ~= nil
        or n:find("duct", 1, true) ~= nil
        or n:find("hatch", 1, true) ~= nil
end

local function ductIsOpen(obj)
    for _, name in ipairs({
        "IsOpen", "Open", "Unlocked", "IsUnlocked"
    }) do
        local value = obj:GetAttribute(name)
        if typeof(value) == "boolean" then
            return value
        end
    end

    return false
end

local function clearDuctESP()
    for obj, h in pairs(ductESP) do
        if h then h:Destroy() end
        ductESP[obj] = nil
    end
end

local function refreshDuctESP()
    clearDuctESP()

    if not states["ESP Dutos"] then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if isDuct(obj) then
            local h = Instance.new("Highlight")
            h.Name = "DuctESP"
            h.Adornee = obj
            h.FillTransparency = 1
            h.OutlineTransparency = 0
            h.OutlineColor = ductIsOpen(obj)
                and Color3.fromRGB(0, 255, 0)
                or Color3.fromRGB(255, 0, 0)
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = gui

            ductESP[obj] = h
        end
    end
end

--==================================================
-- ESP ITENS
--==================================================

local knownItems = {
    ["phone"] = true,
    ["telephone"] = true,
    ["gold bar"] = true,
    ["gold bars"] = true,
    ["laptop"] = true,
    ["encrypted hard drive"] = true,
    ["desk lamp"] = true,
    ["fire extinguisher"] = true,
    ["lab sample case"] = true,
    ["chair"] = true,
    ["bucket"] = true,
    ["lantern"] = true,
    ["granny bag"] = true,
    ["keyboard"] = true,
    ["headphones"] = true,
    ["painting"] = true,
    ["wristwatch"] = true,
    ["watch"] = true,
    ["toolbox"] = true,
    ["tablet"] = true,
    ["camera"] = true,
    ["fan"] = true,
    ["all in one pc"] = true,
    ["console"] = true,
    ["projector"] = true,
    ["guitar"] = true,
    ["record player"] = true,
    ["leather bag"] = true,
    ["desk fan"] = true,
    ["textbook stack"] = true,
    ["coffee mug"] = true,
    ["mini fridge"] = true,
    ["microwave"] = true,
    ["banjo"] = true,
    ["screwdriver"] = true,
    ["screw driver"] = true,
    ["needle"] = true,
    ["agulha"] = true
}

local function getItemTarget(obj)
    local current = obj

    for _ = 1, 4 do
        if not current then break end

        if knownItems[norm(current.Name)]
        or current:GetAttribute("IsItem") == true
        or current:GetAttribute("Item") == true then
            if current:IsA("Model")
            or current:IsA("Tool")
            or current:IsA("BasePart") then
                return current
            end
        end

        current = current.Parent
    end
end

local function clearItemESP()
    for obj, h in pairs(itemESP) do
        if h then h:Destroy() end
        itemESP[obj] = nil
    end
end

local function refreshItemESP()
    clearItemESP()

    if not states["ESP Itens e Chave"] then return end

    local seen = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        local target = getItemTarget(obj)

        if target and not seen[target] then
            seen[target] = true

            local adornee = target

            if target:IsA("Tool") then
                adornee = target:FindFirstChild("Handle")
                    or target:FindFirstChildWhichIsA("BasePart")
            end

            if adornee then
                local h = Instance.new("Highlight")
                h.Name = "LootESP"
                h.Adornee = adornee
                h.FillColor = Color3.fromRGB(255, 190, 50)
                h.OutlineColor = Color3.fromRGB(255, 245, 170)
                h.FillTransparency = 0.45
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = gui

                itemESP[target] = h
            end
        end
    end
end

--==================================================
-- RARIDADE / VALOR / PESO
--==================================================

local rarityColors = {
    common = Color3.fromRGB(190, 190, 190),
    uncommon = Color3.fromRGB(70, 220, 100),
    rare = Color3.fromRGB(60, 150, 255),
    mythic = Color3.fromRGB(200, 70, 255),
    secret = Color3.fromRGB(255, 190, 0)
}

local function readItemData(obj)
    local function read(names)
        for _, name in ipairs(names) do
            local value = obj:GetAttribute(name)

            if value ~= nil then return value end

            local child = obj:FindFirstChild(name, true)

            if child and (
                child:IsA("StringValue")
                or child:IsA("NumberValue")
                or child:IsA("IntValue")
            ) then
                return child.Value
            end
        end
    end

    return read({"Rarity", "ItemRarity", "Tier"}),
        read({"Value", "Price", "SellValue", "Worth"}),
        read({"Weight", "ItemWeight", "Mass"})
end

local function clearRarityESP()
    for obj, data in pairs(rarityESP) do
        if data.highlight then data.highlight:Destroy() end
        if data.tag then data.tag:Destroy() end
        rarityESP[obj] = nil
    end
end

local function refreshRarityESP()
    clearRarityESP()

    if not states["ESP Raridade"] then return end

    local filters = {
        common = states["Raridade Common"],
        uncommon = states["Raridade Uncommon"],
        rare = states["Raridade Rare"],
        mythic = states["Raridade Mythic"],
        secret = states["Raridade Secret"]
    }

    local filterActive = false

    for _, value in pairs(filters) do
        if value then filterActive = true break end
    end

    local seen = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Tool") then
            local rarity, value, weight = readItemData(obj)
            local r = norm(rarity)

            if rarityColors[r]
            and (not filterActive or filters[r])
            and not seen[obj] then

                seen[obj] = true

                local adornee = obj

                if obj:IsA("Tool") then
                    adornee = obj:FindFirstChild("Handle")
                        or obj:FindFirstChildWhichIsA("BasePart")
                end

                if adornee then
                    local color = rarityColors[r]

                    local h = Instance.new("Highlight")
                    h.Name = "RarityESP"
                    h.Adornee = adornee
                    h.FillColor = color
                    h.OutlineColor = color
                    h.FillTransparency = 0.45
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = gui

                    local tag = Instance.new("BillboardGui")
                    tag.Name = "RarityInfo"
                    tag.Adornee = adornee
                    tag.Size = UDim2.fromOffset(210, 65)
                    tag.StudsOffset = Vector3.new(0, 2.5, 0)
                    tag.AlwaysOnTop = true
                    tag.Parent = gui

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.fromScale(1, 1)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = color
                    label.TextStrokeTransparency = 0.1
                    label.TextScaled = true
                    label.Font = Enum.Font.GothamBold

                    label.Text = obj.Name
                        .. "\n" .. tostring(rarity)
                        .. "\nValor: " .. tostring(value or "N/D")
                        .. " | Peso: " .. tostring(weight or "N/D") .. " kg"

                    label.Parent = tag

                    rarityESP[obj] = {
                        highlight = h,
                        tag = tag
                    }
                end
            end
        end
    end
end

--==================================================
-- COLETA INSTANTÂNEA
--==================================================

local function instantCollection(v)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if v then
                if prompts[obj] == nil then
                    prompts[obj] = obj.HoldDuration
                end
                obj.HoldDuration = 0
            elseif prompts[obj] ~= nil then
                obj.HoldDuration = prompts[obj]
                prompts[obj] = nil
            end
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt")
    and states["Coleta Instantânea"] then
        prompts[obj] = obj.HoldDuration
        obj.HoldDuration = 0
    end
end)

--==================================================
-- AUTO FARM
--==================================================

local farmGeneration = 0

local function autoFarm(v)
    farmGeneration += 1
    local generation = farmGeneration

    if not v then return end

    task.spawn(function()
        while generation == farmGeneration do
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if root then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if generation ~= farmGeneration then break end

                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local part = obj.Parent

                        if part and part:IsA("Attachment") then
                            part = part.Parent
                        end

                        if part and part:IsA("BasePart") then
                            local distance =
                                (root.Position - part.Position).Magnitude

                            if distance <= obj.MaxActivationDistance then
                                pcall(function()
                                    obj:InputHoldBegin()
                                    task.wait(0.15)
                                    obj:InputHoldEnd()
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

--==================================================
-- BOTÕES
--==================================================

local function createToggle(name, callback)
    states[name] = false

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.92, 0, 0, 36)
    button.BackgroundColor3 = Color3.fromRGB(42, 42, 49)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Text = name .. " [OFF]"
    button.Parent = content

    Instance.new("UICorner", button).CornerRadius =
        UDim.new(0, 7)

    button.MouseButton1Click:Connect(function()
        local nextState = not states[name]
        states[name] = nextState

        local ok, err = pcall(function()
            callback(nextState)
        end)

        if not ok then
            states[name] = not nextState
            warn(name .. ": " .. tostring(err))
        end

        button.Text = name ..
            (states[name] and " [ON]" or " [OFF]")

        button.BackgroundColor3 = states[name]
            and Color3.fromRGB(170, 25, 40)
            or Color3.fromRGB(42, 42, 49)
    end)
end

createToggle("ESP Players", refreshAll)
createToggle("ESP Monstro Vermelho", refreshAll)
createToggle("ESP Nome", refreshAll)

createToggle("ESP Dutos", refreshDuctESP)
createToggle("ESP Itens e Chave", refreshItemESP)

createToggle("ESP Raridade", refreshRarityESP)
createToggle("Raridade Common", refreshRarityESP)
createToggle("Raridade Uncommon", refreshRarityESP)
createToggle("Raridade Rare", refreshRarityESP)
createToggle("Raridade Mythic", refreshRarityESP)
createToggle("Raridade Secret", refreshRarityESP)

createToggle("Ultra Brilho", setBrightness)
createToggle("Stamina Infinita", stamina)
createToggle("Remover Portas e Dutos", removeDoors)
createToggle("Coleta Instantânea", instantCollection)
createToggle("Auto Farm", autoFarm)

--==================================================
-- ATUALIZAÇÃO AUTOMÁTICA
--==================================================

task.spawn(function()
    while gui.Parent do
        if states["ESP Players"]
        or states["ESP Monstro Vermelho"]
        or states["ESP Nome"] then
            refreshAll()
        end

        if states["ESP Dutos"] then
            refreshDuctESP()
        end

        if states["ESP Itens e Chave"] then
            refreshItemESP()
        end

        if states["ESP Raridade"] then
            refreshRarityESP()
        end

        task.wait(1.5)
    end
end)

--==================================================
-- LIMPEZA
--==================================================

gui.Destroying:Connect(function()
    clearDuctESP()
    clearItemESP()
    clearRarityESP()

    for model in pairs(highlights) do
        clearModel(model)
    end

    for model in pairs(tags) do
        clearModel(model)
    end

    for obj, data in pairs(hidden) do
        if obj and obj.Parent then
            obj.LocalTransparencyModifier = data.transparency
            obj.CanCollide = data.collision
        end
    end
end)

print("ROUBE OU MORRA V9 CARREGADO!")
