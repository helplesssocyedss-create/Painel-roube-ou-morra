--==============================================================
-- ROUBE OU MORRA V16 | Feito por Tales
-- Base funcional V13/V14; interface organizada por paginas.
-- LocalScript / executor com suporte a Luau.
--==============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("RoubeOuMorraV16")
if old then old:Destroy() end

local states = {ESPPlayers=false, ESPMonsters=false, ESPDucts=false,
 RemoveDoors=false, InstantCollection=false, Brightness=false, AntiFlash=false,
 DataCollector=false, AutoFarm=false, StaminaScan=false}
local rarityEnabled = {Common=false,Uncommon=false,Rare=false,Epic=false,Legendary=false,Mythic=false,Secret=false}
local rarityColors = {
 Common=Color3.fromRGB(190,190,190), Uncommon=Color3.fromRGB(70,220,90),
 Rare=Color3.fromRGB(60,140,255), Epic=Color3.fromRGB(180,70,255),
 Legendary=Color3.fromRGB(255,190,30), Mythic=Color3.fromRGB(255,60,100), Secret=Color3.new(1,1,1)
}
local monsterNames={"locust","hollow","rictus","wendell","mimic","o vazio","o ritus","o gafanhoto","o fantasma materno","o inquilino","sara","elden","the elder"}
local highlights,labels,hiddenParts,savedPrompts,savedEffects = {},{},{},{},{}
local records,recordIndex={},{}
local MAX_RECORDS=12000
local statusLabel,reportBox

-- ATENCAO: token cliente pode ser extraido. Troque por um token novo no Supabase.
local SUPABASE_URL="https://nqafhfadocgqkzboyxpp.supabase.co"
local COLLECTOR_TOKEN="RBjAv5gAQ0QBuef0ue3wrhERLlMAuaumDJ0GnAHq83M"
local sentKeys={}; local sendQueue={}; local sendBusy=false
local HttpService=game:GetService("HttpService")
local sendRequest=(type(request)=="function" and request) or (type(http_request)=="function" and http_request) or (type(syn)=="table" and syn.request)
local sessionId
pcall(function() sessionId=HttpService:GenerateGUID(false) end)
sessionId=sessionId or (tostring(os.time()).."-"..tostring(math.random(100000,999999)))

local function queueReport(entry,key)
 if not sentKeys[key] then table.insert(sendQueue,{record_key=key,payload=entry}); sentKeys[key]=true end
end

