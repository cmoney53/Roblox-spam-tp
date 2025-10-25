--[[
    UNIVERSAL SINGLE-CLICK EXECUTOR v9 (HYBRID) - HARVEST BUTTON CLARIFIED
    
    1. Primary button is now clearly labeled "RUN COMMAND HARVESTER".
    2. Executes the command INSTANTLY upon clicking the list button using ZERO ARGUMENTS ({}).
    3. Includes Minimize and Search/Filter functionality.
    4. Set to a larger height (500px) to display maximum results.
]]

local Game = game
local Players = Game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = Game:GetService("HttpService") 

-- Configuration Constants
local FULL_WIDTH = 450 
local FULL_HEIGHT = 500 -- Height to show more results
local MIN_HEIGHT = 30
local isMinimized = false
local currentSearchQuery = "" -- Search query state

-- UI Layout Constants
local CONTROL_HEIGHT = 30
local CONTROL_Y_START = 5
local RESULTS_LIST_HEIGHT = 330 -- Large list for all commands
local STATUS_OUTPUT_HEIGHT = 65
local statusOutputYOffset = 0 

local SUSPICIOUS_KEYWORDS = {
    "teleport", "tp", "move", "position", "warp", "goto", "cframe", 
    "admin", "kick", "ban", "kill", "respawn", "damage", "health", 
    "command", "server", "setprop", "property", "override",
    "item", "inventory", "stat", "update", "value", "setvalue", 
    "char", "character", "load", "save", "debug", "test", "dev",
    "give", "add", "remove", "currency", "level", "xp", "money", "cash", "luck", 
    "hook", "client", "local", "trigger",
    "secret", "key", "token", "password", "hidden", "exploit", "cheat" 
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
    print("--- [UNIVERSAL EXECUTOR] " .. text)
end

-- ====================================================================
-- CORE HARVESTER & UTILITY FUNCTIONS 
-- ====================================================================

local function FormatArgument(val)
    if type(val) == "string" then
        return string.format("\"%s\"", val)
    elseif val == nil then
        return "nil"
    elseif type(val) == "boolean" then
        return val and "true" or "false"
    elseif type(val) == "number" then
        return tostring(val)
    elseif type(val) == "userdata" and tostring(val):find("CFrame") then
        local cframe = val
        return string.format("CFR(%.1f, %.1f, %.1f, ...)", cframe.X, cframe.Y, cframe.Z)
    else
        return tostring(val)
    end
end

local function IsCallableObject(instance)
    return instance:IsA("RemoteEvent") or 
           instance:IsA("RemoteFunction") or
           instance:IsA("BindableEvent") or
           instance:IsA("BindableFunction")
end

-- DeepSearch now ONLY collects callable objects
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

        if #categories == 0 then
            table.insert(categories, "General")
        end

        table.insert(foundRemotes, {
            Name = instance.Name, 
            Path = instancePath, 
            Type = instance.ClassName,
            Categories = categories,
            Instance = instance 
        })
    end

    for _, child in ipairs(instance:GetChildren()) do
        -- Skip scripts and only recurse on non-configuration items
        if not child:IsA("Configuration") and
           not child:IsA("MaterialService") and 
           not child:IsA("LocalizationService") and
           not child:IsA("LocalScript") and -- Exclude scripts from search
           not child:IsA("Script") and
           not child:IsA("ModuleScript")
        then
            DeepSearchForRemotes(child, path .. "." .. child.Name)
        end
    end
end

local function FireRemote(remote, args)
    local success, result
    
    local resultWrapper = function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(unpack(args)) 
        elseif remote:IsA("BindableEvent") then
            remote:Fire(unpack(args)) 
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(unpack(args)) 
        elseif remote:IsA("BindableFunction") then
            return remote:Invoke(unpack(args)) 
        else
            error("Invalid Callable object type.")
        end
    end

    success, result = pcall(resultWrapper)
    
    return success, result
end


-- ====================================================================
-- GUI CONSTRUCTION 
-- ====================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalExecutorSimple"
screenGui.Parent = Game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, FULL_WIDTH, 0, FULL_HEIGHT) 
frame.Position = UDim2.new(0.5, -FULL_WIDTH/2, 0.5, -FULL_HEIGHT/2) 
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(15, 15, 15)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, MIN_HEIGHT) 
title.Text = "Universal Single-Click Executor v9"
title.TextColor3 = Color3.fromRGB(255, 100, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Parent = frame

-- Minimize Button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 30, 0, MIN_HEIGHT)
minimizeButton.Position = UDim2.new(1, -30, 0, 0)
minimizeButton.Text = "-" 
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.TextSize = 20
minimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
minimizeButton.Parent = frame

-- MAIN PANEL
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(1, -10, 1, -35) 
mainPanel.Position = UDim2.new(0, 5, 0, 35) 
mainPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainPanel.Parent = frame
mainPanel.ZIndex = 2 

