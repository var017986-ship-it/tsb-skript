-- ====================================================================
-- The Strongest Battlegrounds (TSB) God Speed & Counter Evasion Engine v6.0
-- File: script.lua
-- Repository: https://github.com/var017986-ship-it/tsb-skript
-- Features: 1. 3X Hyper Speed Sprint (WalkSpeed = 120 + 2.7x CFrame Ground Rush)
--           2. Aerial Launcher Tech (Lifts target into air for air combos)
--           3. Instant Backdash Snap (3.2 studs behind enemy's back)
--           4. Anti-Counter Retreat Evade (Flies back 25 studs if enemy counters)
--           5. Fast Multi-Layer Skill Weaver (Skills 1, 2, 3, 4)
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
_G.TSB_SprintSpeed = 120 -- 3x Faster Speed

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

        if keypress then
            local keys = {0x31, 0x32, 0x33, 0x34}
            if keys[skillNum] then
                keypress(keys[skillNum])
                task.wait(0.02)
                keyrelease(keys[skillNum])
            end
        end

        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if backpack and hum then
            local tools = backpack:GetChildren()
            if tools[skillNum] and tools[skillNum]:IsA("Tool") then
                hum:EquipTool(tools[skillNum])
                task.wait(0.01)
                tools[skillNum]:Activate()
            end
        end

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
    local shortestDist = 800

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
-- Subsystem: 3X Hyper Speed Movement & Target Tracking
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

            -- Precision Aim Lock
            if Workspace.CurrentCamera then
                Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, targetPos + Vector3.new(0, 1.5, 0))
            end

            -- 3X Hyper Ground Rush (2.7 studs per frame glide)
            if dist > 3.0 then
                hum:MoveTo(targetPos)
                local dir = (targetPos - myPos).Unit
                root.CFrame = CFrame.new(myPos + Vector3.new(dir.X * 2.7, 0, dir.Z * 2.7), Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
            else
                root.CFrame = CFrame.new(myPos, Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
            end
        end
    end)
end)

-----------------------------------------------------------------------
-- Subsystem: Aerial Launcher, Backdash & Anti-Counter Engine
-----------------------------------------------------------------------
task.spawn(function()
    local skillCycle = {1, 2, 3, 4}
    local skillIdx = 1
    local stepCounter = 0

    while task.wait(0.03) do
        if _G.TSB_AutoCombat and currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local targetRoot = currentTarget.HumanoidRootPart
                local targetHum = currentTarget:FindFirstChildOfClass("Humanoid")

                if root and targetRoot and hum and hum.Health > 0 and targetHum and targetHum.Health > 0 then
                    local dist = (targetRoot.Position - root.Position).Magnitude

                    -- 1. Anti-Counter Retreat Check: If enemy is countering/parrying -> FLY BACK 25 STUDS
                    local isCountering = false
                    local animator = targetHum:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            local animName = string.lower(track.Name or "")
                            if string.find(animName, "counter") or string.find(animName, "parry") or string.find(animName, "deflect") or string.find(animName, "block") then
                                isCountering = true
                                break
                            end
                        end
                    end

                    if isCountering then
                        -- Instant High-Speed Escape Dash (25 studs backwards + up)
                        root.CFrame = root.CFrame * CFrame.new(0, 6, 25)
                        task.wait(0.2)
                        return
                    end

                    if dist <= 12 then
                        stepCounter = stepCounter + 1

                        -- 2. Fast M1 Strike
                        fastM1Attack()

                        -- 3. Trigger Skills 1, 2, 3, 4
                        pressSkillKey(skillCycle[skillIdx])
                        skillIdx = (skillIdx % #skillCycle) + 1

                        -- 4. Instant Backdash Behind Snap (Every 4 ticks)
                        if stepCounter % 4 == 0 then
                            local backPos = targetRoot.CFrame * CFrame.new(0, 0, 3.2)
                            root.CFrame = CFrame.new(backPos.Position, targetRoot.Position)
                        end

                        -- 5. Aerial Launcher Tech: Lift enemy into the air for air combos (Every 6 ticks)
                        if stepCounter % 6 == 0 then
                            hum.Jump = true
                            pcall(function()
                                targetRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 14, 0)
                                root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                            end)
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
TitleLabel.Text = "⚡ TSB GOD SPEED & COUNTER EVADE v6.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 14
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

local AutoCombatBtn = Instance.new("TextButton")
AutoCombatBtn.Size = UDim2.new(1, -24, 0, 44)
AutoCombatBtn.Position = UDim2.new(0, 12, 0, 54)
AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
AutoCombatBtn.Text = "⚡ 3X SPEED & COUNTER EVADE: ВКЛЮЧЕН"
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
        AutoCombatBtn.Text = "⚡ 3X SPEED & COUNTER EVADE: ВКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
    else
        AutoCombatBtn.Text = "⚡ 3X SPEED & COUNTER EVADE: ВЫКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    end
end)

notify("TSB Pro Combat", "⚡ GOD SPEED v6.0 (3X SPEED + COUNTER RETREAT) АКТИВИРОВАН!")
print("[+] TSB God Speed & Counter Evasion Engine v6.0 Loaded.")
