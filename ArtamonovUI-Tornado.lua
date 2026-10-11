local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Настройки торнадо
local ts = {
    active = false,
    moving = false,
    radius = 150,
    strength = 15000,
    rotation = 8,
    lift = 800,
    speed = 4, -- Уменьшено по умолчанию для плавности (1-16)
    posX = 0,
    posZ = 0,
    currentX = 0,
    currentZ = 0
}

-- Границы карты (вычисляются автоматически при запуске)
local mapBounds = {
    minX = -1000, maxX = 1000,
    minZ = -1000, maxZ = 1000
}

task.spawn(function()
    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
    local count = 0
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and count < 6000 then
            local x, z = obj.Position.X, obj.Position.Z
            if x < minX then minX = x end
            if x > maxX then maxX = x end
            if z < minZ then minZ = z end
            if z > maxZ then maxZ = z end
            count = count + 1
        end
    end
    
    if minX ~= math.huge then
        mapBounds.minX = minX - 300
        mapBounds.maxX = maxX + 300
        mapBounds.minZ = minZ - 300
        mapBounds.maxZ = maxZ + 300
    end
    
    ts.posX = (mapBounds.minX + mapBounds.maxX) / 2
    ts.posZ = (mapBounds.minZ + mapBounds.maxZ) / 2
    ts.currentX = ts.posX
    ts.currentZ = ts.posZ
end)

local function worldToMap(wx, wz)
    local xScale = (wx - mapBounds.minX) / (mapBounds.maxX - mapBounds.minX)
    local zScale = (wz - mapBounds.minZ) / (mapBounds.maxZ - mapBounds.minZ)
    return math.clamp(xScale, 0, 1), math.clamp(zScale, 0, 1)
end

local function mapToWorld(xScale, zScale)
    local wx = mapBounds.minX + (xScale * (mapBounds.maxX - mapBounds.minX))
    local wz = mapBounds.minZ + (zScale * (mapBounds.maxZ - mapBounds.minZ))
    return wx, wz
end

-- ==========================================
-- GUI
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "ArtamonovUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Кнопка открытия (черная, перетаскиваемая)
local iconBtn = Instance.new("ImageButton")
iconBtn.Size = UDim2.new(0, 60, 0, 60)
iconBtn.Position = UDim2.new(0, 20, 0.5, -30)
iconBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
iconBtn.Image = "rbxassetid://127227153289873"
iconBtn.Parent = gui

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(0, 255, 0)
iconStroke.Thickness = 2
iconStroke.Parent = iconBtn

local draggingIcon = false
local dragStartIcon, startPosIcon

iconBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingIcon = true
        dragStartIcon = i.Position
        startPosIcon = iconBtn.Position
    end
end)

iconBtn.InputChanged:Connect(function(i)
    if draggingIcon and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStartIcon
        iconBtn.Position = UDim2.new(startPosIcon.X.Scale, startPosIcon.X.Offset + d.X, startPosIcon.Y.Scale, startPosIcon.Y.Offset + d.Y)
    end
end)

iconBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingIcon = false end
end)

-- Основное окно
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 580)
mainFrame.Position = UDim2.new(0, 90, 0.5, -290)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Visible = false
mainFrame.Parent = gui

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(0, 255, 0)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.FillDirection = Enum.FillDirection.Vertical
layout.Parent = mainFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = mainFrame

local function addTitle(text, size, bold)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, (size or 16))
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    lbl.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    lbl.TextSize = size or 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = mainFrame
end

local function addInput(labelText, defaultVal, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundTransparency = 1
    container.Parent = mainFrame
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.55, -5, 0, 24)
    box.Position = UDim2.new(0.45, 5, 0.5, -12)
    box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    box.Text = tostring(defaultVal)
    box.TextColor3 = Color3.fromRGB(0, 255, 0)
    box.Font = Enum.Font.Code
    box.TextSize = 11
    box.Parent = container
    
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(0, 255, 0)
    boxStroke.Thickness = 1
    boxStroke.Parent = box
    
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            callback(val)
        else
            box.Text = tostring(defaultVal)
        end
    end)
end

local function addToggle(text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundTransparency = 1
    container.Parent = mainFrame
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.65, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.35, -5, 0, 22)
    btn.Position = UDim2.new(0.65, 5, 0.5, -11)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
    btn.Text = default and "ВКЛ" or "ВЫКЛ"
    btn.TextColor3 = default and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = container
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(0, 255, 0)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        local newState = not default
        default = newState
        btn.BackgroundColor3 = newState and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        btn.Text = newState and "ВКЛ" or "ВЫКЛ"
        btn.TextColor3 = newState and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 0)
        callback(newState)
    end)
