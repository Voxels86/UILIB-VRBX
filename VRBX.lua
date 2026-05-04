local VRBX = {}
VRBX.__index = VRBX
VRBX.Version = "1.0.0"

local Services = {
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    HttpService = game:GetService("HttpService"),
    TextService = game:GetService("TextService")
}

local Themes = {
    Midnight = {
        Background = Color3.fromRGB(11, 12, 16),
        Surface = Color3.fromRGB(18, 20, 27),
        SurfaceLight = Color3.fromRGB(25, 28, 38),
        Stroke = Color3.fromRGB(43, 48, 64),
        Text = Color3.fromRGB(238, 242, 255),
        Muted = Color3.fromRGB(148, 158, 184),
        Accent = Color3.fromRGB(94, 144, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        Danger = Color3.fromRGB(255, 82, 102)
    },
    Emerald = {
        Background = Color3.fromRGB(8, 13, 12),
        Surface = Color3.fromRGB(14, 24, 22),
        SurfaceLight = Color3.fromRGB(20, 36, 32),
        Stroke = Color3.fromRGB(36, 61, 55),
        Text = Color3.fromRGB(232, 255, 248),
        Muted = Color3.fromRGB(139, 176, 166),
        Accent = Color3.fromRGB(37, 211, 137),
        AccentText = Color3.fromRGB(4, 20, 14),
        Danger = Color3.fromRGB(255, 88, 88)
    },
    Violet = {
        Background = Color3.fromRGB(13, 10, 19),
        Surface = Color3.fromRGB(22, 17, 33),
        SurfaceLight = Color3.fromRGB(32, 25, 48),
        Stroke = Color3.fromRGB(55, 43, 78),
        Text = Color3.fromRGB(246, 240, 255),
        Muted = Color3.fromRGB(171, 153, 202),
        Accent = Color3.fromRGB(167, 112, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        Danger = Color3.fromRGB(255, 91, 127)
    },
    Crimson = {
        Background = Color3.fromRGB(18, 9, 11),
        Surface = Color3.fromRGB(29, 15, 19),
        SurfaceLight = Color3.fromRGB(43, 22, 28),
        Stroke = Color3.fromRGB(74, 38, 47),
        Text = Color3.fromRGB(255, 239, 242),
        Muted = Color3.fromRGB(199, 142, 153),
        Accent = Color3.fromRGB(255, 74, 104),
        AccentText = Color3.fromRGB(255, 255, 255),
        Danger = Color3.fromRGB(255, 74, 104)
    },
    Graphite = {
        Background = Color3.fromRGB(12, 12, 13),
        Surface = Color3.fromRGB(20, 20, 22),
        SurfaceLight = Color3.fromRGB(30, 30, 33),
        Stroke = Color3.fromRGB(53, 53, 58),
        Text = Color3.fromRGB(242, 242, 245),
        Muted = Color3.fromRGB(160, 160, 169),
        Accent = Color3.fromRGB(235, 235, 240),
        AccentText = Color3.fromRGB(15, 15, 17),
        Danger = Color3.fromRGB(255, 92, 92)
    }
}

VRBX.Themes = Themes

local function safeParent()
    assert(type(gethui) == "function", "VRBX requires gethui().")
    local ok, parent = pcall(gethui)
    assert(ok and parent, "gethui() failed or returned nil.")
    return parent
end

local function create(className, props, children)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function randomName()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local out = table.create(18)
    for i = 1, 18 do
        local index = math.random(1, #chars)
        out[i] = string.sub(chars, index, index)
    end
    return table.concat(out)
end

local function scrambleInstanceNames(root)
    root.Name = randomName()
    for _, child in ipairs(root:GetDescendants()) do
        child.Name = randomName()
    end
end

local function addCorner(parent, radius)
    return nil
end

local function addStroke(parent, color, transparency)
    return create("UIStroke", {
        Color = color,
        Thickness = 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function trackTheme(self, obj, props)
    table.insert(self.ThemeObjects, { Object = obj, Props = props })
    return obj
end

local function tween(obj, props, time)
    local tw = Services.TweenService:Create(obj, TweenInfo.new(time or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function bind(connectionBucket, signal, callback)
    local c = signal:Connect(callback)
    table.insert(connectionBucket, c)
    return c
end

local function disconnectAll(connections)
    for _, c in ipairs(connections) do
        if c and c.Disconnect then
            c:Disconnect()
        end
    end
    for i = #connections, 1, -1 do
        connections[i] = nil
    end
end

local function normalizeTheme(theme)
    if type(theme) == "string" then
        return Themes[theme] or Themes.Midnight
    end
    if type(theme) == "table" then
        local base = {}
        for key, value in pairs(Themes.Midnight) do
            base[key] = value
        end
        for key, value in pairs(theme) do
            base[key] = value
        end
        return base
    end
    return Themes.Midnight
end

local function firstNonNil(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
    return nil
end

local function configFileName(name)
    name = tostring(name or "Default"):gsub("[^%w_%-%s]", "")
    return "VRBX/" .. name .. ".json"
end

local function randomToken(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, length or 10 do
        local index = math.random(1, #chars)
        result[i] = chars:sub(index, index)
    end
    return table.concat(result)
end

local function runtimeName(window, fallback)
    if window and window.NameScrambling then
        return (window.NameSalt or "vr") .. "_" .. randomToken(12)
    end
    return fallback
end

local function offsetUDim2(value, x, y)
    return UDim2.new(value.X.Scale, value.X.Offset + x, value.Y.Scale, value.Y.Offset + y)
end

local function coerceKeyCode(value, fallback)
    if typeof(value) == "EnumItem" then
        return value
    end
    if typeof(value) == "string" then
        local ok, key = pcall(function()
            return Enum.KeyCode[value]
        end)
        if ok and key then
            return key
        end
    end
    return fallback or Enum.KeyCode.RightShift
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local function makeTextButton(props)
    props.AutoButtonColor = false
    props.Font = props.Font or Enum.Font.Gotham
    props.TextSize = props.TextSize or 13
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    props.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    props.TextWrapped = props.TextWrapped == nil and true or props.TextWrapped
    props.TextTruncate = props.TextTruncate or Enum.TextTruncate.AtEnd
    props.BorderSizePixel = 0
    return create("TextButton", props)
end

local function makeTextLabel(props)
    props.Font = props.Font or Enum.Font.Gotham
    props.TextSize = props.TextSize or 13
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    props.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    props.TextWrapped = props.TextWrapped == nil and true or props.TextWrapped
    props.TextTruncate = props.TextTruncate or Enum.TextTruncate.AtEnd
    props.BackgroundTransparency = props.BackgroundTransparency == nil and 1 or props.BackgroundTransparency
    props.BorderSizePixel = 0
    return create("TextLabel", props)
end

local function fitText(instance, minSize, maxSize)
    instance.TextScaled = true
    local constraint = create("UITextSizeConstraint", {
        MinTextSize = minSize or 10,
        MaxTextSize = maxSize or instance.TextSize or 13,
        Parent = instance
    })
    return constraint
end

local function rightControl(props, width, height, inset)
    props.AnchorPoint = Vector2.new(1, 0.5)
    props.Position = UDim2.new(1, -(inset or 10), 0.5, 0)
    props.Size = UDim2.new(0, width, 0, height)
    return props
end

local function topRightControl(props, width, height, inset, top)
    props.AnchorPoint = Vector2.new(1, 0)
    props.Position = UDim2.new(1, -(inset or 10), 0, top or 9)
    props.Size = UDim2.new(0, width, 0, height)
    return props
end

local function shade(color, amount)
    return Color3.new(
        math.clamp(color.R + amount, 0, 1),
        math.clamp(color.G + amount, 0, 1),
        math.clamp(color.B + amount, 0, 1)
    )
end

local function addButtonFeedback(connections, button, normalColor, hoverColor, pressColor, getNormalColor)
    local hovering = false
    local pressed = false
    local function currentNormal()
        return getNormalColor and getNormalColor() or normalColor
    end
    bind(connections, button.MouseEnter, function()
        hovering = true
        if not pressed then
            tween(button, { BackgroundColor3 = hoverColor or shade(currentNormal(), 0.06) }, 0.08)
        end
    end)
    bind(connections, button.MouseLeave, function()
        hovering = false
        pressed = false
        tween(button, { BackgroundColor3 = currentNormal() }, 0.08)
    end)
    bind(connections, button.MouseButton1Down, function()
        pressed = true
        tween(button, { BackgroundColor3 = pressColor or shade(currentNormal(), -0.05) }, 0.06)
    end)
    bind(connections, button.MouseButton1Up, function()
        pressed = false
        tween(button, { BackgroundColor3 = hovering and (hoverColor or shade(currentNormal(), 0.06)) or currentNormal() }, 0.08)
    end)
end

local function runCallback(window, options, callback, ...)
    if not callback then return end
    local args = { ... }
    task.spawn(function()
        local protected = window and window.SecureBoot == true
        local silent = (window and window.NoErrorCallbacks == true) or (options and options.NoErrorCallbacks == true)
        if protected or silent then
            local ok, err = pcall(callback, table.unpack(args))
            if not ok and not silent then
                print("[VRBX Callback Error] " .. tostring(err))
            end
        else
            callback(table.unpack(args))
        end
    end)
end

local function attachTooltip(window, target, text)
    if not text or text == "" then return end
    local tip
    bind(window.Connections, target.MouseEnter, function()
        local theme = window.Theme
        tip = create("Frame", {
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(210, 34),
            ZIndex = 50,
            Parent = window.Gui
        })
        trackTheme(window, tip, { BackgroundColor3 = "Surface" })
        trackTheme(window, addStroke(tip, theme.Stroke, 0.2), { Color = "Stroke" })
        local label = makeTextLabel({
            Text = tostring(text),
            TextColor3 = theme.Text,
            TextSize = 12,
            TextWrapped = true,
            Size = UDim2.new(1, -12, 1, -8),
            Position = UDim2.fromOffset(6, 4),
            ZIndex = 51,
            Parent = tip
        })
        trackTheme(window, label, { TextColor3 = "Text" })
        local mouse = Services.UserInputService:GetMouseLocation()
        tip.Position = UDim2.fromOffset(mouse.X + 12, mouse.Y + 12)
    end)
    bind(window.Connections, target.MouseMoved, function(x, y)
        if tip and tip.Parent then
            tip.Position = UDim2.fromOffset(x + 12, y + 12)
        end
    end)
    bind(window.Connections, target.MouseLeave, function()
        if tip then
            tip:Destroy()
            tip = nil
        end
    end)
end

local function elementHandle(instance, extra)
    local handle = extra or {}
    handle.Instance = instance
    handle.Disabled = false
    handle.DefaultTransparency = instance.BackgroundTransparency
    function handle:Visible(value)
        instance.Visible = value ~= false
        return self
    end
    function handle:SetDisabled(value)
        self.Disabled = value ~= false
        instance.Active = not self.Disabled
        instance.BackgroundTransparency = self.Disabled and 0.45 or self.DefaultTransparency
        for _, child in ipairs(instance:GetDescendants()) do
            if child:IsA("GuiButton") then
                child.Active = not self.Disabled
            end
        end
        return self
    end
    function handle:Destroy()
        if instance then instance:Destroy() end
    end
    return handle
end

local function makeCard(self, parent, title, searchText, height)
    local theme = self.Window.Theme
    local text = tostring(title or "Element")
    local baseHeight = height or 44
    local card = create("Frame", {
        Name = runtimeName(self.Window, "ElementCard"),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.18,
        Size = UDim2.new(1, -16, 0, baseHeight),
        BorderSizePixel = 0,
        Parent = parent
    })
    trackTheme(self.Window, card, { BackgroundColor3 = "Surface" })
    addCorner(card, 9)
    trackTheme(self.Window, addStroke(card, theme.Stroke, 0.35), { Color = "Stroke" })

    local label = makeTextLabel({
        Name = runtimeName(self.Window, "Title"),
        Text = text,
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        AnchorPoint = Vector2.new(0, 0.5),
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, -148, 0, math.max(20, baseHeight - 14)),
        Position = UDim2.fromOffset(10, baseHeight / 2),
        Parent = card
    })
    trackTheme(self.Window, label, { TextColor3 = "Text" })
    fitText(label, 10, 13)
    label.TextScaled = false
    label.TextWrapped = true

    local function updateHeight()
        if not card.Parent then return end
        local width = math.max(label.AbsoluteSize.X, 40)
        local bounds = Services.TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(width, 1000))
        local needed = math.max(baseHeight, math.ceil(bounds.Y) + 18)
        if math.abs(card.Size.Y.Offset - needed) > 1 then
            card.Size = UDim2.new(1, -16, 0, needed)
            label.Size = UDim2.new(1, -148, 0, math.max(20, needed - 14))
            label.Position = UDim2.fromOffset(10, needed / 2)
        end
    end
    bind(self.Window.Connections, label:GetPropertyChangedSignal("AbsoluteSize"), updateHeight)
    bind(self.Window.Connections, label:GetPropertyChangedSignal("Text"), updateHeight)
    task.defer(updateHeight)

    table.insert(self.Window.Searchables, { Frame = card, Text = string.lower(searchText or title or "") })
    if title then
        self.ElementMap[string.lower(tostring(title))] = card
    end
    return card, label
end

local function createWindowInternal(options)
    options = options or {}
    local windowSettings = options.WindowSettings or {}
    local securitySettings = options.SecuritySettings or {}
    local closeSettings = options.CloseSettings or {}
    local configSettings = options.ConfigSettings or {}
    local theme = normalizeTheme(firstNonNil(options.Theme, windowSettings.Theme))
    local nameScrambling = firstNonNil(options.RuntimeNameScrambling, options.RandomizeInstanceNames, securitySettings.RuntimeNameScrambling, securitySettings.RandomizeInstanceNames) == true
    local nameSalt = tostring(firstNonNil(options.NameSalt, securitySettings.NameSalt, "vrbx"))
    local gui = create("ScreenGui", {
        Name = nameScrambling and (nameSalt .. "_" .. randomToken(14)) or (firstNonNil(options.Name, windowSettings.Name) or "VRBX"),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = safeParent()
    })

    local self = setmetatable({
        Gui = gui,
        Theme = theme,
        ThemeName = type(firstNonNil(options.Theme, windowSettings.Theme)) == "string" and firstNonNil(options.Theme, windowSettings.Theme) or "Custom",
        Tabs = {},
        TabMap = {},
        ThemeObjects = {},
        Flags = {},
        Defaults = {},
        FlagSetters = {},
        FlagWatchers = {},
        Searchables = {},
        Connections = {},
        CurrentTab = nil,
        Minimized = false,
        SecureBoot = firstNonNil(options.SecureBoot, securitySettings.SecureBoot) == true,
        NoErrorCallbacks = firstNonNil(options.NoErrorCallbacks, securitySettings.NoErrorCallbacks) == true,
        AskBeforeClose = firstNonNil(options.AskBeforeClose, closeSettings.AskBeforeClose) == true,
        TurnOffAfterDelete = firstNonNil(options.TurnOffAfterDelete, closeSettings.TurnOffAfterDelete) == true,
        NameScrambling = nameScrambling,
        NameSalt = nameSalt,
        ConfigSuffix = firstNonNil(options.ConfigSuffix, configSettings.ConfigSuffix),
        RandomizeConfigNames = firstNonNil(options.RandomizeConfigNames, configSettings.RandomizeConfigNames) == true,
        AutoSaveConfig = nil,
        AutoSaveQueued = false,
        Name = firstNonNil(options.Name, windowSettings.Name, options.Title, windowSettings.Title) or "VRBX"
    }, Window)

    local size = firstNonNil(options.Size, windowSettings.Size) or UDim2.fromOffset(620, 430)
    local normalSize = size
    local pos = firstNonNil(options.Position, windowSettings.Position) or UDim2.new(0.5, -310, 0.5, -215)

    local shadow = create("Frame", {
        Name = runtimeName(self, "Shadow"),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Position = pos,
        Size = size,
        BorderSizePixel = 0,
        Parent = gui
    })
    addCorner(shadow, 16)

    local main = create("Frame", {
        Name = runtimeName(self, "Main"),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.02,
        Position = pos,
        Size = size,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui
    })
    trackTheme(self, main, { BackgroundColor3 = "Background" })
    addCorner(main, 16)
    trackTheme(self, addStroke(main, theme.Stroke, 0.05), { Color = "Stroke" })

    local topbar = create("Frame", {
        Name = runtimeName(self, "Topbar"),
        Active = true,
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.14,
        Size = UDim2.new(1, 0, 0, 44),
        BorderSizePixel = 0,
        Parent = main
    })
    trackTheme(self, topbar, { BackgroundColor3 = "Surface" })

    local title = makeTextLabel({
        Name = runtimeName(self, "WindowTitle"),
        Text = firstNonNil(options.Title, windowSettings.Title) or "VRBX",
        TextColor3 = theme.Text,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(0, 210, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        Parent = topbar
    })
    trackTheme(self, title, { TextColor3 = "Text" })

    local search = create("TextBox", {
        Name = runtimeName(self, "Search"),
        PlaceholderText = "Search...",
        Text = "",
        ClearTextOnFocus = false,
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 170, 0, 28),
        Position = UDim2.new(1, -252, 0, 8),
        Parent = topbar
    })
    trackTheme(self, search, { TextColor3 = "Text", PlaceholderColor3 = "Muted", BackgroundColor3 = "SurfaceLight" })
    addCorner(search, 8)
    trackTheme(self, addStroke(search, theme.Stroke, 0.35), { Color = "Stroke" })
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8), Parent = search })

    local minBtn = makeTextButton({
        Name = runtimeName(self, "Minimize"),
        Text = "-",
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 0.18,
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -66, 0, 8),
        Parent = topbar
    })
    trackTheme(self, minBtn, { TextColor3 = "Text", BackgroundColor3 = "SurfaceLight" })
    addCorner(minBtn, 8)

    local closeBtn = makeTextButton({
        Name = runtimeName(self, "Close"),
        Text = "X",
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        BackgroundColor3 = theme.Danger,
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -34, 0, 8),
        Parent = topbar
    })
    trackTheme(self, closeBtn, { TextColor3 = "Text", BackgroundColor3 = "Danger" })
    addCorner(closeBtn, 8)

    local sidebar = create("Frame", {
        Name = runtimeName(self, "Sidebar"),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.55,
        Position = UDim2.fromOffset(12, 58),
        Size = UDim2.new(0, 144, 1, -70),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = main
    })
    trackTheme(self, sidebar, { BackgroundColor3 = "Surface" })
    addCorner(sidebar, 10)
    trackTheme(self, addStroke(sidebar, theme.Stroke, 0.55), { Color = "Stroke" })

    local tabScroller = create("ScrollingFrame", {
        Name = runtimeName(self, "TabScroller"),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 1, -12),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = sidebar
    })
    trackTheme(self, tabScroller, { ScrollBarImageColor3 = "Accent" })
    local tabList = create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabScroller
    })
    bind(self.Connections, tabList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        tabScroller.CanvasSize = UDim2.fromOffset(0, tabList.AbsoluteContentSize.Y + 4)
    end)

    local pages = create("Frame", {
        Name = runtimeName(self, "Pages"),
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(168, 58),
        Size = UDim2.new(1, -180, 1, -70),
        BorderSizePixel = 0,
        Parent = main
    })

    local notifications = create("Frame", {
        Name = runtimeName(self, "Notifications"),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(290, 320),
        Parent = gui
    })
    local notifyLayout = create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Parent = notifications
    })

    local resizeHandle = create("Frame", {
        Name = runtimeName(self, "ResizeHandle"),
        Active = true,
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = theme.Muted,
        BackgroundTransparency = 0.35,
        Position = UDim2.new(1, -5, 1, -5),
        Size = UDim2.fromOffset(12, 12),
        BorderSizePixel = 0,
        Parent = main
    })
    trackTheme(self, resizeHandle, { BackgroundColor3 = "Muted" })
    addCorner(resizeHandle, 5)

    self.Main = main
    self.Shadow = shadow
    self.Topbar = topbar
    self.Sidebar = sidebar
    self.TabScroller = tabScroller
    self.TabList = tabList
    self.Pages = pages
    self.Notifications = notifications
    self.NotifyLayout = notifyLayout
    self.SearchBox = search

    local function setFiltered(text)
        text = string.lower(text or "")
        for _, item in ipairs(self.Searchables) do
            local show = text == "" or string.find(item.Text, text, 1, true) ~= nil
            if item.Frame and item.Frame.Parent then
                item.Frame.Visible = show
            end
        end
    end

    bind(self.Connections, search:GetPropertyChangedSignal("Text"), function()
        setFiltered(search.Text)
    end)

    local dragging, dragStart, startPos
    bind(self.Connections, topbar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            bind(self.Connections, input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    bind(self.Connections, Services.UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            main.Position = newPos
            shadow.Position = newPos
        end
    end)

    local resizing, resizeStart, startSize
    bind(self.Connections, resizeHandle.InputBegan, function(input)
        if self.Minimized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = main.AbsoluteSize
            bind(self.Connections, input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)
    bind(self.Connections, Services.UserInputService.InputChanged, function(input)
        if resizing and not self.Minimized and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local w = math.max(560, startSize.X + delta.X)
            local h = math.max(320, startSize.Y + delta.Y)
            main.Size = UDim2.fromOffset(w, h)
            shadow.Size = main.Size
            normalSize = main.Size
        end
    end)

    bind(self.Connections, minBtn.MouseButton1Click, function()
        self.Minimized = not self.Minimized
        if self.Minimized then
            resizing = false
            sidebar.Visible = false
            pages.Visible = false
            resizeHandle.Visible = false
            tween(main, { Size = UDim2.fromOffset(main.AbsoluteSize.X, 44) }, 0.16)
            tween(shadow, { Size = UDim2.fromOffset(main.AbsoluteSize.X, 44) }, 0.16)
        else
            tween(main, { Size = normalSize }, 0.16)
            tween(shadow, { Size = normalSize }, 0.16)
            task.delay(0.16, function()
                if not self.Minimized and main.Parent then
                    sidebar.Visible = true
                    pages.Visible = true
                    resizeHandle.Visible = true
                end
            end)
        end
    end)

    bind(self.Connections, closeBtn.MouseButton1Click, function()
        self:RequestClose()
    end)

    return self
end

function VRBX:CreateWindow(options)
    options = options or {}
    if options.SecureBoot == true then
        local ok, result = pcall(createWindowInternal, options)
        if ok then
            return result
        end
        return nil
    end
    return createWindowInternal(options)
end

function Window:CreateTab(options)
    options = type(options) == "table" and options or { Name = tostring(options or "Tab") }
    local theme = self.Theme
    local tab = setmetatable({ Window = self, Name = options.Name or "Tab", Elements = {}, SectionMap = {}, ElementMap = {} }, Tab)

    local page = create("ScrollingFrame", {
        Name = runtimeName(self, tab.Name),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.fromOffset(0, 0),
        Visible = false,
        Parent = self.Pages
    })
    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 0),
        PaddingLeft = UDim.new(0, 0),
        PaddingRight = UDim.new(0, 0),
        PaddingBottom = UDim.new(0, 0),
        Parent = page
    })
    bind(self.Connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 10)
    end)

    local button = makeTextButton({
        Name = runtimeName(self, tab.Name .. "Button"),
        Text = tab.Name,
        TextColor3 = theme.Muted,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = self.TabScroller
    })
    trackTheme(self, button, { BackgroundColor3 = "SurfaceLight" })
    addCorner(button, 8)
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = button })

    tab.Page = page
    tab.Button = button
    tab.Layout = layout
    table.insert(self.Tabs, tab)
    self.TabMap[string.lower(tab.Name)] = tab

    bind(self.Connections, button.MouseButton1Click, function()
        self:SelectTab(tab)
    end)

    if not self.CurrentTab then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SelectTab(tab)
    if type(tab) == "string" then
        tab = self.TabMap[string.lower(tab)]
    end
    if not tab then return nil end
    for _, item in ipairs(self.Tabs) do
        local active = item == tab
        item.Page.Visible = active
        tween(item.Button, {
            BackgroundTransparency = active and 0 or 1,
            TextColor3 = active and self.Theme.Text or self.Theme.Muted
        }, 0.1)
    end
    self.CurrentTab = tab
    return tab
