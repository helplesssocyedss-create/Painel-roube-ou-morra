
-- ROUBE OU MORRA | MOD MENU
-- Compatível com Roblox Studio
-- Coloque em um LocalScript dentro de StarterPlayerScripts

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraMenu"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Janela principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 300)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
title.Text = "ROUBE OU MORRA"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Parent = frame

-- Criador de botões
local function createButton(name, position, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.85, 0, 0, 40)
    button.Position = UDim2.new(0.075, 0, 0, position)
    button.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = name
    button.TextScaled = true
    button.Parent = frame

    Instance.new("UICorner", button).CornerRadius =
        UDim.new(0, 8)

    button.MouseButton1Click:Connect(callback)
end

-- Velocidade
local fast = false

createButton("Velocidade: ON/OFF", 60, function()
    fast = not fast

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.WalkSpeed = fast and 32 or 16
    end
end)

-- Pulo
local jump = false

createButton("Pulo alto: ON/OFF", 110, function()
    jump = not jump

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.JumpPower = jump and 100 or 50
    end
end)

-- Restaurar configurações
createButton("Resetar configurações", 160, function()
    fast = false
    jump = false

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
end)

-- Fechar menu
createButton("FECHAR MENU", 220, function()
    gui.Enabled = false
end)

print("Mod Menu carregado!")
