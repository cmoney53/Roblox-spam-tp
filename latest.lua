--[[
    UNIVERSAL REMOTE COMMANDER v8: Scripts & Commands Harvest.
    
    The harvester now collects and distinguishes between:
    1. Callable Objects (Remotes/Bindables): Auto-execute on click.
    2. Script Objects (LocalScript, Script, ModuleScript): Displays Source code on click.
    
    Execution logic remains generic and robust.
]]

local Game = game
local Players = Game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = Game:GetService("HttpService") 

-- Configuration Constants
local FULL_WIDTH = 450 
local FULL_HEIGHT = 500 
local MIN_HEIGHT = 30
local isMinimized = false
local currentView = "Harvester" 

local SUSPICIOUS_KEYWORDS = {
    "teleport", "tp", "move", "position", "warp", "goto", "cframe", 
    "admin", "kick", "ban", "kill", "respawn", "damage", "health", 
    "command", "server", "setprop", "property", "override",
    "item", "inventory", "stat", "update", "value", "setvalue", 
    "char", "character", "load", "save", "debug", "test", "dev",
    "give", "add", "remove", "currency", "level", "xp", "money", "cash", "luck", 
    "hook", "client", "local", "trigger",
    -- Keywords specific to scripts/secrets
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
local selectedRemoteObject = nil -- Stores the actual object reference

-- Utility to log to the console
local function Log(text)
    print("--- [UNIVERSAL COMMANDER] " .. text)
end

-- ====================================================================
-- ARGUMENT FORMATTING AND CORE HARVESTER FUNCTIONS 
-- ====================================================================

-- Function to format a single argument for clean display in the output box
local function FormatArgument(val)
    if type(val) == "string" then
        return string.format("\"%s\"", val)
    elseif val == nil then
        return "nil"
    elseif type(val) == "boolean" then
        return val and "true" or "false"
    elseif type(val) == "number" then
        return tostring(val)
    elseif val:IsA("Player") then
        return "Player(" .. val.Name .. ")"
    elseif val:IsA("Vector3") then
        return string.format("V3(%.1f, %.1f, %.1f)", val.X, val.Y, val.Z)
    elseif val:IsA("CFrame") then
        return string.format("CFR(%.1f, %.1f, %.1f, ...)", val.X, val.Y, val.Z) -- Only show pos for brevity
    else
        return tostring(val)
    end
end

-- Function to format the entire arguments table for clean display
local function FormatArgsTable(args)
    local formatted = {}
    for _, arg in ipairs(args) do
        table.insert(formatted, FormatArgument(arg))
    end
    return table.concat(formatted, ", ")
end


-- GUESS ARGUMENTS
local function GuessArguments(remoteName, remoteType)
    local lowerName = string.lower(remoteName)
    local prefill = ""
    local hints = {}
    
    local isBindable = remoteType == "BindableEvent" or remoteType == "BindableFunction"
    local targetType = isBindable and "Local Client Function (Bindable)" or "Server Remote Command (Remote)"

    table.insert(hints, string.format("- **Target Type:** %s", targetType))

    if string.find(lowerName, "teleport") or string.find(lowerName, "tp") or string.find(lowerName, "move") or string.find(lowerName, "cframe") then
        prefill = "CFR(0, 50, 0)"
        table.insert(hints, "- **Movement/CFrame Guess**:")
        table.insert(hints, "  - `CFR(0, 50, 0)` (CFrame input)")
        table.insert(hints, "  - `V3(0, 50, 0)` (Vector3 input)")
    elseif string.find(lowerName, "give") or string.find(lowerName, "item") or string.find(lowerName, "add") then
        prefill = "\"Sword\", 1"
        table.insert(hints, "- **Item Grant Guess**:")
        table.insert(hints, "  - `\"ItemName_STRING\", 1_NUMBER`")
    else
        prefill = "\"TestString\", true, 100" 
        table.insert(hints, "- **Generic Guess**:")
        table.insert(hints, "  - Try: `\"String\", true`, `CFR(x,y,z)` or leave blank.")
    end
    
    return prefill, table.concat(hints, "\n")
end

local function IsCallableObject(instance)
    return instance:IsA("RemoteEvent") or 
           instance:IsA("RemoteFunction") or
           instance:IsA("BindableEvent") or
           instance:IsA("BindableFunction")
end

local function IsScriptObject(instance)
    return instance:IsA("LocalScript") or 
           instance:IsA("Script") or 
           instance:IsA("ModuleScript")
end

-- NEW: DeepSearch now collects scripts as well
local function DeepSearchForRemotes(instance, path)
    if not instance then return end

    if IsCallableObject(instance) or IsScriptObject(instance) then
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
        if not child:IsA("Configuration") and
           not child:IsA("MaterialService") and 
           not child:IsA("LocalizationService")
        then
            DeepSearchForRemotes(child, path .. "." .. child.Name)
        end
    end
end

-- ====================================================================
-- GUI CONSTRUCTION (Unchanged)
-- ====================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalCommander"
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
title.Text = "Universal Remote Commander v8 (Scripts & Commands)"
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

-- Tabs Frame
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, 0, 0, 30)
tabsFrame.Position = UDim2.new(0, 0, 0, 30) 
tabsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
tabsFrame.Parent = frame

