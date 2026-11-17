--==================================================
-- ROUBE OU MORRA V9 - CORRIGIDO
-- Mod Menu | LocalScript
-- ESP Players azul | ESP Monstros vermelho
--==================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui

for _, old in ipairs(playerGui:GetChildren()) do
    if old.Name == "RoubeOuMorraV8" or old.Name == "RoubeOuMorraV9" then
        old:Destroy()
    end
end

local states = {}
local highlights = {}
local tags = {}
local ductESP = {}
local itemESP = {}
local rarityESP = {}
local hidden = {}
local prompts = {}

local staminaGeneration = 0
local farmGeneration = 0
local destroyed = false

local function norm(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[%s_%-]", "")
    return value
end

local monsterNames = {
    ["thelocust"] = true,
    ["locust"] = true,
    ["thehollow"] = true,
    ["hollow"] = true,
    ["therictus"] = true,
    ["rictus"] = true,
    ["thewendell"] = true,
    ["wendell"] = true,
    ["mimic"] = true,
    ["themimic"] = true
}

local function playerFromCharacter(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then
            return plr
        end
    end
    return nil
end

local function isMonster(model, plr)
    if not model or not model:IsA("Model") or plr then
        return false
    end

    if model:GetAttribute("IsMonster") == true
        or model:GetAttribute("Monster") == true then
        return true
    end

    local namesToCheck = {
        model.Name,
        model:GetAttribute("MonsterName"),
        model:GetAttribute("Role"),
        model:GetAttribute("EntityType")
    }

    for _, name in ipairs(namesToCheck) do
        if name and monsterNames[norm(name)] then
            return true
        end
    end

    return false
end

local function removeEntry(tbl, model)
    local entry = tbl[model]
    if entry then
        pcall(function()
            entry:Destroy()
        end)
        tbl[model] = nil
    end
end

local function clearModel(model)
    removeEntry(highlights, model)
    removeEntry(tags, model)
end

local function makeHighlight(model, color, tableRef)
    if tableRef[model] then return end

    local h = Instance.new("Highlight")
    h.Name = "ROM_ESP"
    h.Adornee = model
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.75
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = model

    tableRef[model] = h
end

local function makeNameTag(model, label, color)
    if tags[model] or not gui then return end

    local adornee = model:FindFirstChild("Head")
        or model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart

    if not adornee then return end

    local bill = Instance.new("BillboardGui")
    bill.Name = "ROM_Name"
    bill.Adornee = adornee
    bill.Size = UDim2.fromOffset(160, 30)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    bill.Parent = gui

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(1, 1)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 13
    text.TextStrokeTransparency = 0.25
    text.TextColor3 = color
    text.Text = label
    text.Parent = bill

    tags[model] = bill
end

local function applyModel(model)
    if not model or not model:IsA("Model") then return end

    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local plr = playerFromCharacter(model)
    local monster = isMonster(model, plr)

    clearModel(model)

    if monster then
        if states["ESP Monstro Vermelho"] then
            makeHighlight(model, Color3.fromRGB(255, 35, 35), highlights)
        end

        if states["ESP Nome"] then
            makeNameTag(model, model.Name, Color3.fromRGB(255, 50, 50))
        end

    elseif plr and plr ~= player then
        if states["ESP Players"] then
            makeHighlight(model, Color3.fromRGB(40, 140, 255), highlights)
        end

        if states["ESP Nome"] then
            makeNameTag(model, plr.Name, Color3.fromRGB(80, 170, 255))
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

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            applyModel(plr.Character)
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not playerFromCharacter(obj) then
            applyModel(obj)
        end
    end
end

--==================================================
-- INTERFACE
--==================================================

gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraV9"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(285, 450)
main.Position = UDim2.new(0.5, -142, 0.5, -225)
main.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(180, 25, 35)
stroke.Thickness = 1.5
stroke.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(35, 12, 17)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 0)
title.Size = UDim2.new(1, -55, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "ROUBE OU MORRA V9"
title.TextColor3 = Color3.fromRGB(255, 70, 70)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(35, 30)
minimize.Position = UDim2.new(1, -40, 0, 6)
minimize.BackgroundColor3 = Color3.fromRGB(75, 20, 25)
minimize.Text = "-"
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 20
minimize.Parent = header

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimize

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(8, 50)
scroll.Size = UDim2.new(1, -16, 1, -58)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

-- Arrastar painel com mouse ou toque
local dragging = false
local dragStart
local startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
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

local minimized = false
minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll.Visible = not minimized
    main.Size = minimized and UDim2.fromOffset(285, 42)
        or UDim2.fromOffset(285, 450)
    minimize.Text = minimized and "+" or "-"
end)

--==================================================
-- FUNÇÕES
--==================================================

local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows
}

local function setBrightness(enabled)
    if enabled then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        for property, value in pairs(originalLighting) do
            pcall(function()
                Lighting[property] = value
            end)
        end
    end
end