local function flushReports()
 if sendBusy or #sendQueue==0 then return end
 if not sendRequest then
  if statusLabel then statusLabel.Text="Coleta local: executor sem request()" end
  return
 end

 sendBusy=true
 task.spawn(function()
  local sent,failed=0,0
  for _=1,math.min(25,#sendQueue) do
   local item=table.remove(sendQueue,1)
   local body={session_id=sessionId,record_key=item.record_key,payload=item.payload}
   local ok,res=pcall(function()
    return sendRequest({
     Url=SUPABASE_URL.."/functions/v1/ingest-report",
     Method="POST",
     Headers={
      ["Content-Type"]="application/json",
      ["x-collector-token"]=COLLECTOR_TOKEN
     },
     Body=HttpService:JSONEncode(body)
    })
   end)
   local code=ok and tonumber(res.StatusCode or res.Status) or 0
   if ok and code>=200 and code<300 then
    sent+=1
   else
    failed+=1
    table.insert(sendQueue,1,item)
    break
   end
  end
  sendBusy=false
  if statusLabel then
   statusLabel.Text="Coleta online | Enviados: "..sent.." | Pendentes: "..#sendQueue..(failed>0 and " | Falha HTTP/rede" or "")
  end
 end)
end

local scanCount,startTime,lastScan=0,os.clock(),"Nenhuma"
local gui

local function contains(value,list)
 value=string.lower(tostring(value or ""))
 for _,word in ipairs(list) do
  if string.find(value,string.lower(word),1,true) then return true end
 end
 return false
end

local function getPlayerFromModel(model)
 for _,plr in ipairs(Players:GetPlayers()) do
  if plr.Character==model then return plr end
 end
end

local function isMonster(model)
 if not model or not model:IsA("Model") then return false end
 if getPlayerFromModel(model) then return false end
 if contains(model.Name,monsterNames) then return true end

 local okTags,tags=pcall(function()
  return game:GetService("CollectionService"):GetTags(model)
 end)
 if okTags and tags then
  for _,tag in ipairs(tags) do
   if contains(tag,{"monster","enemy","monstro","inimigo","creature"}) then return true end
  end
 end

 for _,key in ipairs({"IsMonster","Monster","IsEnemy","Enemy","EntityType","NPCType","Role","CharacterType","MonsterName"}) do
  local value=model:GetAttribute(key)
  if value==true or (type(value)=="string" and contains(value,{"monster","monstro","enemy","inimigo","creature","entidade"})) then
   return true
  end
 end

 for _,child in ipairs(model:GetChildren()) do
  if contains(child.Name,{"monster","monstro","enemy","inimigo"}) then return true end
  for _,key in ipairs({"IsMonster","Monster","IsEnemy","Enemy","Role","MonsterName"}) do
   local value=child:GetAttribute(key)
   if value==true or (type(value)=="string" and contains(value,{"monster","monstro","enemy","inimigo"})) then
    return true
   end
  end
 end
 return false
end

local function getRarity(obj)
 for _,key in ipairs({"Rarity","Raridade"}) do
  local value=obj:GetAttribute(key)
  if type(value)=="string" then
   for rarity in pairs(rarityEnabled) do
    if value:lower()==rarity:lower() then return rarity end
   end
  end
 end
end

local function removeESP(obj)
 if highlights[obj] then highlights[obj]:Destroy(); highlights[obj]=nil end
 if labels[obj] then labels[obj]:Destroy(); labels[obj]=nil end
end

local function createESP(obj,color,textValue,small)
 if not obj or not obj.Parent then return end
 if not highlights[obj] then
  local h=Instance.new("Highlight")
  h.Name="TalesESP"
  h.Adornee=obj
  h.FillTransparency=0.85
  h.OutlineTransparency=0
  h.Parent=PlayerGui
  highlights[obj]=h
 end
 highlights[obj].OutlineColor=color
 highlights[obj].FillColor=color

 if not textValue then
  if labels[obj] then labels[obj]:Destroy(); labels[obj]=nil end
  return
 end

 local part=obj:IsA("BasePart") and obj or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
 if not part then return end

 if not labels[obj] then
  local bill=Instance.new("BillboardGui")
  bill.Name="TalesESPLabel"
  bill.AlwaysOnTop=true
  bill.Size=small and UDim2.fromOffset(155,24) or UDim2.fromOffset(185,30)
  bill.StudsOffset=Vector3.new(0,3,0)

  local txt=Instance.new("TextLabel")
  txt.Name="TextLabel"
  txt.Size=UDim2.fromScale(1,1)
  txt.BackgroundTransparency=1
  txt.TextScaled=true
  txt.Font=Enum.Font.GothamBold
  txt.TextStrokeTransparency=0.2
  txt.Parent=bill
  bill.Parent=PlayerGui
  labels[obj]=bill
 end

 labels[obj].Adornee=part
 labels[obj].TextLabel.Text=textValue
 labels[obj].TextLabel.TextColor3=color
end

local function refreshESP()
 local keep={}
 for _,obj in ipairs(Workspace:GetDescendants()) do
  if obj:IsA("Model") then
   -- A classificacao de monstro vem antes da classificacao de jogador.
   if isMonster(obj) then
    if states.ESPMonsters then
     createESP(obj,Color3.fromRGB(255,35,35),obj.Name,false)
     keep[obj]=true
    end
   else
    local plr=getPlayerFromModel(obj)
    if plr and plr~=player and states.ESPPlayers then
     createESP(obj,Color3.fromRGB(40,140,255),plr.Name,false)
     keep[obj]=true
    end
   end

   if states.ESPDucts and contains(obj.Name,{"duct","duto","vent"}) then
    local usable=false
    for _,d in ipairs(obj:GetDescendants()) do
     if d:IsA("ProximityPrompt") or (d:IsA("BasePart") and contains(d.Name,{"hatch","cover","lid","tampa","escotilha","entrada","entrance"})) then
      usable=true
      break
     end
    end
    if usable then
     createESP(obj,Color3.fromRGB(255,170,40),nil,true)
     keep[obj]=true
    end
   end
  end

  if obj:IsA("Model") or obj:IsA("BasePart") then
   local rarity=getRarity(obj)
   if rarity and rarityEnabled[rarity] and not (obj:IsA("Model") and isMonster(obj)) and not (obj.Parent and obj.Parent:IsA("Model") and isMonster(obj.Parent)) then
    local weight=obj:GetAttribute("Weight") or obj:GetAttribute("Peso") or "?"
    local price=obj:GetAttribute("Value") or obj:GetAttribute("Price") or obj:GetAttribute("Valor") or "?"
    createESP(obj,rarityColors[rarity],obj.Name.." | "..tostring(weight).." | $"..tostring(price),true)
    keep[obj]=true
   end
  end
 end

 for obj in pairs(highlights) do
  if not keep[obj] then removeESP(obj) end
 end
end

-- Portas: oculta partes nomeadas como porta. Dutos: somente a peca da tampa/escotilha,
-- nunca as paredes laterais do duto. O nome da tampa deve estar no proprio ancestral.
local function hidePart(part)
 if not part or not part:IsA("BasePart") then return end
 if not hiddenParts[part] then
  hiddenParts[part]={
   Transparency=part.Transparency,
   LocalTransparencyModifier=part.LocalTransparencyModifier,
   CanCollide=part.CanCollide,
   CanTouch=part.CanTouch,
   CanQuery=part.CanQuery
  }
 end
 part.LocalTransparencyModifier=1
 part.CanCollide=false
 part.CanTouch=false
 part.CanQuery=false
end

local function restoreDoors()
 for part,data in pairs(hiddenParts) do
  if part and part.Parent then
   pcall(function()
    part.Transparency=data.Transparency
    part.LocalTransparencyModifier=data.LocalTransparencyModifier
    part.CanCollide=data.CanCollide
    part.CanTouch=data.CanTouch
    part.CanQuery=data.CanQuery
   end)
  end
 end
 table.clear(hiddenParts)
end

local function isDoorPart(obj)
 local current=obj
 local context={}
 for _=1,8 do
  if not current then break end
  table.insert(context,current.Name)
  if contains(current.Name,{"fridge","refrigerator","geladeira","freezer","cooler"}) then return false end
  if contains(current.Name,{"door","porta","doorleaf","door_leaf","hingeddoor"}) then
   local joined=table.concat(context," "):lower()
   if joined:find("fridge",1,true) or joined:find("geladeira",1,true) or joined:find("freezer",1,true) then return false end
   return true
  end
  current=current.Parent
 end
 return false
end

local function isDuctCapPart(obj)
 local current=obj
 local inDuct,cap=false,false
 for _=1,8 do
  if not current then break end
  if contains(current.Name,{"duct","duto","vent"}) then inDuct=true end
  if contains(current.Name,{"hatch","cover","lid","tampa","escotilha","ductdoor","ventdoor"}) then cap=true end
  current=current.Parent
 end
 return inDuct and cap
end

local function setDoors(enabled)
 states.RemoveDoors=enabled
 if not enabled then restoreDoors(); return end
 for _,obj in ipairs(Workspace:GetDescendants()) do
  if obj:IsA("BasePart") and (isDoorPart(obj) or isDuctCapPart(obj)) then hidePart(obj) end
 end
end

local function setInstant(enabled)
 states.InstantCollection=enabled
 if enabled then
  for _,obj in ipairs(Workspace:GetDescendants()) do
   if obj:IsA("ProximityPrompt") then
    if savedPrompts[obj]==nil then savedPrompts[obj]=obj.HoldDuration end
    obj.HoldDuration=0
   end
  end
 else
  for obj,duration in pairs(savedPrompts) do
   if obj and obj.Parent then pcall(function() obj.HoldDuration=duration end) end
  end
  table.clear(savedPrompts)
 end
end

Workspace.DescendantAdded:Connect(function(obj)
 task.defer(function()
  if not obj or not obj.Parent then return end
  if states.RemoveDoors and obj:IsA("BasePart") and (isDoorPart(obj) or isDuctCapPart(obj)) then hidePart(obj) end
  if states.InstantCollection and obj:IsA("ProximityPrompt") then
   if savedPrompts[obj]==nil then savedPrompts[obj]=obj.HoldDuration end
   obj.HoldDuration=0
  end
 end)
end)

-- Coletor acumulativo: cada objeto/path e atualizado, nao apaga o historico a cada scan.
local function scanGame()
 scanCount+=1
 lastScan=os.date("%d/%m/%Y %H:%M:%S")
 local added,updated=0,0

 for _,obj in ipairs(Workspace:GetDescendants()) do
  if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("ProximityPrompt") then
   local ok,path=pcall(function() return obj:GetFullName() end)
   path=ok and path or obj.Name
   local key=obj.ClassName.."|"..path
   local entry={Name=obj.Name,Class=obj.ClassName,Path=path}
   local attrs=obj:GetAttributes()
   if next(attrs) then
    entry.Attributes={}
    for k,v in pairs(attrs) do entry.Attributes[k]=tostring(v) end
   end
   if obj:IsA("BasePart") then
    entry.Position=tostring(obj.Position)
    entry.CanCollide=tostring(obj.CanCollide)
   end

   if recordIndex[key] then
    records[recordIndex[key]]=entry
    updated+=1
   elseif #records<MAX_RECORDS then
    table.insert(records,entry)
    recordIndex[key]=#records
    added+=1
   end
   queueReport(entry,key)
  end
 end
 return added,updated
end

local function exportData()
 local out={
  "========================================",
  "ROUBE OU MORRA V16 - RELATORIO",
  "Feito por Tales",
  "Data: "..os.date("%d/%m/%Y %H:%M:%S"),
  "Tempo de coleta: "..math.floor(os.clock()-startTime).." segundos",
  "Varreduras: "..scanCount,
  "Registros acumulados: "..#records,
  "Ultima varredura: "..lastScan,
  "========================================"
 }

 for i,e in ipairs(records) do
  table.insert(out,"\nREGISTRO "..i)
  for k,v in pairs(e) do
   if type(v)=="table" then
    table.insert(out,tostring(k)..":")
    for sk,sv in pairs(v) do
     table.insert(out,"  "..tostring(sk).." = "..tostring(sv))
    end
   else
    table.insert(out,tostring(k)..": "..tostring(v))
   end
  end
 end

 if #records==0 then table.insert(out,"Nenhum registro coletado.") end
 return table.concat(out,"\n")
end

local function copyReport()
 local report=exportData()
 if reportBox then reportBox.Text=report end
 local clipboard
 pcall(function()
  if type(setclipboard)=="function" then clipboard=setclipboard
  elseif type(toclipboard)=="function" then clipboard=toclipboard end
 end)
 if clipboard then return pcall(clipboard,report) end
 return false
end

-- Brilho com restauracao dos valores originais.
local savedLighting={}
local function setBrightness(enabled)
 states.Brightness=enabled
 if enabled then
  savedLighting={
   Brightness=Lighting.Brightness,
   ClockTime=Lighting.ClockTime,
   GlobalShadows=Lighting.GlobalShadows,
   Ambient=Lighting.Ambient,
   OutdoorAmbient=Lighting.OutdoorAmbient
  }
  Lighting.Brightness=3
  Lighting.ClockTime=14
  Lighting.GlobalShadows=false
  Lighting.Ambient=Color3.fromRGB(200,200,200)
  Lighting.OutdoorAmbient=Color3.fromRGB(200,200,200)
 else
  for k,v in pairs(savedLighting) do pcall(function() Lighting[k]=v end) end
 end
end

-- AntiFlash local: desativa efeitos locais de flash/cegueira e sobreposicoes nomeadas.
-- Efeitos controlados pelo servidor podem ser recriados e nao sao garantidamente removidos.
local function effectLooksLikeFlash(obj)
 return contains(obj.Name,{"flash","blind","flashbang","clarão","stunflash","whiteout"})
end

local function setAntiFlash(enabled)
 states.AntiFlash=enabled
 if enabled then
  for _,root in ipairs({Lighting,Workspace.CurrentCamera,PlayerGui}) do
   if root then
    for _,obj in ipairs(root:GetDescendants()) do
     if (obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("ColorCorrectionEffect")) and effectLooksLikeFlash(obj) then
      if savedEffects[obj]==nil then savedEffects[obj]=obj.Enabled end
      pcall(function() obj.Enabled=false end)
     end
    end
   end
  end
 else
  for obj,value in pairs(savedEffects) do
   if obj and obj.Parent then pcall(function() obj.Enabled=value end) end
  end
  table.clear(savedEffects)
 end
end

-- Detecta efeitos de flash criados depois da ativacao sem tocar na interface da loja.
local flashWatcher
local function watchFlashRoot(root)
 if not root then return end
 root.DescendantAdded:Connect(function(obj)
  if states.AntiFlash and (obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect")) and effectLooksLikeFlash(obj) then
   if savedEffects[obj]==nil then savedEffects[obj]=obj.Enabled end
   pcall(function() obj.Enabled=false end)
  end
 end)
end
watchFlashRoot(Lighting)
watchFlashRoot(PlayerGui)

-- Stamina: sem nome/variavel oficial confirmado. Esta opcao apenas mostra diagnostico.
local function staminaReport()
 local found={}
 for _,obj in ipairs(player:GetDescendants()) do
  local n=obj.Name:lower()
  if n:find("stamina",1,true) or n:find("resist",1,true) or n:find("energia",1,true) or n:find("endurance",1,true) then
   local value=(obj:IsA("NumberValue") or obj:IsA("IntValue")) and tostring(obj.Value) or obj.ClassName
   table.insert(found,obj:GetFullName().." = "..value)
  end
 end
 return #found>0 and table.concat(found,"\n") or "Nenhum valor local de stamina/resistencia encontrado."
end

-- Auto farm limitado aos prompts dentro do alcance normal do personagem.
local farmGeneration=0
local function setAutoFarm(enabled)
 states.AutoFarm=enabled
 farmGeneration+=1
 local generation=farmGeneration
 if not enabled then return end
 task.spawn(function()
  while generation==farmGeneration and gui and gui.Parent do
   local char=player.Character
   local root=char and char:FindFirstChild("HumanoidRootPart")
   if root then
    for _,obj in ipairs(Workspace:GetDescendants()) do
     if generation~=farmGeneration then break end
     if obj:IsA("ProximityPrompt") and obj.Enabled then
      local part=obj.Parent
      if part and part:IsA("Attachment") then part=part.Parent end
      if part and part:IsA("BasePart") and (root.Position-part.Position).Magnitude<=obj.MaxActivationDistance then
       pcall(function()
        obj:InputHoldBegin()
        task.wait(0.12)
        obj:InputHoldEnd()
       end)
       task.wait(0.25)
      end
     end
    end
   end
   task.wait(0.45)
  end
 end)
end

--==============================================================
-- INTERFACE V15: PAGINAS ORGANIZADAS (nao painel simples V4)
--==============================================================
gui=Instance.new("ScreenGui")
gui.Name="RoubeOuMorraV16"
gui.ResetOnSpawn=false
gui.Parent=PlayerGui

local main=Instance.new("Frame")
main.Name="Main"
main.Size=UDim2.fromOffset(650,440)
main.Position=UDim2.new(0.5,-325,0.5,-220)
main.BackgroundColor3=Color3.fromRGB(17,17,21)
main.BorderSizePixel=0
main.Parent=gui
Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)

local stroke=Instance.new("UIStroke",main)
stroke.Color=Color3.fromRGB(125,20,30)
stroke.Thickness=1.5

local header=Instance.new("Frame")
header.Size=UDim2.new(1,0,0,48)
header.BackgroundColor3=Color3.fromRGB(105,15,25)
header.BorderSizePixel=0
header.Parent=main
Instance.new("UICorner",header).CornerRadius=UDim.new(0,12)

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-95,1,0)
title.Position=UDim2.fromOffset(16,0)
title.BackgroundTransparency=1
title.Text="ROUBE OU MORRA V16  |  Feito por Tales"
title.TextColor3=Color3.new(1,1,1)
title.Font=Enum.Font.GothamBold
title.TextSize=16
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=header

