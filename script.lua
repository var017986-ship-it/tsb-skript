-- ====================================================================
-- The Strongest Battlegrounds (TSB) M1 Click Frame-Hold Fix v12.0
-- File: script.lua
-- Repository: https://github.com/var017986-ship-it/tsb-skript
-- Features: 1. Frame-Synchronized M1 Mouse Click (0.035s Hold Time for 60FPS Frame Registration)
--           2. InputBegan & InputEnded Dual-State Event Hook
--           3. Instant Burst Skill Rotation (1-2-3-4)
--           4. Auto-Awakening & 25-stud Anti-Counter Evade
-- ====================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

_G.TSB_AutoCombat = true
_G.TSB_SprintSpeed = 75
_G.TSB_AutoAwakening = true

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
-- Frame-Synchronized M1 Mouse Punch Trigger (0.035s Hold Time)
-----------------------------------------------------------------------
local function performM1Click()
    pcall(function()
        local camera = Workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
        local cx = math.floor(vp.X / 2)
        local cy = math.floor(vp.Y / 2)

        -- 1. VirtualInputManager Frame-Held Click
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.035)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end)

        -- 2. Executor Global mouse1press & mouse1release
        pcall(function()
            if mouse1press and mouse1release then
                mouse1press()
                task.wait(0.035)
                mouse1release()
            elseif mouse1click then
                mouse1click()
            end
        end)

        -- 3. VirtualUser Controller Click
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(cx, cy))
            task.wait(0.035)
            VirtualUser:Button1Up(Vector2.new(cx, cy))
        end)

        -- 4. Fire UserInputService Connections (InputBegan + InputEnded)
        if getconnections then
            local mockInputBegin = {
                UserInputType = Enum.UserInputType.MouseButton1,
                UserInputState = Enum.UserInputState.Begin,
                KeyCode = Enum.KeyCode.Unknown,
                Position = Vector3.new(cx, cy, 0)
            }
            local mockInputEnd = {
                UserInputType = Enum.UserInputType.MouseButton1,
                UserInputState = Enum.UserInputState.End,
                KeyCode = Enum.KeyCode.Unknown,
                Position = Vector3.new(cx, cy, 0)
            }
            for _, conn in ipairs(getconnections(UserInputService.InputBegan)) do
                pcall(function() conn:Fire(mockInputBegin, false) end)
            end
            task.wait(0.02)
            for _, conn in ipairs(getconnections(UserInputService.InputEnded)) do
                pcall(function() conn:Fire(mockInputEnd, false) end)
            end
        end
    end)
end

-----------------------------------------------------------------------
-- Q-Key Dash Trigger
-----------------------------------------------------------------------
local function triggerDashQ()
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(UserInputService.InputBegan)) do
                pcall(function()
                    conn:Fire({
                        UserInputType = Enum.UserInputType.Keyboard,
                        UserInputState = Enum.UserInputState.Begin,
                        KeyCode = Enum.KeyCode.Q
                    }, false)
                end)
            end
        end

        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            task.wait(0.035)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)

        if keypress then keypress(0x51) task.wait(0.035) keyrelease(0x51) end
    end)
end

-----------------------------------------------------------------------
-- G-Key Awakening Ultimate Trigger
-----------------------------------------------------------------------
local function triggerAwakeningG()
    pcall(function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, game)
            task.wait(0.035)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, game)
        end)

        if keypress then keypress(0x47) task.wait(0.035) keyrelease(0x47) end
    end)
end

-----------------------------------------------------------------------
-- Skill Activator (Keys 1, 2, 3, 4)
-----------------------------------------------------------------------
local function triggerSkill(skillNum)
    pcall(function()
        local keyCodes = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}
        local hexCodes = {0x31, 0x32, 0x33, 0x34}

        if getconnections and keyCodes[skillNum] then
            for _, conn in ipairs(getconnections(UserInputService.InputBegan)) do
                pcall(function()
                    conn:Fire({
                        UserInputType = Enum.UserInputType.Keyboard,
                        UserInputState = Enum.UserInputState.Begin,
                        KeyCode = keyCodes[skillNum]
                    }, false)
                end)
            end
        end

        if keyCodes[skillNum] then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, keyCodes[skillNum], false, game)
                task.wait(0.035)
                VirtualInputManager:SendKeyEvent(false, keyCodes[skillNum], false, game)
            end)
        end

        if keypress and hexCodes[skillNum] then
            pcall(function()
                keypress(hexCodes[skillNum])
                task.wait(0.035)
                keyrelease(hexCodes[skillNum])
            end)
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
-- Subsystem: High Speed Pursuit & Auto-Aim
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

            -- Camera Aim Lock
            if Workspace.CurrentCamera then
                Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, targetPos + Vector3.new(0, 1.5, 0))
            end

            -- Ground Pursuit
            if dist > 3.0 then
                hum:MoveTo(targetPos)
                local dir = (targetPos - myPos).Unit
                root.CFrame = CFrame.new(myPos + Vector3.new(dir.X * 1.5, 0, dir.Z * 1.5), Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
            else
                root.CFrame = CFrame.new(myPos, Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
            end
        end
    end)
end)

-----------------------------------------------------------------------
-- Subsystem: Pro Combat Loop (M1 Combo + Q Dash + Skills)
-----------------------------------------------------------------------
task.spawn(function()
    local skillCycle = {1, 2, 3, 4}
    local skillIdx = 1

    while task.wait(0.05) do
        if _G.TSB_AutoCombat and currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local targetRoot = currentTarget.HumanoidRootPart
                local targetHum = currentTarget:FindFirstChildOfClass("Humanoid")

                if root and targetRoot and hum and hum.Health > 0 and targetHum and targetHum.Health > 0 then
                    local dist = (targetRoot.Position - root.Position).Magnitude

                    -- Anti-Counter Evade
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
                        triggerDashQ()
                        root.CFrame = root.CFrame * CFrame.new(0, 6, 25)
                        task.wait(0.2)
                        return
                    end

                    if dist <= 14 then
                        -- STEP 1: Execute 4 M1 Punches with 0.035s Frame-Hold
                        for i = 1, 4 do
                            performM1Click()
                            task.wait(0.18)
                        end

                        -- STEP 2: Execute 1 Skill after M1 Combo
                        triggerSkill(skillCycle[skillIdx])
                        skillIdx = (skillIdx % #skillCycle) + 1
                        task.wait(0.2)

                        -- STEP 3: Q-Dash Reset
                        triggerDashQ()
                        task.wait(0.05)

                        -- STEP 4: Snap to Enemy's Back
                        local backPos = targetRoot.CFrame * CFrame.new(0, 0, 3.0)
                        root.CFrame = CFrame.new(backPos.Position, targetRoot.Position)
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
TitleLabel.Text = "🥊 TSB M1 FRAME-HOLD CLICK FIX v12.0"
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
AutoCombatBtn.Text = "⚡ FRAME-HOLD M1 CLICK: ВКЛЮЧЕН"
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
        AutoCombatBtn.Text = "⚡ FRAME-HOLD M1 CLICK: ВКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
    else
        AutoCombatBtn.Text = "⚡ FRAME-HOLD M1 CLICK: ВЫКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    end
end)

notify("TSB Pro Combat", "🥊 M1 FRAME-HOLD CLICK v12.0 УСПЕШНО ЗАПУЩЕН!")
print("[+] TSB Pro Combat Engine v12.0 Loaded.")