local harvTab = Instance.new("TextButton")
harvTab.Name = "HarvesterTab"
harvTab.Size = UDim2.new(0.5, 0, 1, 0)
harvTab.Position = UDim2.new(0, 0, 0, 0)
harvTab.Text = "① HARVESTER"
harvTab.TextColor3 = Color3.fromRGB(200, 200, 255)
harvTab.Font = Enum.Font.SourceSansBold
harvTab.TextSize = 18
harvTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60) 
harvTab.Parent = tabsFrame

local execTab = harvTab:Clone()
execTab.Name = "CommanderTab"
execTab.Position = UDim2.new(0.5, 0, 0, 0)
execTab.Text = "② COMMANDER"
execTab.TextColor3 = Color3.fromRGB(255, 255, 100)
execTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40) 
execTab.Parent = tabsFrame

-- HARVESTER PANEL 
local harvestPanel = Instance.new("Frame")
harvestPanel.Size = UDim2.new(1, -10, 1, -65) 
harvestPanel.Position = UDim2.new(0, 5, 0, 65) 
harvestPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
harvestPanel.Parent = frame
harvestPanel.ZIndex = 2 

local harvestButton = Instance.new("TextButton")
harvestButton.Size = UDim2.new(1, -10, 0, 40)
harvestButton.Position = UDim2.new(0, 5, 0, 5) 
harvestButton.Text = "RUN SUPER HARVEST (ALL SCRIPTS & REMOTES)" 
harvestButton.TextColor3 = Color3.fromRGB(255, 255, 255)
harvestButton.Font = Enum.Font.SourceSansBold
harvestButton.TextSize = 18
harvestButton.BackgroundColor3 = Color3.fromRGB(180, 0, 255) 
harvestButton.Parent = harvestPanel

local resultsFrame = Instance.new("ScrollingFrame")
resultsFrame.Size = UDim2.new(1, -10, 1, -55) 
resultsFrame.Position = UDim2.new(0, 5, 0, 50) 
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

-- COMMANDER PANEL 
local execPanel = Instance.new("Frame")
execPanel.Size = UDim2.new(1, -10, 1, -65) 
execPanel.Position = UDim2.new(0, 5, 0, 65)
execPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
execPanel.Parent = frame
execPanel.Visible = false 
execPanel.ZIndex = 2

-- Path Box 
local pathLabel = Instance.new("TextLabel")
pathLabel.Size = UDim2.new(1, -10, 0, 15)
pathLabel.Position = UDim2.new(0, 5, 0, 5) 
pathLabel.Text = "Function/Script Path:"
pathLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
pathLabel.Font = Enum.Font.SourceSans
pathLabel.TextSize = 14
pathLabel.TextXAlignment = Enum.TextXAlignment.Left
pathLabel.BackgroundTransparency = 1
pathLabel.Parent = execPanel

local pathBox = Instance.new("TextBox")
pathBox.Size = UDim2.new(1, -10, 0, 30)
pathBox.Position = UDim2.new(0, 5, 0, 20)
pathBox.PlaceholderText = "Select a command/script on the left first."
pathBox.Text = "" 
pathBox.Font = Enum.Font.SourceSans
pathBox.TextSize = 14
pathBox.TextColor3 = Color3.fromRGB(255, 255, 255)
pathBox.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
pathBox.Parent = execPanel
pathBox.TextEditable = false 

