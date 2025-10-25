--[[
    UNIVERSAL CODE HARVESTER (GUI OUTPUT) - THE FINAL, UNRESTRICTED SCANNER
    
    This script searches the entire game for ALL types of callable functions 
    that match any known exploit keyword and displays them in an interactive GUI.
]]

local Game = game
local Players = Game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local SimpleNotify 
if not LocalPlayer then return end

SimpleNotify = function(text)
    print("--- [CODE HARVESTER] " .. text)
end

-- Exhaustive list of keywords covering ALL major exploit and dev vectors
local SUSPICIOUS_KEYWORDS = {
    -- 1. Movement/Teleportation
    "teleport", "tp", "move", "position", "pos", "warp", "goto", "cframe", "jumpto", "setcframe",
    
    -- 2. Admin/Actions
    "admin", "kick", "ban", "kill", "respawn", "damage", "health", "clear", "tool", "give", 
    "take", "award", "execute", "command", "server", "client", "setprop", "property", "override",
    
    -- 3. Inventory/Economy
    "item", "inventory", "purchase", "sell", "equip", "unequip", "shop", "currency", "cash", "coins",
    
    -- 4. Statistics/Game State
    "stat", "update", "value", "setvalue", "leaderstat", "gamestate", "time", "weather", 
    "replicate", "sync", "load", "save", "data", "playerdata",
    
    -- 5. Character/Model Manipulation
    "char", "character", "setprimary", "setparent", "destroy", "clothe", "outfit", "accessory",
    
    -- 6. Debug/Hidden Functions
    "debug", "test", "dev", "fix", "error", "message"
}

-- Comprehensive list of services to scan
local SERVICES_TO_SCAN = {
    Game:GetService("Workspace"),
    Game:GetService("ReplicatedStorage"),
    Game:GetService("ReplicatedFirst"),
    Game:GetService("StarterGui"),
    Game:GetService("StarterPlayer"):FindFirstChild("StarterCharacterScripts"),
    Game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"),
    Game:GetService("SoundService"),
    Game:GetService("Lighting"),
}

local foundRemotes = {}

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
                Categories = categories
            })
        end
    end

    -- Recurse through children
    for _, child in ipairs(instance:GetChildren()) do
        -- Skip objects with huge numbers of children
        if #child:GetChildren() < 1000 and 
           not child:IsA("Configuration") and 
           not child:IsA("MaterialService")
        then
            -- Skip top-level services already in the SERVICES_TO_SCAN list
            local isTopLevel = false
            for _, service in ipairs(SERVICES_TO_SCAN) do
                if child == service then isTopLevel = true; break end
            end
            
            if not isTopLevel then
                DeepSearchForRemotes(child, path .. "." .. child.Name)
            end
        end
    end
end

-- ====================================================================
-- GUI AND DISPLAY LOGIC
-- ====================================================================

local CoreGui = Game:GetService("CoreGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CodeHarvesterGUI"
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 500) -- Larger frame for list
frame.Position = UDim2.new(0.5, -200, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(15, 15, 15)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Universal Code Harvester (Final Tool)"
title.TextColor3 = Color3.fromRGB(255, 100, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -20, 0, 40)
button.Position = UDim2.new(0, 10, 0, 35)
button.Text = "RUN ULTIMATE HARVEST"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 18
button.BackgroundColor3 = Color3.fromRGB(200, 0, 255)
button.Parent = frame

local statusBox = Instance.new("TextBox")
statusBox.Size = UDim2.new(1, -20, 0, 25)
statusBox.Position = UDim2.new(0, 10, 1, -30) -- Placed at the very bottom
statusBox.Text = "Click a command to copy its path."
statusBox.PlaceholderText = ""
statusBox.TextSize = 14
statusBox.Font = Enum.Font.SourceSans
statusBox.TextColor3 = Color3.fromRGB(255, 255, 255)
statusBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
statusBox.Parent = frame
statusBox.ClearTextOnFocus = false

local resultsFrame = Instance.new("ScrollingFrame")
resultsFrame.Size = UDim2.new(1, -20, 1, -140) -- Fills remaining space
resultsFrame.Position = UDim2.new(0, 10, 0, 80)
resultsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
resultsFrame.BorderSizePixel = 0
resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsFrame.ScrollBarThickness = 6
resultsFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = resultsFrame

-- Function to create a clickable button for a remote
local function CreateRemoteButton(remoteData)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.BorderColor3 = Color3.fromRGB(15, 15, 15)
    btn.BorderSizePixel = 1
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    
    local nameColor = remoteData.Type == "RemoteEvent" and "<font color='#FFC04D'>" or "<font color='#4DFFFF'>" -- Yellow for Event, Cyan for Function

    btn.Text = string.format("  %s%s</font> | %s | Matches: %s", 
        nameColor, 
        remoteData.Name, 
        remoteData.Type,
        table.concat(remoteData.Categories, ", ")
    )
    btn.RichText = true
    btn.Parent = resultsFrame

    -- On Click, copy the path to the clipboard/status box
    btn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(remoteData.Path)
            statusBox.Text = "Copied Path: " .. remoteData.Path
            statusBox.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            statusBox.Text = "Path: " .. remoteData.Path .. " (Copy manually from this box)"
            statusBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            statusBox.TextEditable = true
        end
    end)
    
    return btn
end

-- Function to display all harvested results in the GUI
local function DisplayResults()
    -- Clear previous results
    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    if #foundRemotes == 0 then
        statusBox.Text = "No suspicious commands found. Security is high."
        resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        return
    end

    -- Create buttons for all found remotes
    for _, remote in ipairs(foundRemotes) do
        CreateRemoteButton(remote)
    end
    
    -- Resize the Canvas to fit all items
    local totalHeight = #foundRemotes * 27 -- 25px height + 2px padding
    resultsFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    statusBox.Text = string.format("HARVEST COMPLETE: %d commands found. Click to copy path.", #foundRemotes)
    statusBox.TextColor3 = Color3.fromRGB(0, 255, 100)
end

-- Main function to run the deep scan
local function RunRemoteScan()
    table.clear(foundRemotes)
    SimpleNotify("Starting ULTIMATE CODE HARVEST across all game services...")
    
    button.Text = "HARVESTING... (Wait for Console Output)"
    button.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    statusBox.Text = "Scanning game objects. Please wait..."
    statusBox.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    local startTime = os.clock()
    
    for _, service in ipairs(SERVICES_TO_SCAN) do
        SimpleNotify("Scanning: " .. (service and service.Name or "nil"))
        DeepSearchForRemotes(service, "game." .. (service and service.Name or "nil"))
    end
    
    local endTime = os.clock()
    local duration = string.format("%.2f", endTime - startTime)

    SimpleNotify("==================================================")
    SimpleNotify(string.format("HARVEST COMPLETE in %s seconds. Found %d total callable targets.", duration, #foundRemotes))
    
    -- Call display function after scan completes
    DisplayResults()
    
    button.Text = "RE-RUN ULTIMATE HARVEST"
    button.BackgroundColor3 = Color3.fromRGB(200, 0, 255)
end

button.MouseButton1Click:Connect(function()
    task.spawn(RunRemoteScan)
end)
