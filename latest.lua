-- =========================================================
--             SPAM TELEPORTER (NO LOCK) SCRIPT
-- =========================================================

-- 1. Setup Global References
local Players = game:GetService("Players")
local LocalPlayer = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- 2. Configuration Variables
local SPAM_POSITION = Vector3.new(0, 10, 0) -- Default spam target position
local SPAM_INTERVAL = 0.05                  -- Default time between teleports (in seconds)

-- 3. State and Thread Management
local IsActive = false                       -- Global toggle for the feature
local LoopThread = nil                       -- Reference to the running spam loop

-- 4. Main Teleport Logic Function (The Spam Loop)
local function StartTeleportSpam()
    -- Stop any existing loop before starting a new one
    if LoopThread then
        task.cancel(LoopThread)
        LoopThread = nil
    end

    -- Only run the loop if the feature is globally active
    if IsActive then
        LoopThread = task.spawn(function()
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            
            if HumanoidRootPart then
                print("Spam Teleporter ON: Teleporting to: " .. tostring(SPAM_POSITION))
                
                -- The infinite loop that forces the position
                while IsActive and HumanoidRootPart.Parent do
                    -- Set the character's CFrame to the target position
                    -- NO lock position code (WalkSpeed/JumpPower) is here!
                    HumanoidRootPart.CFrame = CFrame.new(SPAM_POSITION)
                    
                    -- Wait the adjustable spam interval
                    task.wait(SPAM_INTERVAL)
                end
                
                print("Spam Teleporter loop stopped.")
            else
                warn("Spam Teleporter failed: Character components not found.")
            end
        end)
    end
end

-- 5. Auto-Set Coordinates Function
local function SetSpamPosition()
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    
    if HumanoidRootPart then
        -- Grab the current position, rounding for stability
        local currentPos = HumanoidRootPart.Position
        SPAM_POSITION = Vector3.new(
            math.floor(currentPos.X + 0.5), 
            math.floor(currentPos.Y + 0.5), 
            math.floor(currentPos.Z + 0.5)
        )
        
        print("✅ New Spam Position Set: " .. tostring(SPAM_POSITION))
        
        -- Update the GUI label
        CoordStatusLabel.Text = "Target: " .. tostring(SPAM_POSITION)
        
        -- If the spam is active, restart it with the new position
        if IsActive then
            StartTeleportSpam()
        end
        
    else
        warn("Cannot set position: Character not found.")
    end
end

-- 6. Toggle and GUI Update Functions
local ToggleButton = nil
local DelayBox = nil
local CoordStatusLabel = nil

local function UpdateButtonText()
    if ToggleButton then
        if IsActive then
            ToggleButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2) -- Green (ON)
            ToggleButton.Text = "Spam Teleporter: ON"
        else
            ToggleButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2) -- Red (OFF)
            ToggleButton.Text = "Spam Teleporter: OFF"
        end
    end
end

local function ToggleSpam()
    -- Update the interval from the textbox first
    local newInterval = tonumber(DelayBox.Text)
    if newInterval and newInterval >= 0.001 then
        SPAM_INTERVAL = newInterval
    else
        warn("Invalid interval. Using default: " .. SPAM_INTERVAL)
        DelayBox.Text = tostring(SPAM_INTERVAL)
    end

    IsActive = not IsActive -- Flip the state (ON -> OFF or OFF -> ON)
    
    if IsActive then
        StartTeleportSpam()
    else
        -- Stop the loop (the `while IsActive` check in the loop handles this)
        if LoopThread then
            task.cancel(LoopThread)
            LoopThread = nil
        end
    end
    
    UpdateButtonText()
end

-- 7. GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpamTeleporter_GUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 160)
MainFrame.Position = UDim2.new(0.5, -125, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.Parent = ScreenGui

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
DelayBox.Text = tostring(SPAM_INTERVAL) -- Start with the default value
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
SetButton.BackgroundColor3 = Color3.new(0.1, 0.5, 0.9) -- Blue
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

print("Spam Teleporter (No Lock) Script Loaded!")
