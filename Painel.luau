--==================================================
-- ROUBE OU MORRA | DEVELOPMENT PANEL
-- Linguagem: Luau
--==================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- CONFIGURAÇÕES
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
        "Hospital"
    }
}

local States = {}

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows
}

-- CORES
local Colors = {
    Background = Color3.fromRGB(15, 17, 23),
    Sidebar = Color3.fromRGB(20, 23, 31),
    Panel = Color3.fromRGB(27, 30, 40),
    Button = Color3.fromRGB(37, 41, 53),
    Accent = Color3.fromRGB(90, 125, 255),
    Green = Color3.fromRGB(45, 175, 110),
    Red = Color3.fromRGB(210, 65, 75),
    White = Color3.fromRGB(245, 245, 250),
    Gray = Color3.fromRGB(145, 150, 165)
}

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "ROM_Panel"
GUI.ResetOnSpawn = false
GUI.DisplayOrder = 999
GUI.Parent = PlayerGui

-- JANELA PRINCIPAL
local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(650, 440)
Main.Position = UDim2.new(0.5, -325, 0.5, -220)
Main.BackgroundColor3 = Colors.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = GUI

Instance.new("UICorner", Main).CornerRadius =
    UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 60, 80)
MainStroke.Thickness = 1
MainStroke.Parent = Main

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
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 55)
Header.BackgroundColor3 = Colors.Sidebar
Header.BorderSizePixel = 0
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.fromOffset(18, 0)
Title.BackgroundTransparency = 1
Title.Text = "ROUBE OU MORRA"
Title.TextColor3 = Colors.White
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(38, 34)
Minimize.Position = UDim2.new(1, -48, 0, 10)
Minimize.BackgroundColor3 = Colors.Button
Minimize.Text = "—"
Minimize.TextColor3 = Colors.White
Minimize.TextSize = 22
Minimize.Font = Enum.Font.GothamBold
Minimize.Parent = Header

Instance.new("UICorner", Minimize).CornerRadius =
    UDim.new(0, 7)

-- MENU LATERAL
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 165, 1, -55)
Sidebar.Position = UDim2.fromOffset(0, 55)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 8)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = Sidebar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 15)
SidePadding.Parent = Sidebar

-- CONTEÚDO
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -180, 1, -70)
Content.Position = UDim2.fromOffset(175, 65)
Content.BackgroundTransparency = 1
Content.Parent = Main

local PageTitle = Instance.new("TextLabel")
PageTitle.Size = UDim2.new(1, 0, 0, 35)
PageTitle.BackgroundTransparency = 1
PageTitle.Text = "Dashboard"
PageTitle.TextColor3 = Colors.White
PageTitle.Font = Enum.Font.GothamBold
PageTitle.TextSize = 19
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.Parent = Content

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 1, -25)
Status.BackgroundTransparency = 1
Status.Text = "Sistema iniciado"
Status.TextColor3 = Colors.Green
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Content

local Pages = {}

local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Name = name
    Page.Size = UDim2.new(1, 0, 1, -75)
    Page.Position = UDim2.fromOffset(0, 40)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new()
    Page.Visible = false
    Page.Parent = Content

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Page

    Pages[name] = Page
    return Page
end

local function CreateSection(page, name)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -5, 0, 30)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Colors.Accent
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = page
end

local function CreateButton(page, name, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -8, 0, 39)
    Button.BackgroundColor3 = Colors.Button
    Button.TextColor3 = Colors.White
    Button.Text = name
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamSemibold
    Button.Parent = page

    Instance.new("UICorner", Button).CornerRadius =
        UDim.new(0, 7)

    Button.MouseButton1Click:Connect(callback)

    return Button
end

local function CreateToggle(page, key, name, callback)
    States[key] = false

    local Button = CreateButton(
        page,
        name .. "     OFF",
        function()
            States[key] = not States[key]

            Button.Text = name ..
                (States[key] and "     ON" or "     OFF")

            Button.BackgroundColor3 = States[key]
                and Colors.Green
                or Colors.Button

            if callback then
                callback(States[key])
            end
        end
    )

    return Button
end

