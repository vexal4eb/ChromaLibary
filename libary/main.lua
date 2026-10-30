local playersService = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local httpService = game:GetService("HttpService")
local lightingService = game:GetService("Lighting")
local guiService = game:GetService("GuiService")
local coreGui = game:GetService("CoreGui")

local localPlayer = playersService.LocalPlayer

local Library = {}
Library.__index = Library

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local motion = true

local themes = {
	Dark = {
		Background = Color3.fromRGB(14, 14, 18),
		Surface = Color3.fromRGB(20, 20, 26),
		Element = Color3.fromRGB(28, 28, 36),
		Hover = Color3.fromRGB(38, 38, 48),
		Stroke = Color3.fromRGB(46, 46, 58),
		Text = Color3.fromRGB(236, 236, 242),
		SubText = Color3.fromRGB(140, 140, 158),
		Accent = Color3.fromRGB(255, 140, 40),
	},
	Midnight = {
		Background = Color3.fromRGB(10, 12, 22),
		Surface = Color3.fromRGB(15, 18, 32),
		Element = Color3.fromRGB(22, 26, 44),
		Hover = Color3.fromRGB(31, 36, 60),
		Stroke = Color3.fromRGB(40, 46, 76),
		Text = Color3.fromRGB(230, 234, 250),
		SubText = Color3.fromRGB(130, 140, 175),
		Accent = Color3.fromRGB(96, 140, 255),
	},
	Ocean = {
		Background = Color3.fromRGB(9, 18, 22),
		Surface = Color3.fromRGB(13, 26, 32),
		Element = Color3.fromRGB(19, 36, 44),
		Hover = Color3.fromRGB(27, 48, 58),
		Stroke = Color3.fromRGB(36, 62, 74),
		Text = Color3.fromRGB(226, 244, 248),
		SubText = Color3.fromRGB(125, 162, 172),
		Accent = Color3.fromRGB(40, 200, 190),
	},
	Rose = {
		Background = Color3.fromRGB(20, 12, 16),
		Surface = Color3.fromRGB(28, 17, 22),
		Element = Color3.fromRGB(38, 24, 31),
		Hover = Color3.fromRGB(50, 32, 41),
		Stroke = Color3.fromRGB(66, 42, 54),
		Text = Color3.fromRGB(248, 232, 238),
		SubText = Color3.fromRGB(170, 134, 148),
		Accent = Color3.fromRGB(255, 92, 140),
	},
	Violet = {
		Background = Color3.fromRGB(15, 12, 22),
		Surface = Color3.fromRGB(21, 17, 31),
		Element = Color3.fromRGB(30, 25, 44),
		Hover = Color3.fromRGB(41, 35, 59),
		Stroke = Color3.fromRGB(56, 48, 80),
		Text = Color3.fromRGB(238, 232, 250),
		SubText = Color3.fromRGB(150, 140, 176),
		Accent = Color3.fromRGB(170, 110, 255),
	},
}

local themeOrder = { "Dark", "Midnight", "Ocean", "Rose", "Violet" }

local noteColors = {
	Success = Color3.fromRGB(80, 200, 120),
	Warning = Color3.fromRGB(240, 190, 70),
	Error = Color3.fromRGB(235, 85, 85),
}

Library.Themes = themes

local function create(class, props, parent)
	local object = Instance.new(class)
	for key, value in pairs(props) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function pill(parent)
	return create("UICorner", { CornerRadius = UDim.new(1, 0) }, parent)
end

local function tween(object, duration, props, style, direction)
	if not motion then
		for key, value in pairs(props) do
			object[key] = value
		end
		return
	end

	local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
	tweenService:Create(object, info, props):Play()
end

local function apply(object, props, animate, duration)
	if animate then
		tween(object, duration or 0.2, props)
		return
	end

	for key, value in pairs(props) do
		object[key] = value
	end
end

local function decimals(step)
	local fraction = tostring(step):match("%.(%d+)")
	return fraction and #fraction or 0
end

local function snap(value, min, step, places)
	local snapped = math.floor((value - min) / step + 0.5) * step + min
	return tonumber(string.format("%." .. places .. "f", snapped))
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function pointer(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		local inset = guiService:GetGuiInset()
		return Vector2.new(input.Position.X, input.Position.Y) + inset
	end

	return userInputService:GetMouseLocation()
end

local function encode(value)
	local kind = typeof(value)

	if kind == "Color3" then
		return { type = "Color3", value = { value.R, value.G, value.B } }
	elseif kind == "EnumItem" then
		return { type = "KeyCode", value = value.Name }
	end

	return { type = kind, value = value }
end

local function decode(entry)
	if entry.type == "Color3" then
		return Color3.new(entry.value[1], entry.value[2], entry.value[3])
	elseif entry.type == "KeyCode" then
		return Enum.KeyCode[entry.value]
	end

	return entry.value
end

function Window:_connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.connections, connection)
	return connection
end

function Window:_drag(target, update, finished)
	local active = false

	self:_connect(target.InputBegan, function(input)
		if isPress(input) then
			active = true
			update(pointer(input), true)
		end
	end)

	self:_connect(userInputService.InputChanged, function(input)
		if active and isMove(input) then
			update(pointer(input), false)
		end
	end)

	self:_connect(userInputService.InputEnded, function(input)
		if active and isPress(input) then
			active = false
			if finished then
				finished()
			end
		end
	end)
end

