--[[
    Exploit Menu and Command Detector Script (Lua)

    This script attempts to find common indicators of active exploit scripts and command menus:
    1. Hidden or suspicious GUI elements injected into CoreGui.
    2. Global functions/tables that resemble command registration systems (like 'addcmd' or '_G.Commands').
    3. Global variables commonly used by popular exploit scripts (like '_G.IY_LOADED').

    Disclaimer: This is for educational and analysis purposes. The effectiveness depends on
    how the target exploit script is coded.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local CurrentPlayer = Players.LocalPlayer

-- ====================================================================
-- 1. GUI SCANNER
-- ====================================================================

local function scan_for_gui_menus()
    print("--- 1. SCANNING COREGUI FOR INJECTED MENUS ---")
    local suspicious_elements = {}

    -- Common exploit menu parent names
    local function is_suspicious_name(name)
        local lower_name = name:lower()
        return lower_name:match("exploit") or
               lower_name:match("menu") or
               lower_name:match("gui") or
               lower_name:match("yield") or
               lower_name:match("script") or
               lower_name:match("console")
    end

    for _, element in ipairs(CoreGui:GetChildren()) do
        -- Check for hidden elements or suspicious names
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
run_detector()
