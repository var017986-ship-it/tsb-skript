-- ====================================================================
-- The Strongest Battlegrounds (TSB) Ultimate Gojo & Fling Master Hub
-- File: script.lua
-- Features: 1. Gojo VFX Overlay for Saitama Skills (1, 2, 3, 4)
--           2. Anti-Fling Physics Protection
--           3. Single Target Fling by Username
--           4. Fling All & Loop Fling All Engine
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
-- 1. Anti-Fling Protection Engine
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
        if root and root.AssemblyLinearVelocity.Magnitude > 220 then
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end)
end
setupAntiFling()

-----------------------------------------------------------------------
-- 2. Fling Target & Fling All Engine
-----------------------------------------------------------------------
local function flingTarget(targetChar)
    if not targetChar then return end
    pcall(function()
        local myRoot = Character and Character:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar:FindFirstChildOfClass("Humanoid")

        if not myRoot or not targetRoot or not targetHum or targetHum.Health <= 0 then return end

        local bav = Instance.new("BodyAngularVelocity")
        bav.Name = "TSBFlingForce"
        bav.AngularVelocity = Vector3.new(0, 999999, 0)
        bav.MaxTorque = Vector3.new(0, math.huge, 0)
        bav.P = math.huge
        bav.Parent = myRoot

        local startTime = tick()
        while tick() - startTime < 0.45 do
            if not targetRoot or not myRoot or targetHum.Health <= 0 then break end
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)
            myRoot.AssemblyLinearVelocity = Vector3.new(99999, 99999, 99999)
            task.wait()
        end

        pcall(function() bav:Destroy() end)
    end)
end

local function flingAllPlayers()
    notify("TSB Fling", "🌀 Запуск флинга всех игроков...")
    local myRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local origCFrame = myRoot.CFrame

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            flingTarget(p.Character)
            task.wait(0.04)
        end
    end

    pcall(function()
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.CFrame = origCFrame
        end
    end)
    notify("TSB Fling", "✅ Все игроки успешно отправлены в полет!")
end

task.spawn(function()
    while task.wait(0.5) do
        if _G.TSB_LoopFling then
            flingAllPlayers()
        end
    end
end)

-----------------------------------------------------------------------
-- 3. Gojo Visual Effects Engine (Skills 1, 2, 3, 4)
-----------------------------------------------------------------------
local function spawnGojoVFX(skillIndex)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = Character.HumanoidRootPart

    -- Skill 1: Reversal Red
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

    -- Skill 2: Lapse Blue
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

    -- Skill 3: Hollow Purple
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

    -- Skill 4: Domain Expansion
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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.One then
        spawnGojoVFX(1)
    elseif input.KeyCode == Enum.KeyCode.Two then
        spawnGojoVFX(2)
    elseif input.KeyCode == Enum.KeyCode.Three then
        spawnGojoVFX(3)
    elseif input.KeyCode == Enum.KeyCode.Four then
        spawnGojoVFX(4)
    end
end)

-----------------------------------------------------------------------
-- 4. GUI Dashboard Interface
-----------------------------------------------------------------------
if CoreGui:FindFirstChild("TSBGojoMasterHub") then
    CoreGui.TSBGojoMasterHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TSBGojoMasterHub"
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
MainFrame.Size = UDim2.new(0, 310, 0, 320)
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 42)
TitleLabel.BackgroundColor3 = Color3.fromRGB(130, 0, 240)
TitleLabel.Text = "🌀 TSB: GOJO & FLING MASTER HUB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 13
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

local AntiFlingBtn = Instance.new("TextButton")
AntiFlingBtn.Size = UDim2.new(1, -24, 0, 36)
AntiFlingBtn.Position = UDim2.new(0, 12, 0, 52)
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

local TargetInput = Instance.new("TextBox")
TargetInput.Size = UDim2.new(1, -24, 0, 36)
TargetInput.Position = UDim2.new(0, 12, 0, 96)
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

local FlingTargetBtn = Instance.new("TextButton")
FlingTargetBtn.Size = UDim2.new(1, -24, 0, 36)
FlingTargetBtn.Position = UDim2.new(0, 12, 0, 140)
FlingTargetBtn.BackgroundColor3 = Color3.fromRGB(210, 40, 60)
FlingTargetBtn.Text = "🎯 ФЛИНГНУТЬ ЦЕЛЬ"
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
                flingTarget(p.Character)
                break
            end
        end
    end
end)

local FlingAllBtn = Instance.new("TextButton")
FlingAllBtn.Size = UDim2.new(1, -24, 0, 36)
FlingAllBtn.Position = UDim2.new(0, 12, 0, 184)
FlingAllBtn.BackgroundColor3 = Color3.fromRGB(190, 30, 90)
FlingAllBtn.Text = "💥 ФЛИНГНУТЬ ВСЕХ (1 РАЗ)"
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

local LoopFlingBtn = Instance.new("TextButton")
LoopFlingBtn.Size = UDim2.new(1, -24, 0, 36)
LoopFlingBtn.Position = UDim2.new(0, 12, 0, 228)
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
InfoLabel.Position = UDim2.new(0, 12, 0, 272)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Gojo VFX Skills: 1 (Red), 2 (Blue), 3 (Purple), 4 (Domain)"
InfoLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.SourceSans
InfoLabel.Parent = MainFrame

notify("TSB Master Hub", "✅ Скрипт Годжо + Флинг успешно загружен!")
print("[+] TSB Master Hub loaded successfully.")
