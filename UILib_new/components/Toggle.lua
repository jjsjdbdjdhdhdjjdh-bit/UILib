return function(Theme, Utils, Effects, TweenController)
    local Toggle = {}
    Toggle.__index = Toggle

    --[[
        Config:
            Text     : string
            Icon     : string  (emoji/char shown left side)
            State    : bool    (initial state)
            Locked   : bool
            Callback : function(bool)
    ]]
    function Toggle.new(parent, config)
        local self = setmetatable({}, Toggle)
        local cfg = config or {}

        self.Text     = cfg.Text     or "Toggle"
        self.Icon     = cfg.Icon     or ""
        self.State    = cfg.State    or false
        self.Locked   = cfg.Locked   or false
        self.Callback = cfg.Callback or function() end

        -- Outer row (matches .ui-tgl-row)
        self.Instance = Utils.Create("Frame", {
            Name               = "ToggleRow",
            Size               = UDim2.new(1, 0, 0, 42),
            BackgroundColor3   = Theme.Colors.Surface,
            BackgroundTransparency = Theme.Trans.Surface,
            Parent             = parent
        })
        Utils.Corner(self.Instance, Theme.Sizes.RadiusMedium)
        local stroke = Utils.Stroke(self.Instance, Theme.Colors.Border, 1, Theme.Trans.Border)
        Theme:Bind(self.Instance, {
            BackgroundColor3 = "Surface",
            BackgroundTransparency = function() return Theme.Trans.Surface end
        })
        Theme:Bind(stroke, {Color = "Border"})

        -- Icon label (matches .t-ico area)
        self.IconLabel = Utils.Create("TextLabel", {
            Name               = "Icon",
            Text               = self.Icon,
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextNormal,
            TextColor3         = Theme.Colors.TextLow,
            BackgroundTransparency = 1,
            Size               = UDim2.new(0, self.Icon=="" and 0 or 16, 0, 42),
            Position           = UDim2.new(0, 12, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Left,
            Visible            = self.Icon ~= "",
            Parent             = self.Instance
        })
        Theme:Bind(self.IconLabel, {TextColor3 = "TextLow"})

        local labelX = self.Icon=="" and 13 or 32

        -- Text label (matches .ui-tgl-lbl)
        self.Label = Utils.Create("TextLabel", {
            Name               = "Label",
            Text               = self.Text,
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextMedium,
            TextColor3         = Theme.Colors.TextMed,
            BackgroundTransparency = 1,
            Size               = UDim2.new(1, -(labelX + 58), 1, 0),
            Position           = UDim2.new(0, labelX, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Left,
            Parent             = self.Instance
        })
        Theme:Bind(self.Label, {TextColor3 = "TextMed"})

        -- Switch track (matches .ui-tgl-sw)
        self.Switch = Utils.Create("Frame", {
            Name               = "Switch",
            Size               = UDim2.new(0, 40, 0, 22),
            AnchorPoint        = Vector2.new(1, 0.5),
            Position           = UDim2.new(1, -12, 0.5, 0),
            BackgroundColor3   = Theme.Colors.TextMuted,
            BorderSizePixel    = 0,
            Parent             = self.Instance
        })
        Utils.Corner(self.Switch, Sizes and Sizes.RadiusFull or UDim.new(1, 0))

        -- Knob (matches .ui-tgl-sw::after)
        self.Knob = Utils.Create("Frame", {
            Name               = "Knob",
            Size               = UDim2.new(0, 14, 0, 14),
            Position           = UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3   = Color3.fromRGB(255,255,255),
            BackgroundTransparency = 0.40,
            BorderSizePixel    = 0,
            Parent             = self.Switch
        })
        Utils.Corner(self.Knob, UDim.new(1, 0))

        -- Invisible click button covering the whole row
        self.Button = Utils.Create("TextButton", {
            Text               = "",
            BackgroundTransparency = 1,
            Size               = UDim2.new(1, 0, 1, 0),
            Parent             = self.Instance
        })

        -- Hover
        self.Button.MouseEnter:Connect(function()
            if self.Locked then return end
            TweenController:Play(self.Instance, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.SurfaceHover})
            stroke.Transparency = Theme.Trans.BorderMid
        end)
        self.Button.MouseLeave:Connect(function()
            if self.Locked then return end
            TweenController:Play(self.Instance, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.Surface})
            stroke.Transparency = Theme.Trans.Border
        end)
        self.Button.MouseButton1Click:Connect(function()
            if self.Locked then return end
            self:Set(not self.State)
        end)

        -- Locked visuals (matches .ui-tgl-row.locked)
        if self.Locked then
            self.Instance.BackgroundTransparency = 0.60
            self.Label.TextTransparency          = 0.45
            self.IconLabel.TextTransparency      = 0.45
            self.Button.Active                   = false
        end

        self:Set(self.State, true)
        return self
    end

    function Toggle:Set(state, skipCallback)
        self.State = state
        if self.State then
            -- ON: matches .ui-tgl-row.on
            TweenController:Play(self.Switch, TweenController.Smooth, {BackgroundColor3 = Theme.Colors.Accent})
            TweenController:Play(self.Knob,   TweenController.Spring, {
                Position               = UDim2.new(0, 24, 0.5, -7),
                BackgroundTransparency = 0,
                BackgroundColor3       = Color3.new(1,1,1)
            })
            TweenController:Play(self.Label,  TweenController.Smooth, {TextColor3 = Theme.Colors.TextHigh})
            if self.IconLabel then
                TweenController:Play(self.IconLabel, TweenController.Smooth, {TextColor3 = Theme.Colors.Accent})
            end
        else
            -- OFF
            TweenController:Play(self.Switch, TweenController.Smooth, {BackgroundColor3 = Theme.Colors.TextMuted})
            TweenController:Play(self.Knob,   TweenController.Spring, {
                Position               = UDim2.new(0, 2, 0.5, -7),
                BackgroundTransparency = 0.40,
                BackgroundColor3       = Color3.fromRGB(200,200,200)
            })
            TweenController:Play(self.Label,  TweenController.Smooth, {TextColor3 = Theme.Colors.TextMed})
            if self.IconLabel then
                TweenController:Play(self.IconLabel, TweenController.Smooth, {TextColor3 = Theme.Colors.TextLow})
            end
        end
        if not skipCallback then
            self.Callback(self.State)
        end
    end

    function Toggle:SetLocked(state)
        self.Locked = state
        self.Button.Active = not state
        self.Instance.BackgroundTransparency = state and 0.60 or Theme.Trans.Surface
        self.Label.TextTransparency = state and 0.45 or 0
    end

    return Toggle
end
