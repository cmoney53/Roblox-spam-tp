--[[
    STANDALONE PLAYER TELEPORT GUI

    This script creates a custom GUI for listing all players and provides
    'Bring' (teleport target to you) and 'Teleport To' (teleport you to target)
    functionality without relying on Infinite Yield's internal command system.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Check if LocalPlayer is available
if not LocalPlayer then
    warn("Player Teleport GUI failed to initialize: LocalPlayer is nil.")
    return
end

-- ====================================================================
-- 1. UTILITY FUNCTIONS
-- ====================================================================

local function BringTarget(targetPlayer)
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild('HumanoidRootPart')

    if not localRoot then return "Your character not found." end
    if not targetRoot then return targetPlayer.Name .. " has no character loaded." end
    
    -- Teleport target 3 studs above your head
    local destinationCFrame = localRoot.CFrame * CFrame.new(0, 3, 0)
    targetRoot.CFrame = destinationCFrame
    
    return "SUCCESS: Brought " .. targetPlayer.Name .. " to you."
end

local function TeleportToTarget(targetPlayer)
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild('HumanoidRootPart')

    if not localRoot then return "Your character not found." end
    if not targetRoot then return targetPlayer.Name .. " has no character loaded." end
    
    -- Teleport you 3 studs above the target's head
    local destinationCFrame = targetRoot.CFrame * CFrame.new(0, 3, 0)
    localRoot.CFrame = destinationCFrame
    
    return "SUCCESS: Teleported to " .. targetPlayer.Name .. "."
end

-- Simple Notification System (optional, can be replaced by exploit's notify function if available)
local function SimpleNotify(text)
    print("[TeleportGUI] " .. text)
end

-- ====================================================================
-- 2. GUI SETUP
-- ====================================================================

-- Main Container ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "TeleportPlayerListGui"
gui.IgnoreGuiInset = true -- Optional: keeps UI tight to edges
gui.Parent = CoreGui

-- Main Frame (Centered)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 400)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true -- Allows drag
mainFrame.Draggable = true -- Allows drag
mainFrame.Parent = gui

-- Title Bar
local title = Instance.new("TextLabel")
title.Name = "TitleBar"
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "Player Teleport Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Parent = mainFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 20
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Parent = title

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Player List Scrolling Frame
local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(1, 0, 1, -30) -- Full width, full height minus title bar
playerList.Position = UDim2.new(0, 0, 0, 30)
playerList.CanvasSize = UDim2.new(0, 0, 0, 0) -- Updated by UIListLayout
playerList.ScrollBarThickness = 6
playerList.BackgroundTransparency = 1
playerList.Parent = mainFrame

-- Layout for the player list
local listLayout = Instance.new("UIListLayout")
listLayout.Name = "ListLayout"
listLayout.Padding = UDim.new(0, 2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = playerList

-- Auto Canvas Size setter
local canvasSizer = Instance.new("UISizeConstraint")
canvasSizer.Parent = listLayout
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)


-- ====================================================================
-- 3. PLAYER LISTING AND FUNCTIONALITY
-- ====================================================================

-- Function to create a button entry for a single player
local function CreatePlayerEntry(player)
    
    -- Main Frame for the entry
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = player.Name
    entryFrame.Size = UDim2.new(1, -5, 0, 40) -- Slightly smaller width
    entryFrame.BackgroundTransparency = 1
    entryFrame.Parent = playerList

    -- Player Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextWrapped = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.Padding = UDim.new(0, 5) -- Inner padding
    nameLabel.Parent = entryFrame

    -- Bring Button
    local bringBtn = Instance.new("TextButton")
    bringBtn.Name = "BringButton"
    bringBtn.Size = UDim2.new(0.25, 0, 1, 0)
    bringBtn.Position = UDim2.new(0.5, 0, 0, 0)
    bringBtn.Text = "Bring"
    bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bringBtn.Font = Enum.Font.SourceSansBold
    bringBtn.TextSize = 15
    bringBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    bringBtn.Parent = entryFrame

    bringBtn.MouseButton1Click:Connect(function()
        local result = BringTarget(player)
        SimpleNotify("Bring Result: " .. result)
    end)
    
    -- Teleport To Button
    local tpToBtn = Instance.new("TextButton")
    tpToBtn.Name = "TPToButton"
    tpToBtn.Size = UDim2.new(0.25, 0, 1, 0)
    tpToBtn.Position = UDim2.new(0.75, 0, 0, 0)
    tpToBtn.Text = "TP To"
    tpToBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpToBtn.Font = Enum.Font.SourceSansBold
    tpToBtn.TextSize = 15
    tpToBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    tpToBtn.Parent = entryFrame

    tpToBtn.MouseButton1Click:Connect(function()
        local result = TeleportToTarget(player)
        SimpleNotify("TP To Result: " .. result)
    end)
    
    return entryFrame
end

-- Cache to track which players already have an entry
local playerEntries = {}

-- Main loop to update the player list
RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not playerEntries[player.UserId] then
                -- Player joined: create new entry
                local entry = CreatePlayerEntry(player)
                playerEntries[player.UserId] = entry
            end
        elseif playerEntries[player.UserId] then
            -- This is the local player, ensure they don't have an entry
            playerEntries[player.UserId]:Destroy()
            playerEntries[player.UserId] = nil
        end
    end

    -- Check for players who left
    for userId, entry in pairs(playerEntries) do
        local player = Players:GetPlayerByUserId(userId)
        if not player then
            entry:Destroy()
            playerEntries[userId] = nil
        end
    end
end)

SimpleNotify("Player Teleport GUI loaded successfully. Check CoreGui.")
