-- ====================================================================
-- The Strongest Battlegrounds (TSB) Master Hub v16.0 (FIXED & POWERFUL)
-- File: script.lua
-- Repository: https://github.com/var017986-ship-it/tsb-skript
-- Features: 1. ULTRA SUPER FLING Engine (SimulationRadius & CFrame Jitter)
--           2. GAROU TELEPORT VOID TRAP (Heartbeat Sync + Proximity Check)
--           3. SAITAMA GOJO VFX Skills (1, 2, 3, 4)
--           4. ADVANCED ANTI-FLING Engine
-- ====================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
end)

_G.TSB_AntiFling = true
_G.TSB_LoopFling = false
_G.TSB_GarouVoidTrap = false

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

-- Maximize Physics Network Ownership
pcall(function()
    if sethiddenproperty then
        sethiddenproperty(LocalPlayer, "SimulationRadius", 1000)
        sethiddenproperty(LocalPlayer, "MaximumSimulationRadius", 1000)
    end
end)

-----------------------------------------------------------------------
-- 1. Advanced Anti-Fling Protection Engine
-----------------------------------------------------------------------
local antiFlingConn = nil
local function setupAntiFling()
    if antiFlingConn then antiFlingConn:Disconnect() end
    antiFlingConn = RunService.Stepped:Connect(function()
        if not _G.TSB_AntiFling then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
        local root = Character and Character:FindFirstChild("HumanoidRootPart")
        if root then
            if root.AssemblyLinearVelocity.Magnitude > 150 or root.AssemblyAngularVelocity.Magnitude > 150 then
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end
setupAntiFling()

-----------------------------------------------------------------------
-- 2. ULTRA SUPER FLING ENGINE (FIXED & EXTREME SPEED)
-----------------------------------------------------------------------
local function superFlingTarget(targetChar)
    if not targetChar then return end
    local myRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")

    if not myRoot or not targetRoot or not targetHum or targetHum.Health <= 0 then return end

    local oldCF = myRoot.CFrame
    
    -- Body Gyro & Angular Velocity for max torque
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 9e9
    bg.CFrame = myRoot.CFrame
    bg.Parent = myRoot

    local bav = Instance.new("BodyAngularVelocity")
    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bav.AngularVelocity = Vector3.new(0, 9999999, 0)
    bav.P = 9e9
    bav.Parent = myRoot

    local startTime = tick()
    while tick() - startTime < 1.2 do
        if not targetRoot or not targetRoot.Parent or targetHum.Health <= 0 then break end
        
        -- High-frequency physical jitter right against target HRP
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
        myRoot.AssemblyLinearVelocity = Vector3.new(999999, 999999, 999999)
        myRoot.AssemblyAngularVelocity = Vector3.new(0, 9999999, 0)
        
        RunService.Heartbeat:Wait()
    end

    bav:Destroy()
    bg:Destroy()

    pcall(function()
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            Character.HumanoidRootPart.CFrame = oldCF
        end
    end)
end

local function flingAllPlayers()
    notify("TSB Super Fling", "🌀 Запуск мощного Флинга всех игроков...")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            superFlingTarget(p.Character)
            task.wait(0.05)
        end
    end
    notify("TSB Super Fling", "✅ Все игроки отправлены за карту!")
end

task.spawn(function()
    while task.wait(0.5) do
        if _G.TSB_LoopFling then
            flingAllPlayers()
        end
    end
end)

-----------------------------------------------------------------------
-- 3. GAROU (HERO HUNTER) VOID TELEPORT ENGINE (FIXED & RELIABLE)
-----------------------------------------------------------------------
local voidPlatform = nil
local function getOrCreateVoidPlatform()
    if voidPlatform and voidPlatform.Parent then
        return voidPlatform
    end
    local plate = Instance.new("Part")
    plate.Name = "TSB_GarouVoidPlatform"
    plate.Size = Vector3.new(200, 8, 200)
    plate.CFrame = CFrame.new(9999, 6000, 9999)
    plate.Anchored = true
    plate.CanCollide = true
    plate.Color = Color3.fromRGB(30, 20, 50)
    plate.Material = Enum.Material.SmoothPlastic
    plate.Parent = workspace
    voidPlatform = plate
    return plate
end

local function getNearestPlayer(maxDist)
    local myRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, closestDist = nil, maxDist or 35
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = p
            end
        end
    end
    return closest
end

local isGarouTeleporting = false
local function executeGarouVoidTeleport()
    if isGarouTeleporting then return end
    isGarouTeleporting = true

    task.spawn(function()
        pcall(function()
            local myRoot = Character and Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then isGarouTeleporting = false return end

            local origCF = myRoot.CFrame
            getOrCreateVoidPlatform()

            -- Find target near Garou
            local targetPlayer = getNearestPlayer(40)

            notify("Garou Teleport", "⚡ Активация телепорта за карту...")

            -- Wait 0.15s for Garou combo grab to lock target
            task.wait(0.15)

            -- Continuous Heartbeat Teleport loop for 1.4 seconds to guarantee server sync
            local voidCF = CFrame.new(9999, 6006, 9999)
            local startTime = tick()

            while tick() - startTime < 1.4 do
                if Character and Character:FindFirstChild("HumanoidRootPart") then
                    Character.HumanoidRootPart.CFrame = voidCF
                    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        -- Pull target alongside if needed
                        targetPlayer.Character.HumanoidRootPart.CFrame = voidCF * CFrame.new(0, 0, -2)
                    end
                end
                RunService.Heartbeat:Wait()
            end

            -- Return LocalPlayer back to original fight spot
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                Character.HumanoidRootPart.CFrame = origCF
            end

            notify("Garou Teleport", "🌌 Цель сброшена за карту!")
        end)
        isGarouTeleporting = false
    end)
end

-----------------------------------------------------------------------
-- 4. SAITAMA GOJO VFX ENGINE (Skills 1, 2, 3, 4)
-----------------------------------------------------------------------
local function spawnGojoVFX(skillIndex)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = Character.HumanoidRootPart

    if skillIndex == 1 then
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(255, 20, 50)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.3
        hl.Parent = Character
        Debris:AddItem(hl, 0.6)

        local redSphere = Instance.new("Part")
        redSphere.Shape = Enum.PartType.Ball
        redSphere.Size = Vector3.new(2, 2, 2)
        redSphere.Color = Color3.fromRGB(255, 0, 40)
        redSphere.Material = Enum.Material.Neon
        redSphere.CanCollide = false
        redSphere.Anchored = true
        redSphere.CFrame = hrp.CFrame * CFrame.new(0, 0.5, -3)
        redSphere.Parent = workspace

        local tween = TweenService:Create(redSphere, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(16, 16, 16),
            Transparency = 1,
            CFrame = hrp.CFrame * CFrame.new(0, 0.5, -15)
        })
        tween:Play()
        Debris:AddItem(redSphere, 0.6)

    elseif skillIndex == 2 then
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(0, 150, 255)
        hl.OutlineColor = Color3.fromRGB(200, 240, 255)
        hl.FillTransparency = 0.3
        hl.Parent = Character
        Debris:AddItem(hl, 0.6)

        local blueSphere = Instance.new("Part")
        blueSphere.Shape = Enum.PartType.Ball
        blueSphere.Size = Vector3.new(14, 14, 14)
        blueSphere.Color = Color3.fromRGB(0, 140, 255)
        blueSphere.Material = Enum.Material.Neon
        blueSphere.CanCollide = false
        blueSphere.Anchored = true
        blueSphere.CFrame = hrp.CFrame * CFrame.new(0, 1, -8)
        blueSphere.Parent = workspace

        local tween = TweenService:Create(blueSphere, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
            Size = Vector3.new(0.5, 0.5, 0.5),
            Transparency = 0.2
        })
        tween:Play()
        
        tween.Completed:Connect(function()
            local implosion = Instance.new("Part")
            implosion.Shape = Enum.PartType.Ball
            implosion.Size = Vector3.new(1, 1, 1)
            implosion.Color = Color3.fromRGB(150, 220, 255)
            implosion.Material = Enum.Material.Neon
            implosion.CanCollide = false
            implosion.Anchored = true
            implosion.CFrame = blueSphere.CFrame
            implosion.Parent = workspace

            TweenService:Create(implosion, TweenInfo.new(0.3), {Size = Vector3.new(12, 12, 12), Transparency = 1}):Play()
            Debris:AddItem(implosion, 0.4)
            blueSphere:Destroy()
        end)

    elseif skillIndex == 3 then
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(170, 0, 255)
        hl.OutlineColor = Color3.fromRGB(255, 100, 255)
        hl.FillTransparency = 0.2
        hl.Parent = Character
        Debris:AddItem(hl, 1.2)

        local purpleBlast = Instance.new("Part")
        purpleBlast.Shape = Enum.PartType.Ball
        purpleBlast.Size = Vector3.new(6, 6, 6)
        purpleBlast.Color = Color3.fromRGB(160, 0, 255)
        purpleBlast.Material = Enum.Material.Neon
        purpleBlast.CanCollide = false
        purpleBlast.Anchored = true
        purpleBlast.CFrame = hrp.CFrame * CFrame.new(0, 1, -4)
        purpleBlast.Parent = workspace

        local tween = TweenService:Create(purpleBlast, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {
            CFrame = hrp.CFrame * CFrame.new(0, 1, -80),
            Size = Vector3.new(30, 30, 30),
            Transparency = 1
        })
        tween:Play()
        Debris:AddItem(purpleBlast, 1.3)

    elseif skillIndex == 4 then
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineColor = Color3.fromRGB(140, 0, 255)
        hl.FillTransparency = 0.1
        hl.Parent = Character
        Debris:AddItem(hl, 3.5)

        local domainSphere = Instance.new("Part")
        domainSphere.Shape = Enum.PartType.Ball
        domainSphere.Size = Vector3.new(2, 2, 2)
        domainSphere.Color = Color3.fromRGB(10, 10, 20)
        domainSphere.Material = Enum.Material.ForceField
        domainSphere.CanCollide = false
        domainSphere.Anchored = true
        domainSphere.CFrame = hrp.CFrame
        domainSphere.Parent = workspace

        TweenService:Create(domainSphere, TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
            Size = Vector3.new(100, 100, 100)
        }):Play()

        task.delay(3, function()
            local fade = TweenService:Create(domainSphere, TweenInfo.new(0.8), {Transparency = 1})
            fade:Play()
            fade.Completed:Connect(function() domainSphere:Destroy() end)
        end)
    end
