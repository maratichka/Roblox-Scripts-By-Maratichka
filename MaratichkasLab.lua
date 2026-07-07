--[[
    - OPTIMIZATION BY DEEPSEEK
    - Maratichka's Lab System v2.2
    - Fixed sliders
    - Mobile fly support
    - Infinity jumps
    - Mobile adaptive height
    - Chams color picker
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

-- Device check
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local MenuHeight = IsMobile and 380 or 500

-- Globals
local StoredPosition = nil
local isFlinging = false
local isMinimized = false
local menuVisible = true

-- Player Settings
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
local currentSprintBoost = 0
local InfinityJumpConnection = nil

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

local ChamsColors = {
    Red = Color3.fromRGB(255, 0, 0),
    Blue = Color3.fromRGB(0, 0, 255),
    Green = Color3.fromRGB(0, 255, 0),
    Yellow = Color3.fromRGB(255, 255, 0),
    Orange = Color3.fromRGB(255, 128, 0),
    Purple = Color3.fromRGB(128, 0, 255),
    Pink = Color3.fromRGB(255, 0, 128)
}

local ESPDrawings = {}
local Highlights = {}

-- AIM circle
local AimCircle = Drawing.new("Circle")
AimCircle.Visible = false
AimCircle.Color = Color3.fromRGB(255, 255, 255)
AimCircle.Thickness = 1.5
AimCircle.Transparency = 0.7
AimCircle.Filled = false
AimCircle.NumSides = 64

-- Colors (red/black theme)
local C = {
    Bg = Color3.fromRGB(12, 12, 18),
    Secondary = Color3.fromRGB(22, 22, 32),
    Accent = Color3.fromRGB(180, 10, 10),
    AccentLight = Color3.fromRGB(230, 40, 40),
    AccentDark = Color3.fromRGB(120, 5, 5),
    Text = Color3.fromRGB(220, 200, 200),
    TextDark = Color3.fromRGB(160, 140, 140),
    TextAccent = Color3.fromRGB(255, 70, 70),
    OnColor = Color3.fromRGB(200, 20, 20), -- for active toggles
    OffColor = Color3.fromRGB(40, 35, 35),
    Border = Color3.fromRGB(70, 40, 40),
    SliderBg = Color3.fromRGB(35, 28, 28),
    SliderFill = Color3.fromRGB(200, 15, 15)
}

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MLS_MainGUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = C.Secondary
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
TitleText.TextColor3 = C.AccentLight
TitleText.TextSize = 15
TitleText.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Parent = TitleBar
MinimizeButton.BackgroundColor3 = C.Secondary
MinimizeButton.Position = UDim2.new(1, -65, 0.5, -10)
MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.Text = "─"
MinimizeButton.TextColor3 = Color3.fromRGB(200, 180, 180)
MinimizeButton.TextSize = 14
Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 4)

-- Close
local CloseButton = Instance.new("TextButton")
CloseButton.Parent = TitleBar
CloseButton.BackgroundColor3 = C.Accent
CloseButton.Position = UDim2.new(1, -36, 0.5, -10)
CloseButton.Size = UDim2.new(0, 22, 0, 22)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 4)

-- Tabs
local TabFrame = Instance.new("Frame")
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
    TabButton.BackgroundColor3 = C.Secondary
    TabButton.Size = UDim2.new(1/3 - 0.007, 0, 1, 0)
    TabButton.Position = UDim2.new((i-1)/3, 0, 0, 0)
    TabButton.Font = Enum.Font.SourceSansBold
    TabButton.Text = tabName
    TabButton.TextColor3 = Color3.fromRGB(180, 160, 160)
    TabButton.TextSize = 12
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 5)
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
            btn.BackgroundColor3 = C.Accent
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = C.Secondary
            btn.TextColor3 = Color3.fromRGB(180, 160, 160)
        end
    end
end

for tabName, button in pairs(TabButtons) do
    button.MouseButton1Click:Connect(function() SwitchTab(tabName) end)
end
TabButtons["Player"].BackgroundColor3 = C.Accent
TabButtons["Player"].TextColor3 = Color3.fromRGB(255, 255, 255)

-- ==================== PLAYER TAB ====================
local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Parent = ContentFrames["Player"]
PlayerScroll.BackgroundTransparency = 1
PlayerScroll.Size = UDim2.new(1, 0, 1, 0)
PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 600)
PlayerScroll.ScrollBarThickness = 3
PlayerScroll.ScrollBarImageColor3 = C.Border

local py = 5

