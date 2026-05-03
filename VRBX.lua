local VRBX = {}
VRBX.__index = VRBX
VRBX.Version = "1.0.0"

local Services = {
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    HttpService = game:GetService("HttpService")
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

local function configFileName(name)
    name = tostring(name or "Default"):gsub("[^%w_%-%s]", "")
    return "VRBX/" .. name .. ".json"
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
    props.BorderSizePixel = 0
    return create("TextButton", props)
end

local function makeTextLabel(props)
    props.Font = props.Font or Enum.Font.Gotham
    props.TextSize = props.TextSize or 13
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    props.BackgroundTransparency = props.BackgroundTransparency == nil and 1 or props.BackgroundTransparency
    props.BorderSizePixel = 0
    return create("TextLabel", props)
end

local function makeCard(self, parent, title, searchText, height)
    local theme = self.Window.Theme
    local card = create("Frame", {
        Name = "ElementCard",
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.18,
        Size = UDim2.new(1, 0, 0, height or 44),
        BorderSizePixel = 0,
        Parent = parent
    })
    addCorner(card, 9)
    addStroke(card, theme.Stroke, 0.35)

    local label = makeTextLabel({
        Name = "Title",
        Text = title or "Element",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        Size = UDim2.new(1, -150, 0, 20),
        Position = UDim2.fromOffset(10, 7),
        Parent = card
    })

    table.insert(self.Window.Searchables, { Frame = card, Text = string.lower(searchText or title or "") })
    return card, label
end

function VRBX:CreateWindow(options)
    options = options or {}
    local theme = normalizeTheme(options.Theme)
    local gui = create("ScreenGui", {
        Name = options.Name or "VRBX",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = safeParent()
    })

    local self = setmetatable({
        Gui = gui,
        Theme = theme,
        Tabs = {},
        Flags = {},
        FlagSetters = {},
        Searchables = {},
        Connections = {},
        CurrentTab = nil,
        Minimized = false,
        Name = options.Name or options.Title or "VRBX"
    }, Window)

    local size = options.Size or UDim2.fromOffset(620, 430)
    local normalSize = size
    local pos = options.Position or UDim2.new(0.5, -310, 0.5, -215)

    local shadow = create("Frame", {
        Name = "Shadow",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Position = pos,
        Size = size,
        BorderSizePixel = 0,
        Parent = gui
    })
    addCorner(shadow, 16)

    local main = create("Frame", {
        Name = "Main",
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.02,
        Position = pos,
        Size = size,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui
    })
    addCorner(main, 16)
    addStroke(main, theme.Stroke, 0.05)

    local topbar = create("Frame", {
        Name = "Topbar",
        Active = true,
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.14,
        Size = UDim2.new(1, 0, 0, 44),
        BorderSizePixel = 0,
        Parent = main
    })

    local title = makeTextLabel({
        Name = "WindowTitle",
        Text = options.Title or "VRBX",
        TextColor3 = theme.Text,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(0, 210, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        Parent = topbar
    })

    local search = create("TextBox", {
        Name = "Search",
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
        Position = UDim2.new(1, -276, 0, 8),
        Parent = topbar
    })
    addCorner(search, 8)
    addStroke(search, theme.Stroke, 0.35)
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8), Parent = search })

    local configBtn = makeTextButton({
        Name = "ConfigButton",
        Text = "CFG",
        TextColor3 = theme.Muted,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 0.18,
        Size = UDim2.fromOffset(34, 28),
        Position = UDim2.new(1, -100, 0, 8),
        Parent = topbar
    })
    addCorner(configBtn, 8)

    local minBtn = makeTextButton({
        Name = "Minimize",
        Text = "-",
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 0.18,
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -62, 0, 8),
        Parent = topbar
    })
    addCorner(minBtn, 8)

    local closeBtn = makeTextButton({
        Name = "Close",
        Text = "x",
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = theme.Danger,
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -30, 0, 8),
        Parent = topbar
    })
    addCorner(closeBtn, 8)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.55,
        Position = UDim2.fromOffset(12, 58),
        Size = UDim2.new(0, 144, 1, -70),
        BorderSizePixel = 0,
        Parent = main
    })
    addCorner(sidebar, 10)
    addStroke(sidebar, theme.Stroke, 0.55)

    local tabList = create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sidebar
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = sidebar
    })

    local pages = create("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(168, 58),
        Size = UDim2.new(1, -180, 1, -70),
        BorderSizePixel = 0,
        Parent = main
    })

    local notifications = create("Frame", {
        Name = "Notifications",
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
        Name = "ResizeHandle",
        Active = true,
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = theme.Muted,
        BackgroundTransparency = 0.35,
        Position = UDim2.new(1, -5, 1, -5),
        Size = UDim2.fromOffset(12, 12),
        BorderSizePixel = 0,
        Parent = main
    })
    addCorner(resizeHandle, 5)

    self.Main = main
    self.Shadow = shadow
    self.Topbar = topbar
    self.Sidebar = sidebar
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
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local w = math.max(480, startSize.X + delta.X)
            local h = math.max(300, startSize.Y + delta.Y)
            main.Size = UDim2.fromOffset(w, h)
            shadow.Size = main.Size
            normalSize = main.Size
        end
    end)

    bind(self.Connections, minBtn.MouseButton1Click, function()
        self.Minimized = not self.Minimized
        if self.Minimized then
            tween(main, { Size = UDim2.fromOffset(main.AbsoluteSize.X, 44) }, 0.16)
            tween(shadow, { Size = UDim2.fromOffset(main.AbsoluteSize.X, 44) }, 0.16)
        else
            tween(main, { Size = normalSize }, 0.16)
            tween(shadow, { Size = normalSize }, 0.16)
        end
    end)

    bind(self.Connections, closeBtn.MouseButton1Click, function()
        self:Destroy()
    end)

    bind(self.Connections, configBtn.MouseButton1Click, function()
        self:Notify({ Title = "Config", Content = "Use Window:SaveConfig(name) and Window:LoadConfig(name).", Duration = 3 })
    end)

    return self
