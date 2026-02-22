return function(Theme, Utils, TweenController)
    local Tabs = {}
    Tabs.__index = Tabs

    --[[
        Standalone Tabs widget (when used outside of Window).
        Config: {}
    ]]
    function Tabs.new(parent, config)
        local self = setmetatable({}, Tabs)

        self.Instance = Utils.Create("Frame", {
            Name               = "TabsContainer",
            Size               = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Parent             = parent
        })

        -- Sidebar-style button list
        self.ButtonsContainer = Utils.Create("ScrollingFrame", {
            Name               = "TabButtons",
            Size               = UDim2.new(0, 148, 1, 0),
            BackgroundColor3   = Theme.Colors.Background2,
            BackgroundTransparency = 0.20,
            ScrollBarThickness = 2,
            BorderSizePixel    = 0,
            Parent             = self.Instance
        })
        Utils.Corner(self.ButtonsContainer, Theme.Sizes.RadiusLarge)
        Utils.Stroke(self.ButtonsContainer, Theme.Colors.Border, 1, Theme.Trans.Border)

        self.ButtonsLayout = Utils.Create("UIListLayout", {
            Padding            = UDim.new(0, 2),
            SortOrder          = Enum.SortOrder.LayoutOrder,
            Parent             = self.ButtonsContainer
        })
        Utils.Padding(self.ButtonsContainer, 7, 10)

        -- Content area
        self.ContentContainer = Utils.Create("Frame", {
            Name               = "TabContent",
            Size               = UDim2.new(1, -162, 1, 0),
            Position           = UDim2.new(0, 162, 0, 0),
            BackgroundTransparency = 1,
            Parent             = self.Instance
        })

        self.Pages     = {}
        self.ActivePage = nil

        return self
    end

    --[[
        options:
            Icon   : string
            Badge  : string
            Locked : bool
    ]]
    function Tabs:AddTab(name, options)
        local opts   = options or {}
        local locked = opts.Locked or false

        -- Tab button (matches .tab-btn style)
        local btn = Utils.Create("TextButton", {
            Name               = name .. "_Btn",
            Text               = "",
            Size               = UDim2.new(1, -14, 0, 36),
            BackgroundColor3   = Theme.Colors.Surface,
            BackgroundTransparency = 1,
            AutoButtonColor    = false,
            Parent             = self.ButtonsContainer
        })
        Utils.Corner(btn, Theme.Sizes.RadiusMedium)

        -- Left accent bar (matches .tab-btn::before)
        local marker = Utils.Create("Frame", {
            Name               = "Marker",
            Size               = UDim2.new(0, 3, 0, 0),
            Position           = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint        = Vector2.new(0, 0.5),
            BackgroundColor3   = Theme.Colors.Accent,
            BorderSizePixel    = 0,
            Visible            = false,
            Parent             = btn
        })
        Utils.Corner(marker, UDim.new(1, 0))
        Theme:Bind(marker, {BackgroundColor3 = "Accent"})

        -- Icon
        local iconLbl = Utils.Create("TextLabel", {
            Name               = "Icon",
            Text               = opts.Icon or "○",
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextNormal,
            TextColor3         = Theme.Colors.TextMuted,
            BackgroundTransparency = 1,
            Size               = UDim2.new(0, 15, 0, 36),
            Position           = UDim2.new(0, 8, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Left,
            Parent             = btn
        })
        Theme:Bind(iconLbl, {TextColor3 = "TextMuted"})

        -- Label
        local lbl = Utils.Create("TextLabel", {
            Name               = "Label",
            Text               = name,
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextNormal,
            TextColor3         = Theme.Colors.TextLow,
            BackgroundTransparency = 1,
            Size               = UDim2.new(1, -60, 1, 0),
            Position           = UDim2.new(0, 28, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Left,
            Parent             = btn
        })
        Theme:Bind(lbl, {TextColor3 = "TextLow"})

        -- Badge (matches .t-badge)
        local badge = nil
        if opts.Badge then
            badge = Utils.Create("TextLabel", {
                Name               = "Badge",
                Text               = tostring(opts.Badge),
                Font               = Theme.Fonts.Mono,
                TextSize           = Theme.Sizes.TextXS,
                TextColor3         = Theme.Colors.Accent,
                BackgroundColor3   = Theme.Colors.Accent,
                BackgroundTransparency = Theme.Trans.AccentGlow,
                AnchorPoint        = Vector2.new(1, 0.5),
                Position           = UDim2.new(1, -4, 0.5, 0),
                Size               = UDim2.new(0, 0, 0, 16),
                AutomaticSize      = Enum.AutomaticSize.X,
                Parent             = btn
            })
            Utils.Corner(badge, Theme.Sizes.RadiusSmall)
            Utils.Stroke(badge, Theme.Colors.Accent, 1, Theme.Trans.AccentBorder)
            Utils.Padding(badge, 5, 0)
            Theme:Bind(badge, {TextColor3 = "Accent", BackgroundColor3 = "Accent"})
        end

        -- Lock icon for locked tabs
        if locked then
            local lockIco = Utils.Create("TextLabel", {
                Name               = "LockIcon",
                Text               = "🔒",
                Font               = Theme.Fonts.Main,
                TextSize           = Theme.Sizes.TextSmall,
                TextColor3         = Theme.Colors.TextMuted,
                BackgroundTransparency = 1,
                Size               = UDim2.new(0, 16, 1, 0),
                AnchorPoint        = Vector2.new(1, 0.5),
                Position           = UDim2.new(1, -4, 0.5, 0),
                Parent             = btn
            })
            btn.BackgroundTransparency = 0.6
            lbl.TextTransparency       = 0.45
            iconLbl.TextTransparency   = 0.45
        end

        -- Content page
        local page = Utils.Create("ScrollingFrame", {
            Name               = name .. "_Page",
            Size               = UDim2.new(1, -16, 1, -12),
            Position           = UDim2.new(0, 8, 0, 6),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Colors.Accent,
            CanvasSize         = UDim2.new(0, 0, 0, 0),
            Visible            = false,
            Parent             = self.ContentContainer
        })
        local pageLayout = Utils.Create("UIListLayout", {
            Padding            = UDim.new(0, 10),
            SortOrder          = Enum.SortOrder.LayoutOrder,
            Parent             = page
        })
        Utils.AutoCanvas(page, pageLayout)

        local tabObj = {
            Button  = btn,
            Marker  = marker,
            Label   = lbl,
            Icon    = iconLbl,
            Badge   = badge,
            Page    = page,
            Name    = name,
            Locked  = locked
        }

        if not locked then
            btn.MouseEnter:Connect(function()
                if self.ActivePage ~= tabObj then
                    TweenController:Play(btn, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.Surface})
                    TweenController:Play(lbl, TweenController.Smooth, {TextColor3 = Theme.Colors.TextMed})
                end
            end)
            btn.MouseLeave:Connect(function()
                if self.ActivePage ~= tabObj then
                    TweenController:Play(btn, TweenController.Smooth, {BackgroundTransparency = 1})
                    TweenController:Play(lbl, TweenController.Smooth, {TextColor3 = Theme.Colors.TextLow})
                end
            end)
            btn.MouseButton1Click:Connect(function()
                self:Select(tabObj)
            end)
        end

        table.insert(self.Pages, tabObj)
        if #self.Pages == 1 then self:Select(tabObj) end

        return page
    end

    function Tabs:Select(tabObj)
        if self.ActivePage == tabObj then return end

        -- Deactivate current
        if self.ActivePage then
            local prev = self.ActivePage
            TweenController:Play(prev.Button, TweenController.Smooth, {BackgroundTransparency = 1})
            TweenController:Play(prev.Label,  TweenController.Smooth, {TextColor3 = Theme.Colors.TextLow, FontFace = Font.fromEnum(Enum.Font.Gotham)})
            TweenController:Play(prev.Icon,   TweenController.Smooth, {TextColor3 = Theme.Colors.TextMuted})
            TweenController:Play(prev.Marker, TweenController.Spring, {Size = UDim2.new(0, 3, 0, 0)})
            prev.Marker.Visible = false
            prev.Page.Visible   = false
        end

        self.ActivePage = tabObj

        -- Activate new (matches .tab-btn.active)
        TweenController:Play(tabObj.Button, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.SurfaceHover})
        TweenController:Play(tabObj.Label,  TweenController.Smooth, {TextColor3 = Theme.Colors.TextHigh})
        TweenController:Play(tabObj.Icon,   TweenController.Smooth, {TextColor3 = Theme.Colors.Accent})
        tabObj.Marker.Visible = true
        TweenController:Play(tabObj.Marker, TweenController.Spring, {Size = UDim2.new(0, 3, 0.55, 0)})
        tabObj.Page.Visible   = true
        tabObj.Page.CanvasPosition = Vector2.new(0,0)
    end

    function Tabs:SelectByName(name)
        for _, t in ipairs(self.Pages) do
            if t.Name == name then self:Select(t) return end
        end
    end

    return Tabs
end
