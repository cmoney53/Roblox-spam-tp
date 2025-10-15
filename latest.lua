-- =========================================================
--             MULTI-DESTINATION (MINIMAL LENGTH & TOP-RIGHT)
-- =========================================================

local function c(name)
    local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui.Name == name then gui:Destroy() end
    end
end
c("MultiSpamTP_GUI")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local TELEPORT_DESTINATIONS = {}
local SPAM_INTERVAL = 0.05
local IsActive = false
local LoopThread = nil
local IsVisible = true
local MainFrame, ToggleButton, DelayBox, CoordStatusLabel, VisibilityToggle = nil

local function getRootPart()
    local char = LocalPlayer.Character
    if not char then char = LocalPlayer.CharacterAdded:Wait() end
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function StartSpam()
    if LoopThread then task.cancel(LoopThread) end
    if IsActive then
        LoopThread = task.spawn(function()
            local i = 1
            while IsActive do
                local root = getRootPart()
                if not root or #TELEPORT_DESTINATIONS == 0 then IsActive = false; if MainFrame and MainFrame.Parent then UpdateButtonText() end; break end
                pcall(function() root.CFrame = CFrame.new(TELEPORT_DESTINATIONS[i]) end)
                i = i + 1
                if i > #TELEPORT_DESTINATIONS then i = 1 end
                task.wait(SPAM_INTERVAL)
            end
        end)
    end
end

local function UpdateButtonText()
    if ToggleButton then
        ToggleButton.BackgroundColor3 = IsActive and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
        ToggleButton.Text = IsActive and "Spam ON" or "Spam OFF"
    end
end

local function ToggleSpam()
    local newInterval = tonumber(DelayBox.Text)
    SPAM_INTERVAL = (newInterval and newInterval >= 0.001) and newInterval or 0.05
    IsActive = not IsActive
    if not IsActive and LoopThread then task.cancel(LoopThread); LoopThread = nil end
    if IsActive then StartSpam() end
    UpdateButtonText()
end

local function AddDest()
    local root = getRootPart()
    if root then
        local pos = root.Position
        table.insert(TELEPORT_DESTINATIONS, Vector3.new(math.floor(pos.X + 0.5), math.floor(pos.Y + 0.5), math.floor(pos.Z + 0.5)))
        CoordStatusLabel.Text = #TELEPORT_DESTINATIONS .. " Destinations Saved"
        if IsActive then StartSpam() end
    end
end

local function ClearDest()
    TELEPORT_DESTINATIONS = {} 
    IsActive = false
    if LoopThread then task.cancel(LoopThread) end
    CoordStatusLabel.Text = "0 Destinations Saved"
    UpdateButtonText()
end

local function ToggleVis()
    IsVisible = not IsVisible
    if MainFrame then MainFrame.Visible = IsVisible end
    if VisibilityToggle then
        VisibilityToggle.Text = IsVisible and "HIDE" or "SHOW"
        VisibilityToggle.BackgroundColor3 = IsVisible and Color3.new(0.3, 0.3, 0.3) or Color3.new(0.6, 0.6, 0.6)
    end
end

local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

game.Loaded:Wait()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MultiSpamTP_GUI"
ScreenGui.Parent = PlayerGui

-- TOP-RIGHT FIX 1: Visibility Toggle Button
VisibilityToggle = Instance.new("TextButton")
VisibilityToggle.Text = "HIDE"
VisibilityToggle.Font = Enum.Font.SourceSansBold
VisibilityToggle.TextSize = 14
VisibilityToggle.Size = UDim2.new(0, 50, 0, 25)
VisibilityToggle.Position = UDim2.new(1, -55, 0.01, 0) -- Scaled 1, Minus its size (50) + 5px margin
VisibilityToggle.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
VisibilityToggle.TextColor3 = Color3.new(1, 1, 1)
VisibilityToggle.Parent = ScreenGui
VisibilityToggle.MouseButton1Click:Connect(ToggleVis)

-- TOP-RIGHT FIX 2: Main Draggable Frame
MainFrame
