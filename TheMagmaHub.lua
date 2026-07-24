--[[
    ========MagmaHub========
    Powered by Maratichka's Lab(@Maratichka)
    
    OPTIMIZATION BY DEEPSEEK!!!(Some other functions too, xD), im to bad ssryD:
    
    Features:
    - Player: Speed, Jump, Fly, Sprint, Noclip, Infinity Jumps
    - FE Fling: SkidFling, usercheck, player list
    - ESP: Box, Tracer, Name, Skeleton, Chams
    - AIM: Circle Aim + Lock Aim with Prediction
    
    Palette: MagmaHub (#400b0b, #a12424, #ee7b06, #ffa904, #ffdb00)
    Device: Auto-detect (PC/Mobile)
    
    By: @Maratichka 
    Telegram: -soon-
   
    p.s. Комменты в коде на русском, мне лень писать на англе для юзеров
--]]

-- Подрубаем все сервисы, чтоб работало
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

-- Локальный игрок
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = Player:GetMouse()

-- Чекаем, с телефона зашли или с компа (мобилкам меню поменьше)
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local MenuHeight = IsMobile and 380 or 500

-- Всякие переменные, которые будут нужны потом
local StoredPosition = nil
local isFlinging = false
local isMinimized = false
local menuVisible = true

-- Настройки игрока (скорость, прыжки и тд)
local PlayerSettings = {
    Speed = 16,
    JumpPower = 50,
    InfinityJumps = false,
    FlyEnabled = false,
    FlySpeed = 50,
    FlyKey = Enum.KeyCode.Q,
    SprintEnabled = false,
    SprintSpeed = 25,
    SprintKey = Enum.KeyCode.LeftShift,
    NoclipEnabled = false
}

-- Флаги для управления флаем (WASD + E/C)
local FlyInputFlags = {
    forward = false,
    back = false,
    left = false,
    right = false,
    up = false,
    down = false
}

-- Объекты для флая и ноклипа
local FlyBodyVelocity = nil
local FlyBodyGyro = nil
local NoclipConnection = nil
local currentSprintBoost = 0
local InfinityJumpConnection = nil

-- Настройки AIM
local AimSettings = {
    Enabled = false,
    Mode = "Circle",
    CircleSize = "Medium",
    AimPart = "Head",
    PredictionEnabled = true,
    PredictionAmount = 10,
    TeamCheck = false
}

-- Размеры круга для Circle AIM
local CircleSizes = {
    Small = 80,
    Medium = 150,
    Large = 250
}

-- Настройки ESP
local ESPSettings = {
    Enabled = false,
    BoxESP = false,
    BoxColor = Color3.fromRGB(255, 169, 4),
    BoxThickness = 1,
    TracerESP = false,
    TracerOrigin = "Bottom",
    TracerColor = Color3.fromRGB(255, 169, 4),
    TracerThickness = 1,
    NameESP = false,
    NameColor = Color3.fromRGB(255, 219, 0),
    NameSize = 14,
    SkeletonESP = false,
    SkeletonColor = Color3.fromRGB(255, 169, 4),
    SkeletonThickness = 1.5,
    ChamsEnabled = false,
    ChamsFillColor = Color3.fromRGB(255, 0, 0),
    ChamsTransparency = 0.5,
    ChamsVisibleThroughWalls = true,
    TeamCheck = false,
    ShowTeam = false,
    MaxDistance = 1000
}

-- Цвета для выбора заливки Chams
local ChamsColors = {
    Red = Color3.fromRGB(255, 0, 0),
    Blue = Color3.fromRGB(0, 0, 255),
    Green = Color3.fromRGB(0, 255, 0),
    Yellow = Color3.fromRGB(255, 255, 0),
    Orange = Color3.fromRGB(255, 128, 0),
    Purple = Color3.fromRGB(128, 0, 255),
    Pink = Color3.fromRGB(255, 0, 128)
}

-- Таблицы для хранения ESP-объектов и Highlight'ов
local ESPDrawings = {}
local Highlights = {}

-- Круг для AIM (когда в Circle режиме)
local AimCircle = Drawing.new("Circle")
AimCircle.Visible = false
AimCircle.Color = Color3.fromRGB(255, 219, 0)
AimCircle.Thickness = 1.5
AimCircle.Transparency = 0.7
AimCircle.Filled = false
AimCircle.NumSides = 64

-- Палитра MagmaHub, пизже чем красный с черным
local C = {
    Bg = Color3.fromRGB(64, 11, 11),          -- #400b0b - Типо лавовый камень, фон
    Secondary = Color3.fromRGB(161, 36, 36),   -- #a12424 - Вторичный фон, секции
    Accent = Color3.fromRGB(255, 169, 4),      -- #ffa904 - Магма, кнопки активные
    AccentLight = Color3.fromRGB(255, 219, 0), -- #ffdb00 - Самое яркое, подсветка текста
    Border = Color3.fromRGB(238, 123, 6),      -- #ee7b06 - Обводки, слайдеры заполненные
    Text = Color3.fromRGB(255, 200, 100),      -- Светлый магмовый текст
    TextDark = Color3.fromRGB(200, 120, 50),   -- Тусклый текст для подписей
    OffColor = Color3.fromRGB(80, 25, 25),     -- Тоггл выключен (светлее чтоб видно было)
    OnColor = Color3.fromRGB(238, 123, 6),     -- Тоггл включен (#ee7b06)
    SliderBg = Color3.fromRGB(40, 12, 12),     -- Фон слайдера (пустая часть)
    SliderFill = Color3.fromRGB(255, 169, 4),  -- Заполнение слайдера (#ffa904)
    SectionBg = Color3.fromRGB(55, 18, 18)     -- Фон секций в плеере
}

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MagmaHub_GUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основной фрейм
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = C.Bg
MainFrame.BorderColor3 = C.Accent
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(0.25, 0, 0.15, 0)
MainFrame.Size = UDim2.new(0, 320, 0, MenuHeight)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Верхняя панель с названием и кнопками
local TitleBar = Instance.new("Frame")
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = C.Secondary
TitleBar.Size = UDim2.new(1, 0, 0, 35)
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TitleBar
TitleText.BackgroundTransparency = 1
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Font = Enum.Font.SourceSansBold
TitleText.Text = "MagmaHub"
TitleText.TextColor3 = C.AccentLight
TitleText.TextSize = 15
TitleText.TextXAlignment = Enum.TextXAlignment.Left

-- Кнопка свернуть
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Parent = TitleBar
MinimizeButton.BackgroundColor3 = C.Secondary
MinimizeButton.Position = UDim2.new(1, -65, 0.5, -10)
MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.Text = "─"
MinimizeButton.TextColor3 = C.TextDark
MinimizeButton.TextSize = 14
MinimizeButton.AutoButtonColor = false
Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 5)

-- Кнопка закрыть (крестик) - сбрасывает всё
local CloseButton = Instance.new("TextButton")
CloseButton.Parent = TitleBar
CloseButton.BackgroundColor3 = C.Accent
CloseButton.Position = UDim2.new(1, -36, 0.5, -10)
CloseButton.Size = UDim2.new(0, 22, 0, 22)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
CloseButton.AutoButtonColor = false
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 5)

-- Панель с вкладками
local TabFrame = Instance.new("Frame")
TabFrame.Parent = MainFrame
TabFrame.BackgroundTransparency = 1
TabFrame.Position = UDim2.new(0, 5, 0, 42)
TabFrame.Size = UDim2.new(1, -10, 0, 30)

local Tabs = {"Player", "FE Fling", "ESP/AIM"}
local TabButtons = {}
local ContentFrames = {}

-- Создаём вкладки и контент под них
for i, tabName in ipairs(Tabs) do
    local TabButton = Instance.new("TextButton")
    TabButton.Parent = TabFrame
    TabButton.BackgroundColor3 = C.Secondary
    TabButton.Size = UDim2.new(1/3 - 0.007, 0, 1, 0)
    TabButton.Position = UDim2.new((i-1)/3, 0, 0, 0)
    TabButton.Font = Enum.Font.SourceSansBold
    TabButton.Text = tabName
    TabButton.TextColor3 = C.TextDark
    TabButton.TextSize = 12
    TabButton.AutoButtonColor = false
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 6)
    TabButtons[tabName] = TabButton
    
    local Content = Instance.new("Frame")
    Content.Name = tabName .. "Content"
    Content.Parent = MainFrame
    Content.BackgroundTransparency = 1
    Content.Position = UDim2.new(0, 8, 0, 80)
    Content.Size = UDim2.new(1, -16, 1, -90)
    Content.Visible = (tabName == "Player")
    Content.ClipsDescendants = true
    ContentFrames[tabName] = Content