end

function Window:ScrollTo(target)
    if not self.CurrentTab or not target or not target.Parent then return false end
    local page = self.CurrentTab.Page
    local y = target.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
    page.CanvasPosition = Vector2.new(0, math.max(0, y - 6))
    return true
end

function Window:OpenTab(tabName, targetName)
    local tab = self:SelectTab(tabName)
    if not tab then return false end
    if targetName then
        local key = string.lower(tostring(targetName))
        local target = tab.SectionMap[key] or tab.ElementMap[key]
        if target then
            task.defer(function()
                self:ScrollTo(target)
            end)
        end
    end
    return true
end

function Window:SetTheme(theme)
    self.Theme = normalizeTheme(theme)
    self.ThemeName = type(theme) == "string" and theme or "Custom"
    for _, item in ipairs(self.ThemeObjects) do
        local obj = item.Object
        if obj and obj.Parent then
            for prop, key in pairs(item.Props) do
                obj[prop] = self.Theme[key]
            end
        end
    end
    if self.CurrentTab then
        self:SelectTab(self.CurrentTab)
    end
    return true
end

function Window:SetVisible(value)
    local visible = value ~= false
    self.Main.Visible = visible
    self.Shadow.Visible = visible
    return visible
end

function Window:Toggle()
    return self:SetVisible(not self.Main.Visible)