function Window:bind(object, property, key)
	table.insert(self.themed, { object, property, key })
	object[property] = self.theme[key]
end

function Window:surface(object, base)
	table.insert(self.surfaces, { object, base })
	object.BackgroundTransparency = base + (1 - base) * self.transparency
end

function Window:_text(parent, props, key)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	for property, value in pairs(props) do
		label[property] = value
	end

	label.Parent = parent
	self:bind(label, "TextColor3", key or "Text")
	return label
end

function Window:_hover(row, target)
	target.MouseEnter:Connect(function()
		tween(row, 0.15, { BackgroundColor3 = self.theme.Hover })
	end)

	target.MouseLeave:Connect(function()
		tween(row, 0.15, { BackgroundColor3 = self.theme.Element })
	end)
end

function Window:_fire(callback, ...)
	if not callback then
		return
	end

	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(callback, table.unpack(args, 1, args.n))
		if not ok then
			warn("[Chroma] " .. tostring(err))
		end
	end)
end

function Window:_flag(flag, value, setter)
	if not flag then
		return
	end

	self.flags[flag] = value
	self.setters[flag] = setter
end

function Window:_changed(flag, value)
	if flag then
		self.flags[flag] = value
	end
end

function Window:_applyTheme(animate)
	for index = #self.themed, 1, -1 do
		local entry = self.themed[index]
		if entry[1].Parent then
			apply(entry[1], { [entry[2]] = self.theme[entry[3]] }, animate, 0.3)
		else
			table.remove(self.themed, index)
		end
	end

	for _, refresh in ipairs(self.refreshers) do
		refresh(animate)
	end
end

function Window:SetTheme(name)
	local source = themes[name]
	if not source then
		return
	end

	self.themeName = name
	self.theme = table.clone(source)
	self:_applyTheme(true)
end

function Window:SetAccent(color)
	self.theme.Accent = color
	self:_applyTheme(true)
end

function Window:SetTransparency(value, animate)
	self.transparency = math.clamp(value, 0, 0.85)

	for index = #self.surfaces, 1, -1 do
		local entry = self.surfaces[index]
		if entry[1].Parent then
			local goal = entry[2] + (1 - entry[2]) * self.transparency
			apply(entry[1], { BackgroundTransparency = goal }, animate, 0.2)
		else
			table.remove(self.surfaces, index)
		end
	end
end

function Window:SetScale(scale)
	self.userScale = math.clamp(scale, 0.5, 1.5)
	self.uiScale.Scale = self.userScale * self.animValue.Value
end

function Window:SetBlur(enabled)
	self.blurEnabled = enabled

	if enabled and not self.blur then
		self.blur = create("BlurEffect", { Name = "ChromaBlur", Size = 0 }, lightingService)
	end

	self:_updateBlur()
end

function Window:_updateBlur()
	if self.blur then
		local goal = (self.blurEnabled and self.visible) and 18 or 0
		tween(self.blur, 0.3, { Size = goal })
	end
end

function Window:_animate(show)
	if show then
		self.holder.Visible = true
		tween(self.main, 0.4, { GroupTransparency = 0 })
		tween(self.outline, 0.4, { Transparency = 0.15 })
		tween(self.animValue, 0.45, { Value = 1 })
		return
	end

	tween(self.main, 0.25, { GroupTransparency = 1 })
	tween(self.outline, 0.25, { Transparency = 1 })
	tween(self.animValue, 0.3, { Value = 0.92 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

	task.delay(0.3, function()
		if not self.visible and self.holder.Parent then
			self.holder.Visible = false
		end
	end)
end

function Window:Toggle(state)
	if state == nil then
		state = not self.visible
	end

	self.visible = state
	self:_animate(state)
	self:_updateBlur()
end

function Window:Minimize(state)
	if state == nil then
		state = not self.minimized
	end

	self.minimized = state

	local goal = state and UDim2.new(self.size.X.Scale, self.size.X.Offset, 0, 42) or self.size
	tween(self.holder, 0.35, { Size = goal })
end

function Window:Notify(options)
	options = options or {}

	local duration = options.Duration or 4
	local kind = options.Type or "Info"
	local tint = noteColors[kind]

	self.noteCount = self.noteCount + 1

	local wrapper = create("Frame", {
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundTransparency = 1,
		LayoutOrder = self.noteCount,
	}, self.notifications)

	local card = create("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 64),
		Position = UDim2.fromOffset(300, 0),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		GroupTransparency = 1,
	}, wrapper)
	corner(card, 8)
	self:bind(card, "BackgroundColor3", "Surface")

	local edge = create("UIStroke", { Thickness = 1, Transparency = 0.3 }, card)
	self:bind(edge, "Color", "Stroke")

	local strip = create("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BorderSizePixel = 0,
	}, card)

	local progress = create("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BorderSizePixel = 0,
	}, card)

	if tint then
		strip.BackgroundColor3 = tint
		progress.BackgroundColor3 = tint
	else
		self:bind(strip, "BackgroundColor3", "Accent")
		self:bind(progress, "BackgroundColor3", "Accent")
	end

	self:_text(card, {
		Size = UDim2.new(1, -28, 0, 18),
		Position = UDim2.fromOffset(16, 8),
		Text = options.Title or "Notification",
		Font = Enum.Font.GothamBold,
	})

	self:_text(card, {
		Size = UDim2.new(1, -28, 0, 28),
		Position = UDim2.fromOffset(16, 28),
		Text = options.Content or "",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, "SubText")

	local button = create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
	}, card)

	local closed = false
	local function dismiss()
		if closed then
			return
		end

		closed = true
		tween(card, 0.3, { Position = UDim2.fromOffset(300, 0), GroupTransparency = 1 })

		task.delay(0.3, function()
			if wrapper.Parent then
				tween(wrapper, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
				task.delay(0.25, function()
					wrapper:Destroy()
				end)
			end
		end)
	end

	button.MouseButton1Click:Connect(dismiss)

	tween(card, 0.45, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 })
	tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
	task.delay(duration, dismiss)