end

-- Переключение вкладок
local currentTab = "Player"
local function SwitchTab(tabName)
    if currentTab == tabName then return end
    ContentFrames[currentTab].Visible = false
    ContentFrames[tabName].Visible = true
    currentTab = tabName
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = C.Accent
            btn.TextColor3 = C.AccentLight
        else
            btn.BackgroundColor3 = C.Secondary
            btn.TextColor3 = C.TextDark
        end
    end
    -- Обновляем список игроков при открытии вкладки флинга
    if tabName == "FE Fling" then
        UpdatePlayerList()
    end
end

for tabName, button in pairs(TabButtons) do
    button.MouseButton1Click:Connect(function() SwitchTab(tabName) end)
end
TabButtons["Player"].BackgroundColor3 = C.Accent
TabButtons["Player"].TextColor3 = C.AccentLight

-- ==================== ВКЛАДКА PLAYER ====================
local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Parent = ContentFrames["Player"]
PlayerScroll.BackgroundTransparency = 1
PlayerScroll.Size = UDim2.new(1, 0, 1, 0)
PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 650)
PlayerScroll.ScrollBarThickness = 3
PlayerScroll.ScrollBarImageColor3 = C.Border

local py = 5

-- Создать коробочку (секцию) для элементов
local function CreateBox(parent, y, h)
    local box = Instance.new("Frame")
    box.Parent = parent
    box.BackgroundColor3 = C.SectionBg
    box.BorderColor3 = C.Border
    box.BorderSizePixel = 1
    box.Position = UDim2.new(0, 0, 0, y)
    box.Size = UDim2.new(1, 0, 0, h)
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    return box
end

-- Заголовок секции
local function CreateSectionHeader(parent, y, text)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 5, 0, y)
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Font = Enum.Font.SourceSansBold
    label.Text = text
    label.TextColor3 = C.AccentLight
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

-- Слайдер с перетягиванием, на телефоне тоже норм работает
local function CreateSlider(parent, y, label, minVal, maxVal, defaultVal, callback)
    local box = CreateBox(parent, y, 60)
    
    local header = Instance.new("Frame")
    header.Parent = box
    header.BackgroundTransparency = 1
    header.Position = UDim2.new(0, 10, 0, 6)
    header.Size = UDim2.new(1, -20, 0, 20)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = header
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = label
    nameLabel.TextColor3 = C.Text
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueBox = Instance.new("TextBox")
    valueBox.Parent = header
    valueBox.BackgroundColor3 = C.Secondary
    valueBox.BorderColor3 = C.Border
    valueBox.BorderSizePixel = 1
    valueBox.Position = UDim2.new(1, -50, 0, 0)
    valueBox.Size = UDim2.new(0, 50, 0, 20)
    valueBox.Font = Enum.Font.SourceSans
    valueBox.Text = tostring(defaultVal)
    valueBox.TextColor3 = C.AccentLight
    valueBox.TextSize = 12
    valueBox.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 5)
    
    -- Полоска слайдера
    local sliderBg = Instance.new("TextButton")
    sliderBg.Parent = box
    sliderBg.BackgroundColor3 = C.SliderBg
    sliderBg.BorderSizePixel = 0
    sliderBg.Position = UDim2.new(0, 10, 0, 34)
    sliderBg.Size = UDim2.new(1, -20, 0, 12)
    sliderBg.Text = ""
    sliderBg.AutoButtonColor = false
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 6)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderBg
    sliderFill.BackgroundColor3 = C.SliderFill
    sliderFill.BorderSizePixel = 0
    sliderFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.Active = false
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 6)
    
    local currentValue = defaultVal
    local dragging = false
    
    local function setValue(val)
        val = math.clamp(math.floor(val), minVal, maxVal)
        currentValue = val
        local percent = (val - minVal) / (maxVal - minVal)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        valueBox.Text = tostring(val)
        callback(val)
    end
    
    -- Захват слайдера (мышкой и пальцем)
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = sliderBg.AbsolutePosition
            local sliderSize = sliderBg.AbsoluteSize
            local percent = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
            setValue(minVal + (maxVal - minVal) * percent)
        end
    end)
    
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = sliderBg.AbsolutePosition
            local sliderSize = sliderBg.AbsoluteSize
            local percent = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
            setValue(minVal + (maxVal - minVal) * percent)
        end
    end)
    
    -- Ввод с клавиатуры
    valueBox.FocusLost:Connect(function()
        local num = tonumber(valueBox.Text)
        if num then setValue(num) else valueBox.Text = tostring(currentValue) end
    end)
    
    return {SetValue = function(v) setValue(v) end, GetValue = function() return currentValue end}
end

-- Тоггл (вкл/выкл)
local function CreateToggle(parent, y, text, default, callback)
    local box = CreateBox(parent, y, 34)
    
    local btn = Instance.new("TextButton")
    btn.Parent = box
    btn.BackgroundColor3 = default and C.OnColor or C.OffColor
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0, 10, 0.5, -10)
    btn.Size = UDim2.new(0, 20, 0, 20)
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local label = Instance.new("TextLabel")
    label.Parent = box
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 38, 0, 0)
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Font = Enum.Font.SourceSans
    label.Text = text
    label.TextColor3 = C.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local enabled = default
    
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.BackgroundColor3 = enabled and C.OnColor or C.OffColor
        callback(enabled)
    end)
    
    return {
        SetValue = function(v) enabled = v; btn.BackgroundColor3 = enabled and C.OnColor or C.OffColor end,
        GetValue = function() return enabled end
    }