-- CALCULATE Y POSITIONS
local yPos = CONTROL_Y_START
local function getNextY(height)
    local current = yPos
    yPos = yPos + height + 5 -- Add 5px padding
    return current
end

-- HARVEST BUTTON (The "Run Command Harvester" button)
local harvestButton = Instance.new("TextButton")
harvestButton.Size = UDim2.new(1, -10, 0, CONTROL_HEIGHT) 
harvestButton.Position = UDim2.new(0, 5, 0, getNextY(CONTROL_HEIGHT)) 
harvestButton.Text = "RUN COMMAND HARVESTER" -- CLARIFIED LABEL
harvestButton.TextColor3 = Color3.fromRGB(255, 255, 255)
harvestButton.Font = Enum.Font.SourceSansBold
harvestButton.TextSize = 16
harvestButton.BackgroundColor3 = Color3.fromRGB(180, 0, 255) 
harvestButton.Parent = mainPanel

-- Search Input Box
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -10, 0, CONTROL_HEIGHT)
searchBox.Position = UDim2.new(0, 5, 0, getNextY(CONTROL_HEIGHT))
searchBox.PlaceholderText = "Filter by name or path (e.g., 'teleport', 'give')"
searchBox.Text = "" 
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 14
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
searchBox.Parent = mainPanel

-- Search/Filter Button
local filterButton = Instance.new("TextButton")
filterButton.Size = UDim2.new(1, -10, 0, CONTROL_HEIGHT)
filterButton.Position = UDim2.new(0, 5, 0, getNextY(CONTROL_HEIGHT))
filterButton.Text = "APPLY FILTER" 
filterButton.TextColor3 = Color3.fromRGB(255, 255, 255)
filterButton.Font = Enum.Font.SourceSansBold
filterButton.TextSize = 16
filterButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200) 
filterButton.Parent = mainPanel

-- Results Frame (List)
local resultsFrame = Instance.new("ScrollingFrame")
resultsFrame.Size = UDim2.new(1, -10, 0, RESULTS_LIST_HEIGHT) 
resultsFrame.Position = UDim2.new(0, 5, 0, getNextY(RESULTS_LIST_HEIGHT))
resultsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
resultsFrame.BorderSizePixel = 0
resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsFrame.ScrollBarThickness = 6
resultsFrame.Parent = mainPanel

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = resultsFrame

-- Status Output Console Label
local outputLabel = Instance.new("TextLabel")
outputLabel.Size = UDim2.new(1, -10, 0, 15)
outputLabel.Position = UDim2.new(0, 5, 0, getNextY(15)) 
outputLabel.Text = "Execution Status (0 Args):"
outputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
outputLabel.Font = Enum.Font.SourceSans
outputLabel.TextSize = 14
outputLabel.TextXAlignment = Enum.TextXAlignment.Left
outputLabel.BackgroundTransparency = 1
outputLabel.Parent = mainPanel

-- STATUS OUTPUT CONSOLE 
statusOutputYOffset = yPos -- Capture current Y for text box positioning
local statusOutput = Instance.new("TextBox")
statusOutput.Size = UDim2.new(1, -10, 0, STATUS_OUTPUT_HEIGHT) 
statusOutput.Position = UDim2.new(0, 5, 0, statusOutputYOffset) 
statusOutput.Text = "Click 'RUN COMMAND HARVESTER' to start harvesting. Once found, click any command to fire it with zero arguments."
statusOutput.TextColor3 = Color3.fromRGB(200, 200, 200)
statusOutput.Font = Enum.Font.SourceSans
statusOutput.TextSize = 12 
statusOutput.TextWrapped = true
statusOutput.TextXAlignment = Enum.TextXAlignment.Left
statusOutput.TextYAlignment = Enum.TextYAlignment.Top
statusOutput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
statusOutput.MultiLine = true
statusOutput.TextEditable = false
statusOutput.Parent = mainPanel


-- ====================================================================
-- CONTROL & DISPLAY LOGIC 
-- ====================================================================