-- Helper: Section Box
local function CreateBox(parent, y, h)
    local box = Instance.new("Frame")
    box.Parent = parent
    box.BackgroundColor3 = Color3.fromRGB(18, 15, 15)
    box.BorderColor3 = C.Border
    box.BorderSizePixel = 1
    box.Position = UDim2.new(0, 0, 0, y)
    box.Size = UDim2.new(1, 0, 0, h)
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    return box
end

-- Helper: Slider
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
    valueBox.TextColor3 = C.TextAccent
    valueBox.TextSize = 12
    valueBox.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 3)
    
    -- Slider bg
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
    
    valueBox.FocusLost:Connect(function()
        local num = tonumber(valueBox.Text)
        if num then setValue(num) else valueBox.Text = tostring(currentValue) end
    end)
    
    return {SetValue = function(v) setValue(v) end, GetValue = function() return currentValue end}
end

-- Helper: Toggle
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
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
    
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

-- Helper: Bind
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
    bindBtn.TextColor3 = C.TextAccent
    bindBtn.TextSize = 11
    bindBtn.AutoButtonColor = false
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 3)
    
    local listening = false
    
    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "..."
        bindBtn.BackgroundColor3 = C.Accent
    end)
    
    UserInputService.InputBegan:Connect(function(input)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                bindBtn.Text = input.KeyCode.Name
                bindBtn.BackgroundColor3 = C.Secondary
                callback(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.Touch then
                -- On mobile, keep default
                listening = false
                bindBtn.Text = defaultKey.Name
                bindBtn.BackgroundColor3 = C.Secondary
            end
        end
    end)
end

-- Speed
CreateSlider(PlayerScroll, py, "Speed", 1, 500, 16, function(val)
    PlayerSettings.Speed = val
    ApplyCharacterSettings()
end)
py = py + 66

-- Jump Power
CreateSlider(PlayerScroll, py, "Jump Power", 1, 300, 50, function(val)
    PlayerSettings.JumpPower = val
    ApplyCharacterSettings()
end)
py = py + 66

-- Infinity Jumps
CreateToggle(PlayerScroll, py, "Infinity Jumps", false, function(val)
    PlayerSettings.InfinityJumps = val
    if val then
        EnableInfinityJumps()
    else
        DisableInfinityJumps()
    end
end)
py = py + 40

-- Fly
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

-- Sprint
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
py = py + 40

-- Noclip
CreateToggle(PlayerScroll, py, "Enable Noclip", false, function(val)
    PlayerSettings.NoclipEnabled = val
    if val then EnableNoclip() else DisableNoclip() end
end)
py = py + 46

PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, py)

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

-- Fly controls (works on both PC and mobile)
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

-- Mobile fly buttons
if IsMobile then
    local function createMobileFlyButton(text, position, flag)
        local btn = Instance.new("TextButton")
        btn.Parent = ScreenGui
        btn.BackgroundColor3 = Color3.fromRGB(150, 10, 10)
        btn.BackgroundTransparency = 0.6
        btn.Position = position
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 20
        btn.Font = Enum.Font.SourceSansBold
        btn.Visible = false
        btn.ZIndex = 10
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 25)
        
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
    
    local mobileFlyBtns = {
        createMobileFlyButton("▲", UDim2.new(0.8, -25, 0.45, -25), "forward"),
        createMobileFlyButton("▼", UDim2.new(0.8, -25, 0.65, -25), "back"),
        createMobileFlyButton("◄", UDim2.new(0.7, -25, 0.55, -25), "left"),
        createMobileFlyButton("►", UDim2.new(0.9, -25, 0.55, -25), "right"),
        createMobileFlyButton("⇧", UDim2.new(0.15, -25, 0.45, -25), "up"),
        createMobileFlyButton("⇩", UDim2.new(0.15, -25, 0.65, -25), "down"),
    }
    
    -- Show/hide mobile fly buttons
    RunService.RenderStepped:Connect(function()
        for _, btn in ipairs(mobileFlyBtns) do
            btn.Visible = PlayerSettings.FlyEnabled and menuVisible
        end
    end)
end

-- Fly update
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

-- Character events
Player.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    ApplyCharacterSettings()
    if PlayerSettings.NoclipEnabled then EnableNoclip() end
    if PlayerSettings.InfinityJumps then EnableInfinityJumps() end
    if PlayerSettings.FlyEnabled then task.wait(0.3); EnableFly() end
end)

if Player.Character then ApplyCharacterSettings() end

