-- START OF TP SPAM MODULE (Add to the END of the Infinite Yield script)
local RunService = game:GetService("RunService")
local isSpammingTP = false
local spamTPConnection = nil
local originalCFrame = nil -- Stores the position to teleport to

-- Function to start/stop the rapid teleport
local function ToggleRapidTP(speaker)
    local char = speaker.Character
    -- Get the main part of the character
    local root = char and char:FindFirstChild('HumanoidRootPart')
    
    if not root then
        -- Uses the existing notification system
        notify('SpamTP', 'Character or HumanoidRootPart not found.')
        return
    end

    if isSpammingTP then
        -- Stop the teleport
        isSpammingTP = false
        if spamTPConnection then
            spamTPConnection:Disconnect()
            spamTPConnection = nil
        end
        originalCFrame = nil
        notify('SpamTP', 'Rapid teleport **STOPPED**.', 'Stop')
    else
        -- Start the teleport
        isSpammingTP = true
        -- Save the current position
        originalCFrame = root.CFrame
        
        -- Use Heartbeat for the fastest possible loop
        spamTPConnection = RunService.Heartbeat:Connect(function()
            if isSpammingTP and root.Parent then
                root.CFrame = originalCFrame
            else
                -- Auto-disconnect if character is gone or toggle flipped
                if spamTPConnection then
                    spamTPConnection:Disconnect()
                    spamTPConnection = nil
                end
                isSpammingTP = false
            end
        end)
        notify('SpamTP', 'Rapid teleport **STARTED**. Spawning to current spot.', 'Play')
    end
end

-- 1. Register the main toggle command, which creates the entry in the GUI list.
-- The command will appear as "spamtp" in the menu.
addcmd('spamtp', {'rapidtp', 'spamteleport', 'tpspam'}, function(args, speaker)
    ToggleRapidTP(speaker)
end, nil, 'Toggles rapid teleport to your current spot. Run it once to start, run it again to stop.')

-- 2. Register an explicit stop command (optional, but convenient for the command bar).
-- The GUI entry will be the 'spamtp' command itself.
addcmd('unspamtp', {'stopspamtp', 'nospamtp'}, function(args, speaker)
    if isSpammingTP then
        ToggleRapidTP(speaker) -- Calling the toggle function to turn it off
    else
        notify('SpamTP', 'Rapid teleport is not active.')
    end
end, nil, 'Stops the rapid teleport effect.')
-- END OF TP SPAM MODULE
