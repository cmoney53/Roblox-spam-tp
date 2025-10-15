-- =========================================================
--             EXTREME COMPATIBILITY GUI FIX
-- =========================================================

-- 1. Setup Global References
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- 2. Configuration Variables
local TELEPORT_DESTINATIONS = {}
local SPAM_INTERVAL = 0.05

-- 3. State and Thread Management
local IsActive = false
local LoopThread = nil
local IsMinimized = false

-- Helper function to reliably get the character's root part
local function getRootPart()
    local character = LocalPlayer.Character
    if not character then
        -- Wait for character to load if it hasn't (more robust)
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
                
                if not HumanoidRootPart then 
                    task.wait(0.5)
                    goto continue_loop
                end
                if #TELEPORT_DESTINATIONS == 0 then
                    warn("No destinations saved. Stopping spam.")
                    IsActive = false
                    UpdateButtonText()
                    break
                end
                
                local success, err = pcall(function()
                    HumanoidRootPart.CFrame = CFrame.new(TELEPORT_DESTINATIONS[currentIndex])
                end)

                if not success then
                    warn("Teleport failed: " .. tostring(err))
                end

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

-- 5. Add/Clear Destination Functions (omitted for brevity, assume working)
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

-- 7. GUI Management and Draggable/Collapsible Logic (omitted for brevity, assume working)
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
        MainFrame:TweenSize(UDim2.new(0, 250, 0, 195), "Out", "Quad", 0.2, true)
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

    RunService.Heartbeat:Connect(function()
        if dragging and dragInput then DoDrag(dragInput) end
    end)
end
---
## 8. GUI Construction (Extreme Compatibility Fix)

-- 🌟 FIX 1: Ensure the game is loaded before trying to create the GUI
game.Loaded:Wait()
print("Game loaded. Attempting to create GUI.")

local guiSuccess, guiResult = pcall(function()
    
    -- We can try parenting to PlayerGui if CoreGui fails (depends on executor)
    local targetGui = CoreGui
    if not targetGui then 
        warn("CoreGui not found. Falling back to PlayerGui.")
        targetGui = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MultiSpamTP_GUI"
    ScreenGui.Parent = targetGui -- FIX 2: Use the determined target

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 250, 0, 195)
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

    -- Delay Label
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

    -- Delay Box
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

    -- Toggle Button
    ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Spam_Toggle"
    ToggleButton.Size = UDim2.new(1, 0, 0, 35)
    ToggleButton.Position = UDim2.new(0, 0, 0, 30)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 18
    ToggleButton.Parent = ContentFrame
    ToggleButton.MouseButton1Click:Connect(ToggleSpam)

    -- Add Button
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

    -- Clear Button
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

    -- Coordinate Status Label
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
