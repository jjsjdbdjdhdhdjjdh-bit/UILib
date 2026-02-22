local UserInputService = game:GetService("UserInputService")
local Resizable = {}

function Resizable.Enable(frame, handle, minSize, onResize)
    local resizing = false
    local startPos, startSize
    local min = minSize or Vector2.new(100, 100)
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            startPos = input.Position
            startSize = frame.AbsoluteSize
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and resizing then
            local delta = input.Position - startPos
            local newX = math.max(min.X, startSize.X + delta.X)
            local newY = math.max(min.Y, startSize.Y + delta.Y)
            frame.Size = UDim2.new(0, newX, 0, newY)
            if onResize then
                onResize(newX, newY)
            end
        end
    end)
end

return Resizable
