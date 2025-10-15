-- =========================================================
--             HARDENED MULTI-DESTINATION SPAM TELEPORTER
-- =========================================================

-- 1. Setup Global References
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui") -- Ensure this service is accessible!
local RunService = game:GetService("RunService")

-- 2. Configuration Variables
local TELEPORT_DESTINATIONS = {}
local SPAM_INTERVAL = 0.05

-- 3. State and Thread Management
local IsActive = false
local LoopThread = nil
local IsMinimized = false

-- Helper function to reliably get the character's root part
local function getRootPart()
    local character = LocalPlayer.Character
    if not character then
        character = LocalPlayer.CharacterAdded:Wait()
    end
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- 4. Main Teleport Logic Function (The Cycling Spam Loop)
local function StartTeleportSpam()
    if LoopThread then task.cancel(LoopThread) end

    if IsActive then
        LoopThread = task.spawn(function()
            print("Spam Teleporter ON: Waiting for HumanoidRootPart...")
            local currentIndex = 1
            while IsActive do
                local HumanoidRootPart = getRootPart()
                
                if not HumanoidRootPart then 
                    task.wait(0.5)
                    goto continue_loop
                end
                if #TELEPORT_DESTINATIONS == 0 then
                    warn("No destinations saved. Stopping spam.")
                    IsActive = false
                    UpdateButtonText()
                    break
                end
                
                -- Use pcall to protect the teleport action from crashing the thread
                local success, err = pcall(function()
                    HumanoidRootPart.CFrame = CFrame.new(TELEPORT_DESTINATIONS[currentIndex])
                end)

                if not success then
                    warn("Teleport failed: " .. tostring(err))
                end

                currentIndex = currentIndex + 1
                if currentIndex > #TELEPORT_DESTINATIONS then
                    currentIndex = 1
                end
                
                task.wait(SPAM_INTERVAL)
                ::continue_loop::
            end
            print("Spam Teleporter loop stopped.")
        end)
    end
end

-- 5. Add Destination Function (omitted for brevity, same as previous working version)
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
