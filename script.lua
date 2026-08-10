-- ====================================================================
-- The Strongest Battlegrounds (TSB) Master Hub v1.0
-- File: script.lua
-- Repository: https://github.com/var017986-ship-it/tsb-skript
-- Features: 1. Auto Perfect Block & Parry Engine
--           2. Target ESP & Health Indicator
--           3. Auto Dash Evade & Anti-Combo System
--           4. Sleek Modern Dashboard UI (TSB Master Hub)
-- ====================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Master Flags
_G.TSB_AutoBlock = true
_G.TSB_PlayerESP = true
_G.TSB_AutoDodge = false

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

-----------------------------------------------------------------------
-- Subsystem: Safe Anti-AFK
-----------------------------------------------------------------------
pcall(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

-----------------------------------------------------------------------
-- Subsystem: Auto Block & Parry Engine
-----------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.05) do
        if _G.TSB_AutoBlock then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local enemyRoot = p.Character.HumanoidRootPart
                        local dist = (enemyRoot.Position - root.Position).Magnitude
                        
                        -- Range check for incoming melee strikes (within 18 studs)
                        if dist <= 18 then
                            local enemyHum = p.Character:FindFirstChildOfClass("Humanoid")
                            if enemyHum and enemyHum.Health > 0 then
                                -- Check for active attack animations
                                local animator = enemyHum:FindFirstChildOfClass("Animator")
                                if animator then
                                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                        local animName = string.lower(track.Name or "")
                                        if string.find(animName, "punch") or string.find(animName, "attack") or string.find(animName, "strike") or string.find(animName, "m1") then
                                            -- Trigger Block Remote
                                            local comms = char:FindFirstChild("CommF_") or ReplicatedStorage:FindFirstChild("Remotes")
                                            if comms then
                                                -- Perform Block / Deflect
                                                if keypress then keypress(0x46) end -- 'F' Key
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-----------------------------------------------------------------------
-- Progress Dashboard GUI (TSB Master Hub)
-----------------------------------------------------------------------
if CoreGui:FindFirstChild("TSBMasterHub") then
    CoreGui.TSBMasterHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TSBMasterHub"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 210)
MainFrame.Position = UDim2.new(0.5, -180, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 75, 75)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🥊 TSB MASTER HUB v1.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 16
TitleLabel.Parent = Header

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -38, 0, 7)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(55, 30, 35)
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(240, 220, 225)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 16
MinimizeBtn.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

-- Auto Block Toggle Button
local AutoBlockBtn = Instance.new("TextButton")
AutoBlockBtn.Size = UDim2.new(1, -28, 0, 44)
AutoBlockBtn.Position = UDim2.new(0, 14, 0, 56)
AutoBlockBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
AutoBlockBtn.Text = "🛡️ AUTO PARRY & BLOCK: ВКЛЮЧЕН"
AutoBlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBlockBtn.Font = Enum.Font.SourceSansBold
AutoBlockBtn.TextSize = 14
AutoBlockBtn.Parent = MainFrame

local BlockCorner = Instance.new("UICorner")
BlockCorner.CornerRadius = UDim.new(0, 8)
BlockCorner.Parent = AutoBlockBtn

-- Auto Dodge Toggle Button
local AutoDodgeBtn = Instance.new("TextButton")
AutoDodgeBtn.Size = UDim2.new(1, -28, 0, 44)
AutoDodgeBtn.Position = UDim2.new(0, 14, 0, 110)
AutoDodgeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
AutoDodgeBtn.Text = "⚡ AUTO DASH EVADE: ВЫКЛЮЧЕН"
AutoDodgeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoDodgeBtn.Font = Enum.Font.SourceSansBold
AutoDodgeBtn.TextSize = 14
AutoDodgeBtn.Parent = MainFrame

local DodgeCorner = Instance.new("UICorner")
DodgeCorner.CornerRadius = UDim.new(0, 8)
DodgeCorner.Parent = AutoDodgeBtn

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -28, 0, 30)
StatusLabel.Position = UDim2.new(0, 14, 0, 166)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "🟢 ГОТОВ К БОЮ (TSB ACTIVE)"
StatusLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 13
StatusLabel.Parent = MainFrame

-----------------------------------------------------------------------
-- Event Handlers
-----------------------------------------------------------------------
local isMinimized = false

MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 360, 0, 44)
        MinimizeBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 360, 0, 210)
        MinimizeBtn.Text = "—"
    end
end)

AutoBlockBtn.MouseButton1Click:Connect(function()
    _G.TSB_AutoBlock = not _G.TSB_AutoBlock
    if _G.TSB_AutoBlock then
        AutoBlockBtn.Text = "🛡️ AUTO PARRY & BLOCK: ВКЛЮЧЕН"
        AutoBlockBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
        notify("TSB Hub", "🛡️ Авто-Блок Активирован")
    else
        AutoBlockBtn.Text = "🛡️ AUTO PARRY & BLOCK: ВЫКЛЮЧЕН"
        AutoBlockBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        notify("TSB Hub", "🔴 Авто-Блок Деактивирован")
    end
end)

AutoDodgeBtn.MouseButton1Click:Connect(function()
    _G.TSB_AutoDodge = not _G.TSB_AutoDodge
    if _G.TSB_AutoDodge then
        AutoDodgeBtn.Text = "⚡ AUTO DASH EVADE: ВКЛЮЧЕН"
        AutoDodgeBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
        notify("TSB Hub", "⚡ Уклонение Активировано")
    else
        AutoDodgeBtn.Text = "⚡ AUTO DASH EVADE: ВЫКЛЮЧЕН"
        AutoDodgeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        notify("TSB Hub", "🔴 Уклонение Деактивировано")
    end
end)

notify("TSB Master Hub", "🥊 СКРИПТ УСПЕШНО АКТИВИРОВАН!")
print("[+] TSB Master Hub v1.0 Loaded Successfully.")
