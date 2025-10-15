-- =========================================================
--             SPAM TELEPORTER WITH SHOW/HIDE TOGGLE
-- =========================================================

-- 1. Setup Global References
local Players = game:GetService("Players")
local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") -- Use PlayerGui for better mobile/loadstring compatibility
local RunService = game:GetService("RunService")

-- 2. Configuration Variables
local SPAM_POSITION = Vector3.new(0, 10, 0)
local SPAM_INTERVAL = 0.05

-- 3. State and Thread Management
local IsActive = false
local LoopThread = nil
local IsVisible = true -- New state for visibility

-- 4. Main Teleport Logic Function
local function getRootPart()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function StartTeleportSpam()
    if LoopThread then task.cancel(LoopThread); LoopThread = nil end

    if IsActive then
        LoopThread = task.spawn(function()
            local HumanoidRootPart = getRootPart()
            
            if HumanoidRootPart then
                while IsActive and HumanoidRootPart.Parent do
                    HumanoidRootPart.CFrame = CFrame.new(SPAM_POSITION)
                    task.wait(SPAM_INTERVAL)
                end
            else
                warn("Spam Teleporter failed: Character components not found.")
            end
        end)
    end
end

-- 5. Auto-Set Coordinates Function
local ToggleButton = nil
local DelayBox = nil
local CoordStatusLabel = nil
local MainFrame = nil
local VisibilityToggle = nil

local function SetSpamPosition()
    local HumanoidRootPart = getRootPart()
    
    if HumanoidRootPart then
        local currentPos = HumanoidRootPart.Position
        SPAM_POSITION = Vector3.new(
            math.floor(currentPos.X + 0.5), 
            math.floor(currentPos.Y + 0.5), 
            math.floor(currentPos.Z + 0.5)
        )
        
        print("✅ New Spam Position Set: " .. tostring(SPAM_POSITION))
        CoordStatusLabel.Text = "Target: " .. tostring(SPAM_POSITION)
        
        if IsActive then StartTeleportSpam() end
    else
        warn("Cannot set position: Character not found.")
    end
end

-- 6. Toggle and GUI Update Functions
local function UpdateButtonText()
    if ToggleButton then
        ToggleButton.BackgroundColor3 = IsActive and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
        ToggleButton.Text = IsActive and "Spam Teleporter: ON" or "Spam Teleporter: OFF"
    end
end

local function ToggleSpam()
    local newInterval = tonumber(DelayBox.Text)
    SPAM_INTERVAL = (newInterval and newInterval >= 0.001) and newInterval or SPAM_INTERVAL
    DelayBox.Text = tostring(SPAM_INTERVAL)

    IsActive = not IsActive
    
    if IsActive then
        StartTeleportSpam()
    else
        if LoopThread then task.cancel(LoopThread); LoopThread = nil end
    end
    
    UpdateButtonText()
end

-- NEW: Show/Hide Toggle Function
local function ToggleVisibility()
    IsVisible = not IsVisible
    
    if MainFrame then
        MainFrame.Visible = IsVisible
    end
    
    if VisibilityToggle then
        VisibilityToggle.Text = IsVisible and "HIDE" or "SHOW"
        VisibilityToggle.BackgroundColor3 = IsVisible and Color3.new(0.3, 0.3, 0.3) or Color3.new(0.6, 0.6, 0.6)
    end
end

-- 7. GUI Setup
-- Clean up any old GUI before creating the new one (Crucial for stability)
local function Cleanup(name)
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui.Name == name then gui:Destroy() end
    end
end
Cleanup("SpamTeleporter_GUI") -- Destroy the old one

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpamTeleporter_GUI"
ScreenGui.Parent = PlayerGui -- Use PlayerGui to match the successful mobile setup

-- NEW: Visibility Toggle Button (Top-Right)
VisibilityToggle = Instance.new("TextButton")
VisibilityToggle.Text = "HIDE"
VisibilityToggle.Font = Enum.Font.SourceSansBold
VisibilityToggle.TextSize = 14
VisibilityToggle.Size = UDim2.new(0, 50, 0, 25)
VisibilityToggle.Position = UDim2.new(1, -55, 0.01, 0) -- Top Right Corner
VisibilityToggle.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
VisibilityToggle.TextColor3 = Color3.new(1, 1, 1)
VisibilityToggle.Parent = ScreenGui
VisibilityToggle.MouseButton1Click:Connect(ToggleVisibility)


MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 160)
MainFrame.Position = UDim2.new(0.5, -125, 0.1, 0) -- CENTERED (As per your working version)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.Parent = ScreenGui
MainFrame.Visible = IsVisible

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "Spam Teleporter"
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.Size = UDim2.new(1, 0, 0, 25)
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
TitleLabel.Parent = MainFrame

-- Delay Label
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Text = "Spam Interval (Sec):"
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextSize = 14
DelayLabel.Size = UDim2.new(0.5, 0, 0, 30)
DelayLabel.Position = UDim2.new(0, 0, 0, 30)
DelayLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
DelayLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = MainFrame

-- Delay Input Box
DelayBox = Instance.new("TextBox")
DelayBox.Text = tostring(SPAM_INTERVAL)
DelayBox.Font = Enum.Font.SourceSans
DelayBox.TextSize = 14
DelayBox.Size = UDim2.new(0.5, 0, 0, 20)
DelayBox.Position = UDim2.new(0.5, 0, 0, 30)
DelayBox.PlaceholderText = "Enter interval (e.g., 0.01)"
DelayBox.TextColor3 = Color3.new(1, 1, 1)
DelayBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
DelayBox.Parent = MainFrame

-- Toggle Button
ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Spam_Toggle"
ToggleButton.Size = UDim2.new(1, 0, 0, 35)
ToggleButton.Position = UDim2.new(0, 0, 0, 55)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Parent = MainFrame
ToggleButton.MouseButton1Click:Connect(ToggleSpam)

-- Auto-Set Button
local SetButton = Instance.new("TextButton")
SetButton.Text = "Auto-Set Target Position (I'm here)"
SetButton.Size = UDim2.new(1, 0, 0, 35)
SetButton.Position = UDim2.new(0, 0, 0, 90)
SetButton.BackgroundColor3 = Color3.new(0.1, 0.5, 0.9)
SetButton.TextColor3 = Color3.new(1, 1, 1)
SetButton.Font = Enum.Font.SourceSans
SetButton.TextSize = 14
SetButton.Parent = MainFrame
SetButton.MouseButton1Click:Connect(SetSpamPosition)

-- Coordinate Status Label
CoordStatusLabel = Instance.new("TextLabel")
CoordStatusLabel.Text = "Target: " .. tostring(SPAM_POSITION)
CoordStatusLabel.Font = Enum.Font.SourceSans
CoordStatusLabel.TextSize = 12
CoordStatusLabel.Size = UDim2.new(1, 0, 0, 20)
CoordStatusLabel.Position = UDim2.new(0, 0, 0, 125)
CoordStatusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
CoordStatusLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
CoordStatusLabel.Parent = MainFrame

-- Initialize the button text
UpdateButtonText() 

print("Spam Teleporter with Show/Hide Toggle Loaded!")