end

-- Бинд-кнопка
local function CreateBind(parent, y, label, defaultKey, callback)
    local box = CreateBox(parent, y, 34)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = box
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.Size = UDim2.new(0, 80, 1, 0)
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.Text = label
    nameLabel.TextColor3 = C.TextDark
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local bindBtn = Instance.new("TextButton")
    bindBtn.Parent = box
    bindBtn.BackgroundColor3 = C.Secondary
    bindBtn.BorderColor3 = C.Border
    bindBtn.BorderSizePixel = 1
    bindBtn.Position = UDim2.new(1, -80, 0.5, -10)
    bindBtn.Size = UDim2.new(0, 70, 0, 20)
    bindBtn.Font = Enum.Font.SourceSans
    bindBtn.Text = defaultKey.Name
    bindBtn.TextColor3 = C.AccentLight
    bindBtn.TextSize = 11
    bindBtn.AutoButtonColor = false
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 5)
    
    local listening = false
    
    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "..."
        bindBtn.BackgroundColor3 = C.Accent
    end)
    
    -- Ждём нажатия клавиши
    UserInputService.InputBegan:Connect(function(input)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                bindBtn.Text = input.KeyCode.Name
                bindBtn.BackgroundColor3 = C.Secondary
                callback(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.Touch then
                listening = false
                bindBtn.Text = defaultKey.Name
                bindBtn.BackgroundColor3 = C.Secondary
            end
        end
    end)
end

-- === [Movement] ===
CreateSectionHeader(PlayerScroll, py, "[Movement]")
py = py + 22

CreateSlider(PlayerScroll, py, "Speed", 1, 500, 16, function(val)
    PlayerSettings.Speed = val
    ApplyCharacterSettings()
end)
py = py + 66

CreateSlider(PlayerScroll, py, "Jump Power", 1, 300, 50, function(val)
    PlayerSettings.JumpPower = val
    ApplyCharacterSettings()
end)
py = py + 66

CreateToggle(PlayerScroll, py, "Infinity Jumps", false, function(val)
    PlayerSettings.InfinityJumps = val
    if val then EnableInfinityJumps() else DisableInfinityJumps() end
end)
py = py + 40

CreateToggle(PlayerScroll, py, "Noclip", false, function(val)
    PlayerSettings.NoclipEnabled = val
    if val then EnableNoclip() else DisableNoclip() end
end)
py = py + 40

-- === [Fly] ===
CreateSectionHeader(PlayerScroll, py, "[Fly]")
py = py + 22

local FlyToggleRef = CreateToggle(PlayerScroll, py, "Enable Fly", false, function(val)
    PlayerSettings.FlyEnabled = val
    if val then EnableFly() else DisableFly() end
end)
py = py + 40

CreateSlider(PlayerScroll, py, "Fly Speed", 1, 500, 50, function(val)
    PlayerSettings.FlySpeed = val
end)
py = py + 66

CreateBind(PlayerScroll, py, "Fly Key:", PlayerSettings.FlyKey, function(key)
    PlayerSettings.FlyKey = key
end)
py = py + 40

-- === [Sprint] ===
CreateSectionHeader(PlayerScroll, py, "[Sprint]")
py = py + 22

local SprintToggleRef = CreateToggle(PlayerScroll, py, "Enable Sprint", false, function(val)
    PlayerSettings.SprintEnabled = val
    if not val then currentSprintBoost = 0; ApplyCharacterSettings() end
end)
py = py + 40

CreateSlider(PlayerScroll, py, "Sprint Speed (+)", 1, 100, 25, function(val)
    PlayerSettings.SprintSpeed = val
end)
py = py + 66

CreateBind(PlayerScroll, py, "Sprint Key:", PlayerSettings.SprintKey, function(key)
    PlayerSettings.SprintKey = key
end)
py = py + 46

PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, py)

-- ==================== ФУНКЦИИ ИГРОКА ====================
function ApplyCharacterSettings()
    if Player.Character then
        local humanoid = Player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = PlayerSettings.Speed + currentSprintBoost
            humanoid.UseJumpPower = true
            humanoid.JumpPower = PlayerSettings.JumpPower
        end
    end
end

