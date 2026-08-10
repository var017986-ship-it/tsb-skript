-- ====================================================================
-- The Strongest Battlegrounds (TSB) Pro AI Combat Harvester v2.0
-- File: script.lua
-- Repository: https://github.com/var017986-ship-it/tsb-skript
-- Features: 1. Pro Ground Footstep Chase Engine (No Fly, Real Human Walk/Run)
--           2. M1 Auto-Combo Chain & Skill Weaver (Keys 1, 2, 3, 4)
--           3. Instant Counter-Parry & Anti-Stun Block (F Key)
--           4. Tactical Side Dash Evade & Mixups (Q Key + Directional Strafe)
--           5. Pro Target Lock & Camera Tracking
--           6. Dashboard UI (TSB Master Hub v2.0)
-- ====================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- Master Flags
_G.TSB_AutoCombat = true
_G.TSB_AutoBlock = true
_G.TSB_AutoSkills = true
_G.TSB_TargetLock = true

local currentTarget = nil

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
-- Helper: Virtual Key Pressing for Pro Movement & Combos
-----------------------------------------------------------------------
local function simulateKeyPress(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.04)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

local function simulateClick()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

-----------------------------------------------------------------------
-- Subsystem: Pro Target Finder (Finds Closest Low-HP Enemy)
-----------------------------------------------------------------------
local function getBestTarget()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return nil end

    local closestEnemy = nil
    local shortestDist = 500

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local enemyHum = p.Character:FindFirstChildOfClass("Humanoid")
            local enemyRoot = p.Character.HumanoidRootPart
            if enemyHum and enemyHum.Health > 0 then
                local dist = (enemyRoot.Position - root.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestEnemy = p.Character
                end
            end
        end
    end

    return closestEnemy
end

-----------------------------------------------------------------------
-- Subsystem: Pro Ground Movement & Camera Tracking
-----------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not _G.TSB_AutoCombat then return end

    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return end

        if not currentTarget or not currentTarget:FindFirstChild("HumanoidRootPart") or currentTarget:FindFirstChildOfClass("Humanoid").Health <= 0 then
            currentTarget = getBestTarget()
        end

        if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
            local targetRoot = currentTarget.HumanoidRootPart
            local targetPos = targetRoot.Position
            local myPos = root.Position
            local dist = (targetPos - myPos).Magnitude

            -- Pro Camera Tracking
            if _G.TSB_TargetLock and Workspace.CurrentCamera then
                Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, targetPos + Vector3.new(0, 1.5, 0))
            end

            -- Natural Ground Movement (Humanoid:MoveTo for authentic walking/running)
            if dist > 4.5 then
                hum:MoveTo(targetPos)
            else
                -- Stop and face target closely
                root.CFrame = CFrame.new(myPos, Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
            end
        end
    end)
end)

