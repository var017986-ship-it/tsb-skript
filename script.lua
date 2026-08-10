-- ====================================================================
-- The Strongest Battlegrounds (TSB) Pro Combat Engine v10.0 (InputBegan Event Hook)
-- File: script.lua
-- Repository: https://github.com/var017986-ship-it/tsb-skript
-- Features: 1. Native getconnections(InputBegan) Hook for M1 Punch Attacks
--           2. Native getconnections(InputBegan) Hook for Q-Dash Evades
--           3. Multi-Layer Skill Activator (1, 2, 3, 4)
--           4. 3X Hyper Speed Sprint & Anti-Counter 25-stud Evasion
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
-- Guaranteed M1 Mouse Punch Trigger (InputBegan Hook + Center Click)
-----------------------------------------------------------------------
local function performM1Click()
    pcall(function()
        -- Method 1: Fire UserInputService.InputBegan connections directly (TSB Native Event Hook)
        if getconnections then
            for _, conn in ipairs(getconnections(UserInputService.InputBegan)) do
                pcall(function()
                    conn:Fire({
                        UserInputType = Enum.UserInputType.MouseButton1,
                        UserInputState = Enum.UserInputState.Begin,
                        KeyCode = Enum.KeyCode.Unknown
                    }, false)
                end)
            end
        end

        -- Method 2: Center Viewport VirtualInputManager Click
        local camera = Workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
        local cx = math.floor(vp.X / 2)
        local cy = math.floor(vp.Y / 2)

        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.015)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end)

        -- Method 3: Executor mouse1click / mouse1press
        if mouse1click then
            mouse1click()
        elseif mouse1press then
            mouse1press()
            task.wait(0.015)
            mouse1release()
        end

        -- Method 4: VirtualUser Click
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(cx, cy))
            task.wait(0.015)
            VirtualUser:Button1Up(Vector2.new(cx, cy))
        end)
    end)
end

-----------------------------------------------------------------------
-- Guaranteed Q-Key Dash Trigger (InputBegan Hook + Virtual Key)
-----------------------------------------------------------------------
local function triggerDashQ()
    pcall(function()
        -- Method 1: Fire UserInputService.InputBegan for Q Key
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

        -- Method 2: VirtualInputManager Q Key
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)

        -- Method 3: Executor keypress 0x51 ('Q')
        if keypress then
            pcall(function()
                keypress(0x51)
                task.wait(0.03)
                keyrelease(0x51)
            end)
        end
    end)
end

-----------------------------------------------------------------------
-- Guaranteed Skill Activator (Keys 1, 2, 3, 4)
-----------------------------------------------------------------------
local function triggerSkill(skillNum)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end

        local keyCodes = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}
        local hexCodes = {0x31, 0x32, 0x33, 0x34}

        -- Fire InputBegan Hook for Skill Key
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

        -- VirtualInputManager Key
        if keyCodes[skillNum] then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, keyCodes[skillNum], false, game)
                task.wait(0.02)
                VirtualInputManager:SendKeyEvent(false, keyCodes[skillNum], false, game)
            end)
        end

        -- keypress / keyrelease
        if keypress and hexCodes[skillNum] then
            pcall(function()
                keypress(hexCodes[skillNum])
                task.wait(0.02)
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
-- Subsystem: Fast Movement & Auto-Aim Camera
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

            -- Lock Camera onto Target
            if Workspace.CurrentCamera then
                Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, targetPos + Vector3.new(0, 1.5, 0))
            end

            -- Fast Ground Pursuit
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

                    -- Anti-Counter Check (If enemy parries -> fly back 25 studs)
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
                        -- STEP 1: Execute 4 Consecutive M1 Punches!
                        for m1Count = 1, 4 do
                            performM1Click()
                            task.wait(0.18)
                        end

                        -- STEP 2: Execute Q Dash towards / around target!
                        triggerDashQ()
                        task.wait(0.05)

                        -- STEP 3: Execute 1 Skill after M1 Combo & Q Dash!
                        triggerSkill(skillCycle[skillIdx])
                        skillIdx = (skillIdx % #skillCycle) + 1
                        task.wait(0.2)

                        -- STEP 4: Tactical Backdash Behind Enemy
                        local backPos = targetRoot.CFrame * CFrame.new(0, 0, 3.2)
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
TitleLabel.Text = "🥊 TSB INPUTBEGAN HOOK ENGINE v10.0"
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
AutoCombatBtn.Text = "⚡ INPUTBEGAN HOOK & Q-DASH: ВКЛЮЧЕН"
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
        AutoCombatBtn.Text = "⚡ INPUTBEGAN HOOK & Q-DASH: ВКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
    else
        AutoCombatBtn.Text = "⚡ INPUTBEGAN HOOK & Q-DASH: ВЫКЛЮЧЕН"
        AutoCombatBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    end
end)

notify("TSB Pro Combat", "🥊 INPUTBEGAN HOOK v10.0 УСПЕШНО ЗАПУЩЕН!")
print("[+] TSB Pro Combat Engine v10.0 Loaded.")
