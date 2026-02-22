return function(Theme, Utils, TweenController)
    local Notification = {}
    local Container = nil

    -- Icons matching HTML toast icon types
    local ICONS = {
        success = "✓",
        warning = "!",
        error   = "✕",
        info    = "i"
    }

    function Notification.Init(parentGui)
        if Container then return end

        -- Matches .toast-container (bottom-right, column)
        Container = Utils.Create("Frame", {
            Name               = "ToastContainer",
            Size               = UDim2.new(0, 310, 1, -40),
            Position           = UDim2.new(1, -328, 0, 20),
            BackgroundTransparency = 1,
            Parent             = parentGui
        })

        local ll = Instance.new("UIListLayout")
        ll.VerticalAlignment    = Enum.VerticalAlignment.Bottom
        ll.HorizontalAlignment  = Enum.HorizontalAlignment.Right
        ll.SortOrder            = Enum.SortOrder.LayoutOrder
        ll.Padding              = UDim.new(0, 7)
        ll.FillDirection        = Enum.FillDirection.Vertical
        ll.Parent               = Container
    end

    --[[
        config:
            Text    : string
            Type    : "success" | "warning" | "error" | "info"
            Duration: number (seconds, default 3)
    ]]
    function Notification.New(config)
        if not Container then return end

        local text  = config.Text     or config.Title or "Notificação"
        local kind  = (config.Type    or "info"):lower()
        local dur   = config.Duration or 3

        local color = Theme.Colors.Info
        if kind == "success" then color = Theme.Colors.Success
        elseif kind == "warning" then color = Theme.Colors.Warning
        elseif kind == "error"   then color = Theme.Colors.Error
        end

        local icon = ICONS[kind] or "i"

        -- Toast frame (matches .toast)
        local toast = Utils.Create("Frame", {
            Name               = "Toast_" .. kind,
            Size               = UDim2.new(1, 0, 0, 0),  -- starts collapsed
            BackgroundColor3   = Theme.Colors.Background,
            BackgroundTransparency = 0.05,
            ClipsDescendants   = false,
            Parent             = Container
        })
        Utils.Corner(toast, Theme.Sizes.RadiusMedium)
        Utils.Stroke(toast, Theme.Colors.Border, 1, Theme.Trans.BorderMid)

        -- Left color bar (matches .toast-bar)
        local bar = Utils.Create("Frame", {
            Name               = "Bar",
            Size               = UDim2.new(0, 3, 1, 0),
            BackgroundColor3   = color,
            BorderSizePixel    = 0,
            Parent             = toast
        })
        Utils.Corner(bar, UDim.new(0, 3))

        -- Icon (matches .toast-icon)
        local iconLbl = Utils.Create("TextLabel", {
            Name               = "Icon",
            Text               = icon,
            Font               = Theme.Fonts.Bold,
            TextSize           = Theme.Sizes.TextNormal,
            TextColor3         = color,
            BackgroundTransparency = 1,
            Size               = UDim2.new(0, 16, 1, 0),
            Position           = UDim2.new(0, 14, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Center,
            Parent             = toast
        })

        -- Message (matches .toast-msg)
        local msgLbl = Utils.Create("TextLabel", {
            Name               = "Message",
            Text               = text,
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextNormal,
            TextColor3         = Theme.Colors.TextHigh,
            BackgroundTransparency = 1,
            Size               = UDim2.new(1, -48, 1, 0),
            Position           = UDim2.new(0, 36, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Left,
            TextTruncate       = Enum.TextTruncate.AtEnd,
            Parent             = toast
        })
        Theme:Bind(msgLbl, {TextColor3 = "TextHigh"})

        -- Progress bar at bottom (matches HTML progress bar)
        local progress = Utils.Create("Frame", {
            Name               = "Progress",
            Size               = UDim2.new(1, 0, 0, 2),
            Position           = UDim2.new(0, 0, 1, -2),
            BackgroundColor3   = color,
            BackgroundTransparency = 0.6,
            BorderSizePixel    = 0,
            Parent             = toast
        })

        -- Animate in: expand height (matches @keyframes toastIn)
        TweenController:Play(toast, TweenController.Spring, {Size = UDim2.new(1, 0, 0, 46)})

        -- Progress drain
        TweenController:Play(progress, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})

        -- Auto-dismiss (matches .toast.out)
        task.delay(dur, function()
            TweenController:Play(toast, TweenController.Smooth, {
                Size               = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1
            })
            task.wait(0.25)
            if toast and toast.Parent then toast:Destroy() end
        end)
    end

    -- Convenience shortcuts
    function Notification.Success(text, dur)
        Notification.New({Text=text, Type="success", Duration=dur})
    end
    function Notification.Warning(text, dur)
        Notification.New({Text=text, Type="warning", Duration=dur})
    end
    function Notification.Error(text, dur)
        Notification.New({Text=text, Type="error", Duration=dur})
    end
    function Notification.Info(text, dur)
        Notification.New({Text=text, Type="info", Duration=dur})
    end

    return Notification
end