-----------------------------------------------------------------------
-- Subsystem: Pro Combat Engine (M1 Combos, Skills 1-4, Side Dashes)
-----------------------------------------------------------------------
task.spawn(function()
    local skillCycle = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}
    local currentSkillIndex = 1

    while task.wait(0.1) do
        if _G.TSB_AutoCombat and currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local targetRoot = currentTarget.HumanoidRootPart
                local targetHum = currentTarget:FindFirstChildOfClass("Humanoid")

                if root and targetRoot and hum and hum.Health > 0 and targetHum and targetHum.Health > 0 then
                    local dist = (targetRoot.Position - root.Position).Magnitude

                    if dist <= 12 then
                        -- Check Enemy Animation for Reactive Counter / Parry
                        local isEnemyAttacking = false
                        local animator = targetHum:FindFirstChildOfClass("Animator")
                        if animator then
                            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                local animName = string.lower(track.Name or "")
                                if string.find(animName, "punch") or string.find(animName, "attack") or string.find(animName, "strike") or string.find(animName, "m1") then
                                    isEnemyAttacking = true
                                    break
                                end
                            end
                        end

                        if isEnemyAttacking and _G.TSB_AutoBlock then
                            -- Counter Parry: Hold Block briefly
                            simulateKeyPress(Enum.KeyCode.F)
                            task.wait(0.15)
                        else
                            -- Perform M1 Combo Chain (4 Consecutive Attacks)
                            for i = 1, 4 do
                                simulateClick()
                                task.wait(0.22)
                            end

                            -- Execute Ability Mixup (Skills 1, 2, 3, 4)
                            if _G.TSB_AutoSkills then
                                local targetKey = skillCycle[currentSkillIndex]
                                simulateKeyPress(targetKey)
                                currentSkillIndex = (currentSkillIndex % #skillCycle) + 1
                                task.wait(0.3)
                            end

                            -- Tactical Side Dash (Q Key for Pro Evasion)
                            if math.random(1, 3) == 1 then
                                simulateKeyPress(Enum.KeyCode.Q)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-----------------------------------------------------------------------
-- Progress Dashboard GUI (TSB Master Hub v2.0)
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
MainFrame.Size = UDim2.new(0, 360, 0, 260)
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
TitleLabel.Text = "🥊 TSB PRO COMBAT HARVESTER v2.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 15
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

-- Auto Combat Toggle Button
local AutoCombatBtn = Instance.new("TextButton")
AutoCombatBtn.Size = UDim2.new(1, -28, 0, 44)
AutoCombatBtn.Position = UDim2.new(0, 14, 0, 56)
AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
AutoCombatBtn.Text = "⚔️ PRO AUTO COMBAT: ВКЛЮЧЕН"
AutoCombatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoCombatBtn.Font = Enum.Font.SourceSansBold
AutoCombatBtn.TextSize = 14
AutoCombatBtn.Parent = MainFrame

local CombatCorner = Instance.new("UICorner")
CombatCorner.CornerRadius = UDim.new(0, 8)
CombatCorner.Parent = AutoCombatBtn

-- Auto Parry Toggle Button
local AutoBlockBtn = Instance.new("TextButton")
AutoBlockBtn.Size = UDim2.new(1, -28, 0, 44)
AutoBlockBtn.Position = UDim2.new(0, 14, 0, 110)
AutoBlockBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
AutoBlockBtn.Text = "🛡️ REACTIVE PARRY & BLOCK: ВКЛЮЧЕН"
AutoBlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBlockBtn.Font = Enum.Font.SourceSansBold
AutoBlockBtn.TextSize = 14
AutoBlockBtn.Parent = MainFrame

local BlockCorner = Instance.new("UICorner")
BlockCorner.CornerRadius = UDim.new(0, 8)
BlockCorner.Parent = AutoBlockBtn

-- Auto Skills Toggle Button
local AutoSkillsBtn = Instance.new("TextButton")
AutoSkillsBtn.Size = UDim2.new(1, -28, 0, 44)
AutoSkillsBtn.Position = UDim2.new(0, 14, 0, 164)
AutoSkillsBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
AutoSkillsBtn.Text = "💥 SKILL WEAVER (1,2,3,4): ВКЛЮЧЕН"
AutoSkillsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoSkillsBtn.Font = Enum.Font.SourceSansBold
AutoSkillsBtn.TextSize = 14
AutoSkillsBtn.Parent = MainFrame

local SkillCorner = Instance.new("UICorner")
SkillCorner.CornerRadius = UDim.new(0, 8)
SkillCorner.Parent = AutoSkillsBtn

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -28, 0, 30)
StatusLabel.Position = UDim2.new(0, 14, 0, 218)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "🟢 СТАБИЛЬНЫЙ ПОИСК И БОЙ ВЕДЕТСЯ"
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
        MainFrame.Size = UDim2.new(0, 360, 0, 260)
        MinimizeBtn.Text = "—"
    end
end)

AutoCombatBtn.MouseButton1Click:Connect(function()
    _G.TSB_AutoCombat = not _G.TSB_AutoCombat
    if _G.TSB_AutoCombat then
        AutoCombatBtn.Text = "⚔️ PRO AUTO COMBAT: ВКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
        notify("TSB Hub", "⚔️ Авто-Бой Активирован")
    else
        AutoCombatBtn.Text = "⚔️ PRO AUTO COMBAT: ВЫКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        notify("TSB Hub", "🔴 Авто-Бой Деактивирован")
    end
end)

AutoBlockBtn.MouseButton1Click:Connect(function()
    _G.TSB_AutoBlock = not _G.TSB_AutoBlock
    if _G.TSB_AutoBlock then
        AutoBlockBtn.Text = "🛡️ REACTIVE PARRY & BLOCK: ВКЛЮЧЕН"
        AutoBlockBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
        notify("TSB Hub", "🛡️ Парирование Активировано")
    else
        AutoBlockBtn.Text = "🛡️ REACTIVE PARRY & BLOCK: ВЫКЛЮЧЕН"
        AutoBlockBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        notify("TSB Hub", "🔴 Парирование Деактивировано")
    end
end)

AutoSkillsBtn.MouseButton1Click:Connect(function()
    _G.TSB_AutoSkills = not _G.TSB_AutoSkills
    if _G.TSB_AutoSkills then
        AutoSkillsBtn.Text = "💥 SKILL WEAVER (1,2,3,4): ВКЛЮЧЕН"
        AutoSkillsBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
        notify("TSB Hub", "💥 Использование Скиллов Включено")
    else
        AutoSkillsBtn.Text = "💥 SKILL WEAVER (1,2,3,4): ВЫКЛЮЧЕН"
        AutoSkillsBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        notify("TSB Hub", "🔴 Использование Скиллов Выключено")
    end
end)

notify("TSB Pro Combat", "⚔️ PRO PVP ENGINE УСПЕШНО ЗАПУЩЕН!")
print("[+] TSB Pro Combat Harvester v2.0 Loaded Successfully.")
