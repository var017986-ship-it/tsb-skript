-- ====================================================================
-- The Strongest Battlegrounds (TSB) Master Hub v17.0 (ULTIMATE UPDATE)
-- File: script.lua
-- Repository: https://github.com/var017986-ship-it/tsb-skript
-- Features: 1. CONTINUOUS TARGET FLING (Start / Stop Flinging specific player)
--           2. GAROU VOID PLATFORM (Stay on Platform vs Return to Arena option)
--           3. RETURN TO ARENA BUTTON & HOTKEY
--           4. SAITAMA GOJO VFX Skills (1, 2, 3, 4)
--           5. ADVANCED ANTI-FLING ENGINE
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
_G.TSB_LoopFlingAll = false
_G.TSB_GarouVoidTrap = false
_G.TSB_StayOnVoidPlatform = true
_G.TSB_TargetLoopFling = false
_G.TSB_TargetPlayerObj = nil

local savedArenaCFrame = nil

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
-- 2. ULTRA SUPER FLING ENGINE (SINGLE & CONTINUOUS TARGET FLING)
-----------------------------------------------------------------------
local function superFlingTarget(targetChar)
    if not targetChar then return end
    local myRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")

    if not myRoot or not targetRoot or not targetHum or targetHum.Health <= 0 then return end

    local oldCF = myRoot.CFrame
    
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
    while tick() - startTime < 0.6 do
        if not targetRoot or not targetRoot.Parent or targetHum.Health <= 0 then break end
        
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
            if not _G.TSB_TargetLoopFling then
                Character.HumanoidRootPart.CFrame = oldCF
            end
        end
    end)
end

-- Continuous Target Fling Background Task
task.spawn(function()
    while task.wait(0.1) do
        if _G.TSB_TargetLoopFling and _G.TSB_TargetPlayerObj then
            if _G.TSB_TargetPlayerObj.Character and _G.TSB_TargetPlayerObj.Character:FindFirstChild("HumanoidRootPart") then
                superFlingTarget(_G.TSB_TargetPlayerObj.Character)
            end
        end
    end
end)

-- Loop Fling All Players Background Task
local function flingAllPlayers()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            superFlingTarget(p.Character)
            task.wait(0.04)
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if _G.TSB_LoopFlingAll then
            flingAllPlayers()
        end
    end
end)

-----------------------------------------------------------------------
-- 3. GAROU VOID TELEPORT ENGINE (STAY ON PLATFORM OR RETURN)
-----------------------------------------------------------------------
local voidPlatform = nil
local function getOrCreateVoidPlatform()
    if voidPlatform and voidPlatform.Parent then
        return voidPlatform
    end
    local plate = Instance.new("Part")
    plate.Name = "TSB_GarouVoidPlatform"
    plate.Size = Vector3.new(250, 8, 250)
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

local function executeGarouVoidTeleport()
    pcall(function()
        local myRoot = Character and Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        if not savedArenaCFrame then
            savedArenaCFrame = myRoot.CFrame
        end

        getOrCreateVoidPlatform()
        local targetPlayer = getNearestPlayer(40)

        notify("Garou Teleport", "⚡ Телепорт на небесную платформу...")
        task.wait(0.15)

        local voidCF = CFrame.new(9999, 6006, 9999)

        -- Teleport both to platform
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.CFrame = voidCF
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                targetPlayer.Character.HumanoidRootPart.CFrame = voidCF * CFrame.new(0, 0, -3)
            end
        end

        if not _G.TSB_StayOnVoidPlatform then
            task.wait(2.0)
            if Character and Character:FindFirstChild("HumanoidRootPart") and savedArenaCFrame then
                Character.HumanoidRootPart.CFrame = savedArenaCFrame
            end
            notify("Garou Teleport", "🏠 Возврат на арену...")
        else
            notify("Garou Teleport", "🌌 Вы остались на небесной платформе!")
        end
    end)
end

local function returnToArena()
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        if savedArenaCFrame then
            Character.HumanoidRootPart.CFrame = savedArenaCFrame
            notify("TSB Hub", "🏠 Вы вернулись на арену!")
        else
            Character.HumanoidRootPart.CFrame = CFrame.new(0, 50, 0)
            notify("TSB Hub", "🏠 Телепорт в центр спавна!")
        end
    end
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
        executeGarouVoidTeleport()
    elseif input.KeyCode == Enum.KeyCode.R then
        returnToArena()
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
MainFrame.Size = UDim2.new(0, 330, 0, 470)
MainFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
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
TitleLabel.Text = "⚡ TSB MASTER HUB v17.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 14
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

