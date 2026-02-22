return function(Theme, Utils, TweenController)
    local Slider = {}
    Slider.__index = Slider

    local UserInputService = game:GetService("UserInputService")

    --[[
        Config:
            Text     : string
            Min      : number
            Max      : number
            Default  : number
            Decimals : number (0 = integer)
            Suffix   : string  (e.g. "px", "°")
            Callback : function(value)
    ]]
    function Slider.new(parent, config)
        local self = setmetatable({}, Slider)
        local cfg  = config or {}

        self.Text     = cfg.Text     or "Slider"
        self.Min      = cfg.Min      or 0
        self.Max      = cfg.Max      or 100
        self.Default  = cfg.Default  or self.Min
        self.Decimals = cfg.Decimals or 0
        self.Suffix   = cfg.Suffix   or ""
        self.Callback = cfg.Callback or function() end
        self.Value    = self.Default
        self.Dragging = false

        -- Outer wrap (matches .ui-sld-wrap, height ~58px)
        self.Instance = Utils.Create("Frame", {
            Name               = "SliderWrap",
            Size               = UDim2.new(1, 0, 0, 56),
            BackgroundColor3   = Theme.Colors.Surface,
            BackgroundTransparency = Theme.Trans.Surface,
            Parent             = parent
        })
        Utils.Corner(self.Instance, Theme.Sizes.RadiusMedium)
        Utils.Stroke(self.Instance, Theme.Colors.Border, 1, Theme.Trans.Border)
        Theme:Bind(self.Instance, {
            BackgroundColor3       = "Surface",
            BackgroundTransparency = function() return Theme.Trans.Surface end
        })

        -- Header row (matches .ui-sld-hdr)
        local header = Utils.Create("Frame", {
            Name               = "Header",
            BackgroundTransparency = 1,
            Size               = UDim2.new(1, -24, 0, 18),
            Position           = UDim2.new(0, 12, 0, 10),
            Parent             = self.Instance
        })

        self.Label = Utils.Create("TextLabel", {
            Name               = "Label",
            Text               = self.Text,
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextMedium,
            TextColor3         = Theme.Colors.TextMed,
            BackgroundTransparency = 1,
            Size               = UDim2.new(1, -70, 1, 0),
            TextXAlignment     = Enum.TextXAlignment.Left,
            Parent             = header
        })
        Theme:Bind(self.Label, {TextColor3 = "TextMed"})

        -- Value label (matches .ui-sld-val — accent color, mono font)
        self.ValueLabel = Utils.Create("TextLabel", {
            Name               = "Value",
            Text               = tostring(self.Value) .. self.Suffix,
            Font               = Theme.Fonts.Mono,
            TextSize           = Theme.Sizes.TextNormal,
            TextColor3         = Theme.Colors.Accent,
            BackgroundTransparency = 1,
            Size               = UDim2.new(0, 70, 1, 0),
            Position           = UDim2.new(1, -70, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Right,
            Parent             = header
        })
        Theme:Bind(self.ValueLabel, {TextColor3 = "Accent"})

        -- Track (matches .ui-sld-track)
        self.Track = Utils.Create("Frame", {
            Name               = "Track",
            Size               = UDim2.new(1, -24, 0, 4),
            Position           = UDim2.new(0, 12, 0, 36),
            BackgroundColor3   = Theme.Colors.TextHigh,
            BackgroundTransparency = 0.92,
            BorderSizePixel    = 0,
            Parent             = self.Instance
        })
        Utils.Corner(self.Track, UDim.new(1, 0))

        -- Fill (matches .ui-sld-fill with gradient)
        self.Fill = Utils.Create("Frame", {
            Name               = "Fill",
            Size               = UDim2.new(0, 0, 1, 0),
            BackgroundColor3   = Theme.Colors.Accent,
            BorderSizePixel    = 0,
            Parent             = self.Track
        })
        Utils.Corner(self.Fill, UDim.new(1, 0))
        Utils.Gradient(self.Fill, ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Colors.Accent),
            ColorSequenceKeypoint.new(1, Theme.Colors.AccentHigh)
        }), 0)

        -- Knob (matches .ui-sld-knob)
        self.Knob = Utils.Create("Frame", {
            Name               = "Knob",
            Size               = UDim2.new(0, 14, 0, 14),
            Position           = UDim2.new(0, -7, 0.5, -7),
            BackgroundColor3   = Color3.new(1,1,1),
            BorderSizePixel    = 0,
            Parent             = self.Track
        })
        Utils.Corner(self.Knob, UDim.new(1, 0))
        Utils.Stroke(self.Knob, Theme.Colors.Accent, 2, 0)
        Theme:Bind(self.Knob, {}) -- rebind accent stroke via Bind workaround

        -- Click/drag area (invisible, sits over track + some padding)
        self.ClickArea = Utils.Create("TextButton", {
            Name               = "ClickArea",
            Text               = "",
            BackgroundTransparency = 1,
            Size               = UDim2.new(1, -24, 0, 24),
            Position           = UDim2.new(0, 12, 0, 28),
            Parent             = self.Instance
        })

        self.ClickArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.Dragging = true
                self:UpdateFromInput(input.Position.X)
            end
        end)
        self.ClickArea.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.Dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if self.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                self:UpdateFromInput(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.Dragging = false
            end
        end)

        self:Set(self.Value, true)
        return self
    end

    function Slider:UpdateFromInput(xPos)
        local abs  = self.Track.AbsolutePosition.X
        local size = self.Track.AbsoluteSize.X
        local ratio = math.clamp((xPos - abs) / math.max(size, 1), 0, 1)
        local val   = self.Min + (self.Max - self.Min) * ratio
        if self.Decimals > 0 then
            val = math.floor(val * 10^self.Decimals + 0.5) / 10^self.Decimals
        else
            val = math.floor(val + 0.5)
        end
        self:Set(val)
    end

    function Slider:Set(value, skipCallback)
        self.Value = math.clamp(value, self.Min, self.Max)
        local pct  = (self.Value - self.Min) / math.max(self.Max - self.Min, 1)
        local text = self.Decimals > 0
            and string.format("%." .. self.Decimals .. "f", self.Value) .. self.Suffix
            or  tostring(self.Value) .. self.Suffix
        self.ValueLabel.Text = text
        TweenController:Play(self.Fill,  TweenController.Smooth, {Size     = UDim2.new(pct, 0, 1, 0)})
        TweenController:Play(self.Knob,  TweenController.Smooth, {Position = UDim2.new(pct, -7, 0.5, -7)})
        if not skipCallback then
            self.Callback(self.Value)
        end
    end

    return Slider
end