function EnableInfinityJumps()
    if InfinityJumpConnection then InfinityJumpConnection:Disconnect() end
    InfinityJumpConnection = UserInputService.JumpRequest:Connect(function()
        if PlayerSettings.InfinityJumps and Player.Character then
            local humanoid = Player.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

function DisableInfinityJumps()
    if InfinityJumpConnection then
        InfinityJumpConnection:Disconnect()
        InfinityJumpConnection = nil
    end
end

function EnableFly()
    if not Player.Character then return end
    local rootPart = Player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
    if FlyBodyGyro then FlyBodyGyro:Destroy() end
    
    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    FlyBodyVelocity.Parent = rootPart
    
    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    FlyBodyGyro.CFrame = rootPart.CFrame
    FlyBodyGyro.Parent = rootPart
    
    local humanoid = Player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end
end

function DisableFly()
    if FlyBodyVelocity then FlyBodyVelocity:Destroy(); FlyBodyVelocity = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy(); FlyBodyGyro = nil end
    if Player.Character then
        local humanoid = Player.Character:FindFirstChild("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
end

function EnableNoclip()
    if NoclipConnection then NoclipConnection:Disconnect() end
    NoclipConnection = RunService.Stepped:Connect(function()
        if PlayerSettings.NoclipEnabled and Player.Character then
            for _, part in ipairs(Player.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end

function DisableNoclip()
    if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
    if Player.Character then
        for _, part in ipairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

-- Управление флаем (клавиши и мобильные кнопки)
local function handleFlyInput(input, isBegin)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == PlayerSettings.FlyKey then
            if isBegin then
                PlayerSettings.FlyEnabled = not PlayerSettings.FlyEnabled
                if PlayerSettings.FlyEnabled then EnableFly(); FlyToggleRef.SetValue(true)
                else DisableFly(); FlyToggleRef.SetValue(false) end
            end
            return
        end
        
        if PlayerSettings.FlyEnabled then
            local flags = {
                [Enum.KeyCode.W] = "forward",
                [Enum.KeyCode.S] = "back",
                [Enum.KeyCode.A] = "left",
                [Enum.KeyCode.D] = "right",
                [Enum.KeyCode.E] = "up",
                [Enum.KeyCode.C] = "down"
            }
            if flags[input.KeyCode] then
                FlyInputFlags[flags[input.KeyCode]] = isBegin
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then handleFlyInput(input, true) end
    
    if input.KeyCode == PlayerSettings.SprintKey and PlayerSettings.SprintEnabled then
        currentSprintBoost = PlayerSettings.SprintSpeed
        ApplyCharacterSettings()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    handleFlyInput(input, false)
    
    if input.KeyCode == PlayerSettings.SprintKey then
        currentSprintBoost = 0
        ApplyCharacterSettings()
    end
end)

-- Мобильные кнопки для флая (движение слева, высота справа)
if IsMobile then
    local function createMobileFlyButton(text, position, flag)
        local btn = Instance.new("TextButton")
        btn.Parent = ScreenGui
        btn.BackgroundColor3 = C.Border
        btn.BackgroundTransparency = 0.6
        btn.Position = position
        btn.Size = UDim2.new(0, 45, 0, 45)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 18
        btn.Font = Enum.Font.SourceSansBold
        btn.Visible = false
        btn.ZIndex = 10
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                FlyInputFlags[flag] = true
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                FlyInputFlags[flag] = false
            end
        end)
        
        return btn
    end
    
    -- Левая сторона: движение (WASD)
    local mobileFlyBtns = {
        createMobileFlyButton("▲", UDim2.new(0.08, -22, 0.40, -22), "forward"),
        createMobileFlyButton("▼", UDim2.new(0.08, -22, 0.60, -22), "back"),
        createMobileFlyButton("◄", UDim2.new(0.02, -22, 0.50, -22), "left"),
        createMobileFlyButton("►", UDim2.new(0.14, -22, 0.50, -22), "right"),
        createMobileFlyButton("⇧", UDim2.new(0.88, -22, 0.40, -22), "up"),
        createMobileFlyButton("⇩", UDim2.new(0.88, -22, 0.60, -22), "down"),
    }
    
    -- Показываем/прячем мобильные кнопки
    RunService.RenderStepped:Connect(function()
        for _, btn in ipairs(mobileFlyBtns) do
            btn.Visible = PlayerSettings.FlyEnabled and menuVisible
        end
    end)
end

-- Обновление флая каждый кадр
RunService.RenderStepped:Connect(function()
    if PlayerSettings.FlyEnabled and FlyBodyVelocity then
        local dir = Vector3.zero
        local camCF = Camera.CFrame
        
        if FlyInputFlags.forward then dir += camCF.LookVector end
        if FlyInputFlags.back then dir -= camCF.LookVector end
        if FlyInputFlags.left then dir -= camCF.RightVector end
        if FlyInputFlags.right then dir += camCF.RightVector end
        if FlyInputFlags.up then dir += Vector3.yAxis end
        if FlyInputFlags.down then dir -= Vector3.yAxis end
        
        if dir.Magnitude > 0 then dir = dir.Unit end
        
        FlyBodyVelocity.Velocity = dir * PlayerSettings.FlySpeed
        if FlyBodyGyro then FlyBodyGyro.CFrame = camCF end
    end
end)

-- При респавне заново применяем настройки
Player.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    ApplyCharacterSettings()
    if PlayerSettings.NoclipEnabled then EnableNoclip() end
    if PlayerSettings.InfinityJumps then EnableInfinityJumps() end
    if PlayerSettings.FlyEnabled then task.wait(0.3); EnableFly() end
end)

if Player.Character then ApplyCharacterSettings() end

-- ==================== ВКЛАДКА FE FLING ====================
local FlingScroll = Instance.new("ScrollingFrame")
FlingScroll.Parent = ContentFrames["FE Fling"]
FlingScroll.BackgroundTransparency = 1
FlingScroll.Size = UDim2.new(1, 0, 1, 0)
FlingScroll.CanvasSize = UDim2.new(0, 0, 0, 350)
FlingScroll.ScrollBarThickness = 3
FlingScroll.ScrollBarImageColor3 = C.Border

local FlingBox = CreateBox(FlingScroll, 5, 180)

local FlingTitle = Instance.new("TextLabel")
FlingTitle.Parent = FlingBox
FlingTitle.BackgroundTransparency = 1
FlingTitle.Position = UDim2.new(0, 0, 0, 8)
FlingTitle.Size = UDim2.new(1, 0, 0, 22)
FlingTitle.Font = Enum.Font.SourceSansBold
FlingTitle.Text = "FE Fling"
FlingTitle.TextColor3 = C.AccentLight
FlingTitle.TextSize = 16
FlingTitle.TextXAlignment = Enum.TextXAlignment.Center

local FlingHint = Instance.new("TextLabel")
FlingHint.Parent = FlingBox
FlingHint.BackgroundTransparency = 1
FlingHint.Position = UDim2.new(0, 0, 0, 30)
FlingHint.Size = UDim2.new(1, 0, 0, 16)
FlingHint.Font = Enum.Font.SourceSans
FlingHint.Text = "(select player below or type name)"
FlingHint.TextColor3 = C.TextDark
FlingHint.TextSize = 10
FlingHint.TextXAlignment = Enum.TextXAlignment.Center

local FlingInput = Instance.new("TextBox")
FlingInput.Parent = FlingBox
FlingInput.BackgroundColor3 = Color3.fromRGB(30, 8, 8)
FlingInput.BorderColor3 = C.AccentLight
FlingInput.BorderSizePixel = 1
FlingInput.Position = UDim2.new(0, 15, 0, 50)
FlingInput.Size = UDim2.new(1, -30, 0, 28)
FlingInput.Font = Enum.Font.SourceSans
FlingInput.PlaceholderText = "username..."
FlingInput.PlaceholderColor3 = C.TextDark
FlingInput.Text = ""
FlingInput.TextColor3 = C.AccentLight
FlingInput.TextSize = 14
Instance.new("UICorner", FlingInput).CornerRadius = UDim.new(0, 5)

-- Список игроков
local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Parent = FlingBox
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(40, 12, 12)
PlayerListFrame.BorderColor3 = C.Border
PlayerListFrame.BorderSizePixel = 1
PlayerListFrame.Position = UDim2.new(0, 15, 0, 84)
PlayerListFrame.Size = UDim2.new(1, -30, 0, 70)
PlayerListFrame.ScrollBarThickness = 3
PlayerListFrame.ScrollBarImageColor3 = C.Border
PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0, 5)

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Parent = PlayerListFrame
PlayerListLayout.SortOrder = Enum.SortOrder.Name
PlayerListLayout.Padding = UDim.new(0, 2)
PlayerListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Функция обновления списка игроков
function UpdatePlayerList()
    -- Очищаем старый список
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local anyPlayers = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            anyPlayers = true
            local playerBtn = Instance.new("TextButton")
            playerBtn.Parent = PlayerListFrame
            playerBtn.Size = UDim2.new(1, -4, 0, 22)
            playerBtn.BackgroundColor3 = C.Secondary
            playerBtn.BorderSizePixel = 0
            playerBtn.Text = p.DisplayName .. " (@" .. p.Name .. ")"
            playerBtn.TextColor3 = C.Text
            playerBtn.Font = Enum.Font.SourceSans
            playerBtn.TextSize = 12
            playerBtn.AutoButtonColor = false
            Instance.new("UICorner", playerBtn).CornerRadius = UDim.new(0, 4)
            
            playerBtn.MouseButton1Click:Connect(function()
                FlingInput.Text = p.Name
                -- Подсветка выбранного
                for _, b in ipairs(PlayerListFrame:GetChildren()) do
                    if b:IsA("TextButton") then b.BackgroundColor3 = C.Secondary end
                end
                playerBtn.BackgroundColor3 = C.Accent
            end)
        end
    end
    
    if not anyPlayers then
        local noPlayersLabel = Instance.new("TextLabel")
        noPlayersLabel.Parent = PlayerListFrame
        noPlayersLabel.Size = UDim2.new(1, 0, 0, 22)
        noPlayersLabel.BackgroundTransparency = 1
        noPlayersLabel.Text = "No players found"
        noPlayersLabel.TextColor3 = C.TextDark
        noPlayersLabel.Font = Enum.Font.SourceSans
        noPlayersLabel.TextSize = 12
    end
    
    PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, PlayerListLayout.AbsoluteContentSize.Y + 10)
