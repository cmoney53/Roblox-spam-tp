--[[
    ADVANCED EXPLOIT ARTIFACT SCANNER

    This script performs an exhaustive search to detect injected exploit scripts and their artifacts.
    It covers three main detection vectors:
    1. GUI Elements: Scanning CoreGui for hidden or suspicious UIs.
    2. Global Environment (_G / getgenv()): Searching for functions, tables, and flags used by exploits.
    3. Function Signatures: Searching global tables for functions named 'addcmd' or similar,
       and extracting all registered commands if possible.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local CurrentPlayer = Players.LocalPlayer

-- Global environment to scan (use getgenv() if available, otherwise fallback to _G)
local GLOBAL_ENV = getgenv and getgenv() or _G

-- ====================================================================
-- 1. GUI SCANNER
-- ====================================================================

local function scan_for_gui_menus()
    print("--- 1. SCANNING COREGUI FOR INJECTED MENUS (VISIBLE & HIDDEN) ---")
    local suspicious_elements = {}

    local function is_suspicious_name(name)
        local lower_name = name:lower()
        return lower_name:match("exploit") or lower_name:match("menu") or
               lower_name:match("gui") or lower_name:match("yield") or
               lower_name:match("script") or lower_name:match("console") or
               lower_name:match("hub")
    end

    for _, element in ipairs(CoreGui:GetChildren()) do
        local is_hidden = not element.Visible
        local is_named = is_suspicious_name(element.Name) or is_suspicious_name(element.ClassName)

        -- Detect based on naming convention or if it's a hidden, non-default UI element
        if is_named or (is_hidden and element.ClassName:match("Gui")) then
            local status = {}
            if is_hidden then table.insert(status, "Hidden") end
            if is_named then table.insert(status, "Suspicious Name") end

            table.insert(suspicious_elements, {
                Name = element.Name,
                Class = element.ClassName,
                Visible = element.Visible,
                Status = table.concat(status, " | ")
            })

            -- Attempt to force a hidden GUI to show
            if not element.Visible and (element.ClassName == "ScreenGui" or element.ClassName == "Frame") then
                 pcall(function() element.Visible = true end)
                 -- NOTE: We don't print here to avoid false positives, the final report is accurate.
            end
        end
    end

    if #suspicious_elements > 0 then
        print(string.format("[GUI DETECTED] Found %d potentially active exploit GUIs/elements:", #suspicious_elements))
        for _, info in ipairs(suspicious_elements) do
            print(string.format("  - Name: %s, Class: %s, Status: %s, Visible: %s",
                info.Name, info.Class, info.Status, tostring(info.Visible)))
        end
    else
        print("[GUI DETECTED] No obvious injected GUI elements found in CoreGui.")
    end
end

-- ====================================================================
-- 2. GLOBAL ENVIRONMENT SCANNER
-- ====================================================================

local function scan_global_environment()
    print("--- 2. SCANNING GLOBAL ENVIRONMENT FOR EXPLOIT ARTIFACTS ---")
    local global_hits = {}
    local function_hits = {}
    local table_hits = {}

    -- Common names for exploit-related global variables/functions
    local SUSPICIOUS_NAMES = {
        "addcmd", "notify", "getgenv", "getreg", "rconsoleprint", "syn_send", "fireclickdetector",
        "IY_LOADED", "IY_DEBUG", "COMMANDS", "CMD_LIST", "remoteeventhook", "message", "rconsole"
    }

    local function check_global(key, value)
        local type_str = type(value)

        -- Check against the known list of suspicious names
        if table.find(SUSPICIOUS_NAMES, key) then
             table.insert(global_hits, {Name = key, Type = type_str})
             return
        end

        -- Look for general suspicious naming conventions
        local lower_key = key:lower()
        if lower_key:match("exploit") or lower_key:match("cmd") or lower_key:match("script") or
           lower_key:match("menu") or lower_key:match("hook") then
            table.insert(global_hits, {Name = key, Type = type_str, Note = "Suspect Name"})
        end

        -- Recursively scan large, non-standard tables for functions
        if type_str == "table" and key ~= "_G" and key ~= "game" and #value > 1 and table.getn(value) > 0 then
            table.insert(table_hits, {Name = key, Count = table.getn(value)})
            for k, v in pairs(value) do
                if type(v) == "function" and tostring(k):lower():match("cmd") then
                    table.insert(function_hits, {Name = key .. "." .. tostring(k), Note = "Command-like function inside table"})
                end
            end
        end

        -- Store any globally defined function (a massive indicator of an injected script)
        if type_str == "function" and not string.find(key, "pcall") and not string.find(key, "xpcall") then
            -- Exclude default/whitelisted functions (e.g., math.sin, print, etc.)
            -- We already checked for known suspicious functions above, so this captures generic ones.
        end
    end

    for key, value in pairs(GLOBAL_ENV) do
        check_global(key, value)
    end

    if #global_hits > 0 or #table_hits > 0 then
        print(string.format("[GLOBAL DETECTED] Found %d suspicious global artifacts:", #global_hits + #table_hits))
        for _, info in ipairs(global_hits) do
            print(string.format("  - ARTIFACT: %s (Type: %s, Note: %s)", info.Name, info.Type, info.Note or "Known Exploit Flag/Func"))
        end
        for _, info in ipairs(table_hits) do
            print(string.format("  - LARGE TABLE: %s (Size: %d entries, Potential Command Table)", info.Name, info.Count))
        }
        if #function_hits > 0 then
            print("  - COMMAND FUNCTIONS FOUND INSIDE TABLES:")
            for _, info in ipairs(function_hits) do
                 print(string.format("    -> %s", info.Name))
            end
        end
    else
        print("[GLOBAL DETECTED] No suspicious global variables or functions found.")
    end
end

-- ====================================================================
-- MAIN EXECUTION
-- ====================================================================

local function run_detector()
    if not CurrentPlayer then
        print("Detector failed: LocalPlayer not available.")
        return
    end
    
    -- Give any potential exploit scripts a moment to finish initial setup
    task.wait(0.5) 

    scan_for_gui_menus()
    print("-----------------------------------------------------")
    scan_global_environment()
    print("-----------------------------------------------------")
    
    print("Detection sweep complete. If the GUI did not appear, and no artifacts were detected, the script is likely failing to execute.")
end

run_detector()        -- Check for hidden elements or suspicious names
        local is_hidden = not element.Visible
        local is_named = is_suspicious_name(element.Name) or is_suspicious_name(element.ClassName)

        if is_hidden or is_named then
            local status = {}
            if is_hidden then table.insert(status, "Hidden") end
            if is_named then table.insert(status, "Suspicious Name/Class") end
            
            table.insert(suspicious_elements, {
                Name = element.Name,
                Class = element.ClassName,
                Visible = element.Visible,
                Status = table.concat(status, " | ")
            })
        end
    end

    if #suspicious_elements > 0 then
        print(string.format("[GUI DETECTED] Found %d potentially active exploit GUIs/elements:", #suspicious_elements))
        for _, info in ipairs(suspicious_elements) do
            print(string.format("  - Name: %s, Class: %s, Status: %s, Visible: %s",
                info.Name, info.Class, info.Status, tostring(info.Visible)))
            
            -- Optionally, attempt to make hidden GUIs visible
            if not info.Visible and info.Class:match("ScreenGui") or info.Class:match("Frame") then
                 -- This attempts to force a hidden GUI visible to reveal it.
                 element.Visible = true 
                 print("    --> Attempted to force visible!")
            end
        end
    else
        print("[GUI DETECTED] No obvious injected GUI elements found in CoreGui.")
    end
    print("-----------------------------------------------------")
end

-- ====================================================================
-- 2. GLOBAL COMMAND & LOADER SCANNER
-- ====================================================================

local function scan_for_global_commands()
    print("--- 2. SCANNING GLOBAL ENVIRONMENT (_G) FOR COMMANDS ---")
    local global_hits = {}

    -- Common names for exploit-related global variables/functions
    local suspicious_globals = {
        "addcmd",           -- e.g., Infinite Yield's command registration
        "rconsoleprint",    -- Remote console logging
        "syn_send",         -- Common exploit function
        "notify",           -- Common notification function
        "message",          -- Common message function
        "Fire",             -- Generic, but often used for remote events
        "CMD_LIST",         -- Command list table
        "COMMANDS",         -- Command table
        "IY_LOADED",        -- Infinite Yield loader flag (or similar exploit name)
        "ESPLIST",          -- ESP list table
    }

    local environment_to_scan = getgenv and getgenv() or _G

    for _, name in ipairs(suspicious_globals) do
        if environment_to_scan[name] ~= nil then
            table.insert(global_hits, {
                Name = name,
                Type = type(environment_to_scan[name])
            })
        end
    end

    -- Also check for command tables
    if environment_to_scan.CMD_LIST and type(environment_to_scan.CMD_LIST) == "table" then
        print(string.format("[CMD DETECTED] Found 'CMD_LIST' table with %d entries.", #environment_to_scan.CMD_LIST))
    end
    if environment_to_scan.COMMANDS and type(environment_to_scan.COMMANDS) == "table" then
        print(string.format("[CMD DETECTED] Found 'COMMANDS' table with %d entries.", #environment_to_scan.COMMANDS))
    end


    if #global_hits > 0 then
        print(string.format("[GLOBAL DETECTED] Found %d suspicious global indicators:", #global_hits))
        for _, info in ipairs(global_hits) do
            print(string.format("  - Global: %s (Type: %s)", info.Name, info.Type))
        end
    else
        print("[GLOBAL DETECTED] No common exploit global variables or functions found.")
    end
    print("-----------------------------------------------------")
end

-- ====================================================================
-- MAIN EXECUTION
-- ====================================================================

local function run_detector()
    if not CurrentPlayer then
        print("Detector failed: LocalPlayer not available.")
        return
    end

    scan_for_gui_menus()
    scan_for_global_commands()

    print("Detection sweep complete.")
end

-- Wait a moment for any startup scripts to finish loading their GUIs
task.wait(1)
run_detector()            while IsActive do
                local HumanoidRootPart = getRootPart()
                
                if not HumanoidRootPart or #TELEPORT_DESTINATIONS == 0 then
                    IsActive = false
                    UpdateButtonText()
                    print("ERROR: No destinations or character not found. Stopping spam.")
                    break 
                end
                
                -- Set the character's CFrame to the current destination
                pcall(function() HumanoidRootPart.CFrame = CFrame.new(TELEPORT_DESTINATIONS[i]) end)
                
                i = i + 1
                if i > #TELEPORT_DESTINATIONS then i = 1 end
                
                task.wait(SPAM_INTERVAL)
            end
            print("Spam OFF.")
        end)
    end
end

-- 6. Destination Management Functions (NEW)
local function AddDestination()
    local HumanoidRootPart = getRootPart()
    
    if HumanoidRootPart then
        local currentPos = HumanoidRootPart.Position
        local newPos = Vector3.new(
            math.floor(currentPos.X + 0.5), 
            math.floor(currentPos.Y + 0.5), 
            math.floor(currentPos.Z + 0.5)
        )
        table.insert(TELEPORT_DESTINATIONS, newPos)
        
        print("✅ Added Destination #" .. #TELEPORT_DESTINATIONS .. ": " .. tostring(newPos))
        CoordStatusLabel.Text = #TELEPORT_DESTINATIONS .. " Destinations Saved"
        
        if IsActive then StartTeleportSpam() end
    else
        warn("Cannot add position: Character not found.")
    end
end

local function ClearDestinations()
    TELEPORT_DESTINATIONS = {} 
    IsActive = false
    if LoopThread then task.cancel(LoopThread); LoopThread = nil end
    CoordStatusLabel.Text = "0 Destinations Saved"
    UpdateButtonText()
    print("🗑️ Cleared all teleport destinations.")
end

-- 7. Toggle and GUI Update Functions
local function UpdateButtonText()
    if ToggleButton then
        ToggleButton.BackgroundColor3 = IsActive and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
        ToggleButton.Text = IsActive and "Spam Teleporter: ON" or "Spam Teleporter: OFF"
    end
end

local function ToggleSpam()
    local newInterval = tonumber(DelayBox.Text)
    SPAM_INTERVAL = (newInterval and newInterval >= 0.001) and newInterval or SPAM_INTERVAL
    DelayBox.Text = tostring(SPAM_INTERVAL)

    IsActive = not IsActive
    
    if IsActive then
        StartTeleportSpam()
    else
        if LoopThread then task.cancel(LoopThread); LoopThread = nil end
    end
    
    UpdateButtonText()
end

local function ToggleVisibility()
    IsVisible = not IsVisible
    
    if MainFrame then MainFrame.Visible = IsVisible end
    
    if VisibilityToggle then
        VisibilityToggle.Text = IsVisible and "HIDE" or "SHOW"
        VisibilityToggle.BackgroundColor3 = IsVisible and Color3.new(0.3, 0.3, 0.3) or Color3.new(0.6, 0.6, 0.6)
    end
end

-- 8. GUI Setup
local function Cleanup(name)
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui.Name == name then gui:Destroy() end
    end
end
Cleanup("SpamTeleporter_GUI")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpamTeleporter_GUI"
ScreenGui.Parent = PlayerGui

-- Visibility Toggle Button (Top-Right)
VisibilityToggle = Instance.new("TextButton")
VisibilityToggle.Text = "HIDE"
VisibilityToggle.Font = Enum.Font.SourceSansBold
VisibilityToggle.TextSize = 14
VisibilityToggle.Size = UDim2.new(0, 50, 0, 25)
VisibilityToggle.Position = UDim2.new(1, -55, 0.01, 0)
VisibilityToggle.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
VisibilityToggle.TextColor3 = Color3.new(1, 1, 1)
VisibilityToggle.Parent = ScreenGui
VisibilityToggle.MouseButton1Click:Connect(ToggleVisibility)

MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 195) -- Adjusted size to fit the new button
MainFrame.Position = UDim2.new(0.5, -125, 0.1, 0) -- CENTERED (As per your working version)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.Parent = ScreenGui
MainFrame.Visible = IsVisible

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "Multi-Point Spam TP" -- Updated Text
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.Size = UDim2.new(1, 0, 0, 25)
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
TitleLabel.Parent = MainFrame

-- Delay Label
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Text = "Spam Interval (Sec):"
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextSize = 14
DelayLabel.Size = UDim2.new(0.5, 0, 0, 30)
DelayLabel.Position = UDim2.new(0, 0, 0, 30)
DelayLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
DelayLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = MainFrame

-- Delay Input Box
DelayBox = Instance.new("TextBox")
DelayBox.Text = tostring(SPAM_INTERVAL)
DelayBox.Font = Enum.Font.SourceSans
DelayBox.TextSize = 14
DelayBox.Size = UDim2.new(0.5, 0, 0, 20)
DelayBox.Position = UDim2.new(0.5, 0, 0, 30)
DelayBox.PlaceholderText = "Enter interval (e.g., 0.01)"
DelayBox.TextColor3 = Color3.new(1, 1, 1)
DelayBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
DelayBox.Parent = MainFrame

-- Toggle Button
ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Spam_Toggle"
ToggleButton.Size = UDim2.new(1, 0, 0, 35)
ToggleButton.Position = UDim2.new(0, 0, 0, 55)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Parent = MainFrame
ToggleButton.MouseButton1Click:Connect(ToggleSpam)

-- ADD POSITION Button (Replaced Auto-Set)
local AddButton = Instance.new("TextButton")
AddButton.Text = "Add Current Position (I'm here)"
AddButton.Size = UDim2.new(1, 0, 0, 35)
AddButton.Position = UDim2.new(0, 0, 0, 90)
AddButton.BackgroundColor3 = Color3.new(0.1, 0.5, 0.9)
AddButton.TextColor3 = Color3.new(1, 1, 1)
AddButton.Font = Enum.Font.SourceSans
AddButton.TextSize = 14
AddButton.Parent = MainFrame
AddButton.MouseButton1Click:Connect(AddDestination)

-- CLEAR ALL Destinations Button (NEW)
local ClearButton = Instance.new("TextButton")
ClearButton.Text = "Clear All Destinations"
ClearButton.Size = UDim2.new(1, 0, 0, 30)
ClearButton.Position = UDim2.new(0, 0, 0, 125)
ClearButton.BackgroundColor3 = Color3.new(0.7, 0.3, 0.1)
ClearButton.TextColor3 = Color3.new(1, 1, 1)
ClearButton.Font = Enum.Font.SourceSans
ClearButton.TextSize = 14
ClearButton.Parent = MainFrame
ClearButton.MouseButton1Click:Connect(ClearDestinations)

-- Coordinate Status Label (Updated text)
CoordStatusLabel = Instance.new("TextLabel")
CoordStatusLabel.Text = "0 Destinations Saved"
CoordStatusLabel.Font = Enum.Font.SourceSans
CoordStatusLabel.TextSize = 12
CoordStatusLabel.Size = UDim2.new(1, 0, 0, 20)
CoordStatusLabel.Position = UDim2.new(0, 0, 0, 155)
CoordStatusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
CoordStatusLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
CoordStatusLabel.Parent = MainFrame

-- Initialize the button text
UpdateButtonText() 

print("Multi-Destination Spam Teleporter (Final Stable Version) Loaded!")