local minimize=Instance.new("TextButton")
minimize.Size=UDim2.fromOffset(38,34)
minimize.Position=UDim2.new(1,-44,0,7)
minimize.Text="—"
minimize.TextSize=22
minimize.Font=Enum.Font.GothamBold
minimize.TextColor3=Color3.new(1,1,1)
minimize.BackgroundColor3=Color3.fromRGB(65,12,20)
minimize.Parent=header
Instance.new("UICorner",minimize).CornerRadius=UDim.new(0,7)

local restore=Instance.new("TextButton")
restore.Size=UDim2.fromOffset(38,38)
restore.Position=UDim2.fromOffset(16,0.5)
restore.Text="R"
restore.TextColor3=Color3.new(1,1,1)
restore.Font=Enum.Font.GothamBold
restore.TextSize=15
restore.BackgroundColor3=Color3.fromRGB(135,18,30)
restore.Visible=false
restore.Parent=gui
Instance.new("UICorner",restore).CornerRadius=UDim.new(0,10)

local sidebar=Instance.new("Frame")
sidebar.Position=UDim2.fromOffset(10,58)
sidebar.Size=UDim2.new(0,150,1,-68)
sidebar.BackgroundColor3=Color3.fromRGB(23,23,28)
sidebar.BorderSizePixel=0
sidebar.Parent=main
Instance.new("UICorner",sidebar).CornerRadius=UDim.new(0,8)