end

-- Кнопка FLING
local FlingButton = Instance.new("TextButton")
FlingButton.Parent = FlingBox
FlingButton.BackgroundColor3 = C.Accent
FlingButton.Position = UDim2.new(0, 15, 0, 158)
FlingButton.Size = UDim2.new(1, -30, 0, 0)
FlingButton.Size = UDim2.new(1, -30, 0, 28)
FlingButton.Font = Enum.Font.SourceSansBold
FlingButton.Text = "FLING"
FlingButton.TextColor3 = C.Bg
FlingButton.TextSize = 16
FlingButton.AutoButtonColor = false
Instance.new("UICorner", FlingButton).CornerRadius = UDim.new(0, 5)

-- ==================== ВКЛАДКА ESP/AIM ====================
local ESPAIMScroll = Instance.new("ScrollingFrame")
ESPAIMScroll.Parent = ContentFrames["ESP/AIM"]
ESPAIMScroll.BackgroundTransparency = 1
ESPAIMScroll.Size = UDim2.new(1, 0, 1, 0)
ESPAIMScroll.CanvasSize = UDim2.new(0, 0, 0, 950)
ESPAIMScroll.ScrollBarThickness = 3
ESPAIMScroll.ScrollBarImageColor3 = C.Border
ESPAIMScroll.ZIndex = 5

local ey = 5

-- Заголовок секции для ESP/AIM
local function CreateESPSectionHeader(parent, y, text)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 5, 0, y)
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Font = Enum.Font.SourceSansBold
    label.Text = text
    label.TextColor3 = C.AccentLight
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    return label
end

-- Тоггл для ESP/AIM (в коробочке)
local function CreateESPToggle(parent, y, text, default, callback)
    local box = CreateBox(parent, y, 34)
    box.ZIndex = 5
    
    local enabled = default
    
    local btn = Instance.new("TextButton")
    btn.Parent = box
    btn.BackgroundColor3 = default and C.OnColor or C.OffColor
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0, 10, 0.5, -10)
    btn.Size = UDim2.new(0, 20, 0, 20)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 6
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local label = Instance.new("TextLabel")
    label.Parent = box
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 38, 0, 0)
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Font = Enum.Font.SourceSans
    label.Text = text
    label.TextColor3 = C.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 6
    
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.BackgroundColor3 = enabled and C.OnColor or C.OffColor
        callback(enabled)
    end)
    
    return {SetValue = function(v) enabled = v; btn.BackgroundColor3 = enabled and C.OnColor or C.OffColor end}
end

-- Дропдаун для ESP/AIM (в коробочке, фикс слоёв)
local function CreateESPDropdown(parent, y, text, options, default, callback)
    local box = CreateBox(parent, y, 55)
    box.ZIndex = 5
    
    local label = Instance.new("TextLabel")
    label.Parent = box
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 5)
    label.Size = UDim2.new(1, -20, 0, 16)
    label.Font = Enum.Font.SourceSans
    label.Text = text
    label.TextColor3 = C.TextDark
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 6
    
    local selected = default
    
    local mainBtn = Instance.new("TextButton")
    mainBtn.Parent = box
    mainBtn.BackgroundColor3 = C.Secondary
    mainBtn.BorderColor3 = C.Border
    mainBtn.BorderSizePixel = 1
    mainBtn.Position = UDim2.new(0, 10, 0, 23)
    mainBtn.Size = UDim2.new(1, -20, 0, 24)
    mainBtn.Font = Enum.Font.SourceSans
    mainBtn.Text = "  " .. selected
    mainBtn.TextColor3 = C.Text
    mainBtn.TextSize = 12
    mainBtn.TextXAlignment = Enum.TextXAlignment.Left
    mainBtn.AutoButtonColor = false
    mainBtn.ZIndex = 6
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 5)
    
    local arrow = Instance.new("TextLabel")
    arrow.Parent = mainBtn
    arrow.BackgroundTransparency = 1
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.Size = UDim2.new(0, 16, 1, 0)
    arrow.Font = Enum.Font.SourceSansBold
    arrow.Text = "▼"
    arrow.TextColor3 = C.TextDark
    arrow.TextSize = 9
    arrow.ZIndex = 7
    
    local dropdownList = Instance.new("Frame")
    dropdownList.Parent = box
    dropdownList.BackgroundColor3 = C.SectionBg
    dropdownList.BorderColor3 = C.Border
    dropdownList.BorderSizePixel = 1
    dropdownList.Position = UDim2.new(0, 10, 0, 47)
    dropdownList.Size = UDim2.new(1, -20, 0, #options * 22)
    dropdownList.Visible = false
    dropdownList.ZIndex = 99 -- Самый высокий Z, чтоб не перекрывался
    dropdownList.ClipsDescendants = true
    Instance.new("UICorner", dropdownList).CornerRadius = UDim.new(0, 5)
    
    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Parent = dropdownList
        optBtn.BackgroundColor3 = C.Secondary
        optBtn.BorderSizePixel = 0
        optBtn.Position = UDim2.new(0, 0, 0, (i-1) * 22)
        optBtn.Size = UDim2.new(1, 0, 0, 22)
        optBtn.Font = Enum.Font.SourceSans
        optBtn.Text = option
        optBtn.TextColor3 = C.Text
        optBtn.TextSize = 11
        optBtn.ZIndex = 100
        optBtn.AutoButtonColor = false
        
        optBtn.MouseButton1Click:Connect(function()
            selected = option
            mainBtn.Text = "  " .. selected
            dropdownList.Visible = false
            arrow.Text = "▼"
            for _, b in ipairs(dropdownList:GetChildren()) do
                if b:IsA("TextButton") then b.BackgroundColor3 = C.Secondary end
            end
            optBtn.BackgroundColor3 = C.Accent
            callback(option)
        end)
    end
    
    mainBtn.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
        arrow.Text = dropdownList.Visible and "▲" or "▼"
    end)
end

-- === [ESP] ===
CreateESPSectionHeader(ESPAIMScroll, ey, "[ESP]")
ey = ey + 22

CreateESPToggle(ESPAIMScroll, ey, "Enable ESP", false, function(val)
    ESPSettings.Enabled = val
    if val then for _, p in ipairs(Players:GetPlayers()) do if p ~= Player then CreateESP(p) end end
    else for _, p in ipairs(Players:GetPlayers()) do RemoveESP(p) end end
end)
ey = ey + 40

