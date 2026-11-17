--==================================================
-- ROUBE OU MORRA | PAINEL DE TESTE - tales.helpers
-- Luau | UI Premium
--==================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Config = {
	BagLimit = 80,
	Rarities = {"Secreto","Lendário","Místico","Raro","Incomum","Comum"},
	Maps = {"Hospital"}
}

local States = {}
local OriginalLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	GlobalShadows = Lighting.GlobalShadows
}

local Colors = {
	Background = Color3.fromRGB(13,15,21),
	Sidebar = Color3.fromRGB(18,20,28),
	Panel = Color3.fromRGB(25,28,38),
	Button = Color3.fromRGB(35,39,52),
	Accent = Color3.fromRGB(90,125,255),
	Green = Color3.fromRGB(45,175,110),
	Red = Color3.fromRGB(210,65,75),
	White = Color3.fromRGB(245,245,250),
	Gray = Color3.fromRGB(145,150,165)
}

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "ROM_Panel"
GUI.ResetOnSpawn = false
GUI.DisplayOrder = 999
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(680, 460)
Main.Position = UDim2.new(0.5,-340,0.5,-230)
Main.BackgroundColor3 = Colors.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,14)
local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(55,60,80)
Stroke.Thickness = 1
Stroke.Parent = Main

-- Animação de entrada
Main.Size = UDim2.fromOffset(0,0)
TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(680,460)}):Play()

-- Arrastar
local dragging, dragStart, startPos = false, nil, nil
Main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Main.Position
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,58)
Header.BackgroundColor3 = Colors.Sidebar
Header.BorderSizePixel = 0
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-130,1,0)
Title.Position = UDim2.fromOffset(18,0)
Title.BackgroundTransparency = 1
Title.Text = "ROUBE OU MORRA"
Title.TextColor3 = Colors.White
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1,-130,0,16)
SubTitle.Position = UDim2.fromOffset(18,34)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Painel de Teste Autorizado"
SubTitle.TextColor3 = Colors.Gray
SubTitle.TextSize = 11
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Header

local function HeaderBtn(text, x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(38,34)
	b.Position = UDim2.new(1, x, 0, 12)
	b.BackgroundColor3 = Colors.Button
	b.Text = text
	b.TextColor3 = Colors.White
	b.TextSize = 18
	b.Font = Enum.Font.GothamBold
	b.Parent = Header
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
	return b
end
local Minimize = HeaderBtn("—", -92)
local Close = HeaderBtn("X", -48)
Close.BackgroundColor3 = Colors.Red
Close.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,170,1,-58)
Sidebar.Position = UDim2.fromOffset(0,58)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0,8)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.Parent = Sidebar
local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0,14)
SidePad.Parent = Sidebar

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-185,1,-73)
Content.Position = UDim2.fromOffset(178,68)
Content.BackgroundTransparency = 1
Content.Parent = Main

local PageTitle = Instance.new("TextLabel")
PageTitle.Size = UDim2.new(1,0,0,32)
PageTitle.BackgroundTransparency = 1
PageTitle.Text = "Dashboard"
PageTitle.TextColor3 = Colors.White
PageTitle.Font = Enum.Font.GothamBold
PageTitle.TextSize = 19
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.Parent = Content

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1,0,0,22)
Status.Position = UDim2.new(0,0,1,-22)
Status.BackgroundTransparency = 1
Status.Text = "Sistema iniciado • tales.helpers"
Status.TextColor3 = Colors.Green
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Content

local Pages = {}
local function CreatePage(name)
	local p = Instance.new("ScrollingFrame")
	p.Name = name
	p.Size = UDim2.new(1,0,1,-70)
	p.Position = UDim2.fromOffset(0,38)
	p.BackgroundTransparency = 1
	p.BorderSizePixel = 0
	p.ScrollBarThickness = 3
	p.AutomaticCanvasSize = Enum.AutomaticSize.Y
	p.CanvasSize = UDim2.new()
	p.Visible = false
	p.Parent = Content
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0,8)
	l.Parent = p
	Pages[name] = p
	return p
