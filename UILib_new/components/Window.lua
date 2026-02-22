return function(Theme, Utils, Draggable, Resizable, TweenController, State, EventBus, Registry, Components)
    local Window = {}
    Window.__index = Window

    local Players          = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")

    local function pad2(v) v=tostring(v); return #v==1 and "0"..v or v end

    local function formatUptime(s)
        if s >= 3600 then return math.floor(s/3600).."h"..pad2(math.floor((s%3600)/60)).."m" end
        if s >= 60   then return math.floor(s/60).."m"..pad2(s%60).."s" end
        return s.."s"
    end

    -- ====================================================================
    --  Window.new
    -- ====================================================================
    function Window.new(config)
        local self = setmetatable({}, Window)
        local cfg  = config or {}

        self.Title    = cfg.Title   or "Claude UI"
        self.Version  = cfg.Version or "v4.0.0"
        self.Size     = cfg.Size    or UDim2.new(0, 1060, 0, 680)
        self.MinSize  = cfg.MinSize or Vector2.new(640, 440)
        self.Parent   = cfg.Parent  or Players.LocalPlayer:WaitForChild("PlayerGui")
        self.Components = Components
        self.Registry   = Registry
        self.Events     = EventBus.new()
        self.State      = {
            ActiveTab = State.new("home"),
            Theme     = State.new(Theme.Current),
            Accent    = State.new(Theme.Colors.Accent),
        }
        self.Destroyed  = false
        self.Minimized  = false
        self.Maximized  = false
        self.LastSize   = nil
        self.LastPos    = nil
        self.TabButtons = {}
        self.Panels     = {}

        -- ScreenGui
        self.Gui = self.Parent:FindFirstChild("UILibGui")
        if not self.Gui then
            self.Gui = Utils.Create("ScreenGui", {
                Name = "UILibGui", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = self.Parent
            })
        end
        Registry.RegisterWindow(self)

        -- Backdrop
        self.Backdrop = Utils.Create("Frame", {
            Name = "Backdrop", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Parent = self.Gui
        })

        -- ── Main Window Frame ──────────────────────────────────────────
        self.Window = Utils.Create("Frame", {
            Name = "Window",
            Size = self.Size,
            Position = UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2),
            BackgroundColor3 = Theme.Colors.Background,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Parent = self.Backdrop,
            ClipsDescendants = true
        })
        Utils.Corner(self.Window, Theme.Sizes.RadiusXLarge)
        Utils.Stroke(self.Window, Theme.Colors.Border, 1, Theme.Trans.BorderMid)
        Theme:Bind(self.Window, {BackgroundColor3="Background", BackgroundTransparency=function() return 0 end})

        -- ── TitleBar (matches .titlebar) ──────────────────────────────
        self.TitleBar = Utils.Create("Frame", {
            Name = "TitleBar",
            Size = UDim2.new(1,0,0,60),
            BackgroundColor3 = Theme.Colors.Black,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Parent = self.Window
        })
        Utils.Stroke(self.TitleBar, Theme.Colors.Border, 1, Theme.Trans.Border)

        local tbInner = Utils.Create("Frame", {
            BackgroundTransparency=1, Size=UDim2.new(1,-28,1,0), Position=UDim2.new(0,14,0,0),
            Parent = self.TitleBar
        })

        -- Traffic lights (matches .traffic)
        local traffic = Utils.Create("Frame", {
            Size=UDim2.new(0,54,0,12), Position=UDim2.new(0,0,0.5,-6),
            BackgroundTransparency=1, Parent=tbInner
        })
        local function trafficDot(color, xOff, onClick)
            local btn = Utils.Create("TextButton", {
                Size=UDim2.new(0,12,0,12), Position=UDim2.new(0,xOff,0,0),
                BackgroundColor3=color, Text="", AutoButtonColor=false,
                BorderSizePixel=0, Parent=traffic
            })
            Utils.Corner(btn, UDim.new(1,0))
            Registry.RegisterConnection(self, btn.MouseButton1Click:Connect(onClick))
            return btn
        end
        trafficDot(Color3.fromRGB(255,95,87),  0,  function() self:Destroy() end)
        trafficDot(Color3.fromRGB(254,188,46),  19, function() self:ToggleMinimize() end)
        trafficDot(Color3.fromRGB(40,200,64),  38, function() self:ToggleMaximize() end)

        -- Logo + Title + Version
        local tlLogo = Utils.Create("Frame", {
            Size=UDim2.new(0,22,0,22), Position=UDim2.new(0,70,0.5,-11),
            BackgroundColor3=Theme.Colors.Accent, BackgroundTransparency=Theme.Trans.AccentGlow,
            Parent=tbInner
        })
        Utils.Corner(tlLogo, UDim.new(1,0))
        Utils.Stroke(tlLogo, Theme.Colors.Accent, 1, Theme.Trans.AccentBorder)
        Theme:Bind(tlLogo, {BackgroundColor3="Accent", BackgroundTransparency=function() return Theme.Trans.AccentGlow end})

        local tlTitle = Utils.Create("TextLabel", {
            Text=self.Title, Font=Theme.Fonts.Bold, TextSize=Theme.Sizes.TextLarge,
            TextColor3=Theme.Colors.TextHigh, BackgroundTransparency=1,
            Size=UDim2.new(0,80,1,0), Position=UDim2.new(0,100,0,0),
            TextXAlignment=Enum.TextXAlignment.Left, Parent=tbInner
        })
        Theme:Bind(tlTitle, {TextColor3="TextHigh"})

        local tlVer = Utils.Create("Frame", {
            Size=UDim2.new(0,52,0,18), Position=UDim2.new(0,184,0.5,-9),
            BackgroundColor3=Theme.Colors.Surface, BackgroundTransparency=Theme.Trans.Surface,
            Parent=tbInner
        })
        Utils.Corner(tlVer, Theme.Sizes.RadiusSmall)
        Utils.Stroke(tlVer, Theme.Colors.Border, 1, Theme.Trans.Border)
        Utils.Create("TextLabel", {
            Text=self.Version, Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
            TextColor3=Theme.Colors.TextLow, BackgroundTransparency=1,
            Size=UDim2.new(1,0,1,0), Parent=tlVer
        })

        -- Title actions (search + settings buttons)
        local tlActs = Utils.Create("Frame", {
            Size=UDim2.new(0,68,0,30), AnchorPoint=Vector2.new(1,0.5),
            Position=UDim2.new(1,0,0.5,0), BackgroundTransparency=1, Parent=tbInner
        })
        local function tbBtn(icon, xPos, callback)
            local btn = Utils.Create("TextButton", {
                Size=UDim2.new(0,30,0,30), Position=UDim2.new(0,xPos,0,0),
                BackgroundColor3=Theme.Colors.Surface, BackgroundTransparency=1,
                Text=icon, Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextNormal,
                TextColor3=Theme.Colors.TextLow, AutoButtonColor=false, Parent=tlActs
            })
            Utils.Corner(btn, Theme.Sizes.RadiusSmall)
            btn.MouseEnter:Connect(function()
                TweenController:Play(btn, TweenController.Smooth, {BackgroundTransparency=Theme.Trans.Surface})
                TweenController:Play(btn, TweenController.Smooth, {TextColor3=Theme.Colors.TextMed})
            end)
            btn.MouseLeave:Connect(function()
                TweenController:Play(btn, TweenController.Smooth, {BackgroundTransparency=1})
                TweenController:Play(btn, TweenController.Smooth, {TextColor3=Theme.Colors.TextLow})
            end)
            if callback then
                Registry.RegisterConnection(self, btn.MouseButton1Click:Connect(callback))
            end
            return btn
        end
        tbBtn("⌕", 0, function() if self.Notify then self.Notify({Text="Busca em breve",Type="info"}) end end)
        tbBtn("⚙", 38, function() self:SwitchTab("settings") end)

        -- ── Body (sidebar + content) ──────────────────────────────────
        self.Body = Utils.Create("Frame", {
            Name="Body", Size=UDim2.new(1,0,1,-84), Position=UDim2.new(0,0,0,60),
            BackgroundTransparency=1, Parent=self.Window
        })

        -- ── Sidebar (matches .sidebar — 162px wide) ───────────────────
        local sidebar = Utils.Create("Frame", {
            Name="Sidebar", Size=UDim2.new(0,195,1,0),
            BackgroundColor3=Theme.Colors.Black, BackgroundTransparency=0,
            BorderSizePixel=0, Parent=self.Body
        })
        Utils.Stroke(sidebar, Theme.Colors.Border, 1, Theme.Trans.Border)
        Theme:Bind(sidebar, {BackgroundColor3="Black", BackgroundTransparency=function() return 0 end})

        local sbScroll = Utils.Create("ScrollingFrame", {
            Size=UDim2.new(1,0,1,-60), BackgroundTransparency=1,
            ScrollBarThickness=0, ClipsDescendants=false, Parent=sidebar
        })
        local sbLayout = Utils.Create("UIListLayout", {
            Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder, Parent=sbScroll
        })
        Utils.Padding(sbScroll, 7, 10)
        Utils.AutoCanvas(sbScroll, sbLayout, 14)

        -- Section label (matches .sb-label)
        local function sbLabel(text)
            local lbl = Utils.Create("TextLabel", {
                Name="SectionLabel",
                Text=text, Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
                TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
                Size=UDim2.new(1,-14,0,18),
                TextXAlignment=Enum.TextXAlignment.Left,
                Parent=sbScroll
            })
            Utils.Padding(lbl, 8, 0)
            Theme:Bind(lbl, {TextColor3="TextMuted"})
            return lbl
        end

        -- Tab button factory (matches .tab-btn)
        local function makeTabBtn(id, label, icon, badge, locked)
            local btn = Utils.Create("TextButton", {
                Name="Tab_"..id, Text="",
                Size=UDim2.new(1,-14,0,44),
                BackgroundColor3=Theme.Colors.Surface, BackgroundTransparency=1,
                AutoButtonColor=false, BorderSizePixel=0,
                Parent=sbScroll
            })
            Utils.Corner(btn, Theme.Sizes.RadiusMedium)

            -- Left accent bar (matches .tab-btn::before  — animates height)
            local marker = Utils.Create("Frame", {
                Name="Marker", Size=UDim2.new(0,3,0,0),
                Position=UDim2.new(0,0,0.5,0), AnchorPoint=Vector2.new(0,0.5),
                BackgroundColor3=Theme.Colors.Accent, BorderSizePixel=0, Parent=btn
            })
            Utils.Corner(marker, UDim.new(1,0))
            Theme:Bind(marker, {BackgroundColor3="Accent"})

            -- Icon
            local ico = Utils.Create("TextLabel", {
                Name="Icon", Text=icon or "○",
                Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextNormal,
                TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
                Size=UDim2.new(0,15,0,44), Position=UDim2.new(0,9,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, Parent=btn
            })
            Theme:Bind(ico, {TextColor3="TextMuted"})

            -- Label
            local lbl = Utils.Create("TextLabel", {
                Name="Label", Text=label,
                Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextNormal,
                TextColor3=Theme.Colors.TextLow, BackgroundTransparency=1,
                Size=UDim2.new(1,-56,1,0), Position=UDim2.new(0,28,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, Parent=btn
            })
            Theme:Bind(lbl, {TextColor3="TextLow"})

            -- Badge (matches .t-badge)
            if badge then
                local bdg = Utils.Create("TextLabel", {
                    Name="Badge", Text=badge,
                    Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
                    TextColor3=Theme.Colors.Accent,
                    BackgroundColor3=Theme.Colors.Accent, BackgroundTransparency=Theme.Trans.AccentGlow,
                    AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-4,0.5,0),
                    Size=UDim2.new(0,0,0,16), AutomaticSize=Enum.AutomaticSize.X,
                    Parent=btn
                })
                Utils.Corner(bdg, Theme.Sizes.RadiusSmall)
                Utils.Stroke(bdg, Theme.Colors.Accent, 1, Theme.Trans.AccentBorder)
                Utils.PaddingLR(bdg, 5, 0)
                Theme:Bind(bdg, {TextColor3="Accent", BackgroundColor3="Accent"})
            end

            -- Lock icon for locked tabs (matches .tab-btn.locked)
            if locked then
                Utils.Create("TextLabel", {
                    Name="LockIcon", Text="🔒",
                    Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextSmall,
                    TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
                    Size=UDim2.new(0,14,1,0), AnchorPoint=Vector2.new(1,0.5),
                    Position=UDim2.new(1,-4,0.5,0), Parent=btn
                })
                btn.BackgroundTransparency = 0.6
                lbl.TextTransparency       = 0.5
                ico.TextTransparency       = 0.5
            else
                btn.MouseEnter:Connect(function()
                    if self.State.ActiveTab:Get() ~= id then
                        TweenController:Play(btn, TweenController.Smooth, {BackgroundTransparency=Theme.Trans.Surface})
                        TweenController:Play(lbl,  TweenController.Smooth, {TextColor3=Theme.Colors.TextMed})
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if self.State.ActiveTab:Get() ~= id then
                        TweenController:Play(btn, TweenController.Smooth, {BackgroundTransparency=1})
                        TweenController:Play(lbl,  TweenController.Smooth, {TextColor3=Theme.Colors.TextLow})
                    end
                end)
                Registry.RegisterConnection(self, btn.MouseButton1Click:Connect(function()
                    self:SwitchTab(id)
                end))
            end

            self.TabButtons[id] = {Button=btn, Marker=marker, Label=lbl, Icon=ico, Locked=locked}
        end

        -- Build sidebar nav
        sbLabel("Main")
        makeTabBtn("home",     "Home",     "⌂",  nil,   false)
        makeTabBtn("player",   "Player",   "👤", nil,   false)
        makeTabBtn("visual",   "Visual",   "◉",  nil,   false)
        makeTabBtn("aimbot",   "Aimbot",   "◎",  "HOT", false)
        makeTabBtn("vip",      "VIP Zone", "🔒", nil,   true)
        sbLabel("System")
        makeTabBtn("misc",     "Misc",     "≡",  nil,   false)
        makeTabBtn("settings", "Settings", "⚙",  nil,   false)

        -- Sidebar spacer
        Utils.Create("Frame", {Size=UDim2.new(1,0,0,8), BackgroundTransparency=1, Parent=sbScroll})

        -- Sidebar footer (matches .sb-footer)
        local sbFooter = Utils.Create("Frame", {
            Name="Footer", Size=UDim2.new(1,0,0,60),
            Position=UDim2.new(0,0,1,-60),
            BackgroundColor3=Theme.Colors.Border, BackgroundTransparency=Theme.Trans.Border,
            BorderSizePixel=0, Parent=sidebar
        })
        local sbUser = Utils.Create("TextButton", {
            Name="User", Text="",
            Size=UDim2.new(1,-14,0,44), Position=UDim2.new(0,7,0,8),
            BackgroundColor3=Theme.Colors.Surface, BackgroundTransparency=1,
            AutoButtonColor=false, Parent=sbFooter
        })
        Utils.Corner(sbUser, Theme.Sizes.RadiusMedium)
        sbUser.MouseEnter:Connect(function() TweenController:Play(sbUser, TweenController.Smooth, {BackgroundTransparency=Theme.Trans.Surface}) end)
        sbUser.MouseLeave:Connect(function() TweenController:Play(sbUser, TweenController.Smooth, {BackgroundTransparency=1}) end)

        local avatar = Utils.Create("Frame", {
            Size=UDim2.new(0,24,0,24), Position=UDim2.new(0,8,0.5,-12),
            BackgroundColor3=Theme.Colors.Accent, BorderSizePixel=0, Parent=sbUser
        })
        Utils.Corner(avatar, UDim.new(1,0))
        Utils.Gradient(avatar, ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Colors.Accent),
            ColorSequenceKeypoint.new(1, Theme.Colors.AccentLow)
        }), 135)
        Utils.Create("TextLabel", {
            Text="C", Font=Theme.Fonts.Bold, TextSize=10,
            TextColor3=Color3.new(1,1,1), BackgroundTransparency=1,
            Size=UDim2.new(1,0,1,0), Parent=avatar
        })
        Utils.Create("TextLabel", {
            Text="ClaudeUser", Font=Theme.Fonts.Bold, TextSize=Theme.Sizes.TextSmall,
            TextColor3=Theme.Colors.TextMed, BackgroundTransparency=1,
            Size=UDim2.new(1,-40,0,14), Position=UDim2.new(0,34,0,4),
            TextXAlignment=Enum.TextXAlignment.Left, Parent=sbUser
        })
        Utils.Create("TextLabel", {
            Text="Admin", Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
            TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
            Size=UDim2.new(1,-40,0,12), Position=UDim2.new(0,34,0,18),
            TextXAlignment=Enum.TextXAlignment.Left, Parent=sbUser
        })

        -- ── Content Area ───────────────────────────────────────────────
        self.ContentArea = Utils.Create("Frame", {
            Name="ContentArea", Size=UDim2.new(1,-195,1,0), Position=UDim2.new(0,195,0,0),
            BackgroundTransparency=1, Parent=self.Body, ClipsDescendants=true
        })
        self.Content = self.ContentArea

        -- ── Helper: panel header (matches .panel-hdr) ─────────────────
        local function buildPanelHeader(parent, iconChar, title, desc)
            local hdr = Utils.Create("Frame", {
                Name="PanelHeader", Size=UDim2.new(1,0,0,70),
                BackgroundTransparency=1, Parent=parent
            })
            local borderLine = Utils.Create("Frame", {
                Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
                BackgroundColor3=Theme.Colors.Border, BackgroundTransparency=Theme.Trans.Border,
                BorderSizePixel=0, Parent=hdr
            })
            Theme:Bind(borderLine, {BackgroundColor3="Border", BackgroundTransparency=function() return Theme.Trans.Border end})

            -- Icon box (matches .p-icon)
            local iconBox = Utils.Create("Frame", {
                Name="IconBox", Size=UDim2.new(0,44,0,44),
                Position=UDim2.new(0,0,0.5,-22),
                BackgroundColor3=Theme.Colors.Accent, BackgroundTransparency=Theme.Trans.AccentGlow,
                BorderSizePixel=0, Parent=hdr
            })
            Utils.Corner(iconBox, Theme.Sizes.RadiusMedium)
            Utils.Stroke(iconBox, Theme.Colors.Accent, 1, Theme.Trans.AccentBorder)
            Theme:Bind(iconBox, {BackgroundColor3="Accent", BackgroundTransparency=function() return Theme.Trans.AccentGlow end})

            Utils.Create("TextLabel", {
                Text=iconChar, Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextLarge,
                TextColor3=Theme.Colors.Accent, BackgroundTransparency=1,
                Size=UDim2.new(1,0,1,0), Parent=iconBox
            })

            Utils.Create("TextLabel", {
                Name="PTitle", Text=title, Font=Theme.Fonts.Bold, TextSize=Theme.Sizes.TextHeader,
                TextColor3=Theme.Colors.TextHigh, BackgroundTransparency=1,
                Size=UDim2.new(1,-65,0,22), Position=UDim2.new(0,60,0,10),
                TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr
            })
            Utils.Create("TextLabel", {
                Name="PDesc", Text=desc, Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextSmall,
                TextColor3=Theme.Colors.TextLow, BackgroundTransparency=1,
                Size=UDim2.new(1,-65,0,16), Position=UDim2.new(0,60,0,36),
                TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr
            })
            return hdr
        end

        -- ── Helper: panel scroll frame ─────────────────────────────────
        local function makePanel(id)
            local panel = Utils.Create("ScrollingFrame", {
                Name="Panel_"..id, Size=UDim2.new(1,-16,1,-12),
                Position=UDim2.new(0,8,0,6),
                BackgroundTransparency=1, ScrollBarThickness=4,
                ScrollBarImageColor3=Theme.Colors.Accent,
                CanvasSize=UDim2.new(0,0,0,0), Visible=false,
                Parent=self.ContentArea
            })
            local layout = Utils.Create("UIListLayout", {
                Padding=UDim.new(0,12), SortOrder=Enum.SortOrder.LayoutOrder, Parent=panel
            })
            Registry.RegisterConnection(self, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                panel.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16)
            end))
            self.Panels[id] = panel
            return panel
        end

        -- ── Helper: group label (matches .cg-lbl) ────────────────────
        local function makeGroupLabel(parent, text)
            local lbl = Utils.Create("TextLabel", {
                Name="GroupLabel", Text=text:upper(),
                Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
                TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,14),
                TextXAlignment=Enum.TextXAlignment.Left,
                Parent=parent
            })
            Theme:Bind(lbl, {TextColor3="TextMuted"})
            return lbl
        end

        -- ── Helper: separator (matches .ui-sep) ──────────────────────
        local function makeSep(parent)
            local s = Utils.Create("Frame", {
                Size=UDim2.new(1,0,0,1), BackgroundColor3=Theme.Colors.Border,
                BackgroundTransparency=Theme.Trans.Border, BorderSizePixel=0, Parent=parent
            })
            Theme:Bind(s, {BackgroundColor3="Border", BackgroundTransparency=function() return Theme.Trans.Border end})
            return s
        end

        -- ── Helper: group wrapper ─────────────────────────────────────
        local function makeGroup(parent, labelText)
            local wrap = Utils.Create("Frame", {
                Size=UDim2.new(1,0,0,0), BackgroundTransparency=1,
                AutomaticSize=Enum.AutomaticSize.Y, Parent=parent
            })
            makeGroupLabel(wrap, labelText)
            local body = Utils.Create("Frame", {
                Name="Body", Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,18),
                BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, Parent=wrap
            })
            Utils.Create("UIListLayout", {
                Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder, Parent=body
            })
            return wrap, body
        end

        -- ── Helper: stat card (matches .stat-c) ──────────────────────
        local function makeStatCard(parent, lbl, val, sub, valColor)
            local card = Utils.Create("Frame", {
                BackgroundColor3=Theme.Colors.Surface,
                BackgroundTransparency=Theme.Trans.Surface, Parent=parent
            })
            Utils.Corner(card, Theme.Sizes.RadiusMedium)
            Utils.Stroke(card, Theme.Colors.Border, 1, Theme.Trans.Border)
            Utils.Padding(card, 11)
            Theme:Bind(card, {BackgroundColor3="Surface", BackgroundTransparency=function() return Theme.Trans.Surface end})

            Utils.Create("TextLabel", {
                Text=lbl:upper(), Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
                TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,12), TextXAlignment=Enum.TextXAlignment.Left, Parent=card
            })
            local valLbl = Utils.Create("TextLabel", {
                Name="Val", Text=tostring(val), Font=Theme.Fonts.Mono, TextSize=17,
                TextColor3=valColor or Theme.Colors.TextHigh, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,22), Position=UDim2.new(0,0,0,14),
                TextXAlignment=Enum.TextXAlignment.Left, Parent=card
            })
            if sub then
                Utils.Create("TextLabel", {
                    Text=tostring(sub), Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
                    TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
                    Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,38),
                    TextXAlignment=Enum.TextXAlignment.Left, Parent=card
                })
            end
            return card, valLbl
        end

        -- ── Helper: save manager bar (matches .sm-bar) ───────────────
        local function makeSaveBar(parent, onReset, onSave)
            local bar = Utils.Create("Frame", {
                Name="SaveBar", Size=UDim2.new(1,0,0,34),
                BackgroundColor3=Theme.Colors.Surface,
                BackgroundTransparency=Theme.Trans.Surface, Parent=parent
            })
            Utils.Corner(bar, Theme.Sizes.RadiusMedium)
            Utils.Stroke(bar, Theme.Colors.Border, 1, Theme.Trans.Border)
            Utils.Padding(bar, 12, 0)
            Theme:Bind(bar, {BackgroundColor3="Surface", BackgroundTransparency=function() return Theme.Trans.Surface end})

            -- Status dot (green = saved, yellow/pulse = dirty)
            local dot = Utils.Create("Frame", {
                Name="Dot", Size=UDim2.new(0,6,0,6),
                Position=UDim2.new(0,0,0.5,-3),
                BackgroundColor3=Theme.Colors.Success, BorderSizePixel=0, Parent=bar
            })
            Utils.Corner(dot, UDim.new(1,0))

            local txt = Utils.Create("TextLabel", {
                Name="Text", Text="Configurações salvas",
                Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextSmall,
                TextColor3=Theme.Colors.TextLow, BackgroundTransparency=1,
                Size=UDim2.new(1,-150,1,0), Position=UDim2.new(0,14,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, Parent=bar
            })
            Theme:Bind(txt, {TextColor3="TextLow"})

            -- Buttons
            local btnWrap = Utils.Create("Frame", {
                Size=UDim2.new(0,136,1,0), AnchorPoint=Vector2.new(1,0.5),
                Position=UDim2.new(1,0,0.5,0), BackgroundTransparency=1, Parent=bar
            })
            Utils.Create("UIListLayout", {
                FillDirection=Enum.FillDirection.Horizontal,
                HorizontalAlignment=Enum.HorizontalAlignment.Right,
                VerticalAlignment=Enum.VerticalAlignment.Center,
                Padding=UDim.new(0,6), Parent=btnWrap
            })

            local function smBtn(label, isAccent, callback)
                local b = Utils.Create("TextButton", {
                    Text=label, Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextSmall,
                    TextColor3=isAccent and Theme.Colors.Accent or Theme.Colors.TextMed,
                    BackgroundColor3=isAccent and Theme.Colors.Accent or Theme.Colors.Background2,
                    BackgroundTransparency=isAccent and Theme.Trans.AccentGlow or Theme.Trans.Surface,
                    Size=UDim2.new(0,62,0,22), AutoButtonColor=false, Parent=btnWrap
                })
                Utils.Corner(b, Theme.Sizes.RadiusSmall)
                Utils.Stroke(b, isAccent and Theme.Colors.Accent or Theme.Colors.Border, 1,
                    isAccent and Theme.Trans.AccentBorder or Theme.Trans.Border)
                b.MouseEnter:Connect(function()
                    TweenController:Play(b, TweenController.Smooth, {BackgroundTransparency=isAccent and 0.55 or Theme.Trans.SurfaceHover})
                end)
                b.MouseLeave:Connect(function()
                    TweenController:Play(b, TweenController.Smooth, {BackgroundTransparency=isAccent and Theme.Trans.AccentGlow or Theme.Trans.Surface})
                end)
                if callback then
                    Registry.RegisterConnection(self, b.MouseButton1Click:Connect(callback))
                end
                return b
            end

            smBtn("Reset",  false, onReset)
            smBtn("Salvar", true,  onSave)

            return bar, dot, txt
        end

        -- ================================================================
        --  HOME PANEL
        -- ================================================================
        local homeP = makePanel("home")
        buildPanelHeader(homeP, "⌂", "Home", "Painel geral e status do sistema")

        -- Welcome banner (matches .welcome-banner)
        local welcome = Utils.Create("Frame", {
            Size=UDim2.new(1,0,0,80),
            BackgroundColor3=Theme.Colors.Accent, BackgroundTransparency=Theme.Trans.AccentGlow,
            Parent=homeP
        })
        Utils.Corner(welcome, Theme.Sizes.RadiusLarge)
        Utils.Stroke(welcome, Theme.Colors.Accent, 1, Theme.Trans.AccentBorder)
        Theme:Bind(welcome, {BackgroundColor3="Accent", BackgroundTransparency=function() return Theme.Trans.AccentGlow end})
        Utils.Padding(welcome, 18)

        local wAv = Utils.Create("Frame", {
            Size=UDim2.new(0,44,0,44), Position=UDim2.new(0,0,0.5,-22),
            BackgroundColor3=Theme.Colors.Accent, BorderSizePixel=0, Parent=welcome
        })
        Utils.Corner(wAv, UDim.new(1,0))
        Utils.Gradient(wAv, ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Colors.Accent),
            ColorSequenceKeypoint.new(1, Theme.Colors.AccentLow)
        }), 135)
        Utils.Create("TextLabel", {
            Text="C", Font=Theme.Fonts.Bold, TextSize=18,
            TextColor3=Color3.new(1,1,1), BackgroundTransparency=1,
            Size=UDim2.new(1,0,1,0), Parent=wAv
        })

        local wTxt = Utils.Create("TextLabel", {
            Name="Greeting", Text="Boa noite, ClaudeUser!",
            Font=Theme.Fonts.Bold, TextSize=Theme.Sizes.TextTitle,
            TextColor3=Theme.Colors.TextHigh, BackgroundTransparency=1,
            Size=UDim2.new(1,-175,0,22), Position=UDim2.new(0,56,0,6),
            TextXAlignment=Enum.TextXAlignment.Left, Parent=welcome
        })
        Theme:Bind(wTxt, {TextColor3="TextHigh"})

        Utils.Create("TextLabel", {
            Text="Claude UI "..self.Version.." · Script ativo e operacional",
            Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextSmall,
            TextColor3=Theme.Colors.TextLow, BackgroundTransparency=1,
            Size=UDim2.new(1,-175,0,14), Position=UDim2.new(0,56,0,32),
            TextXAlignment=Enum.TextXAlignment.Left, Parent=welcome
        })

        -- Clock widget
        local clockF = Utils.Create("Frame", {
            Size=UDim2.new(0,110,0,44), AnchorPoint=Vector2.new(1,0.5),
            Position=UDim2.new(1,0,0.5,0),
            BackgroundTransparency=1, Parent=welcome
        })
        local clockT = Utils.Create("TextLabel", {
            Name="Clock", Text="00:00:00",
            Font=Theme.Fonts.Mono, TextSize=20,
            TextColor3=Theme.Colors.TextHigh, BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,24),
            TextXAlignment=Enum.TextXAlignment.Right, Parent=clockF
        })
        Theme:Bind(clockT, {TextColor3="TextHigh"})
        local clockD = Utils.Create("TextLabel", {
            Name="ClockDate", Text="00/00/0000",
            Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
            TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,26),
            TextXAlignment=Enum.TextXAlignment.Right, Parent=clockF
        })
        Theme:Bind(clockD, {TextColor3="TextMuted"})

        -- Stats row (matches .stats-row — 4 cols grid)
        local statsRow = Utils.Create("Frame", {Size=UDim2.new(1,0,0,70), BackgroundTransparency=1, Parent=homeP})
        Utils.Create("UIGridLayout", {
            CellSize=UDim2.new(0.25,-8,0,70), CellPadding=UDim2.new(0,9,0,0), Parent=statsRow
        })
        local _, pingVal = makeStatCard(statsRow, "Ping",     "42",      "ms latência",  Theme.Colors.Accent)
        makeStatCard(statsRow, "Players",  "12/20",   "no servidor",  Theme.Colors.TextHigh)
        makeStatCard(statsRow, "Executor", "Synapse X","✓ Suportado", Theme.Colors.Success)
        local _, uptimeVal = makeStatCard(statsRow, "Uptime", "0s",       "sessão",       Theme.Colors.AccentHigh)

        -- Two-col: changelog + friends
        local twoCol = Utils.Create("Frame", {Size=UDim2.new(1,0,0,190), BackgroundTransparency=1, Parent=homeP})
        Utils.Create("UIGridLayout", {
            CellSize=UDim2.new(0.5,-7,0,190), CellPadding=UDim2.new(0,13,0,0), Parent=twoCol
        })

        -- Changelog card
        local chCard = Utils.Create("Frame", {
            BackgroundColor3=Theme.Colors.Surface, BackgroundTransparency=Theme.Trans.Surface, Parent=twoCol
        })
        Utils.Corner(chCard, Theme.Sizes.RadiusLarge)
        Utils.Stroke(chCard, Theme.Colors.Border, 1, Theme.Trans.Border)
        Utils.Padding(chCard, 13)
        local chTitle = Utils.Create("TextLabel", {
            Text="Changelog", Font=Theme.Fonts.Bold, TextSize=Theme.Sizes.TextNormal,
            TextColor3=Theme.Colors.TextHigh, BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,16), TextXAlignment=Enum.TextXAlignment.Left, Parent=chCard
        })
        Theme:Bind(chTitle, {TextColor3="TextHigh"})

        local chList = Utils.Create("Frame", {
            Size=UDim2.new(1,0,1,-24), Position=UDim2.new(0,0,0,22),
            BackgroundTransparency=1, Parent=chCard
        })
        local changes = {
            {"v4.0 — Ultimate",     "21/02/2026", "ColorPicker, Dialogs, Temas v4 Complete."},
            {"v3.0 — HTML Rewrite", "10/02/2026", "Migração para HTML com tema Claude completo."},
            {"v2.0 — Lua Base",     "05/01/2026", "Versão original em Lua para Roblox."}
        }
        for i, c in ipairs(changes) do
            local yOff = (i-1)*55
            local dot = Utils.Create("Frame", {
                Size=UDim2.new(0,8,0,8), Position=UDim2.new(0,0,0,yOff+2),
                BackgroundColor3=i==1 and Theme.Colors.Accent or Theme.Colors.TextMuted,
                BorderSizePixel=0, Parent=chList
            })
            Utils.Corner(dot, UDim.new(1,0))
            if i==1 then Theme:Bind(dot, {BackgroundColor3="Accent"}) end
            if i < #changes then
                Utils.Create("Frame", {
                    Size=UDim2.new(0,1,0,45), Position=UDim2.new(0,3,0,yOff+12),
                    BackgroundColor3=Theme.Colors.Border, BackgroundTransparency=Theme.Trans.Border,
                    BorderSizePixel=0, Parent=chList
                })
            end
            Utils.Create("TextLabel", {
                Text=c[1], Font=Theme.Fonts.Bold, TextSize=Theme.Sizes.TextSmall,
                TextColor3=Theme.Colors.TextHigh, BackgroundTransparency=1,
                Size=UDim2.new(1,-18,0,14), Position=UDim2.new(0,16,0,yOff),
                TextXAlignment=Enum.TextXAlignment.Left, Parent=chList
            })
            Utils.Create("TextLabel", {
                Text=c[2], Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
                TextColor3=Theme.Colors.Accent, BackgroundTransparency=1,
                Size=UDim2.new(1,-18,0,11), Position=UDim2.new(0,16,0,yOff+15),
                TextXAlignment=Enum.TextXAlignment.Left, Parent=chList
            })
            Utils.Create("TextLabel", {
                Text=c[3], Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextXS,
                TextColor3=Theme.Colors.TextLow, BackgroundTransparency=1,
                Size=UDim2.new(1,-18,0,22), Position=UDim2.new(0,16,0,yOff+28),
                TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, Parent=chList
            })
        end

        -- Friends card
        local frCard = Utils.Create("Frame", {
            BackgroundColor3=Theme.Colors.Surface, BackgroundTransparency=Theme.Trans.Surface, Parent=twoCol
        })
        Utils.Corner(frCard, Theme.Sizes.RadiusLarge)
        Utils.Stroke(frCard, Theme.Colors.Border, 1, Theme.Trans.Border)
        Utils.Padding(frCard, 13)
        Utils.Create("TextLabel", {
            Text="Amigos", Font=Theme.Fonts.Bold, TextSize=Theme.Sizes.TextNormal,
            TextColor3=Theme.Colors.TextHigh, BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,16), TextXAlignment=Enum.TextXAlignment.Left, Parent=frCard
        })
        local frGrid = Utils.Create("Frame", {Size=UDim2.new(1,0,1,-24), Position=UDim2.new(0,0,0,22), BackgroundTransparency=1, Parent=frCard})
        Utils.Create("UIGridLayout", {CellSize=UDim2.new(0.5,-6,0.5,-5), CellPadding=UDim2.new(0,8,0,8), Parent=frGrid})
        makeStatCard(frGrid, "Server",  "2",  nil, Theme.Colors.Accent)
        makeStatCard(frGrid, "Online",  "5",  nil, Theme.Colors.Success)
        makeStatCard(frGrid, "Offline", "11", nil, Theme.Colors.TextMuted)
        makeStatCard(frGrid, "Total",   "18", nil, Theme.Colors.Info)

        -- Discord button (matches .discord-b)
        local dcBtn = Utils.Create("TextButton", {
            Size=UDim2.new(1,0,0,50),
            BackgroundColor3=Color3.fromRGB(88,101,242), BackgroundTransparency=0.88,
            Text="", AutoButtonColor=false, Parent=homeP
        })
        Utils.Corner(dcBtn, Theme.Sizes.RadiusLarge)
        Utils.Stroke(dcBtn, Color3.fromRGB(88,101,242), 1, 0.80)
        Utils.Padding(dcBtn, 14)
        dcBtn.MouseEnter:Connect(function()
            TweenController:Play(dcBtn, TweenController.Smooth, {BackgroundTransparency=0.84})
        end)
        dcBtn.MouseLeave:Connect(function()
            TweenController:Play(dcBtn, TweenController.Smooth, {BackgroundTransparency=0.88})
        end)

        local dcIco = Utils.Create("Frame", {
            Size=UDim2.new(0,30,0,30), Position=UDim2.new(0,0,0.5,-15),
            BackgroundColor3=Color3.fromRGB(88,101,242), BackgroundTransparency=0.80,
            Parent=dcBtn
        })
        Utils.Corner(dcIco, UDim.new(1,0))
        Utils.Create("TextLabel", {
            Text="◎", Font=Theme.Fonts.Main, TextSize=14,
            TextColor3=Color3.fromRGB(130,150,248), BackgroundTransparency=1,
            Size=UDim2.new(1,0,1,0), Parent=dcIco
        })
        Utils.Create("TextLabel", {
            Text="Servidor do Discord", Font=Theme.Fonts.Bold, TextSize=Theme.Sizes.TextNormal,
            TextColor3=Theme.Colors.TextHigh, BackgroundTransparency=1,
            Size=UDim2.new(1,-140,0,14), Position=UDim2.new(0,38,0,6),
            TextXAlignment=Enum.TextXAlignment.Left, Parent=dcBtn
        })
        Utils.Create("TextLabel", {
            Text="Suporte, novidades e updates",
            Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextXS,
            TextColor3=Theme.Colors.TextLow, BackgroundTransparency=1,
            Size=UDim2.new(1,-140,0,12), Position=UDim2.new(0,38,0,24),
            TextXAlignment=Enum.TextXAlignment.Left, Parent=dcBtn
        })
        local dcPill = Utils.Create("TextLabel", {
            Text="discord.gg/meuserver", Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
            TextColor3=Color3.fromRGB(130,150,248),
            BackgroundColor3=Color3.fromRGB(88,101,242), BackgroundTransparency=0.85,
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
            Size=UDim2.new(0,0,0,22), AutomaticSize=Enum.AutomaticSize.X,
            Parent=dcBtn
        })
        Utils.Corner(dcPill, Theme.Sizes.RadiusXLarge)
        Utils.Stroke(dcPill, Color3.fromRGB(88,101,242), 1, 0.70)
        Utils.PaddingLR(dcPill, 11, 0)
        Registry.RegisterConnection(self, dcBtn.MouseButton1Click:Connect(function()
            dcPill.Text = "✓ Copiado!"
            if self.Notify then self.Notify({Text="Discord copiado!", Type="success"}) end
            task.delay(2.5, function() dcPill.Text = "discord.gg/meuserver" end)
        end))

        -- ================================================================
        --  PLAYER PANEL
        -- ================================================================
        local playerP = makePanel("player")
        buildPanelHeader(playerP, "👤", "Player", "Controle de movimento e física")

        -- Save bar
        local _, smDot, smText = makeSaveBar(playerP,
            function() if self.Notify then self.Notify({Text="Configurações resetadas",Type="warning"}) end end,
            function() if self.Notify then self.Notify({Text="Configurações salvas!",Type="success"}) end end
        )

        local _, movBody = makeGroup(playerP, "Movimento")
        local speed = Components.Slider.new(movBody, {Text="Velocidade",    Min=16, Max=200, Default=16, Callback=function() smDot.BackgroundColor3=Theme.Colors.Warning end})
        local jump  = Components.Slider.new(movBody, {Text="Altura do Pulo",Min=7,  Max=100, Default=7,  Callback=function() smDot.BackgroundColor3=Theme.Colors.Warning end})
        Registry.Register(speed, self); Registry.Register(jump, self)

        makeSep(playerP)

        local _, physBody = makeGroup(playerP, "Físicas")
        local noclip  = Components.Toggle.new(physBody, {Text="NoClip",        Icon="◈"})
        local infjump = Components.Toggle.new(physBody, {Text="Infinite Jump",  Icon="▲"})
        local fly     = Components.Toggle.new(physBody, {Text="Fly",            Icon="✈", Locked=true})
        Registry.Register(noclip, self); Registry.Register(infjump, self); Registry.Register(fly, self)

        makeSep(playerP)

        local _, actBody = makeGroup(playerP, "Ações")
        local actGrid = Utils.Create("Frame", {
            Size=UDim2.new(1,0,0,90), BackgroundTransparency=1, Parent=actBody
        })
        Utils.Create("UIGridLayout", {
            CellSize=UDim2.new(0.5,-6,0,40), CellPadding=UDim2.new(0,8,0,8), Parent=actGrid
        })
        local resetBtn = Components.Button.new(actGrid, {Text="Resetar", Callback=function()
            if self.Notify then self.Notify({Text="Resetando jogador",Type="warning"}) end
        end})
        local spawnBtn = Components.Button.new(actGrid, {Text="Ir ao Spawn", Variant="Primary", Callback=function()
            self:ShowDialog("teleport")
        end})
        local lockedBtn = Components.Button.new(actBody, {Text="Speed Hack (Locked)", Locked=true})
        Registry.Register(resetBtn, self); Registry.Register(spawnBtn, self); Registry.Register(lockedBtn, self)

        -- ================================================================
        --  VISUAL PANEL
        -- ================================================================
        local visualP = makePanel("visual")
        buildPanelHeader(visualP, "◉", "Visual", "ESP, câmera e overlays")

        local _, espBody = makeGroup(visualP, "ESP")
        local espToggle   = Components.Toggle.new(espBody, {Text="ESP Jogadores", Icon="▦"})
        local namesToggle = Components.Toggle.new(espBody, {Text="Mostrar Nomes", Icon="≡", State=true})
        Registry.Register(espToggle, self); Registry.Register(namesToggle, self)

        makeSep(visualP)

        -- Color Picker section (matches .ui-cp-wrap)
        local _, cpBody = makeGroup(visualP, "Cor do ESP — Color Picker")
        local cpWrap = Utils.Create("Frame", {
            Size=UDim2.new(1,0,0,120),
            BackgroundColor3=Theme.Colors.Surface, BackgroundTransparency=Theme.Trans.Surface, Parent=cpBody
        })
        Utils.Corner(cpWrap, Theme.Sizes.RadiusMedium)
        Utils.Stroke(cpWrap, Theme.Colors.Border, 1, Theme.Trans.Border)
        Utils.Padding(cpWrap, 12)
        Theme:Bind(cpWrap, {BackgroundColor3="Surface", BackgroundTransparency=function() return Theme.Trans.Surface end})

        Utils.Create("TextLabel", {
            Text="Selecione a cor do ESP", Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextSmall,
            TextColor3=Theme.Colors.TextMed, BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,12), TextXAlignment=Enum.TextXAlignment.Left, Parent=cpWrap
        })

        -- Color wheel simulation (gradient rainbow button)
        local cpWheel = Utils.Create("TextButton", {
            Size=UDim2.new(0,78,0,78), Position=UDim2.new(0,0,0,20),
            BackgroundColor3=Theme.Colors.Background3, Text="", AutoButtonColor=false, Parent=cpWrap
        })
        Utils.Corner(cpWheel, UDim.new(1,0))
        Utils.Gradient(cpWheel, ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,0,0)),
        }), 0)
        Utils.Stroke(cpWheel, Theme.Colors.Border, 1.5, Theme.Trans.BorderMid)

        local cpCursor = Utils.Create("Frame", {
            Size=UDim2.new(0,10,0,10), Position=UDim2.new(0.5,-5,0.5,-5),
            BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, Parent=cpWheel
        })
        Utils.Corner(cpCursor, UDim.new(1,0))
        Utils.Stroke(cpCursor, Color3.fromRGB(0,0,0), 1, 0.5)

        local cpRight = Utils.Create("Frame", {
            Size=UDim2.new(1,-92,0,80), Position=UDim2.new(0,90,0,20),
            BackgroundTransparency=1, Parent=cpWrap
        })

        local brightLabel = Utils.Create("TextLabel", {
            Text="L", Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
            TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
            Size=UDim2.new(0,12,0,12), Parent=cpRight
        })

        local brightTrack = Utils.Create("Frame", {
            Size=UDim2.new(1,-20,0,8), Position=UDim2.new(0,16,0,2),
            BackgroundColor3=Theme.Colors.Background3, BorderSizePixel=0, Parent=cpRight
        })
        Utils.Corner(brightTrack, UDim.new(1,0))
        Utils.Gradient(brightTrack, ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
            ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
        }), 0)

        local brightKnob = Utils.Create("Frame", {
            Size=UDim2.new(0,12,0,12), Position=UDim2.new(1,-6,0.5,-6),
            BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, Parent=brightTrack
        })
        Utils.Corner(brightKnob, UDim.new(1,0))
        Utils.Stroke(brightKnob, Theme.Colors.Border, 1, 0)

        local preview = Utils.Create("Frame", {
            Size=UDim2.new(0,28,0,28), Position=UDim2.new(0,0,0,22),
            BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, Parent=cpRight
        })
        Utils.Corner(preview, Theme.Sizes.RadiusSmall)
        Utils.Stroke(preview, Theme.Colors.Border, 1, Theme.Trans.Border)

        local hexLabel = Utils.Create("TextLabel", {
            Text="#FFFFFF", Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextNormal,
            TextColor3=Theme.Colors.Accent, BackgroundTransparency=1,
            Size=UDim2.new(1,-36,0,12), Position=UDim2.new(0,36,0,22),
            TextXAlignment=Enum.TextXAlignment.Left, Parent=cpRight
        })
        Theme:Bind(hexLabel, {TextColor3="Accent"})

        local rgbLabel = Utils.Create("TextLabel", {
            Text="rgb(255,255,255)", Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
            TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
            Size=UDim2.new(1,-36,0,12), Position=UDim2.new(0,36,0,38),
            TextXAlignment=Enum.TextXAlignment.Left, Parent=cpRight
        })

        -- Color picker interaction
        local cpHue, cpSat, cpBright2 = 0, 1, 1
        local function cpUpdate()
            local color = Color3.fromHSV(cpHue, cpSat, cpBright2)
            preview.BackgroundColor3 = color
            local r,g,b = math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255)
            hexLabel.Text  = string.format("#%02X%02X%02X", r, g, b)
            rgbLabel.Text  = string.format("rgb(%d,%d,%d)", r, g, b)
        end
        cpUpdate()

        Registry.RegisterConnection(self, cpWheel.MouseButton1Down:Connect(function()
            local conn, upConn
            conn = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local pos  = cpWheel.AbsolutePosition
                    local size = cpWheel.AbsoluteSize
                    local x = math.clamp((inp.Position.X-pos.X)/size.X, 0, 1)
                    local y = math.clamp((inp.Position.Y-pos.Y)/size.Y, 0, 1)
                    cpHue = x; cpSat = 1-y
                    cpCursor.Position = UDim2.new(x,-5,y,-5)
                    cpUpdate()
                end
            end)
            upConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    conn:Disconnect(); upConn:Disconnect()
                end
            end)
        end))
        Registry.RegisterConnection(self, brightTrack.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                local pos  = brightTrack.AbsolutePosition
                local size = brightTrack.AbsoluteSize
                local x = math.clamp((inp.Position.X-pos.X)/size.X, 0, 1)
                cpBright2 = x
                brightKnob.Position = UDim2.new(x,-6,0.5,-6)
                cpUpdate()
            end
        end))

        makeSep(visualP)

        local _, camBody = makeGroup(visualP, "Câmera")
        local fov = Components.Slider.new(camBody, {Text="FOV", Min=60, Max=120, Default=70, Suffix="°"})
        Registry.Register(fov, self)

        local _, tagsBody = makeGroup(visualP, "Tags a mostrar — Multi-select")
        local tags = Components.Dropdown.new(tagsBody, {
            Text="Tags do ESP", MultiSelect=true,
            Items={"Nome","Vida","Distância","Time","Arma"}
        })
        Registry.Register(tags, self)

        -- ================================================================
        --  AIMBOT PANEL
        -- ================================================================
        local aimbotP = makePanel("aimbot")
        buildPanelHeader(aimbotP, "◎", "Aimbot", "Assistência de mira avançada")

        local _, aimBody = makeGroup(aimbotP, "Controles")
        local aimbotTgl = Components.Toggle.new(aimBody, {Text="Aimbot",    Icon="◎"})
        local silentTgl = Components.Toggle.new(aimBody, {Text="Silentaim", Icon="△"})
        Registry.Register(aimbotTgl, self); Registry.Register(silentTgl, self)

        makeSep(aimbotP)

        local _, aimCfg = makeGroup(aimbotP, "Configurações")
        local smooth = Components.Slider.new(aimCfg, {Text="Suavidade",    Min=1,  Max=20,  Default=5})
        local afov   = Components.Slider.new(aimCfg, {Text="FOV do Aimbot",Min=10, Max=300, Default=120, Suffix="°"})
        Registry.Register(smooth, self); Registry.Register(afov, self)

        makeSep(aimbotP)

        local _, targBody = makeGroup(aimbotP, "Alvos — MultiDropdown")
        local bones = Components.Dropdown.new(targBody, {
            Text="Hitboxes Alvo", MultiSelect=true,
            Items={"Cabeça","Tronco","Braços","Pernas"}, Default={"Cabeça"}
        })
        Registry.Register(bones, self)

        local _, modeBody = makeGroup(aimbotP, "Modo")
        local aimMode = Components.Dropdown.new(modeBody, {
            Text="Modo de Mira",
            Items={"Mouse (padrão)","Teclado (Toggle)","Sempre ativo"}, Default="Mouse (padrão)"
        })
        Registry.Register(aimMode, self)

        -- ================================================================
        --  MISC PANEL
        -- ================================================================
        local miscP = makePanel("misc")
        buildPanelHeader(miscP, "≡", "Misc", "Utilitários, dialogs e comandos")

        local _, dlgBody = makeGroup(miscP, "Dialogs")
        local dlgGrid = Utils.Create("Frame", {Size=UDim2.new(1,0,0,90), BackgroundTransparency=1, Parent=dlgBody})
        Utils.Create("UIGridLayout", {
            CellSize=UDim2.new(0.5,-6,0,40), CellPadding=UDim2.new(0,8,0,8), Parent=dlgGrid
        })
        local function dlgBtn(txt, variant, kind)
            local b = Components.Button.new(dlgGrid, {Text=txt, Variant=variant, Callback=function()
                self:ShowDialog(kind)
            end})
            Registry.Register(b, self)
        end
        dlgBtn("Dialog Confirmar", nil,     "confirm")
        dlgBtn("Dialog Perigo",    "danger", "danger")
        dlgBtn("Dialog Info",      nil,     "info")
        dlgBtn("Dialog 3 Botões",  nil,     "choices")

        makeSep(miscP)

        local _, notifBody = makeGroup(miscP, "Notificações")
        local nGrid = Utils.Create("Frame", {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1, Parent=notifBody})
        Utils.Create("UIGridLayout", {
            CellSize=UDim2.new(0.25,-6,0,34), CellPadding=UDim2.new(0,6,0,0), Parent=nGrid
        })
        local function nBtn(txt, kind)
            local b = Components.Button.new(nGrid, {Text=txt, Callback=function()
                if self.Notify then self.Notify({Text=txt, Type=kind}) end
            end})
            Registry.Register(b, self)
        end
        nBtn("✓ OK",    "success")
        nBtn("⚠ Warn",  "warning")
        nBtn("✕ Err",   "error")
        nBtn("ℹ Info",  "info")

        makeSep(miscP)

        local _, cmdBody = makeGroup(miscP, "Comando")
        local cmdInput = Components.Input.new(cmdBody, {
            Icon=">", Placeholder="Digite um comando...",
            Callback=function(text)
                if text and #text > 0 and self.Notify then
                    self.Notify({Text="Cmd: "..text, Type="info"})
                end
            end
        })
        Registry.Register(cmdInput, self)

        makeSep(miscP)

        local mGrid = Utils.Create("Frame", {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1, Parent=miscP})
        Utils.Create("UIGridLayout", {
            CellSize=UDim2.new(0.5,-6,0,40), CellPadding=UDim2.new(0,8,0,0), Parent=mGrid
        })
        local reloadB = Components.Button.new(mGrid, {Text="Recarregar", Callback=function()
            if self.Notify then self.Notify({Text="Recarregando...",Type="warning"}) end
        end})
        local closeB  = Components.Button.new(mGrid, {Text="Fechar UI", Variant="danger", Callback=function()
            self:ShowDialog("danger")
        end})
        Registry.Register(reloadB, self); Registry.Register(closeB, self)

        -- ================================================================
        --  SETTINGS PANEL
        -- ================================================================
        local settP = makePanel("settings")
        buildPanelHeader(settP, "⚙", "Settings", "Temas, aparência e preferências")

        local _, themeBody = makeGroup(settP, "Tema")
        local themeGrid = Utils.Create("Frame", {Size=UDim2.new(1,0,0,90), BackgroundTransparency=1, Parent=themeBody})
        Utils.Create("UIGridLayout", {
            CellSize=UDim2.new(0.2,-7,0,84), CellPadding=UDim2.new(0,8,0,0), Parent=themeGrid
        })

        local swatches = {}
        local function themeSwatch(id, label, color1, color2)
            local sw = Utils.Create("TextButton", {
                Name="Sw_"..id, Text="",
                BackgroundColor3=Theme.Colors.Surface, BackgroundTransparency=Theme.Trans.Surface,
                AutoButtonColor=false, Parent=themeGrid
            })
            Utils.Corner(sw, Theme.Sizes.RadiusMedium)
            local swStroke = Utils.Stroke(sw, Theme.Colors.Border, 1, Theme.Trans.Border)
            Utils.Padding(sw, 9)

            local circle = Utils.Create("Frame", {
                Size=UDim2.new(0,20,0,20), BackgroundColor3=color1, BorderSizePixel=0, Parent=sw
            })
            Utils.Corner(circle, UDim.new(1,0))
            Utils.Gradient(circle, ColorSequence.new({
                ColorSequenceKeypoint.new(0, color1),
                ColorSequenceKeypoint.new(1, color2)
            }), 135)

            Utils.Create("TextLabel", {
                Text=label, Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
                TextColor3=Theme.Colors.TextLow, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,1,-14),
                TextXAlignment=Enum.TextXAlignment.Left, Parent=sw
            })

            swatches[id] = {sw=sw, stroke=swStroke}
            Registry.RegisterConnection(self, sw.MouseButton1Click:Connect(function()
                -- Remove active from all
                for _, s in pairs(swatches) do
                    TweenController:Play(s.sw, TweenController.Smooth, {BackgroundTransparency=Theme.Trans.Surface})
                    s.stroke.Color = Theme.Colors.Border
                    s.stroke.Transparency = Theme.Trans.Border
                end
                -- Activate this one
                TweenController:Play(sw, TweenController.Smooth, {BackgroundTransparency=Theme.Trans.AccentGlow})
                swStroke.Color = Theme.Colors.Accent
                swStroke.Transparency = Theme.Trans.AccentBorder
                Theme:SetTheme(id)
                self.State.Theme:Set(id)
                if self.Notify then self.Notify({Text="Tema: "..label, Type="info"}) end
            end))
        end
        local defs = Theme.Defs
        themeSwatch("default", "Claude",
            Color3.fromRGB(unpack(defs.default.accRgb)), Color3.fromRGB(201,114,64))
        themeSwatch("light",   "Light",
            Color3.fromRGB(unpack(defs.light.accRgb)),   Color3.fromRGB(180,90,50))
        themeSwatch("neon",    "Neon",
            Color3.fromRGB(unpack(defs.neon.accRgb)),    Color3.fromRGB(0,200,128))
        themeSwatch("rose",    "Rose",
            Color3.fromRGB(unpack(defs.rose.accRgb)),    Color3.fromRGB(208,88,104))
        themeSwatch("blue",    "Blue",
            Color3.fromRGB(unpack(defs.blue.accRgb)),    Color3.fromRGB(72,120,184))

        -- Mark default as active
        if swatches["default"] then
            swatches["default"].sw.BackgroundTransparency = Theme.Trans.AccentGlow
            swatches["default"].stroke.Color = Theme.Colors.Accent
            swatches["default"].stroke.Transparency = Theme.Trans.AccentBorder
        end

        local _, acBody = makeGroup(settP, "Cor de Destaque Customizada")
        local acRow = Utils.Create("Frame", {
            Size=UDim2.new(1,0,0,36),
            BackgroundColor3=Theme.Colors.Surface, BackgroundTransparency=Theme.Trans.Surface, Parent=acBody
        })
        Utils.Corner(acRow, Theme.Sizes.RadiusMedium)
        Utils.Stroke(acRow, Theme.Colors.Border, 1, Theme.Trans.Border)
        Utils.Padding(acRow, 12)
        Theme:Bind(acRow, {BackgroundColor3="Surface", BackgroundTransparency=function() return Theme.Trans.Surface end})

        Utils.Create("TextLabel", {
            Text="Cor do Accent", Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextSmall,
            TextColor3=Theme.Colors.TextMed, BackgroundTransparency=1,
            Size=UDim2.new(0,90,1,0), TextXAlignment=Enum.TextXAlignment.Left, Parent=acRow
        })
        local acPreview = Utils.Create("Frame", {
            Size=UDim2.new(0,20,0,20), Position=UDim2.new(0,98,0.5,-10),
            BackgroundColor3=Theme.Colors.Accent, BorderSizePixel=0, Parent=acRow
        })
        Utils.Corner(acPreview, UDim.new(1,0))
        Theme:Bind(acPreview, {BackgroundColor3="Accent"})

        local acBox = Utils.Create("TextBox", {
            Text="#d4825a", Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextSmall,
            TextColor3=Theme.Colors.TextHigh,
            BackgroundColor3=Theme.Colors.Background2, BackgroundTransparency=Theme.Trans.Surface,
            Size=UDim2.new(0,88,0,22), Position=UDim2.new(1,-186,0.5,-11),
            ClearTextOnFocus=false, Parent=acRow
        })
        Utils.Corner(acBox, Theme.Sizes.RadiusSmall)
        Utils.Stroke(acBox, Theme.Colors.Border, 1, Theme.Trans.Border)
        Theme:Bind(acBox, {TextColor3="TextHigh", BackgroundColor3="Background2", BackgroundTransparency=function() return Theme.Trans.Surface end})

        local function acBtnSmall(txt, x, callback)
            local b = Utils.Create("TextButton", {
                Text=txt, Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextSmall,
                TextColor3=Theme.Colors.TextMed,
                BackgroundColor3=Theme.Colors.Background2, BackgroundTransparency=Theme.Trans.Surface,
                Size=UDim2.new(0,58,0,22), Position=UDim2.new(1,x,0.5,-11),
                AutoButtonColor=false, Parent=acRow
            })
            Utils.Corner(b, Theme.Sizes.RadiusSmall)
            Utils.Stroke(b, Theme.Colors.Border, 1, Theme.Trans.Border)
            b.MouseEnter:Connect(function() TweenController:Play(b, TweenController.Smooth, {BackgroundTransparency=Theme.Trans.SurfaceHover}) end)
            b.MouseLeave:Connect(function() TweenController:Play(b, TweenController.Smooth, {BackgroundTransparency=Theme.Trans.Surface}) end)
            if callback then Registry.RegisterConnection(self, b.MouseButton1Click:Connect(callback)) end
            return b
        end
        acBtnSmall("Escolher", -122, function() acBox:CaptureFocus() end)
        acBtnSmall("Reset",    -58, function()
            Theme:SetTheme(Theme.Current)
            acPreview.BackgroundColor3 = Theme.Colors.Accent
            acBox.Text = string.format("#%02X%02X%02X",
                math.floor(Theme.Colors.Accent.R*255),
                math.floor(Theme.Colors.Accent.G*255),
                math.floor(Theme.Colors.Accent.B*255))
        end)
        Registry.RegisterConnection(self, acBox.FocusLost:Connect(function()
            if #acBox.Text == 7 then
                Theme:SetCustomAccent(acBox.Text)
                acPreview.BackgroundColor3 = Theme.Colors.Accent
            end
        end))

        makeSep(settP)

        local _, uiBody = makeGroup(settP, "Interface")
        local animTgl  = Components.Toggle.new(uiBody, {Text="Animações",      Icon="○", State=true})
        local noiseTgl = Components.Toggle.new(uiBody, {Text="Noise Texture",  Icon="▦", State=true})
        Registry.Register(animTgl, self); Registry.Register(noiseTgl, self)

        makeSep(settP)

        local _, sm2Body = makeGroup(settP, "Save Manager — Configurações")
        makeSaveBar(sm2Body,
            function() self:ShowDialog("resetAll") end,
            function() if self.Notify then self.Notify({Text="Config exportada!",Type="success"}) end end
        )

        local _, aboutBody = makeGroup(settP, "Sobre")
        local aboutCard = Utils.Create("Frame", {
            Size=UDim2.new(1,0,0,80),
            BackgroundColor3=Theme.Colors.Surface, BackgroundTransparency=Theme.Trans.Surface, Parent=aboutBody
        })
        Utils.Corner(aboutCard, Theme.Sizes.RadiusMedium)
        Utils.Stroke(aboutCard, Theme.Colors.Border, 1, Theme.Trans.Border)
        Utils.Padding(aboutCard, 12)
        Theme:Bind(aboutCard, {BackgroundColor3="Surface", BackgroundTransparency=function() return Theme.Trans.Surface end})

        Utils.Create("TextLabel", {
            Text="Claude UI v4.0", Font=Theme.Fonts.Bold, TextSize=Theme.Sizes.TextLarge,
            TextColor3=Theme.Colors.TextHigh, BackgroundTransparency=1,
            Size=UDim2.new(1,-40,0,18), TextXAlignment=Enum.TextXAlignment.Left, Parent=aboutCard
        })
        Utils.Create("TextLabel", {
            Text="Build 2026.02.21 · Made by Claude (Anthropic)",
            Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
            TextColor3=Theme.Colors.TextLow, BackgroundTransparency=1,
            Size=UDim2.new(1,-40,0,12), Position=UDim2.new(0,0,0,20),
            TextXAlignment=Enum.TextXAlignment.Left, Parent=aboutCard
        })
        Utils.Create("TextLabel", {
            Text="ColorPicker · SaveManager · Dialogs · MultiDropdown · ResizeHandle · Temas · Locked Components · v4 Complete",
            Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextXS,
            TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,36),
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, Parent=aboutCard
        })
        Utils.Create("TextLabel", {
            Text="◈", Font=Theme.Fonts.Bold, TextSize=24,
            TextColor3=Theme.Colors.Accent, BackgroundTransparency=1,
            BackgroundTransparency=1, Size=UDim2.new(0,30,0,30),
            AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0),
            Parent=aboutCard
        })
        Theme:Bind(aboutCard:FindFirstChild("TextLabel"), {TextColor3="Accent"})

        -- ================================================================
        --  STATUS BAR (matches .statusbar)
        -- ================================================================
        self.StatusBar = Utils.Create("Frame", {
            Name="StatusBar", Size=UDim2.new(1,0,0,32),
            Position=UDim2.new(0,0,1,-26),
            BackgroundColor3=Theme.Colors.Black, BackgroundTransparency=0.80,
            BorderSizePixel=0, Parent=self.Window
        })
        Utils.Stroke(self.StatusBar, Theme.Colors.Border, 1, Theme.Trans.Border)
        Utils.Padding(self.StatusBar, 14, 0)

        local sbLL = Utils.Create("UIListLayout", {
            FillDirection=Enum.FillDirection.Horizontal,
            VerticalAlignment=Enum.VerticalAlignment.Center,
            Padding=UDim.new(0,14), Parent=self.StatusBar
        })

        local function statusItem(dotColor, text)
            local wrap = Utils.Create("Frame", {
                Size=UDim2.new(0,0,1,0), BackgroundTransparency=1,
                AutomaticSize=Enum.AutomaticSize.X, Parent=self.StatusBar
            })
            local dot = Utils.Create("Frame", {
                Size=UDim2.new(0,6,0,6), Position=UDim2.new(0,0,0.5,-3),
                BackgroundColor3=dotColor, BorderSizePixel=0, Parent=wrap
            })
            Utils.Corner(dot, UDim.new(1,0))
            local lbl = Utils.Create("TextLabel", {
                Text=text, Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
                TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
                Size=UDim2.new(0,0,1,0), Position=UDim2.new(0,10,0,0),
                AutomaticSize=Enum.AutomaticSize.X,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=wrap
            })
            Theme:Bind(lbl, {TextColor3="TextMuted"})
            return lbl, dot
        end

        statusItem(Theme.Colors.Success, "Conectado")
        local pingLbl, _ = statusItem(Theme.Colors.Warning, "Ping: 42ms")
        local saveLbl    = Utils.Create("TextLabel", {
            Text="● Salvo", Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
            TextColor3=Theme.Colors.Success, BackgroundTransparency=1,
            Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
            Parent=self.StatusBar
        })
        Theme:Bind(saveLbl, {TextColor3="Success"})

        local verLbl = Utils.Create("TextLabel", {
            Text="Claude UI v4.0 · Anthropic · 00:00",
            Font=Theme.Fonts.Mono, TextSize=Theme.Sizes.TextXS,
            TextColor3=Theme.Colors.TextMuted, BackgroundTransparency=1,
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-14,0.5,0),
            Size=UDim2.new(0,0,0,10), AutomaticSize=Enum.AutomaticSize.X,
            Parent=self.StatusBar
        })
        Theme:Bind(verLbl, {TextColor3="TextMuted"})

        -- ================================================================
        --  RESIZE HANDLE (matches .resize-handle)
        -- ================================================================
        self.ResizeHandle = Utils.Create("TextButton", {
            Name="ResizeHandle", Text="⊿",
            Font=Theme.Fonts.Main, TextSize=10,
            TextColor3=Theme.Colors.Accent, BackgroundTransparency=1,
            Size=UDim2.new(0,22,0,22),
            AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-6,1,-6),
            Parent=self.Window
        })
        Theme:Bind(self.ResizeHandle, {TextColor3="Accent"})
        self.ResizeHandle.MouseEnter:Connect(function()
            TweenController:Play(self.ResizeHandle, TweenController.Smooth, {TextTransparency=0})
        end)
        self.ResizeHandle.MouseLeave:Connect(function()
            TweenController:Play(self.ResizeHandle, TweenController.Smooth, {TextTransparency=0.35})
        end)
        self.ResizeHandle.TextTransparency = 0.35

        -- Enable drag and resize
        Draggable.Enable(self.Window, self.TitleBar)
        Resizable.Enable(self.Window, self.ResizeHandle, self.MinSize)

        self:SwitchTab("home")

        -- Notify proxy
        self.Notify = function(cfg)
            if self.Notification then self.Notification.New(cfg) end
        end

        -- ================================================================
        --  TICK: clock, uptime, ping
        -- ================================================================
        local startClock = os.clock()
        task.spawn(function()
            while not self.Destroyed do
                local ok, err = pcall(function()
                    local now  = os.date("*t")
                    local hour = now.hour
                    clockT.Text = pad2(hour)..":"..pad2(now.min)..":"..pad2(now.sec)
                    clockD.Text = pad2(now.day).."/"..pad2(now.month).."/"..tostring(now.year)
                    local g = hour<6 and "Vai dormir," or hour<12 and "Bom dia," or hour<18 and "Boa tarde," or "Boa noite,"
                    wTxt.Text = g.." ClaudeUser!"
                    uptimeVal.Text = formatUptime(math.floor(os.clock()-startClock))
                    local ping = 38 + math.floor(math.sin(os.clock())*8)
                    pingVal.Text  = tostring(ping).."ms"
                    pingLbl.Text  = "Ping: "..tostring(ping).."ms"
                    verLbl.Text   = "Claude UI v4.0 · Anthropic · "..pad2(hour)..":"..pad2(now.min)
                end)
                task.wait(1)
            end
        end)

        return self
    end

    -- ====================================================================
    --  SwitchTab
    -- ====================================================================
    function Window:SwitchTab(id)
        if not self.Panels[id] then return end
        self.State.ActiveTab:Set(id)

        for key, panel in pairs(self.Panels) do
            panel.Visible = key == id
        end
        for key, data in pairs(self.TabButtons) do
            if data.Locked then continue end
            local active = key == id
            if active then
                TweenController:Play(data.Button, TweenController.Smooth, {BackgroundTransparency = Theme.Trans.SurfaceHover})
                TweenController:Play(data.Label,  TweenController.Smooth, {TextColor3 = Theme.Colors.TextHigh})
                TweenController:Play(data.Icon,   TweenController.Smooth, {TextColor3 = Theme.Colors.Accent})
                data.Marker.Visible = true
                TweenController:Play(data.Marker, TweenController.Spring, {Size = UDim2.new(0,3,0.55,0)})
            else
                TweenController:Play(data.Button, TweenController.Smooth, {BackgroundTransparency = 1})
                TweenController:Play(data.Label,  TweenController.Smooth, {TextColor3 = Theme.Colors.TextLow})
                TweenController:Play(data.Icon,   TweenController.Smooth, {TextColor3 = Theme.Colors.TextMuted})
                TweenController:Play(data.Marker, TweenController.Smooth, {Size = UDim2.new(0,3,0,0)})
                task.delay(0.2, function()
                    if self.State.ActiveTab:Get() ~= key and data.Marker then
                        data.Marker.Visible = false
                    end
                end)
            end
        end
    end

    -- ====================================================================
    --  ShowDialog  (matches HTML dialog overlay)
    -- ====================================================================
    local DIALOG_DEFS = {
        confirm   = {title="Confirmar Ação",         msg="Você tem certeza que deseja realizar esta ação?",    btns={{l="Cancelar"},{l="Confirmar",v="primary"}}},
        danger    = {title="Ação Perigosa",           msg="Esta operação irá fechar a UI. Deseja continuar?",   btns={{l="Cancelar"},{l="Fechar UI",v="danger"}}},
        info      = {title="Informação",              msg="O script está na versão 4.0. Visite o Discord.",     btns={{l="Entendido",v="primary"}}},
        choices   = {title="Escolha uma opção",       msg="Como você deseja prosseguir com esta configuração?", btns={{l="Opção 1"},{l="Opção 2"},{l="Opção 3",v="primary"}}},
        teleport  = {title="Teletransporte",          msg="Escolha o destino do teletransporte.",               btns={{l="Cancelar"},{l="Spawn"},{l="Waypoint",v="primary"}}},
        resetAll  = {title="Resetar Configurações",   msg="Todas as configurações serão resetadas para o padrão.", btns={{l="Cancelar"},{l="Resetar Tudo",v="danger"}}},
    }

    function Window:ShowDialog(kind)
        -- Build dialog overlay lazily
        if not self.DialogOverlay then
            self.DialogOverlay = Utils.Create("Frame", {
                Name="DialogOverlay", Size=UDim2.new(1,0,1,0),
                BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.35,
                Visible=false, ZIndex=100, Parent=self.Backdrop
            })
            -- Close on backdrop click
            local overlayBtn = Utils.Create("TextButton", {
                Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
                Parent=self.DialogOverlay, ZIndex=100
            })
            Registry.RegisterConnection(self, overlayBtn.MouseButton1Click:Connect(function()
                self.DialogOverlay.Visible = false
            end))

            local card = Utils.Create("Frame", {
                Name="Card", Size=UDim2.new(0,360,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                Position=UDim2.new(0.5,-180,0.5,-100),
                BackgroundColor3=Theme.Colors.Background,
                BackgroundTransparency=0.02, ZIndex=101, Parent=self.DialogOverlay
            })
            Utils.Corner(card, Theme.Sizes.RadiusLarge)
            Utils.Stroke(card, Theme.Colors.Border, 1, Theme.Trans.BorderMid)
            Theme:Bind(card, {BackgroundColor3="Background"})
            Utils.Padding(card, 22)

            -- Block overlay clicks from hitting the backdrop button
            Utils.Create("TextButton", {
                Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
                ZIndex=101, Parent=card
            })

            -- Icon box
            self.DlgIconBox = Utils.Create("Frame", {
                Name="IconBox", Size=UDim2.new(0,40,0,40),
                BackgroundColor3=Theme.Colors.Warning, BackgroundTransparency=0.85,
                ZIndex=102, Parent=card
            })
            Utils.Corner(self.DlgIconBox, Theme.Sizes.RadiusMedium)
            self.DlgIcon = Utils.Create("TextLabel", {
                Text="!", Font=Theme.Fonts.Bold, TextSize=20,
                TextColor3=Theme.Colors.Warning, BackgroundTransparency=1,
                Size=UDim2.new(1,0,1,0), ZIndex=103, Parent=self.DlgIconBox
            })

            self.DlgTitle = Utils.Create("TextLabel", {
                Name="Title", Text="Dialog",
                Font=Theme.Fonts.Bold, TextSize=Theme.Sizes.TextHeader,
                TextColor3=Theme.Colors.TextHigh, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,22), Position=UDim2.new(0,0,0,50),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=102, Parent=card
            })
            Theme:Bind(self.DlgTitle, {TextColor3="TextHigh"})

            self.DlgMsg = Utils.Create("TextLabel", {
                Name="Msg", Text="",
                Font=Theme.Fonts.Main, TextSize=Theme.Sizes.TextSmall,
                TextColor3=Theme.Colors.TextLow, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,40), Position=UDim2.new(0,0,0,80),
                TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
                ZIndex=102, Parent=card
            })
            Theme:Bind(self.DlgMsg, {TextColor3="TextLow"})

            self.DlgBtns = Utils.Create("Frame", {
                Name="Buttons", Size=UDim2.new(1,0,0,40),
                Position=UDim2.new(0,0,0,130),
                BackgroundTransparency=1, ZIndex=102, Parent=card
            })
            Utils.Create("UIListLayout", {
                FillDirection=Enum.FillDirection.Horizontal,
                HorizontalAlignment=Enum.HorizontalAlignment.Right,
                VerticalAlignment=Enum.VerticalAlignment.Center,
                Padding=UDim.new(0,8), Parent=self.DlgBtns
            })
        end

        local def = DIALOG_DEFS[kind]
        if not def then def = DIALOG_DEFS.info end

        self.DlgTitle.Text = def.title
        self.DlgMsg.Text   = def.msg

        -- Clear old buttons
        for _, c in ipairs(self.DlgBtns:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end

        for _, btnDef in ipairs(def.btns) do
            local b = Components.Button.new(self.DlgBtns, {
                Text    = btnDef.l,
                Variant = btnDef.v,
                Width   = UDim2.new(0,90,0,36),
                Callback= function()
                    self.DialogOverlay.Visible = false
                    if kind == "danger" and btnDef.v == "danger" then
                        self:Destroy()
                    elseif kind == "teleport" and btnDef.l ~= "Cancelar" then
                        if self.Notify then self.Notify({Text="Teletransportando para "..btnDef.l.."!", Type="success"}) end
                    elseif kind == "resetAll" and btnDef.v == "danger" then
                        Theme:SetTheme("default")
                        if self.Notify then self.Notify({Text="Configurações resetadas!", Type="success"}) end
                    else
                        if self.Notify and btnDef.l ~= "Cancelar" then
                            self.Notify({Text="Dialog: "..btnDef.l, Type="info"})
                        end
                    end
                end
            })
            Registry.Register(b, self)
        end

        self.DialogOverlay.Visible = true
    end

    -- ====================================================================
    --  Window controls
    -- ====================================================================
    function Window:ToggleMinimize()
        if self.Minimized then
            self.Minimized = false
            if self.LastSize then self.Window.Size = self.LastSize end
            self.Body.Visible       = true
            self.StatusBar.Visible  = true
            self.ResizeHandle.Visible=true
        else
            self.Minimized = true
            self.LastSize  = self.Window.Size
            self.Body.Visible       = false
            self.StatusBar.Visible  = false
            self.ResizeHandle.Visible=false
            TweenController:Play(self.Window, TweenController.Smooth,
                {Size = UDim2.new(self.Window.Size.X.Scale, self.Window.Size.X.Offset, 0, 50)})
        end
    end

    function Window:ToggleMaximize()
        if self.Maximized then
            self.Maximized = false
            if self.LastSize then self.Window.Size = self.LastSize end
            if self.LastPos  then self.Window.Position = self.LastPos end
        else
            self.Maximized = true
            self.LastSize  = self.Window.Size
            self.LastPos   = self.Window.Position
            TweenController:Play(self.Window, TweenController.Smooth,
                {Size=UDim2.new(1,-40,1,-40), Position=UDim2.new(0,20,0,20)})
        end
    end

    function Window:Init(notificationModule)
        self.Notification = notificationModule
        if self.Notification then
            self.Notification.Init(self.Gui)
        end
    end

    function Window:Mount()
        if self.Window then self.Window.Visible = true end
    end

    function Window:Destroy()
        if self.Destroyed then return end
        self.Destroyed = true
        if self.Window then
            TweenController:Play(self.Window, TweenController.Smooth,
                {BackgroundTransparency=1, Size=UDim2.new(
                    self.Window.Size.X.Scale, self.Window.Size.X.Offset,
                    0, 0)})
            task.delay(0.3, function()
                if self.Window and self.Window.Parent then self.Window:Destroy() end
            end)
        end
        Registry.CleanupWindow(self)
    end

    return Window
end
