--[[
=========================================================
       DUAL-PANEL HARVESTER & EXECUTOR (FINAL SCRIPT)
=========================================================

This script combines the deep remote event scanner (Harvester)
with a dedicated execution panel (Executor) to find and use
vulnerable server commands to bring a target player.
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Shared State
local TargetPathTextBox = nil
local TargetPlayerTextBox = nil
local StatusLabel = nil

-- =========================================================
-- 1. HARVESTER LOGIC (Remote Scanner)
-- =========================================================

local function is_suspicious(name)
    local lower_name = name:lower()
    return lower_name:find("teleport") or
           lower_name:find("tp") or
           lower_name:find("admin") or
           lower_name:find("kill") or
           lower_name:find("warp") or
           lower_name:find("kick") or
           lower_name:find("force") or
           lower_name:find("move")
end

local function deep_scan(parent, path_parts, results)
    if #path_parts > 8 then return end -- Prevent infinite loops/depth explosion

    for _, child in ipairs(parent:GetChildren()) do
        local new_path_parts = {table.unpack(path_parts), child.Name}
        local current_path = table.concat(new_path_parts, ".")

        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            if is_suspicious(child.Name) then
                table.insert(results, {
                    Name = child.Name,
                    Type = child.ClassName,
                    Path = current_path
                })
            end
        end
        
        -- Recursively check containers, but ignore character models and large instances
        if child:IsA("Folder") or child:IsA("Part") or child:IsA("Model") or child:IsA("Configuration") or child:IsA("ScreenGui") then
             if not child:IsA("Model") or child ~= LocalPlayer.Character then -- Avoid scanning character parts
                deep_scan(child, new_path_parts, results)
             end
        end
    end
end


-- =========================================================
-- 2. EXECUTOR LOGIC (Command Runner)
-- =========================================================

local function getRemoteByPath(path_string)
    local parts = path_string:split(".")
    local current = game
    for i, part in ipairs(parts) do
        if i == 1 then continue end -- Skip 'game'
        if current then
            current = current:FindFirstChild(part)
        else
            return nil
        end
    end
    return current
end

local function BringTarget(remotePath, targetName)
    local remote = getRemoteByPath(remotePath)
    local target = Players:FindFirstChild(targetName)
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not remote then
        StatusLabel.Text = "ERROR: Remote not found at path!"
        return
    end
    if not target then
        StatusLabel.Text = "ERROR: Target player not found!"
        return
    end
    if not rootPart then
        StatusLabel.Text = "ERROR: Your character not found!"
        return
    end
    
    local playerPos = rootPart.Position + Vector3.new(0, 5, 0)

    -- Attempt 1: Player Object, Target Position
    pcall(function()
        remote:FireServer(target, playerPos)
        StatusLabel.Text = "Attempt 1 Fired (Target, Position)"
    end)
    task.wait(0.1)

    -- Attempt 2: Target Name, Target Position
    pcall(function()
        remote:FireServer(target.Name, playerPos)
        StatusLabel.Text = "Attempt 2 Fired (Name, Position)"
    end)
    task.wait(0.1)

    -- Attempt 3: Just Target Name (for common admin scripts)
    pcall(function()
        remote:FireServer(target.Name, "teleport", playerPos)
        StatusLabel.Text = "Attempt 3 Fired (Name, Command, Position)"
    end)
end


-- =========================================================
-- 3. GUI CREATION
-- =========================================================

-- Cleanup existing GUI
local function Cleanup(name)
    local existing = CoreGui:FindFirstChild(name)
    if existing then existing:Destroy() end
end
Cleanup("Dual_Panel_Exploit_GUI")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Dual_Panel_Exploit_GUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 700, 0, 400)
MainFrame.Position = UDim2.new(0.5, -350, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Title Bar (for dragging)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 25)
TitleBar.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "DUAL-PANEL HARVESTER & EXECUTOR"
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, -25, 1, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 25, 1, 0)
CloseButton.Position = UDim2.new(1, -25, 0, 0)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
CloseButton.Parent = TitleBar
CloseButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Draggable functionality
local drag = false
local offset = Vector2.new(0, 0)
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = true
        offset = input.Position - MainFrame.AbsolutePosition
        TitleBar.BackgroundColor3 = Color3.new(0.3, 0.3, 0.4)
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = false
        TitleBar.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        MainFrame.Position = UDim2.fromOffset(input.Position.X - offset.X, input.Position.Y - offset.Y)
    end