end

local function Section(page, name)
	local lb = Instance.new("TextLabel")
	lb.Size = UDim2.new(1,-5,0,28)
	lb.BackgroundTransparency = 1
	lb.Text = name
	lb.TextColor3 = Colors.Accent
	lb.TextSize = 13
	lb.Font = Enum.Font.GothamBold
	lb.TextXAlignment = Enum.TextXAlignment.Left
	lb.Parent = page
end

local function Button(page, name, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-8,0,40)
	b.BackgroundColor3 = Colors.Button
	b.TextColor3 = Colors.White
	b.Text = name
	b.TextSize = 12
	b.Font = Enum.Font.GothamSemibold
	b.Parent = page
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
	b.MouseButton1Click:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Colors.Accent}):Play()
		task.delay(0.12, function() TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Button}):Play() end)
		if cb then cb() end
	end)
	return b
end

local function Toggle(page, key, name, cb)
	States[key] = false
	local b = Button(page, name.."  •  OFF", nil)
	b.MouseButton1Click:Connect(function()
		States[key] = not States[key]
		b.Text = name.."  •  "..(States[key] and "ON" or "OFF")
		TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = States[key] and Colors.Green or Colors.Button}):Play()
		Status.Text = name.." "..(States[key] and "ativado" or "desativado")
		if cb then cb(States[key]) end
	end)
	return b
end

-- Páginas separadas
local Dashboard = CreatePage("Dashboard")
local ESP = CreatePage("ESP")
local Coleta = CreatePage("Coleta")
local Mapas = CreatePage("Mapas")
local Mochila = CreatePage("Mochila")
local Visual = CreatePage("Visual")
local Estamina = CreatePage("Estamina")

