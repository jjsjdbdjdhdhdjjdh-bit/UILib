local TweenService = game:GetService("TweenService")
local TweenController = {}

-- Matches HTML CSS easings as closely as Roblox allows
TweenController.Spring  = TweenInfo.new(0.40, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
TweenController.Smooth  = TweenInfo.new(0.20, Enum.EasingStyle.Sine,  Enum.EasingDirection.Out)
TweenController.Out     = TweenInfo.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
TweenController.Fast    = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
TweenController.Bounce  = TweenInfo.new(0.35, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
TweenController.Linear  = TweenInfo.new(1.00, Enum.EasingStyle.Linear)
TweenController.Slow    = TweenInfo.new(0.50, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut)

function TweenController:Play(instance, info, props)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

function TweenController:FadeIn(instance, duration)
    instance.Visible = true
    if instance:IsA("CanvasGroup") then
        instance.GroupTransparency = 1
        self:Play(instance, TweenInfo.new(duration or 0.20), {GroupTransparency = 0})
    end
end

function TweenController:FadeOut(instance, duration)
    local t
    if instance:IsA("CanvasGroup") then
        t = self:Play(instance, TweenInfo.new(duration or 0.20), {GroupTransparency = 1})
    end
    if t then
        t.Completed:Connect(function()
            instance.Visible = false
        end)
    else
        instance.Visible = false
    end
end

return TweenController