-- ==================== FE FLING TAB ====================
local FlingScroll = Instance.new("ScrollingFrame")
FlingScroll.Parent = ContentFrames["FE Fling"]
FlingScroll.BackgroundTransparency = 1
FlingScroll.Size = UDim2.new(1, 0, 1, 0)
FlingScroll.CanvasSize = UDim2.new(0, 0, 0, 180)
FlingScroll.ScrollBarThickness = 3
FlingScroll.ScrollBarImageColor3 = C.Border

local FlingBox = CreateBox(FlingScroll, 5, 140)

local FlingTitle = Instance.new("TextLabel")
FlingTitle.Parent = FlingBox
FlingTitle.BackgroundTransparency = 1
FlingTitle.Position = UDim2.new(0, 0, 0, 10)
FlingTitle.Size = UDim2.new(1, 0, 0, 22)
FlingTitle.Font = Enum.Font.SourceSansBold
FlingTitle.Text = "FE Fling"
FlingTitle.TextColor3 = C.TextAccent
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
FlingInput.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
FlingInput.BorderColor3 = C.TextAccent
FlingInput.BorderSizePixel = 1
FlingInput.Position = UDim2.new(0, 20, 0, 55)
FlingInput.Size = UDim2.new(1, -40, 0, 30)
FlingInput.Font = Enum.Font.SourceSans
FlingInput.PlaceholderText = "username..."
FlingInput.PlaceholderColor3 = Color3.fromRGB(120, 50, 50)
FlingInput.Text = ""
FlingInput.TextColor3 = C.TextAccent
FlingInput.TextSize = 14

local FlingButton = Instance.new("TextButton")
FlingButton.Parent = FlingBox
FlingButton.BackgroundColor3 = C.Accent
FlingButton.Position = UDim2.new(0, 20, 0, 93)
FlingButton.Size = UDim2.new(1, -40, 0, 36)
FlingButton.Font = Enum.Font.SourceSansBold
FlingButton.Text = "FLING"
FlingButton.TextColor3 = Color3.fromRGB(0, 0, 0)
FlingButton.TextSize = 20
Instance.new("UICorner", FlingButton).CornerRadius = UDim.new(0, 6)

-- ==================== ESP/AIM TAB ====================
local ESPAIMScroll = Instance.new("ScrollingFrame")
ESPAIMScroll.Parent = ContentFrames["ESP/AIM"]
ESPAIMScroll.BackgroundTransparency = 1
ESPAIMScroll.Size = UDim2.new(1, 0, 1, 0)
ESPAIMScroll.CanvasSize = UDim2.new(0, 0, 0, 800)
ESPAIMScroll.ScrollBarThickness = 3
ESPAIMScroll.ScrollBarImageColor3 = C.Border

local ey = 5