end

function Window:_paintTab(tab, active, animate)
	apply(tab.label, { TextColor3 = active and self.theme.Text or self.theme.SubText }, animate)
	apply(tab.button, { BackgroundTransparency = active and 0.4 or 1 }, animate)
end

function Window:_select(tab)
	if self.current == tab then
		return
	end

	local previous = self.current
	self.current = tab

	local goal = UDim2.fromOffset(0, 16 + (tab.index - 1) * 36)

	if previous then
		previous.page.Visible = false
		previous.page.GroupTransparency = 1
		self:_paintTab(previous, false, true)
		tween(self.indicator, 0.35, { Position = goal })
	else
		self.indicator.Position = goal
		self.indicator.Visible = true
	end

	self:_paintTab(tab, true, true)

	tab.page.Position = UDim2.fromOffset(0, 14)
	tab.page.Visible = true
	tween(tab.page, 0.35, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
end

function Window:Tab(name)
	local tab = setmetatable({}, Tab)
	tab.window = self
	tab.name = name
	tab.index = #self.tabs + 1
	tab.order = 0

	tab.button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = tab.index,
	}, self.tabList)
	corner(tab.button, 7)
	self:bind(tab.button, "BackgroundColor3", "Element")

	tab.label = create("TextLabel", {
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = self.theme.SubText,
	}, tab.button)

	tab.page = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
	}, self.pages)

	tab.scroll = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, tab.page)
	self:bind(tab.scroll, "ScrollBarImageColor3", "Accent")

	create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 14),
	}, tab.scroll)

	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tab.scroll)

	tab.button.MouseEnter:Connect(function()
		if self.current ~= tab then
			tween(tab.button, 0.15, { BackgroundTransparency = 0.75 })
			tween(tab.label, 0.15, { TextColor3 = self.theme.Text })
		end
	end)

	tab.button.MouseLeave:Connect(function()
		if self.current ~= tab then
			self:_paintTab(tab, false, true)
		end
	end)

	tab.button.MouseButton1Click:Connect(function()
		self:_select(tab)
	end)

	table.insert(self.refreshers, function(animate)
		self:_paintTab(tab, self.current == tab, animate)
	end)

	table.insert(self.tabs, tab)

	if #self.tabs == 1 then
		self:_select(tab)
	end

	return tab
end

function Window:SaveConfig(name)
	if not (writefile and makefolder and isfolder) then
		return false, "Filesystem not available"
	end

	local data = {}
	for flag, value in pairs(self.flags) do
		data[flag] = encode(value)
	end

	if not isfolder(self.folder) then
		makefolder(self.folder)
	end

	return pcall(writefile, self.folder .. "/" .. name .. ".json", httpService:JSONEncode(data))
end

function Window:LoadConfig(name)
	if not (isfile and readfile) then
		return false, "Filesystem not available"
	end

	local path = self.folder .. "/" .. name .. ".json"
	if not isfile(path) then
		return false, "Config not found"
	end

	local ok, data = pcall(function()
		return httpService:JSONDecode(readfile(path))
	end)

	if not ok then
		return false, "Config is corrupted"
	end

	local keys = {}
	for flag in pairs(data) do
		table.insert(keys, flag)
	end

	table.sort(keys, function(a, b)
		local left = a == "UI.Theme" and 0 or 1
		local right = b == "UI.Theme" and 0 or 1
		if left ~= right then
			return left < right
		end
		return a < b
	end)

	for _, flag in ipairs(keys) do
		local setter = self.setters[flag]
		if setter then
			local decoded, value = pcall(decode, data[flag])
			if decoded then
				pcall(setter, value)
			end
		end
	end

	return true
end

function Window:ListConfigs()
	local names = {}

	if not (isfolder and listfiles and isfolder(self.folder)) then
		return names
	end

	for _, path in ipairs(listfiles(self.folder)) do
		local name = path:match("([^/\\]+)%.json$")
		if name then
			table.insert(names, name)
		end
	end

	table.sort(names)
	return names
end