local sideLayout=Instance.new("UIListLayout",sidebar)
sideLayout.Padding=UDim.new(0,7)
sideLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
sideLayout.SortOrder=Enum.SortOrder.LayoutOrder

local content=Instance.new("Frame")
content.Position=UDim2.fromOffset(170,58)
content.Size=UDim2.new(1,-180,1,-68)
content.BackgroundColor3=Color3.fromRGB(22,22,27)
content.BorderSizePixel=0
content.Parent=main
Instance.new("UICorner",content).CornerRadius=UDim.new(0,8)

local pages={}
local pageButtons={}
local currentPage

local function makePage(name)
 local page=Instance.new("ScrollingFrame")
 page.Name=name
 page.Size=UDim2.new(1,-16,1,-16)
 page.Position=UDim2.fromOffset(8,8)
 page.BackgroundTransparency=1
 page.BorderSizePixel=0
 page.ScrollBarThickness=4
 page.AutomaticCanvasSize=Enum.AutomaticSize.Y
 page.CanvasSize=UDim2.new()
 page.Visible=false
 page.Parent=content
 local list=Instance.new("UIListLayout",page)
 list.Padding=UDim.new(0,7)
 list.SortOrder=Enum.SortOrder.LayoutOrder
 pages[name]=page
 return page
