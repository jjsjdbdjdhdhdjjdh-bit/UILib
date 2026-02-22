local UserInputService = game:GetService("UserInputService")
local Draggable = {}

function Draggable.Enable(frame, dragHandle, options)
    local dragging = false
    local dragInput, dragStart, startPos
    options = options or {}
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    local function isIgnored(pos)
        if not options.Ignore or #options.Ignore == 0 then
            return false
        end
        local objs = UserInputService:GetGuiObjectsAtPosition(pos.X, pos.Y)
        for _, obj in ipairs(objs) do
            for _, ign in ipairs(options.Ignore) do
                if obj == ign or obj:IsDescendantOf(ign) then
                    return true
                end
            end
        end
        return false
    end
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isIgnored(input.Position) then
                return
            end
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

return Draggable
