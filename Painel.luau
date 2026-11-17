
-- ROUBE OU MORRA - MOD MENU
-- Interface para Roblox Studio

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeOuMorraMenu"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 270, 0, 400)
frame.Position = UDim2.new(0.05, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundColor3 = Color3.fromRGB(180, 20, 35)
title.Text = "ROUBE OU MORRA"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = frame

local functions = {
    "ESP Nome",
    "ESP Players Branco",
    "ESP Monstro RGB",
    "Stamina Infinita",
    "Remover Portas e Dutos",
    "Coleta Instantânea",
    "Ultra Brilho",
    "Invisibilidade do Monstro"
}

local states = {}

for i, name in ipairs(functions) do
    states[name] = false

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.9, 0, 0, 35)
    button.Position = UDim2.new(0.05, 0, 0, 55 + (i-1)*42)
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Text = name .. " [OFF]"
    button.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 7)
    btnCorner.Parent = button

    button.MouseButton1Click:Connect(function()
        states[name] = not states[name]

        button.Text = name ..
            (states[name] and " [ON]" or " [OFF]")

        button.BackgroundColor3 = states[name]
            and Color3.fromRGB(170, 25, 40)
            or Color3.fromRGB(45, 45, 52)

        print(name, states[name])
    end)
end
