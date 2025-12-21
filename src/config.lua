--[[
    Configuration Module
    Contains all constants and settings for the visualizer
]]

local Config = {}

-- Window settings
Config.WINDOW = {
    WIDTH = 1280,
    HEIGHT = 720,
    TITLE = "Love2d Midi Visualizer"
}

-- Colors (in hex format, converted to RGB)
Config.COLORS = {
    BACKGROUND = "232221",
    BLACKISH = "282c34",
    TRAIL = "189cf8",
    WHITE = "f3f0e0",
    -- Colors for each track's boids
    TRACKS = {
        "fb606a",
        "15A7EB",
        "ff753f",
        "189cf8",
        "16F547",
        "ffe23f",
        "cc5d32",
        "D36FF7",
        "CCED82",
        "BA5B4A"
    }
}

-- Boid settings
Config.BOID = {
    MAX_FORCE = 0.2,
    MAX_SPEED = 4,
    PERCEPTION_RADIUS_ALIGN = 100,
    PERCEPTION_RADIUS_COHESION = 150,
    PERCEPTION_RADIUS_SEPARATION = 150,
    SIZE = 3,
    SPAWN_Y = 500
}

-- Font settings
Config.FONTS = {
    DEFAULT_PATH = "fonts/MontserratBoldItalic.ttf",
    DEFAULT_SIZE = 12
}

-- UI settings
Config.UI = {
    CONTROLS_MARGIN_RIGHT = 10,
    CONTROLS_MARGIN_BOTTOM = 25
}

return Config
