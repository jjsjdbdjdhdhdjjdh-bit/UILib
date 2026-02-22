local Theme = {}

Theme.Fonts = {
    Main = Enum.Font.Gotham,
    Mono = Enum.Font.Code,
    Bold = Enum.Font.GothamBold
}

Theme.Sizes = {
    RadiusSmall  = UDim.new(0, 6),
    RadiusMedium = UDim.new(0, 10),
    RadiusLarge  = UDim.new(0, 16),
    RadiusXLarge = UDim.new(0, 24),
    RadiusFull   = UDim.new(1, 0),
    TextXS      = 12,
    TextSmall   = 13,
    TextNormal  = 15,
    TextMedium  = 16,
    TextLarge   = 17,
    TextTitle   = 20,
    TextHeader  = 22
}

-- Exact colors from HTML CSS variables
Theme.Defs = {
    default = {
        acc     = "#d4825a", accH = "#e09070", accL = "#c97240",
        accRgb  = {212, 130, 90},
        bg      = "#1a1714", bg2 = "#141210", bg3 = "#0f0d0b",
        surfRgb = {250, 248, 245},
        sA=0.04, sH=0.07, sB=0.10, bA=0.08, bM=0.14,
        tHigh="#f5f0e8", tMed="#c8bfb0", tLow="#7a7570", tMuted="#4a4540",
        win=0.16,
        success="#5a8f6e", warning="#c9943a", error="#c46060", info="#5a7ea8"
    },
    light = {
        acc     = "#c97240", accH = "#d4825a", accL = "#b86030",
        accRgb  = {201, 114, 64},
        bg      = "#f5f0e8", bg2 = "#ede4d4", bg3 = "#e0d5c2",
        surfRgb = {30, 25, 20},
        sA=0.04, sH=0.07, sB=0.10, bA=0.08, bM=0.16,
        tHigh="#1a1510", tMed="#4a4038", tLow="#8a8078", tMuted="#b0a898",
        win=0.08,
        success="#5a8f6e", warning="#c9943a", error="#c46060", info="#5a7ea8"
    },
    neon = {
        acc     = "#00f5a0", accH = "#30ffb8", accL = "#00c880",
        accRgb  = {0, 245, 160},
        bg      = "#060a12", bg2 = "#040810", bg3 = "#020508",
        surfRgb = {0, 245, 160},
        sA=0.04, sH=0.07, sB=0.10, bA=0.08, bM=0.15,
        tHigh="#d0ffe8", tMed="#80c0a0", tLow="#408060", tMuted="#204030",
        win=0.10,
        success="#5a8f6e", warning="#c9943a", error="#c46060", info="#5a7ea8"
    },
    rose = {
        acc     = "#e87080", accH = "#f08898", accL = "#d05868",
        accRgb  = {232, 112, 128},
        bg      = "#120a0c", bg2 = "#0e0608", bg3 = "#0a0406",
        surfRgb = {255, 220, 225},
        sA=0.04, sH=0.07, sB=0.10, bA=0.08, bM=0.14,
        tHigh="#ffe8ec", tMed="#c09098", tLow="#806068", tMuted="#503038",
        win=0.10,
        success="#5a8f6e", warning="#c9943a", error="#c46060", info="#5a7ea8"
    },
    blue = {
        acc     = "#5a90d0", accH = "#70a8e8", accL = "#4878b8",
        accRgb  = {90, 144, 208},
        bg      = "#0a0e18", bg2 = "#080c14", bg3 = "#060a10",
        surfRgb = {200, 220, 255},
        sA=0.04, sH=0.07, sB=0.10, bA=0.08, bM=0.14,
        tHigh="#e0ecff", tMed="#90a8c8", tLow="#506888", tMuted="#304058",
        win=0.10,
        success="#5a8f6e", warning="#c9943a", error="#c46060", info="#5a7ea8"
    }
}

Theme.Current   = "default"
Theme.Bindings  = {}
Theme.Colors    = {}
Theme.Trans     = {}

local function hex(h)
    h = h:gsub("#","")
    return Color3.fromRGB(tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16))
end
local function rgb(t) return Color3.fromRGB(t[1],t[2],t[3]) end
local function tr(a)  return 1-a end

function Theme:BuildPalette(name)
    local d = self.Defs[name] or self.Defs.default
    self.Colors = {
        Accent      = hex(d.acc),
        AccentHigh  = hex(d.accH),
        AccentLow   = hex(d.accL),
        AccentRgb   = d.accRgb,
        Background  = hex(d.bg),
        Background2 = hex(d.bg2),
        Background3 = hex(d.bg3),
        Surface     = rgb(d.surfRgb),
        Border      = rgb(d.surfRgb),
        TextHigh    = hex(d.tHigh),
        TextMed     = hex(d.tMed),
        TextLow     = hex(d.tLow),
        TextMuted   = hex(d.tMuted),
        Success     = hex(d.success),
        Warning     = hex(d.warning),
        Error       = hex(d.error),
        Info        = hex(d.info),
        White       = Color3.new(1,1,1),
        Black       = Color3.new(0,0,0)
    }
    self.Trans = {
        Surface       = tr(d.sA),
        SurfaceHover  = tr(d.sH),
        SurfaceActive = tr(d.sB),
        Border        = tr(d.bA),
        BorderMid     = tr(d.bM),
        WindowBg      = d.win,
        AccentGlow    = 0.82,   -- ~0.18 alpha
        AccentBorder  = 0.68,   -- ~0.32 alpha
        TitleBar      = 0.80,   -- like rgba(0,0,0,0.2)
    }
end

Theme:BuildPalette("default")

function Theme:SetTheme(name)
    self.Current = name or "default"
    self:BuildPalette(self.Current)
    for inst, map in pairs(self.Bindings) do
        if inst and inst.Parent then
            self:Apply(inst, map)
        else
            self.Bindings[inst] = nil
        end
    end
end

function Theme:SetCustomAccent(hex_)
    local c = hex(hex_)
    local r,g,b = math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)
    self.Colors.Accent     = c
    self.Colors.AccentHigh = Color3.fromRGB(math.min(255,math.floor(r*1.15)), math.min(255,math.floor(g*1.15)), math.min(255,math.floor(b*1.15)))
    self.Colors.AccentLow  = Color3.fromRGB(math.floor(r*.85), math.floor(g*.85), math.floor(b*.85))
    self.Colors.AccentRgb  = {r,g,b}
    for inst, map in pairs(self.Bindings) do
        if inst and inst.Parent then self:Apply(inst, map)
        else self.Bindings[inst] = nil end
    end
end

function Theme:Resolve(key)
    if self.Colors[key]  ~= nil then return self.Colors[key] end
    if self.Trans[key]   ~= nil then return self.Trans[key]  end
    return nil
end

function Theme:Apply(inst, map)
    for prop, key in pairs(map) do
        local val = type(key)=="function" and key() or (self:Resolve(key) ~= nil and self:Resolve(key) or key)
        inst[prop] = val
    end
end

function Theme:Bind(inst, map)
    self:Apply(inst, map)
    self.Bindings[inst] = map
    if inst.Destroying then
        inst.Destroying:Connect(function()
            self.Bindings[inst] = nil
        end)
    end
end

return Theme
