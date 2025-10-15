-- Global variables to control the spam loop (if not already added)
local RunService = game:GetService("RunService")
local isSpammingTP = false
local spamTPConnection = nil

--- The main logic for the rapid teleport
local function ToggleRapidTP()
    local char = Players.LocalPlayer.Character
    local root = char and char:FindFirstChild('HumanoidRootPart')

    if not root then
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
        notify('SpamTP', 'Rapid Teleport Stopped.', 'Stop')
    else
        -- Start the teleport
        isSpammingTP = true
        local originalCFrame = root.CFrame

        spamTPConnection = RunService.Heartbeat:Connect(function()
            if isSpammingTP and root.Parent then
                root.CFrame = originalCFrame
            else
                if spamTPConnection then
                    spamTPConnection:Disconnect()
                    spamTPConnection = nil
                end
                isSpammingTP = false
            end
        end)
        notify('SpamTP', 'Rapid Teleport Started.', 'Play')
    end
    -- Update the button text to reflect the state
    if SpamTPButton then
        SpamTPButton.Text = isSpammingTP and 'STOP TP SPAM' or 'TP SPAM'
    end
end

-- 1. Register the command so it can be used via the command bar (/spamtp)
addcmd('spamtp', {'rapidtp'}, function(args, speaker)
    ToggleRapidTP()
end)

-- 2. Register the command to stop it via the command bar (/unspamtp)
addcmd('unspamtp', {'stopspamtp', 'nospamtp'}, function(args, speaker)
    if isSpammingTP then
        ToggleRapidTP()
    else
        notify('SpamTP', 'Rapid teleport is not active.')
    end
end)

-- 3. Create the GUI button (This requires the script's 'addbutton' function)
local SpamTPButton
SpamTPButton = addbutton('TP SPAM', 'Spams your position very fast (Toggle)', function()
    ToggleRapidTP()
end)

-- Ensure the button text updates if the command is run via the bar
if SpamTPButton then
    task.spawn(function()
        while wait(0.1) do
            SpamTPButton.Text = isSpammingTP and 'STOP TP SPAM' or 'TP SPAM'
        end
    end)
end
