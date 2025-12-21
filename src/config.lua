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

-- Color Themes
Config.THEMES = {
    DARK = {
        name = "Dark",
        BACKGROUND = "232221",
        BLACKISH = "282c34",
        TRAIL = "189cf8",
        WHITE = "f3f0e0",
        UI_TEXT = "ffffff",
        UI_PANEL = "1a1a1a",
        UI_PANEL_BORDER = "444444",
        TIMELINE_BG = "333333",
        TIMELINE_PROGRESS = "4a9eff",
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
    },
    LIGHT = {
        name = "Light",
        BACKGROUND = "e8e8e8",
        BLACKISH = "cccccc",
        TRAIL = "0066cc",
        WHITE = "333333",
        UI_TEXT = "222222",
        UI_PANEL = "f0f0f0",
        UI_PANEL_BORDER = "aaaaaa",
        TIMELINE_BG = "cccccc",
        TIMELINE_PROGRESS = "0066cc",
        TRACKS = {
            "e63946",
            "1d3557",
            "f4a261",
            "2a9d8f",
            "264653",
            "e9c46a",
            "9b2226",
            "6a4c93",
            "606c38",
            "bc6c25"
        }
    }
}

-- Current active theme (default to dark)
Config.COLORS = Config.THEMES.DARK

-- Boid settings (can be adjusted via control panel)
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
    CONTROLS_MARGIN_BOTTOM = 25,
    PANEL_WIDTH = 280,
    PANEL_PADDING = 15,
    SLIDER_HEIGHT = 20,
    SLIDER_KNOB_SIZE = 12,
    TIMELINE_HEIGHT = 30,
    TIMELINE_Y = 680
}

-- Playback settings
Config.PLAYBACK = {
    SPEEDS = {0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0},
    DEFAULT_SPEED_INDEX = 4,  -- 1.0x
    SEEK_AMOUNT = 5  -- seconds to seek with arrow keys
}

-- Visualization modes
Config.VIS_MODES = {
    "boids",
    "particles",
    "waveform"
}

return Config
