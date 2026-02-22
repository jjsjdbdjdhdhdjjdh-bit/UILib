return function(Theme, Utils, Effects, TweenController)
    local Button = {}
    Button.__index = Button

    --[[
        Config:
            Text      : string
            Variant   : "default" | "primary" | "danger"
            Icon      : string emoji/char
            Locked    : bool
            Callback  : function
            Width     : UDim2 (optional, defaults to 1,0)
            Height    : number (default 38)
    ]]
    function Button.new(parent, config)
        local self = setmetatable({}, Button)
        local cfg = config or {}

        self.Text     = cfg.Text     or "Botão"
        self.Variant  = (cfg.Variant or "default"):lower()
        self.Icon     = cfg.Icon     or ""
        self.Locked   = cfg.Locked   or false
        self.Callback = cfg.Callback or function() end

        local h = cfg.Height or 46

        -- Outer frame (matches .ui-btn)
        self.Instance = Utils.Create("TextButton", {
            Name               = "Button",
            Text               = "",
            Size               = cfg.Width or UDim2.new(1, 0, 0, h),
            BackgroundColor3   = Theme.Colors.Surface,
            BackgroundTransparency = Theme.Trans.Surface,
            AutoButtonColor    = false,
            BorderSizePixel    = 0,
            Parent             = parent
        })
        Utils.Corner(self.Instance, Theme.Sizes.RadiusMedium)
        local stroke = Utils.Stroke(self.Instance, Theme.Colors.Border, 1, Theme.Trans.Border)
        local scale  = Utils.Scale(self.Instance, 1)

        -- Content row (icon + label centered)
        local content = Utils.Create("Frame", {
            BackgroundTransparency = 1,
            Size     = UDim2.new(1, -28, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            Parent   = self.Instance
        })
        local ll = Instance.new("UIListLayout")
        ll.FillDirection      = Enum.FillDirection.Horizontal
        ll.VerticalAlignment  = Enum.VerticalAlignment.Center
        ll.HorizontalAlignment= Enum.HorizontalAlignment.Center
        ll.Padding            = UDim.new(0, 7)
        ll.Parent             = content

        local iconLbl = Utils.Create("TextLabel", {
            Name               = "Icon",
            Text               = self.Icon,
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextNormal,
            TextColor3         = Theme.Colors.TextHigh,
            BackgroundTransparency = 1,
            Size               = UDim2.new(0, self.Icon=="" and 0 or 14, 1, 0),
            Visible            = self.Icon ~= "",
            Parent             = content
        })

        self.Label = Utils.Create("TextLabel", {
            Name               = "Label",
            Text               = self.Text,
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextMedium,
            TextColor3         = Theme.Colors.TextHigh,
            BackgroundTransparency = 1,
            Size               = UDim2.new(0, 0, 1, 0),
            AutomaticSize      = Enum.AutomaticSize.X,
            TextXAlignment     = Enum.TextXAlignment.Center,
            Parent             = content
        })

        -- Apply variant styling (matches .ui-btn.primary / .ui-btn.danger)
        local function applyVariant()
            if self.Variant == "primary" then
                self.Instance.BackgroundTransparency = 0
                -- Gradient 135deg, accent -> accentLow
                local grad = Instance.new("UIGradient")
                grad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.Colors.Accent),
                    ColorSequenceKeypoint.new(1, Theme.Colors.AccentLow)
                })
                grad.Rotation = 135
                grad.Parent   = self.Instance
                stroke.Color        = Theme.Colors.Accent
                stroke.Transparency = Theme.Trans.AccentBorder
                self.Label.TextColor3   = Color3.new(1,1,1)
                iconLbl.TextColor3      = Color3.new(1,1,1)
            elseif self.Variant == "danger" then
                -- Default look, danger color on hover only (matches CSS)
                stroke.Color        = Theme.Colors.Border
                stroke.Transparency = Theme.Trans.Border
                self.Label.TextColor3   = Theme.Colors.TextHigh
                iconLbl.TextColor3      = Theme.Colors.TextHigh
            else
                Theme:Bind(self.Label,  {TextColor3 = "TextHigh"})
                Theme:Bind(iconLbl,     {TextColor3 = "TextHigh"})
                Theme:Bind(self.Instance, {
                    BackgroundColor3   = "Surface",
                    BackgroundTransparency = function() return Theme.Trans.Surface end
                })
                Theme:Bind(stroke, {Color = "Border"})
            end
        end
        applyVariant()

        -- Hover interactions
        self.Instance.MouseEnter:Connect(function()
            if self.Locked then return end
            if self.Variant == "danger" then
                TweenController:Play(self.Instance, TweenController.Smooth, {
                    BackgroundColor3 = Color3.fromRGB(196,96,96),
                    BackgroundTransparency = 0.88
                })
                TweenController:Play(self.Label, TweenController.Smooth, {TextColor3 = Color3.fromRGB(224,128,128)})
                stroke.Color        = Color3.fromRGB(196,96,96)
                stroke.Transparency = 0.60
            elseif self.Variant == "primary" then
                self.Instance.BackgroundTransparency = 0
                -- brightness increase handled by filter in HTML; we slightly brighten
            else
                TweenController:Play(self.Instance, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.SurfaceHover})
                stroke.Transparency = Theme.Trans.BorderMid
            end
        end)

        self.Instance.MouseLeave:Connect(function()
            if self.Locked then return end
            if self.Variant == "danger" then
                TweenController:Play(self.Instance, TweenController.Smooth, {
                    BackgroundColor3 = Theme.Colors.Surface,
                    BackgroundTransparency = Theme.Trans.Surface
                })
                TweenController:Play(self.Label, TweenController.Smooth, {TextColor3 = Theme.Colors.TextHigh})
                stroke.Color        = Theme.Colors.Border
                stroke.Transparency = Theme.Trans.Border
            elseif self.Variant ~= "primary" then
                TweenController:Play(self.Instance, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.Surface})
                stroke.Transparency = Theme.Trans.Border
            end
        end)

        -- Press scale (matches :active transform:scale(0.98))
        self.Instance.MouseButton1Down:Connect(function()
            if self.Locked then return end
            TweenController:Play(scale, TweenController.Fast, {Scale = 0.97})
        end)
        self.Instance.MouseButton1Up:Connect(function()
            TweenController:Play(scale, TweenController.Spring, {Scale = 1})
        end)
        self.Instance.MouseButton1Click:Connect(function()
            if self.Locked then return end
            Effects.Ripple(self.Instance, self.Instance.AbsoluteSize.X/2, self.Instance.AbsoluteSize.Y/2)
            self.Callback()
        end)

        -- Locked state (matches .ui-btn.locked)
        if self.Locked then
            self.Instance.AutoButtonColor = false
            self.Instance.Active          = false
            self.Instance.BackgroundTransparency = 0.60
            self.Label.TextTransparency   = 0.45
            iconLbl.TextTransparency      = 0.45
        end

        return self
    end

    function Button:SetText(text)
        self.Text = text
        self.Label.Text = text
    end

    function Button:SetLocked(state)
        self.Locked = state
        self.Instance.Active = not state
        self.Instance.BackgroundTransparency = state and 0.60 or Theme.Trans.Surface
        self.Label.TextTransparency = state and 0.45 or 0
    end

    return Button
end