end)


-- =================== LEFT PANEL (HARVESTER) ===================
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0.5, 0, 1, -25)
LeftPanel.Position = UDim2.new(0, 0, 0, 25)
LeftPanel.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
LeftPanel.Parent = MainFrame

local ScanButton = Instance.new("TextButton")
ScanButton.Size = UDim2.new(1, -10, 0, 30)
ScanButton.Position = UDim2.new(0, 5, 0, 5)
ScanButton.Text = "RUN ULTIMATE HARVEST"
ScanButton.BackgroundColor3 = Color3.new(0.5, 0.2, 0.8)
ScanButton.TextColor3 = Color3.new(1, 1, 1)
ScanButton.Font = Enum.Font.SourceSansBold
ScanButton.TextSize = 16
ScanButton.Parent = LeftPanel

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -45)
ScrollFrame.Position = UDim2.new(0, 5, 0, 40)
ScrollFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = LeftPanel

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 2)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollFrame

local function CreateResultEntry(data, y_offset)
    local EntryButton = Instance.new("TextButton")
    EntryButton.Size = UDim2.new(1, 0, 0, 20)
    EntryButton.TextXAlignment = Enum.TextXAlignment.Left
    EntryButton.Text = string.format(" [%s] %s", data.Type:sub(1, 3), data.Name)
    EntryButton.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    EntryButton.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    EntryButton.TextSize = 14
    EntryButton.Font = Enum.Font.SourceSans
    EntryButton.Parent = ScrollFrame
    EntryButton.LayoutOrder = y_offset

    EntryButton.MouseButton1Click:Connect(function()
        if TargetPathTextBox then
            TargetPathTextBox.Text = data.Path
            StatusLabel.Text = "Path Loaded: " .. data.Path
        end
    end)
end

local function PopulateResults(results)
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local y_offset = 0
    for _, data in ipairs(results) do
        CreateResultEntry(data, y_offset)
        y_offset = y_offset + 1
    end
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #results * 22) -- 20 height + 2 padding
end

ScanButton.MouseButton1Click:Connect(function()
    local results = {}
    ScanButton.Text = "SCANNING..."
    ScanButton.BackgroundColor3 = Color3.new(0.8, 0.5, 0.2)
    StatusLabel.Text = "Scanning game for suspicious remote events/functions..."

    -- Scan main service containers
    deep_scan(ReplicatedStorage, {"game", "ReplicatedStorage"}, results)
    deep_scan(game:GetService("Workspace"), {"game", "Workspace"}, results)
    deep_scan(game:GetService("Lighting"), {"game", "Lighting"}, results)
    
    PopulateResults(results)
    
    ScanButton.Text = "RUN ULTIMATE HARVEST (COMPLETE)"
    ScanButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    StatusLabel.Text = string.format("HARVEST COMPLETE: Found %d suspicious remotes.", #results)
end)

-- =================== RIGHT PANEL (EXECUTOR) ===================
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.5, 0, 1, -25)
RightPanel.Position = UDim2.new(0.5, 0, 0, 25)
RightPanel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
RightPanel.Parent = MainFrame