-- === [Box] ===
CreateESPSectionHeader(ESPAIMScroll, ey, "[Box]")
ey = ey + 22

CreateESPToggle(ESPAIMScroll, ey, "Box ESP", false, function(val) ESPSettings.BoxESP = val end)
ey = ey + 40

-- === [Tracer] ===
CreateESPSectionHeader(ESPAIMScroll, ey, "[Tracer]")
ey = ey + 22

CreateESPToggle(ESPAIMScroll, ey, "Tracer ESP", false, function(val) ESPSettings.TracerESP = val end)
ey = ey + 40

CreateESPDropdown(ESPAIMScroll, ey, "Tracer Origin", {"Bottom", "Top", "Center"}, "Bottom", function(val) ESPSettings.TracerOrigin = val end)
ey = ey + 61

-- === [Names] ===
CreateESPSectionHeader(ESPAIMScroll, ey, "[Names]")
ey = ey + 22

CreateESPToggle(ESPAIMScroll, ey, "Name ESP", false, function(val) ESPSettings.NameESP = val end)
ey = ey + 40

CreateESPToggle(ESPAIMScroll, ey, "Skeleton ESP", false, function(val) ESPSettings.SkeletonESP = val end)
ey = ey + 40

-- === [Chams] ===
CreateESPSectionHeader(ESPAIMScroll, ey, "[Chams]")
ey = ey + 22

CreateESPToggle(ESPAIMScroll, ey, "Enable Chams", false, function(val)
    ESPSettings.ChamsEnabled = val
    for p, h in pairs(Highlights) do h.Enabled = val end
end)
ey = ey + 40

CreateESPDropdown(ESPAIMScroll, ey, "Fill Color", {"Red", "Blue", "Green", "Yellow", "Orange", "Purple", "Pink"}, "Red", function(val)
    ESPSettings.ChamsFillColor = ChamsColors[val]
    for p, h in pairs(Highlights) do h.FillColor = ChamsColors[val] end
end)
ey = ey + 61

CreateESPToggle(ESPAIMScroll, ey, "Through Walls", true, function(val)
    ESPSettings.ChamsVisibleThroughWalls = val
    for p, h in pairs(Highlights) do
        h.DepthMode = val and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    end
end)
ey = ey + 40

CreateESPToggle(ESPAIMScroll, ey, "Team Check", false, function(val) ESPSettings.TeamCheck = val end)
ey = ey + 46

-- === [AIM] ===
CreateESPSectionHeader(ESPAIMScroll, ey, "[AIM]")
ey = ey + 22

CreateESPToggle(ESPAIMScroll, ey, "Enable AIM", false, function(val)
    AimSettings.Enabled = val
    AimCircle.Visible = val and AimSettings.Mode == "Circle"
end)
ey = ey + 40

CreateESPDropdown(ESPAIMScroll, ey, "AIM Mode", {"Circle", "Lock"}, "Circle", function(val)
    AimSettings.Mode = val
    AimCircle.Visible = AimSettings.Enabled and val == "Circle"
end)
ey = ey + 61

CreateESPDropdown(ESPAIMScroll, ey, "Circle Size", {"Small", "Medium", "Large"}, "Medium", function(val) AimSettings.CircleSize = val end)
ey = ey + 61

CreateESPDropdown(ESPAIMScroll, ey, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(val) AimSettings.AimPart = val end)
ey = ey + 61

CreateESPToggle(ESPAIMScroll, ey, "Prediction", true, function(val) AimSettings.PredictionEnabled = val end)
ey = ey + 40

CreateESPToggle(ESPAIMScroll, ey, "Team Check (AIM)", false, function(val) AimSettings.TeamCheck = val end)
ey = ey + 20

ESPAIMScroll.CanvasSize = UDim2.new(0, 0, 0, ey)

-- ==================== ESP ФУНКЦИИ ====================
function CreateESP(targetPlayer)
    if targetPlayer == Player or ESPDrawings[targetPlayer] then return end
    
    local drawings = {
        Box = {
            Left = Drawing.new("Line"), Right = Drawing.new("Line"),
            Top = Drawing.new("Line"), Bottom = Drawing.new("Line")
        },
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Skeleton = {
            Head = Drawing.new("Line"), LeftArm = Drawing.new("Line"),
            RightArm = Drawing.new("Line"), LeftLeg = Drawing.new("Line"),
            RightLeg = Drawing.new("Line")
        }
    }
    
    for _, line in pairs(drawings.Box) do
        line.Visible = false; line.Color = ESPSettings.BoxColor; line.Thickness = ESPSettings.BoxThickness
    end
    drawings.Tracer.Visible = false; drawings.Tracer.Color = ESPSettings.TracerColor; drawings.Tracer.Thickness = ESPSettings.TracerThickness
    drawings.Name.Visible = false; drawings.Name.Color = ESPSettings.NameColor; drawings.Name.Size = ESPSettings.NameSize
    drawings.Name.Font = 2; drawings.Name.Center = true; drawings.Name.Outline = true
    for _, line in pairs(drawings.Skeleton) do
        line.Visible = false; line.Color = ESPSettings.SkeletonColor; line.Thickness = ESPSettings.SkeletonThickness
    end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESPSettings.ChamsFillColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = ESPSettings.ChamsVisibleThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.Enabled = ESPSettings.ChamsEnabled
    Highlights[targetPlayer] = highlight
    ESPDrawings[targetPlayer] = drawings
end

function RemoveESP(targetPlayer)
    local drawings = ESPDrawings[targetPlayer]
    if drawings then
        for _, line in pairs(drawings.Box) do line:Remove() end
        drawings.Tracer:Remove(); drawings.Name:Remove()
        for _, line in pairs(drawings.Skeleton) do line:Remove() end
        ESPDrawings[targetPlayer] = nil
    end
    local highlight = Highlights[targetPlayer]
    if highlight then highlight:Destroy(); Highlights[targetPlayer] = nil end
end

function HideAllESP(drawings)
    for _, line in pairs(drawings.Box) do line.Visible = false end
    drawings.Tracer.Visible = false; drawings.Name.Visible = false
    for _, line in pairs(drawings.Skeleton) do line.Visible = false end
end

