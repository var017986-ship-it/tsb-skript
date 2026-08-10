-- ====================================================================
-- The Strongest Battlegrounds (TSB) Tech Master Engine v4.0
-- File: script.lua
-- Repository: https://github.com/var017986-ship-it/tsb-skript
-- Features: 1. Uppercut Aerial Tech (M1 + Space Jump Uppercut Combo)
--           2. Backdash Behind-Spin (Quick Q-Dash / CFrame Snap Behind Enemy)
--           3. Instant Auto-Aim Lock & Camera Tracking
--           4. Skill Weaver (Skills 1, 2, 3, 4)
-- ====================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

_G.TSB_AutoCombat = true
_G.TSB_SprintSpeed = 30
_G.TSB_TechEnabled = true

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
-- Helper: Combat Triggers & Tech Techniques
-----------------------------------------------------------------------
local function attackM1()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 0))
        task.wait(0.02)
        VirtualUser:Button1Up(Vector2.new(0, 0))
    end)
end

-- Tech 1: Uppercut Tech (Jump + M1 Strike)
local function executeUppercutTech()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and root then
            -- Jump into air for Uppercut
            hum.Jump = true
            task.wait(0.05)
            attackM1()
            task.wait(0.05)
            attackM1()
        end
    end)
end

-- Tech 2: Backdash Behind Spin (Snap behind enemy's back)
local function executeBackdashBehindTech(targetRoot)
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and targetRoot then
            -- Calculate Position Exactly Behind Target's Back (3.5 studs behind)
            local backPos = targetRoot.CFrame * CFrame.new(0, 0, 3.5)
            -- Instantly face target's back
            root.CFrame = CFrame.new(backPos.Position, targetRoot.Position)
        end
    end)
end

local function executeSkill(skillNum)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        local toolName = "Skill" .. skillNum
        local tool = char:FindFirstChild(toolName) or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild(toolName))
        
        if tool then
            if tool.Parent ~= char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:EquipTool(tool) end
            end
            tool:Activate()
        end

        local comms = char:FindFirstChild("CommF_") or ReplicatedStorage:FindFirstChild("Remotes")
        if comms then
            pcall(function() comms:InvokeServer("Skill", skillNum) end)
        end
    end)
end

-----------------------------------------------------------------------
-- Subsystem: Target Finder
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
-- Subsystem: Movement & Lock-On Aim Engine
-----------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not _G.TSB_AutoCombat then return end

    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return end

        hum.WalkSpeed = _G.TSB_SprintSpeed

        if not currentTarget or not currentTarget:FindFirstChild("HumanoidRootPart") or currentTarget:FindFirstChildOfClass("Humanoid").Health <= 0 then
            currentTarget = getBestTarget()
        end

        if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
            local targetRoot = currentTarget.HumanoidRootPart
            local targetPos = targetRoot.Position
            local myPos = root.Position
            local dist = (targetPos - myPos).Magnitude

            -- Precision Auto-Aim Camera Lock
            if Workspace.CurrentCamera then
                Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, targetPos + Vector3.new(0, 1.5, 0))
            end

            -- Chase Target
            if dist > 3.5 then
                hum:MoveTo(targetPos)
                local dir = (targetPos - myPos).Unit
                root.CFrame = CFrame.new(myPos + Vector3.new(dir.X * 0.45, 0, dir.Z * 0.45), Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
            end
        end
    end)
end)

-----------------------------------------------------------------------
-- Subsystem: Pro Tech Combat Loop (Uppercut + Backdash Combo Chain)
-----------------------------------------------------------------------
task.spawn(function()
    local skillCycle = {1, 2, 3, 4}
    local skillIndex = 1
    local comboStep = 0

    while task.wait(0.08) do
        if _G.TSB_AutoCombat and currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local targetRoot = currentTarget.HumanoidRootPart
                local targetHum = currentTarget:FindFirstChildOfClass("Humanoid")

                if root and targetRoot and hum and hum.Health > 0 and targetHum and targetHum.Health > 0 then
                    local dist = (targetRoot.Position - root.Position).Magnitude

                    if dist <= 11 then
                        comboStep = comboStep + 1

                        -- 1. Standard M1 Strike
                        attackM1()

                        -- 2. Every 3 M1s -> Execute Uppercut Tech
                        if comboStep % 3 == 0 then
                            executeUppercutTech()
                            task.wait(0.1)
                        end

                        -- 3. Execute Backdash Behind-Spin Tech
                        if comboStep % 5 == 0 then
                            executeBackdashBehindTech(targetRoot)
                            task.wait(0.1)
                        end

                        -- 4. Cast Skill 1-4
                        if comboStep % 4 == 0 then
                            executeSkill(skillCycle[skillIndex])
                            skillIndex = (skillIndex % #skillCycle) + 1
                        end
                    end
                end
            end)
        end
    end
end)

-----------------------------------------------------------------------
-- Progress Dashboard GUI (TSB Master Hub v4.0)
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
MainFrame.Size = UDim2.new(0, 340, 0, 160)
MainFrame.Position = UDim2.new(0.5, -170, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
TitleLabel.Text = "🥊 TSB TECH MASTER v4.0 (UPPERCUT/BACKDASH)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 13
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

local AutoCombatBtn = Instance.new("TextButton")
AutoCombatBtn.Size = UDim2.new(1, -24, 0, 44)
AutoCombatBtn.Position = UDim2.new(0, 12, 0, 54)
AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
AutoCombatBtn.Text = "⚡ UPPERCUT & BACKDASH TECH: ВКЛЮЧЕН"
AutoCombatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoCombatBtn.Font = Enum.Font.SourceSansBold
AutoCombatBtn.TextSize = 13
AutoCombatBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = AutoCombatBtn

AutoCombatBtn.MouseButton1Click:Connect(function()
    _G.TSB_AutoCombat = not _G.TSB_AutoCombat
    if _G.TSB_AutoCombat then
        AutoCombatBtn.Text = "⚡ UPPERCUT & BACKDASH TECH: ВКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
    else
        AutoCombatBtn.Text = "⚡ UPPERCUT & BACKDASH TECH: ВЫКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    end
end)

notify("TSB Tech Master", "🥊 UPPERCUT & BACKDASH TECH АКТИВИРОВАНЫ!")
print("[+] TSB Tech Master Engine v4.0 Loaded.")
