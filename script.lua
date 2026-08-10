-- ====================================================================
-- The Strongest Battlegrounds (TSB) Pro Auto-Combat & Key-Weaver v5.0
-- File: script.lua
-- Repository: https://github.com/var017986-ship-it/tsb-skript
-- Features: 1. Ultra Fast Ground Rush Engine (WalkSpeed 45 + Direct CFrame Pivot)
--           2. TSB Skill Key Activator (Keys 1, 2, 3, 4 via Keypress / Remote Emulation)
--           3. High-Speed M1 Autoclicker (0.01s Execution)
--           4. Uppercut & Backdash Snap Mechanics
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
_G.TSB_SprintSpeed = 45

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

pcall(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

-----------------------------------------------------------------------
-- Helper: Multi-Layer Skill Activator (1, 2, 3, 4)
-----------------------------------------------------------------------
local function pressSkillKey(skillNum)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end

        -- Layer 1: Fire keypress / keyrelease if environment supports
        if keypress then
            local keys = {0x31, 0x32, 0x33, 0x34} -- Keycodes for 1, 2, 3, 4
            if keys[skillNum] then
                keypress(keys[skillNum])
                task.wait(0.03)
                keyrelease(keys[skillNum])
            end
        end

        -- Layer 2: Equip & Activate Tool by Index / Hotbar slot
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if backpack and hum then
            local tools = backpack:GetChildren()
            if tools[skillNum] and tools[skillNum]:IsA("Tool") then
                hum:EquipTool(tools[skillNum])
                task.wait(0.02)
                tools[skillNum]:Activate()
            end
        end

        -- Layer 3: Direct Character Tool Activation
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                item:Activate()
            end
        end
    end)
end

local function fastM1Attack()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 0))
        task.wait(0.01)
        VirtualUser:Button1Up(Vector2.new(0, 0))
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
    local shortestDist = 600

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
-- Subsystem: Ultra Fast Movement Engine (WalkSpeed 45 + Smooth Snap)
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

            -- Fast Auto-Aim Lock
            if Workspace.CurrentCamera then
                Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, targetPos + Vector3.new(0, 1.5, 0))
            end

            -- High-Speed Ground Pursuit
            if dist > 3.0 then
                hum:MoveTo(targetPos)
                local dir = (targetPos - myPos).Unit
                root.CFrame = CFrame.new(myPos + Vector3.new(dir.X * 0.9, 0, dir.Z * 0.9), Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
            else
                root.CFrame = CFrame.new(myPos, Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
            end
        end
    end)
end)

-----------------------------------------------------------------------
-- Subsystem: High-Frequency Combat & Skill Weaver Loop
-----------------------------------------------------------------------
task.spawn(function()
    local skillCycle = {1, 2, 3, 4}
    local skillIdx = 1
    local stepCounter = 0

    while task.wait(0.04) do
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
                        stepCounter = stepCounter + 1

                        -- 1. Rapid M1 Strike
                        fastM1Attack()

                        -- 2. Trigger Skills 1, 2, 3, 4
                        pressSkillKey(skillCycle[skillIdx])
                        skillIdx = (skillIdx % #skillCycle) + 1

                        -- 3. Backdash Behind Target (Every 6 ticks)
                        if stepCounter % 6 == 0 then
                            local backPos = targetRoot.CFrame * CFrame.new(0, 0, 3.2)
                            root.CFrame = CFrame.new(backPos.Position, targetRoot.Position)
                        end

                        -- 4. Uppercut Jump Tech (Every 8 ticks)
                        if stepCounter % 8 == 0 then
                            hum.Jump = true
                            fastM1Attack()
                        end
                    end
                end
            end)
        end
    end
end)

-- Dashboard UI
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
TitleLabel.Text = "🥊 TSB ULTRA FAST COMBAT v5.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 15
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

local AutoCombatBtn = Instance.new("TextButton")
AutoCombatBtn.Size = UDim2.new(1, -24, 0, 44)
AutoCombatBtn.Position = UDim2.new(0, 12, 0, 54)
AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
AutoCombatBtn.Text = "⚔️ ULTRA FAST AUTO COMBAT & SKILLS: ВКЛЮЧЕН"
AutoCombatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoCombatBtn.Font = Enum.Font.SourceSansBold
AutoCombatBtn.TextSize = 12
AutoCombatBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = AutoCombatBtn

AutoCombatBtn.MouseButton1Click:Connect(function()
    _G.TSB_AutoCombat = not _G.TSB_AutoCombat
    if _G.TSB_AutoCombat then
        AutoCombatBtn.Text = "⚔️ ULTRA FAST AUTO COMBAT & SKILLS: ВКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
    else
        AutoCombatBtn.Text = "⚔️ ULTRA FAST AUTO COMBAT & SKILLS: ВЫКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    end
end)

notify("TSB Pro Combat", "⚡ СКОРОСТНОЙ БОЙ И СКИЛЛЫ (1,2,3,4) ЗАПУЩЕНЫ!")
print("[+] TSB Ultra Fast Combat v5.0 Loaded.")
