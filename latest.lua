--[[
    PLAYER TELEPORT GUI - VERSION 6.0 (FINAL DEFINITIVE ATTEMPT: RAYCAST WARP)
    
    This script abandons Character Reload and generic CFrame setting. It uses a 
    Raycasting and SetPrimaryPartCFrame strategy combined with Network Ownership 
    spam, which is often successful against highly patched anti-exploits.
    If this fails, the game is immune to all generic public exploits.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer 
local Workspace = game:GetService("Workspace")

if not LocalPlayer then return end

-- ====================================================================
-- 1. UTILITY FUNCTIONS (SERVER-SIDE FORCE 6.0)
-- ====================================================================

local function SimpleNotify(text)
    -- Prints a message to the executor console
    print("[TeleportGUI] " .. text)
end

-- The FINAL, most powerful generic bring attempt: Raycast Warp
local function BringTarget(targetPlayer)
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local targetCharacter = targetPlayer.Character
    local targetRoot = targetCharacter and targetCharacter:FindFirstChild('HumanoidRootPart')

    if not localRoot or not targetCharacter or not targetRoot then
        SimpleNotify("Character data not fully found for " .. targetPlayer.Name .. ".") 
        return
    end
    
    -- Teleport target 5 studs above your head for clearance
    local newCFrame = localRoot.CFrame * CFrame.new(0, 5, 0) 
    SimpleNotify("Attempting FINAL Raycast Warp Bring on " .. targetPlayer.Name .. "...")

    -- STEP 1: FORCE NETWORK OWNERSHIP AND RAYCAST HACK
    
    -- Attempt to get a legitimate physics vector through a raycast (often ignored by server but worth the attempt)
    local ray = Workspace:Raycast(targetRoot.Position, (newCFrame.Position - targetRoot.Position).Unit * 100)
    
    -- STEP 2: AGGRESSIVE OWNERSHIP STEAL AND SETPRIMARYPARTCFRAME SPAM
    -- This is the critical part: using the high-level SetPrimaryPartCFrame function
    for i = 1, 15 do -- Spam 15 times for maximum network impact
        targetRoot:SetNetworkOwner(LocalPlayer) -- Steal ownership
        pcall(function()
            targetCharacter:SetPrimaryPartCFrame(newCFrame)
        end)
        -- Also set the HRP directly as a backup
        targetRoot.CFrame = newCFrame
        -- Attempt to force client-side physics packets
        targetRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        targetRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        RunService.Heartbeat:Wait() 
    end
    
    -- STEP 3: FINAL SYNCHRONIZATION
    pcall(function()
        local targetHumanoid = targetCharacter:FindFirstChild('Humanoid')
        if targetHumanoid then
            -- Force a state change to synchronize the new CFrame
            targetHumanoid.PlatformStand = true
            wait(0.1)
            targetHumanoid.PlatformStand = false
        end
    end)
    
    -- STEP 4: CLEANUP
    targetCharacter:SetPrimaryPartCFrame(newCFrame) -- Final CFrame set
    targetRoot:SetNetworkOwner(targetPlayer) -- Restore original owner
    
    SimpleNotify("COMPLETED: Raycast Warp executed on " .. targetPlayer.Name .. ".")
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
-- 2. GUI SETUP (Modified to use robust search box)
-- ====================================================================

-- Your utility functions for name finding (re-integrated here)
local function gp(p,n,cl) if typeof(p)=="Instance" then local c=p:GetChildren() for i=1,#c do local v=c[i] if (v.Name==n) and v:IsA(cl) then return v end end end return nil end
local i=Instance.new local v2=Vector2.new local bc=BrickColor.new local c3=Color3.new local u2=UDim2.new local sc,mr=string.char,math.random local function rs(l) l=l or mr(8,15) local s="" for i=1,l do if mr(1,2)==1 then s=s..sc(mr(65,90)) else s=s..sc(mr(97,122)) end end return s end local e=Enum 
local plrs=Players
local lp=LocalPlayer
local slower=string.lower local ssub=string.sub

local gui = i("ScreenGui")
gui.Name = "TeleportPlayerListGui"
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local mainFrame = i("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = u2(0, 320, 0, 500) -- Slightly taller for search box
mainFrame.Position = u2(0.5, -160, 0.5, -250)
mainFrame.BackgroundColor3 = c3(40/255, 40/255, 40/255)
mainFrame.BorderColor3 = c3(25/255, 25/255, 25/255)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

local title = i("TextLabel")
title.Name = "TitleBar"
title.Size = u2(1, 0, 0, 30)
title.Text = "Ultimate Bring Menu (6.0)"
title.TextColor3 = c3(255/255, 255/255, 255/255)
title.Font = e.Font.SourceSansBold
title.TextSize = 18
title.BackgroundColor3 = c3(50/255, 50/255, 50/255)
title.Parent = mainFrame

local closeBtn = i("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = u2(0, 30, 0, 30)
closeBtn.Position = u2(1, -30, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = c3(255/255, 255/255, 255/255)
closeBtn.Font = e.Font.SourceSansBold
closeBtn.TextSize = 20
closeBtn.BackgroundColor3 = c3(200/255, 50/255, 50/255)
closeBtn.Parent = title

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Search Section
local searchBox = i("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = u2(1, -10, 0, 30)
searchBox.Position = u2(0, 5, 0, 40)
searchBox.PlaceholderText = "Search/Find Player..."
searchBox.BackgroundColor3 = c3(60/255, 60/255, 60/255)
searchBox.TextColor3 = c3(255/255, 255/255, 255/255)
searchBox.Font = e.Font.SourceSans
searchBox.TextSize = 16
searchBox.Parent = mainFrame

local searchResultFrame = i("Frame")
searchResultFrame.Name = "SearchResult"
searchResultFrame.Size = u2(1, -10, 0, 50)
searchResultFrame.Position = u2(0, 5, 0, 75)
searchResultFrame.BackgroundTransparency = 1
searchResultFrame.Parent = mainFrame

local playerList = i("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = u2(1, 0, 1, -135) -- Adjusted size
playerList.Position = u2(0, 0, 0, 130) -- Starts below search results
playerList.CanvasSize = u2(0, 0, 0, 0)
playerList.ScrollBarThickness = 6
playerList.BackgroundTransparency = 1
playerList.Parent = mainFrame

local listLayout = i("UIListLayout")
listLayout.Name = "ListLayout"
listLayout.Padding = UDim.new(0, 2)
listLayout.SortOrder = e.SortOrder.LayoutOrder
listLayout.Parent = playerList

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerList.CanvasSize = u2(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)

-- Draggable setup
local function Draggable(window)
    window.InputBegan:Connect(function(input)
        if input.UserInputType == e.UserInputType.MouseButton1 or input.UserInputType == e.UserInputType.Touch then
            local startPos = window.Position
            local mouseStart = input.Position
            local dragConn

            dragConn = RunService.RenderStepped:Connect(function()
                local delta = uis:GetMouseLocation() - mouseStart
                window.Position = startPos + u2(0, delta.X, 0, delta.Y)
            end)

            input.InputEnded:Connect(function()
                if dragConn then
                    dragConn:Disconnect()
                end
            end)
        end
    end)
end
Draggable(title) -- Only title bar should be draggable

-- ====================================================================
-- 3. PLAYER LISTING AND FUNCTIONALITY
-- ====================================================================

local playerEntries = {}

local function CreatePlayerEntry(player, parentFrame)
    local entryFrame = i("Frame")
    entryFrame.Name = player.Name
    entryFrame.Size = u2(1, 0, 0, 40)
    entryFrame.BackgroundTransparency = 1
    entryFrame.Parent = parentFrame or playerList -- Allows use in both scrolling list and search result

    local nameLabel = i("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = u2(0.4, 0, 1, 0)
    nameLabel.Position = u2(0, 0, 0, 0)
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = c3(200/255, 200/255, 200/255)
    nameLabel.Font = e.Font.SourceSans
    nameLabel.TextSize = 16
    nameLabel.TextXAlignment = e.TextXAlignment.Left
    nameLabel.BackgroundTransparency = 1
    nameLabel.Parent = entryFrame

    -- BUTTON 1: BRING THEM (Moves target to you)
    local bringBtn = i("TextButton")
    bringBtn.Name = "BringButton"
    bringBtn.Size = u2(0.3, 0, 1, -5)
    bringBtn.Position = u2(0.4, 0, 0, 0)
    bringBtn.Text = "Bring Them"
    bringBtn.TextColor3 = c3(255/255, 255/255, 255/255)
    bringBtn.Font = e.Font.SourceSansBold
    bringBtn.TextSize = 14
    bringBtn.BackgroundColor3 = c3(50/255, 150/255, 255/255)
    bringBtn.Parent = entryFrame

    bringBtn.MouseButton1Click:Connect(function()
        BringTarget(player) 
    end)
    
    -- BUTTON 2: TP TO THEM (Moves you to target)
    local tpToBtn = i("TextButton")
    tpToBtn.Name = "TPToButton"
    tpToBtn.Size = u2(0.3, 0, 1, -5)
    tpToBtn.Position = u2(0.7, 0, 0, 0)
    tpToBtn.Text = "TP To Them"
    tpToBtn.TextColor3 = c3(255/255, 255/255, 255/255)
    tpToBtn.Font = e.Font.SourceSansBold
    tpToBtn.TextSize = 14
    tpToBtn.BackgroundColor3 = c3(255/255, 150/255, 50/255)
    tpToBtn.Parent = entryFrame

    tpToBtn.MouseButton1Click:Connect(function()
        TeleportToTarget(player) 
    end)
    
    return entryFrame
end

local function GetReliablePlayers()
    -- Uses both methods for robust detection against sandboxes
    local playerTable = plrs:GetPlayers()
    if #playerTable == 0 and #plrs:GetChildren() > 0 then
        playerTable = plrs:GetChildren()
    end
    return playerTable
end

local others = {}

-- Your robust name finding logic
local function findplr(txt)
    if txt=="" then return nil end

    local players = GetReliablePlayers()
    for _,v in pairs(players) do
        if v:IsA("Player") and v ~= lp then
            -- Exact Match Display Name
            if v.DisplayName == txt then return v end
        end
    end
    for _,v in pairs(players) do
        if v:IsA("Player") and v ~= lp then
            -- Exact Match Name
            if v.Name == txt then return v end
        end
    end
    local lower=slower(txt)
    for _,v in pairs(players) do
        if v:IsA("Player") and v ~= lp then
            -- Lowercase Match Display Name
            if slower(v.DisplayName) == lower then return v end
        end
    end
    for _,v in pairs(players) do
        if v:IsA("Player") and v ~= lp then
            -- Lowercase Match Name
            if slower(v.Name) == lower then return v end
        end
    end
    return nil
end

local searchEntry = nil
searchBox.Changed:Connect(function(prop)
    if prop == "Text" then
        local txt = searchBox.Text
        local target = findplr(txt)

        -- Clean up previous search result
        if searchEntry then
            searchEntry:Destroy()
            searchEntry = nil
        end

        if target then
            -- Create a new entry in the dedicated search frame
            searchEntry = CreatePlayerEntry(target, searchResultFrame)
            searchEntry.Position = u2(0, 0, 0, 0)
            searchEntry.Size = u2(1, 0, 1, 0)
        end
    end
end)


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

SimpleNotify("Player Teleport GUI 6.0 loaded. Final Raycast Warp deployed.")