local function setStamina(enabled)
    staminaGeneration += 1
    local generation = staminaGeneration

    if not enabled then return end

    task.spawn(function()
        while states["Stamina Infinita"]
            and staminaGeneration == generation do

            local character = player.Character
            if character then
                for _, obj in ipairs(character:GetDescendants()) do
                    if (obj:IsA("NumberValue") or obj:IsA("IntValue"))
                        and norm(obj.Name):find("stamina") then
                        obj.Value = 100
                    end
                end
            end

            task.wait(0.25)
        end
    end)
end

local function setDoors(enabled)
    if enabled then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = norm(obj.Name)
                if n:find("door") or n:find("porta") then
                    if not hidden[obj] then
                        hidden[obj] = {
                            Transparency = obj.LocalTransparencyModifier,
                            CanCollide = obj.CanCollide
                        }
                    end

                    obj.LocalTransparencyModifier = 1
                    obj.CanCollide = false
                end
            end
        end
    else
        for part, data in pairs(hidden) do
            if part and part.Parent then
                part.LocalTransparencyModifier = data.Transparency
                part.CanCollide = data.CanCollide
            end
        end
        table.clear(hidden)
    end
end

local function setDuctESP(enabled)
    for obj, h in pairs(ductESP) do
        if h then h:Destroy() end
    end
    table.clear(ductESP)

    if not enabled then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local n = norm(obj.Name)
            if n:find("duct") or n:find("duto") or n:find("hatch") then
                local opened = obj:GetAttribute("IsOpen")
                    or obj:GetAttribute("Open")
                    or obj:GetAttribute("Unlocked")
                    or obj:GetAttribute("IsUnlocked")

                local color = opened
                    and Color3.fromRGB(40, 255, 100)
                    or Color3.fromRGB(255, 45, 45)

                local h = Instance.new("Highlight")
                h.Adornee = obj
                h.FillColor = color
                h.OutlineColor = color
                h.FillTransparency = 0.75
                h.Parent = obj
                ductESP[obj] = h
            end
        end
    end
end

local knownItems = {
    phone = true,
    cellphone = true,
    goldbar = true,
    laptop = true,
    screwdriver = true,
    needle = true,
    agulha = true,
    key = true,
    chave = true,
    item = true
}

local function getItemTarget(obj)
    local current = obj
    for _ = 1, 4 do
        if not current then break end
        if current:IsA("Model") then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function setItemESP(enabled)
    for obj, h in pairs(itemESP) do
        if h then h:Destroy() end
    end
    table.clear(itemESP)

    if not enabled then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Tool") then
            local target = getItemTarget(obj) or obj
            local n = norm(target.Name)

            if knownItems[n]
                or target:GetAttribute("IsItem") == true
                or target:GetAttribute("Item") == true then

                if not itemESP[target] then
                    local h = Instance.new("Highlight")
                    h.Adornee = target
                    h.FillColor = Color3.fromRGB(255, 220, 30)
                    h.OutlineColor = Color3.fromRGB(255, 245, 100)
                    h.FillTransparency = 0.7
                    h.Parent = target
                    itemESP[target] = h
                end
            end
        end
    end
end

local rarityColors = {
    common = Color3.fromRGB(180, 180, 180),
    uncommon = Color3.fromRGB(50, 220, 90),
    rare = Color3.fromRGB(60, 140, 255),
    mythic = Color3.fromRGB(190, 60, 255),
    secret = Color3.fromRGB(255, 50, 50)
}

local function readItemData(obj)
    local rarity = obj:GetAttribute("Rarity")
        or obj:GetAttribute("Raridade")
        or "common"

    local value = obj:GetAttribute("Value")
        or obj:GetAttribute("Valor")
        or ""

    local weight = obj:GetAttribute("Weight")
        or obj:GetAttribute("Peso")
        or ""

    for _, child in ipairs(obj:GetChildren()) do
        if child:IsA("StringValue") then
            local n = norm(child.Name)
            if n == "rarity" or n == "raridade" then
                rarity = child.Value
            end
        elseif child:IsA("NumberValue") or child:IsA("IntValue") then
            local n = norm(child.Name)
            if n == "value" or n == "valor" then
                value = child.Value
            elseif n == "weight" or n == "peso" then
                weight = child.Value
            end
        end
    end

    return norm(rarity), value, weight
end

local function setRarityESP(enabled)
    for obj, data in pairs(rarityESP) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Tag then data.Tag:Destroy() end
    end
    table.clear(rarityESP)

    if not enabled then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (
            obj:GetAttribute("IsItem") == true
            or obj:GetAttribute("Item") == true
            or knownItems[norm(obj.Name)]
        ) then
            local rarity, value, weight = readItemData(obj)
            local color = rarityColors[rarity]

            if color then
                local h = Instance.new("Highlight")
                h.Adornee = obj
                h.FillColor = color
                h.OutlineColor = color
                h.FillTransparency = 0.75
                h.Parent = obj

                local tag

                local adornee = obj:FindFirstChild("Head")
                    or obj.PrimaryPart
                    or obj:FindFirstChildWhichIsA("BasePart")

                if adornee then
                    tag = Instance.new("BillboardGui")
                    tag.Adornee = adornee
                    tag.Size = UDim2.fromOffset(150, 45)
                    tag.StudsOffset = Vector3.new(0, 2, 0)
                    tag.AlwaysOnTop = true
                    tag.Parent = gui

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.fromScale(1, 1)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = color
                    label.TextStrokeTransparency = 0.2
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 11
                    label.Text = obj.Name .. "\n" .. rarity
                        .. " | $" .. tostring(value)
                        .. " | " .. tostring(weight)
                    label.Parent = tag
                end

                rarityESP[obj] = {
                    Highlight = h,
                    Tag = tag
                }
            end
        end
    end