local function ToggleVisibility()
    isMinimized = not isMinimized

    local targetHeight = isMinimized and MIN_HEIGHT or FULL_HEIGHT
    local targetText = isMinimized and "+" or "-"
    local targetVisible = not isMinimized

    frame:TweenSize(UDim2.new(0, FULL_WIDTH, 0, targetHeight), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
    
    minimizeButton.Text = targetText
    mainPanel.Visible = targetVisible
end

-- Button Connection: Minimize Button
minimizeButton.MouseButton1Click:Connect(ToggleVisibility)

local function UpdateStatus(text, color)
    statusOutput.Text = text
    statusOutput.TextColor3 = color
    Log(text)
end

local function CreateRemoteButton(remoteData)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.BorderColor3 = Color3.fromRGB(15, 15, 15)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    
    -- Iconography based on type
    local abbr, nameColor
    if remoteData.Type == "RemoteEvent" then abbr = "RE"; nameColor = "#FFC04D" 
    elseif remoteData.Type == "RemoteFunction" then abbr = "RF"; nameColor = "#4DFFFF" 
    elseif remoteData.Type == "BindableEvent" then abbr = "BE"; nameColor = "#FF4DFF"
    elseif remoteData.Type == "BindableFunction" then abbr = "BF"; nameColor = "#FF00FF"
    end
    
    local matchText = table.concat(remoteData.Categories, ", ")
    local statusColor = matchText ~= "General" and "#FF9900" or "#AAAAAA" 

    btn.Text = string.format("  <font color='%s'>%s</font> | %s | Status: <font color='%s'>%s</font>", 
        nameColor, 
        remoteData.Name, 
        abbr,
        statusColor,
        matchText
    )
    btn.RichText = true
    btn.Parent = resultsFrame

    -- Button Connection: INSTANT ZERO-ARGUMENT EXECUTION
    btn.MouseButton1Click:Connect(function()
        local Remote = remoteData.Instance
        
        UpdateStatus(string.format("Attempting to fire %s: %s (0 args)...", Remote.ClassName, Remote.Name), Color3.fromRGB(255, 165, 0))
        
        -- Execute with NO ARGUMENTS
        local success, result = FireRemote(Remote, {}) 

        -- Final Report
        if success then
            local resultString = result and FormatArgument(result) or "nil"
            UpdateStatus(
                string.format("SUCCESS: %s fired.\nPath: %s\nReturn: %s", Remote.Name, remoteData.Path, resultString),
                Color3.fromRGB(0, 255, 100)
            )
        else
            -- If the execution fails, it usually means the remote is protected or expects arguments.
            UpdateStatus(
                string.format("FAILURE: %s failed or error.\nPath: %s\nError: %s", Remote.Name, remoteData.Path, tostring(result)),
                Color3.fromRGB(255, 0, 0)
            )
        end
    end)
    
    return btn
end

-- Filtering logic
local function FilterResults(query)
    local filteredList = {}
    local lowerQuery = string.lower(query or "")
    
    if lowerQuery == "" then
        return foundRemotes -- Return all if no query
    end
    
    for _, remote in ipairs(foundRemotes) do
        local lowerName = string.lower(remote.Name)
        local lowerPath = string.lower(remote.Path)
        
        if string.find(lowerName, lowerQuery, 1, true) or 
           string.find(lowerPath, lowerQuery, 1, true) then
            table.insert(filteredList, remote)
        end
    end
    
    return filteredList
end

local function DisplayResults()
    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    -- Apply Filter
    local listToDisplay = FilterResults(currentSearchQuery)

    local totalItems = #listToDisplay
    local totalFound = #foundRemotes

    if totalFound == 0 then
        -- No commands found
        UpdateStatus("SCAN COMPLETE: Zero callable commands (Remote/Bindable) found. This game environment is very locked down.", Color3.fromRGB(255, 100, 0))
    elseif totalItems == 0 then
        -- Commands were found, but none match the filter
        UpdateStatus(string.format("No commands match the filter: '%s'. Total commands found: %d.", currentSearchQuery, totalFound), Color3.fromRGB(255, 165, 0))
    else
        -- Commands found and/or filtered
        for _, remote in ipairs(listToDisplay) do
            CreateRemoteButton(remote)
        end
        
        local statusText = totalItems == totalFound and 
            string.format("SCAN COMPLETE: %d commands found. Click to execute with 0 arguments.", totalFound) or
            string.format("FILTER APPLIED: Showing %d of %d commands. Click to execute with 0 arguments.", totalItems, totalFound)

        UpdateStatus(statusText, Color3.fromRGB(0, 255, 100))
    end
    
    -- Adjust Canvas Size
    local totalHeight = totalItems * 27 
    resultsFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

local function RunRemoteScan()
    table.clear(foundRemotes)
    
    harvestButton.Text = "HARVESTING..."
    harvestButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    
    UpdateStatus("Starting scan for RemoteEvents, RemoteFunctions, and Bindables...", Color3.fromRGB(255, 165, 0))
    
    -- Run deep search concurrently for speed
    local co = coroutine.wrap(function()
        for _, service in ipairs(SERVICES_TO_SCAN) do
            DeepSearchForRemotes(service, "game." .. (service and service.Name or "nil"))
            task.wait(0.05) -- Yield occasionally
        end
    end)
    co()
    
    task.wait(1.5) -- Give time for most popular services to be scanned

    DisplayResults()
    
    harvestButton.Text = "RUN COMMAND HARVESTER"
    harvestButton.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
end

-- Button Connection: Run Super Harvest Button
harvestButton.MouseButton1Click:Connect(function()
    task.spawn(RunRemoteScan)
end)

-- Connect Search Button and Text Changed
local function ApplyFilter()
    currentSearchQuery = searchBox.Text
    DisplayResults()
end

filterButton.MouseButton1Click:Connect(ApplyFilter)
searchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        ApplyFilter()
    end
end)