-- PÁGINAS
local Dashboard = CreatePage("Dashboard")
local ESP = CreatePage("ESP")
local Farm = CreatePage("Farm")
local Settings = CreatePage("Settings")

-- DASHBOARD
CreateSection(Dashboard, "INFORMAÇÕES")

CreateButton(Dashboard, "Atualizar jogadores", function()
    Status.Text = "Jogadores: " .. #Players:GetPlayers()
end)

CreateButton(Dashboard, "Verificar versão", function()
    Status.Text = "ROM Panel - Luau"
end)

-- ESP
CreateSection(ESP, "IDENTIFICAÇÃO VISUAL")

CreateButton(ESP, "ESP Players - Azul", function()
    Status.Text = "Integração de ESP requer dados autorizados"
end)

CreateButton(ESP, "ESP Monstro - Vermelho", function()
    Status.Text = "Integração de ESP requer dados autorizados"
end)

CreateButton(ESP, "ESP Itens e raridades", function()
    Status.Text = "Integração de itens pendente"
end)

CreateSection(ESP, "RARIDADES")

for _, rarity in ipairs(Config.Rarities) do
    CreateButton(ESP, rarity, function()
        Status.Text = "Raridade selecionada: " .. rarity
    end)
end

-- FARM
CreateSection(Farm, "AUTO FARM")

CreateButton(Farm, "Auto Farm Inteligente", function()
    Status.Text = "Integração com jogo pendente"
end)

CreateButton(Farm, "Auto Collect", function()
    Status.Text = "Integração com coleta pendente"
end)

CreateSection(Farm, "MAPAS")

local SelectedMap = nil

for _, map in ipairs(Config.Maps) do
    CreateButton(Farm, "Selecionar " .. map, function()
        SelectedMap = map
        Status.Text = "Mapa: " .. map
    end)
end

CreateSection(Farm, "MONITORAMENTO")

local CurrentWeight = 0
local MaximumWeight = 100

CreateButton(Farm, "Verificar mochila", function()
    local percentage = CurrentWeight / MaximumWeight * 100

    Status.Text = string.format(
        "Mochila: %.1f%%",
        percentage
    )

    if percentage >= Config.BagLimit then
        Status.Text = "Limite de 80% atingido"
    end
end)

-- CONFIGURAÇÕES
CreateSection(Settings, "ILUMINAÇÃO")

CreateToggle(Settings, "Brightness", "Brilho máximo", function(enabled)
    if enabled then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
    end
end)

CreateSection(Settings, "OUTROS")

CreateButton(Settings, "Portas e dutos", function()
    Status.Text = "Integração visual pendente"
end)

CreateButton(Settings, "Estamina do jogador", function()
    Status.Text = "Integração com sistema de estamina pendente"
end)

CreateButton(Settings, "Estamina do monstro", function()
    Status.Text = "Integração com sistema de estamina pendente"
end)

-- NAVEGAÇÃO
local function CreateTab(name, page)
    local Button = Instance.new("TextButton")

    Button.Size = UDim2.new(1, -16, 0, 38)
    Button.BackgroundColor3 = Colors.Button
    Button.Text = name
    Button.TextColor3 = Colors.White
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamSemibold
    Button.Parent = Sidebar

    Instance.new("UICorner", Button).CornerRadius =
        UDim.new(0, 7)

    Button.MouseButton1Click:Connect(function()
        for pageName, object in pairs(Pages) do
            object.Visible = object == page
        end

        PageTitle.Text = name
        Status.Text = "Categoria: " .. name
    end)
end

CreateTab("Dashboard", Dashboard)
CreateTab("ESP", ESP)
CreateTab("Auto Farm", Farm)
CreateTab("Configurações", Settings)

Dashboard.Visible = true

-- MINIMIZAR / RESTAURAR
local minimized = false

Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized

    Sidebar.Visible = not minimized
    Content.Visible = not minimized

    Main.Size = minimized
        and UDim2.fromOffset(250, 55)
        or UDim2.fromOffset(650, 440)

    Minimize.Text = minimized and "+" or "—"
end)

print("ROUBE OU MORRA - Interface carregada")
