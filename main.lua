--[[
    Love2D MIDI Visualizer
    A music visualizer that uses MIDI files to create a boid flocking animation

    Usage: love . song.json
           Or drag and drop a JSON file onto the window
    
    Controls:
        Space      - Pause/Resume
        R          - Restart song
        ←/→        - Seek backward/forward 5 seconds
        ↑/↓        - Increase/decrease playback speed
        V          - Cycle visualization mode (boids/particles/waveform)
        T          - Toggle light/dark theme
        P          - Toggle control panel
        1-9        - Toggle mute for tracks 1-9
        Escape     - Quit
    
    Author: Ahmed Dawoud
    Repository: https://github.com/AhmedDawoud3/Love2d-Midi-Visualizer
]]

-- External Libraries
local midi = require "luamidi"
local Timer = require "lib.timer"
local Vector = require "lib.vector"

-- Internal Modules
local Config = require "src.config"
local MidiParser = require "src.midi.parser"
local Boid = require "src.entities.boid"
local Renderer = require "src.visualizer.renderer"
local Panel = require "src.ui.panel"
local Timeline = require "src.ui.timeline"

-- Local state variables
local gameState = {
    time = 0,
    tracks = {},
    flocks = {},
    playingNotes = {},
    midiData = nil,
    pixelsPerNote = 0,
    defaultFont = nil,
    isPaused = false,
    isLoaded = false,
    currentFile = nil,
    playbackSpeed = 1.0,
    speedIndex = Config.PLAYBACK.DEFAULT_SPEED_INDEX,
    mutedTracks = {},
    originalTracks = nil  -- Store original track data for restart/seek
}

-- Constant to mark notes as played (prevents re-triggering)
local NOTE_PLAYED_TIME = 1e10

--- Convert MIDI note value to X screen position
-- @param midiValue number The MIDI note value
-- @return number X position on screen
local function getXFromMidi(midiValue)
    return MidiParser.getXFromMidi(
        midiValue,
        gameState.midiData.lowestMidi,
        gameState.pixelsPerNote
    )
end

--- Remove a playing note by its track index
-- @param trackIndex number The track index of the note to remove
local function removePlayingNote(trackIndex)
    for i, note in ipairs(gameState.playingNotes) do
        if note.indexOfPlaying == trackIndex then
            table.remove(gameState.playingNotes, i)
            return
        end
    end
end

--- Handle a note trigger - play sound and spawn boids
-- @param trackIndex number Index of the track
-- @param noteData table The note data from the MIDI file
local function triggerNote(trackIndex, noteData)
    -- Skip if track is muted
    if gameState.mutedTracks[trackIndex] then
        return
    end
    
    -- Play the MIDI note
    midi.noteOn(0, noteData.midi, noteData.velocity * 100)
    
    -- Add to playing notes for visual feedback
    table.insert(gameState.playingNotes, {
        indexOfPlaying = trackIndex,
        midi = noteData.midi,
        duration = noteData.duration,
        playedTime = gameState.time,
        velocity = noteData.velocity
    })
    
    -- Spawn a boid for this note
    local spawnX = getXFromMidi(noteData.midi)
    local spawnY = Config.BOID.SPAWN_Y
    local velocity = Vector(0, -noteData.velocity * 10)  -- Reduced from 1000 to 10
    
    table.insert(gameState.flocks[trackIndex], Boid(Vector(spawnX, spawnY), velocity))
    
    -- Schedule note removal after its duration
    Timer.after(noteData.duration / gameState.playbackSpeed, function()
        removePlayingNote(trackIndex)
    end)
end

--- Update boid simulation
-- @param dt number Delta time
local function updateBoids(dt)
    local width = Config.WINDOW.WIDTH
    local height = Config.WINDOW.HEIGHT
    
    for _, flock in ipairs(gameState.flocks) do
        -- Iterate backwards to safely remove boids
        for i = #flock, 1, -1 do
            local boid = flock[i]
            boid:edges()
            boid:flock(flock)
            boid:update(dt)
            
            -- Remove boids that are out of bounds
            if boid:isOutOfBounds(width, height) then
                table.remove(flock, i)
            end
        end
    end
end

--- Process MIDI tracks and trigger notes
-- @param dt number Delta time
local function processMidiTracks(dt)
    for trackIndex, track in ipairs(gameState.tracks) do
        for _, note in ipairs(track.notes) do
            -- Check if this note should play now
            if gameState.time >= note.time and gameState.time - note.time <= dt then
                triggerNote(trackIndex, note)
                
                -- Mark note as played (prevent re-triggering)
                note.played = gameState.time
                note.time = NOTE_PLAYED_TIME
            end
        end
    end
end

--- Reset game state for a new song or restart
local function resetGameState()
    gameState.time = 0
    gameState.tracks = {}
    gameState.flocks = {}
    gameState.playingNotes = {}
    gameState.midiData = nil
    gameState.pixelsPerNote = 0
    gameState.isPaused = false
    gameState.originalTracks = nil
    Timer.clear()
