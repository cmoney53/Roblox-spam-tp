-- =========================================================
--             SIMPLE SPAM TELEPORTER (MOBILE ONLY)
-- =========================================================

-- 1. Setup Global References
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") -- The most reliable mobile parent
local RunService = game:GetService("RunService")

-- 2. Configuration Variables
local SPAM_POSITION = Vector3.new(0, 10, 0) 
local SPAM_INTERVAL = 0.05                  

-- 3. State and Thread Management
local IsActive = false                       
local LoopThread = nil                       

-- Helper function to reliably get the character's root part
local function getRootPart()
    local character = LocalPlayer.Character
    if not character then character = LocalPlayer.CharacterAdded:Wait() end
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- 4. Main Teleport Logic Function
local function StartTeleportSpam()
    if LoopThread then task.cancel(LoopThread) end

    if IsActive then
        LoopThread = task.spawn(function()
            while IsActive do
                local HumanoidRootPart = getRootPart()
                
                if HumanoidRootPart then
                    -- The core teleport action
                    HumanoidRootPart.CFrame = CFrame.new(SPAM_POSITION)
                end
                
                task.wait(SPAM_INTERVAL)
            end
        end)
    end
end

-- 5. Auto-Set Coordinates Function
local function SetSpamPosition(CoordStatusLabel, StartTeleportSpam)
    local HumanoidRootPart = getRootPart()
    
    if HumanoidRootPart then
        local currentPos = HumanoidRootPart.Position
        SPAM_POSITION = Vector3.new(
            math.floor(currentPos.X + 0.5), 
            math.floor(currentPos.Y + 0.5), 
            math.floor(currentPos.Z + 0.5)
        )
        
        CoordStatusLabel.Text = "Target: " .. tostring(SPAM_POSITION)
        
        if IsActive then StartTeleportSpam() end
    end
end

-- 6. Toggle and GUI Update Functions
local function UpdateButtonText(ToggleButton, IsActive)
    if ToggleButton then
        ToggleButton.BackgroundColor3 = IsActive and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
        ToggleButton.Text = IsActive and "Spam Teleporter: ON" or "Spam Teleporter: OFF"
    end
end

local function ToggleSpam(DelayBox, ToggleButton, StartTeleportSpam)
    local newInterval = tonumber(DelayBox.Text)
    SPAM_INTERVAL = (newInterval and newInterval >= 0.001) and newInterval or 0.05

    IsActive = not IsActive
    
    if not IsActive and LoopThread then task.cancel(LoopThread); LoopThread = nil end
    if IsActive then StartTeleportSpam() end
    
    UpdateButtonText(ToggleButton, IsActive)
end

-- 7. GUI Setup (Minimum elements, direct creation)

game.Loaded:Wait() -- Wait for the game to be ready

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleSpamTP_GUI"
ScreenGui.Parent = PlayerGui -- Use the most compatible mobile parent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 160) -- Small size for mobile
MainFrame.Position = UDim2.new(0.5, -100, 0.2, 0) -- Centered top
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.Parent = ScreenGui

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "Spam Teleporter"
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 16
TitleLabel.Size = UDim2.new(1, 0, 0, 25)
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
TitleLabel.Parent = MainFrame

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Text = "Interval (Sec):"
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextSize = 14
DelayLabel.Size = UDim2.new(0.5, 0, 0, 20)
DelayLabel.Position = UDim2.new(0, 0, 0, 30)
DelayLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
DelayLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = MainFrame

local DelayBox = Instance.new("TextBox")
DelayBox.Text = tostring(SPAM_INTERVAL)
DelayBox.Font = Enum.Font.SourceSans
DelayBox.TextSize = 14
DelayBox.Size = UDim2.new(0.5, 0, 0, 20)
DelayBox.Position = UDim2.new(0.5, 0, 0, 30)
DelayBox.PlaceholderText = "e.g., 0.01"
DelayBox.TextColor3 = Color3.new(1, 1, 1)
DelayBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
DelayBox.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Spam_Toggle"
ToggleButton.Size = UDim2.new(1, 0, 0, 35)
ToggleButton.Position = UDim2.new(0, 0, 0, 55)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 16
ToggleButton.Parent = MainFrame
ToggleButton.MouseButton1Click:Connect(function() ToggleSpam(DelayBox, ToggleButton, StartTeleportSpam) end)

local SetButton = Instance.new("TextButton")
SetButton.Text = "Set Target Position (I'm here)"
SetButton.Size = UDim2.new(1, 0, 0, 35)
SetButton.Position = UDim2.new(0, 0, 0, 90)
SetButton.BackgroundColor3 = Color3.new(0.1, 0.5, 0.9)
SetButton.TextColor3 = Color3.new(1, 1, 1)
SetButton.Font = Enum.Font.SourceSans
SetButton.TextSize = 14
SetButton.Parent = MainFrame

local CoordStatusLabel = Instance.new("TextLabel")
CoordStatusLabel.Text = "Target: " .. tostring(SPAM_POSITION)
CoordStatusLabel.Font = Enum.Font.SourceSans
CoordStatusLabel.TextSize = 12
CoordStatusLabel.Size = UDim2.new(1, 0, 0, 20)
CoordStatusLabel.Position = UDim2.new(0, 0, 0, 125)
CoordStatusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
CoordStatusLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
CoordStatusLabel.Parent = MainFrame

SetButton.MouseButton1Click:Connect(function() SetSpamPosition(CoordStatusLabel, StartTeleportSpam) end)

UpdateButtonText(ToggleButton, IsActive) 
print("Minimal Spam Teleporter (Mobile Compatibility) Script Loaded!")
