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

-- Persistent trails storage (trails that remain after boids are deleted)
local persistentTrails = {}

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

--- Add a trail to persistent storage when a boid is deleted
-- @param trail table The trail points array {x1, y1, x2, y2, ...}
-- @param trackIndex number The track index for coloring
function Renderer.addPersistentTrail(trail, trackIndex)
    if #trail >= 4 then  -- Need at least 2 points
        table.insert(persistentTrails, {
            points = trail,
            trackIndex = trackIndex,
            createdAt = love.timer.getTime(),
            persistTime = Config.TRAIL.PERSIST_TIME
        })
    end
end

--- Update persistent trails (remove expired ones)
-- @param dt number Delta time
function Renderer.updatePersistentTrails(dt)
    local currentTime = love.timer.getTime()
    
    -- Remove expired trails
    for i = #persistentTrails, 1, -1 do
        local trail = persistentTrails[i]
        if currentTime - trail.createdAt > trail.persistTime then
            table.remove(persistentTrails, i)
        end
    end
end

--- Clear all persistent trails
function Renderer.clearPersistentTrails()
    persistentTrails = {}
end

--- Draw a beautiful trail with gradient and glow
-- @param points table Trail points {x1, y1, x2, y2, ...}
-- @param trackColor Color The color for the trail
-- @param alpha number Base alpha value (0-1)
local function drawBeautifulTrail(points, trackColor, alpha)
    if #points < 4 then return end
    
    local numPoints = #points / 2
    local trailConfig = Config.TRAIL
    
    -- Enable smooth lines if configured
    if trailConfig.SMOOTH_LINES then
        love.graphics.setLineStyle("smooth")
    end
    
    -- Draw glow layer first (if enabled)
    if trailConfig.GLOW_ENABLED then
        love.graphics.setLineWidth(trailConfig.MAX_WIDTH * trailConfig.GLOW_SIZE)
        if trackColor then
            trackColor:Set(alpha * 0.2)
        else
            love.graphics.setColor(1, 1, 1, alpha * 0.2)
        end
        love.graphics.line(points)
    end
    
    -- Draw trail segments with varying width and alpha (for gradient effect)
    local segmentSize = math.max(1, math.floor(numPoints / 10))  -- Divide into ~10 segments
    
    for segmentStart = 1, numPoints - 1, segmentSize do
        local segmentEnd = math.min(segmentStart + segmentSize, numPoints - 1)
        
        -- Calculate progress (0 = start/oldest, 1 = end/newest)
        local progress = segmentStart / numPoints
        
        -- Width tapers from MAX_WIDTH at newest to MIN_WIDTH at oldest
        local width = trailConfig.MIN_WIDTH + (trailConfig.MAX_WIDTH - trailConfig.MIN_WIDTH) * progress
        love.graphics.setLineWidth(width)
        
        -- Alpha also fades along the trail
        local segmentAlpha = alpha * (0.3 + 0.7 * progress)
        
        if trackColor then
            trackColor:Set(segmentAlpha)
        else
            love.graphics.setColor(1, 1, 1, segmentAlpha)
        end
        
        -- Extract segment points
        local segmentPoints = {}
        for i = segmentStart, segmentEnd + 1 do
            local px = points[(i - 1) * 2 + 1]
            local py = points[(i - 1) * 2 + 2]
            if px and py then
                table.insert(segmentPoints, px)
                table.insert(segmentPoints, py)
            end
        end
        
        if #segmentPoints >= 4 then
            love.graphics.line(segmentPoints)
        end
    end
    
    -- Reset line width
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
end

--- Draw all persistent trails
local function drawPersistentTrails()
    local currentTime = love.timer.getTime()
    
    for _, trail in ipairs(persistentTrails) do
        local age = currentTime - trail.createdAt
        local lifeRatio = 1 - (age / trail.persistTime)  -- 1 = just created, 0 = about to expire
        
        local alpha = Config.TRAIL.FADE_START_ALPHA * lifeRatio
        local trackColor = colors.tracks[trail.trackIndex]
        
        drawBeautifulTrail(trail.points, trackColor, alpha)
    end
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
    
    -- Draw persistent trails first (background layer)
    drawPersistentTrails()
    
    for trackIndex, flock in ipairs(flocks) do
        if not mutedTracks[trackIndex] then
            local trackColor = colors.tracks[trackIndex]
            
            for _, boid in ipairs(flock) do
                numBoids = numBoids + 1
                
                -- Draw beautiful trail
                if #boid.trail >= 4 then
                    drawBeautifulTrail(boid.trail, trackColor, Config.TRAIL.FADE_START_ALPHA)
                end
                
                -- Draw boid body with glow
                if trackColor then
                    -- Glow
                    trackColor:Set(0.3)
                    love.graphics.circle("fill", boid.position.x, boid.position.y, Config.BOID.SIZE * 2)
                    -- Core
                    trackColor:Set(1)
                end
                love.graphics.circle("fill", boid.position.x, boid.position.y, Config.BOID.SIZE)
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
    
    -- Draw persistent trails first
    drawPersistentTrails()
    
    for trackIndex, flock in ipairs(flocks) do
        if not mutedTracks[trackIndex] then
            local trackColor = colors.tracks[trackIndex]
            
            for _, boid in ipairs(flock) do
                numParticles = numParticles + 1
                
                -- Draw trail with gradient
                if #boid.trail >= 4 then
                    drawBeautifulTrail(boid.trail, trackColor, 0.5)
                end
                
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
    
    -- Draw persistent trails first
    drawPersistentTrails()
    
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
                    drawBeautifulTrail(boid.trail, trackColor, 0.5)
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