-- DASHBOARD
Section(Dashboard, "INFORMAÇÕES")
Button(Dashboard, "Atualizar jogadores", function() Status.Text = "Jogadores online: "..#Players:GetPlayers() end)
Button(Dashboard, "Verificar versão", function() Status.Text = "ROM Panel v2 • tales.helpers" end)

-- ESP
Section(ESP, "IDENTIFICAÇÃO VISUAL")
Toggle(ESP, "ESPPlayers", "ESP Players - Azul", function(on) Status.Text = "ESP Players "..(on and "ativado - aguardando dados do servidor" or "desativado") end)
Toggle(ESP, "ESPMonster", "ESP Monstro - Vermelho", function(on) Status.Text = "ESP Monstro "..(on and "ativado - aguardando dados do servidor" or "desativado") end)
Toggle(ESP, "ESPItems", "ESP Itens e raridades", function(on) Status.Text = "ESP Itens "..(on and "ativado" or "desativado") end)

-- COLETA
Section(Coleta, "AUTO COLETA")
Toggle(Coleta, "AutoCollect", "Auto Collect", function(on) Status.Text = "Auto Collect "..(on and "ativado" or "desativado") end)
Toggle(Coleta, "AutoFarm", "Auto Farm Inteligente", function(on) Status.Text = "Auto Farm "..(on and "ativado" or "desativado") end)
Toggle(Coleta, "ExitFinder", "Localizador de saída", function(on) Status.Text = "Localizador "..(on and "ativado" or "desativado") end)
Section(Coleta, "PRIORIDADE POR RARIDADE")
for _, rarity in ipairs(Config.Rarities) do
	Button(Coleta, rarity, function() Status.Text = "Prioridade: "..rarity end)
end

-- MAPAS
Section(Mapas, "SELECIONAR MAPA")
for _, map in ipairs(Config.Maps) do
	Button(Mapas, "Selecionar "..map, function() Status.Text = "Mapa selecionado: "..map end)
end

-- MOCHILA
Section(Mochila, "MONITORAMENTO")
local cur, max = 0, 100
local BagBarBG = Instance.new("Frame")
BagBarBG.Size = UDim2.new(1,-8,0,16)
BagBarBG.BackgroundColor3 = Colors.Button
BagBarBG.Parent = Mochila
Instance.new("UICorner", BagBarBG).CornerRadius = UDim.new(0,8)
local BagBar = Instance.new("Frame")
BagBar.Size = UDim2.new(0,0,1,0)
BagBar.BackgroundColor3 = Colors.Green
BagBar.Parent = BagBarBG
Instance.new("UICorner", BagBar).CornerRadius = UDim.new(0,8)
Button(Mochila, "Verificar mochila", function()
	local pct = cur / max * 100
	TweenService:Create(BagBar, TweenInfo.new(0.4), {Size = UDim2.new(pct/100,0,1,0)}):Play()
	if pct >= Config.BagLimit then Status.Text = "LIMITE DE 80% ATINGIDO" else Status.Text = string.format("Mochila: %.1f%%", pct) end
end)

-- VISUAL
Section(Visual, "ILUMINAÇÃO")
Toggle(Visual, "Brightness", "Brilho máximo", function(on)
	if on then Lighting.Brightness = 3 Lighting.ClockTime = 14 Lighting.GlobalShadows = false
	else Lighting.Brightness = OriginalLighting.Brightness Lighting.ClockTime = OriginalLighting.ClockTime Lighting.GlobalShadows = OriginalLighting.GlobalShadows end
end)
Section(Visual, "AMBIENTE")
Toggle(Visual, "Doors", "Portas e dutos", function(on) Status.Text = "Portas e dutos "..(on and "ativado - modo visual" or "desativado") end)

-- ESTAMINA
Section(Estamina, "ESTAMINA")
Toggle(Estamina, "StamPlayer", "Estamina - Jogador", function(on) Status.Text = "Estamina Jogador "..(on and "ativada" or "desativada") end)
Toggle(Estamina, "StamMonster", "Estamina - Monstro", function(on) Status.Text = "Estamina Monstro "..(on and "ativada" or "desativada") end)

-- Rodapé
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1,0,0,18)
Footer.Position = UDim2.new(0,0,1,-18)
Footer.BackgroundTransparency = 1
Footer.Text = "tales.helpers"
Footer.TextColor3 = Colors.Gray
Footer.TextSize = 11
Footer.Font = Enum.Font.Gotham
Footer.Parent = Main

-- Navegação
local function Tab(name, page)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-16,0,38)
	b.BackgroundColor3 = Colors.Button
	b.Text = name
	b.TextColor3 = Colors.White
	b.TextSize = 12
	b.Font = Enum.Font.GothamSemibold
	b.Parent = Sidebar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
	b.MouseButton1Click:Connect(function()
		for _, obj in pairs(Pages) do obj.Visible = false end
		page.Visible = true
		PageTitle.Text = name
		Status.Text = "Categoria: "..name
		for _, other in pairs(Sidebar:GetChildren()) do if other:IsA("TextButton") then other.BackgroundColor3 = Colors.Button end end
		b.BackgroundColor3 = Colors.Accent
	end)
end
Tab("Dashboard", Dashboard)
Tab("ESP", ESP)
Tab("Coleta", Coleta)
Tab("Mapas", Mapas)
Tab("Mochila", Mochila)
Tab("Visual", Visual)
Tab("Estamina", Estamina)
Dashboard.Visible = true

local minimized = false
Minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	Sidebar.Visible = not minimized
	Content.Visible = not minimized
	TweenService:Create(Main, TweenInfo.new(0.25), {Size = minimized and UDim2.fromOffset(280,58) or UDim2.fromOffset(680,460)}):Play()
	Minimize.Text = minimized and "+" or "—"
end)

print("ROUBE OU MORRA - Painel tales.helpers carregado")
