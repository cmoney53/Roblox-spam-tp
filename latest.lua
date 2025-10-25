--[[
    DUAL-PANEL HARVESTER & EXECUTOR: The final, all-in-one tool.
    
    Left Panel: Universal Code Harvester
    - Scans the entire game for suspicious RemoteEvents and other callable functions.
    
    Right Panel: Remote Executor
    - Allows you to select a remote from the left, set a target, and fire the final "Bring" exploit script.
    
    This is designed to bypass strong anti-exploits by finding and abusing the game's own developer-made commands.
]]

local Game = game
local Players = Game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = Game:GetService("RunService")
local CoreGui = Game:GetService("CoreGui")
local ReplicatedStorage = Game:GetService("ReplicatedStorage")
local HttpService = Game:GetService("HttpService") -- Used for its UUID function (better than os.clock() for unique IDs)
local SUSPICIOUS_KEYWORDS = {
    "teleport", "tp", "move", "position", "warp", "goto", "cframe", 
    "admin", "kick", "ban", "kill", "respawn", "damage", "health", 
    "command", "server", "setprop", "property", "override",
    "item", "inventory", "stat", "update", "value", "setvalue", 
    "char", "character", "load", "save", "debug", "test", "dev"
}
local SERVICES_TO_SCAN = {
    Game:GetService("Workspace"), Game:GetService("ReplicatedStorage"), 
    Game:GetService("ReplicatedFirst"), Game:GetService("StarterGui"),
    Game:GetService("StarterPlayer"):FindFirstChild("StarterCharacterScripts"),
    Game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"),
    Game:GetService("Lighting"), Game:GetService("SoundService"),
    Game
}
local foundRemotes = {}

-- Utility to log to the console
local function Log(text)
    print("--- [DUAL HACKER] " .. text)
end

-- Function to check if an instance is a callable remote/bindable object
local function IsCallableObject(instance)
    return instance:IsA("RemoteEvent") or 
           instance:IsA("RemoteFunction") or
           instance:IsA("BindableEvent") or
           instance:IsA("BindableFunction")
end

-- Recursive function to search for all callable objects matching keywords
local function DeepSearchForRemotes(instance, path)
    if not instance then return end

    if IsCallableObject(instance) then
        local instancePath = path .. "." .. instance.Name
        local lowerName = string.lower(instance.Name)
        
        local categories = {}
        for _, keyword in ipairs(SUSPICIOUS_KEYWORDS) do
            if string.find(lowerName, keyword) then
                table.insert(categories, keyword)
            end
        end

        if #categories > 0 then
            table.insert(foundRemotes, {
                Name = instance.Name, 
                Path = instancePath, 
                Type = instance.ClassName,
                Categories = categories,
                ID = HttpService:GenerateGUID(false) -- Unique ID for lookup
            })
        end
    end

    -- Recurse through children, limiting depth/size
    for _, child in ipairs(instance:GetChildren()) do
        if #child:GetChildren() < 1000 and 
           not child:IsA("Configuration") and
           not child:IsA("MaterialService") and 
           not child:IsA("LocalizationService")
        then
            DeepSearchForRemotes(child, path .. "." .. child.Name)
        end
    end
end

