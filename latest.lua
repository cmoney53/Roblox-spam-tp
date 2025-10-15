-- =========================================================
--             MULTI-DESTINATION (STABLE GUI BASE)
-- =========================================================

-- 1. Setup Global References
local Players = game:GetService("Players")
local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

-- 2. Configuration Variables
local TELEPORT_DESTINATIONS = {} -- CHANGED to a table for multiple points
local SPAM_INTERVAL = 0.05

-- 3. State and Thread Management
local IsActive = false
local LoopThread = nil
local IsVisible = true

-- 4. GUI Element References (Defined early for clarity)
local ToggleButton, DelayBox, CoordStatusLabel, MainFrame, VisibilityToggle = nil

-- Helper function to reliably get the character's root part
local function getRootPart()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

-- 5. Main Teleport Logic Function (The Cycling Spam Loop)
local function StartTeleportSpam()
    if LoopThread then task.cancel(LoopThread); LoopThread = nil end

    if IsActive then
        LoopThread = task.spawn(function()
            local i = 1
            print("Spam ON. Cycling " .. #TELEPORT_DESTINATIONS .. " destinations.")
            while IsActive do
                local HumanoidRootPart = getRootPart()
                
                if not HumanoidRootPart or #TELEPORT_DESTINATIONS == 0 then
                    IsActive = false
                    UpdateButtonText()
                    print("ERROR: No destinations or character not found. Stopping spam.")
                    break 
                end
                
                -- Set the character's CFrame to the current destination
                pcall(function() HumanoidRootPart.CFrame = CFrame.new(TELEPORT_DESTINATIONS[i]) end)
                
                i = i + 1
                if i > #TELEPORT_DESTINATIONS then i = 1 end
                
                task.wait(SPAM_INTERVAL)
            end
            print("Spam OFF.")
        end)
    end
end

-- 6. Destination Management Functions (NEW)
local function AddDestination()
    local HumanoidRootPart = getRootPart()
    
    if HumanoidRootPart then
        local currentPos = HumanoidRootPart.Position
        local newPos = Vector3.new(
            math.floor(currentPos.X + 0.5), 
            math.floor(currentPos.Y + 0.5), 
            math.floor(currentPos.Z + 0.5)
        )
        table.insert(TELEPORT_DESTINATIONS, newPos)
        
        print("✅ Added Destination #" .. #TELEPORT_DESTINATIONS .. ": " .. tostring(newPos))
        CoordStatusLabel.Text = #TELEPORT_DESTINATIONS .. " Destinations Saved"
        
        if IsActive then StartTeleportSpam() end
    else
        warn("Cannot add position: Character not found.")
    end
end

local function ClearDestinations()
    TELEPORT_DESTINATIONS = {} 
    IsActive = false
    if LoopThread then task.cancel(LoopThread); LoopThread = nil end
    CoordStatusLabel.Text = "0 Destinations Saved"
    UpdateButtonText()
    print("🗑️ Cleared all teleport destinations.")
end

-- 7. Toggle and GUI Update Functions
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

local function ToggleVisibility()
    IsVisible = not IsVisible
    
    if MainFrame then MainFrame.Visible = IsVisible end
    
    if VisibilityToggle then
        VisibilityToggle.Text = IsVisible and "HIDE" or "SHOW"
        VisibilityToggle.BackgroundColor3 = IsVisible and Color3.new(0.3, 0.3, 0.3) or Color3.new(0.6, 0.6, 0.6)
    end
end

-- 8. GUI Setup
local function Cleanup(name)
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui.Name == name then gui:Destroy() end
    end
end
Cleanup("SpamTeleporter_GUI")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpamTeleporter_GUI"
ScreenGui.Parent = PlayerGui

-- Visibility Toggle Button (Top-Right)
VisibilityToggle = Instance.new("TextButton")
VisibilityToggle.Text = "HIDE"
VisibilityToggle.Font = Enum.Font.SourceSansBold
VisibilityToggle.TextSize = 14
VisibilityToggle.Size = UDim2.new(0, 50, 0, 25)
VisibilityToggle.Position = UDim2.new(1, -55, 0.01, 0)
VisibilityToggle.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
VisibilityToggle.TextColor3 = Color3.new(1, 1, 1)
VisibilityToggle.Parent = ScreenGui
VisibilityToggle.MouseButton1Click:Connect(ToggleVisibility)

MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 195) -- Adjusted size to fit the new button
MainFrame.Position = UDim2.new(0.5, -125, 0.1, 0) -- CENTERED (As per your working version)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.Parent = ScreenGui
MainFrame.Visible = IsVisible

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "Multi-Point Spam TP" -- Updated Text
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

-- ADD POSITION Button (Replaced Auto-Set)
local AddButton = Instance.new("TextButton")
AddButton.Text = "Add Current Position (I'm here)"
AddButton.Size = UDim2.new(1, 0, 0, 35)
AddButton.Position = UDim2.new(0, 0, 0, 90)
AddButton.BackgroundColor3 = Color3.new(0.1, 0.5, 0.9)
AddButton.TextColor3 = Color3.new(1, 1, 1)
AddButton.Font = Enum.Font.SourceSans
AddButton.TextSize = 14
AddButton.Parent = MainFrame
AddButton.MouseButton1Click:Connect(AddDestination)

-- CLEAR ALL Destinations Button (NEW)
local ClearButton = Instance.new("TextButton")
ClearButton.Text = "Clear All Destinations"
ClearButton.Size = UDim2.new(1, 0, 0, 30)
ClearButton.Position = UDim2.new(0, 0, 0, 125)
ClearButton.BackgroundColor3 = Color3.new(0.7, 0.3, 0.1)
ClearButton.TextColor3 = Color3.new(1, 1, 1)
ClearButton.Font = Enum.Font.SourceSans
ClearButton.TextSize = 14
ClearButton.Parent = MainFrame
ClearButton.MouseButton1Click:Connect(ClearDestinations)

-- Coordinate Status Label (Updated text)
CoordStatusLabel = Instance.new("TextLabel")
CoordStatusLabel.Text = "0 Destinations Saved"
CoordStatusLabel.Font = Enum.Font.SourceSans
CoordStatusLabel.TextSize = 12
CoordStatusLabel.Size = UDim2.new(1, 0, 0, 20)
CoordStatusLabel.Position = UDim2.new(0, 0, 0, 155)
CoordStatusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
CoordStatusLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
CoordStatusLabel.Parent = MainFrame

-- Initialize the button text
UpdateButtonText() 

print("Multi-Destination Spam Teleporter (Final Stable Version) Loaded!")