end

function Window:TurnOffBooleanFlags()
    for flag, value in pairs(self.Flags) do
        if value == true then
            self:SetFlag(flag, false)
        end
    end
end

function Window:RequestClose()
    local function closeNow()
        if self.TurnOffAfterDelete then
            self:TurnOffBooleanFlags()
        end
        self:Destroy()
    end
    if self.AskBeforeClose then
        self:Confirm({
            Title = "Close UI",
            Content = "Are you sure you want to permanently close the UI?",
            Type = "warning",
            ConfirmText = "Close",
            CancelText = "Cancel",
            BlackConfirm = true,
            Delay = 2,
            NoErrorCallbacks = true,
            Callback = function(confirmed)
                if confirmed then
                    closeNow()
                end
            end
        })
    else
        closeNow()
    end
end

function Window:SetStatus(text)
    return nil
end

function Window:SetSearch(text)
    self.SearchBox.Text = tostring(text or "")
end

function Window:AddUnloadButton(tab, name)
    return tab:CreateButton({
        Name = name or "Unload UI",
        ButtonText = "Unload",
        Callback = function()
            self:Destroy()
        end
    })
end

function Window:SetToggleKey(key)
    key = coerceKeyCode(key, Enum.KeyCode.RightShift)
    bind(self.Connections, Services.UserInputService.InputBegan, function(input, processed)
        if not processed and input.KeyCode == key then
            self:Toggle()
        end
    end)
