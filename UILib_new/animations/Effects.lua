local TweenService = game:GetService("TweenService")
local Effects = {}

-- Ripple effect matching HTML button active feedback
function Effects.Ripple(parent, x, y)
    local ripple = Instance.new("Frame")
    ripple.BackgroundColor3   = Color3.new(1,1,1)
    ripple.BackgroundTransparency = 0.65
    ripple.BorderSizePixel    = 0
    ripple.AnchorPoint        = Vector2.new(0.5, 0.5)
    ripple.Position           = UDim2.new(0, x or parent.AbsoluteSize.X/2, 0, y or parent.AbsoluteSize.Y/2)
    ripple.Size               = UDim2.new(0, 0, 0, 0)
    ripple.ZIndex             = (parent.ZIndex or 1) + 5
    Instance.new("UICorner", ripple).CornerRadius = UDim.new(1,0)
    ripple.Parent = parent

    local maxDim = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    TweenService:Create(ripple, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size                  = UDim2.new(0, maxDim, 0, maxDim),
        BackgroundTransparency = 1
    }):Play()

    task.delay(0.5, function()
        if ripple and ripple.Parent then ripple:Destroy() end
    end)
end

-- Soft glow image on an element (for spotlight effects)
function Effects.Glow(parent, color, transparency)
    local g = Instance.new("ImageLabel")
    g.BackgroundTransparency = 1
    g.Image            = "rbxassetid://5028857472"
    g.ImageColor3      = color or Color3.new(1,1,1)
    g.ImageTransparency = transparency or 0.5
    g.Size             = UDim2.new(1, 60, 1, 60)
    g.Position         = UDim2.new(0, -30, 0, -30)
    g.ZIndex           = 0
    g.Parent           = parent
    return g
end

-- Pulse animation (for status dots like in HTML `@keyframes pulse`)
function Effects.Pulse(frame)
    local originalTrans = frame.BackgroundTransparency
    local function doPulse()
        TweenService:Create(frame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = originalTrans + 0.5
        }):Play()
        task.wait(1)
        TweenService:Create(frame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = originalTrans
        }):Play()
        task.wait(1)
    end
    task.spawn(function()
        while frame and frame.Parent do
            doPulse()
        end
    end)
end

return Effects
