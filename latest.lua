--[[
    REMOTE EVENT SPY - A TOOL TO FIND EXPLOITABLE REMOTE EVENTS
    
    Since generic 'Bring' hacks failed, this script searches the entire game 
    environment for RemoteEvents with suspicious names that developers might 
    have used for admin tools or character manipulation.
    
    If you find one, you can use the name with a 'FireServer' command.
]]
local Game = game
local Players = Game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local SimpleNotify -- Placeholder for a notification function
if not LocalPlayer then return end

-- Helper to print to console or notify (reusing the console print for simplicity)
SimpleNotify = function(text)
    print("[RemoteSpy] " .. text)
end

local SUSPICIOUS_KEYWORDS = {
    "teleport", "tp", "move", "position", "pos", "warp", "goto", 
    "admin", "kick", "ban", "kill", "respawn", "cframe", "setplayer", "setchar"
}

-- Recursive function to search for remote events matching keywords
local function DeepSearchForRemotes(instance, results, path)
    -- Check if the instance is a RemoteEvent or RemoteFunction
    if instance:IsA("RemoteEvent") or instance:IsA("RemoteFunction") then
        local instancePath = path .. "." .. instance.Name
        local lowerName = string.lower(instance.Name)
        
        for _, keyword in ipairs(SUSPICIOUS_KEYWORDS) do
            if string.find(lowerName, keyword) then
                table.insert(results, {Name = instance.Name, Path = instancePath, Type = instance.ClassName})
                return -- Stop searching this branch once found
            end
        end
    end

    -- Recurse through children
    for _, child in ipairs(instance:GetChildren()) do
        -- Skip core services that are huge and unlikely to contain exploits
        if child.Name ~= "CoreGui" and child.Name ~= "ReplicatedStorage" and child.Name ~= "Players" then
            DeepSearchForRemotes(child, results, path .. "." .. child.Name)
        end
    end
end

-- Main function to run the deep scan
local function RunRemoteScan()
    SimpleNotify("Starting Deep Remote Event Scan for exploit targets...")
    
    local startTime = os.clock()
    local foundRemotes = {}
    
    -- Start search from Workspace and ServerScriptService/ReplicatedFirst for best coverage
    DeepSearchForRemotes(Game:GetService("Workspace"), foundRemotes, "game.Workspace")
    DeepSearchForRemotes(Game:GetService("ReplicatedFirst"), foundRemotes, "game.ReplicatedFirst")
    
    local endTime = os.clock()
    local duration = string.format("%.2f", endTime - startTime)

    SimpleNotify(string.format("Scan finished in %s seconds. Found %d potential exploit targets:", duration, #foundRemotes))
    
    if #foundRemotes > 0 then
        for i, remote in ipairs(foundRemotes) do
            SimpleNotify(string.format("  [%d] %s: %s (Type: %s)", i, remote.Name, remote.Path, remote.Type))
        end
        SimpleNotify("Copy one of the paths (e.g., 'game.Workspace.TeleportEvent') and try to fire it manually.")
    else
        SimpleNotify("No suspicious remote events found with generic keywords.")
    end
end

-- ====================================================================
-- GUI SETUP 
-- ====================================================================

local gui = Instance.new("ScreenGui")
gui.Name = "RemoteSpyGui"
gui.IgnoreGuiInset = true
gui.Parent = Game:GetService("CoreGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "SpyFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 150)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "TitleBar"
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Remote Event Spy (Final Tool)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Parent = mainFrame

local description = Instance.new("TextLabel")
description.Name = "DescriptionLabel"
description.Size = UDim2.new(1, -20, 0, 40)
description.Position = UDim2.new(0, 10, 0, 35)
description.Text = "Click 'Scan' to search for hidden teleport/admin RemoteEvents in the game. Results print to the executor console."
description.TextColor3 = Color3.fromRGB(180, 180, 180)
description.Font = Enum.Font.SourceSans
description.TextSize = 14
description.BackgroundTransparency = 1
description.TextWrapped = true
description.Parent = mainFrame

local scanButton = Instance.new("TextButton")
scanButton.Name = "ScanButton"
scanButton.Size = UDim2.new(1, -20, 0, 40)
scanButton.Position = UDim2.new(0, 10, 0, 90)
scanButton.Text = "RUN DEEP SCAN"
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Font = Enum.Font.SourceSansBold
scanButton.TextSize = 20
scanButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
scanButton.Parent = mainFrame

scanButton.MouseButton1Click:Connect(RunRemoteScan)

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

SimpleNotify("Remote Event Spy loaded. Click RUN DEEP SCAN to find game-specific exploit targets.")
