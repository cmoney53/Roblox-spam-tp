-- =========================================================
--             MULTI-DESTINATION SPAM TELEPORTER
-- =========================================================

-- 1. Setup Global References
local Players = game:GetService("Players")
local LocalPlayer = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- 2. Configuration Variables
local TELEPORT_DESTINATIONS = {} -- List to hold multiple Vector3 points
local SPAM_INTERVAL = 0.05       -- Default time between teleports (in seconds)

-- 3. State and Thread Management
local IsActive = false           -- Global toggle for the feature
local LoopThread = nil           -- Reference to the running spam loop
local IsMinimized = false        -- State variable for the GUI

-- 4. Main Teleport Logic Function (The Cycling Spam Loop)
local function StartTeleportSpam()
    -- Stop any existing loop before starting a new one
    if LoopThread then task.cancel(LoopThread) end

    if IsActive then
        LoopThread = task.spawn(function()
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            
            if HumanoidRootPart then
                print("Spam Teleporter ON: Cycling through " .. #TELEPORT_DESTINATIONS .. " destinations.")
                
                local currentIndex = 1 -- Start at the first destination
                while IsActive and HumanoidRootPart.Parent do
                    
                    -- Check if any destinations are saved before trying to cycle
                    if #TELEPORT_DESTINATIONS == 0 then
                        warn("No destinations saved. Stopping spam.")
                        IsActive = false
                        task.cancel(LoopThread)
                        UpdateButtonText()
                        break
                    end
                    
                    -- Teleport to the current destination
                    HumanoidRootPart.CFrame = CFrame.new(TELEPORT_DESTINATIONS[currentIndex])
                    
                    -- Move to next index, looping back to 1 if at the end of the list
                    currentIndex = currentIndex + 1
                    if currentIndex > #TELEPORT_DESTINATIONS then
                        currentIndex = 1
                    end
                    
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

-- 5. Add Destination Function
local function AddDestination()
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    
    if HumanoidRootPart then
        local currentPos = HumanoidRootPart.Position
        local newPos = Vector3.new(
            math.floor(currentPos.X + 0.5), 
            math.floor(currentPos.Y + 0.5), 
            math.floor(currentPos.Z + 0.5)
        )
        
        -- Add the new position to the list
        table.insert(TELEPORT_DESTINATIONS, newPos)
        
        print("✅ Added Destination #" .. #TELEPORT_DESTINATIONS .. ": " .. tostring(newPos))
        
        -- Update the GUI label
        CoordStatusLabel.Text = #TELEPORT_DESTINATIONS .. " Destinations Saved"
        
        -- If the spam is active, restart it so it immediately cycles to the new destination
        if IsActive then StartTeleportSpam() end
    else
        warn("Cannot set position: Character not found.")
    end
end

-- 6. Clear Destinations Function
local function ClearDestinations()
    TELEPORT_DESTINATIONS = {} -- Reset the list
    if IsActive then 
        IsActive = false 
        if LoopThread then task.cancel(LoopThread) end
    end
    
    CoordStatusLabel.Text = "0 Destinations Saved"
    UpdateButtonText()
    print("Cleared all teleport destinations.")
end

-- 7. GUI Management and Draggable/Collapsible Logic
local ToggleButton, DelayBox, CoordStatusLabel, MainFrame, TitleLabel, MinMaxButton = nil
local ContentFrame = nil

local function UpdateButtonText()
    if ToggleButton then
        ToggleButton.BackgroundColor3 = IsActive and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
        ToggleButton.Text = IsActive and "Spam Teleporter: ON" or "Spam Teleporter: OFF"
    end
end

local function ToggleSpam()
    local newInterval = tonumber(DelayBox.Text)
    if newInterval and newInterval >= 0.001 then
        SPAM_INTERVAL = newInterval
    else
        warn("Invalid interval. Using default: " .. SPAM_INTERVAL)
        DelayBox.Text = tostring(SPAM_INTERVAL)
    end

    IsActive = not IsActive
    
    if not IsActive and LoopThread then task.cancel(LoopThread); LoopThread = nil end
    if IsActive then StartTeleportSpam() end
    
    UpdateButtonText()
}

local function ToggleMinimize()
    IsMinimized = not IsMinimized
    
    if IsMinimized then
        MainFrame:TweenSize(UDim2.new(0, 250, 0, 25), "Out", "Quad", 0.2, true)
        ContentFrame.Visible = false
        MinMaxButton.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 250, 0, 195), "Out", "Quad", 0.2, true) -- Restored size
        ContentFrame.Visible = true
        MinMaxButton.Text = "-"
    end
}

