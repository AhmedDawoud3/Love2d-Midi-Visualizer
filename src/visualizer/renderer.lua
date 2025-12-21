--[[
    Renderer Module
    Handles all drawing operations for the visualizer
]]

local Color = require "lib.color"
local Config = require "src.config"

local Renderer = {}

-- Current visualization mode
local visMode = "boids"

-- Pre-loaded colors (initialized in setup)
local colors = {
    background = nil,
    blackish = nil,
    white = nil,
    tracks = {},
    uiText = nil
}

-- Current theme name
local currentTheme = "DARK"

--- Initialize the renderer with colors from current theme
function Renderer.setup()
    Renderer.applyTheme(currentTheme)
end

--- Apply a color theme
-- @param themeName string Theme name ("DARK" or "LIGHT")
function Renderer.applyTheme(themeName)
    local theme = Config.THEMES[themeName]
    if not theme then
        theme = Config.THEMES.DARK
        themeName = "DARK"
    end
    
    currentTheme = themeName
    Config.COLORS = theme
    
    colors.background = Color(theme.BACKGROUND)
    colors.blackish = Color(theme.BLACKISH)
    colors.white = Color(theme.WHITE)
    colors.uiText = Color(theme.UI_TEXT or "ffffff")
    
    colors.tracks = {}
    for i, hex in ipairs(theme.TRACKS) do
        colors.tracks[i] = Color(hex)
    end
end

--- Get current theme name
-- @return string Current theme name
function Renderer.getCurrentTheme()
    return currentTheme
end

--- Toggle between light and dark themes
function Renderer.toggleTheme()
    if currentTheme == "DARK" then
        Renderer.applyTheme("LIGHT")
    else
        Renderer.applyTheme("DARK")
    end
end

--- Set visualization mode
-- @param mode string Mode name ("boids", "particles", "waveform")
function Renderer.setVisMode(mode)
    visMode = mode
end

--- Get current visualization mode
-- @return string Current mode
function Renderer.getVisMode()
    return visMode
end