end

function Window:RegisterFlag(flag, default, setter)
    if flag then
        self.Flags[flag] = default
        self.Defaults[flag] = default
        self.FlagSetters[flag] = setter
    end
end

function Window:SetFlag(flag, value)
    self:UpdateFlag(flag, value)
    if self.FlagSetters[flag] then
        self.FlagSetters[flag](value, true)
    end
end

function Window:ApplyFlag(flag, value, noAutoSave)
    self:UpdateFlag(flag, value, noAutoSave)
    if self.FlagSetters[flag] then
        self.FlagSetters[flag](value, true)
    end
end

function Window:QueueAutoSave()
    if not self.AutoSaveConfig or self.AutoSaveQueued then return end
    self.AutoSaveQueued = true
    task.delay(0.35, function()
        self.AutoSaveQueued = false
        if self.Gui and self.Gui.Parent and self.AutoSaveConfig then
            self:SaveConfig(self.AutoSaveConfig, true)
        end
    end)
end

function Window:UpdateFlag(flag, value, noAutoSave)
    if flag then
        self.Flags[flag] = value
        if self.FlagWatchers[flag] then
            for _, callback in ipairs(self.FlagWatchers[flag]) do
                task.spawn(callback, value)
            end
        end
        if not noAutoSave then
            self:QueueAutoSave()
        end
    end
end

function Window:WatchFlag(flag, callback)
    self.FlagWatchers[flag] = self.FlagWatchers[flag] or {}
    table.insert(self.FlagWatchers[flag], callback)
end

function Window:BindDependency(flag, element, expected)
    self:WatchFlag(flag, function(value)
        local enabled = expected == nil and value or value == expected
        if element and element.SetDisabled then
            element:SetDisabled(not enabled)
        elseif element and element.Visible then
            element:Visible(enabled)
        end
    end)
    local current = self.Flags[flag]
    if current ~= nil then
        local enabled = expected == nil and current or current == expected
        if element and element.SetDisabled then element:SetDisabled(not enabled) end
    end
end

function Window:ExportConfig()
    local ok, data = pcall(Services.HttpService.JSONEncode, Services.HttpService, self.Flags)
    return ok and data or nil
end

function Window:ImportConfig(data)
    local ok, decoded = pcall(function()
        return Services.HttpService:JSONDecode(tostring(data or "{}"))
    end)
    if not ok or type(decoded) ~= "table" then
        return false, decoded or "Invalid config data."
    end
    for flag, value in pairs(decoded) do
        if self.FlagSetters[flag] then
            self:ApplyFlag(flag, value)
        end
    end
    return true
end

function Window:ResetFlag(flag)
    if self.Defaults[flag] ~= nil then
        self:SetFlag(flag, self.Defaults[flag])
        return true
    end
    return false
end

function Window:ResetAll()
    for flag, value in pairs(self.Defaults) do
        self:SetFlag(flag, value)
    end
    return true
end

function Window:ListConfigs()
    if not listfiles or not isfolder or not isfolder("VRBX") then
        return {}
    end
    local configs = {}
    for _, path in ipairs(listfiles("VRBX")) do
        local name = tostring(path):match("([^/\\]+)%.json$")
        if name then table.insert(configs, name) end
    end
    table.sort(configs)
    return configs
end

function Window:DeleteConfig(name)
    if not delfile or not isfile then
        return false, "File delete APIs are unavailable in this executor."
    end
    name = name or self.AutoSaveConfig or self.Name
    if self.RandomizeConfigNames and self.ConfigSuffix and not tostring(name):find("__" .. tostring(self.ConfigSuffix), 1, true) then
        name = tostring(name) .. "__" .. tostring(self.ConfigSuffix)
    end
    local file = configFileName(name)
    if not isfile(file) then
        return false, "Config not found: " .. file
    end
    local ok, err = pcall(delfile, file)
    if ok and self.AutoSaveConfig == name then
        self.AutoSaveConfig = nil
    end
    return ok, err
end

function Window:AutoLoadConfig(name)
    local ok = self:LoadConfig(name or self.Name)
    return ok
end

function Window:SaveConfig(name, internal)
    if not writefile or not makefolder then
        return false, "File APIs are unavailable in this executor."
    end
    if not isfolder or not isfolder("VRBX") then
        pcall(makefolder, "VRBX")
    end
    name = name or self.Name
    if self.RandomizeConfigNames and self.ConfigSuffix and not tostring(name):find("__" .. tostring(self.ConfigSuffix), 1, true) then
        name = tostring(name) .. "__" .. tostring(self.ConfigSuffix)
    end
    local file = configFileName(name)
    local ok, data = pcall(Services.HttpService.JSONEncode, Services.HttpService, self.Flags)
    if not ok then
        return false, data
    end
    local wrote, err = pcall(writefile, file, data)
    if wrote and not internal then
        self.AutoSaveConfig = name
    end
    return wrote, err
