
-- ROUBE OU MORRA | MOD MENU
-- LocalScript em StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RoubeOuMorraMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(270, 310)
Frame.Position = UDim2.new(0, 30, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundColor3 = Color3.fromRGB(140, 35, 45)
Title.Text = "ROUBE OU MORRA"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true
Title.Parent = Frame

local settings = {
    PlayerESP = false,
    MonsterESP = false,
    NameESP = false,
    InfiniteStamina = false
}

local function createButton(text, y, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.88, 0, 0, 42)
    button.Position = UDim2.new(0.06, 0, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Text = text .. " [OFF]"
    button.Parent = Frame

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    local enabled = false

    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        button.Text = text .. (enabled and " [ON]" or " [OFF]")
        callback(enabled)
    end)
end

-- Player ESP com aparência original
local playerHighlights = {}

local function updatePlayerESP(enabled)
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= LocalPlayer then
            local character = target.Character

            if enabled and character then
                if not playerHighlights[target] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "PlayerESP"
                    highlight.FillColor = Color3.fromRGB(0, 170, 255)
                    highlight.OutlineColor = Color3.new(1, 1, 1)
                    highlight.FillTransparency = 0.65
                    highlight.Adornee = character
                    highlight.Parent = ScreenGui

                    playerHighlights[target] = highlight
                end
            elseif playerHighlights[target] then
                playerHighlights[target]:Destroy()
                playerHighlights[target] = nil
            end
        end
    end
end

createButton("Player ESP / Skin", 60, function(enabled)
    settings.PlayerESP = enabled
    updatePlayerESP(enabled)
end)

-- Nome dos jogadores
local nameTags = {}

local function updateNames(enabled)
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= LocalPlayer then
            local character = target.Character
            local head = character and character:FindFirstChild("Head")

            if enabled and head and not nameTags[target] then
                local billboard = Instance.new("BillboardGui")
                billboard.Size = UDim2.fromOffset(150, 35)
                billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                billboard.AlwaysOnTop = true
                billboard.Adornee = head
                billboard.Parent = ScreenGui

                local label = Instance.new("TextLabel")
                label.Size = UDim2.fromScale(1, 1)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.new(1, 1, 1)
                label.TextStrokeTransparency = 0
                label.TextScaled = true
                label.Text = target.DisplayName
                label.Parent = billboard

                nameTags[target] = billboard
            elseif not enabled and nameTags[target] then
                nameTags[target]:Destroy()
                nameTags[target] = nil
            end
        end
    end
end

createButton("Name ESP", 110, function(enabled)
    settings.NameESP = enabled
    updateNames(enabled)
end)

-- ESP de monstros do próprio jogo
local function updateMonsterESP(enabled)
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Model") and
           object:GetAttribute("IsMonster") == true then

            local highlight = object:FindFirstChild("MonsterESP")

            if enabled and not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "MonsterESP"
                highlight.FillColor = Color3.fromRGB(255, 40, 40)
                highlight.OutlineColor = Color3.new(1, 1, 1)
                highlight.Parent = object
            elseif not enabled and highlight then
                highlight:Destroy()
            end
        end
    end
end

createButton("Monster ESP", 160, function(enabled)
    settings.MonsterESP = enabled
    updateMonsterESP(enabled)
end)

-- Stamina: integração com o sistema do seu jogo
createButton("Infinite Stamina", 210, function(enabled)
    settings.InfiniteStamina = enabled
    print("Infinite Stamina:", enabled)
    print("Conecte esta opção ao sistema de stamina do servidor.")
end)

-- Abrir e fechar
createButton("Fechar Menu", 260, function()
    Frame.Visible = false
end)

print("Roube ou Morra Menu carregado!")