local function CreateSectionLabel(parent, y, text)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 5, 0, y)
    label.Size = UDim2.new(1, 0, 0, 22)
    label.Font = Enum.Font.SourceSansBold
    label.Text = text
    label.TextColor3 = C.AccentLight
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
    btn.BackgroundColor3 = default and C.OnColor or C.OffColor
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0, 0, 0.5, -9)
    btn.Size = UDim2.new(0, 20, 0, 20)
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 28, 0, 0)
    label.Size = UDim2.new(1, -28, 1, 0)
    label.Font = Enum.Font.SourceSans
    label.Text = text
    label.TextColor3 = C.Text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.BackgroundColor3 = enabled and C.OnColor or C.OffColor
        callback(enabled)
    end)
    
    return {SetValue = function(v) enabled = v; btn.BackgroundColor3 = enabled and C.OnColor or C.OffColor end}
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
    label.TextColor3 = C.TextDark
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local selected = default
    
    local mainBtn = Instance.new("TextButton")
    mainBtn.Parent = frame
    mainBtn.BackgroundColor3 = C.Secondary
    mainBtn.BorderColor3 = C.Border
    mainBtn.BorderSizePixel = 1
    mainBtn.Position = UDim2.new(0, 0, 0, 20)
    mainBtn.Size = UDim2.new(1, 0, 0, 28)
    mainBtn.Font = Enum.Font.SourceSans
    mainBtn.Text = "  " .. selected
    mainBtn.TextColor3 = C.Text
    mainBtn.TextSize = 13
    mainBtn.TextXAlignment = Enum.TextXAlignment.Left
    mainBtn.AutoButtonColor = false
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 4)
    
    local arrow = Instance.new("TextLabel")
    arrow.Parent = mainBtn
    arrow.BackgroundTransparency = 1
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.Size = UDim2.new(0, 18, 1, 0)
    arrow.Font = Enum.Font.SourceSansBold
    arrow.Text = "▼"
    arrow.TextColor3 = C.TextDark
    arrow.TextSize = 10
    
    local dropdownList = Instance.new("Frame")
    dropdownList.Parent = frame
    dropdownList.BackgroundColor3 = Color3.fromRGB(18, 14, 14)
    dropdownList.BorderColor3 = C.Border
    dropdownList.BorderSizePixel = 1
    dropdownList.Position = UDim2.new(0, 0, 0, 48)
    dropdownList.Size = UDim2.new(1, 0, 0, #options * 25)
    dropdownList.Visible = false
    dropdownList.ZIndex = 10
    Instance.new("UICorner", dropdownList).CornerRadius = UDim.new(0, 4)
    
    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Parent = dropdownList
        optBtn.BackgroundColor3 = Color3.fromRGB(28, 22, 22)
        optBtn.BorderSizePixel = 0
        optBtn.Position = UDim2.new(0, 0, 0, (i-1) * 25)
        optBtn.Size = UDim2.new(1, 0, 0, 25)
        optBtn.Font = Enum.Font.SourceSans
        optBtn.Text = option
        optBtn.TextColor3 = C.Text
        optBtn.TextSize = 12
        optBtn.ZIndex = 11
        optBtn.AutoButtonColor = false
        
        optBtn.MouseButton1Click:Connect(function()
            selected = option
            mainBtn.Text = "  " .. selected
            dropdownList.Visible = false
            arrow.Text = "▼"
            for _, b in ipairs(dropdownList:GetChildren()) do
                if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(28, 22, 22) end
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

-- ESP
CreateSectionLabel(ESPAIMScroll, ey, "ESP Settings")
ey = ey + 25

CreateESPToggle(ESPAIMScroll, ey, "Enable ESP", false, function(val)
    ESPSettings.Enabled = val
    if val then for _, p in ipairs(Players:GetPlayers()) do if p ~= Player then CreateESP(p) end end
    else for _, p in ipairs(Players:GetPlayers()) do RemoveESP(p) end end
end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Box ESP", false, function(val) ESPSettings.BoxESP = val end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Tracer ESP", false, function(val) ESPSettings.TracerESP = val end)
ey = ey + 32

CreateESPDropdown(ESPAIMScroll, ey, "Tracer Origin", {"Bottom", "Top", "Center"}, "Bottom", function(val) ESPSettings.TracerOrigin = val end)
ey = ey + 60

CreateESPToggle(ESPAIMScroll, ey, "Name ESP", false, function(val) ESPSettings.NameESP = val end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Skeleton ESP", false, function(val) ESPSettings.SkeletonESP = val end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Chams", false, function(val)
    ESPSettings.ChamsEnabled = val
    for p, h in pairs(Highlights) do h.Enabled = val end
end)
ey = ey + 32

CreateESPDropdown(ESPAIMScroll, ey, "Chams Fill Color", {"Red", "Blue", "Green", "Yellow", "Orange", "Purple", "Pink"}, "Red", function(val)
    ESPSettings.ChamsFillColor = ChamsColors[val]
    for p, h in pairs(Highlights) do h.FillColor = ChamsColors[val] end
end)
ey = ey + 60

CreateESPToggle(ESPAIMScroll, ey, "Chams Through Walls", true, function(val)
    ESPSettings.ChamsVisibleThroughWalls = val
    for p, h in pairs(Highlights) do
        h.DepthMode = val and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    end
end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Team Check", false, function(val) ESPSettings.TeamCheck = val end)
ey = ey + 38

-- AIM
CreateSectionLabel(ESPAIMScroll, ey, "AIM Settings")
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

CreateESPDropdown(ESPAIMScroll, ey, "Circle Size", {"Small", "Medium", "Large"}, "Medium", function(val) AimSettings.CircleSize = val end)
ey = ey + 60

CreateESPDropdown(ESPAIMScroll, ey, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(val) AimSettings.AimPart = val end)
ey = ey + 60

CreateESPToggle(ESPAIMScroll, ey, "Prediction", true, function(val) AimSettings.PredictionEnabled = val end)
ey = ey + 32

CreateESPToggle(ESPAIMScroll, ey, "Team Check (AIM)", false, function(val) AimSettings.TeamCheck = val end)
ey = ey + 20

ESPAIMScroll.CanvasSize = UDim2.new(0, 0, 0, ey)

-- ==================== ESP FUNCTIONS ====================
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

-- ==================== FLING FUNCTIONS ====================
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

function SkidFling(TargetPlayer)
    -- [Same as before - kept for brevity]
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
    
    local TimeToWait, StartTime, Angle = 2, tick(), 0
    repeat
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

-- ==================== EVENT HANDLERS ====================
FlingButton.MouseButton1Click:Connect(function()
    if isFlinging then return end
    local TargetName = FlingInput.Text
    if TargetName == "" then StarterGui:SetCore("SendNotification", {Title = "MLS", Text = "Enter a username!", Duration = 3}); return end
    local Target = FindPlayer(TargetName)
    if not Target then StarterGui:SetCore("SendNotification", {Title = "MLS", Text = "Player not found!", Duration = 3}); return end
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        StoredPosition = Player.Character.HumanoidRootPart.CFrame
    end
    isFlinging = true
    FlingButton.Text = "FLINGING..."
    FlingButton.BackgroundColor3 = C.AccentLight
    task.spawn(function() SkidFling(Target) end)
end)

FlingInput.FocusLost:Connect(function(ep) if ep then FlingButton.MouseButton1Click:Fire() end end)

-- Minimize (fixed - float button doesn't open on drag)
local FloatBtn = nil
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = true
    MainFrame.Visible = false
    
    if FloatBtn then FloatBtn:Destroy() end
    FloatBtn = Instance.new("TextButton")
    FloatBtn.Name = "FloatButton"
    FloatBtn.Parent = ScreenGui
    FloatBtn.BackgroundColor3 = C.Accent
    FloatBtn.Position = UDim2.new(0.5, -20, 0.5, -20)
    FloatBtn.Size = UDim2.new(0, 40, 0, 40)
    FloatBtn.Font = Enum.Font.SourceSansBold
    FloatBtn.Text = "MLS"
    FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FloatBtn.TextSize = 10
    FloatBtn.ZIndex = 100
    Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
    
    -- Use a delayed click detection to prevent drag-triggering
    local dragStartPos = nil
    FloatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStartPos = input.Position
        end
    end)
    
    FloatBtn.InputEnded:Connect(function(input)
        if dragStartPos and input.Position then
            local dist = (input.Position - dragStartPos).Magnitude
            if dist < 10 then -- Only click if barely moved
                isMinimized = false
                MainFrame.Visible = true
                FloatBtn:Destroy()
                FloatBtn = nil
            end
        end
        dragStartPos = nil
    end)
    
    -- Make draggable manually so it doesn't trigger click on drag end
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    FloatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = FloatBtn.Position
        end
    end)
    
    FloatBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            FloatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    FloatBtn.InputEnded:Connect(function()
        dragging = false
    end)
end)

-- Close
CloseButton.MouseButton1Click:Connect(function()
    DisableFly(); DisableNoclip(); DisableInfinityJumps()
    for _, p in ipairs(Players:GetPlayers()) do RemoveESP(p) end
    AimCircle:Remove()
    if FloatBtn then FloatBtn:Destroy() end
    ScreenGui:Destroy()
end)

-- Hover effects
MinimizeButton.MouseEnter:Connect(function() MinimizeButton.BackgroundColor3 = C.Border end)
MinimizeButton.MouseLeave:Connect(function() MinimizeButton.BackgroundColor3 = C.Secondary end)
CloseButton.MouseEnter:Connect(function() CloseButton.BackgroundColor3 = C.AccentLight end)
CloseButton.MouseLeave:Connect(function() CloseButton.BackgroundColor3 = C.Accent end)
FlingButton.MouseEnter:Connect(function() if not isFlinging then FlingButton.BackgroundColor3 = C.AccentLight end end)
FlingButton.MouseLeave:Connect(function() if not isFlinging then FlingButton.BackgroundColor3 = C.Accent end end)

-- L Alt toggle
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

-- AIM mouse
local mouseDown = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then mouseDown = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then mouseDown = false end
end)

-- ==================== RENDER LOOP ====================
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
    if p ~= Player and ESPSettings.Enabled then task.wait(1); CreateESP(p) end
end)
Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end)

if ESPSettings.Enabled then
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then CreateESP(p) end
    end
end

StarterGui:SetCore("SendNotification", {
    Title = "Maratichka's Lab",
    Text = "v2.2 Loaded! " .. (IsMobile and "Mobile" or "PC") .. " mode",
    Duration = 5
})

print("Maratichka's Lab System v2.2 - Loaded")
print("Device:", IsMobile and "Mobile" or "PC", "| Menu height:", MenuHeight)
