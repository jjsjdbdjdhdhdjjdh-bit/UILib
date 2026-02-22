local Container = {}

function Container.new(parent, padding, direction)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, padding or 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirection = direction or Enum.FillDirection.Vertical
    layout.Parent = parent
    return layout
end

function Container.Grid(parent, cellSize, padding)
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = cellSize or UDim2.new(0, 100, 0, 100)
    layout.CellPadding = padding or UDim2.new(0, 5, 0, 5)
    layout.Parent = parent
    return layout
end

return Container
