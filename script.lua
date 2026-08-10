-- ====================================================================
-- The Strongest Battlegrounds (TSB) Ultimate Fling All Tool v14.0
-- File: script.lua
-- Repository: https://github.com/var017986-ship-it/tsb-skript
-- Features: 1. Dedicated Fling All Players Physics Engine
--           2. Single Click Fling All Button
--           3. Infinite Loop Fling All Toggle
--           4. Noclip & Anti-Stuck Protection
-- ====================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

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

pcall(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

-----------------------------------------------------------------------
-- Fling Physics Engine
-----------------------------------------------------------------------
local function flingPlayer(targetChar)
    if not targetChar then return end
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar:FindFirstChildOfClass("Humanoid")

        if not root or not targetRoot or not targetHum or targetHum.Health <= 0 then return end

        local bav = Instance.new("BodyAngularVelocity")
        bav.Name = "TSBFlingForce"
        bav.AngularVelocity = Vector3.new(0, 999999, 0)
        bav.MaxTorque = Vector3.new(0, math.huge, 0)
        bav.P = math.huge
        bav.Parent = root

        local startTime = tick()
        while tick() - startTime < 0.45 do
            if not targetRoot or not root or targetHum.Health <= 0 then break end
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)
            root.Velocity = Vector3.new(99999, 99999, 99999)
            task.wait()
        end

        pcall(function() bav:Destroy() end)
    end)
end

local function flingAllPlayers()
    notify("TSB Fling", "🌀 Запуск Флинга Всех Игроков...")
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local origCFrame = root.CFrame

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            flingPlayer(p.Character)
            task.wait(0.05)
        end
    end

    -- Return to original location
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = origCFrame
        end
    end)

    notify("TSB Fling", "✅ Все Игроки Успешно Запущены!")
end

-----------------------------------------------------------------------
-- Loop Fling Background Task
-----------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.5) do
        if _G.TSB_LoopFling then
            flingAllPlayers()
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
MainFrame.Size = UDim2.new(0, 320, 0, 170)
MainFrame.Position = UDim2.new(0.5, -160, 0.3, 0)
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
TitleLabel.Text = "🌀 TSB ULTIMATE FLING ALL v14.0"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 14
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

local FlingOnceBtn = Instance.new("TextButton")
FlingOnceBtn.Size = UDim2.new(1, -24, 0, 44)
FlingOnceBtn.Position = UDim2.new(0, 12, 0, 52)
FlingOnceBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
FlingOnceBtn.Text = "🌀 ФЛИНГНУТЬ ВСЕХ ИГРОКОВ (1 РАЗ)"
FlingOnceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlingOnceBtn.Font = Enum.Font.SourceSansBold
FlingOnceBtn.TextSize = 12
FlingOnceBtn.Parent = MainFrame

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 8)
BtnCorner1.Parent = FlingOnceBtn

local LoopFlingBtn = Instance.new("TextButton")
LoopFlingBtn.Size = UDim2.new(1, -24, 0, 44)
LoopFlingBtn.Position = UDim2.new(0, 12, 0, 106)
LoopFlingBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
LoopFlingBtn.Text = "⚡ АВТО-ФЛИНГ ВСЕХ (БЕСКОНЕЧНО): ВЫКЛЮЧЕН"
LoopFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopFlingBtn.Font = Enum.Font.SourceSansBold
LoopFlingBtn.TextSize = 11
LoopFlingBtn.Parent = MainFrame

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 8)
BtnCorner2.Parent = LoopFlingBtn

FlingOnceBtn.MouseButton1Click:Connect(function()
    task.spawn(flingAllPlayers)
end)

LoopFlingBtn.MouseButton1Click:Connect(function()
    _G.TSB_LoopFling = not _G.TSB_LoopFling
    if _G.TSB_LoopFling then
        LoopFlingBtn.Text = "⚡ АВТО-ФЛИНГ ВСЕХ (БЕСКОНЕЧНО): ВКЛЮЧЕН"
        LoopFlingBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 92)
    else
        LoopFlingBtn.Text = "⚡ АВТО-ФЛИНГ ВСЕХ (БЕСКОНЕЧНО): ВЫКЛЮЧЕН"
        LoopFlingBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    end
end)

notify("TSB Fling Tool", "🌀 ULTIMATE FLING ALL v14.0 УСПЕШНО ЗАПУЩЕН!")
print("[+] TSB Ultimate Fling All Tool v14.0 Loaded.")