end

addTitle("ArtamonovUI * Скрипт Торнадо", 15, true)
addTitle("Создатель: ArtamonovHacker", 11, false)
addTitle("Настройки Торнадо", 13, true)

addInput("Расстояние", 150, function(v) ts.radius = v end)
addInput("Сила", 15000, function(v) ts.strength = v end)
addInput("Вращение", 8, function(v) ts.rotation = v end)
addInput("Подъём", 800, function(v) ts.lift = v end)
addInput("Скорость (1-16)", 4, function(v) ts.speed = math.clamp(v, 1, 16) end)

addTitle("Управление", 13, true)
addToggle("Вкл торнадо", false, function(v) ts.active = v end)
addToggle("Передвигание торнадо", false, function(v) ts.moving = v end)

addTitle("Карта (Клик для перемещения)", 13, true)
local mapFrame = Instance.new("Frame")
mapFrame.Size = UDim2.new(1, 0, 0, 160)
mapFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mapFrame.BackgroundTransparency = 0.8
mapFrame.Parent = mainFrame

local mapStroke = Instance.new("UIStroke")
mapStroke.Color = Color3.fromRGB(0, 255, 0)
mapStroke.Thickness = 1
mapStroke.Parent = mapFrame

local mapPartsFolder = Instance.new("Folder")
mapPartsFolder.Parent = mapFrame

-- Цвета опасности (Фиолетовый -> Голубой -> Желтый -> Оранжевый -> Красный -> Черный)
local dangerColors = {
    {0.15, Color3.fromRGB(128, 0, 128)}, 
    {0.35, Color3.fromRGB(0, 150, 255)},  
    {0.55, Color3.fromRGB(255, 255, 0)},  
    {0.75, Color3.fromRGB(255, 165, 0)},  
    {1.00, Color3.fromRGB(255, 50, 50)}     
}

for _, ring in ipairs(dangerColors) do
    local r = Instance.new("Frame")
    r.Size = UDim2.new(ring[1], 0, ring[1], 0)
    r.Position = UDim2.new(0.5 - ring[1]/2, 0, 0.5 - ring[1]/2, 0)
    r.BackgroundColor3 = ring[2]
    r.BackgroundTransparency = 0.7
    r.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = r
    r.Parent = mapFrame
end

local tornadoDot = Instance.new("Frame")
tornadoDot.Size = UDim2.new(0, 8, 0, 8)
tornadoDot.Position = UDim2.new(0.5, -4, 0.5, -4)
tornadoDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
tornadoDot.BorderSizePixel = 0
tornadoDot.ZIndex = 10
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = tornadoDot
tornadoDot.Parent = mapFrame

mapFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        local xScale = (i.Position.X - mapFrame.AbsolutePosition.X) / mapFrame.AbsoluteSize.X
        local yScale = (i.Position.Y - mapFrame.AbsolutePosition.Y) / mapFrame.AbsoluteSize.Y
        ts.posX, ts.posZ = mapToWorld(xScale, yScale)
    end
end)

-- Полноэкранная карта на Z
local fullMapFrame = Instance.new("Frame")
fullMapFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
fullMapFrame.Position = UDim2.new(0.2, 0, 0.15, 0)
fullMapFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
fullMapFrame.BackgroundTransparency = 0.3
fullMapFrame.Visible = false
fullMapFrame.ZIndex = 100
fullMapFrame.Parent = gui

local fmStroke = Instance.new("UIStroke")
fmStroke.Color = Color3.fromRGB(0, 255, 0)
fmStroke.Thickness = 3
fmStroke.Parent = fullMapFrame

local fmTitle = Instance.new("TextLabel")
fmTitle.Size = UDim2.new(1, 0, 0, 30)
fmTitle.BackgroundTransparency = 1
fmTitle.Text = "ГЛОБАЛЬНАЯ КАРТА (Нажми Z чтобы закрыть) | Кликни для перемещения"
fmTitle.TextColor3 = Color3.fromRGB(0, 255, 0)
fmTitle.Font = Enum.Font.GothamBold
fmTitle.TextSize = 16
fmTitle.Parent = fullMapFrame

local fmMapContainer = Instance.new("Frame")
fmMapContainer.Size = UDim2.new(1, -20, 1, -50)
fmMapContainer.Position = UDim2.new(0, 10, 0, 40)
fmMapContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
fmMapContainer.BackgroundTransparency = 0.8
fmMapContainer.Parent = fullMapFrame