-- Remote Path Text Box
local PathLabel = Instance.new("TextLabel")
PathLabel.Size = UDim2.new(1, -10, 0, 20)
PathLabel.Position = UDim2.new(0, 5, 0, 5)
PathLabel.Text = "REMOTE PATH (Click left panel to load)"
PathLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
PathLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
PathLabel.Font = Enum.Font.SourceSansBold
PathLabel.TextSize = 14
PathLabel.TextXAlignment = Enum.TextXAlignment.Left
PathLabel.Parent = RightPanel

TargetPathTextBox = Instance.new("TextBox")
TargetPathTextBox.Size = UDim2.new(1, -10, 0, 25)
TargetPathTextBox.Position = UDim2.new(0, 5, 0, 25)
TargetPathTextBox.PlaceholderText = "e.g., game.ReplicatedStorage.RemoteEvents.TeleportPlayerEvent"
TargetPathTextBox.Text = ""
TargetPathTextBox.TextColor3 = Color3.new(1, 1, 1)
TargetPathTextBox.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
TargetPathTextBox.Font = Enum.Font.SourceSans
TargetPathTextBox.TextSize = 14
TargetPathTextBox.Parent = RightPanel

-- Target Player Text Box
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -10, 0, 20)
TargetLabel.Position = UDim2.new(0, 5, 0, 60)
TargetLabel.Text = "TARGET PLAYER NAME"
TargetLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
TargetLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
TargetLabel.Font = Enum.Font.SourceSansBold
TargetLabel.TextSize = 14
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = RightPanel

TargetPlayerTextBox = Instance.new("TextBox")
TargetPlayerTextBox.Size = UDim2.new(1, -10, 0, 25)
TargetPlayerTextBox.Position = UDim2.new(0, 5, 0, 80)
TargetPlayerTextBox.PlaceholderText = "e.g., 'TargetPlayerName'"
TargetPlayerTextBox.Text = ""
TargetPlayerTextBox.TextColor3 = Color3.new(1, 1, 1)
TargetPlayerTextBox.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
TargetPlayerTextBox.Font = Enum.Font.SourceSans
TargetPlayerTextBox.TextSize = 14
TargetPlayerTextBox.Parent = RightPanel

-- Execution Button
local ExecuteButton = Instance.new("TextButton")
ExecuteButton.Size = UDim2.new(1, -10, 0, 40)
ExecuteButton.Position = UDim2.new(0, 5, 0, 120)
ExecuteButton.Text = "ATTEMPT FINAL BRING (3 PARAMETER COMBOS)"
ExecuteButton.BackgroundColor3 = Color3.new(0.9, 0.1, 0.1)
ExecuteButton.TextColor3 = Color3.new(1, 1, 1)
ExecuteButton.Font = Enum.Font.SourceSansBold
ExecuteButton.TextSize = 16
ExecuteButton.Parent = RightPanel

ExecuteButton.MouseButton1Click:Connect(function()
    local remotePath = TargetPathTextBox.Text
    local targetName = TargetPlayerTextBox.Text
    if remotePath == "" or targetName == "" then
        StatusLabel.Text = "ERROR: Both Remote Path and Target Player Name must be filled."
        return
    end
    ExecuteButton.Text = "ATTEMPTING..."
    ExecuteButton.BackgroundColor3 = Color3.new(0.8, 0.5, 0.2)
    BringTarget(remotePath, targetName)
    ExecuteButton.Text = "ATTEMPT FINAL BRING (3 PARAMETER COMBOS)"
    ExecuteButton.BackgroundColor3 = Color3.new(0.9, 0.1, 0.1)
end)


-- =================== STATUS BAR (Shared) ===================
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, 0, 0, 20)
StatusBar.Position = UDim2.new(0, 0, 1, -20)
StatusBar.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
StatusBar.Parent = MainFrame

StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.Text = "Ready. Click 'RUN ULTIMATE HARVEST' to start scanning."
StatusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
StatusLabel.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 14
StatusLabel.Parent = StatusBar

print("Dual-Panel Harvester & Executor GUI Script Loaded.")
