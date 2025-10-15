-- =========================================================
--             MULTI-DESTINATION (MINIMAL LENGTH)
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

VisibilityToggle = Instance.new("TextButton")
VisibilityToggle.Text = "HIDE"
VisibilityToggle.Font = Enum.Font.SourceSansBold
VisibilityToggle.TextSize = 14
VisibilityToggle.Size = UDim2.new(0, 50, 0, 25)
VisibilityToggle.Position = UDim2.new(0.01, 0, 0.01, 0)
VisibilityToggle.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
VisibilityToggle.TextColor3 = Color3.new(1, 1, 1)
VisibilityToggle.Parent = ScreenGui
VisibilityToggle.MouseButton1Click:Connect(ToggleVis)

MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 200)
MainFrame.Position = UDim2.new(0.5, -100, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.Parent = ScreenGui
MainFrame.Visible = IsVisible

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "Multi-Point Spam TP"
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 16
TitleLabel.Size = UDim2.new(1, 0, 0, 25)
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
TitleLabel.Parent = MainFrame
MakeDraggable(MainFrame, TitleLabel)

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -25)
ContentFrame.Position = UDim2.new(0, 0, 0, 25)
ContentFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Text = "Interval (Sec):"
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
DelayBox.PlaceholderText = "e.g., 0.01"
DelayBox.TextColor3 = Color3.new(1, 1, 1)
DelayBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
DelayBox.Parent = ContentFrame

ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Spam_Toggle"
ToggleButton.Size = UDim2.new(1, 0, 0, 35)
ToggleButton.Position = UDim2.new(0, 0, 0, 30)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 16
ToggleButton.Parent = ContentFrame
ToggleButton.MouseButton1Click:Connect(ToggleSpam)

local AddButton = Instance.new("TextButton")
AddButton.Text = "Add Position"
AddButton.Size = UDim2.new(1, 0, 0, 35)
AddButton.Position = UDim2.new(0, 0, 0, 65)
AddButton.BackgroundColor3 = Color3.new(0.1, 0.5, 0.9)
AddButton.TextColor3 = Color3.new(1, 1, 1)
AddButton.Font = Enum.Font.SourceSans
AddButton.TextSize = 14
AddButton.Parent = ContentFrame
AddButton.MouseButton1Click:Connect(AddDest)

local ClearButton = Instance.new("TextButton")
ClearButton.Text = "Clear All Destinations"
ClearButton.Size = UDim2.new(1, 0, 0, 35)
ClearButton.Position = UDim2.new(0, 0, 0, 100)
ClearButton.BackgroundColor3 = Color3.new(0.7, 0.3, 0.1)
ClearButton.TextColor3 = Color3.new(1, 1, 1)
ClearButton.Font = Enum.Font.SourceSans
ClearButton.TextSize = 14
ClearButton.Parent = ContentFrame
ClearButton.MouseButton1Click:Connect(ClearDest)

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
print("Compressed Multi-Destination Script Loaded!")
