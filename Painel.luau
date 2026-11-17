
local function isMonsterCharacter(character, plr)
    if not character then return false end

    local function containsMonsterName(name)
        name = string.lower(name or "")
        return name:find("monster")
            or name:find("monstro")
            or name:find("killer")
            or name:find("beast")
    end

    if containsMonsterName(character.Name) then
        return true
    end

    if plr and plr.Team and containsMonsterName(plr.Team.Name) then
        return true
    end

    if character:GetAttribute("IsMonster") == true then
        return true
    end

    return false
end

local function updatePlayerESP(plr)
    clearESP(plr)

    if plr == player then return end

    local character = plr.Character
    if not character then return end

    -- NUNCA aplicar ESP de jogador no monstro
    if isMonsterCharacter(character, plr) then
        return
    end

    if states["ESP Players"] then
        local h = Instance.new("Highlight")
        h.Adornee = character
        h.FillColor = Color3.fromRGB(80,150,255)
        h.FillTransparency = 0.65
        h.OutlineColor = Color3.fromRGB(255,255,255)
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = gui

        highlights[plr] = h
    end

    if states["ESP Nome"] then
        local head = character:FindFirstChild("Head")

        if head then
            local tag = Instance.new("BillboardGui")
            tag.Adornee = head
            tag.Size = UDim2.fromOffset(100,20)
            tag.StudsOffset = Vector3.new(0,2.3,0)
            tag.AlwaysOnTop = true
            tag.Parent = gui

            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1,1)
            label.BackgroundTransparency = 1
            label.Text = plr.DisplayName
            label.TextColor3 = Color3.new(1,1,1)
            label.TextStrokeTransparency = 0.3
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = tag

            nameTags[plr] = tag
        end
    end
end
