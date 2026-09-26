	-- ============================================================
	--  Yousef|Aim Assist Anti-Ban
	-- ============================================================
-- Anti-bypass check.
if not _G["YOUSEF-OWNER-123"] then
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:Kick("Unauthorized execution. Please use the official key system.")
    end
    return
end
	-- Services.
	local playersService = game:GetService("Players")
	local runService = game:GetService("RunService")
	local userInputService = game:GetService("UserInputService")
	local workspaceService = game:GetService("Workspace")
	local coreGui = game:GetService("CoreGui")

	-- State.
	local localPlayer = playersService.LocalPlayer
	local currentCamera = workspaceService.CurrentCamera

	-- Settings.
	local settings = {
		enabled = true,
		teamCheck = true,
		wallCheck = true,
		targetLock = true,
		fovRadius = 120,
		smoothness = 0.35,
		headshot = false,
		toggleKey = Enum.KeyCode.P,
		menuKey = Enum.KeyCode.Period,
	}

	-- Runtime state.
	local aimActive = false
	local screenGui
	local lockedTarget = nil
	local selectionBox = nil
	local keybindListening = false

	---Clean up the selection box.
	local function clearSelectionBox()
		if selectionBox then
			selectionBox:Destroy()
			selectionBox = nil
		end
	end

	---Attach a selection box to the locked target.
	---@param character Model
	local function setSelectionBox(character)
		clearSelectionBox()
		if not character then return end
		local box = Instance.new("SelectionBox")
		box.Adornee = character
		box.LineThickness = 0.08
		box.Color3 = Color3.fromRGB(255, 60, 60)
		box.Transparency = 0.4
		box.SurfaceTransparency = 1
		box.Parent = coreGui
		selectionBox = box
	end

	---Return true if the player is on the same team.
	local function isTeammate(player)
		if not settings.teamCheck then return false end
		if not player.Team then return false end
		return player.Team == localPlayer.Team
	end

	---Return true if there is line of sight.
	local function hasLineOfSight(part, character)
		if not settings.wallCheck then return true end
		local origin = currentCamera.CFrame.Position
		local direction = part.Position - origin
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {localPlayer.Character, currentCamera}
		local hit = workspaceService:Raycast(origin, direction, rayParams)
		if not hit then return true end
		return hit.Instance:IsDescendantOf(character)
	end

	---Return the player whose target part projects closest to the cursor.
	local function getClosestPlayer()
		local closest, closestDist = nil, math.huge
		local mousePos = userInputService:GetMouseLocation()

		for _, player in ipairs(playersService:GetPlayers()) do
			if player == localPlayer then continue end
			if isTeammate(player) then continue end

			local character = player.Character
			if not character then continue end

			local part = character:FindFirstChild(settings.headshot and "Head" or "UpperTorso")
			local humanoid = character:FindFirstChild("Humanoid")
			if not (part and humanoid and humanoid.Health > 0) then continue end

			if not hasLineOfSight(part, character) then continue end

			local screenPos, onScreen = currentCamera:WorldToViewportPoint(part.Position)
			if not onScreen then continue end

			local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
			if dist <= settings.fovRadius and dist < closestDist then
				closest = player
				closestDist = dist
			end
		end

		return closest, closestDist
	end

	-- Aim loop.
	runService.RenderStepped:Connect(function()
		if not settings.enabled then
			clearSelectionBox()
			return
		end

		if not aimActive then return end

		if lockedTarget and settings.targetLock then
			local character = lockedTarget.Character
			local part = character and character:FindFirstChild(settings.headshot and "Head" or "UpperTorso")
			local humanoid = character and character:FindFirstChild("Humanoid")

			if not (part and humanoid and humanoid.Health > 0) or isTeammate(lockedTarget) then
				lockedTarget = nil
				clearSelectionBox()
			end
		end

		if not lockedTarget then
			local found = getClosestPlayer()
			if found then
				lockedTarget = found
				if screenGui and screenGui.Enabled then
					setSelectionBox(found.Character)
				end
			end
		end

		if not lockedTarget then return end

		local character = lockedTarget.Character
		if not character then return end

		local part = character:FindFirstChild(settings.headshot and "Head" or "UpperTorso")
		if not part then return end

		local screenPos, onScreen = currentCamera:WorldToViewportPoint(part.Position)
		if not onScreen then return end

		local mousePos = userInputService:GetMouseLocation()
		local deltaX = screenPos.X - mousePos.X
		local deltaY = screenPos.Y - mousePos.Y
		local moveX = deltaX * settings.smoothness
		local moveY = deltaY * settings.smoothness

			-- Deadzone: stop twitching when already on target.
	if settings.smoothness >= 0.99 then
		-- Max smoothness = instant snap.
		if math.abs(moveX) < 0.01 and math.abs(moveY) < 0.01 then return end
	else
		if math.abs(moveX) < 0.5 and math.abs(moveY) < 0.5 then return end
	end

		local jitterX = (math.random() - 0.5) * 0.6
		local jitterY = (math.random() - 0.5) * 0.6
		mousemoverel(moveX + jitterX, moveY + jitterY)
	end)

	-- MENU UI.
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AimAssistMenu"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999999
	screenGui.Parent = coreGui

	local fovCircle = Instance.new("Frame")
	fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	fovCircle.BackgroundTransparency = 1
	fovCircle.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
	fovCircle.ZIndex = 1
	fovCircle.Parent = screenGui

	local fovCircleCorner = Instance.new("UICorner")
	fovCircleCorner.CornerRadius = UDim.new(1, 0)
	fovCircleCorner.Parent = fovCircle

	local fovCircleStroke = Instance.new("UIStroke")
	fovCircleStroke.Thickness = 1.5
	fovCircleStroke.Color = Color3.fromRGB(255, 255, 255)
	fovCircleStroke.Transparency = 0.5
	fovCircleStroke.Parent = fovCircle

	runService.RenderStepped:Connect(function()
		local mousePos = userInputService:GetMouseLocation()
		fovCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
		fovCircle.Size = UDim2.new(0, settings.fovRadius * 2, 0, settings.fovRadius * 2)
	end)

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 230, 0, 466)
	mainFrame.Position = UDim2.new(0, 20, 0, 20)
	mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = false
	mainFrame.ZIndex = 2
	mainFrame.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = mainFrame

	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 34)
	titleBar.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
	titleBar.BorderSizePixel = 0
	titleBar.Active = true
	titleBar.ZIndex = 3
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Yousef|Aim Assist Anti-Ban"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 15
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 4
	title.Parent = titleBar

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Size = UDim2.new(0, 24, 0, 24)
	minimizeButton.Position = UDim2.new(1, -30, 0.5, -12)
	minimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	minimizeButton.BorderSizePixel = 0
	minimizeButton.Text = "—"
	minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	minimizeButton.TextSize = 14
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.ZIndex = 4
	minimizeButton.Parent = titleBar

	local minimizeCorner = Instance.new("UICorner")
	minimizeCorner.CornerRadius = UDim.new(0, 6)
	minimizeCorner.Parent = minimizeButton

	local contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(1, 0, 1, -34)
	contentFrame.Position = UDim2.new(0, 0, 0, 34)
	contentFrame.BackgroundTransparency = 1
	contentFrame.ZIndex = 2
	contentFrame.Parent = mainFrame

	local minimized = false
	minimizeButton.MouseButton1Click:Connect(function()
		minimized = not minimized
		contentFrame.Visible = not minimized
		mainFrame.Size = minimized and UDim2.new(0, 230, 0, 34) or UDim2.new(0, 230, 0, 466)
		minimizeButton.Text = minimized and "+" or "—"
	end)

	local dragging = false
	local dragStart, startPos

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
		end
	end)

	userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	local function createToggle(name, order, getter, setter)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -20, 0, 28)
		row.Position = UDim2.new(0, 10, 0, 10 + (order - 1) * 32)
		row.BackgroundTransparency = 1
		row.ZIndex = 2
		row.Parent = contentFrame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.6, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.fromRGB(220, 220, 220)
		label.TextSize = 13
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 3
		label.Parent = row

		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 56, 0, 22)
		button.Position = UDim2.new(1, -56, 0.5, -11)
		button.BackgroundColor3 = getter() and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 60, 70)
		button.BorderSizePixel = 0
		button.Text = getter() and "ON" or "OFF"
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 12
		button.Font = Enum.Font.GothamBold
		button.ZIndex = 3
		button.Parent = row

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button

		button.MouseButton1Click:Connect(function()
			setter(not getter())
			local state = getter()
			button.BackgroundColor3 = state and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 60, 70)
			button.Text = state and "ON" or "OFF"
		end)
	end

	createToggle("Enabled", 1, function() return settings.enabled end, function(v) settings.enabled = v end)
	createToggle("Team Check", 2, function() return settings.teamCheck end, function(v) settings.teamCheck = v end)
	createToggle("Wall Check", 3, function() return settings.wallCheck end, function(v) settings.wallCheck = v end)
	createToggle("Target Lock", 4, function() return settings.targetLock end, function(v) settings.targetLock = v end)

	local function createSlider(name, order, minValue, maxValue, getter, setter, format)
		local baseY = 10 + (order - 1) * 32

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 0, 18)
		label.Position = UDim2.new(0, 10, 0, baseY)
		label.BackgroundTransparency = 1
		label.Text = name .. ": " .. (format and format(getter()) or getter())
		label.TextColor3 = Color3.fromRGB(220, 220, 220)
		label.TextSize = 13
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 3
		label.Parent = contentFrame

		local slider = Instance.new("Frame")
		slider.Size = UDim2.new(1, -20, 0, 6)
		slider.Position = UDim2.new(0, 10, 0, baseY + 20)
		slider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		slider.BorderSizePixel = 0
		slider.ZIndex = 3
		slider.Parent = contentFrame

		local sliderCorner = Instance.new("UICorner")
		sliderCorner.CornerRadius = UDim.new(1, 0)
		sliderCorner.Parent = slider

		local fill = Instance.new("Frame")
		local initialAlpha = (getter() - minValue) / (maxValue - minValue)
		fill.Size = UDim2.new(initialAlpha, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(80, 140, 220)
		fill.BorderSizePixel = 0
		fill.ZIndex = 4
		fill.Parent = slider

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = fill

		local draggingSlider = false

		slider.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				draggingSlider = true
			end
		end)

		userInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				draggingSlider = false
			end
		end)

		userInputService.InputChanged:Connect(function(input)
			if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
				local alpha = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
				local value = minValue + (maxValue - minValue) * alpha
				value = math.floor(value * 100) / 100
				setter(value)
				fill.Size = UDim2.new(alpha, 0, 1, 0)
				label.Text = name .. ": " .. (format and format(value) or value)
			end
		end)
	end

	createSlider("FOV", 5, 20, 400, function() return settings.fovRadius end, function(v) settings.fovRadius = v end)
	createSlider("Smoothness", 6, 0.05, 1, function() return settings.smoothness end, function(v) settings.smoothness = v end)

	local keybindRow = Instance.new("Frame")
	keybindRow.Size = UDim2.new(1, -20, 0, 28)
	keybindRow.Position = UDim2.new(0, 10, 0, 10 + 6 * 32)
	keybindRow.BackgroundTransparency = 1
	keybindRow.ZIndex = 2
	keybindRow.Parent = contentFrame

	local keybindLabel = Instance.new("TextLabel")
	keybindLabel.Size = UDim2.new(0.6, 0, 1, 0)
	keybindLabel.BackgroundTransparency = 1
	keybindLabel.Text = "Off Aim Assist"
	keybindLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	keybindLabel.TextSize = 13
	keybindLabel.Font = Enum.Font.Gotham
	keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
	keybindLabel.ZIndex = 3
	keybindLabel.Parent = keybindRow

	local keybindButton = Instance.new("TextButton")
	keybindButton.Size = UDim2.new(0, 80, 0, 22)
	keybindButton.Position = UDim2.new(1, -80, 0.5, -11)
	keybindButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	keybindButton.BorderSizePixel = 0
	keybindButton.Text = settings.toggleKey.Name
	keybindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	keybindButton.TextSize = 12
	keybindButton.Font = Enum.Font.GothamBold
	keybindButton.ZIndex = 3
	keybindButton.Parent = keybindRow

	local keybindCorner = Instance.new("UICorner")
	keybindCorner.CornerRadius = UDim.new(0, 6)
	keybindCorner.Parent = keybindButton

	keybindButton.MouseButton1Click:Connect(function()
		keybindListening = true
		keybindButton.Text = "..."
	end)
