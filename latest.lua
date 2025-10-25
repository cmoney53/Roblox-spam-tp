--[[
    UNIVERSAL REMOTE COMMANDER: The final, flexible tool.
    
    Left Panel: Universal Code Harvester
    - Scans the entire game for callable RemoteEvents/Functions.
    
    Right Panel: Remote Commander
    - Allows you to select a remote from the left and manually set the arguments (parameters) to fire the command.
    
    This is the most direct way to execute any command found in the game's code.
]]

local Game = game
local Players = Game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = Game:GetService("HttpService") 
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
    print("--- [UNIVERSAL COMMANDER] " .. text)
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
        }

        if #categories > 0 then
            table.insert(foundRemotes, {
                Name = instance.Name, 
                Path = instancePath, 
                Type = instance.ClassName,
                Categories = categories,
                ID = HttpService:GenerateGUID(false)
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
screenGui.Name = "UniversalCommander"
screenGui.Parent = Game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 780, 0, 500) 
frame.Position = UDim2.new(0.5, -390, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(15, 15, 15)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Universal Remote Commander (Ultimate Exploit Tool)"
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

-- RIGHT PANEL: COMMANDER
local execPanel = Instance.new("Frame")
execPanel.Size = UDim2.new(0.5, -10, 1, -40)
execPanel.Position = UDim2.new(0.5, 5, 0, 35)
execPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
execPanel.Parent = frame

local execTitle = title:Clone()
execTitle.Name = "ExecutorTitle"
execTitle.Text = "STEP 2: REMOTE COMMANDER"
execTitle.TextColor3 = Color3.fromRGB(255, 255, 100)
execTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
execTitle.Parent = execPanel

-- Path Box (Uneditable by user, set by Harvester)
local pathLabel = Instance.new("TextLabel")
pathLabel.Size = UDim2.new(1, -10, 0, 15)
pathLabel.Position = UDim2.new(0, 5, 0, 35)
pathLabel.Text = "Remote Path:"
pathLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
pathLabel.Font = Enum.Font.SourceSans
pathLabel.TextSize = 14
pathLabel.TextXAlignment = Enum.TextXAlignment.Left
pathLabel.BackgroundTransparency = 1
pathLabel.Parent = execPanel

local pathBox = Instance.new("TextBox")
pathBox.Size = UDim2.new(1, -10, 0, 30)
pathBox.Position = UDim2.new(0, 5, 0, 50)
pathBox.PlaceholderText = "Select a command on the left first."
pathBox.Text = "" 
pathBox.Font = Enum.Font.SourceSans
pathBox.TextSize = 14
pathBox.TextColor3 = Color3.fromRGB(255, 255, 255)
pathBox.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
pathBox.Parent = execPanel
pathBox.TextEditable = false -- Path is read-only after selection

-- Arguments Box
local argsLabel = pathLabel:Clone()
argsLabel.Position = UDim2.new(0, 5, 0, 85)
argsLabel.Text = "Arguments (use commas to separate, e.g., 'TargetPlayerName, 100, true')"
argsLabel.Parent = execPanel

local argsBox = pathBox:Clone()
argsBox.Size = UDim2.new(1, -10, 0, 30)
argsBox.Position = UDim2.new(0, 5, 0, 100)
argsBox.PlaceholderText = "Example: 'MyWorld, 50, true' (Leave blank for no arguments)"
argsBox.Text = "" 
argsBox.TextColor3 = Color3.fromRGB(255, 255, 255)
argsBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
argsBox.TextEditable = true
argsBox.Parent = execPanel

local execButton = harvestButton:Clone()
execButton.Size = UDim2.new(1, -10, 0, 40)
execButton.Position = UDim2.new(0, 5, 0, 140)
execButton.Text = "EXECUTE COMMAND"
execButton.TextColor3 = Color3.fromRGB(255, 255, 255)
execButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
execButton.Parent = execPanel

-- Output Console
local outputLabel = pathLabel:Clone()
outputLabel.Position = UDim2.new(0, 5, 0, 185)
outputLabel.Text = "Execution Console Output:"
outputLabel.Parent = execPanel

local execOutput = Instance.new("TextBox")
execOutput.Size = UDim2.new(1, -10, 1, -210)
execOutput.Position = UDim2.new(0, 5, 0, 200)
execOutput.Text = "Select a command on the left and enter arguments to begin."
execOutput.TextColor3 = Color3.fromRGB(200, 200, 200)
execOutput.Font = Enum.Font.SourceSans
execOutput.TextSize = 16
execOutput.TextWrapped = true
execOutput.TextXAlignment = Enum.TextXAlignment.Left
execOutput.TextYAlignment = Enum.TextYAlignment.Top
execOutput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
execOutput.MultiLine = true
execOutput.TextEditable = false
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
        execOutput.Text = string.format("Command Selected: %s (%s)\nPath: %s\n\nEnter the arguments required by the remote and click EXECUTE.", 
            remoteData.Name, 
            remoteData.Type, 
            remoteData.Path
        )
        execOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
        -- Set a common initial argument as a hint
        argsBox.Text = (remoteData.Type == "RemoteEvent" or remoteData.Type == "RemoteFunction") and "nil, TargetPlayerName" or ""
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
        task.spawn(function()
            -- Add a brief delay to prevent potential timeouts on huge games
            DeepSearchForRemotes(service, "game." .. (service and service.Name or "nil"))
        end)
    end
    
    -- Wait briefly for spawns to complete (crude, but works in executor environments)
    task.wait(2) 
    
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
    local parts = string.split(path, ".")
    local current = Game
    for i = 2, #parts do 
        if not current then return nil end
        current = current:FindFirstChild(parts[i])
    end
    return current
end

local function ParseArguments(argString)
    local args = {}
    
    if string.len(argString) == 0 then return args end
    
    -- Split by comma and trim whitespace
    for part in string.gmatch(argString, "([^,]+)") do
        part = string.gsub(part, "^%s*(.-)%s*$", "%1") -- Trim whitespace
        
        -- Try to interpret the type of the argument
        local numberValue = tonumber(part)
        if numberValue ~= nil then
            table.insert(args, numberValue) -- Is a number
        elseif part == "true" then
            table.insert(args, true) -- Is boolean true
        elseif part == "false" then
            table.insert(args, false) -- Is boolean false
        elseif string.match(part, "TargetPlayerName") then -- Placeholder for target
            local targetPlayer = Players:FindFirstChild(string.gsub(part, "TargetPlayerName", argsBox.Text))
            if targetPlayer then
                table.insert(args, targetPlayer)
            else
                -- If it fails to find the player, pass the string
                table.insert(args, part)
            end
        elseif part == "LocalPlayer" then
            table.insert(args, LocalPlayer) -- Pass the local player instance
        elseif string.match(part, "^[A-Za-z_]+$") then
            -- Try to find a player by name if it's a simple string
            local player = Players:FindFirstChild(part)
            if player then
                table.insert(args, player)
            else
                table.insert(args, part) -- Is a simple string
            end
        elseif part == "nil" then
            table.insert(args, nil)
        else
            table.insert(args, part) -- Default to string (CFrame, complex name, etc.)
        end
    end
    
    return args
end

execButton.MouseButton1Click:Connect(function()
    local path = pathBox.Text
    local argString = argsBox.Text
    
    if path == "" or path == pathBox.PlaceholderText then
        execOutput.Text = "Error: Please select a command on the left first."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end
    
    local Remote = FindInstanceByPath(path)
    if not Remote or (not IsCallableObject(Remote)) then
        execOutput.Text = "Error: Path does not lead to a valid Remote/Bindable object."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    local args = ParseArguments(argString)
    
    execOutput.Text = string.format("Attempting to fire %s: %s\nArguments: %s\n\nResult:", Remote.ClassName, Remote.Name, table.concat(args, ", "))
    execOutput.TextColor3 = Color3.fromRGB(255, 165, 0)

    local success, result
    
    if Remote:IsA("RemoteEvent") or Remote:IsA("BindableEvent") then
        -- Fire for Events
        success, result = pcall(function()
            Remote:FireServer(unpack(args)) 
        end)
    elseif Remote:IsA("RemoteFunction") or Remote:IsA("BindableFunction") then
        -- Invoke for Functions (waiting for a return value)
        success, result = pcall(function()
            return Remote:InvokeServer(unpack(args)) 
        end)
    end
    
    -- Final Report
    if success then
        local resultString = result and tostring(result) or "nil"
        execOutput.Text = execOutput.Text .. "\nSUCCESS.\nServer Return: " .. resultString
        execOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        execOutput.Text = execOutput.Text .. "\nFAILURE.\nError Message: " .. tostring(result)
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)