end

local function showPage(name)
 currentPage=name
 for n,p in pairs(pages) do p.Visible=(n==name) end
 for n,b in pairs(pageButtons) do
  b.BackgroundColor3=(n==name) and Color3.fromRGB(135,22,36) or Color3.fromRGB(42,42,49)
 end
end

local function addSection(page,text)
 local label=Instance.new("TextLabel")
 label.Size=UDim2.new(1,-6,0,27)
 label.BackgroundColor3=Color3.fromRGB(65,18,26)
 label.TextColor3=Color3.fromRGB(255,220,220)
 label.Text=text
 label.Font=Enum.Font.GothamBold
 label.TextSize=13
 label.TextXAlignment=Enum.TextXAlignment.Left
 label.Parent=page
 Instance.new("UICorner",label).CornerRadius=UDim.new(0,5)
end

local function addButton(page,text,callback)
 local b=Instance.new("TextButton")
 b.Size=UDim2.new(1,-6,0,32)
 b.BackgroundColor3=Color3.fromRGB(43,43,50)
 b.TextColor3=Color3.new(1,1,1)
 b.Text=text
 b.TextSize=12
 b.Font=Enum.Font.Gotham
 b.Parent=page
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
 b.MouseButton1Click:Connect(callback)
 return b
end

local function addToggle(page,name,key,callback)
 local track,knob
 local b
 b=addButton(page,"  "..name,function()
  states[key]=not states[key]
  local on=states[key]
  b.BackgroundColor3=on and Color3.fromRGB(35,125,75) or Color3.fromRGB(43,43,50)
  track.BackgroundColor3=on and Color3.fromRGB(30,155,85) or Color3.fromRGB(90,90,98)
  knob.Position=on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
  if callback then
   local ok,err=pcall(callback,on)
   if not ok then warn("[V16] "..name..": "..tostring(err)) end
  end
 end)
 b.TextXAlignment=Enum.TextXAlignment.Left
 b.BackgroundColor3=Color3.fromRGB(43,43,50)

 track=Instance.new("Frame")
 track.Name="ToggleTrack"
 track.Size=UDim2.fromOffset(34,18)
 track.Position=UDim2.new(1,-44,0.5,-9)
 track.BackgroundColor3=Color3.fromRGB(90,90,98)
 track.BorderSizePixel=0
 track.Parent=b
 Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

 knob=Instance.new("Frame")
 knob.Name="ToggleKnob"
 knob.Size=UDim2.fromOffset(14,14)
 knob.Position=UDim2.new(0,2,0.5,-7)
 knob.BackgroundColor3=Color3.fromRGB(245,245,245)
 knob.BorderSizePixel=0
 knob.Parent=track
 Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
 return b
