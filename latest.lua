-- =========================================================
--             MULTI-DESTINATION SPAM TELEPORTER (FINAL)
-- =========================================================

-- 1. Setup Global References
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- 2. Configuration Variables
local TELEPORT_DESTINATIONS = {} -- List to hold multiple Vector3 points
local SPAM_INTERVAL = 0.05       -- Default time between teleports (in seconds)

-- 3. State and Thread Management
local IsActive = false           -- Global toggle for the spam loop
local LoopThread = nil           -- Reference to the running spam loop
local IsVisible = true           -- New state variable for the main GUI visibility (starts visible)

-- Helper function to reliably get the character's root part
local function getRootPart()
    local character = LocalPlayer.Character
    if not character then
        character = LocalPlayer.CharacterAdded:Wait()
    end
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- 4. Main Teleport Logic Function (The Cycling Spam Loop)
local function StartTeleportSpam()
    if LoopThread then task.cancel(LoopThread) end

    if IsActive then
        LoopThread = task.spawn(function()
            print("Spam Teleporter ON: Waiting for HumanoidRootPart...")
            local currentIndex = 1
            while IsActive do
                local HumanoidRootPart = getRootPart()
                
                if not HumanoidRootPart then task.wait(0.5); goto continue_loop end
                if #TELEPORT_DESTINATIONS == 0 then
                    warn("No destinations saved. Stopping spam.")
                    IsActive = false
                    UpdateButtonText()
                    break
                end
                
                local success, err = pcall(function()
                    HumanoidRootPart.CFrame = CFrame.new(TELEPORT_DESTINATIONS[currentIndex])
                end)

                if not success then warn("Teleport failed: " .. tostring(err)) end

                currentIndex = currentIndex + 1
                if currentIndex > #TELEPORT_DESTINATIONS then
                    currentIndex = 1
                end
                
                task.wait(SPAM_INTERVAL)
                ::continue_loop::
            end
            print("Spam Teleporter loop stopped.")
        end)
    end
end

-- 5. Add Destination Function
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
        warn("Cannot set position: Character not found.")
    end
end

-- 6. Clear Destinations Function
local function ClearDestinations()
    TELEPORT_DESTINATIONS = {} 
    if IsActive then 
        IsActive = false 
        if LoopThread then task.cancel(LoopThread) end
    end
    CoordStatusLabel.Text = "0 Destinations Saved"
    UpdateButtonText()
    print("Cleared all teleport destinations.")
end

-- 7. GUI Management and Draggable/Show/Hide Logic
local ToggleButton, DelayBox, CoordStatusLabel, MainFrame, TitleLabel, VisibilityToggle = nil
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

-- NEW: Show/Hide Toggle Function
local function ToggleVisibility()
    IsVisible = not IsVisible
    
    if MainFrame then
        MainFrame.Visible = IsVisible
    end
    
    if VisibilityToggle then
        VisibilityToggle.Text = IsVisible and "HIDE" or "SHOW"
        VisibilityToggle.BackgroundColor3 = IsVisible and Color3.new(0.1, 0.1, 0.1) or Color3.new(0.8, 0.8, 0.8)
    end
end

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

    RunService.Heartbeat:Connect(function()
        if dragging and dragInput then DoDrag(dragInput) end
    end)
}

-- 8. GUI Construction
game.Loaded:Wait()
print("Game loaded. Attempting to create GUI.")

-- Create the master ScreenGui first (outside the pcall for the Show/Hide button)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MultiSpamTP_GUI"
ScreenGui.Parent = CoreGui -- Parent to CoreGui for stability

-- Create the separate Visibility Toggle Button (always visible, outside the main frame)
VisibilityToggle = Instance.new("TextButton")
VisibilityToggle.Text = "HIDE" -- Starts visible
VisibilityToggle.Font = Enum.Font.SourceSansBold
VisibilityToggle.TextSize = 14
VisibilityToggle.Size = UDim2.new(0, 50, 0, 20)
VisibilityToggle.Position = UDim2.new(0.01, 0, 0.01, 0) -- Top left corner
VisibilityToggle.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
VisibilityToggle.TextColor3 = Color3.new(1, 1, 1)
VisibilityToggle.Parent = ScreenGui
VisibilityToggle.MouseButton1Click:Connect(ToggleVisibility)

-- Now create the main draggable frame inside a pcall
local guiSuccess, guiResult = pcall(function()

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 250, 0, 195)
    MainFrame.Position = UDim2.new(0.5, -125, 0.1, 0)
    MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    MainFrame.Parent = ScreenGui
    MainFrame.Visible = IsVisible -- Set initial visibility

    TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = "Multi-Point Spam TP"
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 18
    TitleLabel.Size = UDim2.new(1, 0, 0, 25)
    TitleLabel.TextColor3 = Color3.new(1, 1, 1)
    TitleLabel.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    TitleLabel.Parent = MainFrame
    MakeDraggable(MainFrame, TitleLabel)

    -- Content Frame (The body of the GUI)
    ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, 0, 1, -25)
    ContentFrame.Position = UDim2.new(0, 0, 0, 25)
    ContentFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = MainFrame

    -- UI Elements within ContentFrame (Same as before)
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
    ClearButton.BackgroundColor3 = Color3.new(0.7, 0.3, 0.1)
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
    
    UpdateButtonText()
    
end) -- End pcall

if guiSuccess then
    print("Multi-Point Spam TP GUI successfully loaded!")
else
    error("FATAL ERROR: GUI construction failed! Error details: " .. tostring(guiResult))
end