end

function Window:LoadConfig(name)
    if not readfile or not isfile then
        return false, "File APIs are unavailable in this executor."
    end
    name = name or self.Name
    if self.RandomizeConfigNames and self.ConfigSuffix and not tostring(name):find("__" .. tostring(self.ConfigSuffix), 1, true) then
        name = tostring(name) .. "__" .. tostring(self.ConfigSuffix)
    end
    local file = configFileName(name)
    if not isfile(file) then
        return false, "Config not found: " .. file
    end
    local ok, decoded = pcall(function()
        return Services.HttpService:JSONDecode(readfile(file))
    end)
    if not ok or type(decoded) ~= "table" then
        return false, decoded or "Invalid config."
    end
    for flag, value in pairs(decoded) do
        if self.FlagSetters[flag] then
            self:ApplyFlag(flag, value, true)
        end
    end
    self.AutoSaveConfig = name or self.Name
    return true
end

function Window:Notify(options)
    options = options or {}
    local theme = self.Theme
    local notifyType = string.lower(tostring(options.Type or "info"))
    local accent = theme.Accent
    if notifyType == "success" then accent = Color3.fromRGB(70, 210, 130) end
    if notifyType == "warning" then accent = Color3.fromRGB(235, 190, 80) end
    if notifyType == "error" then accent = theme.Danger end
    local holder = create("Frame", {
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.02,
        Size = UDim2.fromOffset(290, 78),
        Position = UDim2.fromOffset(320, 0),
        BorderSizePixel = 0,
        Parent = self.Notifications
    })
    addCorner(holder, 12)
    addStroke(holder, theme.Stroke, 0.15)
    create("Frame", { BackgroundColor3 = accent, BorderSizePixel = 0, Size = UDim2.new(0, 3, 1, 0), Parent = holder })
    makeTextLabel({
        Text = tostring(options.Title or "Notification"),
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Position = UDim2.fromOffset(12, 9),
        Size = UDim2.new(1, -24, 0, 20),
        Parent = holder
    })
    makeTextLabel({
        Text = tostring(options.Content or options.Description or ""),
        TextColor3 = theme.Muted,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.fromOffset(12, 32),
        Size = UDim2.new(1, -24, 1, -38),
        Parent = holder
    })
    tween(holder, { Position = UDim2.fromOffset(0, 0) }, 0.16)
    task.delay(options.Duration or 4, function()
        if holder.Parent then
            tween(holder, { BackgroundTransparency = 1, Position = UDim2.fromOffset(320, 0) }, 0.16)
            task.delay(0.18, function()
                if holder then holder:Destroy() end
            end)
        end
    end)
    return holder
end

function Window:Confirm(options)
    options = options or {}
    local theme = self.Theme
    local confirmColor = theme.Accent
    local confirmType = string.lower(tostring(options.Type or "info"))
    if confirmType == "warning" then confirmColor = Color3.fromRGB(235, 190, 80) end
    if confirmType == "error" then confirmColor = theme.Danger end
    local modal = create("Frame", {
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(300, 132),
        ZIndex = 80,
        Parent = self.Gui
    })
    trackTheme(self, modal, { BackgroundColor3 = "Background" })
    trackTheme(self, addStroke(modal, theme.Stroke, 0.1), { Color = "Stroke" })
    local title = makeTextLabel({ Text = tostring(options.Title or "Confirm"), TextColor3 = theme.Text, Font = Enum.Font.GothamBold, TextSize = 14, Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 22), ZIndex = 81, Parent = modal })
    trackTheme(self, title, { TextColor3 = "Text" })
    local body = makeTextLabel({ Text = tostring(options.Content or "Are you sure?"), TextColor3 = theme.Muted, TextWrapped = true, Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -24, 0, 42), ZIndex = 81, Parent = modal })
    trackTheme(self, body, { TextColor3 = "Muted" })
    if options.BlackConfirm == true then
        confirmColor = Color3.fromRGB(0, 0, 0)
    end
    local yes = makeTextButton({ Text = options.ConfirmText or "Yes", TextColor3 = options.BlackConfirm and Color3.fromRGB(255, 255, 255) or theme.AccentText, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, BackgroundColor3 = confirmColor, ClipsDescendants = true, Position = UDim2.new(1, -142, 1, -38), Size = UDim2.fromOffset(62, 26), ZIndex = 81, Parent = modal })
    local no = makeTextButton({ Text = options.CancelText or "No", TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Center, BackgroundColor3 = theme.SurfaceLight, Position = UDim2.new(1, -72, 1, -38), Size = UDim2.fromOffset(60, 26), ZIndex = 81, Parent = modal })
    if confirmType ~= "warning" and confirmType ~= "error" and options.BlackConfirm ~= true then
        trackTheme(self, yes, { BackgroundColor3 = "Accent", TextColor3 = "AccentText" })
    end
    trackTheme(self, no, { BackgroundColor3 = "SurfaceLight", TextColor3 = "Text" })
    addButtonFeedback(self.Connections, yes, confirmColor, nil, nil, function() return confirmColor end)
    addButtonFeedback(self.Connections, no, theme.SurfaceLight, nil, nil, function() return self.Theme.SurfaceLight end)
    local canConfirm = true
    local delayTime = tonumber(options.Delay or 0) or 0
    if delayTime > 0 then
        canConfirm = false
        local originalText = yes.Text
        local startTime = os.clock()
        local function formatRemaining(seconds)
            local rounded = math.ceil(math.max(0, seconds) * 10) / 10
            return string.format("%.1fs", rounded)
        end
        yes.Text = formatRemaining(delayTime)
        local fill = create("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.82, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 82, Parent = yes })
        tween(fill, { Size = UDim2.fromScale(1, 1) }, delayTime)
        task.spawn(function()
            while yes and yes.Parent and not canConfirm do
                local remaining = delayTime - (os.clock() - startTime)
                yes.Text = formatRemaining(remaining)
                if remaining <= 0 then break end
                task.wait(0.05)
            end
        end)
        task.delay(delayTime, function()
            if yes and yes.Parent then
                canConfirm = true
                yes.Text = originalText
            end
        end)
    end
    bind(self.Connections, yes.MouseButton1Click, function()
        if not canConfirm then return end
        modal:Destroy()
        runCallback(self, options, options.Callback, true)
    end)
    bind(self.Connections, no.MouseButton1Click, function()
        modal:Destroy()
        runCallback(self, options, options.Callback, false)
    end)
    return modal
end

function Window:Destroy()
    disconnectAll(self.Connections)
    if self.Gui then
        self.Gui:Destroy()
    end
end

function Tab:CreateSection(title)
    local theme = self.Window.Theme
    local holder = create("Frame", {
        Name = runtimeName(self.Window, "Section"),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 0, 22),
        Parent = self.Page
    })
    local sectionTitle = makeTextLabel({
        Name = runtimeName(self.Window, "SectionTitle"),
        Text = tostring(title or "Section"),
        TextColor3 = theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Position = UDim2.fromOffset(2, 1),
        Size = UDim2.new(1, -4, 0, 20),
        Parent = holder
    })
    trackTheme(self.Window, sectionTitle, { TextColor3 = "Accent" })
    table.insert(self.Window.Searchables, { Frame = holder, Text = string.lower(tostring(title or "section")) })
    self.SectionMap[string.lower(tostring(title or "section"))] = holder
    return elementHandle(holder)
end

function Tab:CreateLabel(options)
    options = type(options) == "table" and options or { Text = tostring(options or "Label") }
    local card, label = makeCard(self, self.Page, options.Text or "Label", options.Text or "Label", 36)
    label.AnchorPoint = Vector2.new(0, 0)
    label.Size = UDim2.new(1, -20, 1, -12)
    label.Position = UDim2.fromOffset(10, 6)
    return elementHandle(card, {
        Set = function(_, text)
            label.Text = tostring(text)
        end
    })
end