-- Streamer notice.
local noticeRow = Instance.new("Frame")
noticeRow.Size = UDim2.new(1, -20, 0, 34)
noticeRow.Position = UDim2.new(0, 10, 0, 10 + 8 * 32)
noticeRow.BackgroundTransparency = 1
noticeRow.ZIndex = 2
noticeRow.Parent = contentFrame

local noticeLabel = Instance.new("TextLabel")
noticeLabel.Size = UDim2.new(1, 0, 1, 0)
noticeLabel.BackgroundTransparency = 1
noticeLabel.Text = "Press (.) to hide. Silent Aim Assist - safe for streamers"
noticeLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
noticeLabel.TextSize = 10
noticeLabel.Font = Enum.Font.Gotham
noticeLabel.TextWrapped = true
noticeLabel.TextXAlignment = Enum.TextXAlignment.Left
noticeLabel.TextYAlignment = Enum.TextYAlignment.Top
noticeLabel.ZIndex = 3
noticeLabel.Parent = noticeRow

	local headshotRow = Instance.new("Frame")
	headshotRow.Size = UDim2.new(1, -20, 0, 28)
	headshotRow.Position = UDim2.new(0, 10, 0, 10 + 9 * 32)
	headshotRow.BackgroundTransparency = 1
	headshotRow.ZIndex = 2
	headshotRow.Parent = contentFrame

	local headshotLabel = Instance.new("TextLabel")
	headshotLabel.Size = UDim2.new(0.6, 0, 1, 0)
	headshotLabel.BackgroundTransparency = 1
	headshotLabel.Text = "Headshot"
	headshotLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	headshotLabel.TextSize = 13
	headshotLabel.Font = Enum.Font.Gotham
	headshotLabel.TextXAlignment = Enum.TextXAlignment.Left
	headshotLabel.ZIndex = 3
	headshotLabel.Parent = headshotRow

	local headshotButton = Instance.new("TextButton")
	headshotButton.Size = UDim2.new(0, 56, 0, 22)
	headshotButton.Position = UDim2.new(1, -56, 0.5, -11)
	headshotButton.BackgroundColor3 = settings.headshot and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 60, 70)
	headshotButton.BorderSizePixel = 0
	headshotButton.Text = settings.headshot and "ON" or "OFF"
	headshotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	headshotButton.TextSize = 12
	headshotButton.Font = Enum.Font.GothamBold
	headshotButton.ZIndex = 3
	headshotButton.Parent = headshotRow

	local headshotCorner = Instance.new("UICorner")
	headshotCorner.CornerRadius = UDim.new(0, 6)
	headshotCorner.Parent = headshotButton

	headshotButton.MouseButton1Click:Connect(function()
		settings.headshot = not settings.headshot
		headshotButton.BackgroundColor3 = settings.headshot and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(60, 60, 70)
		headshotButton.Text = settings.headshot and "ON" or "OFF"
	end)

	userInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if screenGui and input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mousePos = userInputService:GetMouseLocation()
		local guiObjects = localPlayer.PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
		for _, obj in ipairs(guiObjects) do
			if obj:IsDescendantOf(screenGui) then return end
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton2 then
		aimActive = true
	end

	if input.KeyCode == settings.toggleKey and not keybindListening then
		settings.enabled = not settings.enabled
	end

	if input.KeyCode == settings.menuKey and not keybindListening then
		if screenGui then
			screenGui.Enabled = not screenGui.Enabled
		end
		-- Hidden mode: patayin din yung FOV circle at red selection box.
		if fovCircle then
			fovCircle.Visible = screenGui.Enabled
		end
		if not screenGui.Enabled then
			clearSelectionBox()
		end
	end
end)

	userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2 then
			if not userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
				and not userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				aimActive = false
				lockedTarget = nil
				clearSelectionBox()
			end
		end
	end)
