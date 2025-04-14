-- NebulaStrike | Aimbot System

--// Environment

local Aimbot = {
    Settings = {
        Enabled = false,
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        Sensitivity = 0,
        ThirdPerson = false,
        ThirdPersonSensitivity = 3,
        TriggerKey = "MouseButton2",
        Toggle = false,
        LockPart = "Head"
    },

    FOV = {
        Enabled = true,
        Visible = true,
        Radius = 90,
        Color = Color3.fromRGB(255, 255, 255),
        LockedColor = Color3.fromRGB(255, 70, 70),
        Transparency = 0.5,
        Sides = 60,
        Thickness = 1,
        Filled = false
    },

    Connections = {},
    Target = nil,
    IsActive = false,
    DrawingCircle = Drawing.new("Circle")
}

--// Services & References

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local MouseLocation = UserInputService.GetMouseLocation
local Vector2 = Vector2.new
local CFrameNew = CFrame.new

--// Internal Functions

local function GetDistance(vector)
    return (MouseLocation(UserInputService) - Vector2(vector.X, vector.Y)).Magnitude
end

local function ClearTarget()
    Aimbot.Target = nil
    Aimbot.DrawingCircle.Color = Aimbot.FOV.Color
    UserInputService.MouseDeltaSensitivity = 1
end

local function IsOnTeam(player)
    return player.Team == LocalPlayer.Team
end

local function IsAlive(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function IsVisible(targetPart, model)
    if not Aimbot.Settings.WallCheck then return true end
    local parts = model:GetDescendants()
    return #Camera:GetPartsObscuringTarget({targetPart.Position}, parts) == 0
end

local function FindClosestPlayer()
    local closest, shortest = nil, Aimbot.FOV.Radius

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Aimbot.Settings.LockPart) then
            if Aimbot.Settings.TeamCheck and IsOnTeam(player) then continue end
            if Aimbot.Settings.AliveCheck and not IsAlive(player.Character) then continue end
            if not IsVisible(player.Character[Aimbot.Settings.LockPart], player.Character) then continue end

            local screenPos, visible = Camera:WorldToViewportPoint(player.Character[Aimbot.Settings.LockPart].Position)
            if visible then
                local dist = GetDistance(screenPos)
                if dist < shortest then
                    closest = player
                    shortest = dist
                end
            end
        end
    end

    Aimbot.Target = closest
end

--// Drawing FOV

local function UpdateFOV()
    local circle = Aimbot.DrawingCircle
    circle.Visible = Aimbot.FOV.Visible and Aimbot.FOV.Enabled
    circle.Radius = Aimbot.FOV.Radius
    circle.Color = Aimbot.Target and Aimbot.FOV.LockedColor or Aimbot.FOV.Color
    circle.Filled = Aimbot.FOV.Filled
    circle.Thickness = Aimbot.FOV.Thickness
    circle.NumSides = Aimbot.FOV.Sides
    circle.Transparency = Aimbot.FOV.Transparency
    circle.Position = MouseLocation(UserInputService)
end

--// Activation Logic

local function AimAtTarget()
    if not Aimbot.Target then return end

    local part = Aimbot.Target.Character and Aimbot.Target.Character:FindFirstChild(Aimbot.Settings.LockPart)
    if not part then return end

    if Aimbot.Settings.ThirdPerson then
        local pos = Camera:WorldToViewportPoint(part.Position)
        local offset = (pos - MouseLocation(UserInputService)) * Aimbot.Settings.ThirdPersonSensitivity
        mousemoverel(offset.X, offset.Y)
    else
        if Aimbot.Settings.Sensitivity > 0 then
            local tween = TweenService:Create(Camera, TweenInfo.new(Aimbot.Settings.Sensitivity), {
                CFrame = CFrameNew(Camera.CFrame.Position, part.Position)
            })
            tween:Play()
        else
            Camera.CFrame = CFrameNew(Camera.CFrame.Position, part.Position)
        end
        UserInputService.MouseDeltaSensitivity = 0
    end
end

--// Input Handlers

Aimbot.Connections.InputBegan = UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Aimbot.Settings.TriggerKey or
       input.UserInputType.Name == Aimbot.Settings.TriggerKey then
        if Aimbot.Settings.Toggle then
            Aimbot.IsActive = not Aimbot.IsActive
            if not Aimbot.IsActive then ClearTarget() end
        else
            Aimbot.IsActive = true
        end
    end
end)

Aimbot.Connections.InputEnded = UserInputService.InputEnded:Connect(function(input)
    if not Aimbot.Settings.Toggle and (
        input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Aimbot.Settings.TriggerKey or
        input.UserInputType.Name == Aimbot.Settings.TriggerKey
    ) then
        Aimbot.IsActive = false
        ClearTarget()
    end
end)

--// Main Update

Aimbot.Connections.Render = RunService.RenderStepped:Connect(function()
    if Aimbot.Settings.Enabled then
        UpdateFOV()

        if Aimbot.IsActive then
            FindClosestPlayer()
            AimAtTarget()
        end
    else
        Aimbot.DrawingCircle.Visible = false
        Aimbot.Target = nil
    end
end)

--// Reset Function

function Aimbot.Reset()
    Aimbot.Settings.Enabled = false
    Aimbot.Target = nil
    ClearTarget()
end

--// Exit Function

function Aimbot.Destroy()
    for _, conn in pairs(Aimbot.Connections) do
        conn:Disconnect()
    end
    Aimbot.DrawingCircle:Remove()
end

return Aimbot