-- Garou Void Trap Toggle Button
local GarouBtn = Instance.new("TextButton")
GarouBtn.Size = UDim2.new(1, -24, 0, 34)
GarouBtn.Position = UDim2.new(0, 12, 0, 50)
GarouBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
GarouBtn.Text = "🐺 GAROU VOID TRAP (1&2 / T): ВЫКЛ"
GarouBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GarouBtn.Font = Enum.Font.SourceSansBold
GarouBtn.TextSize = 11
GarouBtn.Parent = MainFrame

local GarouCorner = Instance.new("UICorner")
GarouCorner.CornerRadius = UDim.new(0, 8)
GarouCorner.Parent = GarouBtn

GarouBtn.MouseButton1Click:Connect(function()
    _G.TSB_GarouVoidTrap = not _G.TSB_GarouVoidTrap
    if _G.TSB_GarouVoidTrap then
        GarouBtn.Text = "🐺 GAROU VOID TRAP (1&2 / T): ВКЛ"
        GarouBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 240)
        notify("Garou Mode", "🌌 Выброс за карту ВКЛЮЧЕН!")
    else
        GarouBtn.Text = "🐺 GAROU VOID TRAP (1&2 / T): ВЫКЛ"
        GarouBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        notify("Garou Mode", "❌ Выброс за карту ВЫКЛЮЧЕН!")
    end
end)

-- Stay On Void Platform Toggle Button
local StayPlatformBtn = Instance.new("TextButton")
StayPlatformBtn.Size = UDim2.new(1, -24, 0, 34)
StayPlatformBtn.Position = UDim2.new(0, 12, 0, 90)
StayPlatformBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 220)
StayPlatformBtn.Text = "🌌 ОСТАВАТЬСЯ НА ПЛАТФОРМЕ: ВКЛ"
StayPlatformBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StayPlatformBtn.Font = Enum.Font.SourceSansBold
StayPlatformBtn.TextSize = 11
StayPlatformBtn.Parent = MainFrame

local StayCorner = Instance.new("UICorner")
StayCorner.CornerRadius = UDim.new(0, 8)
StayCorner.Parent = StayPlatformBtn

StayPlatformBtn.MouseButton1Click:Connect(function()
    _G.TSB_StayOnVoidPlatform = not _G.TSB_StayOnVoidPlatform
    if _G.TSB_StayOnVoidPlatform then
        StayPlatformBtn.Text = "🌌 ОСТАВАТЬСЯ НА ПЛАТФОРМЕ: ВКЛ"
        StayPlatformBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 220)
    else
        StayPlatformBtn.Text = "🌌 ОСТАВАТЬСЯ НА ПЛАТФОРМЕ: ВЫКЛ (АВТО-ВОЗВРАТ)"
        StayPlatformBtn.BackgroundColor3 = Color3.fromRGB(220, 100, 40)
    end
end)

-- Return to Arena Button
local ReturnBtn = Instance.new("TextButton")
ReturnBtn.Size = UDim2.new(1, -24, 0, 34)
ReturnBtn.Position = UDim2.new(0, 12, 0, 130)
ReturnBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 200)
ReturnBtn.Text = "🏠 ВЕРНУТЬСЯ НА АРЕНУ (КЛАВИША R)"
ReturnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ReturnBtn.Font = Enum.Font.SourceSansBold
ReturnBtn.TextSize = 11
ReturnBtn.Parent = MainFrame

local ReturnCorner = Instance.new("UICorner")
ReturnCorner.CornerRadius = UDim.new(0, 8)
ReturnCorner.Parent = ReturnBtn

ReturnBtn.MouseButton1Click:Connect(function()
    returnToArena()
end)

-- Anti Fling Button
local AntiFlingBtn = Instance.new("TextButton")
AntiFlingBtn.Size = UDim2.new(1, -24, 0, 34)
AntiFlingBtn.Position = UDim2.new(0, 12, 0, 170)
AntiFlingBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 80)
AntiFlingBtn.Text = "🛡️ ANTI-FLING: ВКЛЮЧЕН"
AntiFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AntiFlingBtn.Font = Enum.Font.SourceSansBold
AntiFlingBtn.TextSize = 11
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

-- Target Username Input
local TargetInput = Instance.new("TextBox")
TargetInput.Size = UDim2.new(1, -24, 0, 34)
TargetInput.Position = UDim2.new(0, 12, 0, 210)
TargetInput.PlaceholderText = "Введите ник жертвы для Флинга..."
TargetInput.Text = ""
TargetInput.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
TargetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetInput.Font = Enum.Font.SourceSans
TargetInput.TextSize = 12
TargetInput.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = TargetInput

