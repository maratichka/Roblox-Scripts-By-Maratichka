--[[
    Maratichka's Lab System v2.1
    + Player tab: Speed, Jump, Flight, Sprint, Noclip
--]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

-- Local player
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = Player:GetMouse()

-- Globals
local StoredPosition = nil
local isFlinging = false
local isMinimized = false
local menuVisible = true

-- Player Settings
local PlayerSettings = {
    Speed = 16,
    JumpPower = 50,
    FlyEnabled = false,
    FlySpeed = 50,
    FlyKey = Enum.KeyCode.Q,
    SprintEnabled = false,
    SprintSpeed = 25,
    SprintKey = Enum.KeyCode.LeftShift,
    NoclipEnabled = false
}

local FlyInputFlags = {
    forward = false,
    back = false,
    left = false,
    right = false,
    up = false,
    down = false
}

local FlyBodyVelocity = nil
local FlyBodyGyro = nil
local NoclipConnection = nil
local FlyConnection = nil
local SprintConnection = nil
local currentSprintBoost = 0

-- AIM Settings
local AimSettings = {
    Enabled = false,
    Mode = "Circle",
    CircleSize = "Medium",
    AimPart = "Head",
    PredictionEnabled = true,
    PredictionAmount = 10,
    TeamCheck = false
}

local CircleSizes = {
    Small = 80,
    Medium = 150,
    Large = 250
}

-- ESP Settings
local ESPSettings = {
    Enabled = false,
    BoxESP = false,
    BoxColor = Color3.fromRGB(255, 25, 25),
    BoxThickness = 1,
    TracerESP = false,
    TracerOrigin = "Bottom",
    TracerColor = Color3.fromRGB(255, 25, 25),
    TracerThickness = 1,
    NameESP = false,
    NameColor = Color3.fromRGB(255, 255, 255),
    NameSize = 14,
    SkeletonESP = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonThickness = 1.5,
    ChamsEnabled = false,
    ChamsFillColor = Color3.fromRGB(255, 0, 0),
    ChamsTransparency = 0.5,
    ChamsVisibleThroughWalls = true,
    TeamCheck = false,
    ShowTeam = false,
    MaxDistance = 1000
}

local ESPDrawings = {}
local Highlights = {}

-- AIM circle drawing
local AimCircle = Drawing.new("Circle")
AimCircle.Visible = false
AimCircle.Color = Color3.fromRGB(255, 255, 255)
AimCircle.Thickness = 1.5
AimCircle.Transparency = 0.7
AimCircle.Filled = false
AimCircle.NumSides = 64

-- Colors
local Colors = {
    Background = Color3.fromRGB(15, 15, 20),
    Secondary = Color3.fromRGB(25, 25, 35),
    Accent = Color3.fromRGB(200, 10, 10),
    AccentHover = Color3.fromRGB(255, 30, 30),
    Text = Color3.fromRGB(220, 220, 220),
    TextDark = Color3.fromRGB(160, 160, 160),
    TextAccent = Color3.fromRGB(255, 80, 80),
    Green = Color3.fromRGB(0, 200, 100),
    Border = Color3.fromRGB(60, 60, 70),
    SliderBg = Color3.fromRGB(35, 35, 45),
    SliderFill = Color3.fromRGB(200, 10, 10)
}

-- ==================== GUI CREATION ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MLS_MainGUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderColor3 = Colors.Accent
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 320, 0, 480)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Colors.Secondary
TitleBar.Size = UDim2.new(1, 0, 0, 35)

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TitleBar
TitleText.BackgroundTransparency = 1
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.Size = UDim2.new(1, -100, 1, 0)
TitleText.Font = Enum.Font.SourceSansBold
TitleText.Text = "Maratichka's Lab"
TitleText.TextColor3 = Colors.Accent
TitleText.TextSize = 15
TitleText.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Parent = TitleBar
MinimizeButton.BackgroundColor3 = Colors.Secondary
MinimizeButton.Position = UDim2.new(1, -65, 0.5, -10)
MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.Text = "─"
MinimizeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeButton.TextSize = 14

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 4)
MinimizeCorner.Parent = MinimizeButton

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Parent = TitleBar
CloseButton.BackgroundColor3 = Colors.Accent
CloseButton.Position = UDim2.new(1, -36, 0.5, -10)
CloseButton.Size = UDim2.new(0, 22, 0, 22)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseButton

-- Tab Buttons
local TabFrame = Instance.new("Frame")
TabFrame.Name = "TabFrame"
TabFrame.Parent = MainFrame
TabFrame.BackgroundTransparency = 1
TabFrame.Position = UDim2.new(0, 5, 0, 42)
TabFrame.Size = UDim2.new(1, -10, 0, 30)

local Tabs = {"Player", "FE Fling", "ESP/AIM"}
local TabButtons = {}
local ContentFrames = {}

for i, tabName in ipairs(Tabs) do
    local TabButton = Instance.new("TextButton")
    TabButton.Parent = TabFrame
    TabButton.BackgroundColor3 = Colors.Secondary
    TabButton.Size = UDim2.new(1/3 - 0.007, 0, 1, 0)
    TabButton.Position = UDim2.new((i-1)/3, 0, 0, 0)
    TabButton.Font = Enum.Font.SourceSansBold
    TabButton.Text = tabName
    TabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
    TabButton.TextSize = 12
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 5)
    TabCorner.Parent = TabButton
    
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

