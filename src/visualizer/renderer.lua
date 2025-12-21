--[[
    Renderer Module
    Handles all drawing operations for the visualizer
]]

local Color = require "lib.color"
local Config = require "src.config"

local Renderer = {}

-- Pre-loaded colors (initialized in setup)
local colors = {
    background = nil,
    blackish = nil,
    white = nil,
    tracks = {}
}

--- Initialize the renderer with colors
function Renderer.setup()
    colors.background = Color(Config.COLORS.BACKGROUND)
    colors.blackish = Color(Config.COLORS.BLACKISH)
    colors.white = Color(Config.COLORS.WHITE)
    
    for i, hex in ipairs(Config.COLORS.TRACKS) do
        colors.tracks[i] = Color(hex)
    end
end

--- Ensure we have enough track colors
-- @param trackCount number Number of tracks
function Renderer.ensureTrackColors(trackCount)
    while #colors.tracks < trackCount do
        table.insert(colors.tracks, Color.Random())
    end
end

--- Get a track color
-- @param index number Track index
-- @return Color The color for the track
function Renderer.getTrackColor(index)
    return colors.tracks[index] or Color.Random()
end

--- Clear the screen with background color
function Renderer.clearBackground()
    colors.background:SetBackground()
end

--- Draw the note trigger points (white circles)
-- @param lowestMidi number Lowest MIDI note value
-- @param highestMidi number Highest MIDI note value
-- @param pixelsPerNote number Width in pixels per MIDI note
-- @param getXFromMidi function Function to convert MIDI to X position
function Renderer.drawNoteTriggers(lowestMidi, highestMidi, pixelsPerNote, getXFromMidi)
    local spawnY = Config.BOID.SPAWN_Y
    local radius = pixelsPerNote / 2
    
    for midi = lowestMidi, highestMidi do
        local x = getXFromMidi(midi)
        
        -- Draw white filled circle
        colors.white:Set()
        love.graphics.circle("fill", x, spawnY, radius)
        
        -- Draw dark outline
        colors.blackish:Set()
        love.graphics.circle("line", x, spawnY, radius)
    end
end

--- Draw currently playing notes
-- @param playingNotes table List of currently playing notes
-- @param currentTime number Current playback time
-- @param pixelsPerNote number Width in pixels per MIDI note
-- @param getXFromMidi function Function to convert MIDI to X position
function Renderer.drawPlayingNotes(playingNotes, currentTime, pixelsPerNote, getXFromMidi)
    local spawnY = Config.BOID.SPAWN_Y
    local radius = pixelsPerNote / 2
    
    for _, note in ipairs(playingNotes) do
        local alpha = (note.playedTime + note.duration - currentTime) / note.duration
        colors.blackish:Set(alpha)
        love.graphics.circle("fill", getXFromMidi(note.midi), spawnY, radius)
    end
end

--- Draw all boids from all flocks
-- @param flocks table Table of flock arrays
-- @return number Total number of boids drawn
function Renderer.drawBoids(flocks)
    local numBoids = 0
    
    for trackIndex, flock in ipairs(flocks) do
        local trackColor = colors.tracks[trackIndex]
        
        for _, boid in ipairs(flock) do
            numBoids = numBoids + 1
            
            if trackColor then
                trackColor:Set()
            else
                Color.Random():Set()
            end
            
            boid:show()
        end
    end
    
    return numBoids
end

--- Draw FPS counter
function Renderer.drawFPS()
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
end

--- Draw stats (time and boid count)
-- @param time number Current time
-- @param boidCount number Number of boids
-- @param font Font The font to use
-- @param isPaused boolean Whether the song is paused
function Renderer.drawStats(time, boidCount, font, isPaused)
    love.graphics.setFont(font)
    Color.Reset()
    
    -- Format time to 2 decimal places
    local seconds = math.floor(time)
    local milliseconds = time - seconds
    local timeStr = tostring(seconds) .. string.sub(tostring(milliseconds), 2, 4)
    
    local pauseStr = isPaused and "  [PAUSED]" or ""
    
    love.graphics.print(
        "Time: " .. timeStr .. "   Boids: " .. boidCount .. pauseStr,
        55, 5
    )
end

--- Draw waiting screen when no song is loaded
function Renderer.drawWaitingScreen()
    Color.Reset()
    
    local width = Config.WINDOW.WIDTH
    local height = Config.WINDOW.HEIGHT
    
    -- Draw centered text
    love.graphics.printf(
        "Drag and drop a JSON file to start\n\nor run: love . song.json",
        0, height / 2 - 40,
        width,
        "center"
    )
end

--- Draw control hints
-- @param isPaused boolean Whether the song is paused
function Renderer.drawControls(isPaused)
    Color.Reset()
    
    local controlText = "[Space] " .. (isPaused and "Resume" or "Pause") .. "  [R] Restart  [Esc] Quit"
    local textWidth = love.graphics.getFont():getWidth(controlText)
    
    love.graphics.print(
        controlText,
        Config.WINDOW.WIDTH - textWidth - Config.UI.CONTROLS_MARGIN_RIGHT,
        Config.WINDOW.HEIGHT - Config.UI.CONTROLS_MARGIN_BOTTOM
    )
end

return Renderer
