return function(Theme, Utils, TweenController, Effects)
    local Dropdown = {}
    Dropdown.__index = Dropdown

    --[[
        Config:
            Text        : string  (left label)
            Items       : {string, ...}
            MultiSelect : bool
            Default     : string | {string, ...}
            EmptyText   : string
            Callback    : function(selected)
    ]]
    function Dropdown.new(parent, config)
        local self = setmetatable({}, Dropdown)
        local cfg  = config or {}

        self.Text        = cfg.Text        or "Dropdown"
        self.Items       = cfg.Items       or {}
        self.MultiSelect = cfg.MultiSelect or false
        self.EmptyText   = cfg.EmptyText   or (self.MultiSelect and "Nenhuma" or "Selecionar")
        self.Callback    = cfg.Callback    or function() end
        self.Open        = false

        -- Selection state
        if self.MultiSelect then
            self.Selected = {}
            if type(cfg.Default) == "table" then
                for _,v in ipairs(cfg.Default) do table.insert(self.Selected, v) end
            elseif cfg.Default then
                table.insert(self.Selected, cfg.Default)
            end
        else
            self.Selected = cfg.Default or nil
        end

        -- Wrap (matches .ui-dd-wrap)
        self.Instance = Utils.Create("Frame", {
            Name               = "DropdownWrap",
            Size               = UDim2.new(1, 0, 0, 44),
            BackgroundColor3   = Theme.Colors.Surface,
            BackgroundTransparency = Theme.Trans.Surface,
            ClipsDescendants   = true,
            Parent             = parent
        })
        Utils.Corner(self.Instance, Theme.Sizes.RadiusMedium)
        self.Stroke = Utils.Stroke(self.Instance, Theme.Colors.Border, 1, Theme.Trans.Border)
        Theme:Bind(self.Instance, {
            BackgroundColor3       = "Surface",
            BackgroundTransparency = function() return Theme.Trans.Surface end
        })

        -- Header row (matches .ui-dd-hdr)
        self.Header = Utils.Create("TextButton", {
            Name               = "Header",
            Text               = "",
            Size               = UDim2.new(1, 0, 0, 44),
            BackgroundTransparency = 1,
            AutoButtonColor    = false,
            Parent             = self.Instance
        })

        -- Left icon (optional – generic filter icon)
        self.LeftIcon = Utils.Create("TextLabel", {
            Name               = "LeftIcon",
            Text               = "≡",
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextNormal,
            TextColor3         = Theme.Colors.TextLow,
            BackgroundTransparency = 1,
            Size               = UDim2.new(0, 20, 1, 0),
            Position           = UDim2.new(0, 12, 0, 0),
            Parent             = self.Header
        })
        Theme:Bind(self.LeftIcon, {TextColor3 = "TextLow"})

        -- Title label (matches .ui-dd-lbl)
        self.TitleLabel = Utils.Create("TextLabel", {
            Name               = "Title",
            Text               = self.Text,
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextMedium,
            TextColor3         = Theme.Colors.TextMed,
            BackgroundTransparency = 1,
            Size               = UDim2.new(1, -145, 1, 0),
            Position           = UDim2.new(0, 36, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Left,
            Parent             = self.Header
        })
        Theme:Bind(self.TitleLabel, {TextColor3 = "TextMed"})

        -- Value label (matches .ui-dd-val)
        self.ValueLabel = Utils.Create("TextLabel", {
            Name               = "Value",
            Text               = self.EmptyText,
            Font               = Theme.Fonts.Mono,
            TextSize           = Theme.Sizes.TextXS,
            TextColor3         = Theme.Colors.TextMuted,
            BackgroundTransparency = 1,
            Size               = UDim2.new(0, 100, 1, 0),
            Position           = UDim2.new(1, -120, 0, 0),
            TextXAlignment     = Enum.TextXAlignment.Right,
            TextTruncate       = Enum.TextTruncate.AtEnd,
            Parent             = self.Header
        })
        Theme:Bind(self.ValueLabel, {TextColor3 = "TextMuted"})

        -- Chevron arrow (matches .dd-chev)
        self.Arrow = Utils.Create("TextLabel", {
            Name               = "Arrow",
            Text               = "▾",
            Font               = Theme.Fonts.Main,
            TextSize           = Theme.Sizes.TextNormal,
            TextColor3         = Theme.Colors.TextLow,
            BackgroundTransparency = 1,
            Size               = UDim2.new(0, 16, 0, 16),
            Position           = UDim2.new(1, -24, 0.5, -8),
            Parent             = self.Header
        })
        Theme:Bind(self.Arrow, {TextColor3 = "TextLow"})

        -- Menu container (matches .ui-dd-menu)
        local menuBg = Utils.Create("Frame", {
            Name               = "MenuBg",
            Size               = UDim2.new(1, -4, 0, 0),
            Position           = UDim2.new(0, 2, 0, 48),
            BackgroundColor3   = Theme.Colors.Background,
            BackgroundTransparency = 0.05,
            ClipsDescendants   = false,
            Parent             = self.Instance
        })
        Utils.Corner(menuBg, Theme.Sizes.RadiusMedium)

        self.ListContainer = Utils.Create("ScrollingFrame", {
            Name               = "List",
            Size               = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Colors.Accent,
            CanvasSize         = UDim2.new(0,0,0,0),
            Visible            = false,
            Parent             = menuBg
        })
        Utils.Padding(self.ListContainer, 4, 4)

        self.ListLayout = Utils.Create("UIListLayout", {
            Padding            = UDim.new(0, 2),
            SortOrder          = Enum.SortOrder.LayoutOrder,
            Parent             = self.ListContainer
        })

        -- Interactions
        self.Header.MouseEnter:Connect(function()
            if not self.Open then
                TweenController:Play(self.Instance, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.SurfaceHover})
                self.Stroke.Transparency = Theme.Trans.BorderMid
            end
        end)
        self.Header.MouseLeave:Connect(function()
            if not self.Open then
                TweenController:Play(self.Instance, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.Surface})
                self.Stroke.Transparency = Theme.Trans.Border
            end
        end)
        self.Header.MouseButton1Click:Connect(function()
            self:Toggle()
        end)

        self:Refresh(self.Items)
        return self
    end

    function Dropdown:Toggle()
        self.Open = not self.Open
        local contentH = self.ListLayout.AbsoluteContentSize.Y + 16
        local menuH    = math.min(contentH, 200)
        local totalH   = self.Open and (44 + menuH + 6) or 44
        local rot      = self.Open and 180 or 0

        self.ListContainer.Visible = true
        TweenController:Play(self.Instance, TweenController.Out, {Size = UDim2.new(1, 0, 0, totalH)})
        TweenController:Play(self.Arrow, TweenController.Smooth, {Rotation = rot})

        if self.Open then
            -- Highlight header (matches .ui-dd-hdr.open)
            TweenController:Play(self.Instance, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.AccentGlow})
            self.Stroke.Color        = Theme.Colors.Accent
            self.Stroke.Transparency = Theme.Trans.AccentBorder
        else
            TweenController:Play(self.Instance, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.Surface})
            self.Stroke.Color        = Theme.Colors.Border
            self.Stroke.Transparency = Theme.Trans.Border
            task.delay(0.22, function()
                if not self.Open then
                    self.ListContainer.Visible = false
                end
            end)
        end
    end

    function Dropdown:Refresh(items)
        self.Items = items or {}
        for _, c in ipairs(self.ListContainer:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end

        for _, item in ipairs(self.Items) do
            local row = Utils.Create("TextButton", {
                Name               = tostring(item),
                Text               = "",
                Size               = UDim2.new(1, 0, 0, 32),
                BackgroundColor3   = Theme.Colors.Surface,
                BackgroundTransparency = Theme.Trans.Surface,
                AutoButtonColor    = false,
                Parent             = self.ListContainer
            })
            Utils.Corner(row, Theme.Sizes.RadiusSmall)

            -- For multi-select: checkbox box (matches .dd-chkbox)
            local checkbox = nil
            if self.MultiSelect then
                checkbox = Utils.Create("Frame", {
                    Name               = "Checkbox",
                    Size               = UDim2.new(0, 15, 0, 15),
                    Position           = UDim2.new(0, 10, 0.5, -7),
                    BackgroundColor3   = Theme.Colors.Surface,
                    BackgroundTransparency = Theme.Trans.Surface,
                    Parent             = row
                })
                Utils.Corner(checkbox, Theme.Sizes.RadiusSmall)
                Utils.Stroke(checkbox, Theme.Colors.Border, 1.5, Theme.Trans.BorderMid)
            end

            -- For single-select: check mark (matches .dd-check)
            local check = nil
            if not self.MultiSelect then
                check = Utils.Create("TextLabel", {
                    Name               = "Check",
                    Text               = "✓",
                    Font               = Theme.Fonts.Bold,
                    TextSize           = Theme.Sizes.TextNormal,
                    TextColor3         = Theme.Colors.Accent,
                    BackgroundTransparency = 1,
                    Size               = UDim2.new(0, 16, 1, 0),
                    Position           = UDim2.new(0, 8, 0, 0),
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    TextTransparency   = 1,
                    Parent             = row
                })
            end

            local itemLabel = Utils.Create("TextLabel", {
                Text               = tostring(item),
                Font               = Theme.Fonts.Main,
                TextSize           = Theme.Sizes.TextNormal,
                TextColor3         = Theme.Colors.TextLow,
                BackgroundTransparency = 1,
                Size               = UDim2.new(1, -50, 1, 0),
                Position           = UDim2.new(0, self.MultiSelect and 32 or 26, 0, 0),
                TextXAlignment     = Enum.TextXAlignment.Left,
                Parent             = row
            })
            Theme:Bind(itemLabel, {TextColor3 = "TextLow"})

            row.MouseEnter:Connect(function()
                TweenController:Play(row, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.SurfaceHover})
                TweenController:Play(itemLabel, TweenController.Smooth, {TextColor3 = Theme.Colors.TextHigh})
            end)
            row.MouseLeave:Connect(function()
                -- Reapply selection color if selected
                local isSel = self.MultiSelect and table.find(self.Selected, tostring(item))
                    or (not self.MultiSelect and self.Selected == tostring(item))
                if isSel then
                    TweenController:Play(row, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.AccentGlow})
                    TweenController:Play(itemLabel, TweenController.Smooth, {TextColor3 = Theme.Colors.Accent})
                else
                    TweenController:Play(row, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.Surface})
                    TweenController:Play(itemLabel, TweenController.Smooth, {TextColor3 = Theme.Colors.TextLow})
                end
            end)

            row.MouseButton1Click:Connect(function()
                Effects.Ripple(row, row.AbsoluteSize.X/2, row.AbsoluteSize.Y/2)
                self:Select(tostring(item))
            end)
        end

        self.ListContainer.CanvasSize = UDim2.new(0, 0, 0, self.ListLayout.AbsoluteContentSize.Y + 8)
        self:UpdateVisuals()
    end

    function Dropdown:UpdateVisuals()
        -- Update value label text
        if self.MultiSelect then
            local n = #self.Selected
            self.ValueLabel.Text = n==0 and self.EmptyText or n==1 and self.Selected[1] or n.." selecionados"
        else
            self.ValueLabel.Text = self.Selected and tostring(self.Selected) or self.EmptyText
        end

        -- Update row visuals
        for _, row in ipairs(self.ListContainer:GetChildren()) do
            if row:IsA("TextButton") then
                local isSel = self.MultiSelect and table.find(self.Selected, row.Name)
                    or (not self.MultiSelect and self.Selected == row.Name)
                local lbl  = row:FindFirstChildWhichIsA("TextLabel")
                local cb   = row:FindFirstChild("Checkbox")
                local chk  = row:FindFirstChild("Check")

                if isSel then
                    row.BackgroundTransparency = Theme.Trans.AccentGlow
                    if lbl  then lbl.TextColor3 = Theme.Colors.Accent end
                    if cb   then
                        cb.BackgroundColor3 = Theme.Colors.Accent
                        cb.BackgroundTransparency = 0
                        local ck = cb:FindFirstChildWhichIsA("UIStroke")
                        if ck then ck.Transparency = 1 end
                        -- Check mark inside checkbox
                        if not cb:FindFirstChild("ChkMark") then
                            Utils.Create("TextLabel", {
                                Name="ChkMark", Text="✓",
                                Font=Theme.Fonts.Bold, TextSize=9,
                                TextColor3=Color3.new(1,1,1),
                                BackgroundTransparency=1,
                                Size=UDim2.new(1,0,1,0),
                                Parent=cb
                            })
                        end
                    end
                    if chk  then chk.TextTransparency = 0 end
                else
                    row.BackgroundTransparency = Theme.Trans.Surface
                    if lbl  then lbl.TextColor3 = Theme.Colors.TextLow end
                    if cb   then
                        cb.BackgroundColor3 = Theme.Colors.Surface
                        cb.BackgroundTransparency = Theme.Trans.Surface
                        local ck = cb:FindFirstChildWhichIsA("UIStroke")
                        if ck then ck.Transparency = Theme.Trans.BorderMid end
                        local cm = cb:FindFirstChild("ChkMark")
                        if cm then cm:Destroy() end
                    end
                    if chk  then chk.TextTransparency = 1 end
                end
            end
        end
    end

    function Dropdown:Select(item)
        if self.MultiSelect then
            local idx = table.find(self.Selected, item)
            if idx then table.remove(self.Selected, idx)
            else table.insert(self.Selected, item) end
            self:UpdateVisuals()
            self.Callback(self.Selected)
        else
            self.Selected = item
            self:UpdateVisuals()
            self.Callback(item)
            self:Toggle()
        end
    end

    function Dropdown:SetItems(items)
        self:Refresh(items)
    end

    return Dropdown
end