end

function Window:CreateTab(options)
    options = type(options) == "table" and options or { Name = tostring(options or "Tab") }
    local theme = self.Theme
    local tab = setmetatable({ Window = self, Name = options.Name or "Tab", Elements = {} }, Tab)

    local page = create("ScrollingFrame", {
        Name = tab.Name,
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
        Name = tab.Name .. "Button",
        Text = tab.Name,
        TextColor3 = theme.Muted,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = self.Sidebar
    })
    addCorner(button, 8)
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = button })

    tab.Page = page
    tab.Button = button
    table.insert(self.Tabs, tab)

    bind(self.Connections, button.MouseButton1Click, function()
        self:SelectTab(tab)
    end)

    if not self.CurrentTab then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SelectTab(tab)
    for _, item in ipairs(self.Tabs) do
        local active = item == tab
        item.Page.Visible = active
        tween(item.Button, {
            BackgroundTransparency = active and 0 or 1,
            TextColor3 = active and self.Theme.Text or self.Theme.Muted
        }, 0.1)
    end
    self.CurrentTab = tab
end

function Window:RegisterFlag(flag, default, setter)
    if flag then
        self.Flags[flag] = default
        self.FlagSetters[flag] = setter
    end
end

function Window:SetFlag(flag, value)
    self.Flags[flag] = value
    if self.FlagSetters[flag] then
        self.FlagSetters[flag](value, true)
    end
end

function Window:SaveConfig(name)
    if not writefile or not makefolder then
        return false, "File APIs are unavailable in this executor."
    end
    if not isfolder or not isfolder("VRBX") then
        pcall(makefolder, "VRBX")
    end
    local file = configFileName(name or self.Name)
    local ok, data = pcall(Services.HttpService.JSONEncode, Services.HttpService, self.Flags)
    if not ok then
        return false, data
    end
    local wrote, err = pcall(writefile, file, data)
    return wrote, err
end

function Window:LoadConfig(name)
    if not readfile or not isfile then
        return false, "File APIs are unavailable in this executor."
    end
    local file = configFileName(name or self.Name)
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
            self:SetFlag(flag, value)
        end
    end
    return true
end

function Window:Notify(options)
    options = options or {}
    local theme = self.Theme
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

function Window:Destroy()
    disconnectAll(self.Connections)
    if self.Gui then
        self.Gui:Destroy()
    end
end

function Tab:CreateSection(title)
    local theme = self.Window.Theme
    local holder = create("Frame", {
        Name = "Section",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Parent = self.Page
    })
    makeTextLabel({
        Text = tostring(title or "Section"),
        TextColor3 = theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Position = UDim2.fromOffset(2, 1),
        Size = UDim2.new(1, -4, 0, 20),
        Parent = holder
    })
    table.insert(self.Window.Searchables, { Frame = holder, Text = string.lower(tostring(title or "section")) })
    return holder