-- ====================================================================
-- GUI CONSTRUCTION
-- ====================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DualPanelHacker"
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 780, 0, 500) -- Wide frame for two panels
frame.Position = UDim2.new(0.5, -390, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(15, 15, 15)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Dual-Panel Remote Harvester & Executor"
title.TextColor3 = Color3.fromRGB(255, 100, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Parent = frame

-- LEFT PANEL: HARVESTER
local harvestPanel = Instance.new("Frame")
harvestPanel.Size = UDim2.new(0.5, -10, 1, -40)
harvestPanel.Position = UDim2.new(0, 5, 0, 35)
harvestPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
harvestPanel.Parent = frame

local harvestTitle = title:Clone()
harvestTitle.Name = "HarvestTitle"
harvestTitle.Text = "STEP 1: COMMAND HARVESTER"
harvestTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
harvestTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
harvestTitle.Parent = harvestPanel

local harvestButton = Instance.new("TextButton")
harvestButton.Size = UDim2.new(1, -10, 0, 40)
harvestButton.Position = UDim2.new(0, 5, 0, 35)
harvestButton.Text = "RUN ULTIMATE HARVEST"
harvestButton.TextColor3 = Color3.fromRGB(255, 255, 255)
harvestButton.Font = Enum.Font.SourceSansBold
harvestButton.TextSize = 18
harvestButton.BackgroundColor3 = Color3.fromRGB(130, 0, 255)
harvestButton.Parent = harvestPanel

local resultsFrame = Instance.new("ScrollingFrame")
resultsFrame.Size = UDim2.new(1, -10, 1, -110)
resultsFrame.Position = UDim2.new(0, 5, 0, 80)
resultsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
resultsFrame.BorderSizePixel = 0
resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsFrame.ScrollBarThickness = 6
resultsFrame.Parent = harvestPanel

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = resultsFrame

-- RIGHT PANEL: EXECUTOR
local execPanel = Instance.new("Frame")
execPanel.Size = UDim2.new(0.5, -10, 1, -40)
execPanel.Position = UDim2.new(0.5, 5, 0, 35)
execPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
execPanel.Parent = frame

local execTitle = title:Clone()
execTitle.Name = "ExecutorTitle"
execTitle.Text = "STEP 2: REMOTE EXECUTOR"
execTitle.TextColor3 = Color3.fromRGB(255, 255, 100)
execTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
execTitle.Parent = execPanel

local pathBox = Instance.new("TextBox")
pathBox.Size = UDim2.new(1, -10, 0, 30)
pathBox.Position = UDim2.new(0, 5, 0, 35)
pathBox.PlaceholderText = "Path of RemoteEvent (e.g., game.RbltSrv.TeleportEvent)"
pathBox.Text = "" -- Will be populated on click
pathBox.Font = Enum.Font.SourceSans
pathBox.TextSize = 14
pathBox.TextColor3 = Color3.fromRGB(255, 255, 255)
pathBox.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
pathBox.Parent = execPanel
pathBox.TextEditable = false -- Read-only once a path is selected

local targetBox = pathBox:Clone()
targetBox.Size = UDim2.new(1, -10, 0, 30)
targetBox.Position = UDim2.new(0, 5, 0, 70)
targetBox.PlaceholderText = "Target Player Name"
targetBox.Text = LocalPlayer.Name == "Player1" and "Player2" or "Player1" -- Placeholder target
targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
targetBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
targetBox.TextEditable = true
targetBox.Parent = execPanel

local execButton = harvestButton:Clone()
execButton.Size = UDim2.new(1, -10, 0, 40)
execButton.Position = UDim2.new(0, 5, 0, 105)
execButton.Text = "ATTEMPT FINAL BRING"
execButton.TextColor3 = Color3.fromRGB(255, 255, 255)
execButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
execButton.Parent = execPanel

local execOutput = Instance.new("TextLabel")
execOutput.Size = UDim2.new(1, -10, 1, -155)
execOutput.Position = UDim2.new(0, 5, 0, 150)
execOutput.Text = "Select a command on the left to begin."
execOutput.TextColor3 = Color3.fromRGB(200, 200, 200)
execOutput.Font = Enum.Font.SourceSans
execOutput.TextSize = 16
execOutput.TextWrapped = true
execOutput.TextXAlignment = Enum.TextXAlignment.Left
execOutput.TextYAlignment = Enum.TextYAlignment.Top
execOutput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
execOutput.Parent = execPanel

-- ====================================================================
-- HARVESTER LOGIC (LEFT PANEL)
-- ====================================================================

local function CreateRemoteButton(remoteData)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.BorderColor3 = Color3.fromRGB(15, 15, 15)
    btn.BorderSizePixel = 1
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    
    local nameColor = remoteData.Type == "RemoteEvent" and "#FFC04D" or "#4DFFFF" -- Yellow/Cyan
    local matchText = table.concat(remoteData.Categories, ", ")

    btn.Text = string.format("  <font color='%s'>%s</font> | %s | Matches: %s", 
        nameColor, 
        remoteData.Name, 
        remoteData.Type:sub(1,1), -- Use abbreviation E/F/BE/BF
        matchText
    )
    btn.RichText = true
    btn.Parent = resultsFrame

    -- On Click, populate the executor panel
    btn.MouseButton1Click:Connect(function()
        pathBox.Text = remoteData.Path
        pathBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        execOutput.Text = string.format("Selected command: %s\nType: %s\nPath: %s\n\nReady to fire. Make sure '%s' is the correct target.", 
            remoteData.Name, 
            remoteData.Type, 
            remoteData.Path, 
            targetBox.Text
        )
        execOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
    end)
    
    return btn
end

local function DisplayResults()
    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    if #foundRemotes == 0 then
        execOutput.Text = "No suspicious commands found. Security is extremely high."
        resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        return
    end

    for _, remote in ipairs(foundRemotes) do
        CreateRemoteButton(remote)
    end
    
    local totalHeight = #foundRemotes * 27 
    resultsFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    Log(string.format("HARVEST COMPLETE: %d commands found.", #foundRemotes))
    execOutput.Text = string.format("HARVEST COMPLETE: %d commands found. Scroll the left list and click one to select it.", #foundRemotes)
    execOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
end

local function RunRemoteScan()
    table.clear(foundRemotes)
    Log("Starting ULTIMATE CODE HARVEST...")
    
    harvestButton.Text = "HARVESTING..."
    harvestButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    
    for _, service in ipairs(SERVICES_TO_SCAN) do
        DeepSearchForRemotes(service, "game." .. (service and service.Name or "nil"))
    end
    
    DisplayResults()
    
    harvestButton.Text = "RE-RUN ULTIMATE HARVEST"
    harvestButton.BackgroundColor3 = Color3.fromRGB(130, 0, 255)
end

harvestButton.MouseButton1Click:Connect(function()
    task.spawn(RunRemoteScan)
end)

-- ====================================================================
-- EXECUTOR LOGIC (RIGHT PANEL)
-- ====================================================================

local function FindInstanceByPath(path)
    -- This function converts "game.ReplicatedStorage.Remote" into the actual instance
    local parts = string.split(path, ".")
    local current = Game
    for i = 2, #parts do -- Start at 2 to skip "game"
        if not current then return nil end
        current = current:FindFirstChild(parts[i])
    end
    return current
end

execButton.MouseButton1Click:Connect(function()
    local path = pathBox.Text
    local targetName = targetBox.Text
    
    if path == "" or path == pathBox.PlaceholderText then
        execOutput.Text = "Error: Please select a command on the left first."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end
    if targetName == "" then
        execOutput.Text = "Error: Please enter a target player's name."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end
    
    local Target = Players:FindFirstChild(targetName)
    if not Target then
        execOutput.Text = "Error: Target player '" .. targetName .. "' not found."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    local Remote = FindInstanceByPath(path)
    if not Remote or (not Remote:IsA("RemoteEvent") and not Remote:IsA("RemoteFunction")) then
        execOutput.Text = "Error: Path does not lead to a valid RemoteEvent/Function."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then
        execOutput.Text = "Error: Your character's HumanoidRootPart not found."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    local MyCFrame = MyRoot.CFrame
    
    execOutput.Text = string.format("Attempting to fire: %s\nTarget: %s\nTrying parameter combinations...", Remote.Name, targetName)
    execOutput.TextColor3 = Color3.fromRGB(255, 165, 0)
    
    local success = false
    
    -- Attempt 1: TargetPlayer, DestinationCFrame (Most common 'Bring' signature)
    local s1, e1 = pcall(function() Remote:FireServer(Target, MyCFrame) end)
    if s1 and not e1 then success = true end

    -- Attempt 2: TargetPlayer only (Server pulls CFrame automatically)
    if not success then
        local s2, e2 = pcall(function() Remote:FireServer(Target) end)
        if s2 and not e2 then success = true end
    end
    
    -- Attempt 3: DestinationCFrame only (Remote assumes LocalPlayer is target)
    if not success then
        local s3, e3 = pcall(function() Remote:FireServer(MyCFrame) end)
        if s3 and not e3 then success = true end
    end

    -- Attempt 4: CFrame, TargetPlayer (Less common, but seen in some custom admins)
    if not success then
        local s4, e4 = pcall(function() Remote:FireServer(MyCFrame, Target) end)
        if s4 and not e4 then success = true end
    end

    -- Attempt 5: No Arguments (Remote expects the server to figure it out)
    if not success then
        local s5, e5 = pcall(function() Remote:FireServer() end)
        if s5 and not e5 then success = true end
    end


    -- Final Report
    if success then
        execOutput.Text = "SUCCESS! Remote fired. Check if " .. targetName .. " has moved!"
        execOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        execOutput.Text = "FAILURE. Remote failed to fire or was rejected by the server. Try a different command on the left."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)