-- Arguments Box
local argsLabel = pathLabel:Clone()
argsLabel.Position = UDim2.new(0, 5, 0, 55)
argsLabel.Text = "Arguments (Disabled for Scripts):"
argsLabel.Parent = execPanel

local argsBox = pathBox:Clone()
argsBox.Size = UDim2.new(1, -10, 0, 30)
argsBox.Position = UDim2.new(0, 5, 0, 70)
argsBox.PlaceholderText = "\"Value\", 99999, true"
argsBox.Text = "" 
argsBox.TextColor3 = Color3.fromRGB(255, 255, 255)
argsBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
argsBox.TextEditable = true
argsBox.Parent = execPanel

-- Argument Help Box 
local argHelp = Instance.new("TextLabel")
argHelp.Size = UDim2.new(1, -10, 0, 30)
argHelp.Position = UDim2.new(0, 5, 0, 105)
argHelp.Text = "HINT: V3 = Vector3(x, y, z), CFR = CFrame(x, y, z). Use full Player Name to reference."
argHelp.TextColor3 = Color3.fromRGB(255, 255, 100)
argHelp.Font = Enum.Font.SourceSans
argHelp.TextSize = 14
argHelp.TextXAlignment = Enum.TextXAlignment.Left
argHelp.BackgroundTransparency = 1
argHelp.TextWrapped = true
argHelp.Parent = execPanel

-- EXECUTE BUTTON
local execButton = harvestButton:Clone()
execButton.Size = UDim2.new(1, -10, 0, 40)
execButton.Position = UDim2.new(0, 5, 0, 140) 
execButton.Text = "EXECUTE CUSTOM COMMAND"
execButton.TextColor3 = Color3.fromRGB(255, 255, 255)
execButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
execButton.Parent = execPanel

-- PERMUTATION BUTTON
local permutationButton = harvestButton:Clone()
permutationButton.Size = UDim2.new(0.5, -8, 0, 40)
permutationButton.Position = UDim2.new(0, 5, 0, 185) 
permutationButton.Text = "TRY PERMUTATIONS"
permutationButton.TextColor3 = Color3.fromRGB(20, 20, 20)
permutationButton.Font = Enum.Font.SourceSansBold
permutationButton.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
permutationButton.Parent = execPanel

-- VIEW CODE TEMPLATE/SOURCE BUTTON 
local codeTemplateButton = harvestButton:Clone()
codeTemplateButton.Size = UDim2.new(0.5, -8, 0, 40)
codeTemplateButton.Position = UDim2.new(0.5, 3, 0, 185) 
codeTemplateButton.Text = "VIEW CODE TEMPLATE"
codeTemplateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
codeTemplateButton.Font = Enum.Font.SourceSansBold
codeTemplateButton.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
codeTemplateButton.Parent = execPanel


-- Output Console
local outputLabel = pathLabel:Clone()
outputLabel.Position = UDim2.new(0, 5, 0, 235) 
outputLabel.Text = "Execution Console Output / Script Source Code:"
outputLabel.Parent = execPanel

local execOutput = Instance.new("TextBox")
execOutput.Size = UDim2.new(1, -10, 1, -255) 
execOutput.Position = UDim2.new(0, 5, 0, 250) 
execOutput.Text = "Select a command/function on the left to auto-execute, or a script to view its source."
execOutput.TextColor3 = Color3.fromRGB(200, 200, 200)
execOutput.Font = Enum.Font.SourceSans
execOutput.TextSize = 12 -- Smaller font for code visibility
execOutput.TextWrapped = true
execOutput.TextXAlignment = Enum.TextXAlignment.Left
execOutput.TextYAlignment = Enum.TextYAlignment.Top
execOutput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
execOutput.MultiLine = true
execOutput.TextEditable = false
execOutput.Parent = execPanel


-- ====================================================================
-- CONTROL LOGIC (Unchanged)
-- ====================================================================