local fmMapStroke = Instance.new("UIStroke")
fmMapStroke.Color = Color3.fromRGB(0, 255, 0)
fmMapStroke.Thickness = 1
fmMapStroke.Parent = fmMapContainer

local fmPartsFolder = Instance.new("Folder")
fmPartsFolder.Parent = fmMapContainer

local fmTornadoDot = Instance.new("Frame")
fmTornadoDot.Size = UDim2.new(0, 12, 0, 12)
fmTornadoDot.Position = UDim2.new(0.5, -6, 0.5, -6)
fmTornadoDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
fmTornadoDot.BorderSizePixel = 0
fmTornadoDot.ZIndex = 10
local fmDotCorner = Instance.new("UICorner")
fmDotCorner.CornerRadius = UDim.new(1, 0)
fmDotCorner.Parent = fmTornadoDot
fmTornadoDot.Parent = fmMapContainer

for _, ring in ipairs(dangerColors) do
    local r = Instance.new("Frame")
    r.Size = UDim2.new(ring[1], 0, ring[1], 0)
    r.Position = UDim2.new(0.5 - ring[1]/2, 0, 0.5 - ring[1]/2, 0)
    r.BackgroundColor3 = ring[2]
    r.BackgroundTransparency = 0.75
    r.BorderSizePixel = 0
    r.ZIndex = 5
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = r
    r.Parent = fmMapContainer
end

fmMapContainer.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        local xScale = (i.Position.X - fmMapContainer.AbsolutePosition.X) / fmMapContainer.AbsoluteSize.X
        local yScale = (i.Position.Y - fmMapContainer.AbsolutePosition.Y) / fmMapContainer.AbsoluteSize.Y
        ts.posX, ts.posZ = mapToWorld(xScale, yScale)
    end
end)

-- ==========================================
-- ВИЗУАЛ ТОРНАДО (3 слоя для плавности и красоты)
-- ==========================================
local innerVisual = Instance.new("Part")
innerVisual.Shape = Enum.PartType.Cylinder
innerVisual.Size = Vector3.new(4, 50, 4)
innerVisual.Orientation = Vector3.new(0, 0, 90)
innerVisual.Anchored = true
innerVisual.CanCollide = false
innerVisual.Transparency = 0.2
innerVisual.Color = Color3.fromRGB(220, 220, 220)
innerVisual.Material = Enum.Material.SmoothPlastic
innerVisual.Parent = workspace

local midVisual = Instance.new("Part")
midVisual.Shape = Enum.PartType.Cylinder
midVisual.Size = Vector3.new(8, 45, 8)
midVisual.Orientation = Vector3.new(0, 0, 90)
midVisual.Anchored = true
midVisual.CanCollide = false
midVisual.Transparency = 0.5
midVisual.Color = Color3.fromRGB(180, 180, 180)
midVisual.Material = Enum.Material.SmoothPlastic
midVisual.Parent = workspace

local outerVisual = Instance.new("Part")
outerVisual.Shape = Enum.PartType.Cylinder
outerVisual.Size = Vector3.new(14, 40, 14)
outerVisual.Orientation = Vector3.new(0, 0, 90)
outerVisual.Anchored = true
outerVisual.CanCollide = false
outerVisual.Transparency = 0.75
outerVisual.Color = Color3.fromRGB(130, 130, 130)
outerVisual.Material = Enum.Material.SmoothPlastic
outerVisual.Parent = workspace

local angle = 0
local midAngle = 0
local outerAngle = 0

-- ==========================================
-- ОБНОВЛЕНИЕ КАРТЫ (Каждые 0.1 секунды)
-- ==========================================
local function updateMapDots(folder)
    for _, child in ipairs(folder:GetChildren()) do
        child:Destroy()
    end
    
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if count > 350 then break end -- Оптимизация для 0.1с обновления
        if obj:IsA("BasePart") and not obj.Anchored then
            local isPlayer = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and obj:IsDescendantOf(p.Character) then
                    isPlayer = true
                    break
                end
            end
            
            if not isPlayer then
                local xScale, zScale = worldToMap(obj.Position.X, obj.Position.Z)
                if xScale >= 0 and xScale <= 1 and zScale >= 0 and zScale <= 1 then
                    -- Чем выше объект (Y), тем он светлее на карте
                    local brightness = math.clamp((obj.Position.Y + 50) / 300, 0.2, 1)
                    local dot = Instance.new("Frame")
                    dot.Size = UDim2.new(0, 3, 0, 3)
                    dot.Position = UDim2.new(xScale, -1.5, zScale, -1.5)
                    dot.BackgroundColor3 = Color3.fromRGB(brightness * 255, brightness * 255, brightness * 255)
                    dot.BorderSizePixel = 0
                    dot.ZIndex = 2
                    dot.Parent = folder
                    count = count + 1
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.1) -- Обновление каждые 0.1 секунды
        if mainFrame.Visible or fullMapFrame.Visible then
            updateMapDots(mapPartsFolder)
            updateMapDots(fmPartsFolder)
        end
    end