end

local function addNav(name)
 local b=Instance.new("TextButton")
 b.Size=UDim2.new(1,-12,0,36)
 b.BackgroundColor3=Color3.fromRGB(42,42,49)
 b.TextColor3=Color3.new(1,1,1)
 b.Text=name
 b.Font=Enum.Font.GothamBold
 b.TextSize=12
 b.Parent=sidebar
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
 b.MouseButton1Click:Connect(function() showPage(name) end)
 pageButtons[name]=b
end

local pMain=makePage("Principal")
local pESP=makePage("ESP")
local pEnv=makePage("Ambiente")
local pCollect=makePage("Coleta")
local pData=makePage("Dados")
local pConfig=makePage("Configurações")

for _,name in ipairs({"Principal","ESP","Ambiente","Coleta","Dados","Configurações"}) do
 addNav(name)
end

addSection(pMain,"RECURSOS PRINCIPAIS")
addToggle(pMain,"ESP Jogadores","ESPPlayers",refreshESP)
addToggle(pMain,"ESP Monstros","ESPMonsters",refreshESP)
addToggle(pMain,"ESP Dutos","ESPDucts",refreshESP)
addToggle(pMain,"Coleta Instantânea","InstantCollection",setInstant)
addToggle(pMain,"Brilho","Brightness",setBrightness)
addToggle(pMain,"Anti-Flash","AntiFlash",setAntiFlash)