function Window:Settings()
	local tab = self:Tab("Settings")
	local accent

	tab:Section("Interface")

	tab:Dropdown({
		Name = "Theme",
		Options = themeOrder,
		Default = self.themeName,
		Flag = "UI.Theme",
		Callback = function(name)
			if name == self.themeName then
				return
			end
			self:SetTheme(name)
			accent:Set(self.theme.Accent, true)
		end,
	})

	accent = tab:ColorPicker({
		Name = "Accent",
		Default = self.theme.Accent,
		Flag = "UI.Accent",
		Callback = function(color)
			self:SetAccent(color)
		end,
	})

	tab:Slider({
		Name = "Transparency",
		Min = 0,
		Max = 85,
		Default = math.floor(self.transparency * 100 + 0.5),
		Suffix = "%",
		Flag = "UI.Transparency",
		Callback = function(value)
			self:SetTransparency(value / 100, true)
		end,
	})

	tab:Slider({
		Name = "Scale",
		Min = 70,
		Max = 130,
		Default = 100,
		Suffix = "%",
		Flag = "UI.Scale",
		Callback = function(value)
			self:SetScale(value / 100)
		end,
	})

	tab:Keybind({
		Name = "Menu Key",
		Default = self.toggleKey,
		Flag = "UI.ToggleKey",
		Changed = function(key)
			self.toggleKey = key or Enum.KeyCode.RightShift
		end,
	})

	tab:Toggle({
		Name = "Animations",
		Default = true,
		Flag = "UI.Animations",
		Callback = function(state)
			motion = state
		end,
	})

	tab:Toggle({
		Name = "Background Blur",
		Default = false,
		Flag = "UI.Blur",
		Callback = function(state)
			self:SetBlur(state)
		end,
	})

	tab:Section("Configuration")

	local nameBox = tab:Textbox({
		Name = "Config Name",
		Default = "default",
		Placeholder = "name",
	})

	local saved = tab:Dropdown({
		Name = "Saved Configs",
		Options = self:ListConfigs(),
	})

	tab:Button({
		Name = "Save Config",
		Callback = function()
			local name = nameBox:Get()
			if name == "" then
				self:Notify({ Title = "Config", Content = "Enter a config name first.", Type = "Warning" })
				return
			end

			local ok, err = self:SaveConfig(name)
			self:Notify({
				Title = "Config",
				Content = ok and ("Saved " .. name) or tostring(err),
				Type = ok and "Success" or "Error",
			})
			saved:Refresh(self:ListConfigs())
		end,
	})

	tab:Button({
		Name = "Load Config",
		Callback = function()
			local name = saved:Get() or nameBox:Get()
			local ok, err = self:LoadConfig(name)
			self:Notify({
				Title = "Config",
				Content = ok and ("Loaded " .. name) or tostring(err),
				Type = ok and "Success" or "Error",
			})
		end,
	})

	tab:Button({
		Name = "Refresh List",
		Callback = function()
			saved:Refresh(self:ListConfigs())
		end,
	})

	tab:Section("Window")

	tab:Button({
		Name = "Unload Interface",
		Callback = function()
			self:Destroy()
		end,
	})

	return tab
end

function Window:Destroy()
	if self.destroyed then
		return
	end

	self.destroyed = true
	self.visible = false
	self:_animate(false)
	self:_updateBlur()

	task.delay(0.4, function()
		for _, connection in ipairs(self.connections) do
			connection:Disconnect()
		end

		self.gui:Destroy()
		self.animValue:Destroy()

		if self.blur then
			self.blur:Destroy()
		end
	end)
end

