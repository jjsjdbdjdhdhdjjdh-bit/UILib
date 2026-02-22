local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
    local self = setmetatable({}, EventBus)
    self._connections = {}
    self._destroyed = false
    return self
end

function EventBus:Connect(callback)
    if self._destroyed then
        return {Disconnect = function() end, Connected = false}
    end
    local connection = {
        Callback = callback,
        Connected = true,
        Disconnect = function(self)
            self.Connected = false
        end
    }
    table.insert(self._connections, connection)
    return connection
end

function EventBus:Fire(...)
    if self._destroyed then
        return
    end
    for i = #self._connections, 1, -1 do
        local conn = self._connections[i]
        if conn.Connected then
            task.spawn(conn.Callback, ...)
        else
            table.remove(self._connections, i)
        end
    end
end

function EventBus:DisconnectAll()
    for _, conn in ipairs(self._connections) do
        conn.Connected = false
    end
    self._connections = {}
end

function EventBus:Destroy()
    self._destroyed = true
    self:DisconnectAll()
end

return EventBus
