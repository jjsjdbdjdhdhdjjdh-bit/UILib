local UILib = {}

-- [[ Services ]]
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")

-- [[ Base URL (GitHub raw) ]]
local REPO_URL = "https://raw.githubusercontent.com/jjsjdbdjdhdhdjjdh-bit/UILib/main/"

-- [[ Module Cache ]]
local Cache = {}

-- ======================================================================
--  Import: load from local child first, then remote URL
-- ======================================================================
local function Import(path)
    if Cache[path] then return Cache[path] end

    -- Try local child
    local function findLocal(current, parts)
        for _, name in ipairs(parts) do
            current = current:FindFirstChild(name)
            if not current then return nil end
        end
        return current
    end

    local parts = string.split(path, "/")
    local local_ = findLocal(script, parts)
    if local_ and local_:IsA("ModuleScript") then
        local result  = require(local_)
        Cache[path]   = result
        return result
    end

    -- Remote fallback
    local url = REPO_URL .. path .. ".lua"
    local ok, content

    if request then
        local resp = request({Url=url, Method="GET"})
        if resp.Success and resp.StatusCode == 200 then
            content = resp.Body; ok = true
        end
    end
    if not ok then
        local s, r = pcall(function() return game:HttpGet(url) end)
        if s then content = r; ok = true end
    end

    if ok and content then
        local fn, err = loadstring(content)
        if fn then
            local result = fn()
            Cache[path]  = result
            return result
        else
            warn("[UILib] Compile error in "..path..": "..tostring(err))
        end
    else
        warn("[UILib] Failed to load module: "..path)
    end
    return nil
end

-- ======================================================================
--  Load modules in dependency order
-- ======================================================================

-- 1. Core
local Theme          = Import("core/Theme")
local Utils          = Import("core/Utils")
local State          = Import("core/State")
local EventBus       = Import("core/EventBus")
local Registry       = Import("core/Registry")

-- 2. Animations
local TweenController = Import("animations/TweenController")
local Effects         = Import("animations/Effects")

-- 3. Layout
local Draggable       = Import("layout/Draggable")
local Resizable       = Import("layout/Resizable")

-- 4. Component factories
local WindowFactory       = Import("components/Window")
local ButtonFactory       = Import("components/Button")
local ToggleFactory       = Import("components/Toggle")
local SliderFactory       = Import("components/Slider")
local DropdownFactory     = Import("components/Dropdown")
local InputFactory        = Import("components/Input")
local TabsFactory         = Import("components/Tabs")
local NotificationFactory = Import("components/Notification")

-- ======================================================================
--  Initialize component classes (inject dependencies)
-- ======================================================================
local Components = {
    Button    = ButtonFactory(Theme, Utils, Effects, TweenController),
    Toggle    = ToggleFactory(Theme, Utils, Effects, TweenController),
    Slider    = SliderFactory(Theme, Utils, TweenController),
    Dropdown  = DropdownFactory(Theme, Utils, TweenController, Effects),
    Input     = InputFactory(Theme, Utils, TweenController),
    Tabs      = TabsFactory(Theme, Utils, TweenController),
}

-- Window class (depends on all others)
local Window = WindowFactory(
    Theme, Utils, Draggable, Resizable,
    TweenController, State, EventBus, Registry,
    Components
)

-- Notification (standalone module)
local Notification = NotificationFactory(Theme, Utils, TweenController)

-- ======================================================================
--  Convenience methods added to Window (addon API)
-- ======================================================================
function Window:AddButton(config)
    return Components.Button.new(self.Content, config)
end
function Window:AddToggle(config)
    return Components.Toggle.new(self.Content, config)
end
function Window:AddSlider(config)
    return Components.Slider.new(self.Content, config)
end
function Window:AddDropdown(config)
    return Components.Dropdown.new(self.Content, config)
end
function Window:AddInput(config)
    return Components.Input.new(self.Content, config)
end
function Window:AddTabs(config)
    return Components.Tabs.new(self.Content, config)
end

-- ======================================================================
--  Public API
-- ======================================================================
UILib.Window       = Window
UILib.Notification = Notification
UILib.Theme        = Theme
UILib.Components   = Components
UILib.Utils        = Utils

return UILib