function Library.new(options)
	options = options or {}

	local self = setmetatable({}, Window)
	self.connections = {}
	self.themed = {}
	self.surfaces = {}
	self.refreshers = {}
	self.tabs = {}
	self.flags = {}
	self.setters = {}
	self.themeName = themes[options.Theme] and options.Theme or "Dark"
	self.theme = table.clone(themes[self.themeName])
	self.transparency = math.clamp(options.Transparency or 0, 0, 0.85)
	self.userScale = 1
	self.visible = true
	self.minimized = false
	self.listening = false
	self.listenEnded = 0
	self.noteCount = 0
	self.toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
	self.folder = options.Folder or "ChromaLibrary"
	self.size = options.Size or UDim2.fromOffset(580, 400)

	if options.Accent then
		self.theme.Accent = options.Accent
	end

	local name = options.Name or "ChromaUI"
	local container = (gethui and gethui()) or coreGui

	local previous = container:FindFirstChild(name)
	if previous then
		previous:Destroy()
	end

	self.gui = create("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, container)

	self.animValue = Instance.new("NumberValue")
	self.animValue.Value = 0.9

	self.holder = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = self.size,
		BackgroundTransparency = 1,
	}, self.gui)
	corner(self.holder, 10)

	self.uiScale = create("UIScale", { Scale = 0.9 }, self.holder)
	self:_connect(self.animValue.Changed, function(value)
		self.uiScale.Scale = self.userScale * value
	end)

	self.outline = create("UIStroke", { Thickness = 1, Transparency = 1 }, self.holder)
	self:bind(self.outline, "Color", "Stroke")

	self.main = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		GroupTransparency = 1,
	}, self.holder)
	corner(self.main, 10)
	self:bind(self.main, "BackgroundColor3", "Background")
	self:surface(self.main, 0.02)

	local topbar = create("Frame", {
		Size = UDim2.new(1, 0, 0, 42),
		BorderSizePixel = 0,
	}, self.main)
	self:bind(topbar, "BackgroundColor3", "Surface")
	self:surface(topbar, 0.1)

	local dot = create("Frame", {
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.new(0, 16, 0.5, -4),
		BorderSizePixel = 0,
	}, topbar)
	pill(dot)
	self:bind(dot, "BackgroundColor3", "Accent")

	self:_text(topbar, {
		Size = UDim2.new(1, -140, 1, 0),
		Position = UDim2.fromOffset(34, 0),
		Text = options.Title or "Chroma",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	})

	local function headerButton(text, offset, hoverColor)
		local button = create("TextButton", {
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.new(1, offset, 0.5, -14),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = text,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
		}, topbar)
		corner(button, 7)
		self:bind(button, "TextColor3", "SubText")

		if hoverColor then
			button.BackgroundColor3 = hoverColor
		else
			self:bind(button, "BackgroundColor3", "Hover")
		end

		button.MouseEnter:Connect(function()
			tween(button, 0.15, { BackgroundTransparency = 0.15 })
			tween(button, 0.15, { TextColor3 = self.theme.Text })
		end)

		button.MouseLeave:Connect(function()
			tween(button, 0.15, { BackgroundTransparency = 1 })
			tween(button, 0.15, { TextColor3 = self.theme.SubText })
		end)

		return button
	end

	local minimize = headerButton("–", -70)
	local close = headerButton("×", -38, Color3.fromRGB(200, 60, 60))

	minimize.MouseButton1Click:Connect(function()
		self:Minimize()
	end)

	close.MouseButton1Click:Connect(function()
		self:Destroy()
	end)

	local divider = create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, 42),
		BorderSizePixel = 0,
	}, self.main)
	self:bind(divider, "BackgroundColor3", "Stroke")

	local sidebar = create("Frame", {
		Size = UDim2.new(0, 150, 1, -43),
		Position = UDim2.fromOffset(0, 43),
		BorderSizePixel = 0,
	}, self.main)
	self:bind(sidebar, "BackgroundColor3", "Surface")
	self:surface(sidebar, 0.25)

	local sideLine = create("Frame", {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BorderSizePixel = 0,
	}, sidebar)
	self:bind(sideLine, "BackgroundColor3", "Stroke")

	self.tabList = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -48),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, sidebar)

	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, self.tabList)

	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, self.tabList)

	self.indicator = create("Frame", {
		Size = UDim2.fromOffset(3, 16),
		BorderSizePixel = 0,
		Visible = false,
	}, sidebar)
	pill(self.indicator)
	self:bind(self.indicator, "BackgroundColor3", "Accent")

	self:_text(sidebar, {
		Size = UDim2.new(1, -24, 0, 28),
		Position = UDim2.new(0, 14, 1, -36),
		Text = localPlayer and localPlayer.DisplayName or "Player",
		TextSize = 12,
	}, "SubText")

	self.pages = create("Frame", {
		Size = UDim2.new(1, -151, 1, -43),
		Position = UDim2.fromOffset(151, 43),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, self.main)

	self.notifications = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.new(0, 280, 1, -32),
		BackgroundTransparency = 1,
	}, self.gui)

	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, self.notifications)

	local startPointer, startPosition
	self:_drag(topbar, function(position, began)
		if began then
			startPointer = position
			startPosition = self.holder.Position
			return
		end

		local delta = position - startPointer
		tween(self.holder, 0.08, {
			Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			),
		}, Enum.EasingStyle.Linear)
	end)

	self:_connect(userInputService.InputBegan, function(input, processed)
		if processed or self.listening or os.clock() - self.listenEnded < 0.2 then
			return
		end

		if input.KeyCode == self.toggleKey then
			self:Toggle()
		end
	end)

	task.defer(function()
		self:_animate(true)
	end)

	return self
end

function Tab:_next()
	self.order = self.order + 1
	return self.order
end

function Tab:_row(height)
	local window = self.window

	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = self:_next(),
	}, self.scroll)
	corner(row, 7)

	local stroke = create("UIStroke", { Thickness = 1, Transparency = 0.6 }, row)

	window:bind(row, "BackgroundColor3", "Element")
	window:bind(stroke, "Color", "Stroke")
	window:surface(row, 0.1)

	return row
end

function Tab:_hit(row)
	return create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
	}, row)
end

function Tab:Section(name)
	local label = self.window:_text(self.scroll, {
		Size = UDim2.new(1, 0, 0, 24),
		Text = string.upper(name),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		LayoutOrder = self:_next(),
	}, "SubText")

	create("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 6),
	}, label)

	return label
end

function Tab:Divider()
	local line = create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		LayoutOrder = self:_next(),
	}, self.scroll)
	self.window:bind(line, "BackgroundColor3", "Stroke")
	return line
end

function Tab:Label(text)
	local label = self.window:_text(self.scroll, {
		Size = UDim2.new(1, 0, 0, 20),
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextWrapped = true,
		LayoutOrder = self:_next(),
	}, "SubText")

	local object = {}

	function object:Set(value)
		label.Text = value
	end

	return object
end