local currentTab = "Player"
local function SwitchTab(tabName)
    if currentTab == tabName then return end
    ContentFrames[currentTab].Visible = false
    ContentFrames[tabName].Visible = true
    currentTab = tabName
    
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Colors.Accent
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Colors.Secondary
            btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end
end

for tabName, button in pairs(TabButtons) do
    button.MouseButton1Click:Connect(function()
        SwitchTab(tabName)
    end)
end

TabButtons["Player"].BackgroundColor3 = Colors.Accent
TabButtons["Player"].TextColor3 = Color3.fromRGB(255, 255, 255)

-- ==================== PLAYER TAB ====================
local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Parent = ContentFrames["Player"]
PlayerScroll.BackgroundTransparency = 1
PlayerScroll.Size = UDim2.new(1, 0, 1, 0)
PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 520)
PlayerScroll.ScrollBarThickness = 4
PlayerScroll.ScrollBarImageColor3 = Color3.fromRGB(40, 40, 50)
PlayerScroll.ScrollingDirection = Enum.ScrollingDirection.Y

local py = 5 -- player y offset

-- Helper: Section Box
local function CreateSectionBox(parent, y, height)
    local box = Instance.new("Frame")
    box.Parent = parent
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    box.BorderColor3 = Color3.fromRGB(50, 50, 60)
    box.BorderSizePixel = 1
    box.Position = UDim2.new(0, 0, 0, y)
    box.Size = UDim2.new(1, 0, 0, height)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box
    
    return box
end

-- Helper: Slider
local function CreateSlider(parent, y, label, minVal, maxVal, defaultVal, callback)
    local box = CreateSectionBox(parent, y, 62)
    
    -- Header row
    local headerFrame = Instance.new("Frame")
    headerFrame.Parent = box
    headerFrame.BackgroundTransparency = 1
    headerFrame.Position = UDim2.new(0, 10, 0, 8)
    headerFrame.Size = UDim2.new(1, -20, 0, 18)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = headerFrame
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = label
    nameLabel.TextColor3 = Colors.Text
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueBox = Instance.new("TextBox")
    valueBox.Parent = headerFrame
    valueBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    valueBox.BorderColor3 = Colors.Border
    valueBox.BorderSizePixel = 1
    valueBox.Position = UDim2.new(1, -55, 0, -1)
    valueBox.Size = UDim2.new(0, 55, 0, 20)
    valueBox.Font = Enum.Font.SourceSans
    valueBox.Text = tostring(defaultVal)
    valueBox.TextColor3 = Colors.TextAccent
    valueBox.TextSize = 12
    
    local valCorner = Instance.new("UICorner")
    valCorner.CornerRadius = UDim.new(0, 3)
    valCorner.Parent = valueBox
    
    -- Slider background
    local sliderBg = Instance.new("Frame")
    sliderBg.Parent = box
    sliderBg.BackgroundColor3 = Colors.SliderBg
    sliderBg.Position = UDim2.new(0, 10, 0, 34)
    sliderBg.Size = UDim2.new(1, -20, 0, 10)
    
    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(0, 5)
    sliderBgCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderBg
    sliderFill.BackgroundColor3 = Colors.SliderFill
    sliderFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    
    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(0, 5)
    sliderFillCorner.Parent = sliderFill
    
    local dragging = false
    local currentValue = defaultVal
    
    local function updateSlider(val)
        val = math.clamp(math.floor(val), minVal, maxVal)
        currentValue = val
        local percent = (val - minVal) / (maxVal - minVal)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        valueBox.Text = tostring(val)
        callback(val)
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = sliderBg.AbsolutePosition
            local sliderSize = sliderBg.AbsoluteSize
            local percent = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
            local val = minVal + (maxVal - minVal) * percent
            updateSlider(val)
        end
    end)
    
    valueBox.FocusLost:Connect(function(enterPressed)
        local num = tonumber(valueBox.Text)
        if num then
            updateSlider(num)
        else
            valueBox.Text = tostring(currentValue)
        end
    end)
    
    return {
        SetValue = function(val) updateSlider(val) end,
        GetValue = function() return currentValue end
    }
end

-- Helper: Toggle
local function CreateToggle(parent, y, text, default, callback)
    local box = CreateSectionBox(parent, y, 36)
    
    local btn = Instance.new("TextButton")
    btn.Parent = box
    btn.BackgroundColor3 = default and Colors.Green or Colors.SliderBg
    btn.Position = UDim2.new(0, 10, 0.5, -9)
    btn.Size = UDim2.new(0, 20, 0, 20)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = ""
    btn.TextSize = 10
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn
    
    local label = Instance.new("TextLabel")
    label.Parent = box
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 38, 0, 0)
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Font = Enum.Font.SourceSans
    label.Text = text
    label.TextColor3 = Colors.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local enabled = default
    
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.BackgroundColor3 = enabled and Colors.Green or Colors.SliderBg
        callback(enabled)
    end)
    
    return {
        SetValue = function(val)
            enabled = val
            btn.BackgroundColor3 = enabled and Colors.Green or Colors.SliderBg
        end,
        GetValue = function() return enabled end
    }