-- Start / Stop Loop Fling Target Button
local ToggleTargetFlingBtn = Instance.new("TextButton")
ToggleTargetFlingBtn.Size = UDim2.new(1, -24, 0, 34)
ToggleTargetFlingBtn.Position = UDim2.new(0, 12, 0, 250)
ToggleTargetFlingBtn.BackgroundColor3 = Color3.fromRGB(210, 40, 60)
ToggleTargetFlingBtn.Text = "💥 СТАРТ ФЛИНГ ЦЕЛИ (БЕСКОНЕЧНО)"
ToggleTargetFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleTargetFlingBtn.Font = Enum.Font.SourceSansBold
ToggleTargetFlingBtn.TextSize = 11
ToggleTargetFlingBtn.Parent = MainFrame

local TargetCorner = Instance.new("UICorner")
TargetCorner.CornerRadius = UDim.new(0, 8)
TargetCorner.Parent = ToggleTargetFlingBtn

ToggleTargetFlingBtn.MouseButton1Click:Connect(function()
    _G.TSB_TargetLoopFling = not _G.TSB_TargetLoopFling
    if _G.TSB_TargetLoopFling then
        local name = TargetInput.Text
        local foundPlayer = nil
        if name ~= "" then
            for _, p in ipairs(Players:GetPlayers()) do
                if string.sub(string.lower(p.Name), 1, #name) == string.lower(name) or string.sub(string.lower(p.DisplayName), 1, #name) == string.lower(name) then
                    foundPlayer = p
                    break
                end
            end
        end
        if foundPlayer then
            _G.TSB_TargetPlayerObj = foundPlayer
            ToggleTargetFlingBtn.Text = "🛑 ОСТАНОВИТЬ ФЛИНГ: " .. string.upper(foundPlayer.Name)
            ToggleTargetFlingBtn.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
            notify("Target Fling", "💥 Бесконечный флинг начат для " .. foundPlayer.Name)
        else
            _G.TSB_TargetLoopFling = false
            notify("Target Fling", "❌ Игрок с таким ником не найден!")
        end
    else
        _G.TSB_TargetPlayerObj = nil
        ToggleTargetFlingBtn.Text = "💥 СТАРТ ФЛИНГ ЦЕЛИ (БЕСКОНЕЧНО)"
        ToggleTargetFlingBtn.BackgroundColor3 = Color3.fromRGB(210, 40, 60)
        notify("Target Fling", "🛑 Флинг цели остановлен!")
    end
end)

-- Single Fling All Button
local FlingAllBtn = Instance.new("TextButton")
FlingAllBtn.Size = UDim2.new(1, -24, 0, 34)
FlingAllBtn.Position = UDim2.new(0, 12, 0, 290)
FlingAllBtn.BackgroundColor3 = Color3.fromRGB(190, 30, 90)
FlingAllBtn.Text = "💥 ФЛИНГНУТЬ ВСЕХ (1 РАЗ)"
FlingAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlingAllBtn.Font = Enum.Font.SourceSansBold
FlingAllBtn.TextSize = 11
FlingAllBtn.Parent = MainFrame

local BtnCorner3 = Instance.new("UICorner")
BtnCorner3.CornerRadius = UDim.new(0, 8)
BtnCorner3.Parent = FlingAllBtn

FlingAllBtn.MouseButton1Click:Connect(function()
    task.spawn(flingAllPlayers)
end)

-- Loop Fling All Button
local LoopFlingBtn = Instance.new("TextButton")
LoopFlingBtn.Size = UDim2.new(1, -24, 0, 34)
LoopFlingBtn.Position = UDim2.new(0, 12, 0, 330)
LoopFlingBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
LoopFlingBtn.Text = "⚡ АВТО-ФЛИНГ ВСЕХ: ВЫКЛ"
LoopFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopFlingBtn.Font = Enum.Font.SourceSansBold
LoopFlingBtn.TextSize = 11
LoopFlingBtn.Parent = MainFrame

local BtnCorner4 = Instance.new("UICorner")
BtnCorner4.CornerRadius = UDim.new(0, 8)
BtnCorner4.Parent = LoopFlingBtn

LoopFlingBtn.MouseButton1Click:Connect(function()
    _G.TSB_LoopFlingAll = not _G.TSB_LoopFlingAll
    if _G.TSB_LoopFlingAll then
        LoopFlingBtn.Text = "⚡ АВТО-ФЛИНГ ВСЕХ: ВКЛ"
        LoopFlingBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        LoopFlingBtn.Text = "⚡ АВТО-ФЛИНГ ВСЕХ: ВЫКЛ"
        LoopFlingBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    end
end)

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -24, 0, 40)
InfoLabel.Position = UDim2.new(0, 12, 0, 375)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Hotkeys: T (Void Teleport), R (Return Arena), 1-4 (Gojo / Garou)"
InfoLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.SourceSans
InfoLabel.Parent = MainFrame

notify("TSB Master Hub v17.0", "✅ Готово! Старт/Стоп флинга цели + Платформа Гароу")
print("[+] TSB Master Hub v17.0 Loaded Successfully.")
