--[[
    Love2D MIDI Visualizer
    A music visualizer that uses MIDI files to create a boid flocking animation

    Usage: love . song.json
    
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

-- Local state variables
local gameState = {
    time = 0,
    tracks = {},
    flocks = {},
    playingNotes = {},
    midiData = nil,
    pixelsPerNote = 0,
    defaultFont = nil
}

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
    -- Play the MIDI note
    midi.noteOn(0, noteData.midi, noteData.velocity * 100)
    
    -- Add to playing notes for visual feedback
    table.insert(gameState.playingNotes, {
        indexOfPlaying = trackIndex,
        midi = noteData.midi,
        duration = noteData.duration,
        playedTime = gameState.time
    })
    
    -- Spawn a boid for this note
    local spawnX = getXFromMidi(noteData.midi)
    local spawnY = Config.BOID.SPAWN_Y
    local velocity = Vector(0, -noteData.velocity * 1000)
    
    table.insert(gameState.flocks[trackIndex], Boid(Vector(spawnX, spawnY), velocity))
    
    -- Schedule note removal after its duration
    Timer.after(noteData.duration, function()
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
                note.time = 10 ^ 10
            end
        end
    end
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
    
    -- Initialize renderer
    Renderer.setup()
    
    -- Validate command line arguments
    if not arg[1] then
        error("Usage: love . file.json")
    end
    
    -- Load and parse MIDI file
    gameState.midiData = MidiParser.load(arg[1])
    gameState.tracks = gameState.midiData.tracks
    
    -- Calculate pixels per MIDI note
    gameState.pixelsPerNote = Config.WINDOW.WIDTH / gameState.midiData.midiRange
    
    -- Ensure we have enough track colors
    Renderer.ensureTrackColors(#gameState.tracks)
    
    -- Initialize flocks (one per track)
    for _ = 1, #gameState.tracks do
        table.insert(gameState.flocks, {})
    end
end

function love.update(dt)
    Timer.update(dt)
    gameState.time = gameState.time + dt
    
    -- Process MIDI and trigger notes
    processMidiTracks(dt)
    
    -- Update boid simulation
    updateBoids(dt)
end

function love.draw()
    -- Clear background
    Renderer.clearBackground()
    
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
    
    -- Draw boids and get count
    local numBoids = Renderer.drawBoids(gameState.flocks)
    
    -- Draw stats
    Renderer.drawStats(gameState.time, numBoids, gameState.defaultFont)
    Renderer.drawFPS()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.quit()
    -- Clean up MIDI resources before exiting
    midi.gc()
end