end

-- Helper: Bind Button
local function CreateBind(parent, y, label, defaultKey, callback)
    local box = CreateSectionBox(parent, y, 36)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = box
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.Size = UDim2.new(0, 80, 1, 0)
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.Text = label
    nameLabel.TextColor3 = Colors.TextDark
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local bindBtn = Instance.new("TextButton")
    bindBtn.Parent = box
    bindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    bindBtn.BorderColor3 = Colors.Border
    bindBtn.BorderSizePixel = 1
    bindBtn.Position = UDim2.new(1, -80, 0.5, -10)
    bindBtn.Size = UDim2.new(0, 70, 0, 20)
    bindBtn.Font = Enum.Font.SourceSans
    bindBtn.Text = defaultKey.Name
    bindBtn.TextColor3 = Colors.TextAccent
    bindBtn.TextSize = 11
    
    local bindCorner = Instance.new("UICorner")
    bindCorner.CornerRadius = UDim.new(0, 3)
    bindCorner.Parent = bindBtn
    
    local listening = false
    
    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "..."
        bindBtn.BackgroundColor3 = Colors.Accent
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening and not gameProcessed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                bindBtn.Text = input.KeyCode.Name
                bindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                callback(input.KeyCode)
            end
        end
    end)
end

-- === SPEED SLIDER ===
local SpeedSlider = CreateSlider(PlayerScroll, py, "Speed", 1, 500, 16, function(val)
    PlayerSettings.Speed = val
    ApplyCharacterSettings()
end)
py = py + 70

-- === JUMP POWER SLIDER ===
local JumpSlider = CreateSlider(PlayerScroll, py, "Jump Power", 1, 300, 50, function(val)
    PlayerSettings.JumpPower = val
    ApplyCharacterSettings()
end)
py = py + 70

-- === FLY SECTION ===
local FlyToggle = CreateToggle(PlayerScroll, py, "Enable Fly", false, function(val)
    PlayerSettings.FlyEnabled = val
    if val then
        EnableFly()
    else
        DisableFly()
    end
end)
py = py + 44

local FlySpeedSlider = CreateSlider(PlayerScroll, py, "Fly Speed", 1, 500, 50, function(val)
    PlayerSettings.FlySpeed = val
end)
py = py + 70

CreateBind(PlayerScroll, py, "Fly Key:", PlayerSettings.FlyKey, function(key)
    PlayerSettings.FlyKey = key
end)
py = py + 44

-- === SPRINT SECTION ===
local SprintToggle = CreateToggle(PlayerScroll, py, "Enable Sprint", false, function(val)
    PlayerSettings.SprintEnabled = val
    if not val then
        currentSprintBoost = 0
        ApplyCharacterSettings()
    end
end)
py = py + 44

local SprintSpeedSlider = CreateSlider(PlayerScroll, py, "Sprint Speed (+)", 1, 100, 25, function(val)
    PlayerSettings.SprintSpeed = val
end)
py = py + 70

CreateBind(PlayerScroll, py, "Sprint Key:", PlayerSettings.SprintKey, function(key)
    PlayerSettings.SprintKey = key
end)
py = py + 44

-- === NOCLIP SECTION ===
local NoclipToggle = CreateToggle(PlayerScroll, py, "Enable Noclip", false, function(val)
    PlayerSettings.NoclipEnabled = val
    if val then
        EnableNoclip()
    else
        DisableNoclip()
    end
end)
py = py + 50

PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, py)

-- ==================== FE FLING TAB ====================
local FlingScroll = Instance.new("ScrollingFrame")
FlingScroll.Parent = ContentFrames["FE Fling"]
FlingScroll.BackgroundTransparency = 1
FlingScroll.Size = UDim2.new(1, 0, 1, 0)
FlingScroll.CanvasSize = UDim2.new(0, 0, 0, 200)
FlingScroll.ScrollBarThickness = 4
FlingScroll.ScrollBarImageColor3 = Color3.fromRGB(40, 40, 50)

local FlingBox = CreateSectionBox(FlingScroll, 5, 150)

local FlingTitle = Instance.new("TextLabel")
FlingTitle.Parent = FlingBox
FlingTitle.BackgroundTransparency = 1
FlingTitle.Position = UDim2.new(0, 0, 0, 10)
FlingTitle.Size = UDim2.new(1, 0, 0, 22)
FlingTitle.Font = Enum.Font.SourceSansBold
FlingTitle.Text = "FE Fling"
FlingTitle.TextColor3 = Colors.TextAccent
FlingTitle.TextSize = 16
FlingTitle.TextXAlignment = Enum.TextXAlignment.Center

local FlingHint = Instance.new("TextLabel")
FlingHint.Parent = FlingBox
FlingHint.BackgroundTransparency = 1
FlingHint.Position = UDim2.new(0, 0, 0, 34)
FlingHint.Size = UDim2.new(1, 0, 0, 16)
FlingHint.Font = Enum.Font.SourceSans
FlingHint.Text = "(enter name)"
FlingHint.TextColor3 = Color3.fromRGB(180, 80, 80)
FlingHint.TextSize = 11
FlingHint.TextXAlignment = Enum.TextXAlignment.Center