end

--- Deep copy a table
-- @param orig table Original table
-- @return table Copy of the table
local function deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[deepCopy(k)] = deepCopy(v)
        end
    else
        copy = orig
    end
    return copy
end

--- Load and initialize a MIDI JSON file
-- @param filepath string Path to the JSON file
local function loadSong(filepath)
    resetGameState()
    
    -- Load and parse MIDI file
    local success, result = pcall(MidiParser.load, filepath)
    if not success then
        print("Error loading file: " .. tostring(result))
        return false
    end
    
    gameState.midiData = result
    gameState.tracks = result.tracks
    gameState.originalTracks = deepCopy(result.tracks)  -- Store original for restart/seek
    gameState.currentFile = filepath
    
    -- Calculate pixels per MIDI note
    gameState.pixelsPerNote = Config.WINDOW.WIDTH / gameState.midiData.midiRange
    
    -- Ensure we have enough track colors
    Renderer.ensureTrackColors(#gameState.tracks)
    
    -- Initialize flocks (one per track)
    for _ = 1, #gameState.tracks do
        table.insert(gameState.flocks, {})
    end
    
    -- Set timeline duration
    Timeline.setDuration(gameState.midiData.duration or 200)
    
    gameState.isLoaded = true
    return true
end

--- Seek to a specific time in the song
-- @param newTime number Time to seek to
local function seekToTime(newTime)
    if not gameState.isLoaded or not gameState.originalTracks then
        return
    end
    
    -- Clamp time
    newTime = math.max(0, newTime)
    
    -- Reset tracks from original
    gameState.tracks = deepCopy(gameState.originalTracks)
    gameState.time = newTime
    gameState.playingNotes = {}
    gameState.flocks = {}
    Timer.clear()
    
    -- Re-initialize flocks
    for _ = 1, #gameState.tracks do
        table.insert(gameState.flocks, {})
    end
    
    -- Mark notes before newTime as played
    for _, track in ipairs(gameState.tracks) do
        for _, note in ipairs(track.notes) do
            if note.time < newTime then
                note.time = NOTE_PLAYED_TIME
            end
        end
    end
end

--- Change playback speed
-- @param delta number Change in speed index (-1 or 1)
local function changeSpeed(delta)
    gameState.speedIndex = gameState.speedIndex + delta
    gameState.speedIndex = math.max(1, math.min(#Config.PLAYBACK.SPEEDS, gameState.speedIndex))
    gameState.playbackSpeed = Config.PLAYBACK.SPEEDS[gameState.speedIndex]
    
    -- Update panel slider if visible
    Panel.setSliderValue("speed", gameState.playbackSpeed)
end

--- Toggle mute for a track
-- @param trackIndex number Track index to toggle
local function toggleTrackMute(trackIndex)
    if trackIndex <= #gameState.tracks then
        gameState.mutedTracks[trackIndex] = not gameState.mutedTracks[trackIndex]
    end
end

--- Restart the current song from the beginning
local function restartSong()
    if gameState.currentFile then
        local mutedTracks = gameState.mutedTracks  -- Preserve muted tracks
        loadSong(gameState.currentFile)
        gameState.mutedTracks = mutedTracks
    end
end

--- Toggle pause state
local function togglePause()
    if gameState.isLoaded then
        gameState.isPaused = not gameState.isPaused
    end
end

--- Initialize the control panel with sliders and buttons
local function setupControlPanel()
    -- Playback speed slider
    Panel.addSlider("speed", "Playback Speed", 0.25, 2.0, 1.0, function(value)
        gameState.playbackSpeed = value
        -- Speed index updates are only needed for arrow key presets
    end)
    
    -- Boid settings sliders with reduced ranges
    Panel.addSlider("maxSpeed", "Boid Max Speed", 0.5, 5, Config.BOID.MAX_SPEED, function(value)
        Config.BOID.MAX_SPEED = value
    end)
    
    Panel.addSlider("maxForce", "Boid Max Force", 0.01, 0.3, Config.BOID.MAX_FORCE, function(value)
        Config.BOID.MAX_FORCE = value
    end)
    
    Panel.addSlider("boidSize", "Boid Size", 1, 8, Config.BOID.SIZE, function(value)
        Config.BOID.SIZE = value
    end)
    
    Panel.addSlider("perception", "Perception Radius", 20, 150, Config.BOID.PERCEPTION_RADIUS_ALIGN, function(value)
        Config.BOID.PERCEPTION_RADIUS_ALIGN = value
        Config.BOID.PERCEPTION_RADIUS_COHESION = value * 1.5
        Config.BOID.PERCEPTION_RADIUS_SEPARATION = value * 1.5
    end)
    
    -- Buttons
    Panel.addButton("theme", "Toggle Theme (T)", function()
        Renderer.toggleTheme()
        Panel.setup()  -- Refresh panel colors
        Timeline.setup()  -- Refresh timeline colors
    end)
    
    Panel.addButton("visMode", "Cycle Visualization (V)", function()
        Renderer.cycleVisMode()
    end)
    
    Panel.addButton("restart", "Restart Song (R)", function()
        restartSong()
    end)
end

--[[
    LOVE2D Callbacks
]]

function love.load(arg)
    -- Seed random number generator
    math.randomseed(os.time())
    
    -- Store default font
    gameState.defaultFont = love.graphics.getFont()
    
    -- Set custom font
    love.graphics.setFont(love.graphics.newFont(Config.FONTS.DEFAULT_PATH))
    
    -- Initialize renderer and UI
    Renderer.setup()
    Panel.setup()
    Timeline.setup()
    setupControlPanel()
    
    -- Load song from command line argument if provided
    if arg[1] then
        loadSong(arg[1])
    end
    -- If no argument, show waiting screen (handled in love.draw)
end

function love.update(dt)
    -- Only update if loaded and not paused
    if not gameState.isLoaded or gameState.isPaused then
        return
    end
    
    -- Apply playback speed to delta time
    local scaledDt = dt * gameState.playbackSpeed
    
    Timer.update(scaledDt)
    gameState.time = gameState.time + scaledDt
    
    -- Update timeline
    Timeline.setTime(gameState.time)
    
    -- Process MIDI and trigger notes
    processMidiTracks(scaledDt)
    
    -- Update boid simulation
    updateBoids(scaledDt)
end

function love.draw()
    -- Clear background
    Renderer.clearBackground()
    
    -- If no song loaded, show instructions
    if not gameState.isLoaded then
        Renderer.drawWaitingScreen()
        Panel.draw()
        return
    end
    
    -- Draw note trigger points
    Renderer.drawNoteTriggers(
        gameState.midiData.lowestMidi,
        gameState.midiData.highestMidi,
        gameState.pixelsPerNote,
        getXFromMidi
    )
    
    -- Draw playing notes
    Renderer.drawPlayingNotes(
        gameState.playingNotes,
        gameState.time,
        gameState.pixelsPerNote,
        getXFromMidi
    )
    
    -- Draw boids with muted tracks and playing notes
    local numBoids = Renderer.drawBoids(gameState.flocks, gameState.mutedTracks, gameState.playingNotes)
    
    -- Draw timeline
    Timeline.draw()
    
    -- Draw track mute indicators
    Renderer.drawTrackMutes(#gameState.tracks, gameState.mutedTracks)
    
    -- Draw stats and controls
    Renderer.drawStats(gameState.time, numBoids, gameState.defaultFont, gameState.isPaused, gameState.playbackSpeed)
    Renderer.drawFPS()
    Renderer.drawControls(gameState.isPaused, gameState.playbackSpeed)
    
    -- Draw control panel (on top)
    Panel.draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" then
        togglePause()
    elseif key == "r" then
        restartSong()
    elseif key == "left" then
        -- Seek backward
        seekToTime(gameState.time - Config.PLAYBACK.SEEK_AMOUNT)
    elseif key == "right" then
        -- Seek forward
        seekToTime(gameState.time + Config.PLAYBACK.SEEK_AMOUNT)
    elseif key == "up" then
        -- Increase speed
        changeSpeed(1)
    elseif key == "down" then
        -- Decrease speed
        changeSpeed(-1)
    elseif key == "v" then
        -- Cycle visualization mode
        Renderer.cycleVisMode()
    elseif key == "t" then
        -- Toggle theme
        Renderer.toggleTheme()
        Panel.setup()
        Timeline.setup()
    elseif key == "p" then
        -- Toggle control panel
        Panel.toggle()
    elseif tonumber(key) and tonumber(key) >= 1 and tonumber(key) <= 9 then
        -- Toggle track mute
        toggleTrackMute(tonumber(key))
    end
end

function love.mousepressed(x, y, button)
    -- Check if panel handles the click
    if Panel.mousepressed(x, y, button) then
        return
    end
    
    -- Check if timeline handles the click
    local handled, newTime = Timeline.mousepressed(x, y)
    if handled then
        seekToTime(newTime)
        return
    end
end

function love.mousereleased(x, y, button)
    Panel.mousereleased()
    Timeline.mousereleased()
end

function love.mousemoved(x, y)
    Panel.mousemoved(x, y)
    
    -- Handle timeline drag
    local dragging, newTime = Timeline.mousemoved(x)
    if dragging then
        seekToTime(newTime)
    end
end

function love.filedropped(file)
    -- Get the file path and load it
    local filepath = file:getFilename()
    
    -- Check if it's a JSON file (case-insensitive)
    if filepath:lower():match("%.json$") then
        loadSong(filepath)
    else
        print("Please drop a JSON file")
    end
end

function love.quit()
    -- Clean up MIDI resources before exiting
    midi.gc()
end