local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    local function DoDrag(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)

    game:GetService("RunService").Heartbeat:Connect(function()
        if dragging and dragInput then DoDrag(dragInput) end
    end)
}

-- 8. GUI Construction
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MultiSpamTP_GUI"
ScreenGui.Parent = CoreGui

MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 195) -- Increased height for new buttons
MainFrame.Position = UDim2.new(0.5, -125, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.Parent = ScreenGui

TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "Multi-Point Spam TP"
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.Size = UDim2.new(1, 0, 0, 25)
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
TitleLabel.Parent = MainFrame
MakeDraggable(MainFrame, TitleLabel)

MinMaxButton = Instance.new("TextButton")
MinMaxButton.Text = "-"
MinMaxButton.Font = Enum.Font.SourceSansBold
MinMaxButton.TextSize = 18
MinMaxButton.Size = UDim2.new(0, 25, 0, 25)
MinMaxButton.Position = UDim2.new(1, -25, 0, 0)
MinMaxButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
MinMaxButton.TextColor3 = Color3.new(1, 1, 1)
MinMaxButton.Parent = TitleLabel
MinMaxButton.MouseButton1Click:Connect(ToggleMinimize)

ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -25)
ContentFrame.Position = UDim2.new(0, 0, 0, 25)
ContentFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

-- UI Elements within ContentFrame
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Text = "Spam Interval (Sec):"
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextSize = 14
DelayLabel.Size = UDim2.new(0.5, 0, 0, 20)
DelayLabel.Position = UDim2.new(0, 0, 0, 5)
DelayLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
DelayLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = ContentFrame

DelayBox = Instance.new("TextBox")
DelayBox.Text = tostring(SPAM_INTERVAL)
DelayBox.Font = Enum.Font.SourceSans
DelayBox.TextSize = 14
DelayBox.Size = UDim2.new(0.5, 0, 0, 20)
DelayBox.Position = UDim2.new(0.5, 0, 0, 5)
DelayBox.PlaceholderText = "Enter interval (e.g., 0.01)"
DelayBox.TextColor3 = Color3.new(1, 1, 1)
DelayBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
DelayBox.Parent = ContentFrame

ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Spam_Toggle"
ToggleButton.Size = UDim2.new(1, 0, 0, 35)
ToggleButton.Position = UDim2.new(0, 0, 0, 30)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Parent = ContentFrame
ToggleButton.MouseButton1Click:Connect(ToggleSpam)

local AddButton = Instance.new("TextButton")
AddButton.Text = "Add Current Position (I'm here)"
AddButton.Size = UDim2.new(1, 0, 0, 35)
AddButton.Position = UDim2.new(0, 0, 0, 65)
AddButton.BackgroundColor3 = Color3.new(0.1, 0.5, 0.9)
AddButton.TextColor3 = Color3.new(1, 1, 1)
AddButton.Font = Enum.Font.SourceSans
AddButton.TextSize = 14
AddButton.Parent = ContentFrame
AddButton.MouseButton1Click:Connect(AddDestination)

local ClearButton = Instance.new("TextButton")
ClearButton.Text = "Clear All Destinations"
ClearButton.Size = UDim2.new(1, 0, 0, 35)
ClearButton.Position = UDim2.new(0, 0, 0, 100)
ClearButton.BackgroundColor3 = Color3.new(0.7, 0.3, 0.1) -- Orange-ish
ClearButton.TextColor3 = Color3.new(1, 1, 1)
ClearButton.Font = Enum.Font.SourceSans
ClearButton.TextSize = 14
ClearButton.Parent = ContentFrame
ClearButton.MouseButton1Click:Connect(ClearDestinations)

CoordStatusLabel = Instance.new("TextLabel")
CoordStatusLabel.Text = "0 Destinations Saved"
CoordStatusLabel.Font = Enum.Font.SourceSans
CoordStatusLabel.TextSize = 12
CoordStatusLabel.Size = UDim2.new(1, 0, 0, 20)
CoordStatusLabel.Position = UDim2.new(0, 0, 0, 135)
CoordStatusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
CoordStatusLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
CoordStatusLabel.Parent = ContentFrame

-- Final Initialization
UpdateButtonText() 
print("Multi-Destination Spam Teleporter Script Loaded!")