local FlingInput = Instance.new("TextBox")
FlingInput.Parent = FlingBox
FlingInput.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
FlingInput.BorderColor3 = Colors.TextAccent
FlingInput.BorderSizePixel = 1
FlingInput.Position = UDim2.new(0, 20, 0, 55)
FlingInput.Size = UDim2.new(1, -40, 0, 30)
FlingInput.Font = Enum.Font.SourceSans
FlingInput.PlaceholderText = "username..."
FlingInput.PlaceholderColor3 = Color3.fromRGB(120, 50, 50)
FlingInput.Text = ""
FlingInput.TextColor3 = Colors.TextAccent
FlingInput.TextSize = 14

local FlingButton = Instance.new("TextButton")
FlingButton.Parent = FlingBox
FlingButton.BackgroundColor3 = Colors.Accent
FlingButton.Position = UDim2.new(0, 20, 0, 93)
FlingButton.Size = UDim2.new(1, -40, 0, 40)
FlingButton.Font = Enum.Font.SourceSansBold
FlingButton.Text = "FLING"
FlingButton.TextColor3 = Color3.fromRGB(0, 0, 0)
FlingButton.TextSize = 20

local FlingBtnCorner = Instance.new("UICorner")
FlingBtnCorner.CornerRadius = UDim.new(0, 6)
FlingBtnCorner.Parent = FlingButton

-- ==================== ESP/AIM TAB ====================
local ESPAIMScroll = Instance.new("ScrollingFrame")
ESPAIMScroll.Parent = ContentFrames["ESP/AIM"]
ESPAIMScroll.BackgroundTransparency = 1
ESPAIMScroll.Size = UDim2.new(1, 0, 1, 0)
ESPAIMScroll.CanvasSize = UDim2.new(0, 0, 0, 750)
ESPAIMScroll.ScrollBarThickness = 4
ESPAIMScroll.ScrollBarImageColor3 = Color3.fromRGB(40, 40, 50)

local ey = 5

local function CreateSectionLabel(parent, y, text, color)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 5, 0, y)
    label.Size = UDim2.new(1, 0, 0, 22)
    label.Font = Enum.Font.SourceSansBold
    label.Text = text
    label.TextColor3 = color or Colors.Accent
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function CreateESPToggle(parent, y, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(0, 5, 0, y)
    frame.Size = UDim2.new(1, -10, 0, 28)
    
    local enabled = default
    
    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundColor3 = default and Colors.Green or Colors.SliderBg
    btn.Position = UDim2.new(0, 0, 0.5, -9)
    btn.Size = UDim2.new(0, 20, 0, 20)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = ""
    btn.TextSize = 10
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 28, 0, 0)
    label.Size = UDim2.new(1, -28, 1, 0)
    label.Font = Enum.Font.SourceSans
    label.Text = text
    label.TextColor3 = Colors.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.BackgroundColor3 = enabled and Colors.Green or Colors.SliderBg
        callback(enabled)
    end)
end