end)

-- ==========================================
-- ГЛАВНЫЙ ЦИКЛ (Физика и Движение)
-- ==========================================
RunService.Heartbeat:Connect(function(dt)
    if not ts.active then
        innerVisual.Transparency = 1
        midVisual.Transparency = 1
        outerVisual.Transparency = 1
        return
    end
    
    innerVisual.Transparency = 0.2
    midVisual.Transparency = 0.5
    outerVisual.Transparency = 0.75
    
    -- ПЛАВНОЕ ДВИЖЕНИЕ (Lerp) вместо рывков
    local targetX, targetZ = ts.posX, ts.posZ
    if ts.moving then
        targetX = mouse.Hit.X
        targetZ = mouse.Hit.Z
    end
    
    -- Плавная интерполяция позиции (скорость контролирует, как быстро торнадо догоняет цель)
    local lerpFactor = math.clamp(ts.speed * 0.03, 0.01, 0.2)
    ts.currentX = ts.currentX + (targetX - ts.currentX) * lerpFactor
    ts.currentZ = ts.currentZ + (targetZ - ts.currentZ) * lerpFactor
    
    -- Вращение слоев с разной скоростью для эффекта вихря
    angle = angle + ts.rotation * dt
    midAngle = midAngle + (ts.rotation * 0.7) * dt
    outerAngle = outerAngle + (ts.rotation * 0.4) * dt
    
    local cframe = CFrame.new(ts.currentX, 25, ts.currentZ)
    innerVisual.CFrame = cframe * CFrame.Angles(angle, 0, 0)
    midVisual.CFrame = cframe * CFrame.Angles(midAngle, 0, 0)
    outerVisual.CFrame = cframe * CFrame.Angles(outerAngle, 0, 0)
    
    -- Обновление точки на карте
    local dotX, dotZ = worldToMap(ts.currentX, ts.currentZ)
    tornadoDot.Position = UDim2.new(dotX, -4, dotZ, -4)
    fmTornadoDot.Position = UDim2.new(dotX, -6, dotZ, -6)
    
    -- ФИЗИКА ПРИТЯГИВАНИЯ (Оптимизированная)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excludeList = {player.Character, innerVisual, midVisual, outerVisual}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(excludeList, p.Character) end
    end
    params.FilterDescendantsInstances = excludeList
    
    local center = Vector3.new(ts.currentX, 25, ts.currentZ)
    local size = Vector3.new(ts.radius * 2, 100, ts.radius * 2)
    local parts = workspace:GetPartBoundsInBox(CFrame.new(center), size, params)
    
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and not part.Anchored then
            local pos = part.Position
            local dx = ts.currentX - pos.X
            local dz = ts.currentZ - pos.Z
            local dist = math.sqrt(dx*dx + dz*dz)
            
            if dist < ts.radius and dist > 0.5 then
                local dirX = dx / dist
                local dirZ = dz / dist
                
                -- Сила притяжения и закручивания
                local pull = ts.strength / (dist * 0.5)
                local rot = ts.rotation * 3
                
                local forceX = (dirX * pull) + (-dirZ * rot)
                local forceZ = (dirZ * pull) + (dirX * rot)
                local forceY = ts.lift / math.max(1, dist * 0.1)
                
                part.AssemblyLinearVelocity = part.AssemblyLinearVelocity + Vector3.new(forceX, forceY, forceZ) * dt
                
                -- Ограничение максимальной скорости, чтобы физика Roblox не сломалась
                local maxV = 200
                if part.AssemblyLinearVelocity.Magnitude > maxV then
                    part.AssemblyLinearVelocity = part.AssemblyLinearVelocity.Unit * maxV
                end
            end
        end
    end
end)

-- ==========================================
-- УПРАВЛЕНИЕ
-- ==========================================
iconBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.Z then
        fullMapFrame.Visible = not fullMapFrame.Visible
        if fullMapFrame.Visible then
            updateMapDots(fmPartsFolder)
        end
    end
end)

print("ArtamonovUI Скрипт Торнадо успешно загружен")
print("Создатель: ArtamonovHacker")