local function ToggleVisibility()
    isMinimized = not isMinimized

    local targetHeight = isMinimized and MIN_HEIGHT or FULL_HEIGHT
    local targetText = isMinimized and "+" or "-"
    local targetVisible = not isMinimized

    frame:TweenSize(UDim2.new(0, FULL_WIDTH, 0, targetHeight), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
    
    minimizeButton.Text = targetText

    tabsFrame.Visible = targetVisible
    if currentView == "Harvester" then
        harvestPanel.Visible = targetVisible
        execPanel.Visible = false 
    else
        execPanel.Visible = targetVisible
        harvestPanel.Visible = false 
    end
end

-- Button Connection: Minimize Button
minimizeButton.MouseButton1Click:Connect(ToggleVisibility)

local function SwitchView(viewName)
    if viewName == currentView then return end
    
    currentView = viewName
    
    if viewName == "Harvester" then
        harvestPanel.Visible = true
        execPanel.Visible = false
        harvTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        execTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    else -- Commander
        harvestPanel.Visible = false
        execPanel.Visible = true
        harvTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        execTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end

-- Button Connection: Harvester Tab
harvTab.MouseButton1Click:Connect(function() SwitchView("Harvester") end)
-- Button Connection: Commander Tab
execTab.MouseButton1Click:Connect(function() SwitchView("Commander") end)


-- ====================================================================
-- HARVESTER DISPLAY LOGIC (MODIFIED: Handles Scripts/Commands)
-- ====================================================================

local function CreateRemoteButton(remoteData)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.BorderColor3 = Color3.fromRGB(15, 15, 15)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    
    local abbr, nameColor, actionText 
    
    if IsCallableObject(remoteData.Instance) then
        abbr = remoteData.Type:sub(1,1)
        nameColor = "#FFC04D" 
        if remoteData.Type == "RemoteFunction" then nameColor = "#4DFFFF" end
        if remoteData.Type:find("Bindable") then nameColor = "#FF4DFF"; abbr = remoteData.Type:sub(1,2) end
        actionText = " (Click to Auto-Execute)"
    else -- Is Script
        abbr = remoteData.Type:sub(1,1) == "M" and "M" or remoteData.Type:sub(1,2)
        nameColor = "#00FF00" -- Green for Scripts/Code
        actionText = " (Click to View Source)"
        if remoteData.Type == "ModuleScript" then nameColor = "#00BFFF" end
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

    -- Button Connection: Dynamic Action
    btn.MouseButton1Click:Connect(function()
        selectedRemoteObject = remoteData.Instance
        local Instance = selectedRemoteObject
        
        pathBox.Text = remoteData.Path 
        pathBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        if IsCallableObject(Instance) then
            -- Set UI for Command Mode
            argsLabel.Text = "Arguments (Type 'V3(x,y,z)' or 'CFR(x,y,z)' for object types):"
            argsBox.TextEditable = true
            execButton.Text = "EXECUTE CUSTOM COMMAND"
            codeTemplateButton.Text = "VIEW CODE TEMPLATE"
            permutationButton.Visible = true

            -- AUTO-EXECUTION LOGIC (Unchanged from v7)
            local guessedArgs, hints = GuessArguments(Instance.Name, Instance.ClassName)
            argsBox.Text = guessedArgs 
            
            execOutput.Text = string.format(
                "Auto-Executing %s: %s\n\n**Arguments Used (Guessed):** %s\n\nResult:", 
                Instance.ClassName, 
                Instance.Name, 
                guessedArgs
            )
            execOutput.TextColor3 = Color3.fromRGB(255, 165, 0)
            
            local args = ParseArguments(guessedArgs)
            local formattedArgs = FormatArgsTable(args) 

            local success, result = FireRemote(Instance, args)

            if success then
                local resultString = result and FormatArgument(result) or "nil"
                execOutput.Text = string.format(
                    "Auto-Executed %s: %s\n\n**Arguments Used (Confirmed):** %s\n\nSUCCESS.\nFunction Return: %s\n\n---\nArgument Testing Checklist:\n%s\n\nModify the arguments above or click 'Try Permutations' if this result is not what you expected.", 
                    Instance.ClassName, 
                    Instance.Name, 
                    formattedArgs, 
                    resultString, 
                    hints
                )
                execOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
            else
                execOutput.Text = string.format(
                    "Auto-Executed %s: %s\n\n**Arguments Used (Confirmed):** %s\n\nFAILURE.\nError Message: %s\n\n---\nArgument Testing Checklist:\n%s\n\nModify the arguments above or click 'Try Permutations'.", 
                    Instance.ClassName, 
                    Instance.Name, 
                    formattedArgs, 
                    tostring(result),
                    hints
                )
                execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
            end
            
        elseif IsScriptObject(Instance) then
            -- Set UI for Script Mode
            argsLabel.Text = "Arguments (Disabled for Scripts):"
            argsBox.Text = "--- Script Source Mode ---"
            argsBox.TextEditable = false
            execButton.Text = "--- CANNOT EXECUTE SCRIPT ---"
            codeTemplateButton.Text = "VIEW SOURCE (RE-VIEW)"
            permutationButton.Visible = false
            
            -- Display Source Code
            local sourceText
            local success, content = pcall(function()
                return Instance.Source
            end)
            
            if success and content then
                sourceText = content
                execOutput.TextColor3 = Color3.fromRGB(200, 200, 200)
                execOutput.Text = string.format("--- SOURCE CODE FOR %s (%s) ---\n\n%s", Instance.Name, Instance.ClassName, sourceText)
            else
                sourceText = "Error: Failed to retrieve script source. This can happen with certain protected scripts or environments."
                execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
                execOutput.Text = string.format("--- SOURCE CODE FOR %s (%s) ---\n\n%s\n\nError Details: %s", Instance.Name, Instance.ClassName, sourceText, tostring(content))
            end
        end
        
        SwitchView("Commander") 
    end)
    
    return btn
end

local function DisplayResults()
    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local totalItems = #foundRemotes
    if totalItems == 0 then
        execOutput.Text = "No remote commands or scripts found. This environment is highly secure."
        resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        return
    end

    for _, remote in ipairs(foundRemotes) do
        CreateRemoteButton(remote)
    end
    
    local totalHeight = totalItems * 27 
    resultsFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    Log(string.format("SUPER HARVEST COMPLETE: %d total items (Scripts/Commands) found.", totalItems))
    execOutput.Text = string.format("SUPER HARVEST COMPLETE: %d total items found. Click a command to **AUTO-EXECUTE** it or click a script to **VIEW SOURCE**.", totalItems)
    execOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
end

local function RunRemoteScan()
    table.clear(foundRemotes)
    selectedRemoteObject = nil 
    Log("Starting SUPER CHECK HARVEST for Scripts & Commands...")
    
    harvestButton.Text = "HARVESTING..."
    harvestButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    
    for _, service in ipairs(SERVICES_TO_SCAN) do
        task.spawn(function()
            DeepSearchForRemotes(service, "game." .. (service and service.Name or "nil"))
        end)
    end
    
    local success, _ = pcall(function() task.wait(2) end)
    if not success then Log("Warning: task.wait failed, possibly due to environment restrictions.") end
    
    DisplayResults()
    
    harvestButton.Text = "RE-RUN SUPER HARVEST (ALL SCRIPTS & REMOTES)"
    harvestButton.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
end

-- Button Connection: Run Super Harvest Button
harvestButton.MouseButton1Click:Connect(function()
    task.spawn(RunRemoteScan)
end)

-- ====================================================================
-- EXECUTOR LOGIC (Unchanged from v6/v7)
-- ====================================================================

local function ParseArguments(argString)
    local args = {}
    
    if string.len(argString) == 0 then return args end
    
    local function parseObjectArgs(objType, part)
        local pattern = "%( *([^,]+) *, *([^,]+) *, *([^%)]+)%)"
        local x, y, z = string.match(part, pattern)
        if x and y and z then
            local numX, numY, numZ = tonumber(x), tonumber(y), tonumber(z)
            if numX ~= nil and numY ~= nil and numZ ~= nil then
                if objType == "V3" then return Vector3.new(numX, numY, numZ) end
                if objType == "CFR" then return CFrame.new(numX, numY, numZ) end
                if objType == "C3" then return Color3.new(numX, numY, numZ) end
            end
        end
        return nil
    end

    for part in string.gmatch(argString, "([^,]+)") do
        local success, trimmedPart = pcall(function()
            return string.gsub(part, "^%s*(.-)%s*$", "%1") 
        end)
        
        if not success then
             trimmedPart = part 
        end
        
        local lowerPart = string.lower(trimmedPart)
        
        local obj
        if lowerPart:sub(1, 3) == "v3(" then obj = parseObjectArgs("V3", trimmedPart) end
        if lowerPart:sub(1, 4) == "cfr(" then obj = parseObjectArgs("CFR", trimmedPart) end
        if lowerPart:sub(1, 3) == "c3(" then obj = parseObjectArgs("C3", trimmedPart) end
        
        if obj then
            table.insert(args, obj)
        elseif tonumber(trimmedPart) ~= nil then
            table.insert(args, tonumber(trimmedPart)) 
        elseif lowerPart == "true" then
            table.insert(args, true) 
        elseif lowerPart == "false" then
            table.insert(args, false) 
        elseif Players:FindFirstChild(trimmedPart) then
            table.insert(args, Players:FindFirstChild(trimmedPart)) 
        elseif lowerPart == "nil" then
            table.insert(args, nil)
        else
            -- Insert as a raw string
            table.insert(args, trimmedPart) 
        end
    end
    
    return args
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
            error("Invalid Remote/Bindable object type.")
        end
    end

    success, result = pcall(resultWrapper)
    
    return success, result
end

-- Button Connection: Execute Custom Command
execButton.MouseButton1Click:Connect(function()
    local Instance = selectedRemoteObject 

    if not Instance or not IsCallableObject(Instance) then
        if IsScriptObject(Instance) then
             execOutput.Text = "Cannot execute a Script/LocalScript/ModuleScript using the command executor. Click 'VIEW SOURCE' to re-view the code."
        else
            execOutput.Text = "Execution Error: No command selected or selected item is not executable."
        end
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end
    
    local Remote = Instance 
    -- ... (rest of the FireRemote logic is the same)
    
    local argString = argsBox.Text
    local args = ParseArguments(argString)
    local formattedArgs = FormatArgsTable(args) 
    
    execOutput.Text = string.format(
        "Attempting to fire %s: %s\n\n**Arguments Passed (CONFIRMED):** %s\n\nResult:", 
        Remote.ClassName, 
        Remote.Name, 
        formattedArgs 
    )
    execOutput.TextColor3 = Color3.fromRGB(255, 165, 0)

    local success, result = FireRemote(Remote, args)
    
    -- Final Report
    if success then
        local resultString = result and FormatArgument(result) or "nil"
        execOutput.Text = execOutput.Text .. "\nSUCCESS.\nFunction Return: " .. resultString
        execOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        execOutput.Text = execOutput.Text .. "\nFAILURE.\nError Message: " .. tostring(result)
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- Button Connection: Try Permutations
permutationButton.MouseButton1Click:Connect(function()
    local Remote = selectedRemoteObject 

    if not Remote or not IsCallableObject(Remote) then
        execOutput.Text = "Permutation Error: Select an executable command first."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    local remoteName = Remote.Name
    local testValue = 99999 
    local testStatName = "TestString" 
    
    local permutations = {
        {"Empty Arguments", {}},
        {"Single String", {testStatName}},
        {"Single Number (99999)", {testValue}},
        {"Single Boolean (True)", {true}},
        {"String, Number", {testStatName, testValue}},
        {"Number, String", {testValue, testStatName}},
        {"String, Number, Bool(True)", {testStatName, testValue, true}},
    }
    
    local output = "--- PERMUTATION TEST: " .. remoteName .. " ---\n"
    execOutput.Text = output
    execOutput.TextColor3 = Color3.fromRGB(255, 165, 0)
    
    for i, test in ipairs(permutations) do
        local testName, args = unpack(test)
        
        local success, result = FireRemote(Remote, args)
        local resultString = result and FormatArgument(result) or "nil" 
        local color = success and (resultString == "nil" and "#FFC04D" or "#00FF00") or "#FF0000" 
        local formattedArgs = FormatArgsTable(args) 
        
        output = output .. string.format(
            "%d. %s: <font color='%s'>%s</font>\n    Args: %s\n", 
            i, 
            testName, 
            color, 
            resultString, 
            formattedArgs 
        )
        execOutput.Text = output
        task.wait(0.1) 
        
        if success and resultString ~= "nil" then
            execOutput.Text = output .. "\n\n--- FOUND VALID FORMAT! ---\nTest " .. i .. " produced a non-nil result. Try this argument structure manually!"
            break
        end
    end
    
    execOutput.Text = execOutput.Text .. "\n\n--- PERMUTATION TEST COMPLETE ---"
end)

-- GENERATE CODE TEMPLATE LOGIC 
local function GenerateCodeTemplate(instance)
    local instanceName = instance.Name
    local instanceType = instance.ClassName
    local path = instance.Path

    if IsScriptObject(instance) then
        -- Handle Script Source View
        local sourceText
        local success, content = pcall(function()
            return instance.Source
        end)
        
        if success and content then
            sourceText = content
        else
            sourceText = "Error: Failed to retrieve script source. %s"
        end
        
        return string.format(
            "--- SOURCE CODE FOR %s (%s) ---\n" ..
            "--- Path: %s\n" ..
            "----------------------------------------------------------\n\n%s",
            instanceName, instanceType, path, sourceText
        )
    end
    
    -- Handle Callable Object (Remote/Bindable) Template
    local isRemote = instanceType == "RemoteEvent" or instanceType == "RemoteFunction"
    local isFunction = instanceType == "RemoteFunction" or instanceType == "BindableFunction"
    
    local connectionType = isRemote and "OnServerEvent" or (isFunction and "OnInvoke" or "Event")
    local senderArg = isRemote and "sendingPlayer" or "" 
    local receiver = isRemote and "Server" or "Client"

    local args = "arg1, arg2, ..."
    local returns = isFunction and " return true" or ""
    
    local body = string.format(
        "    -- Use the arguments (arg1, arg2, ...) to figure out the actual function logic.\n" ..
        "    print(string.format(\"Received command from: %%s\", %s and %s.Name or \"LocalScript\"))\n" ..
        "    %s\n", 
        senderArg, senderArg, returns
    )
    
    local logicCheck = "    -- 1. Argument validation check (Essential Server Security!)\n" ..
                       "    -- If this is a Remote, sendingPlayer is always the first argument.\n" 
                       
    local playerCheck = isRemote and 
        "    -- NOTE: If this is a RemoteEvent/Function, the first argument in the connection is ALWAYS the Player object.\n" or 
        ""
                       
    local template = string.format(
        "--- THEORETICAL %s CODE TEMPLATE for %s ---\n" ..
        "--- This is the LUA code the %s is *most likely* running. ---\n" ..
        "--- Use the argument structure below for your own call.\n" ..
        "----------------------------------------------------------\n\n" ..
        "local remote = %s\n" ..
        "%s" .. 
        "remote.%s(%s, function(%s) --> (Server/Client Code)\n" ..
        "%s" ..
        "    -- The client only sends the arguments: (%s)\n" ..
        "%s\n" ..
        "end)\n\n" ..
        "----------------------------------------------------------\n" ..
        "Your Client Call Must Look Like:\n" ..
        "%s:FireServer(%s)\n" ..
        "----------------------------------------------------------\n",
        receiver, instanceName, receiver,
        path, playerCheck,
        connectionType, senderArg, args,
        logicCheck, args,
        body,
        instanceName, "arg1, arg2, ..."
    )
    
    return template
end


-- Button Connection: View Code Template
codeTemplateButton.MouseButton1Click:Connect(function()
    local Instance = selectedRemoteObject 

    if not Instance then
        execOutput.Text = "Code Template/Source Error: Select an item first."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    local success, template = pcall(GenerateCodeTemplate, Instance)
    
    if success then
        execOutput.Text = template
        execOutput.TextColor3 = Color3.fromRGB(200, 200, 200)
        -- Ensure the output box is configured for source viewing if it's a script
        if IsScriptObject(Instance) then
            execOutput.TextSize = 12
        else
            execOutput.TextSize = 16
        end
    else
        execOutput.Text = "Critical Error in Template/Source Generation. Check the console for details."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        Log("CRITICAL FAILURE in GenerateCodeTemplate: " .. tostring(template))
    end
end)