local function CreateESPDropdown(parent, y, text, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Position = UDim2.new(0, 5, 0, y)
    frame.Size = UDim2.new(1, -10, 0, 55)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Font = Enum.Font.SourceSans
    label.Text = text
    label.TextColor3 = Colors.TextDark
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local selected = default
    
    local mainBtn = Instance.new("TextButton")
    mainBtn.Parent = frame
    mainBtn.BackgroundColor3 = Colors.Secondary
    mainBtn.BorderColor3 = Colors.Border
    mainBtn.BorderSizePixel = 1
    mainBtn.Position = UDim2.new(0, 0, 0, 20)
    mainBtn.Size = UDim2.new(1, 0, 0, 28)
    mainBtn.Font = Enum.Font.SourceSans
    mainBtn.Text = "  " .. selected
    mainBtn.TextColor3 = Colors.Text
    mainBtn.TextSize = 13
    mainBtn.TextXAlignment = Enum.TextXAlignment.Left
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = mainBtn
    
    local dropdownList = Instance.new("Frame")
    dropdownList.Parent = frame
    dropdownList.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    dropdownList.BorderColor3 = Colors.Border
    dropdownList.BorderSizePixel = 1
    dropdownList.Position = UDim2.new(0, 0, 0, 48)
    dropdownList.Size = UDim2.new(1, 0, 0, #options * 25)
    dropdownList.Visible = false
    dropdownList.ZIndex = 10
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 4)
    listCorner.Parent = dropdownList
    
    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Parent = dropdownList
        optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        optBtn.Position = UDim2.new(0, 0, 0, (i-1) * 25)
        optBtn.Size = UDim2.new(1, 0, 0, 25)
        optBtn.Font = Enum.Font.SourceSans
        optBtn.Text = option
        optBtn.TextColor3 = Colors.Text
        optBtn.TextSize = 12
        optBtn.ZIndex = 11
        
        optBtn.MouseButton1Click:Connect(function()
            selected = option
            mainBtn.Text = "  " .. selected
            dropdownList.Visible = false
            for _, b in ipairs(dropdownList:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
                end
            end
            optBtn.BackgroundColor3 = Colors.Accent
            callback(option)
        end)
    end
    
    mainBtn.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
    end)
end

CreateSectionLabel(ESPAIMScroll, ey, "ESP Settings", Color3.fromRGB(0, 255, 150))
ey = ey + 25

CreateESPToggle(ESPAIMScroll, ey, "Enable ESP", false, function(val)
    ESPSettings.Enabled = val
    if val then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player then CreateESP(p) end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            RemoveESP(p)
        end
    end
end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Box ESP", false, function(val)
    ESPSettings.BoxESP = val
end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Tracer ESP", false, function(val)
    ESPSettings.TracerESP = val
end)
ey = ey + 32

CreateESPDropdown(ESPAIMScroll, ey, "Tracer Origin", {"Bottom", "Top", "Center"}, "Bottom", function(val)
    ESPSettings.TracerOrigin = val
end)
ey = ey + 60

CreateESPToggle(ESPAIMScroll, ey, "Name ESP", false, function(val)
    ESPSettings.NameESP = val
end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Skeleton ESP", false, function(val)
    ESPSettings.SkeletonESP = val
end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Chams", false, function(val)
    ESPSettings.ChamsEnabled = val
    for p, h in pairs(Highlights) do
        h.Enabled = val
    end
end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Chams Through Walls", true, function(val)
    ESPSettings.ChamsVisibleThroughWalls = val
    for p, h in pairs(Highlights) do
        h.DepthMode = val and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    end
end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Team Check", false, function(val)
    ESPSettings.TeamCheck = val
end)
ey = ey + 38

CreateSectionLabel(ESPAIMScroll, ey, "AIM Settings", Color3.fromRGB(255, 200, 0))
ey = ey + 25

CreateESPToggle(ESPAIMScroll, ey, "Enable AIM", false, function(val)
    AimSettings.Enabled = val
    AimCircle.Visible = val and AimSettings.Mode == "Circle"
end)
ey = ey + 32

CreateESPDropdown(ESPAIMScroll, ey, "AIM Mode", {"Circle", "Lock"}, "Circle", function(val)
    AimSettings.Mode = val
    AimCircle.Visible = AimSettings.Enabled and val == "Circle"
end)
ey = ey + 60

CreateESPDropdown(ESPAIMScroll, ey, "Circle Size", {"Small", "Medium", "Large"}, "Medium", function(val)
    AimSettings.CircleSize = val
end)
ey = ey + 60

CreateESPDropdown(ESPAIMScroll, ey, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(val)
    AimSettings.AimPart = val
end)
ey = ey + 60

CreateESPToggle(ESPAIMScroll, ey, "Prediction", true, function(val)
    AimSettings.PredictionEnabled = val
end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Team Check (AIM)", false, function(val)
    AimSettings.TeamCheck = val
end)
ey = ey + 20

ESPAIMScroll.CanvasSize = UDim2.new(0, 0, 0, ey)

-- ==================== PLAYER FUNCTIONS ====================
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
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() FlyBodyVelocity = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
    
    if Player.Character then
        local humanoid = Player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

function EnableNoclip()
    if NoclipConnection then NoclipConnection:Disconnect() end
    
    NoclipConnection = RunService.Stepped:Connect(function()
        if PlayerSettings.NoclipEnabled and Player.Character then
            for _, part in ipairs(Player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

function DisableNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    
    if Player.Character then
        for _, part in ipairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Fly controls
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == PlayerSettings.FlyKey then
        PlayerSettings.FlyEnabled = not PlayerSettings.FlyEnabled
        if PlayerSettings.FlyEnabled then
            EnableFly()
            FlyToggle.SetValue(true)
        else
            DisableFly()
            FlyToggle.SetValue(false)
        end
    end
    
    if PlayerSettings.FlyEnabled then
        if input.KeyCode == Enum.KeyCode.W then FlyInputFlags.forward = true end
        if input.KeyCode == Enum.KeyCode.S then FlyInputFlags.back = true end
        if input.KeyCode == Enum.KeyCode.A then FlyInputFlags.left = true end
        if input.KeyCode == Enum.KeyCode.D then FlyInputFlags.right = true end
        if input.KeyCode == Enum.KeyCode.E then FlyInputFlags.up = true end
        if input.KeyCode == Enum.KeyCode.C then FlyInputFlags.down = true end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if PlayerSettings.FlyEnabled then
        if input.KeyCode == Enum.KeyCode.W then FlyInputFlags.forward = false end
        if input.KeyCode == Enum.KeyCode.S then FlyInputFlags.back = false end
        if input.KeyCode == Enum.KeyCode.A then FlyInputFlags.left = false end
        if input.KeyCode == Enum.KeyCode.D then FlyInputFlags.right = false end
        if input.KeyCode == Enum.KeyCode.E then FlyInputFlags.up = false end
        if input.KeyCode == Enum.KeyCode.C then FlyInputFlags.down = false end
    end
end)

-- Sprint
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == PlayerSettings.SprintKey and PlayerSettings.SprintEnabled then
        currentSprintBoost = PlayerSettings.SprintSpeed
        ApplyCharacterSettings()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == PlayerSettings.SprintKey then
        currentSprintBoost = 0
        ApplyCharacterSettings()
    end
end)

-- Fly update loop
RunService.RenderStepped:Connect(function(dt)
    if PlayerSettings.FlyEnabled and FlyBodyVelocity then
        local dir = Vector3.zero
        local camCF = Camera.CFrame
        
        if FlyInputFlags.forward then dir = dir + camCF.LookVector end
        if FlyInputFlags.back then dir = dir - camCF.LookVector end
        if FlyInputFlags.left then dir = dir - camCF.RightVector end
        if FlyInputFlags.right then dir = dir + camCF.RightVector end
        if FlyInputFlags.up then dir = dir + Vector3.yAxis end
        if FlyInputFlags.down then dir = dir - Vector3.yAxis end
        
        if dir.Magnitude > 0 then dir = dir.Unit end
        
        FlyBodyVelocity.Velocity = dir * PlayerSettings.FlySpeed
        if FlyBodyGyro then
            FlyBodyGyro.CFrame = camCF
        end
    end
end)

-- Character events
Player.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    ApplyCharacterSettings()
    
    if PlayerSettings.NoclipEnabled then
        EnableNoclip()
    end
    
    if PlayerSettings.FlyEnabled then
        task.wait(0.3)
        EnableFly()
    end
end)

