-- ROUBE OU MORRA
-- Painel demonstrativo em Luau

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Config = {
    BagLimit = 80,

    Rarities = {
        "Secreto",
        "Lendário",
        "Místico",
        "Raro",
        "Incomum",
        "Comum"
    },

    Maps = {
        "Hospital",
        "Mapa 2",
        "Mapa 3"
    }
}

local States = {}

local GUI = Instance.new("ScreenGui")
GUI.Name = "ROM_Dashboard"
GUI.ResetOnSpawn = false
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(330, 480)
Main.Position = UDim2.new(0.5, -165, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = GUI

Instance.new("UICorner", Main).CornerRadius =
    UDim.new(0, 12)

-- ARRASTAR JANELA

local dragging = false
local dragStart
local startPosition

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
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

-- CABEÇALHO

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -45, 0, 45)
Title.Position = UDim2.fromOffset(10, 0)
Title.BackgroundTransparency = 1
Title.Text = "ROUBE OU MORRA"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(35, 35)
Close.Position = UDim2.new(1, -40, 0, 5)
Close.Text = "X"
Close.TextColor3 = Color3.new(1, 1, 1)
Close.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
Close.Font = Enum.Font.GothamBold
Close.Parent = Main

Close.MouseButton1Click:Connect(function()
    GUI:Destroy()
end)

-- STATUS

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 25)
Status.Position = UDim2.fromOffset(10, 45)
Status.BackgroundTransparency = 1
Status.Text = "Painel iniciado"
Status.TextColor3 = Color3.fromRGB(100, 220, 140)
Status.TextSize = 12
Status.Font = Enum.Font.Gotham
Status.Parent = Main

-- ÁREA DE CONTEÚDO

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -85)
Scroll.Position = UDim2.fromOffset(10, 75)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new()
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.Parent = Scroll

local function Section(name)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -5, 0, 28)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(100, 170, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Scroll
end

local function Button(name, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -5, 0, 36)
    button.BackgroundColor3 = Color3.fromRGB(42, 42, 52)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = name
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.Parent = Scroll

    Instance.new("UICorner", button).CornerRadius =
        UDim.new(0, 7)

    button.MouseButton1Click:Connect(callback)

    return button
end

local function Toggle(key, name)
    States[key] = false

    local button

    button = Button(name .. " [OFF]", function()
        States[key] = not States[key]

        button.Text = name ..
            (States[key] and " [ON]" or " [OFF]")

        button.BackgroundColor3 = States[key]
            and Color3.fromRGB(35, 105, 65)
            or Color3.fromRGB(42, 42, 52)

        Status.Text = name ..
            (States[key] and " ativado" or " desativado")
    end)
end

-- IDENTIFICAÇÃO DEMONSTRATIVA

Section("01 - ESP DEMONSTRATIVO")
Toggle("Players", "Players - Azul")
Toggle("Monster", "Monstro - Vermelho")
Toggle("Items", "Itens por raridade")

-- CONTROLES

Section("02 - CONFIGURAÇÕES")
Toggle("PlayerStamina", "Estamina - Jogador")
Toggle("MonsterStamina", "Estamina - Monstro")
Toggle("AutoCollect", "Auto Collect")
Toggle("ExitFinder", "Localizador de saída")

-- MAPAS

Section("03 - MAPAS")

local selectedMap = nil

for _, mapName in ipairs(Config.Maps) do
    Button("Selecionar " .. mapName, function()
        selectedMap = mapName
        Status.Text = "Mapa selecionado: " .. mapName
    end)
end

-- RARIDADES

Section("04 - PRIORIDADE DOS ITENS")

for index, rarity in ipairs(Config.Rarities) do
    Button(index .. " - " .. rarity, function()
        Status.Text = "Raridade selecionada: " .. rarity
    end)
end

-- MOCHILA

Section("05 - MONITORAMENTO DA MOCHILA")

local currentWeight = 0
local maximumWeight = 100

local function UpdateBag(weight, capacity)
    currentWeight = math.max(0, weight)
    maximumWeight = math.max(1, capacity)

    local percentage = currentWeight / maximumWeight * 100

    Status.Text = string.format(
        "Mochila: %.1f%%",
        percentage
    )

    if percentage >= Config.BagLimit then
        Status.Text = "LIMITE DE 80% ATINGIDO"
    end
end

Button("Verificar mochila", function()
    UpdateBag(currentWeight, maximumWeight)
end)

-- VISUAL

Section("06 - VISUAL")
Toggle("Brightness", "Brilho máximo")
Toggle("Objects", "Portas e dutos")

-- FINALIZAÇÃO

print("ROM Dashboard iniciado.")
print("Ambiente: Luau")
print("Modo: Demonstrativo")