addSection(pESP,"ESP DE JOGADORES E ENTIDADES")
addToggle(pESP,"ESP Jogadores","ESPPlayers",refreshESP)
addToggle(pESP,"ESP Monstros (prioridade vermelha)","ESPMonsters",refreshESP)
addToggle(pESP,"ESP Dutos","ESPDucts",refreshESP)

addSection(pESP,"ESP DE ITENS POR RARIDADE")
for _,rarity in ipairs({"Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret"}) do
 local b
 b=addButton(pESP,"ESP "..rarity.."  [OFF]",function()
  rarityEnabled[rarity]=not rarityEnabled[rarity]
  b.Text="ESP "..rarity..(rarityEnabled[rarity] and "  [ON]" or "  [OFF]")
  b.BackgroundColor3=rarityEnabled[rarity] and Color3.fromRGB(100,35,120) or Color3.fromRGB(43,43,50)
  refreshESP()
 end)
end

addSection(pEnv,"MAPA E VISIBILIDADE")
addToggle(pEnv,"Remover Portas e Tampas de Dutos","RemoveDoors",setDoors)
addToggle(pEnv,"Brilho","Brightness",setBrightness)
addToggle(pEnv,"Anti-Flash","AntiFlash",setAntiFlash)

addSection(pCollect,"COLETA")
addToggle(pCollect,"Coleta Instantânea","InstantCollection",setInstant)
addToggle(pCollect,"Auto Farm (prompts no alcance)","AutoFarm",setAutoFarm)

addSection(pData,"COLETOR AUTOMÁTICO DA PARTIDA")
addToggle(pData,"Coletor automático durante a partida","DataCollector",function(enabled)
 if enabled then
  local a,u=scanGame()
  flushReports()
  statusLabel.Text="Coleta ativa | Novos: "..a.." | Total: "..#records
 else
  statusLabel.Text="Coleta automática pausada"
 end
end)

