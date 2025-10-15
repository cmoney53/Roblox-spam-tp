local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local isSpammingTP = false
local spamTPConnection = nil
local player = Players.LocalPlayer

-- Create the button frame
local TPButton = Instance.new("TextButton")
TPButton.Name = "RapidTP_Toggle"
TPButton.Parent = CoreGui
TPButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
TPButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
TPButton.Size = UDim2.new(0, 150, 0, 30)
TPButton.Position = UDim2.new(0.01, 0, 0.25, 0) -- Adjust position as needed
TPButton.Font = Enum.Font.SourceSansBold
TPButton.FontSize = Enum.FontSize.Size18
TPButton.Text = "TP SPAM [OFF]"
TPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TPButton.ZIndex = 99

-- Logic function to start/stop the teleport
local function ToggleRapidTP()
    local char = player.Character
    local root = char and char:FindFirstChild('HumanoidRootPart')

    if not root then
        TPButton.Text = "TP SPAM [ERROR: No Root]"
        return
    end

    if isSpammingTP then
        -- STOP
        isSpammingTP = false
        if spamTPConnection then
            spamTPConnection:Disconnect()
            spamTPConnection = nil
        end
        TPButton.Text = "TP SPAM [OFF]"
    else
        -- START
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
        TPButton.Text = "TP SPAM [ON]"
    end
end

-- Connect the function to the button click
TPButton.MouseButton1Click:Connect(ToggleRapidTP)

-- Optional: Make the button dragable
local dragging
local dragStart

TPButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TPButton.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        TPButton:TweenPosition(UDim2.new(TPButton.Position.X.Scale, TPButton.Position.X.Offset + delta.X, TPButton.Position.Y.Scale, TPButton.Position.Y.Offset + delta.Y), "Out", "Quad", 0.05, true)
        dragStart = input.Position
    end
end)
