-- =========================================================
--             HYPER-MINIMAL GUI SPAM TP (FINAL)
-- =========================================================

-- Cleanup (Essential for loadstring stability)
local function Cleanup(name)
    local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui.Name == name then gui:Destroy() end
    end
end
Cleanup("SpamTP_Minimal_GUI")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TELEPORT_DESTINATIONS = {}
local SPAM_INTERVAL = 0.05
local IsActive = false
local LoopThread = nil
local MainFrame, ToggleButton, DelayBox, CoordStatusLabel = nil

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
                if not root or #TELEPORT_DESTINATIONS == 0 then IsActive = false; UpdateButtonText(); break end
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
        ToggleButton.Text = IsActive and "SPAM ON" or "SPAM OFF"
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

game.Loaded:Wait()

-- GUI Construction: NO SUB-FRAMES, NO DRAG, just direct buttons.
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpamTP_Minimal_GUI"
ScreenGui.Parent = PlayerGui

MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 160)
MainFrame.Position = UDim2.new(0.5, -90, 0.2, 0) -- Center-Top Placement
MainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
MainFrame.Parent = ScreenGui

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "MULTI-SPAM TP"
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 16
TitleLabel.Size = UDim2.new(1, 0, 0, 25)
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
TitleLabel.Parent = MainFrame

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Text = "Interval (s):"
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextSize = 14
DelayBox = Instance.new("TextBox")
DelayBox.Text = tostring(SPAM_INTERVAL)
DelayBox.Font = Enum.Font.SourceSans
DelayBox.TextSize = 14

DelayLabel.Size = UDim2.new(0.5, 0, 0, 20)
DelayLabel.Position = UDim2.new(0, 0, 0, 30)
DelayLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
DelayLabel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = MainFrame

DelayBox.Size = UDim2.new(0.5, 0, 0, 20)
DelayBox.Position = UDim2.new(0.5, 0, 0, 30)
DelayBox.PlaceholderText = "0.05"
DelayBox.TextColor3 = Color3.new(1, 1, 1)
DelayBox.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
DelayBox.Parent = MainFrame

ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Spam_Toggle"
ToggleButton.Size = UDim2.new(1, 0, 0, 35)
ToggleButton.Position = UDim2.new(0, 0, 0, 55)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 16
ToggleButton.Parent = MainFrame
ToggleButton.MouseButton1Click:Connect(ToggleSpam)

local AddButton = Instance.new("TextButton")
AddButton.Text = "ADD CURRENT POS"
AddButton.Size = UDim2.new(1, 0, 0, 35)
AddButton.Position = UDim2.new(0, 0, 0, 90)
AddButton.BackgroundColor3 = Color3.new(0.1, 0.5, 0.9)
AddButton.TextColor3 = Color3.new(1, 1, 1)
AddButton.Font = Enum.Font.SourceSansBold
AddButton.TextSize = 14
AddButton.Parent = MainFrame
AddButton.MouseButton1Click:Connect(AddDest)

local ClearButton = Instance.new("TextButton")
ClearButton.Text = "CLEAR ALL"
ClearButton.Size = UDim2.new(1, 0, 0, 15)
ClearButton.Position = UDim2.new(0, 0, 0, 125)
ClearButton.BackgroundColor3 = Color3.new(0.7, 0.3, 0.1)
ClearButton.TextColor3 = Color3.new(1, 1, 1)
ClearButton.Font = Enum.Font.SourceSansBold
ClearButton.TextSize = 12
ClearButton.Parent = MainFrame
ClearButton.MouseButton1Click:Connect(ClearDest)

CoordStatusLabel = Instance.new("TextLabel")
CoordStatusLabel.Text = "0 Destinations Saved"
CoordStatusLabel.Font = Enum.Font.SourceSans
CoordStatusLabel.TextSize = 12
CoordStatusLabel.Size = UDim2.new(1, 0, 0, 20)
CoordStatusLabel.Position = UDim2.new(0, 0, 0, 140)
CoordStatusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
CoordStatusLabel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
CoordStatusLabel.Parent = MainFrame

UpdateButtonText()
print("Hyper-Minimal Spam TP GUI Loaded!")
