return function(Theme, Utils, TweenController)
    local Input = {}
    Input.__index = Input

    --[[
        Config:
            Title       : string  (optional label above)
            Icon        : string  (emoji/char shown left)
            Placeholder : string
            Text        : string  (default value)
            Callback    : function(text)  called on FocusLost
            OnChanged   : function(text)  called on every keystroke
    ]]
    function Input.new(parent, config)
        local self  = setmetatable({}, Input)
        local cfg   = config or {}

        self.Title       = cfg.Title
        self.Icon        = cfg.Icon        or ">"
        self.Placeholder = cfg.Placeholder or "Input..."
        self.Text        = cfg.Text        or ""
        self.Callback    = cfg.Callback    or function() end
        self.OnChanged   = cfg.OnChanged   or nil

        local totalH = self.Title and 62 or 40

        self.Instance = Utils.Create("Frame", {
            Name               = "InputWrap",
            Size               = UDim2.new(1, 0, 0, totalH),
            BackgroundTransparency = 1,
            Parent             = parent
        })

        -- Optional title label
        if self.Title then
            local titleLbl = Utils.Create("TextLabel", {
                Text               = self.Title,
                Font               = Theme.Fonts.Main,
                TextSize           = Theme.Sizes.TextSmall,
                TextColor3         = Theme.Colors.TextMed,
                BackgroundTransparency = 1,
                Size               = UDim2.new(1, 0, 0, 14),
                TextXAlignment     = Enum.TextXAlignment.Left,
                Parent             = self.Instance
            })
            Theme:Bind(titleLbl, {TextColor3 = "TextMed"})
        end

        local boxY = self.Title and 18 or 0

        -- Input container (matches .ui-inp-wrap)
        self.Container = Utils.Create("Frame", {
            Name               = "InputBox",
            Size               = UDim2.new(1, 0, 0, 40),
            Position           = UDim2.new(0, 0, 0, boxY),
            BackgroundColor3   = Theme.Colors.Surface,
            BackgroundTransparency = Theme.Trans.Surface,
            Parent             = self.Instance
        })
        Utils.Corner(self.Container, Theme.Sizes.RadiusMedium)
        local stroke = Utils.Stroke(self.Container, Theme.Colors.Border, 1, Theme.Trans.Border)
        Theme:Bind(self.Container, {
            BackgroundColor3       = "Surface",
            BackgroundTransparency = function() return Theme.Trans.Surface end
        })
        Theme:Bind(stroke, {Color = "Border"})

        -- Icon on the left (matches .ui-inp-wrap svg)
        local iconLbl = Utils.Create("TextLabel", {
            Name               = "Icon",
            Text               = self.Icon,
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextNormal,
            TextColor3         = Theme.Colors.TextMuted,
            BackgroundTransparency = 1,
            Size               = UDim2.new(0, 22, 1, 0),
            Position           = UDim2.new(0, 12, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Left,
            Parent             = self.Container
        })
        Theme:Bind(iconLbl, {TextColor3 = "TextMuted"})

        -- TextBox (matches .ui-inp)
        self.TextBox = Utils.Create("TextBox", {
            Name               = "TextBox",
            Text               = self.Text,
            PlaceholderText    = self.Placeholder,
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextMedium,
            TextColor3         = Theme.Colors.TextHigh,
            PlaceholderColor3  = Theme.Colors.TextMuted,
            BackgroundTransparency = 1,
            Size               = UDim2.new(1, -46, 1, 0),
            Position           = UDim2.new(0, 38, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Left,
            ClearTextOnFocus   = false,
            Parent             = self.Container
        })
        Theme:Bind(self.TextBox, {TextColor3 = "TextHigh", PlaceholderColor3 = "TextMuted"})

        -- Focus: accent border + glow (matches :focus-within style in HTML)
        self.TextBox.Focused:Connect(function()
            TweenController:Play(self.Container, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.SurfaceHover})
            stroke.Color        = Theme.Colors.Accent
            stroke.Transparency = Theme.Trans.AccentBorder
            iconLbl.TextColor3  = Theme.Colors.Accent
        end)
        self.TextBox.FocusLost:Connect(function(enterPressed)
            TweenController:Play(self.Container, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.Surface})
            stroke.Color        = Theme.Colors.Border
            stroke.Transparency = Theme.Trans.Border
            iconLbl.TextColor3  = Theme.Colors.TextMuted
            self.Text = self.TextBox.Text
            self.Callback(self.Text)
        end)

        if self.OnChanged then
            self.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                self.OnChanged(self.TextBox.Text)
            end)
        end

        return self
    end

    function Input:Set(text)
        self.Text = text
        self.TextBox.Text = text
    end

    function Input:Get()
        return self.TextBox.Text
    end

    function Input:Clear()
        self.TextBox.Text = ""
        self.Text = ""
    end

    function Input:Focus()
        self.TextBox:CaptureFocus()
    end

    return Input
end