statusLabel=Instance.new("TextLabel")
statusLabel.Size=UDim2.new(1,-6,0,28)
statusLabel.BackgroundTransparency=1
statusLabel.TextColor3=Color3.fromRGB(255,205,120)
statusLabel.Text="Coletor parado"
statusLabel.Font=Enum.Font.Gotham
statusLabel.TextSize=12
statusLabel.Parent=pData

reportBox=Instance.new("TextBox")
reportBox.Size=UDim2.new(1,-6,0,170)
reportBox.BackgroundColor3=Color3.fromRGB(10,10,13)
reportBox.TextColor3=Color3.new(1,1,1)
reportBox.PlaceholderText="O relatorio acumulado aparecera aqui..."
reportBox.Text=""
reportBox.TextSize=10
reportBox.TextWrapped=false
reportBox.TextXAlignment=Enum.TextXAlignment.Left
reportBox.TextYAlignment=Enum.TextYAlignment.Top
reportBox.ClearTextOnFocus=false
reportBox.MultiLine=true
reportBox.Parent=pData
Instance.new("UICorner",reportBox).CornerRadius=UDim.new(0,6)

addButton(pData,"COPIAR RELATÓRIO",function()
 reportBox.Text=exportData()
 if copyReport() then
  statusLabel.Text="Relatorio copiado para a area de transferencia"
 else
  statusLabel.Text="Clipboard indisponivel: selecione e copie o texto do campo"
 end
end)

addButton(pData,"LIMPAR RELATÓRIO",function()
 table.clear(records)
 table.clear(recordIndex)
 scanCount=0
 startTime=os.clock()
 lastScan="Nenhuma"
 reportBox.Text=""
 statusLabel.Text="Relatorio limpo"
end)

addSection(pConfig,"DIAGNÓSTICO E CONFIGURAÇÕES")
addButton(pConfig,"VERIFICAR VALORES DE STAMINA/RESISTÊNCIA",function()
 local report=staminaReport()
 reportBox.Text=report
 statusLabel.Text="Diagnostico local concluido (nao altera stamina)"
 showPage("Dados")
end)

addButton(pConfig,"RESTAURAR PORTAS E EFEITOS",function()
 setDoors(false)
 setAntiFlash(false)
 setBrightness(false)
 statusLabel.Text="Valores locais restaurados"
end)

addButton(pConfig,"FECHAR PAINEL",function() gui:Destroy() end)
showPage("Principal")

-- Arrastar janela pelo cabeçalho; minimizar/restaurar.
local dragging,dragStart,startPosition=false,nil,nil

header.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  dragging=true
  dragStart=input.Position
  startPosition=main.Position
 end
end)

UIS.InputChanged:Connect(function(input)
 if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
  local d=input.Position-dragStart
  main.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+d.X,startPosition.Y.Scale,startPosition.Y.Offset+d.Y)
 end
end)

UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  dragging=false
 end
end)

minimize.MouseButton1Click:Connect(function()
 main.Visible=false
 restore.Visible=true
end)

restore.MouseButton1Click:Connect(function()
 main.Visible=true
 restore.Visible=false
end)

-- Atualizacao periodica e coleta acumulativa durante a partida.
task.spawn(function()
 while gui.Parent do
  if states.ESPPlayers or states.ESPMonsters or states.ESPDucts or next(rarityEnabled) then
   refreshESP()
  end
  if states.RemoveDoors then
   for _,obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("BasePart") and (isDoorPart(obj) or isDuctCapPart(obj)) then hidePart(obj) end
   end
  end
  if states.AntiFlash then setAntiFlash(true) end
  if states.DataCollector then
   local a,u=scanGame()
   flushReports()
   if statusLabel and not sendBusy then
    statusLabel.Text="Coleta ativa | Novos: "..a.." | Total: "..#records.." | Pendentes: "..#sendQueue
   end
  end
  task.wait(states.DataCollector and 8 or 1.5)
 end
end)

gui.Destroying:Connect(function()
 farmGeneration+=1
 restoreDoors()
 setInstant(false)
 setBrightness(false)
 setAntiFlash(false)
 for obj in pairs(highlights) do removeESP(obj) end
 for obj,bill in pairs(labels) do
  if bill then bill:Destroy() end
  labels[obj]=nil
 end
end)

print("ROUBE OU MORRA V16 CARREGADO | Feito por Tales")
