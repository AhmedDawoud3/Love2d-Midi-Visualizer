--[[
    Love2D Configuration File
    This file is automatically called by Love2D before love.load()
    See: https://love2d.org/wiki/Config_Files
]]

function love.conf(t)
    -- Identity
    t.identity = "love2d-midi-visualizer"
    t.version = "11.4"

    -- Window settings
    t.window.title = "Love2d Midi Visualizer"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = false
    t.window.vsync = 1

    -- Console (for debugging on Windows)
    t.console = false

    -- Modules (disable unused modules for performance)
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = false
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
end