-- Apply initial settings
if Player.Character then
    ApplyCharacterSettings()
end

-- ==================== ESP FUNCTIONS ====================
function CreateESP(targetPlayer)
    if targetPlayer == Player then return end
    if ESPDrawings[targetPlayer] then return end
    
    local drawings = {
        Box = {
            Left = Drawing.new("Line"),
            Right = Drawing.new("Line"),
            Top = Drawing.new("Line"),
            Bottom = Drawing.new("Line")
        },
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Skeleton = {
            Head = Drawing.new("Line"),
            LeftArm = Drawing.new("Line"),
            RightArm = Drawing.new("Line"),
            LeftLeg = Drawing.new("Line"),
            RightLeg = Drawing.new("Line")
        }
    }
    
    for _, line in pairs(drawings.Box) do
        line.Visible = false
        line.Color = ESPSettings.BoxColor
        line.Thickness = ESPSettings.BoxThickness
    end
    
    drawings.Tracer.Visible = false
    drawings.Tracer.Color = ESPSettings.TracerColor
    drawings.Tracer.Thickness = ESPSettings.TracerThickness
    
    drawings.Name.Visible = false
    drawings.Name.Color = ESPSettings.NameColor
    drawings.Name.Size = ESPSettings.NameSize
    drawings.Name.Font = 2
    drawings.Name.Center = true
    drawings.Name.Outline = true
    
    for _, line in pairs(drawings.Skeleton) do
        line.Visible = false
        line.Color = ESPSettings.SkeletonColor
        line.Thickness = ESPSettings.SkeletonThickness
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
        drawings.Tracer:Remove()
        drawings.Name:Remove()
        for _, line in pairs(drawings.Skeleton) do line:Remove() end
        ESPDrawings[targetPlayer] = nil
    end
    
    local highlight = Highlights[targetPlayer]
    if highlight then
        highlight:Destroy()
        Highlights[targetPlayer] = nil
    end
end

function HideAllESP(drawings)
    for _, line in pairs(drawings.Box) do line.Visible = false end
    drawings.Tracer.Visible = false
    drawings.Name.Visible = false
    for _, line in pairs(drawings.Skeleton) do line.Visible = false end
end

