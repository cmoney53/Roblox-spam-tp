--[[
    PLAYER TELEPORT GUI - VERSION 2.0 (MAXIMUM SERVER-SIDE FORCE)
    
    This script implements a multi-phase attack in the 'BringTarget' function 
    to bypass robust anti-exploit measures and force a server-side teleport.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer 

if not LocalPlayer then return end

-- ====================================================================
-- 1. UTILITY FUNCTIONS (SERVER-SIDE FORCE 2.0)
-- ====================================================================

local function SimpleNotify(text)
    -- Prints a message to the executor console
    print("[TeleportGUI] " .. text)
end

-- Function to find RemoteEvents with common names throughout the game instance
local function FindRemoteEvent(name)
    local success, result = pcall(function()
        return game:FindFirstChild(name, true)
    end)
    return success and result and result:IsA("RemoteEvent") and result
end

local function BringTarget(targetPlayer)
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild('HumanoidRootPart')
    local targetHumanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChild('Humanoid')

    if not localRoot or not targetRoot or not targetHumanoid then
        SimpleNotify("Character data not fully found for " .. targetPlayer.Name .. ".") 
        return
    end
    
    -- Calculate the destination CFrame (3 studs above your head)
    local newCFrame = localRoot.CFrame * CFrame.new(0, 3, 0)

    SimpleNotify("Attempting Multi-Phase Bring on " .. targetPlayer.Name .. "...")

    -- PHASE 1: NETWORK OWNERSHIP HIJACK (Aggressive, often patched)
    -- Temporarily steal network ownership to make the server trust our position update.
    targetRoot:SetNetworkOwner(nil) -- Clear old owner
    targetRoot:SetNetworkOwner(LocalPlayer) -- Set to local player

    -- PHASE 2: AGGRESSIVE LOCAL WARP AND PHYSICS LOCK
    targetRoot.CFrame = newCFrame
    targetRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    targetRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    targetHumanoid.PlatformStand = true -- Lock target movement
    wait(0.05) -- Brief pause for physics update

    -- PHASE 3: REMOTE EVENT SPOOFING (Most likely to succeed)
    local remote = FindRemoteEvent("RemoteTeleport") or 
                   FindRemoteEvent("SetPosition") or 
                   FindRemoteEvent("MoveTo") or
                   FindRemoteEvent("UpdateCharacter")
    
    if remote then
        pcall(function()
            -- Fire the event with the new position, making it look like a valid request
            remote:FireServer(targetPlayer, targetRoot, newCFrame) 
        end)
        SimpleNotify("Executed Remote Spoof via: " .. remote.Name)
    end
    
    -- PHASE 4: FORCED STATE SYNCHRONIZATION
    -- Force a state change that makes the server re-evaluate the character's position.
    pcall(function()
        targetHumanoid.Sit = true
        wait(0.1)
        targetHumanoid.Sit = false
    end)
    targetHumanoid.PlatformStand = false -- Release movement lock

    -- PHASE 5: RELEASE OWNERSHIP (Essential for them to regain control)
    targetRoot:SetNetworkOwner(targetPlayer) 
    
    SimpleNotify("COMPLETED: Multi-Phase Server Bring executed on " .. targetPlayer.Name .. ".")
end

local function TeleportToTarget(targetPlayer)
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild('HumanoidRootPart')

    if not localRoot or not targetRoot then return end
    
    -- Teleport *you* (LocalPlayer) to them (Client-side is fine for self-teleport)
    local destinationCFrame = targetRoot.CFrame * CFrame.new(0, 3, 0)
    localRoot.CFrame = destinationCFrame
    
    SimpleNotify("SUCCESS: Teleported to " .. targetPlayer.Name .. ".")
end

-- ====================================================================
-- 2. GUI SETUP (No changes to layout)
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
title.Text = "Player Teleport Menu (2.0)"
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
-- 3. PLAYER LISTING AND FUNCTIONALITY
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
        BringTarget(player) 
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
        TeleportToTarget(player) 
    end)
    
    return entryFrame
end

local function GetReliablePlayers()
    -- Uses both methods for robust detection against sandboxes
    local playerTable = Players:GetPlayers()
    if #playerTable == 0 and #Players:GetChildren() > 0 then
        playerTable = Players:GetChildren()
    end
    return playerTable
end

-- Main loop to update the player list
RunService.Heartbeat:Connect(function()
    local currentPlayers = GetReliablePlayers()
    local playersInServer = {}

    for _, instance in ipairs(currentPlayers) do
        if instance:IsA("Player") and instance.UserId ~= LocalPlayer.UserId then
            playersInServer[instance.UserId] = true
            
            if not playerEntries[instance.UserId] then
                local entry = CreatePlayerEntry(instance)
                playerEntries[instance.UserId] = entry
            end
        end
    end

    for userId, entry in pairs(playerEntries) do
        if not playersInServer[userId] then
            entry:Destroy()
            playerEntries[userId] = nil
        end
    end
end)

SimpleNotify("Player Teleport GUI 2.0 loaded. Aggressive Server-Side Bring activated.")
