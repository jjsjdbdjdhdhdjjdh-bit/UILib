-- ================================================================
--  Claude UI v4 — Usage Example
--  Demonstrates every feature available in UILib
-- ================================================================

local UILib = require(script.Parent) -- or: loadstring(game:HttpGet(REPO_URL.."init.lua"))()

-- Create Window (automatically builds all tabs and panels)
local win = UILib.Window.new({
    Title   = "Claude UI",
    Version = "v4.0.0",
    Size    = UDim2.new(0, 860, 0, 580),
    Parent  = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
})

-- Initialize Notification system
win:Init(UILib.Notification)

-- Mount (show) the window
win:Mount()

-- ----------------------------------------------------------------
-- Access panels directly via win.Panels["panelName"]
-- ----------------------------------------------------------------

-- ----------------------------------------------------------------
-- Show a dialog programmatically:
--   "confirm" | "danger" | "info" | "choices" | "teleport" | "resetAll"
-- ----------------------------------------------------------------
-- win:ShowDialog("confirm")

-- ----------------------------------------------------------------
-- Show a toast notification:
-- ----------------------------------------------------------------
-- win.Notify({ Text = "Hello!", Type = "success" })
-- win.Notify({ Text = "Warning!", Type = "warning", Duration = 5 })

-- ----------------------------------------------------------------
-- Switch tabs programmatically:
-- ----------------------------------------------------------------
-- win:SwitchTab("settings")

-- ----------------------------------------------------------------
-- Change theme programmatically:
--   "default" | "light" | "neon" | "rose" | "blue"
-- ----------------------------------------------------------------
-- UILib.Theme:SetTheme("neon")

-- ----------------------------------------------------------------
-- Set custom accent color:
-- ----------------------------------------------------------------
-- UILib.Theme:SetCustomAccent("#ff6699")

-- ----------------------------------------------------------------
-- Standalone components (when building custom panels):
-- ----------------------------------------------------------------
-- local myPanel = win.Panels["misc"]  -- any existing panel

-- local btn = UILib.Components.Button.new(myPanel, {
--     Text     = "My Button",
--     Variant  = "primary",   -- "default" | "primary" | "danger"
--     Callback = function()
--         win.Notify({ Text = "Button clicked!", Type = "success" })
--     end
-- })

-- local tgl = UILib.Components.Toggle.new(myPanel, {
--     Text     = "My Toggle",
--     Icon     = "◈",
--     State    = false,
--     Callback = function(state)
--         print("Toggle:", state)
--     end
-- })

-- local sld = UILib.Components.Slider.new(myPanel, {
--     Text     = "My Slider",
--     Min      = 0,
--     Max      = 100,
--     Default  = 50,
--     Suffix   = "%",
--     Callback = function(value)
--         print("Slider:", value)
--     end
-- })

-- local drp = UILib.Components.Dropdown.new(myPanel, {
--     Text        = "My Dropdown",
--     Items       = { "Option A", "Option B", "Option C" },
--     MultiSelect = false,
--     Default     = "Option A",
--     Callback    = function(selected)
--         print("Selected:", selected)
--     end
-- })

-- local inp = UILib.Components.Input.new(myPanel, {
--     Icon        = "⌘",
--     Placeholder = "Enter value...",
--     Callback    = function(text)
--         print("Input:", text)
--     end
-- })
