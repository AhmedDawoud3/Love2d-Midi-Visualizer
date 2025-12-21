--[[
    MIDI Parser Module
    Handles loading and parsing MIDI JSON files
]]

local json = require "lib.json"

local MidiParser = {}

--- Read entire file content
-- @param filepath string Path to the file
-- @return string File contents
local function readFile(filepath)
    local f = assert(io.open(filepath, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

--- Parse a MIDI JSON file and extract track data
-- @param filepath string Path to the JSON file
-- @return table Parsed MIDI data with tracks and range info
function MidiParser.load(filepath)
    local fileContent = readFile(filepath)
    local midiData = json:decode(fileContent)
    
    local result = {
        tracks = {},
        lowestMidi = math.huge,
        highestMidi = -math.huge
    }
    
    -- Extract tracks that have notes
    for _, track in ipairs(midiData['tracks']) do
        if track['notes'] then
            table.insert(result.tracks, track)
            
            -- Calculate MIDI range
            for _, note in ipairs(track['notes']) do
                if note['midi'] > result.highestMidi then
                    result.highestMidi = note['midi']
                end
                if note['midi'] < result.lowestMidi then
                    result.lowestMidi = note['midi']
                end
            end
        end
    end
    
    -- Calculate derived values
    result.midiRange = result.highestMidi - result.lowestMidi
    
    return result
end

--- Calculate X position from MIDI note value
-- @param midi number MIDI note value
-- @param lowestMidi number Lowest MIDI value in the song
-- @param pixelsPerNote number Width in pixels for each MIDI note
-- @return number X position on screen
function MidiParser.getXFromMidi(midi, lowestMidi, pixelsPerNote)
    return (midi - lowestMidi) * pixelsPerNote
end

return MidiParser