function Tab:CreateParagraph(options)
    options = options or {}
    local theme = self.Window.Theme
    local card, label = makeCard(self, self.Page, options.Title or "Paragraph", (options.Title or "") .. " " .. (options.Content or ""), 74)
    label.AnchorPoint = Vector2.new(0, 0)
    label.Position = UDim2.fromOffset(10, 7)
    label.Size = UDim2.new(1, -20, 0, 18)
    local body = makeTextLabel({
        Text = tostring(options.Content or options.Text or ""),
        TextColor3 = theme.Muted,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.fromOffset(10, 29),
        Size = UDim2.new(1, -20, 1, -34),
        Parent = card
    })
    fitText(body, 10, 13)
    return elementHandle(card, {
        Set = function(_, titleText, bodyText)
            label.Text = tostring(titleText or label.Text)
            body.Text = tostring(bodyText or body.Text)
        end
    })
end

function Tab:CreateButton(options)
    options = options or {}
    local theme = self.Window.Theme
    local flag = options.Flag or options.Name or options.Title or "Button"
    local toggleMode = options.Toggle == true or options.Stateful == true
    local state = not not options.Default
    local handle
    local card, label = makeCard(self, self.Page, options.Name or options.Title or "Button", options.Name or options.Title or "Button", 44)
    if options.Disabled then card.BackgroundTransparency = 0.45 end
    local function buttonColor()
        return self.Window.Theme.Accent
    end
    local btn = makeTextButton(topRightControl({
        Text = options.ButtonText or "Run",
        TextColor3 = theme.AccentText,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = buttonColor(),
        Parent = card
    }, 72, 26, 10, 9))
    trackTheme(self.Window, btn, { BackgroundColor3 = "Accent", TextColor3 = "AccentText" })
    fitText(btn, 9, 12)
    addButtonFeedback(self.Window.Connections, btn, theme.Accent, nil, nil, buttonColor)
    attachTooltip(self.Window, card, options.Tooltip)
    addCorner(btn, 8)
    local function set(value, silent)
        state = not not value
        self.Window:UpdateFlag(flag, state)
        tween(btn, {
            BackgroundColor3 = buttonColor(),
            TextColor3 = self.Window.Theme.AccentText
        }, 0.08)
        if not silent then runCallback(self.Window, options, options.Callback, state) end
    end
    bind(self.Window.Connections, btn.MouseButton1Click, function()
        if handle and handle.Disabled then return end
        if toggleMode then
            set(not state)
        elseif options.Callback then
            runCallback(self.Window, options, options.Callback)
        end
    end)
    if toggleMode then
        self.Window:RegisterFlag(flag, state, set)
    end
    handle = elementHandle(card, {
        Button = btn,
        SetText = function(_, text) label.Text = tostring(text) end,
        Set = function(_, value) if toggleMode then set(value) end end,
        Get = function() return toggleMode and state or nil end
    })
    if options.Disabled then handle:SetDisabled(true) end
    return handle
end

function Tab:CreateToggle(options)
    options = options or {}
    local theme = self.Window.Theme
    local name = options.Name or "Toggle"
    local flag = options.Flag or name
    local state = not not options.Default
    local card, label = makeCard(self, self.Page, name, name, 44)
    local track = makeTextButton(topRightControl({
        Text = "",
        BackgroundColor3 = state and theme.Accent or theme.SurfaceLight,
        Parent = card
    }, 42, 22, 10, 11))
    attachTooltip(self.Window, card, options.Tooltip)
    trackTheme(self.Window, track, { BackgroundColor3 = state and "Accent" or "SurfaceLight" })
    addButtonFeedback(self.Window.Connections, track, state and theme.Accent or theme.SurfaceLight, nil, nil, function()
        local currentTheme = self.Window.Theme
        return state and currentTheme.Accent or currentTheme.SurfaceLight
    end)
    addCorner(track, 12)
    local knob = create("Frame", {
        BackgroundColor3 = theme.Text,
        Size = UDim2.fromOffset(16, 16),
        Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
        BorderSizePixel = 0,
        Parent = track
    })
    trackTheme(self.Window, knob, { BackgroundColor3 = "Text" })
    addCorner(knob, 9)
    local function set(value, silent)
        state = not not value
        self.Window:UpdateFlag(flag, state)
        local currentTheme = self.Window.Theme
        for _, item in ipairs(self.Window.ThemeObjects) do
            if item.Object == track then
                item.Props.BackgroundColor3 = state and "Accent" or "SurfaceLight"
                break
            end
        end
        tween(track, { BackgroundColor3 = state and currentTheme.Accent or currentTheme.SurfaceLight }, 0.12)
        tween(knob, { Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) }, 0.12)
        if not silent then runCallback(self.Window, options, options.Callback, state) end
    end
    bind(self.Window.Connections, track.MouseButton1Click, function() set(not state) end)
    self.Window:RegisterFlag(flag, state, set)
    return elementHandle(card, { Set = function(_, value) set(value) end, Get = function() return state end })
end

