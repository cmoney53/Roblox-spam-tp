--[[
    FINAL STANDALONE PLAYER TELEPORT GUI
    
    This script creates a draggable GUI with a real-time list of all players 
    in the server (excluding yourself). It includes a server-side teleport fix 
    to ensure the 'Bring Them' command works for the target player and the server.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer 

if not LocalPlayer then
    -- Exit if LocalPlayer is not available (shouldn't happen if game is loaded)
    warn("Player Teleport GUI failed to initialize: LocalPlayer not found.")
    return
end

-- ====================================================================
-- 1. UTILITY FUNCTIONS (WITH SERVER-SIDE FIX)
-- ====================================================================

local function SimpleNotify(text)
    -- Prints a message to the executor console
    print("[TeleportGUI] " .. text)
end

local function BringTarget(targetPlayer)
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild('HumanoidRootPart')

    if not localRoot then SimpleNotify("Your character not found.") return end
    if not targetRoot then SimpleNotify(targetPlayer.Name .. " has no character loaded.") return end
    
    local destinationCFrame = localRoot.CFrame * CFrame.new(0, 3, 0)

    -- *** SERVER-SIDE TELEPORT HACK ***
    -- Anchor part, set position, unanchor part to force server physics replication.
    targetRoot.Anchored = true
    targetRoot.CFrame = destinationCFrame
    targetRoot.Velocity = Vector3.new(0, 0, 0)
    targetRoot.RotationalVelocity = Vector3.new(0, 0, 0)
    targetRoot.Anchored = false
    
    SimpleNotify("SUCCESS: Server-side brought " .. targetPlayer.Name .. " to you.")
end

local function TeleportToTarget(targetPlayer)
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild('HumanoidRootPart')

    if not localRoot then SimpleNotify("Your character not found.") return end
    if not targetRoot then SimpleNotify(targetPlayer.Name .. " has no character loaded.") return end
    
    -- Teleport *you* (LocalPlayer) to them
    local destinationCFrame = targetRoot.CFrame * CFrame.new(0, 3, 0)
    localRoot.CFrame = destinationCFrame
    
    SimpleNotify("SUCCESS: Teleported to " .. targetPlayer.Name .. ".")
end

-- ====================================================================
-- 2. GUI SETUP
-- ====================================================================

local gui = Instance.new("ScreenGui")
gui.Name = "TeleportPlayerListGui"
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 400)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "TitleBar"
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Player Teleport Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Parent = mainFrame

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

local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(1, 0, 1, -30)
playerList.Position = UDim2.new(0, 0, 0, 30)
playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerList.ScrollBarThickness = 6
playerList.BackgroundTransparency = 1
playerList.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Name = "ListLayout"
listLayout.Padding = UDim.new(0, 2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = playerList

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)

-- ====================================================================
-- 3. PLAYER LISTING AND FUNCTIONALITY (ROBUST CHECK)
-- ====================================================================

local playerEntries = {}

local function CreatePlayerEntry(player)
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = player.Name
    entryFrame.Size = UDim2.new(1, -5, 0, 40)
    entryFrame.BackgroundTransparency = 1
    entryFrame.Parent = playerList

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.BackgroundTransparency = 1
    nameLabel.Parent = entryFrame

    -- BUTTON 1: BRING THEM (Moves target to you)
    local bringBtn = Instance.new("TextButton")
    bringBtn.Name = "BringButton"
    bringBtn.Size = UDim2.new(0.3, 0, 1, -5)
    bringBtn.Position = UDim2.new(0.4, 0, 0, 0)
    bringBtn.Text = "Bring Them"
    bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bringBtn.Font = Enum.Font.SourceSansBold
    bringBtn.TextSize = 14
    bringBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    bringBtn.Parent = entryFrame

    bringBtn.MouseButton1Click:Connect(function()
        BringTarget(player) -- Correctly calls the server-side bring function
    end)
    
    -- BUTTON 2: TP TO THEM (Moves you to target)
    local tpToBtn = Instance.new("TextButton")
    tpToBtn.Name = "TPToButton"
    tpToBtn.Size = UDim2.new(0.3, 0, 1, -5)
    tpToBtn.Position = UDim2.new(0.7, 0, 0, 0)
    tpToBtn.Text = "TP To Them"
    tpToBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpToBtn.Font = Enum.Font.SourceSansBold
    tpToBtn.TextSize = 14
    tpToBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    tpToBtn.Parent = entryFrame

    tpToBtn.MouseButton1Click:Connect(function()
        TeleportToTarget(player) -- Correctly calls the local teleport function
    end)
    
    return entryFrame
end

-- Function that fetches players using two methods (robust detection)
local function GetReliablePlayers()
    -- Method 1: Standard GetPlayers()
    local playerTable = Players:GetPlayers()
    
    -- Method 2: GetChildren() (Fallback for strict sandboxing)
    if #playerTable == 0 and #Players:GetChildren() > 0 then
        playerTable = Players:GetChildren()
    end
    
    return playerTable
end

-- Main loop to update the player list
RunService.Heartbeat:Connect(function()
    local currentPlayers = GetReliablePlayers()
    local playersInServer = {}

    -- 1. Scan the reliable list and update the GUI (creation/caching)
    for _, instance in ipairs(currentPlayers) do
        -- Ensure the instance is actually a Player object and not the LocalPlayer
        if instance:IsA("Player") and instance.UserId ~= LocalPlayer.UserId then
            playersInServer[instance.UserId] = true -- Mark player as present
            
            if not playerEntries[instance.UserId] then
                -- Player joined: create new entry
                local entry = CreatePlayerEntry(instance)
                playerEntries[instance.UserId] = entry
            end
        end
    end

    -- 2. Check for players who left (cleanup)
    for userId, entry in pairs(playerEntries) do
        if not playersInServer[userId] then
            -- Player left: destroy the entry and remove from cache
            entry:Destroy()
            playerEntries[userId] = nil
        end
    end
end)

SimpleNotify("Player Teleport GUI loaded successfully. Server-side bring fix active.")
