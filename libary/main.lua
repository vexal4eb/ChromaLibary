local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

local Library = {}
Library.__index = Library

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local function create(class, props, parent)
	local object = Instance.new(class)
	for key, value in pairs(props) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function makeDraggable(handle, target)
	local dragging, startPos, startInput

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startPos = target.Position
			startInput = input.Position
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - startInput
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

function Library.new(title)
	local self = setmetatable({}, Window)
	self.tabs = {}
	self.connections = {}

	self.gui = create("ScreenGui", {
		Name = "Library",
		ResetOnSpawn = false,
	}, (gethui and gethui()) or game:GetService("CoreGui"))

	self.main = create("Frame", {
		Size = UDim2.fromOffset(500, 350),
		Position = UDim2.fromScale(0.3, 0.3),
		BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		BorderSizePixel = 0,
	}, self.gui)

	create("UICorner", { CornerRadius = UDim.new(0, 8) }, self.main)

	local topbar = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, self.main)

	self.tabBar = create("Frame", {
		Size = UDim2.new(0, 120, 1, -32),
		Position = UDim2.fromOffset(0, 32),
		BackgroundTransparency = 1,
	}, self.main)
	create("UIListLayout", { Padding = UDim.new(0, 4) }, self.tabBar)

	self.pages = create("Frame", {
		Size = UDim2.new(1, -130, 1, -40),
		Position = UDim2.fromOffset(126, 36),
		BackgroundTransparency = 1,
	}, self.main)

	makeDraggable(topbar, self.main)
	return self
end

function Window:Tab(name)
	local tab = setmetatable({}, Tab)

	tab.button = create("TextButton", {
		Size = UDim2.new(1, -8, 0, 28),
		BackgroundColor3 = Color3.fromRGB(35, 35, 42),
		Text = name,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.Gotham,
		TextSize = 13,
	}, self.tabBar)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, tab.button)

	tab.page = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Visible = false,
	}, self.pages)
	create("UIListLayout", { Padding = UDim.new(0, 6) }, tab.page)

	tab.button.MouseButton1Click:Connect(function()
		for _, other in ipairs(self.tabs) do
			other.page.Visible = false
		end
		tab.page.Visible = true
	end)

	table.insert(self.tabs, tab)
	if #self.tabs == 1 then
		tab.page.Visible = true
	end

	return tab
end

function Tab:Button(text, callback)
	local button = create("TextButton", {
		Size = UDim2.new(1, -8, 0, 30),
		BackgroundColor3 = Color3.fromRGB(45, 45, 55),
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.Gotham,
		TextSize = 13,
	}, self.page)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
	button.MouseButton1Click:Connect(callback)
end

function Tab:Toggle(text, default, callback)
	local state = default
	local button = create("TextButton", {
		Size = UDim2.new(1, -8, 0, 30),
		BackgroundColor3 = Color3.fromRGB(45, 45, 55),
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.Gotham,
		TextSize = 13,
	}, self.page)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, button)

	local indicator = create("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(1, -24, 0.5, -7),
		BackgroundColor3 = state and Color3.fromRGB(255, 140, 40) or Color3.fromRGB(80, 80, 90),
	}, button)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, indicator)

	button.MouseButton1Click:Connect(function()
		state = not state
		tweenService:Create(indicator, TweenInfo.new(0.15), {
			BackgroundColor3 = state and Color3.fromRGB(255, 140, 40) or Color3.fromRGB(80, 80, 90),
		}):Play()
		callback(state)
	end)
end

function Window:Destroy()
	self.gui:Destroy()
end

return Library