function Tab:CreateSlider(options)
    options = options or {}
    local theme = self.Window.Theme
    local name = options.Name or "Slider"
    local flag = options.Flag or name
    local min = options.Min or 0
    local max = options.Max or 100
    if max < min then
        min, max = max, min
    end
    local increment = options.Increment or 1
    if increment <= 0 then
        increment = 1
    end
    local precision = tostring(increment):match("%.(%d+)")
    precision = precision and #precision or 0
    local value = math.clamp(options.Default or min, min, max)
    local card, label = makeCard(self, self.Page, name, name, 56)
    attachTooltip(self.Window, card, options.Tooltip)
    local valueLabel = create("TextBox", {
        Text = tostring(value),
        TextColor3 = theme.Muted,
        PlaceholderText = "",
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 7),
        Size = UDim2.fromOffset(64, 18),
        Parent = card
    })
    trackTheme(self.Window, valueLabel, { TextColor3 = "Muted", BackgroundColor3 = "SurfaceLight" })
    fitText(valueLabel, 9, 12)
    local bar = makeTextButton({
        Text = "",
        BackgroundColor3 = theme.SurfaceLight,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 10, 1, -12),
        Size = UDim2.new(1, -20, 0, 7),
        Parent = card
    })
    trackTheme(self.Window, bar, { BackgroundColor3 = "SurfaceLight" })
    addButtonFeedback(self.Window.Connections, bar, theme.SurfaceLight, nil, nil, function()
        return self.Window.Theme.SurfaceLight
    end)
    addCorner(bar, 4)
    local fill = create("Frame", { BackgroundColor3 = theme.Accent, Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = bar })
    trackTheme(self.Window, fill, { BackgroundColor3 = "Accent" })
    addCorner(fill, 4)
    local dragging = false
    local function round(num)
        local rounded = math.floor((num / increment) + 0.5) * increment
        local multiplier = 10 ^ precision
        return math.floor((rounded * multiplier) + 0.5) / multiplier
    end
    local function formatValue(num)
        if precision <= 0 then
            return tostring(math.floor(num + 0.5))
        end
        local text = string.format("%." .. precision .. "f", num)
        text = text:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
        return text
    end
    local function set(newValue, silent)
        newValue = tonumber(newValue)
        if not newValue then
            valueLabel.Text = formatValue(value)
            return
        end
        value = math.clamp(round(newValue), min, max)
        local alpha = max == min and 1 or (value - min) / (max - min)
        valueLabel.Text = formatValue(value)
        fill.Size = UDim2.fromScale(alpha, 1)
        self.Window:UpdateFlag(flag, value)
        if not silent then runCallback(self.Window, options, options.Callback, value) end
    end
    bind(self.Window.Connections, valueLabel.Focused, function()
        valueLabel.BackgroundTransparency = 0.15
        valueLabel.Text = ""
    end)
    bind(self.Window.Connections, valueLabel.FocusLost, function(enterPressed)
        valueLabel.BackgroundTransparency = 1
        local typed = tonumber(valueLabel.Text)
        if typed then
            set(math.clamp(typed, min, max))
        else
            valueLabel.Text = formatValue(value)
        end
    end)
    local function fromInput(input)
        if bar.AbsoluteSize.X <= 0 then return end
        local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        set(min + ((max - min) * alpha))
    end
    bind(self.Window.Connections, bar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromInput(input)
        end
    end)
    bind(self.Window.Connections, Services.UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    bind(self.Window.Connections, Services.UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end)
    self.Window:RegisterFlag(flag, value, set)
    set(value, true)
    return elementHandle(card, { Set = function(_, v) set(v) end, Get = function() return value end })
end

function Tab:CreateDropdown(options)
    options = options or {}
    local theme = self.Window.Theme
    local name = options.Name or "Dropdown"
    local flag = options.Flag or name
    local values = options.Options or options.Values or {}
    local value = options.Default or values[1]
    local buttonDropdown = options.ButtonDropdown == true
    local dropdownWidth = options.Width or 180
    local rowHeight = 24
    local maxVisibleOptions = options.MaxVisibleOptions or 5
    local maxOptionsHeight = options.MaxHeight or (rowHeight * maxVisibleOptions)
    local card, label = makeCard(self, self.Page, name, name, 44)
    attachTooltip(self.Window, card, options.Tooltip)
    label.Size = UDim2.new(1, -(dropdownWidth + 28), 0, 22)
    local btn = makeTextButton({
        Text = tostring(buttonDropdown and (options.ButtonText or options.Placeholder or "Select...") or (value or "Select")),
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = theme.SurfaceLight,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 9),
        Size = UDim2.fromOffset(dropdownWidth, 26),
        ZIndex = 3,
        Parent = card
    })
    trackTheme(self.Window, btn, { TextColor3 = "Text", BackgroundColor3 = "SurfaceLight" })
    fitText(btn, 9, 12)
    addButtonFeedback(self.Window.Connections, btn, theme.SurfaceLight, nil, nil, function()
        return self.Window.Theme.SurfaceLight
    end)
    addCorner(btn, 8)
    local list = create("Frame", {
        BackgroundColor3 = theme.SurfaceLight,
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(dropdownWidth, 0),
        Position = UDim2.new(1, -10, 0, 44),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = card
    })
    trackTheme(self.Window, list, { BackgroundColor3 = "SurfaceLight" })
    addCorner(list, 9)
    local searchBox = create("TextBox", {
        Text = "",
        PlaceholderText = "Search...",
        ClearTextOnFocus = false,
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 24),
        Position = UDim2.fromOffset(4, 4),
        ZIndex = 3,
        Parent = list
    })
    trackTheme(self.Window, searchBox, { TextColor3 = "Text", PlaceholderColor3 = "Muted", BackgroundColor3 = "Surface" })
    fitText(searchBox, 9, 11)
    create("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7), Parent = searchBox })
    local optionsHolder = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 3,
        Parent = list
    })
    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = optionsHolder
    })
    bind(self.Window.Connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        optionsHolder.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
    end)
    local open = false
    local optionConnections = {}
    local filteredValues = values
    local pointerInsideDropdown = false
    local suppressNextToggle = false
    local function setPageScrolling(enabled)
        if self.Page and self.Page.Parent then
            self.Page.ScrollingEnabled = enabled
        end
    end
    local function hasDropdownOverflow()
        return optionsHolder.CanvasSize.Y.Offset > optionsHolder.AbsoluteSize.Y + 1
    end
    local function isInside(instance, point)
        local pos = instance.AbsolutePosition
        local size = instance.AbsoluteSize
        return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
    end
    local function set(newValue, silent)
        if buttonDropdown then
            if not silent then runCallback(self.Window, options, options.Callback, newValue) end
            return
        end
        value = newValue
        btn.Text = tostring(newValue or "Select")
        self.Window:UpdateFlag(flag, value)
        if not silent then runCallback(self.Window, options, options.Callback, value) end
    end
    local function setOpen(state)
        open = state
        pointerInsideDropdown = false
        setPageScrolling(true)
        local optionsHeight = math.min(#filteredValues * rowHeight, maxOptionsHeight)
        local h = open and (32 + optionsHeight) or 0
        tween(card, { Size = UDim2.new(1, -16, 0, 48 + h) }, 0.12)
        tween(list, { Size = UDim2.fromOffset(dropdownWidth, h) }, 0.12)
        tween(optionsHolder, { Size = UDim2.new(1, 0, 0, optionsHeight) }, 0.12)
        if open then
            searchBox.Text = ""
            optionsHolder.CanvasPosition = Vector2.new(0, 0)
            task.defer(function()
                if open and pointerInsideDropdown and hasDropdownOverflow() then
                    setPageScrolling(false)
                end
            end)
        else
            searchBox:ReleaseFocus()
        end
    end
    local function rebuildOptions(query)
        disconnectAll(optionConnections)
        for _, child in ipairs(optionsHolder:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        query = string.lower(query or "")
        filteredValues = {}
        for _, item in ipairs(values) do
            if query == "" or string.find(string.lower(tostring(item)), query, 1, true) then
                table.insert(filteredValues, item)
            end
        end
        for _, item in ipairs(filteredValues) do
            local opt = makeTextButton({
                Text = tostring(item),
                TextColor3 = theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Center,
                BackgroundColor3 = theme.SurfaceLight,
                BackgroundTransparency = 0,
                Size = UDim2.new(1, -2, 0, rowHeight),
                ZIndex = 3,
                Parent = optionsHolder
            })
            trackTheme(self.Window, opt, { TextColor3 = "Muted", BackgroundColor3 = "SurfaceLight" })
            fitText(opt, 9, 12)
            addButtonFeedback(optionConnections, opt, theme.SurfaceLight, nil, nil, function()
                return self.Window.Theme.SurfaceLight
            end)
            bind(optionConnections, opt.MouseButton1Click, function()
                set(item)
                setOpen(false)
            end)
        end
        if open then
            local optionsHeight = math.min(#filteredValues * rowHeight, maxOptionsHeight)
            local h = 32 + optionsHeight
            tween(card, { Size = UDim2.new(1, -16, 0, 48 + h) }, 0.08)
            tween(list, { Size = UDim2.fromOffset(dropdownWidth, h) }, 0.08)
            tween(optionsHolder, { Size = UDim2.new(1, 0, 0, optionsHeight) }, 0.08)
            optionsHolder.CanvasPosition = Vector2.new(0, 0)
        end
    end
    local function rebuild(newValues)
        values = newValues or values
        rebuildOptions(searchBox.Text)
    end
    rebuild(values)
    bind(self.Window.Connections, searchBox:GetPropertyChangedSignal("Text"), function()
        if open then
            rebuildOptions(searchBox.Text)
            setPageScrolling(not (pointerInsideDropdown and hasDropdownOverflow()))
        end
    end)
    bind(self.Window.Connections, list.MouseEnter, function()
        pointerInsideDropdown = true
        if open and hasDropdownOverflow() then
            setPageScrolling(false)
        end
    end)
    bind(self.Window.Connections, list.MouseLeave, function()
        pointerInsideDropdown = false
        setPageScrolling(true)
    end)
    bind(self.Window.Connections, searchBox.FocusLost, function()
        task.defer(function()
            if open and not pointerInsideDropdown then
                suppressNextToggle = true
                setOpen(false)
                task.delay(0.12, function()
                    suppressNextToggle = false
                end)
            end
        end)
    end)
    bind(self.Window.Connections, Services.UserInputService.InputBegan, function(input)
        if not open then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if isInside(btn, input.Position) or isInside(list, input.Position) then return end
        setOpen(false)
    end)
    bind(self.Window.Connections, btn.MouseButton1Click, function()
        if suppressNextToggle then
            suppressNextToggle = false
            return
        end
        setOpen(not open)
    end)
    if not buttonDropdown then
        self.Window:RegisterFlag(flag, value, set)
    end
    return elementHandle(card, {
        Set = function(_, v) set(v) end,
        SetText = function(_, text) btn.Text = tostring(text or "Select...") end,
        Refresh = function(_, newValues) rebuild(newValues) end,
        Get = function() return buttonDropdown and nil or value end
    })
end

function Tab:CreateMultiDropdown(options)
    options = options or {}
    local selected = {}
    for _, item in ipairs(options.Default or {}) do
        selected[tostring(item)] = true
    end
    local list = options.Options or options.Values or {}
    local display = {}
    for _, item in ipairs(list) do table.insert(display, tostring(item)) end
    local dropdown
    local function selectedList()
        local values = {}
        for key, enabled in pairs(selected) do
            if enabled then table.insert(values, key) end
        end
        table.sort(values)
        return values
    end
    dropdown = self:CreateDropdown({
        Name = options.Name or "Multi Dropdown",
        Flag = options.Flag,
        Options = display,
        Default = "Select...",
        Width = options.Width,
        MaxVisibleOptions = options.MaxVisibleOptions,
        Tooltip = options.Tooltip,
        Callback = function(value)
            selected[tostring(value)] = not selected[tostring(value)]
            local values = selectedList()
            dropdown:SetText(#values > 0 and table.concat(values, ", ") or "Select...")
            if options.Flag then
                self.Window:UpdateFlag(options.Flag, values)
            end
            runCallback(self.Window, options, options.Callback, values)
        end
    })
    if options.Flag then
        self.Window:RegisterFlag(options.Flag, selectedList(), function(values, silent)
            selected = {}
            for _, item in ipairs(values or {}) do selected[tostring(item)] = true end
            local current = selectedList()
            dropdown:SetText(#current > 0 and table.concat(current, ", ") or "Select...")
            if not silent then runCallback(self.Window, options, options.Callback, current) end
        end)
    end
    local initial = selectedList()
    dropdown:SetText(#initial > 0 and table.concat(initial, ", ") or "Select...")
    return dropdown
end

function Tab:CreateColorPicker(options)
    options = options or {}
    local default = options.Default or Color3.fromRGB(255, 255, 255)
    local values = {
        R = math.floor(default.R * 255 + 0.5),
        G = math.floor(default.G * 255 + 0.5),
        B = math.floor(default.B * 255 + 0.5)
    }
    self:CreateSection(options.Name or "Color Picker")
    local preview = self:CreateLabel("Preview")
    local function currentColor()
        return Color3.fromRGB(values.R, values.G, values.B)
    end
    local function update(silent)
        local color = currentColor()
        if preview.Instance then
            preview.Instance.BackgroundTransparency = 0
            preview.Instance.BackgroundColor3 = color
        end
        if options.Flag then
            self.Window:UpdateFlag(options.Flag, { values.R, values.G, values.B })
        end
        if not silent then runCallback(self.Window, options, options.Callback, color) end
    end
    local r = self:CreateSlider({ Name = "Red", Min = 0, Max = 255, Increment = 1, Default = values.R, Callback = function(v) values.R = v update() end })
    local g = self:CreateSlider({ Name = "Green", Min = 0, Max = 255, Increment = 1, Default = values.G, Callback = function(v) values.G = v update() end })
    local b = self:CreateSlider({ Name = "Blue", Min = 0, Max = 255, Increment = 1, Default = values.B, Callback = function(v) values.B = v update() end })
    if options.Flag then
        self.Window:RegisterFlag(options.Flag, { values.R, values.G, values.B }, function(saved, silent)
            values.R = saved and saved[1] or values.R
            values.G = saved and saved[2] or values.G
            values.B = saved and saved[3] or values.B
            r:Set(values.R); g:Set(values.G); b:Set(values.B)
            update(silent)
        end)
    end
    update(true)
    return elementHandle(preview.Instance, { Get = currentColor, Set = function(_, color) values.R = math.floor(color.R * 255 + 0.5); values.G = math.floor(color.G * 255 + 0.5); values.B = math.floor(color.B * 255 + 0.5); update() end })
end

function Tab:CreateCollapsibleSection(title)
    local section = self:CreateSection(title)
    local children = {}
    local collapsed = false
    local api = elementHandle(section.Instance, {
        Add = function(_, element)
            table.insert(children, element)
            return element
        end,
        SetCollapsed = function(_, value)
            collapsed = value ~= false
            for _, element in ipairs(children) do
                if element and element.Instance then element.Instance.Visible = not collapsed end
            end
        end,
        Toggle = function(selfHandle)
            selfHandle:SetCollapsed(not collapsed)
        end,
        Get = function() return collapsed end
    })
    return api
end

function Tab:CreateTextbox(options)
    options = options or {}
    local theme = self.Window.Theme
    local name = options.Name or "Textbox"
    local flag = options.Flag or name
    local card, label = makeCard(self, self.Page, name, name, 46)
    attachTooltip(self.Window, card, options.Tooltip)
    local box = create("TextBox", topRightControl({
        Text = tostring(options.Default or ""),
        PlaceholderText = options.Placeholder or "Enter text...",
        ClearTextOnFocus = false,
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundColor3 = theme.SurfaceLight,
        BorderSizePixel = 0,
        Parent = card
    }, 150, 28, 10, 9))
    trackTheme(self.Window, box, { TextColor3 = "Text", PlaceholderColor3 = "Muted", BackgroundColor3 = "SurfaceLight" })
    fitText(box, 9, 12)
    bind(self.Window.Connections, box.MouseEnter, function()
        tween(box, { BackgroundColor3 = shade(self.Window.Theme.SurfaceLight, 0.05) }, 0.08)
    end)
    bind(self.Window.Connections, box.MouseLeave, function()
        if not box:IsFocused() then
            tween(box, { BackgroundColor3 = self.Window.Theme.SurfaceLight }, 0.08)
        end
    end)
    bind(self.Window.Connections, box.Focused, function()
        tween(box, { BackgroundColor3 = shade(self.Window.Theme.SurfaceLight, 0.07) }, 0.08)
    end)
    addCorner(box, 8)
    create("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = box })
    local function set(text, silent)
        box.Text = tostring(text or "")
        self.Window:UpdateFlag(flag, box.Text)
        if not silent then runCallback(self.Window, options, options.Callback, box.Text) end
    end
    bind(self.Window.Connections, box.FocusLost, function(enter)
        if options.SubmitOnEnter and not enter then return end
        tween(box, { BackgroundColor3 = self.Window.Theme.SurfaceLight }, 0.08)
        set(box.Text)
    end)
    self.Window:RegisterFlag(flag, box.Text, set)
    return elementHandle(card, { Set = function(_, text) set(text) end, Get = function() return box.Text end })
end

function Tab:CreateKeybind(options)
    options = options or {}
    local theme = self.Window.Theme
    local name = options.Name or "Keybind"
    local flag = options.Flag or name
    local key = coerceKeyCode(options.Default, Enum.KeyCode.RightShift)
    local listening = false
    local card, label = makeCard(self, self.Page, name, name, 44)
    attachTooltip(self.Window, card, options.Tooltip)
    local btn = makeTextButton(topRightControl({
        Text = key.Name,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = theme.SurfaceLight,
        Parent = card
    }, 104, 26, 10, 9))
    trackTheme(self.Window, btn, { TextColor3 = "Text", BackgroundColor3 = "SurfaceLight" })
    fitText(btn, 9, 12)
    addButtonFeedback(self.Window.Connections, btn, theme.SurfaceLight, nil, nil, function()
        return self.Window.Theme.SurfaceLight
    end)
    addCorner(btn, 8)
    local function set(newKey, silent)
        newKey = coerceKeyCode(newKey, key)
        if newKey then
            key = newKey
            btn.Text = key.Name
            self.Window:UpdateFlag(flag, key.Name)
            if not silent then runCallback(self.Window, options, options.ChangedCallback, key) end
        end
    end
    bind(self.Window.Connections, btn.MouseButton1Click, function()
        listening = true
        btn.Text = "..."
    end)
    bind(self.Window.Connections, Services.UserInputService.InputBegan, function(input, processed)
        if processed then return end
        if listening and input.KeyCode ~= Enum.KeyCode.Unknown then
            listening = false
            set(input.KeyCode)
            return
        end
        if input.KeyCode == key and options.Callback then
            runCallback(self.Window, options, options.Callback)
        end
    end)
    self.Window:RegisterFlag(flag, key.Name, set)
    return elementHandle(card, { Set = function(_, newKey) set(newKey) end, Get = function() return key end })
end

return VRBX