end

-- Key Input Dispatcher
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.One then
        spawnGojoVFX(1)
        if _G.TSB_GarouVoidTrap then
            executeGarouVoidTeleport()
        end
    elseif input.KeyCode == Enum.KeyCode.Two then
        spawnGojoVFX(2)
        if _G.TSB_GarouVoidTrap then
            executeGarouVoidTeleport()
        end
    elseif input.KeyCode == Enum.KeyCode.Three then
        spawnGojoVFX(3)
    elseif input.KeyCode == Enum.KeyCode.Four then
        spawnGojoVFX(4)
    elseif input.KeyCode == Enum.KeyCode.T then
        -- Manual Hotkey T for Garou Teleport Void
        executeGarouVoidTeleport()
    end
end)

-----------------------------------------------------------------------
-- 5. DASHBOARD UI
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
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 42)
TitleLabel.BackgroundColor3 = Color3.fromRGB(140, 0, 255)
TitleLabel.Text = "⚡ TSB MASTER HUB v16.0 (FIXED)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 14
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

-- Garou Void Trap Toggle Button
local GarouBtn = Instance.new("TextButton")
GarouBtn.Size = UDim2.new(1, -24, 0, 36)
GarouBtn.Position = UDim2.new(0, 12, 0, 52)
GarouBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
GarouBtn.Text = "🐺 GAROU VOID TRAP (1&2 / T): ВЫКЛ"
GarouBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GarouBtn.Font = Enum.Font.SourceSansBold
GarouBtn.TextSize = 12
GarouBtn.Parent = MainFrame