end

function Tab:CreateLabel(options)
    options = type(options) == "table" and options or { Text = tostring(options or "Label") }
    local card, label = makeCard(self, self.Page, options.Text or "Label", options.Text or "Label", 36)
    label.Position = UDim2.fromOffset(10, 8)
    return {
        Instance = card,
        Set = function(_, text)
            label.Text = tostring(text)
        end
    }
end

function Tab:CreateParagraph(options)
    options = options or {}
    local theme = self.Window.Theme
    local card, label = makeCard(self, self.Page, options.Title or "Paragraph", (options.Title or "") .. " " .. (options.Content or ""), 74)
    local body = makeTextLabel({
        Text = tostring(options.Content or options.Text or ""),
        TextColor3 = theme.Muted,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.fromOffset(10, 29),
        Size = UDim2.new(1, -20, 1, -34),
        Parent = card
    })
    return {
        Instance = card,
        Set = function(_, titleText, bodyText)
            label.Text = tostring(titleText or label.Text)
            body.Text = tostring(bodyText or body.Text)
        end
    }
end

function Tab:CreateButton(options)
    options = options or {}
    local theme = self.Window.Theme
    local card, label = makeCard(self, self.Page, options.Name or options.Title or "Button", options.Name or options.Title or "Button", 44)
    local btn = makeTextButton({
        Text = options.ButtonText or "Run",
        TextColor3 = theme.AccentText,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = theme.Accent,
        Size = UDim2.fromOffset(72, 26),
        Position = UDim2.new(1, -82, 0, 9),
        Parent = card
    })
    addCorner(btn, 8)
    bind(self.Window.Connections, btn.MouseButton1Click, function()
        if options.Callback then
            task.spawn(options.Callback)
        end
    end)
    return { Instance = card, Button = btn, SetText = function(_, text) label.Text = tostring(text) end }
end

function Tab:CreateToggle(options)
    options = options or {}
    local theme = self.Window.Theme
    local name = options.Name or "Toggle"
    local flag = options.Flag or name
    local state = not not options.Default
    local card, label = makeCard(self, self.Page, name, name, 44)
    local track = makeTextButton({
        Text = "",
        BackgroundColor3 = state and theme.Accent or theme.SurfaceLight,
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -52, 0, 11),
        Parent = card
    })
    addCorner(track, 12)
    local knob = create("Frame", {
        BackgroundColor3 = theme.Text,
        Size = UDim2.fromOffset(16, 16),
        Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
        BorderSizePixel = 0,
        Parent = track
    })
    addCorner(knob, 9)
    local function set(value, silent)
        state = not not value
        self.Window.Flags[flag] = state
        tween(track, { BackgroundColor3 = state and theme.Accent or theme.SurfaceLight }, 0.12)
        tween(knob, { Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) }, 0.12)
        if not silent and options.Callback then task.spawn(options.Callback, state) end
    end
    bind(self.Window.Connections, track.MouseButton1Click, function() set(not state) end)
    self.Window:RegisterFlag(flag, state, set)
    return { Instance = card, Set = function(_, value) set(value) end, Get = function() return state end }
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
    local value = math.clamp(options.Default or min, min, max)
    local card, label = makeCard(self, self.Page, name, name, 56)
    local valueLabel = makeTextLabel({
        Text = tostring(value),
        TextColor3 = theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -80, 0, 7),
        Size = UDim2.fromOffset(70, 20),
        Parent = card
    })
    local bar = makeTextButton({
        Text = "",
        BackgroundColor3 = theme.SurfaceLight,
        Position = UDim2.fromOffset(10, 35),
        Size = UDim2.new(1, -20, 0, 7),
        Parent = card
    })
    addCorner(bar, 4)
    local fill = create("Frame", { BackgroundColor3 = theme.Accent, Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = bar })
    addCorner(fill, 4)
    local dragging = false
    local function round(num)
        return math.floor((num / increment) + 0.5) * increment
    end
    local function set(newValue, silent)
        value = math.clamp(round(newValue), min, max)
        local alpha = max == min and 1 or (value - min) / (max - min)
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.fromScale(alpha, 1)
        self.Window.Flags[flag] = value
        if not silent and options.Callback then task.spawn(options.Callback, value) end
    end
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
    return { Instance = card, Set = function(_, v) set(v) end, Get = function() return value end }