function UpdateESP(targetPlayer)
    if not ESPSettings.Enabled then return end
    local drawings = ESPDrawings[targetPlayer]
    if not drawings then return end
    
    local character = targetPlayer.Character
    if not character then HideAllESP(drawings) return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        HideAllESP(drawings) return
    end
    
    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    
    if not onScreen or distance > ESPSettings.MaxDistance then
        HideAllESP(drawings) return
    end
    
    if ESPSettings.TeamCheck and targetPlayer.Team == Player.Team and not ESPSettings.ShowTeam then
        HideAllESP(drawings) return
    end
    
    local size = character:GetExtentsSize()
    local cf = rootPart.CFrame
    
    local top = Camera:WorldToViewportPoint((cf * CFrame.new(0, size.Y/2, 0)).Position)
    local bottom = Camera:WorldToViewportPoint((cf * CFrame.new(0, -size.Y/2, 0)).Position)
    
    local screenSize = math.abs(bottom.Y - top.Y)
    local boxWidth = screenSize * 0.65
    local boxPos = Vector2.new(top.X - boxWidth/2, top.Y)
    
    -- Box ESP
    if ESPSettings.BoxESP then
        drawings.Box.Left.From = boxPos
        drawings.Box.Left.To = boxPos + Vector2.new(0, screenSize)
        drawings.Box.Left.Visible = true
        
        drawings.Box.Right.From = boxPos + Vector2.new(boxWidth, 0)
        drawings.Box.Right.To = boxPos + Vector2.new(boxWidth, screenSize)
        drawings.Box.Right.Visible = true
        
        drawings.Box.Top.From = boxPos
        drawings.Box.Top.To = boxPos + Vector2.new(boxWidth, 0)
        drawings.Box.Top.Visible = true
        
        drawings.Box.Bottom.From = boxPos + Vector2.new(0, screenSize)
        drawings.Box.Bottom.To = boxPos + Vector2.new(boxWidth, screenSize)
        drawings.Box.Bottom.Visible = true
        
        for _, line in pairs(drawings.Box) do
            line.Color = ESPSettings.BoxColor
            line.Thickness = ESPSettings.BoxThickness
        end
    else
        for _, line in pairs(drawings.Box) do line.Visible = false end
    end
    
    -- Tracer ESP
    if ESPSettings.TracerESP then
        local origin
        if ESPSettings.TracerOrigin == "Bottom" then
            origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        elseif ESPSettings.TracerOrigin == "Top" then
            origin = Vector2.new(Camera.ViewportSize.X/2, 0)
        else
            origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        end
        drawings.Tracer.From = origin
        drawings.Tracer.To = Vector2.new(pos.X, pos.Y)
        drawings.Tracer.Visible = true
    else
        drawings.Tracer.Visible = false
    end
    
    -- Name ESP
    if ESPSettings.NameESP then
        drawings.Name.Text = targetPlayer.DisplayName
        drawings.Name.Position = Vector2.new(boxPos.X + boxWidth/2, boxPos.Y - 18)
        drawings.Name.Visible = true
    else
        drawings.Name.Visible = false
    end
    
    -- Skeleton ESP
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
                    line.From = Vector2.new(fp.X, fp.Y)
                    line.To = Vector2.new(tp.X, tp.Y)
                    line.Visible = true
                    return
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
    else
        for _, line in pairs(drawings.Skeleton) do line.Visible = false end
    end
    
    -- Highlight
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

-- ==================== AIM FUNCTIONS ====================
function GetAimTarget()
    local target = nil
    local shortestDistance = AimSettings.Mode == "Circle" and CircleSizes[AimSettings.CircleSize] or math.huge
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            local aimPart = otherPlayer.Character:FindFirstChild(AimSettings.AimPart)
            
            if aimPart then
                if not (AimSettings.TeamCheck and otherPlayer.Team == Player.Team) then
                    local pos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                    
                    if onScreen and pos.Z > 0 then
                        local screenPos = Vector2.new(pos.X, pos.Y)
                        local distanceToCenter = (screenPos - screenCenter).Magnitude
                        
                        if distanceToCenter < shortestDistance then
                            shortestDistance = distanceToCenter
                            target = otherPlayer
                        end
                    end
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
        targetPos = targetPos + aimPart.Velocity / AimSettings.PredictionAmount
    end
    
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
end

-- ==================== FLING FUNCTIONS ====================
function FindPlayer(Name)
    Name = Name:lower()
    for _, Target in ipairs(Players:GetPlayers()) do
        if Target ~= Player then
            if Target.Name:lower():match("^" .. Name) then
                return Target
            elseif Target.DisplayName:lower():match("^" .. Name) then
                return Target
            end
        end
    end
    return nil
end

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
    
    if THead then Camera.CameraSubject = THead
    elseif THumanoid and TRootPart then Camera.CameraSubject = THumanoid end
    
    local OldPos = RootPart.CFrame
    local OldFPDH = Workspace.FallenPartsDestroyHeight
    Workspace.FallenPartsDestroyHeight = 0/0
    
    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    
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
    if TRootPart and THead then
        BasePart = (TRootPart.Position - THead.Position).Magnitude > 5 and THead or TRootPart
    end
    
    local TimeToWait = 2
    local StartTime = tick()
    local Angle = 0
    
    repeat
        if RootPart and THumanoid and BasePart then
            if BasePart.Velocity.Magnitude < 50 then
                Angle = Angle + 100
                local offsets = {
                    CFrame.new(0, 1.5, 0),
                    CFrame.new(0, -1.5, 0),
                    CFrame.new(2.25, 1.5, -2.25),
                    CFrame.new(-2.25, -1.5, 2.25),
                    CFrame.new(0, 1.5, 0),
                    CFrame.new(0, -1.5, 0)
                }
                for _, offset in ipairs(offsets) do
                    FPos(BasePart, offset + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                end
            else
                local offsets = {
                    {CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)},
                    {CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0)},
                    {CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)},
                    {CFrame.new(0, 1.5, TRootPart and TRootPart.Velocity.Magnitude / 1.25 or 100), CFrame.Angles(math.rad(90), 0, 0)},
                    {CFrame.new(0, -1.5, TRootPart and -TRootPart.Velocity.Magnitude / 1.25 or -100), CFrame.Angles(0, 0, 0)},
                    {CFrame.new(0, 1.5, TRootPart and TRootPart.Velocity.Magnitude / 1.25 or 100), CFrame.Angles(math.rad(90), 0, 0)},
                    {CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0)},
                    {CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)},
                    {CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0)},
                    {CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)}
                }
                for _, off in ipairs(offsets) do
                    FPos(BasePart, off[1], off[2])
                    task.wait()
                end
            end
        else
            break
        end
    until BasePart.Velocity.Magnitude > 500 or not BasePart.Parent or BasePart.Parent ~= TCharacter or TargetPlayer.Parent ~= Players or Humanoid.Health <= 0 or tick() > StartTime + TimeToWait
    
    if BV then BV:Destroy() end
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    Camera.CameraSubject = Humanoid
    
    if OldPos then
        repeat
            pcall(function()
                RootPart.CFrame = OldPos * CFrame.new(0, 0.5, 0)
                Character:SetPrimaryPartCFrame(OldPos * CFrame.new(0, 0.5, 0))
                Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                for _, Part in ipairs(Character:GetChildren()) do
                    if Part:IsA("BasePart") then
                        Part.Velocity = Vector3.new()
                        Part.RotVelocity = Vector3.new()
                    end
                end
            end)
            task.wait()
        until (RootPart.Position - OldPos.Position).Magnitude < 25
    end
    
    Workspace.FallenPartsDestroyHeight = OldFPDH
    isFlinging = false
    FlingButton.Text = "FLING"
    FlingButton.BackgroundColor3 = Colors.Accent
