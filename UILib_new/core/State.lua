local State = {}
State.__index = State

function State.new(initialValue)
    local self = setmetatable({}, State)
    self._value = initialValue
    self._listeners = {}
    self._destroyed = false
    return self
end

function State:Get()
    return self._value
end

function State:Set(value)
    if self._destroyed then
        return
    end
    if self._value == value then
        return
    end
    self._value = value
    for _, listener in ipairs(self._listeners) do
        task.spawn(listener, value)
    end
end

function State:OnChange(callback, fireNow)
    if self._destroyed then
        return function() end
    end
    table.insert(self._listeners, callback)
    if fireNow ~= false then
        callback(self._value)
    end
    return function()
        for i, listener in ipairs(self._listeners) do
            if listener == callback then
                table.remove(self._listeners, i)
                break
            end
        end
    end
end

function State:Destroy()
    self._destroyed = true
    self._listeners = {}
end

return State