local GarouCorner = Instance.new("UICorner")
GarouCorner.CornerRadius = UDim.new(0, 8)
GarouCorner.Parent = GarouBtn

GarouBtn.MouseButton1Click:Connect(function()
    _G.TSB_GarouVoidTrap = not _G.TSB_GarouVoidTrap
    if _G.TSB_GarouVoidTrap then
        GarouBtn.Text = "🐺 GAROU VOID TRAP (1&2 / T): ВКЛ"
        GarouBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 240)
        notify("Garou Mode", "🌌 Выброс за карту для Гароу ВКЛЮЧЕН! (Жми 1, 2 или клавишу T)")
    else
        GarouBtn.Text = "🐺 GAROU VOID TRAP (1&2 / T): ВЫКЛ"
        GarouBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        notify("Garou Mode", "❌ Выброс за карту ВЫКЛЮЧЕН!")
    end
end)

-- Garou Manual Teleport Button
local GarouManualBtn = Instance.new("TextButton")
GarouManualBtn.Size = UDim2.new(1, -24, 0, 36)
GarouManualBtn.Position = UDim2.new(0, 12, 0, 96)
GarouManualBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 200)
GarouManualBtn.Text = "⚡ ТЕЛЕПОРТИРОВАТЬ БЛИЖНЕГО (КЛАВИША T)"
GarouManualBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GarouManualBtn.Font = Enum.Font.SourceSansBold
GarouManualBtn.TextSize = 11
GarouManualBtn.Parent = MainFrame

local GarouManualCorner = Instance.new("UICorner")
GarouManualCorner.CornerRadius = UDim.new(0, 8)
GarouManualCorner.Parent = GarouManualBtn

GarouManualBtn.MouseButton1Click:Connect(function()
    executeGarouVoidTeleport()
end)

-- Anti Fling Button
local AntiFlingBtn = Instance.new("TextButton")
AntiFlingBtn.Size = UDim2.new(1, -24, 0, 36)
AntiFlingBtn.Position = UDim2.new(0, 12, 0, 140)
AntiFlingBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 80)
AntiFlingBtn.Text = "🛡️ ANTI-FLING: ВКЛЮЧЕН"
AntiFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AntiFlingBtn.Font = Enum.Font.SourceSansBold
AntiFlingBtn.TextSize = 12
AntiFlingBtn.Parent = MainFrame

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 8)
BtnCorner1.Parent = AntiFlingBtn