end

-- ==================== EVENT HANDLERS ====================
FlingButton.MouseButton1Click:Connect(function()
    if isFlinging then return end
    
    local TargetName = FlingInput.Text
    if TargetName == "" then
        StarterGui:SetCore("SendNotification", {Title = "MLS", Text = "Enter a username first!", Duration = 3})
        return
    end
    
    local Target = FindPlayer(TargetName)
    if not Target then
        StarterGui:SetCore("SendNotification", {Title = "MLS", Text = "Player not found!", Duration = 3})
        return
    end
    
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        StoredPosition = Player.Character.HumanoidRootPart.CFrame
    end
    
    isFlinging = true
    FlingButton.Text = "FLINGING..."
    FlingButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    
    task.spawn(function() SkidFling(Target) end)
end)

FlingInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then FlingButton.MouseButton1Click:Fire() end
end)

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = true
    MainFrame.Visible = false
    
    local FloatBtn = Instance.new("TextButton")
    FloatBtn.Name = "FloatButton"
    FloatBtn.Parent = ScreenGui
    FloatBtn.BackgroundColor3 = Colors.Accent
    FloatBtn.Position = UDim2.new(0.5, -20, 0.5, -20)
    FloatBtn.Size = UDim2.new(0, 40, 0, 40)
    FloatBtn.Font = Enum.Font.SourceSansBold
    FloatBtn.Text = "MLS"
    FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FloatBtn.TextSize = 10
    FloatBtn.Draggable = true
    
    local FloatCorner = Instance.new("UICorner")
    FloatCorner.CornerRadius = UDim.new(1, 0)
    FloatCorner.Parent = FloatBtn
    
    FloatBtn.MouseButton1Click:Connect(function()
        isMinimized = false
        MainFrame.Visible = true
        FloatBtn:Destroy()
    end)
end)

CloseButton.MouseButton1Click:Connect(function()
    DisableFly()
    DisableNoclip()
    for _, p in ipairs(Players:GetPlayers()) do RemoveESP(p) end
    AimCircle:Remove()
    ScreenGui:Destroy()
end)

MinimizeButton.MouseEnter:Connect(function() MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60) end)
MinimizeButton.MouseLeave:Connect(function() MinimizeButton.BackgroundColor3 = Colors.Secondary end)
CloseButton.MouseEnter:Connect(function() CloseButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100) end)
CloseButton.MouseLeave:Connect(function() CloseButton.BackgroundColor3 = Colors.Accent end)
FlingButton.MouseEnter:Connect(function() if not isFlinging then FlingButton.BackgroundColor3 = Colors.AccentHover end end)
FlingButton.MouseLeave:Connect(function() if not isFlinging then FlingButton.BackgroundColor3 = Colors.Accent end end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        if isMinimized then
            local floatBtn = ScreenGui:FindFirstChild("FloatButton")
            if floatBtn then
                isMinimized = false
                MainFrame.Visible = true
                floatBtn:Destroy()
            end
        else
            menuVisible = not menuVisible
            MainFrame.Visible = menuVisible
        end
    end
end)

local mouseDown = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = false
    end
end)

-- ==================== MAIN RENDER LOOP ====================
RunService.RenderStepped:Connect(function()
    if AimSettings.Enabled and AimSettings.Mode == "Circle" then
        AimCircle.Visible = true
        AimCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        AimCircle.Radius = CircleSizes[AimSettings.CircleSize]
    else
        AimCircle.Visible = false
    end
    
    if AimSettings.Enabled and mouseDown then
        local target = GetAimTarget()
        if target then AimAt(target) end
    end
    
    if ESPSettings.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player then
                if not ESPDrawings[p] then CreateESP(p) end
                UpdateESP(p)
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    if p ~= Player and ESPSettings.Enabled then
        task.wait(1)
        CreateESP(p)
    end
end)

Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end)

if ESPSettings.Enabled then
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then CreateESP(p) end
    end
end

StarterGui:SetCore("SendNotification", {
    Title = "Maratichka's Lab",
    Text = "v2.1 Loaded! LAlt to toggle",
    Duration = 5
})

print("Maratichka's Lab System v2.1 - Loaded")