-- ESP обновляется каждый кадр, если включено
-- Дальше 1000 studs не рисуем, ибо смысла нет и лагает
function UpdateESP(targetPlayer)
    if not ESPSettings.Enabled then return end
    local drawings = ESPDrawings[targetPlayer]
    if not drawings then return end
    
    local character = targetPlayer.Character
    if not character then HideAllESP(drawings); return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid or humanoid.Health <= 0 then HideAllESP(drawings); return end
    
    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if not onScreen or distance > ESPSettings.MaxDistance then HideAllESP(drawings); return end
    
    if ESPSettings.TeamCheck and targetPlayer.Team == Player.Team and not ESPSettings.ShowTeam then
        HideAllESP(drawings); return
    end
    
    local size = character:GetExtentsSize()
    local cf = rootPart.CFrame
    local top = Camera:WorldToViewportPoint((cf * CFrame.new(0, size.Y/2, 0)).Position)
    local bottom = Camera:WorldToViewportPoint((cf * CFrame.new(0, -size.Y/2, 0)).Position)
    local screenSize = math.abs(bottom.Y - top.Y)
    local boxWidth = screenSize * 0.65
    local boxPos = Vector2.new(top.X - boxWidth/2, top.Y)
    
    -- Box
    if ESPSettings.BoxESP then
        drawings.Box.Left.From = boxPos; drawings.Box.Left.To = boxPos + Vector2.new(0, screenSize)
        drawings.Box.Right.From = boxPos + Vector2.new(boxWidth, 0); drawings.Box.Right.To = boxPos + Vector2.new(boxWidth, screenSize)
        drawings.Box.Top.From = boxPos; drawings.Box.Top.To = boxPos + Vector2.new(boxWidth, 0)
        drawings.Box.Bottom.From = boxPos + Vector2.new(0, screenSize); drawings.Box.Bottom.To = boxPos + Vector2.new(boxWidth, screenSize)
        for _, line in pairs(drawings.Box) do line.Visible = true; line.Color = ESPSettings.BoxColor; line.Thickness = ESPSettings.BoxThickness end
    else for _, line in pairs(drawings.Box) do line.Visible = false end end
    
    -- Tracer
    if ESPSettings.TracerESP then
        local origin = ESPSettings.TracerOrigin == "Bottom" and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            or ESPSettings.TracerOrigin == "Top" and Vector2.new(Camera.ViewportSize.X/2, 0)
            or Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        drawings.Tracer.From = origin; drawings.Tracer.To = Vector2.new(pos.X, pos.Y); drawings.Tracer.Visible = true
    else drawings.Tracer.Visible = false end
    
    -- Name
    if ESPSettings.NameESP then
        drawings.Name.Text = targetPlayer.DisplayName
        drawings.Name.Position = Vector2.new(boxPos.X + boxWidth/2, boxPos.Y - 18)
        drawings.Name.Visible = true
    else drawings.Name.Visible = false end
    
    -- Skeleton
    if ESPSettings.SkeletonESP and distance < 500 then
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        local leftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
        local rightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
        local leftLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg")
        local rightLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
        
        local function drawBone(fromPart, toPart, line)
            if fromPart and toPart then
                local fp, fv = Camera:WorldToViewportPoint(fromPart.Position)
                local tp, tv = Camera:WorldToViewportPoint(toPart.Position)
                if fv and tv and fp.Z > 0 and tp.Z > 0 then
                    line.From = Vector2.new(fp.X, fp.Y); line.To = Vector2.new(tp.X, tp.Y)
                    line.Visible = true; return
                end
            end
            line.Visible = false
        end
        
        if head and torso then
            drawBone(head, torso, drawings.Skeleton.Head)
            if leftArm then drawBone(torso, leftArm, drawings.Skeleton.LeftArm) end
            if rightArm then drawBone(torso, rightArm, drawings.Skeleton.RightArm) end
            if leftLeg then drawBone(torso, leftLeg, drawings.Skeleton.LeftLeg) end
            if rightLeg then drawBone(torso, rightLeg, drawings.Skeleton.RightLeg) end
        end
    else for _, line in pairs(drawings.Skeleton) do line.Visible = false end end
    
    -- Highlight (Chams через стены, чтоб видеть крыс в углах)
    local highlight = Highlights[targetPlayer]
    if highlight then
        highlight.Parent = character
        highlight.Enabled = ESPSettings.ChamsEnabled
        if ESPSettings.ChamsEnabled then
            highlight.FillColor = ESPSettings.ChamsFillColor
            highlight.FillTransparency = ESPSettings.ChamsTransparency
            highlight.DepthMode = ESPSettings.ChamsVisibleThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        end
    end
end

-- ==================== AIM ФУНКЦИИ ====================
function GetAimTarget()
    local target = nil
    local shortestDistance = AimSettings.Mode == "Circle" and CircleSizes[AimSettings.CircleSize] or math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            local aimPart = otherPlayer.Character:FindFirstChild(AimSettings.AimPart)
            if aimPart and not (AimSettings.TeamCheck and otherPlayer.Team == Player.Team) then
                local pos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen and pos.Z > 0 then
                    local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if dist < shortestDistance then shortestDistance = dist; target = otherPlayer end
                end
            end
        end
    end
    return target
end

function AimAt(target)
    if not target or not target.Character then return end
    local aimPart = target.Character:FindFirstChild(AimSettings.AimPart)
    if not aimPart then return end
    local targetPos = aimPart.Position
    if AimSettings.PredictionEnabled and aimPart.Velocity then
        targetPos += aimPart.Velocity / AimSettings.PredictionAmount
    end
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
end

-- ==================== FLING ФУНКЦИИ ====================
function FindPlayer(Name)
    Name = Name:lower()
    for _, Target in ipairs(Players:GetPlayers()) do
        if Target ~= Player then
            if Target.Name:lower():match("^" .. Name) or Target.DisplayName:lower():match("^" .. Name) then
                return Target
            end
        end
    end
    return nil
end

-- Флинг на 2 сек, потом возращает тебя обратно
-- Если жертва сдохла или вышла — флинг сбрасывается
function SkidFling(TargetPlayer)
    local Character = Player.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    if not RootPart then return end
    
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    if not TRootPart and not THead then return end
    
    if THead then Camera.CameraSubject = THead elseif THumanoid and TRootPart then Camera.CameraSubject = THumanoid end
    
    local OldPos = RootPart.CFrame
    local OldFPDH = Workspace.FallenPartsDestroyHeight
    Workspace.FallenPartsDestroyHeight = 0/0
    
    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart; BV.Velocity = Vector3.new(9e8, 9e8, 9e8); BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    
    local function FPos(BasePart, Pos, Ang)
        pcall(function()
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end)
    end
    
    local BasePart = TRootPart or THead
    if TRootPart and THead then BasePart = (TRootPart.Position - THead.Position).Magnitude > 5 and THead or TRootPart end
    
    local TimeToWait = 2
    local StartTime = tick()
    local Angle = 0
    
    -- Глобальный таймаут 7 секунд, чтоб флинг не зацикливался
    local globalTimeout = 7
    local flingStart = tick()
    
    repeat
        if tick() - flingStart > globalTimeout then break end
        
        if RootPart and THumanoid and BasePart then
            if BasePart.Velocity.Magnitude < 50 then
                Angle += 100
                for _, offset in ipairs({CFrame.new(0, 1.5, 0), CFrame.new(0, -1.5, 0), CFrame.new(2.25, 1.5, -2.25), CFrame.new(-2.25, -1.5, 2.25), CFrame.new(0, 1.5, 0), CFrame.new(0, -1.5, 0)}) do
                    FPos(BasePart, offset + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                end
            else
                for _, off in ipairs({{CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)}, {CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0)}, {CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)}, {CFrame.new(0, 1.5, TRootPart and TRootPart.Velocity.Magnitude / 1.25 or 100), CFrame.Angles(math.rad(90), 0, 0)}, {CFrame.new(0, -1.5, TRootPart and -TRootPart.Velocity.Magnitude / 1.25 or -100), CFrame.Angles(0, 0, 0)}, {CFrame.new(0, 1.5, TRootPart and TRootPart.Velocity.Magnitude / 1.25 or 100), CFrame.Angles(math.rad(90), 0, 0)}, {CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0)}, {CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)}, {CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0)}, {CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)}}) do
                    FPos(BasePart, off[1], off[2]); task.wait()
                end
            end
        else break end
    until BasePart.Velocity.Magnitude > 500 or not BasePart.Parent or BasePart.Parent ~= TCharacter or TargetPlayer.Parent ~= Players or Humanoid.Health <= 0 or tick() > StartTime + TimeToWait
    
    if BV then BV:Destroy() end
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    Camera.CameraSubject = Humanoid
    
    -- Возвращаем игрока обратно, даже если флинг прервался
    if OldPos then
        repeat
            pcall(function()
                RootPart.CFrame = OldPos * CFrame.new(0, 0.5, 0)
                Character:SetPrimaryPartCFrame(OldPos * CFrame.new(0, 0.5, 0))
                Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                for _, Part in ipairs(Character:GetChildren()) do
                    if Part:IsA("BasePart") then Part.Velocity = Vector3.new(); Part.RotVelocity = Vector3.new() end
                end
            end)
            task.wait()
        until (RootPart.Position - OldPos.Position).Magnitude < 25
    end
    Workspace.FallenPartsDestroyHeight = OldFPDH
    isFlinging = false
    FlingButton.Text = "FLING"
    FlingButton.BackgroundColor3 = C.Accent
