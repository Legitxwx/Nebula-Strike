-- AimbotModule.lua
local Aimbot = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- Local Player
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Settings
Aimbot.Enabled = true
Aimbot.CancelLock = false
Aimbot.TeamCheck = true
Aimbot.FirstPersonMode = false -- Default: false (3rd person)
Aimbot.FOV = 150
Aimbot.FOVCircleColor = Color3.fromRGB(255, 0, 0)
Aimbot.TargetPart = "Head"

-- Internal State
local currentTarget = nil

-- Drawing FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Aimbot.FOVCircleColor
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Radius = Aimbot.FOV
FOVCircle.Transparency = 1
FOVCircle.Visible = true

-- Get if a player is a valid enemy
local function IsEnemy(player)
	if Aimbot.TeamCheck and player.Team == LocalPlayer.Team then
		return false
	end
	return true
end

-- Get the closest enemy within FOV
function Aimbot.GetClosestTarget()
	local closestPlayer = nil
	local shortestDistance = Aimbot.FOV

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and IsEnemy(player) then
			local targetPart = player.Character:FindFirstChild(Aimbot.TargetPart)
			if targetPart then
				local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
				if onScreen then
					local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
					if dist < shortestDistance then
						shortestDistance = dist
						closestPlayer = player
					end
				end
			end
		end
	end

	return closestPlayer
end

-- Soft lock camera on enemy (used in 3rd-person)
function Aimbot.AimAtTarget(target)
	if not target or not target.Character then return end
	local part = target.Character:FindFirstChild(Aimbot.TargetPart)
	if part then
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
	end
end

-- Adjust raycast direction
function Aimbot.GetAimDirection(defaultDirection)
	if Aimbot.Enabled and not Aimbot.CancelLock and currentTarget and currentTarget.Character then
		local part = currentTarget.Character:FindFirstChild(Aimbot.TargetPart)
		if part then
			return (part.Position - Camera.CFrame.Position).Unit
		end
	end

	-- First-person: always shoot straight
	if Aimbot.FirstPersonMode then
		return Camera.CFrame.LookVector
	end

	return defaultDirection
end

-- Toggle first/third person
function Aimbot.ToggleMode()
	Aimbot.FirstPersonMode = not Aimbot.FirstPersonMode
end

-- Continuous update
RunService.RenderStepped:Connect(function()
	FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
	FOVCircle.Visible = Aimbot.Enabled

	-- Handle camera mode
	if Aimbot.FirstPersonMode then
		LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
		Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or nil
		Camera.CameraType = Enum.CameraType.Custom
		UIS.MouseIconEnabled = true
	else
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
		Camera.CameraType = Enum.CameraType.Custom
		UIS.MouseIconEnabled = true
	end

	-- Get target
	if Aimbot.Enabled and not Aimbot.CancelLock then
		currentTarget = Aimbot.GetClosestTarget()
	else
		currentTarget = nil
	end

	-- Lock to target (only in 3rd person)
	if currentTarget and not Aimbot.FirstPersonMode then
		Aimbot.AimAtTarget(currentTarget)
	end
end)

return Aimbot