--- Cycle through visualization modes
function Renderer.cycleVisMode()
    local modes = Config.VIS_MODES
    for i, mode in ipairs(modes) do
        if mode == visMode then
            visMode = modes[(i % #modes) + 1]
            return
        end
    end
    visMode = modes[1]
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

--- Draw boids visualization mode
-- @param flocks table Table of flock arrays
-- @param mutedTracks table Table of muted track indices
-- @return number Total number of boids drawn
local function drawBoidsMode(flocks, mutedTracks)
    local numBoids = 0
    
    for trackIndex, flock in ipairs(flocks) do
        if not mutedTracks[trackIndex] then
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
    end
    
    return numBoids
end

--- Draw particles visualization mode
-- @param flocks table Table of flock arrays
-- @param mutedTracks table Table of muted track indices
-- @return number Total number of particles drawn
local function drawParticlesMode(flocks, mutedTracks)
    local numParticles = 0
    
    for trackIndex, flock in ipairs(flocks) do
        if not mutedTracks[trackIndex] then
            local trackColor = colors.tracks[trackIndex]
            
            for _, boid in ipairs(flock) do
                numParticles = numParticles + 1
                
                if trackColor then
                    trackColor:Set(0.8)
                else
                    Color.Random():Set(0.8)
                end
                
                -- Draw as simple particles with glow effect
                local size = Config.BOID.SIZE
                love.graphics.circle("fill", boid.position.x, boid.position.y, size * 2)
                
                if trackColor then
                    trackColor:Set(0.4)
                end
                love.graphics.circle("fill", boid.position.x, boid.position.y, size * 4)
            end
        end
    end
    
    return numParticles
end

--- Draw waveform visualization mode
-- @param flocks table Table of flock arrays
-- @param mutedTracks table Table of muted track indices
-- @param playingNotes table Currently playing notes
-- @return number Total number of items drawn
local function drawWaveformMode(flocks, mutedTracks, playingNotes)
    local numItems = 0
    local width = Config.WINDOW.WIDTH
    local height = Config.WINDOW.HEIGHT
    local centerY = height / 2
    
    -- Draw waveform bars based on playing notes
    for _, note in ipairs(playingNotes or {}) do
        if not mutedTracks[note.indexOfPlaying] then
            local trackColor = colors.tracks[note.indexOfPlaying]
            if trackColor then
                trackColor:Set(0.7)
            else
                love.graphics.setColor(1, 1, 1, 0.7)
            end
            
            -- Calculate bar properties based on MIDI note range (128 possible notes)
            local numBars = 88  -- Standard piano range
            local barWidth = width / numBars
            local barX = ((note.midi - 21) % numBars) * barWidth  -- 21 is A0 (lowest piano key)
            local barHeight = note.velocity * 200
            
            love.graphics.rectangle("fill", barX, centerY - barHeight / 2, barWidth - 2, barHeight)
            numItems = numItems + 1
        end
    end
    
    -- Also draw boid trails as waveform lines
    for trackIndex, flock in ipairs(flocks) do
        if not mutedTracks[trackIndex] then
            local trackColor = colors.tracks[trackIndex]
            
            for _, boid in ipairs(flock) do
                if #boid.trail >= 4 then
                    if trackColor then
                        trackColor:Set(0.5)
                    end
                    love.graphics.line(boid.trail)
                    numItems = numItems + 1
                end
            end
        end
    end
    
    return numItems
end

--- Draw all boids/particles based on current visualization mode
-- @param flocks table Table of flock arrays
-- @param mutedTracks table Table of muted track indices (optional)
-- @param playingNotes table Currently playing notes (optional)
-- @return number Total number of items drawn
function Renderer.drawBoids(flocks, mutedTracks, playingNotes)
    mutedTracks = mutedTracks or {}
    
    if visMode == "particles" then
        return drawParticlesMode(flocks, mutedTracks)
    elseif visMode == "waveform" then
        return drawWaveformMode(flocks, mutedTracks, playingNotes)
    else
        return drawBoidsMode(flocks, mutedTracks)
    end
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
-- @param speed number Current playback speed (optional)
function Renderer.drawStats(time, boidCount, font, isPaused, speed)
    love.graphics.setFont(font)
    colors.uiText:Set()
    
    -- Format time to 2 decimal places
    local seconds = math.floor(time)
    local milliseconds = time - seconds
    local timeStr = tostring(seconds) .. string.sub(tostring(milliseconds), 2, 4)
    
    local pauseStr = isPaused and "  [PAUSED]" or ""
    local speedStr = speed and speed ~= 1 and string.format("  [%.2fx]", speed) or ""
    
    love.graphics.print(
        "Time: " .. timeStr .. "   Boids: " .. boidCount .. pauseStr .. speedStr,
        55, 5
    )
end

--- Draw waiting screen when no song is loaded
function Renderer.drawWaitingScreen()
    colors.uiText:Set()
    
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
-- @param speed number Current playback speed
function Renderer.drawControls(isPaused, speed)
    colors.uiText:Set()
    
    local speedStr = string.format("%.2fx", speed or 1)
    local controlText = "[Space] " .. (isPaused and "Resume" or "Pause") .. 
                       "  [R] Restart  [←/→] Seek  [↑/↓] Speed: " .. speedStr ..
                       "  [V] Vis  [T] Theme  [P] Panel"
    local textWidth = love.graphics.getFont():getWidth(controlText)
    
    love.graphics.print(
        controlText,
        Config.WINDOW.WIDTH - textWidth - Config.UI.CONTROLS_MARGIN_RIGHT,
        Config.WINDOW.HEIGHT - Config.UI.CONTROLS_MARGIN_BOTTOM - 40
    )
end

--- Draw track mute indicators
-- @param trackCount number Number of tracks
-- @param mutedTracks table Table of muted track indices
function Renderer.drawTrackMutes(trackCount, mutedTracks)
    local startX = 10
    local startY = 60
    local boxSize = 15
    local spacing = 5
    
    colors.uiText:Set()
    love.graphics.print("Tracks (1-9 to mute):", startX, startY - 15)
    
    for i = 1, math.min(trackCount, 9) do
        local x = startX + (i - 1) * (boxSize + spacing)
        local y = startY
        
        -- Draw track color box
        local trackColor = colors.tracks[i]
        if trackColor then
            if mutedTracks[i] then
                trackColor:Set(0.3)
            else
                trackColor:Set()
            end
        end
        love.graphics.rectangle("fill", x, y, boxSize, boxSize)
        
        -- Draw border
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.rectangle("line", x, y, boxSize, boxSize)
        
        -- Draw X if muted
        if mutedTracks[i] then
            love.graphics.setColor(1, 0, 0, 0.8)
            love.graphics.line(x + 2, y + 2, x + boxSize - 2, y + boxSize - 2)
            love.graphics.line(x + boxSize - 2, y + 2, x + 2, y + boxSize - 2)
        end
        
        -- Draw track number
        colors.uiText:Set()
        love.graphics.print(tostring(i), x + 4, y + boxSize + 2)
    end
end

return Renderer