function Tab:Button(options)
	local window = self.window

	local row = self:_row(36)
	local hit = self:_hit(row)

	window:_text(row, {
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		Text = options.Name or "Button",
	})

	local arrow = window:_text(row, {
		Size = UDim2.fromOffset(20, 36),
		Position = UDim2.new(1, -32, 0, 0),
		Text = "›",
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, "Accent")

	window:_hover(row, hit)

	hit.MouseEnter:Connect(function()
		tween(arrow, 0.2, { Position = UDim2.new(1, -28, 0, 0) })
	end)

	hit.MouseLeave:Connect(function()
		tween(arrow, 0.2, { Position = UDim2.new(1, -32, 0, 0) })
	end)

	hit.MouseButton1Down:Connect(function()
		tween(row, 0.1, { BackgroundColor3 = window.theme.Stroke })
	end)

	hit.MouseButton1Up:Connect(function()
		tween(row, 0.15, { BackgroundColor3 = window.theme.Hover })
	end)

	hit.MouseButton1Click:Connect(function()
		window:_fire(options.Callback)
	end)

	local object = {}

	function object:Fire()
		window:_fire(options.Callback)
	end

	return object
end

function Tab:Toggle(options)
	local window = self.window
	local state = options.Default == true
	local last = state

	local row = self:_row(36)
	local hit = self:_hit(row)

	window:_text(row, {
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		Text = options.Name or "Toggle",
	})

	local track = create("Frame", {
		Size = UDim2.fromOffset(36, 18),
		Position = UDim2.new(1, -50, 0.5, -9),
		BorderSizePixel = 0,
	}, row)
	pill(track)

	local knob = create("Frame", {
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, track)
	pill(knob)

	local object = {}

	local function render(animate)
		apply(track, { BackgroundColor3 = state and window.theme.Accent or window.theme.Stroke }, animate)
		apply(knob, { Position = UDim2.fromOffset(state and 21 or 3, 3) }, animate, 0.25)
	end

	function object:Set(value, silent)
		state = value == true
		render(true)
		window:_changed(options.Flag, state)

		if state ~= last then
			last = state
			if not silent then
				window:_fire(options.Callback, state)
			end
		end
	end

	function object:Get()
		return state
	end

	hit.MouseButton1Click:Connect(function()
		object:Set(not state)
	end)

	window:_hover(row, hit)
	table.insert(window.refreshers, render)
	render(false)

	window:_flag(options.Flag, state, function(value)
		object:Set(value)
	end)

	if state then
		task.defer(window._fire, window, options.Callback, state)
	end

	return object
end

function Tab:Slider(options)
	local window = self.window
	local min = options.Min or 0
	local max = options.Max or 100
	local step = options.Increment or 1
	local places = decimals(step)
	local suffix = options.Suffix or ""
	local value = snap(math.clamp(options.Default or min, min, max), min, step, places)
	local last = value

	local row = self:_row(52)

	window:_text(row, {
		Size = UDim2.new(1, -110, 0, 18),
		Position = UDim2.fromOffset(14, 8),
		Text = options.Name or "Slider",
	})

	local readout = window:_text(row, {
		Size = UDim2.fromOffset(90, 18),
		Position = UDim2.new(1, -104, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, "SubText")

	local track = create("Frame", {
		Size = UDim2.new(1, -28, 0, 6),
		Position = UDim2.fromOffset(14, 36),
		BorderSizePixel = 0,
	}, row)
	pill(track)
	window:bind(track, "BackgroundColor3", "Stroke")

	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
	}, track)
	pill(fill)
	window:bind(fill, "BackgroundColor3", "Accent")

	local knob = create("Frame", {
		Size = UDim2.fromOffset(12, 12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, fill)
	pill(knob)

	local hit = create("TextButton", {
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.fromOffset(8, 26),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, row)

	local object = {}

	local function render(animate)
		local ratio = max > min and (value - min) / (max - min) or 0
		readout.Text = string.format("%." .. places .. "f", value) .. suffix
		apply(fill, { Size = UDim2.fromScale(ratio, 1) }, animate, 0.12)
	end

	function object:Set(newValue, silent)
		newValue = math.clamp(tonumber(newValue) or min, min, max)
		value = math.min(snap(newValue, min, step, places), max)
		render(true)
		window:_changed(options.Flag, value)

		if value ~= last then
			last = value
			if not silent then
				window:_fire(options.Callback, value)
			end
		end
	end

	function object:Get()
		return value
	end

	window:_drag(hit, function(position, began)
		if began then
			tween(knob, 0.15, { Size = UDim2.fromOffset(16, 16) })
		end

		local ratio = math.clamp((position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		object:Set(min + (max - min) * ratio)
	end, function()
		tween(knob, 0.15, { Size = UDim2.fromOffset(12, 12) })
	end)

	render(false)

	window:_flag(options.Flag, value, function(newValue)
		object:Set(newValue)
	end)

	task.defer(window._fire, window, options.Callback, value)

	return object
end

function Tab:Dropdown(options)
	local window = self.window
	local list = options.Options or {}
	local multi = options.Multi == true
	local open = false
	local current = nil
	local picked = {}
	local entries = {}
	local object = {}

	if multi then
		for _, name in ipairs(options.Default or {}) do
			picked[name] = true
		end
	else
		current = options.Default
	end

	local row = self:_row(36)
	local header = self:_hit(row)

	window:_text(row, {
		Size = UDim2.new(0.5, -14, 0, 36),
		Position = UDim2.fromOffset(14, 0),
		Text = options.Name or "Dropdown",
	})

	local readout = window:_text(row, {
		Size = UDim2.new(0.5, -46, 0, 36),
		Position = UDim2.fromScale(0.5, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, "SubText")

	local chevron = window:_text(row, {
		Size = UDim2.fromOffset(20, 36),
		Position = UDim2.new(1, -30, 0, 0),
		Text = "›",
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Rotation = 90,
	}, "SubText")

	local listFrame = create("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 42),
		Size = UDim2.new(1, -16, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, row)
	window:bind(listFrame, "ScrollBarImageColor3", "Accent")

	create("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, listFrame)

	local function expandedHeight()
		return 42 + math.min(#list, 5) * 28 + 6
	end

	local function isPicked(name)
		if multi then
			return picked[name] == true
		end
		return current == name
	end

	local function collect()
		if not multi then
			return current
		end

		local result = {}
		for _, name in ipairs(list) do
			if picked[name] then
				table.insert(result, name)
			end
		end
		return result
	end

	local function render(animate)
		for _, entry in ipairs(entries) do
			local active = isPicked(entry.name)
			apply(entry.text, { TextColor3 = active and window.theme.Accent or window.theme.SubText }, animate)
			apply(entry.button, { BackgroundTransparency = active and 0.6 or 1 }, animate)
		end

		if multi then
			local names = {}
			for _, name in ipairs(list) do
				if picked[name] then
					table.insert(names, tostring(name))
				end
			end
			readout.Text = #names > 0 and table.concat(names, ", ") or "None"
		else
			readout.Text = current ~= nil and tostring(current) or "None"
		end
	end

	local function commit()
		render(true)
		local value = collect()
		window:_changed(options.Flag, value)
		window:_fire(options.Callback, value)
	end

	local function setOpen(state)
		open = state
		tween(row, 0.3, { Size = UDim2.new(1, 0, 0, state and expandedHeight() or 36) })
		tween(chevron, 0.3, { Rotation = state and -90 or 90 })
	end

	local function choose(name)
		if multi then
			picked[name] = not picked[name] or nil
		else
			setOpen(false)
			if current == name then
				return
			end
			current = name
		end

		commit()
	end

	local function build()
		for _, entry in ipairs(entries) do
			entry.button:Destroy()
		end
		entries = {}

		for index, name in ipairs(list) do
			local button = create("TextButton", {
				Size = UDim2.new(1, -4, 0, 26),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
			}, listFrame)
			corner(button, 5)
			window:bind(button, "BackgroundColor3", "Hover")

			local text = create("TextLabel", {
				Size = UDim2.new(1, -20, 1, 0),
				Position = UDim2.fromOffset(10, 0),
				BackgroundTransparency = 1,
				Text = tostring(name),
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, button)

			table.insert(entries, { name = name, button = button, text = text })

			button.MouseEnter:Connect(function()
				if not isPicked(name) then
					tween(button, 0.12, { BackgroundTransparency = 0.8 })
				end
			end)

			button.MouseLeave:Connect(function()
				if not isPicked(name) then
					tween(button, 0.12, { BackgroundTransparency = 1 })
				end
			end)

			button.MouseButton1Click:Connect(function()
				choose(name)
			end)
		end

		listFrame.Size = UDim2.new(1, -16, 0, math.max(math.min(#list, 5) * 28 - 2, 0))

		if open then
			tween(row, 0.3, { Size = UDim2.new(1, 0, 0, expandedHeight()) })
		end

		render(false)
	end

	function object:Set(value, silent)
		if multi then
			picked = {}
			for _, name in ipairs(value or {}) do
				picked[name] = true
			end
		else
			current = value
		end

		render(true)
		window:_changed(options.Flag, collect())

		if not silent then
			window:_fire(options.Callback, collect())
		end
	end

	function object:Get()
		return collect()
	end

	function object:Refresh(newList)
		list = newList or {}

		if multi then
			for name in pairs(picked) do
				if not table.find(list, name) then
					picked[name] = nil
				end
			end
		elseif current ~= nil and not table.find(list, current) then
			current = nil
		end

		build()
	end

	header.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)

	window:_hover(row, header)
	table.insert(window.refreshers, render)
	build()

	window:_flag(options.Flag, collect(), function(value)
		object:Set(value)
	end)

	if (multi and next(picked) ~= nil) or (not multi and current ~= nil) then
		task.defer(window._fire, window, options.Callback, collect())
	end

	return object
end

function Tab:Textbox(options)
	local window = self.window
	local value = options.Default or ""

	local row = self:_row(36)

	window:_text(row, {
		Size = UDim2.new(0.45, -14, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		Text = options.Name or "Textbox",
	})

	local frame = create("Frame", {
		Size = UDim2.new(0.55, -24, 0, 24),
		Position = UDim2.new(0.45, 10, 0.5, -12),
		BorderSizePixel = 0,
	}, row)
	corner(frame, 5)
	window:bind(frame, "BackgroundColor3", "Background")
	window:surface(frame, 0.2)

	local stroke = create("UIStroke", { Thickness = 1, Transparency = 0.2 }, frame)
	window:bind(stroke, "Color", "Stroke")

	local input = create("TextBox", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1,
		Text = value,
		PlaceholderText = options.Placeholder or "",
		ClearTextOnFocus = options.ClearOnFocus == true,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)
	window:bind(input, "TextColor3", "Text")
	window:bind(input, "PlaceholderColor3", "SubText")

	local object = {}

	function object:Set(text, silent)
		value = tostring(text)
		input.Text = value
		window:_changed(options.Flag, value)

		if not silent then
			window:_fire(options.Callback, value, false)
		end
	end

	function object:Get()
		return value
	end

	if options.Numeric then
		input:GetPropertyChangedSignal("Text"):Connect(function()
			local filtered = input.Text:gsub("[^%d%.%-]", "")
			if filtered ~= input.Text then
				input.Text = filtered
			end
		end)
	end

	input.Focused:Connect(function()
		tween(stroke, 0.2, { Color = window.theme.Accent, Transparency = 0 })
	end)

	input.FocusLost:Connect(function(enter)
		tween(stroke, 0.2, { Color = window.theme.Stroke, Transparency = 0.2 })
		value = input.Text
		window:_changed(options.Flag, value)
		window:_fire(options.Callback, value, enter)
	end)

	window:_flag(options.Flag, value, function(text)
		object:Set(text)
	end)

	return object
end

function Tab:Keybind(options)
	local window = self.window
	local key = options.Default
	local listening = false

	if type(key) == "string" then
		local found, parsed = pcall(function()
			return Enum.KeyCode[key]
		end)
		key = found and parsed or nil
	end

	local row = self:_row(36)

	window:_text(row, {
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		Text = options.Name or "Keybind",
	})

	local button = create("TextButton", {
		Size = UDim2.fromOffset(88, 24),
		Position = UDim2.new(1, -102, 0.5, -12),
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		BorderSizePixel = 0,
		Text = "",
	}, row)
	corner(button, 5)
	window:bind(button, "BackgroundColor3", "Background")
	window:surface(button, 0.2)

	local stroke = create("UIStroke", { Thickness = 1, Transparency = 0.2 }, button)
	local object = {}

	local function render(animate)
		button.Text = listening and "..." or (key and key.Name or "None")
		apply(button, { TextColor3 = listening and window.theme.Accent or window.theme.Text }, animate)
		apply(stroke, { Color = listening and window.theme.Accent or window.theme.Stroke }, animate)
	end

	function object:Set(value, silent)
		if typeof(value) == "EnumItem" then
			key = value
		else
			key = nil
		end

		render(true)
		window:_changed(options.Flag, key or false)

		if not silent then
			window:_fire(options.Changed, key)
		end
	end

	function object:Get()
		return key
	end

	button.MouseButton1Click:Connect(function()
		listening = true
		window.listening = true
		render(true)
	end)

	window:_connect(userInputService.InputBegan, function(input, processed)
		if listening then
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end

			listening = false
			window.listening = false
			window.listenEnded = os.clock()

			if input.KeyCode == Enum.KeyCode.Escape then
				key = nil
			else
				key = input.KeyCode
			end

			render(true)
			window:_changed(options.Flag, key or false)
			window:_fire(options.Changed, key)
			return
		end

		if processed or not key then
			return
		end

		if input.KeyCode == key then
			window:_fire(options.Callback, key)
		end
	end)

	table.insert(window.refreshers, render)
	render(false)

	window:_flag(options.Flag, key or false, function(value)
		object:Set(value)
	end)

	return object
end

function Tab:ColorPicker(options)
	local window = self.window
	local color = options.Default or Color3.fromRGB(255, 255, 255)
	local hue, sat, val = color:ToHSV()
	local last = color
	local open = false

	local row = self:_row(36)
	local header = self:_hit(row)

	window:_text(row, {
		Size = UDim2.new(1, -70, 0, 36),
		Position = UDim2.fromOffset(14, 0),
		Text = options.Name or "Color",
	})

	local swatch = create("Frame", {
		Size = UDim2.fromOffset(34, 18),
		Position = UDim2.new(1, -48, 0, 9),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, row)
	corner(swatch, 5)

	local swatchStroke = create("UIStroke", { Thickness = 1, Transparency = 0.5 }, swatch)
	window:bind(swatchStroke, "Color", "Text")

	local field = create("Frame", {
		Position = UDim2.fromOffset(14, 46),
		Size = UDim2.new(1, -58, 0, 100),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderSizePixel = 0,
	}, row)
	corner(field, 5)

	local white = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, field)
	corner(white, 5)
	create("UIGradient", { Transparency = NumberSequence.new(0, 1) }, white)

	local black = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
	}, field)
	corner(black, 5)
	create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, black)

	local cursor = create("Frame", {
		Size = UDim2.fromOffset(10, 10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, field)
	pill(cursor)
	create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, cursor)

	local bar = create("Frame", {
		Position = UDim2.new(1, -30, 0, 46),
		Size = UDim2.fromOffset(16, 100),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, row)
	corner(bar, 5)

	local points = {}
	for index = 0, 6 do
		table.insert(points, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV(index / 6, 1, 1)))
	end
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(points) }, bar)

	local marker = create("Frame", {
		Size = UDim2.new(1, 4, 0, 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, bar)
	pill(marker)
	create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.5 }, marker)

	local object = {}

	local function render()
		swatch.BackgroundColor3 = color
		field.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		cursor.Position = UDim2.fromScale(sat, 1 - val)
		marker.Position = UDim2.fromScale(0.5, hue)
	end

	local function commit(silent)
		color = Color3.fromHSV(hue, sat, val)
		render()
		window:_changed(options.Flag, color)

		if color ~= last then
			last = color
			if not silent then
				window:_fire(options.Callback, color)
			end
		end
	end

	function object:Set(value, silent)
		hue, sat, val = value:ToHSV()
		commit(silent)
	end

	function object:Get()
		return color
	end

	window:_drag(field, function(position)
		sat = math.clamp((position.X - field.AbsolutePosition.X) / field.AbsoluteSize.X, 0, 1)
		val = 1 - math.clamp((position.Y - field.AbsolutePosition.Y) / field.AbsoluteSize.Y, 0, 1)
		commit()
	end)

	window:_drag(bar, function(position)
		hue = math.clamp((position.Y - bar.AbsolutePosition.Y) / bar.AbsoluteSize.Y, 0, 1)
		commit()
	end)

	header.MouseButton1Click:Connect(function()
		open = not open
		tween(row, 0.3, { Size = UDim2.new(1, 0, 0, open and 160 or 36) })
	end)

	window:_hover(row, header)
	render()

	window:_flag(options.Flag, color, function(value)
		object:Set(value)
	end)

	task.defer(window._fire, window, options.Callback, color)

	return object
end

return Library
