--[[
    UNIVERSAL REMOTE COMMANDER: Code Templating & Enhanced Debugging.
    
    This version generates a theoretical Lua template to infer argument structure
    and provides the most robust argument parsing for complex types (V3, CFrame, Color3).
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
    "char", "character", "load", "save", "debug", "test", "dev",
    "give", "add", "remove", "currency", "level", "xp", "money", "cash", "luck", 
    "hook", "client", "local", "trigger" 
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

-- Function to check if an instance is a callable remote/bindable object
local function IsCallableObject(instance)
    return instance:IsA("RemoteEvent") or 
           instance:IsA("RemoteFunction") or
           instance:IsA("BindableEvent") or
           instance:IsA("BindableFunction")
end

-- Function to guess arguments and provide hints 
local function GuessArguments(remoteName, remoteType)
    local lowerName = string.lower(remoteName)
    local prefill = ""
    local hints = {}
    
    local isBindable = remoteType == "BindableEvent" or remoteType == "BindableFunction"
    local playerArg = isBindable and "" or "LocalPlayer, " 
    local targetType = isBindable and "Local Client Function" or "Server Remote Command"

    table.insert(hints, string.format("- **Target Type:** %s", targetType))

    if string.find(lowerName, "stat") or string.find(lowerName, "value") or string.find(lowerName, "set") or string.find(lowerName, "luck") then
        prefill = playerArg .. "StatName_STRING, 99999_NUMBER"
        table.insert(hints, "- **Stat Setter Guesses**:")
        table.insert(hints, "  - *Use the 'Try Permutations' button for automated testing.*")
        table.insert(hints, string.format("  - `%s\"Luck\", 99999` (The most common full format)", playerArg))
    elseif string.find(lowerName, "teleport") or string.find(lowerName, "tp") or string.find(lowerName, "move") or string.find(lowerName, "cframe") then
        prefill = playerArg .. "CFR(0, 50, 0)"
        table.insert(hints, "- **Movement Guesses**:")
        table.insert(hints, "  - `CFR(0, 50, 0)` (For CFrame input)")
        table.insert(hints, "  - `V3(0, 50, 0)` (For Vector3 input)")
    elseif string.find(lowerName, "give") or string.find(lowerName, "item") or string.find(lowerName, "add") then
        prefill = playerArg .. "ItemName_STRING, 1_NUMBER"
        table.insert(hints, "- **Item Guesses**:")
        table.insert(hints, string.format("  - `%s\"Sword\", 1`", playerArg))
    else
        prefill = playerArg:sub(1, -3) 
        if prefill == "" then prefill = "true" end
        table.insert(hints, "- **General Guess**:")
        table.insert(hints, "  - Try: `true`, `\"Test\"`, or leave blank.")
    end
    
    return prefill, table.concat(hints, "\n")
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
                Instance = instance 
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
frame.Size = UDim2.new(0, 780, 0, 550) 
frame.Position = UDim2.new(0.5, -390, 0.5, -275)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(15, 15, 15)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Universal Remote Commander (Code Template Debugger)"
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
harvestTitle.Text = "STEP 1: COMMAND/FUNCTION HARVESTER"
harvestTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
harvestTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
harvestTitle.Parent = harvestPanel

local harvestButton = Instance.new("TextButton")
harvestButton.Size = UDim2.new(1, -10, 0, 40)
harvestButton.Position = UDim2.new(0, 5, 0, 35)
harvestButton.Text = "RUN SMART HARVEST"
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
execTitle.Text = "STEP 2: REMOTE/BINDABLE COMMANDER"
execTitle.TextColor3 = Color3.fromRGB(255, 255, 100)
execTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
execTitle.Parent = execPanel

-- Path Box 
local pathLabel = Instance.new("TextLabel")
pathLabel.Size = UDim2.new(1, -10, 0, 15)
pathLabel.Position = UDim2.new(0, 5, 0, 35)
pathLabel.Text = "Function Path:"
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
pathBox.TextEditable = false 

-- Arguments Box
local argsLabel = pathLabel:Clone()
argsLabel.Position = UDim2.new(0, 5, 0, 85)
argsLabel.Text = "Arguments (Type 'V3(x,y,z)' or 'CFR(x,y,z)' for object types):"
argsLabel.Parent = execPanel

local argsBox = pathBox:Clone()
argsBox.Size = UDim2.new(1, -10, 0, 30)
argsBox.Position = UDim2.new(0, 5, 0, 100)
argsBox.PlaceholderText = "LocalPlayer, StatName, NewValue"
argsBox.Text = "" 
argsBox.TextColor3 = Color3.fromRGB(255, 255, 255)
argsBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
argsBox.TextEditable = true
argsBox.Parent = execPanel

-- Argument Help Box 
local argHelp = Instance.new("TextLabel")
argHelp.Size = UDim2.new(1, -10, 0, 30)
argHelp.Position = UDim2.new(0, 5, 0, 135)
argHelp.Text = "HINT: V3 = Vector3(x, y, z), CFR = CFrame(x, y, z). Use 'LocalPlayer' for yourself."
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
execButton.Position = UDim2.new(0, 5, 0, 170) 
execButton.Text = "EXECUTE CUSTOM COMMAND"
execButton.TextColor3 = Color3.fromRGB(255, 255, 255)
execButton.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
execButton.Parent = execPanel

-- PERMUTATION BUTTON
local permutationButton = harvestButton:Clone()
permutationButton.Size = UDim2.new(0.5, -8, 0, 40)
permutationButton.Position = UDim2.new(0, 5, 0, 215) 
permutationButton.Text = "TRY PERMUTATIONS"
permutationButton.TextColor3 = Color3.fromRGB(20, 20, 20)
permutationButton.Font = Enum.Font.SourceSansBold
permutationButton.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
permutationButton.Parent = execPanel

-- VIEW CODE TEMPLATE BUTTON (NEW)
local codeTemplateButton = harvestButton:Clone()
codeTemplateButton.Size = UDim2.new(0.5, -8, 0, 40)
codeTemplateButton.Position = UDim2.new(0.5, 3, 0, 215) 
codeTemplateButton.Text = "VIEW CODE TEMPLATE"
codeTemplateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
codeTemplateButton.Font = Enum.Font.SourceSansBold
codeTemplateButton.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
codeTemplateButton.Parent = execPanel


-- Output Console
local outputLabel = pathLabel:Clone()
outputLabel.Position = UDim2.new(0, 5, 0, 265) 
outputLabel.Text = "Execution Console Output:"
outputLabel.Parent = execPanel

local execOutput = Instance.new("TextBox")
execOutput.Size = UDim2.new(1, -10, 1, -290) 
execOutput.Position = UDim2.new(0, 5, 0, 280) 
execOutput.Text = "Select a command/function on the left and enter arguments to begin."
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
    
    local abbr = remoteData.Type:sub(1,1)
    local nameColor = "#FFC04D" -- RemoteEvent (E)
    if remoteData.Type == "RemoteFunction" then
        nameColor = "#4DFFFF" -- RemoteFunction (F)
    elseif remoteData.Type == "BindableEvent" or remoteData.Type == "BindableFunction" then
        nameColor = "#FF4DFF" -- Bindable (BE/BF) - Local Function Codes
        abbr = remoteData.Type == "BindableEvent" and "BE" or "BF"
    end
    
    local matchText = table.concat(remoteData.Categories, ", ")

    btn.Text = string.format("  <font color='%s'>%s</font> | %s | Matches: %s", 
        nameColor, 
        remoteData.Name, 
        abbr,
        matchText
    )
    btn.RichText = true
    btn.Parent = resultsFrame

    -- On Click, populate the executor panel
    btn.MouseButton1Click:Connect(function()
        selectedRemoteObject = remoteData.Instance
        pathBox.Text = remoteData.Path 
        pathBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        local guessedArgs, hints = GuessArguments(remoteData.Name, remoteData.Type)
        
        argsBox.Text = guessedArgs 
        
        execOutput.Text = string.format(
            "Command Selected: %s (%s)\nPath: %s\n\nGuessed Argument Format: %s\n\n---\n\n**Argument Testing Checklist:**\n%s\n\nTry the suggested formats, use 'Try Permutations', or 'View Code Template'!", 
            remoteData.Name, 
            remoteData.Type, 
            remoteData.Path,
            guessedArgs,
            hints 
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
        execOutput.Text = "No suspicious commands or functions found. Security is extremely high."
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
    selectedRemoteObject = nil 
    Log("Starting SMART CODE HARVEST...")
    
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
    
    harvestButton.Text = "RE-RUN SMART HARVEST"
    harvestButton.BackgroundColor3 = Color3.fromRGB(130, 0, 255)
end

harvestButton.MouseButton1Click:Connect(function()
    task.spawn(RunRemoteScan)
end)

-- ====================================================================
-- EXECUTOR LOGIC (RIGHT PANEL)
-- ====================================================================

local function ParseArguments(argString)
    local args = {}
    
    if string.len(argString) == 0 then return args end
    
    -- Function to parse V3/CFR/C3 arguments inside parentheses
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

    -- Split by comma and trim whitespace
    for part in string.gmatch(argString, "([^,]+)") do
        local success, trimmedPart = pcall(function()
            return string.gsub(part, "^%s*(.-)%s*$", "%1") -- Trim whitespace
        end)
        
        if not success then
             -- Fallback for environments where string.gsub is restricted
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
        elseif lowerPart == "localplayer" then
            table.insert(args, LocalPlayer) 
        elseif Players:FindFirstChild(trimmedPart) then
            table.insert(args, Players:FindFirstChild(trimmedPart)) 
        elseif lowerPart == "nil" then
            table.insert(args, nil)
        else
            table.insert(args, trimmedPart) 
        end
    end
    
    return args
end

-- Generalized function to fire the remote/bindable
local function FireRemote(remote, args)
    local success, result
    
    if remote:IsA("RemoteEvent") then
        success, result = pcall(remote.FireServer, remote, unpack(args)) 
    elseif remote:IsA("BindableEvent") then
        success, result = pcall(remote.Fire, remote, unpack(args)) 
    elseif remote:IsA("RemoteFunction") then
        success, result = pcall(remote.InvokeServer, remote, unpack(args)) 
    elseif remote:IsA("BindableFunction") then
        success, result = pcall(remote.Invoke, remote, unpack(args)) 
    else
        success = false
        result = "Invalid Remote/Bindable object type."
    end
    
    return success, result
end

-- Handle single command execution from the manual box
execButton.MouseButton1Click:Connect(function()
    local Remote = selectedRemoteObject 

    if not Remote or not IsCallableObject(Remote) then
        execOutput.Text = "Execution Error: No command selected. Click an item in the Harvester list."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    local argString = argsBox.Text
    local args = ParseArguments(argString)
    
    execOutput.Text = string.format("Attempting to fire %s: %s\nArguments: %s\n\nResult:", Remote.ClassName, Remote.Name, table.concat(args, ", "))
    execOutput.TextColor3 = Color3.fromRGB(255, 165, 0)

    local success, result = FireRemote(Remote, args)
    
    -- Final Report
    if success then
        local resultString = result and tostring(result) or "nil"
        execOutput.Text = execOutput.Text .. "\nSUCCESS.\nFunction Return: " .. resultString
        execOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        execOutput.Text = execOutput.Text .. "\nFAILURE.\nError Message: " .. tostring(result)
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- Handle automated permutation testing
permutationButton.MouseButton1Click:Connect(function()
    local Remote = selectedRemoteObject 

    if not Remote or not IsCallableObject(Remote) then
        execOutput.Text = "Permutation Error: Select a command first."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    local remoteName = Remote.Name
    local testValue = 99999 
    local testStatName = "Luck" 
    
    local permutations = {
        {"Value Only", {testValue}},
        {"Player, Value", {LocalPlayer, testValue}},
        {"StatName, Value", {testStatName, testValue}},
        {"Player, StatName, Value", {LocalPlayer, testStatName, testValue}},
        {"Player, Value, Bool(True)", {LocalPlayer, testValue, true}},
    }
    
    local output = "--- PERMUTATION TEST: " .. remoteName .. " ---\n"
    execOutput.Text = output
    execOutput.TextColor3 = Color3.fromRGB(255, 165, 0)
    
    for i, test in ipairs(permutations) do
        local testName, args = unpack(test)
        
        if Remote:IsA("RemoteEvent") or Remote:IsA("RemoteFunction") or not string.find(testName, "Player") then
            
            local success, result = FireRemote(Remote, args)
            local resultString = result and tostring(result) or "nil"
            local color = success and (resultString == "nil" and "#FFC04D" or "#00FF00") or "#FF0000" 
            
            output = output .. string.format(
                "%d. %s: <font color='%s'>%s</font>\n    Args: %s\n", 
                i, 
                testName, 
                color, 
                resultString, 
                table.concat(args, ", ")
            )
            execOutput.Text = output
            task.wait(0.1) 
            
            if success and resultString ~= "nil" then
                execOutput.Text = output .. "\n--- FOUND VALID FORMAT! ---\nTest " .. i .. " produced a non-nil result. Try this argument structure manually!"
                break
            end
        end
    end
    
    execOutput.Text = execOutput.Text .. "\n\n--- PERMUTATION TEST COMPLETE ---"
end)

-- GENERATE CODE TEMPLATE LOGIC (NEW)
local function GenerateCodeTemplate(remoteObject)
    local remoteName = remoteObject.Name
    local remoteType = remoteObject.ClassName
    local path = remoteObject.Path
    
    local isRemote = remoteType == "RemoteEvent" or remoteType == "RemoteFunction"
    local isFunction = remoteType == "RemoteFunction" or remoteType == "BindableFunction"
    local isBindable = remoteType == "BindableEvent" or remoteType == "BindableFunction"
    
    local handler = isRemote and "OnServerEvent" or (isFunction and "Invoke" or "Event")
    local connection = isRemote and "Connect" or "Connect" 
    local playerArgName = isRemote and "player" or ""
    local exampleStatName = string.match(string.lower(remoteName), "stat") and "statName" or "valueName"
    
    local codeTemplate = ""
    
    if isRemote then
        -- Server-side code template for Remotes (The code you want to see, but can't)
        codeTemplate = string.format(
            "--- THEORETICAL SERVER-SIDE CODE for %s ---\n", remoteName
        )
        if string.find(string.lower(remoteName), "set") or string.find(string.lower(remoteName), "give") then
            codeTemplate = codeTemplate .. string.format(
                "game.ReplicatedStorage.%s.%s:%s:Connect(function(%s, %s, value)\n" ..
                "    -- 1. Check if the value is valid (Server-Side Check!)\n" ..
                "    if type(value) ~= 'number' or value > 1000 then return end\n" ..
                "    -- 2. Check if player has permission\n" ..
                "    if player.Character:GetAttribute('Admin') == true then\n" ..
                "        player.leaderstats:%s.Value = value\n" ..
                "        return true -- Or simply nothing for an Event\n" ..
                "    end\n" ..
                "end)\n",
                remoteName, remoteName, handler, playerArgName, exampleStatName
            )
        elseif string.find(string.lower(remoteName), "teleport") then
             codeTemplate = codeTemplate .. string.format(
                "game.ReplicatedStorage.%s.%s:%s:Connect(function(%s, targetCFrame)\n" ..
                "    -- 1. Check CFrame validity\n" ..
                "    if targetCFrame.Y > 5000 then return end\n" ..
                "    -- 2. Execute teleport command\n" ..
                "    if player.Character and player.Character:FindFirstChild('HumanoidRootPart') then\n" ..
                "        player.Character.HumanoidRootPart.CFrame = targetCFrame\n" ..
                "    end\n" ..
                "end)\n",
                remoteName, remoteName, handler, playerArgName
            )
        else
            codeTemplate = codeTemplate .. string.format(
                "game.ReplicatedStorage.%s.%s:%s:Connect(function(%s, ...)\n" ..
                "    -- The server code checks your arguments here! \n" ..
                "    -- If you send the wrong number/type of arguments, it returns nil.\n" ..
                "    print('Received command from: ' .. %s.Name)\n" ..
                "end)\n",
                remoteName, remoteName, handler, playerArgName, playerArgName
            )
        end
        codeTemplate = "\n" .. codeTemplate .. "\n" .. "--- The **client-side arguments** you send must exactly match the server's expected arguments (excluding the first 'player' argument)."
    else
        -- Client-side code template for Bindables (The code you want to see)
        codeTemplate = string.format(
            "--- THEORETICAL CLIENT-SIDE CODE for %s ---\n", remoteName
        )
        if string.find(string.lower(remoteName), "set") or string.find(string.lower(remoteName), "update") then
             codeTemplate = codeTemplate .. string.format(
                "game.ReplicatedStorage.%s.%s.Event:%s(function(%s, value)\n" ..
                "    -- This is the code that *receives* a command (usually from the server)\n" ..
                "    local statObject = LocalPlayer.PlayerGui.UI.%s\n" ..
                "    statObject.Text = string.format('%%s: %%d', %s, value)\n" ..
                "end)\n",
                remoteName, remoteName, connection, exampleStatName, exampleStatName, exampleStatName
            )
        else
             codeTemplate = codeTemplate .. string.format(
                "game.ReplicatedStorage.%s.%s.Event:%s(function(...)\n" ..
                "    -- This simple trigger is often used to launch a local GUI effect.\n" ..
                "    print('Local event fired!')\n" ..
                "end)\n",
                remoteName, remoteName, connection
            )
        end
        codeTemplate = "\n" .. codeTemplate .. "\n" .. "--- This is the local code that runs when this Bindable/Remote is executed. Your goal is to find the arguments it expects."
    end
    
    return codeTemplate
end


codeTemplateButton.MouseButton1Click:Connect(function()
    local Remote = selectedRemoteObject 

    if not Remote or not IsCallableObject(Remote) then
        execOutput.Text = "Code Template Error: Select a command first."
        execOutput.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    local template = GenerateCodeTemplate(Remote)
    
    execOutput.Text = template
    execOutput.TextColor3 = Color3.fromRGB(200, 200, 200)
end)