end

function Tab:CreateDropdown(options)
    options = options or {}
    local theme = self.Window.Theme
    local name = options.Name or "Dropdown"
    local flag = options.Flag or name
    local values = options.Options or options.Values or {}
    local value = options.Default or values[1]
    local card, label = makeCard(self, self.Page, name, name, 44)
    local btn = makeTextButton({
        Text = tostring(value or "Select"),
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = theme.SurfaceLight,
        Size = UDim2.fromOffset(120, 26),
        Position = UDim2.new(1, -130, 0, 9),
        Parent = card
    })
    addCorner(btn, 8)
    local list = create("Frame", {
        BackgroundColor3 = theme.SurfaceLight,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromOffset(0, 44),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = card
    })
    addCorner(list, 9)
    local layout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
    local open = false
    local optionConnections = {}
    local function set(newValue, silent)
        value = newValue
        btn.Text = tostring(newValue or "Select")
        self.Window.Flags[flag] = value
        if not silent and options.Callback then task.spawn(options.Callback, value) end
    end
    local function setOpen(state)
        open = state
        local h = open and math.min(#values * 26, 130) or 0
        tween(card, { Size = UDim2.new(1, 0, 0, 44 + h) }, 0.12)
        tween(list, { Size = UDim2.new(1, 0, 0, h) }, 0.12)
    end
    local function rebuild(newValues)
        disconnectAll(optionConnections)
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        values = newValues or values
        for _, item in ipairs(values) do
            local opt = makeTextButton({
                Text = tostring(item),
                TextColor3 = theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Center,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 26),
                Parent = list
            })
            bind(optionConnections, opt.MouseButton1Click, function()
                set(item)
                setOpen(false)
            end)
        end
        setOpen(open)
    end
    rebuild(values)
    bind(self.Window.Connections, btn.MouseButton1Click, function() setOpen(not open) end)
    self.Window:RegisterFlag(flag, value, set)
    return { Instance = card, Set = function(_, v) set(v) end, Refresh = function(_, newValues) rebuild(newValues) end, Get = function() return value end }
end

function Tab:CreateTextbox(options)
    options = options or {}
    local theme = self.Window.Theme
    local name = options.Name or "Textbox"
    local flag = options.Flag or name
    local card, label = makeCard(self, self.Page, name, name, 46)
    local box = create("TextBox", {
        Text = tostring(options.Default or ""),
        PlaceholderText = options.Placeholder or "Enter text...",
        ClearTextOnFocus = false,
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = theme.SurfaceLight,
        Size = UDim2.fromOffset(150, 28),
        Position = UDim2.new(1, -160, 0, 9),
        BorderSizePixel = 0,
        Parent = card
    })
    addCorner(box, 8)
    create("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = box })
    local function set(text, silent)
        box.Text = tostring(text or "")
        self.Window.Flags[flag] = box.Text
        if not silent and options.Callback then task.spawn(options.Callback, box.Text) end
    end
    bind(self.Window.Connections, box.FocusLost, function(enter)
        if options.SubmitOnEnter and not enter then return end
        set(box.Text)
    end)
    self.Window:RegisterFlag(flag, box.Text, set)
    return { Instance = card, Set = function(_, text) set(text) end, Get = function() return box.Text end }
end

function Tab:CreateKeybind(options)
    options = options or {}
    local theme = self.Window.Theme
    local name = options.Name or "Keybind"
    local flag = options.Flag or name
    local key = coerceKeyCode(options.Default, Enum.KeyCode.RightShift)
    local listening = false
    local card, label = makeCard(self, self.Page, name, name, 44)
    local btn = makeTextButton({
        Text = key.Name,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundColor3 = theme.SurfaceLight,
        Size = UDim2.fromOffset(104, 26),
        Position = UDim2.new(1, -114, 0, 9),
        Parent = card
    })
    addCorner(btn, 8)
    local function set(newKey, silent)
        newKey = coerceKeyCode(newKey, key)
        if newKey then
            key = newKey
            btn.Text = key.Name
            self.Window.Flags[flag] = key.Name
            if not silent and options.ChangedCallback then task.spawn(options.ChangedCallback, key) end
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
            task.spawn(options.Callback)
        end
    end)
    self.Window:RegisterFlag(flag, key.Name, set)
    return { Instance = card, Set = function(_, newKey) set(newKey) end, Get = function() return key end }
end

return VRBX