AntiFlingBtn.MouseButton1Click:Connect(function()
    _G.TSB_AntiFling = not _G.TSB_AntiFling
    if _G.TSB_AntiFling then
        AntiFlingBtn.Text = "🛡️ ANTI-FLING: ВКЛЮЧЕН"
        AntiFlingBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 80)
    else
        AntiFlingBtn.Text = "🛡️ ANTI-FLING: ВЫКЛЮЧЕН"
        AntiFlingBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
end)

-- Target Input
local TargetInput = Instance.new("TextBox")
TargetInput.Size = UDim2.new(1, -24, 0, 36)
TargetInput.Position = UDim2.new(0, 12, 0, 184)
TargetInput.PlaceholderText = "Введите ник игрока..."
TargetInput.Text = ""
TargetInput.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
TargetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetInput.Font = Enum.Font.SourceSans
TargetInput.TextSize = 13
TargetInput.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = TargetInput

-- Fling Target Button
local FlingTargetBtn = Instance.new("TextButton")
FlingTargetBtn.Size = UDim2.new(1, -24, 0, 36)
FlingTargetBtn.Position = UDim2.new(0, 12, 0, 228)
FlingTargetBtn.BackgroundColor3 = Color3.fromRGB(210, 40, 60)
FlingTargetBtn.Text = "🎯 СУПЕР ФЛИНГ ЦЕЛИ"
FlingTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlingTargetBtn.Font = Enum.Font.SourceSansBold
FlingTargetBtn.TextSize = 12
FlingTargetBtn.Parent = MainFrame

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 8)
BtnCorner2.Parent = FlingTargetBtn

FlingTargetBtn.MouseButton1Click:Connect(function()
    local name = TargetInput.Text
    if name ~= "" then
        for _, p in ipairs(Players:GetPlayers()) do
            if string.sub(string.lower(p.Name), 1, #name) == string.lower(name) or string.sub(string.lower(p.DisplayName), 1, #name) == string.lower(name) then
                superFlingTarget(p.Character)
                break
            end
        end
    end
end)

-- Fling All Button
local FlingAllBtn = Instance.new("TextButton")
FlingAllBtn.Size = UDim2.new(1, -24, 0, 36)
FlingAllBtn.Position = UDim2.new(0, 12, 0, 272)
FlingAllBtn.BackgroundColor3 = Color3.fromRGB(190, 30, 90)
FlingAllBtn.Text = "💥 СУПЕР ФЛИНГ ВСЕХ (1 РАЗ)"
FlingAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlingAllBtn.Font = Enum.Font.SourceSansBold
FlingAllBtn.TextSize = 12
FlingAllBtn.Parent = MainFrame

local BtnCorner3 = Instance.new("UICorner")
BtnCorner3.CornerRadius = UDim.new(0, 8)
BtnCorner3.Parent = FlingAllBtn

FlingAllBtn.MouseButton1Click:Connect(function()
    task.spawn(flingAllPlayers)
end)

-- Loop Fling Button
local LoopFlingBtn = Instance.new("TextButton")
LoopFlingBtn.Size = UDim2.new(1, -24, 0, 36)
LoopFlingBtn.Position = UDim2.new(0, 12, 0, 316)
LoopFlingBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
LoopFlingBtn.Text = "⚡ АВТО-ФЛИНГ ВСЕХ: ВЫКЛ"
LoopFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopFlingBtn.Font = Enum.Font.SourceSansBold
LoopFlingBtn.TextSize = 12
LoopFlingBtn.Parent = MainFrame

local BtnCorner4 = Instance.new("UICorner")
BtnCorner4.CornerRadius = UDim.new(0, 8)
BtnCorner4.Parent = LoopFlingBtn

LoopFlingBtn.MouseButton1Click:Connect(function()
    _G.TSB_LoopFling = not _G.TSB_LoopFling
    if _G.TSB_LoopFling then
        LoopFlingBtn.Text = "⚡ АВТО-ФЛИНГ ВСЕХ: ВКЛ"
        LoopFlingBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        LoopFlingBtn.Text = "⚡ АВТО-ФЛИНГ ВСЕХ: ВЫКЛ"
        LoopFlingBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    end
end)

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -24, 0, 36)
InfoLabel.Position = UDim2.new(0, 12, 0, 358)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Garou Void: Keys 1, 2 or T | Gojo: Keys 1-4"
InfoLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.SourceSans
InfoLabel.Parent = MainFrame

notify("TSB Master Hub v16.0", "✅ Загружен! Супер Флинг + Гароу ТП (T) исправлены!")
print("[+] TSB Master Hub v16.0 Loaded Successfully.")
