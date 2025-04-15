-- UniversalCombatModule.lua
local Module = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

-- Essentials
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
Module.AimbotEnabled = true
Module.TeamCheck = true
Module.FOVRadius = 150
Module.Sensitivity = 0.2
Module.AimPart = "Head"
Module.FirstPersonLock = false

Module.ESPEnabled = true
Module.NoclipEnabled = true
Module.WallbangEnabled = true

-- Customizable Hitbox Size (50, 50, 50 by default for key parts)
Module.CustomHitboxSizes = {
    Head = Vector3.new(50, 50, 50),
    UpperTorso = Vector3.new(50, 50, 50),
    LowerTorso = Vector3.new(50, 50, 50),
    HumanoidRootPart = Vector3.new(50, 50, 50)
}

-- Internals
local CurrentTarget = nil
local AppliedESP = {}

-- FOV Circle (visual)
local circle = Drawing.new("Circle")
circle.Transparency = 0.4
circle.Thickness = 2
circle.NumSides = 100
circle.Radius = Module.FOVRadius
circle.Color = Color3.fromRGB(255, 255, 255)
circle.Visible = true
circle.Filled = false

-- Get Closest Target within FOV
function Module.GetClosestTarget()
	local closest = nil
	local shortestDist = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Module.AimPart) then
			if Module.TeamCheck and player.Team == LocalPlayer.Team then continue end

			local part = player.Character[Module.AimPart]
			local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
			local mousePos = UIS:GetMouseLocation()
			local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude

			if onScreen and dist < shortestDist and dist < Module.FOVRadius then
				closest = player
				shortestDist = dist
			end
		end
	end

	return closest
end

-- Apply Smooth Lock
function Module.ApplySmoothLock(targetPos)
	local dir = (targetPos - Camera.CFrame.Position).Unit
	local smoothed = Camera.CFrame.LookVector:Lerp(dir, Module.Sensitivity)
	Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + smoothed)
end

-- Update FOV Circle
function Module.UpdateFOV()
	local mousePos = UIS:GetMouseLocation()
	circle.Position = Vector2.new(mousePos.X, mousePos.Y + 36)
	circle.Radius = Module.FOVRadius
	circle.Visible = Module.AimbotEnabled
end

-- ESP with Highlight
function Module.ApplyESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and not AppliedESP[player] then
			if Module.TeamCheck and player.Team == LocalPlayer.Team then continue end

			local highlight = Instance.new("Highlight")
			highlight.Name = "ESPHighlight"
			highlight.FillColor = Color3.fromRGB(255, 0, 0)
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			highlight.FillTransparency = 0.4
			highlight.OutlineTransparency = 0.1
			highlight.Adornee = player.Character
			highlight.Parent = player.Character

			AppliedESP[player] = highlight
		end
	end
end

-- Expand Hitboxes
function Module.ExpandHitboxes()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			if Module.TeamCheck and player.Team == LocalPlayer.Team then continue end

			for partName, newSize in pairs(Module.CustomHitboxSizes) do
				local part = player.Character:FindFirstChild(partName)
				if part and part:IsA("BasePart") then
					part.Size = newSize
					part.Material = Enum.Material.ForceField
					part.Transparency = 0.5
					part.CanCollide = false
				end
			end
		end
	end
end

-- Noclip Local
function Module.ApplyNoclip()
	if not LocalPlayer.Character then return end
	for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

-- Wallbang Raycast
function Module.Raycast(origin, direction, params)
	if not Module.WallbangEnabled then
		return Workspace:Raycast(origin, direction, params)
	end

	local result = nil
	local tries = 0
	local newOrigin = origin

	repeat
		result = Workspace:Raycast(newOrigin, direction, params)
		if result then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			local isPlayer = model and Players:GetPlayerFromCharacter(model)

			if isPlayer then
				return result
			else
				newOrigin = result.Position + direction.Unit * 1
			end
		end
		tries += 1
	until not result or tries > 10

	return nil
end

-- First Person Lock (optional toggle)
function Module.LockFirstPerson()
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
		Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
		Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end
end

-- Main Update Loop
RunService.RenderStepped:Connect(function()
	if Module.AimbotEnabled then
		CurrentTarget = Module.GetClosestTarget()
		if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(Module.AimPart) then
			Module.ApplySmoothLock(CurrentTarget.Character[Module.AimPart].Position)
		end
	end

	if Module.ESPEnabled then
		Module.ApplyESP()
	end

	if Module.NoclipEnabled then
		Module.ApplyNoclip()
	end

	Module.ExpandHitboxes()
	Module.UpdateFOV()

	if Module.FirstPersonLock then
		Module.LockFirstPerson()
	end
end)

return Module
