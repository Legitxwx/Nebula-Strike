-- NebulaStrike | Aimbot + Hitbox + FOV Control Module
local NebulaStrike = {}

NebulaStrike.Settings = {
    HitboxSize = 50,
    HitboxColorName = "White",
    TargetPart = "Head",
    AimbotFOV = 150,
    ColorMap = {
        ["White"] = Color3.fromRGB(255, 255, 255),
        ["Red"] = Color3.fromRGB(255, 0, 0),
        ["Blue"] = Color3.fromRGB(0, 0, 255),
        ["Pink"] = Color3.fromRGB(255, 105, 180),
        ["Dark"] = Color3.fromRGB(30, 30, 30),
        ["Green"] = Color3.fromRGB(0, 255, 0)
    }
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local AimbotConnection
local CurrentTarget = nil

-- Hitbox Setup
function NebulaStrike:ApplyHitbox()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(self.Settings.TargetPart) then
            local part = player.Character[self.Settings.TargetPart]
            part.Size = Vector3.new(self.Settings.HitboxSize, self.Settings.HitboxSize, self.Settings.HitboxSize)
            part.Material = Enum.Material.ForceField
            part.Transparency = 0.5
            part.Color = self.Settings.ColorMap[self.Settings.HitboxColorName] or Color3.fromRGB(255, 255, 255)
            part.CanCollide = false
        end
    end
end

-- Remove Hitbox from Defeated
local function RemoveHitbox(player)
    if player.Character and player.Character:FindFirstChild(NebulaStrike.Settings.TargetPart) then
        local part = player.Character[NebulaStrike.Settings.TargetPart]
        part.Size = Vector3.new(1, 1, 1)
        part.Transparency = 0
        part.Material = Enum.Material.Plastic
    end
end

-- Find Nearest Enemy in FOV
local function GetClosestTarget()
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character and player.Character:FindFirstChild(NebulaStrike.Settings.TargetPart) then
            local part = player.Character[NebulaStrike.Settings.TargetPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude

            if onScreen and dist < NebulaStrike.Settings.AimbotFOV and dist < closestDist then
                closest = player
                closestDist = dist
            end
        end
    end
    return closest
end

-- Aimbot + Shoot Logic
local function StartAimbotLoop()
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if not CurrentTarget or not CurrentTarget.Character or not CurrentTarget.Character:FindFirstChild("Humanoid") or CurrentTarget.Character:FindFirstChild("Humanoid").Health <= 0 then
            if CurrentTarget then
                RemoveHitbox(CurrentTarget)
            end
            CurrentTarget = GetClosestTarget()
        end

        if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(NebulaStrike.Settings.TargetPart) then
            local targetPart = CurrentTarget.Character[NebulaStrike.Settings.TargetPart]
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        end
    end)
end

function NebulaStrike:ToggleAimbot(state)
    if state then
        -- Force first person
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        StartAimbotLoop()

        -- Input hook to redirect mouse to FOV target
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and CurrentTarget and CurrentTarget.Character then
                local target = CurrentTarget.Character:FindFirstChild(self.Settings.TargetPart)
                if target then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
                end
            end
        end)

    else
        -- Reset to third person
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        if AimbotConnection then AimbotConnection:Disconnect() end
        if CurrentTarget then
            RemoveHitbox(CurrentTarget)
            CurrentTarget = nil
        end
    end
end

-- Config Setters
function NebulaStrike:SetHitboxSize(size)
    self.Settings.HitboxSize = tonumber(size) or 50
end

function NebulaStrike:SetHitboxColorName(color)
    if self.Settings.ColorMap[color] then
        self.Settings.HitboxColorName = color
    end
end

function NebulaStrike:SetTargetPart(part)
    self.Settings.TargetPart = part
end

function NebulaStrike:SetAimbotFOV(value)
    self.Settings.AimbotFOV = tonumber(value) or 150
end

return NebulaStrike