end

local function setInstantCollection(enabled)
    if enabled then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and not prompts[obj] then
                prompts[obj] = obj.HoldDuration
                obj.HoldDuration = 0
            end
        end
    else
        for prompt, duration in pairs(prompts) do
            if prompt and prompt.Parent then
                prompt.HoldDuration = duration
            end
        end
        table.clear(prompts)
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") and states["Coleta Instantânea"] then
        if not prompts[obj] then
            prompts[obj] = obj.HoldDuration
        end
        obj.HoldDuration = 0
    end
end)

local function setAutoFarm(enabled)
    farmGeneration += 1
    local generation = farmGeneration

    if not enabled then return end

    task.spawn(function()
        while states["Auto Farm"]
            and farmGeneration == generation do

            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if root then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local part = obj.Parent
                        if part and part:IsA("Attachment") then
                            part = part.Parent
                        end

                        if part and part:IsA("BasePart") then
                            local distance = (root.Position - part.Position).Magnitude

                            if distance <= obj.MaxActivationDistance then
                                pcall(function()
                                    obj:InputHoldBegin()
                                    task.wait(0.1)
                                    obj:InputHoldEnd()
                                end)
                            end
                        end
                    end
                end
            end

            task.wait(0.3)
        end
    end)
end

--==================================================
-- BOTÕES
--==================================================

local order = 0

local function createToggle(name, callback)
    order += 1

    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -4, 0, 34)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 43)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.TextColor3 = Color3.fromRGB(225, 225, 230)
    button.Text = name .. "  [OFF]"
    button.LayoutOrder = order
    button.Parent = scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = button

    states[name] = false

    button.MouseButton1Click:Connect(function()
        states[name] = not states[name]

        local enabled = states[name]
        button.Text = name .. (enabled and "  [ON]" or "  [OFF]")
        button.BackgroundColor3 = enabled
            and Color3.fromRGB(105, 25, 35)
            or Color3.fromRGB(35, 35, 43)

        if callback then
            local ok, err = pcall(callback, enabled)
            if not ok then
                warn("[ROM] Erro em " .. name .. ": " .. tostring(err))
            end
        end
    end)
end

createToggle("ESP Players", refreshAll)
createToggle("ESP Monstro Vermelho", refreshAll)
createToggle("ESP Nome", refreshAll)
createToggle("ESP Dutos", setDuctESP)
createToggle("ESP Itens e Chave", setItemESP)
createToggle("ESP Raridade", setRarityESP)
createToggle("Ultra Brilho", setBrightness)
createToggle("Stamina Infinita", setStamina)
createToggle("Remover Portas e Dutos", setDoors)
createToggle("Coleta Instantânea", setInstantCollection)
createToggle("Auto Farm", setAutoFarm)

--==================================================
-- ATUALIZAÇÃO AUTOMÁTICA
--==================================================

task.spawn(function()
    while gui and gui.Parent and not destroyed do
        task.wait(1.5)

        if states["ESP Players"]
            or states["ESP Monstro Vermelho"]
            or states["ESP Nome"] then
            refreshAll()
        end

        if states["ESP Dutos"] then
            setDuctESP(true)
        end

        if states["ESP Itens e Chave"] then
            setItemESP(true)
        end

        if states["ESP Raridade"] then
            setRarityESP(true)
        end
    end
end)

--==================================================
-- LIMPEZA
--==================================================

gui.Destroying:Connect(function()
    destroyed = true

    staminaGeneration += 1
    farmGeneration += 1

    for prompt, duration in pairs(prompts) do
        if prompt and prompt.Parent then
            pcall(function()
                prompt.HoldDuration = duration
            end)
        end
    end

    for part, data in pairs(hidden) do
        if part and part.Parent then
            pcall(function()
                part.LocalTransparencyModifier = data.Transparency
                part.CanCollide = data.CanCollide
            end)
        end
    end

    for property, value in pairs(originalLighting) do
        pcall(function()
            Lighting[property] = value
        end)
    end

    for model in pairs(highlights) do
        clearModel(model)
    end

    for obj, h in pairs(ductESP) do
        if h then h:Destroy() end
    end

    for obj, h in pairs(itemESP) do
        if h then h:Destroy() end
    end

    for obj, data in pairs(rarityESP) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Tag then data.Tag:Destroy() end
    end
end)

print("[ROUBE OU MORRA V9] Mod Menu carregado!")