end

-- ==================== ОБРАБОТЧИКИ СОБЫТИЙ ====================
FlingButton.MouseButton1Click:Connect(function()
    if isFlinging then return end
    local TargetName = FlingInput.Text
    if TargetName == "" then StarterGui:SetCore("SendNotification", {Title = "MagmaHub", Text = "Введи имя или выбери из списка!", Duration = 3}); return end
    local Target = FindPlayer(TargetName)
    if not Target then StarterGui:SetCore("SendNotification", {Title = "MagmaHub", Text = "Игрок не найден!", Duration = 3}); return end
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        StoredPosition = Player.Character.HumanoidRootPart.CFrame
    end
    isFlinging = true
    FlingButton.Text = "FLINGING..."
    FlingButton.BackgroundColor3 = C.AccentLight
    task.spawn(function() SkidFling(Target) end)
end)

FlingInput.FocusLost:Connect(function(ep) if ep then FlingButton.MouseButton1Click:Fire() end end)

-- Кнопка свернуть (сохраняет позицию, не открывается при перетаскивании)
local FloatBtn = nil
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = true
    local savedPos = MainFrame.Position
    MainFrame.Visible = false
    
    if FloatBtn then FloatBtn:Destroy() end
    FloatBtn = Instance.new("TextButton")
    FloatBtn.Name = "FloatButton"
    FloatBtn.Parent = ScreenGui
    FloatBtn.BackgroundColor3 = C.Accent
    FloatBtn.Position = UDim2.new(savedPos.X.Scale, savedPos.X.Offset + 140, savedPos.Y.Scale, savedPos.Y.Offset)
    FloatBtn.Size = UDim2.new(0, 40, 0, 40)
    FloatBtn.Font = Enum.Font.SourceSansBold
    FloatBtn.Text = "M"
    FloatBtn.TextColor3 = C.Bg
    FloatBtn.TextSize = 18
    FloatBtn.ZIndex = 100
    FloatBtn.AutoButtonColor = false
    Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 8)
    
    local dragStartPos = nil
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    FloatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = FloatBtn.Position
            dragStartPos = input.Position
        end
    end)
    
    FloatBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            FloatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    FloatBtn.InputEnded:Connect(function(input)
        if dragStartPos and input.Position then
            local dist = (input.Position - dragStartPos).Magnitude
            if dist < 10 then
                isMinimized = false
                MainFrame.Position = savedPos
                MainFrame.Visible = true
                FloatBtn:Destroy()
                FloatBtn = nil
            end
        end
        dragging = false
        dragStartPos = nil
    end)
end)

-- Кнопка закрыть (крестик) - сбрасывает всё
CloseButton.MouseButton1Click:Connect(function()
    DisableFly(); DisableNoclip(); DisableInfinityJumps()
    for _, p in ipairs(Players:GetPlayers()) do RemoveESP(p) end
    AimCircle:Remove()
    if FloatBtn then FloatBtn:Destroy() end
    ScreenGui:Destroy()
end)

-- Ховер-эффекты
MinimizeButton.MouseEnter:Connect(function() MinimizeButton.BackgroundColor3 = C.Border end)
MinimizeButton.MouseLeave:Connect(function() MinimizeButton.BackgroundColor3 = C.Secondary end)
CloseButton.MouseEnter:Connect(function() CloseButton.BackgroundColor3 = C.AccentLight end)
CloseButton.MouseLeave:Connect(function() CloseButton.BackgroundColor3 = C.Accent end)
FlingButton.MouseEnter:Connect(function() if not isFlinging then FlingButton.BackgroundColor3 = C.AccentLight end end)
FlingButton.MouseLeave:Connect(function() if not isFlinging then FlingButton.BackgroundColor3 = C.Accent end end)

-- L Alt скрыть/показать меню
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        if isMinimized and FloatBtn then
            isMinimized = false
            MainFrame.Visible = true
            FloatBtn:Destroy()
            FloatBtn = nil
        else
            menuVisible = not menuVisible
            MainFrame.Visible = menuVisible
        end
    end
end)

-- AIM захват мыши
local mouseDown = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then mouseDown = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then mouseDown = false end
end)

-- ==================== ГЛАВНЫЙ ЦИКЛ ====================
RunService.RenderStepped:Connect(function()
    -- AIM circle
    if AimSettings.Enabled and AimSettings.Mode == "Circle" then
        AimCircle.Visible = true
        AimCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        AimCircle.Radius = CircleSizes[AimSettings.CircleSize]
    else
        AimCircle.Visible = false
    end
    
    -- AIM
    if AimSettings.Enabled and mouseDown then
        local target = GetAimTarget()
        if target then AimAt(target) end
    end
    
    -- ESP
    if ESPSettings.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player then
                if not ESPDrawings[p] then CreateESP(p) end
                UpdateESP(p)
            end
        end
    end
end)

-- Новые игроки
Players.PlayerAdded:Connect(function(p)
    if p ~= Player and ESPSettings.Enabled then task.wait(1); CreateESP(p) end
end)
Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end)

-- Если ESP включен при старте
if ESPSettings.Enabled then
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then CreateESP(p) end
    end
end

-- Первичное заполнение списка игроков
UpdatePlayerList()

-- Уведомление о загрузке
StarterGui:SetCore("SendNotification", {
    Title = "MagmaHub",
    Text = "Загружен! " .. (IsMobile and "Мобилка" or "ПК") .. " | LAlt скрыть",
    Duration = 5
})

print("MagmaHub загружен! | " .. (IsMobile and "Mobile" or "PC"))
