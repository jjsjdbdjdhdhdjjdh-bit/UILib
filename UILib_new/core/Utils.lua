local Utils = {}

function Utils.Create(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

function Utils.Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0, 6)
    c.Parent = parent
    return c
end

function Utils.Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color       = color       or Color3.new(1,1,1)
    s.Thickness   = thickness   or 1
    s.Transparency= transparency or 0
    s.Parent = parent
    return s
end

function Utils.Padding(parent, px, py)
    local p = Instance.new("UIPadding")
    local vx = UDim.new(0, px or 0)
    local vy = UDim.new(0, py or px or 0)
    p.PaddingLeft   = vx
    p.PaddingRight  = vx
    p.PaddingTop    = vy
    p.PaddingBottom = vy
    p.Parent = parent
    return p
end

function Utils.PaddingLR(parent, h, v)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, h)
    p.PaddingRight  = UDim.new(0, h)
    p.PaddingTop    = UDim.new(0, v)
    p.PaddingBottom = UDim.new(0, v)
    p.Parent = parent
    return p
end

function Utils.Scale(parent, value)
    local s = Instance.new("UIScale")
    s.Scale = value or 1
    s.Parent = parent
    return s
end

function Utils.Gradient(parent, colors, rotation)
    local g = Instance.new("UIGradient")
    g.Color    = colors
    g.Rotation = rotation or 0
    g.Parent   = parent
    return g
end

function Utils.ListLayout(parent, direction, padding, halign, valign)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = direction or Enum.FillDirection.Vertical
    l.Padding             = UDim.new(0, padding or 0)
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = halign or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = valign or Enum.VerticalAlignment.Top
    l.Parent = parent
    return l
end

-- Auto-resize a scrolling frame to its UIListLayout content
function Utils.AutoCanvas(scrollFrame, layout, extraPad)
    local function update()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extraPad or 10))
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

return Utils
