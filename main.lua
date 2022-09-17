Class = require 'lib.class'
require 'lib.Utils'
Vector = require 'lib.vector'
Color = require 'lib.color'
midi = require "luamidi"
json = require "lib.json"
-- inspect = require "lib.inspect"
require 'lib.boid'
local Timer = require "lib.timer"
local time = 0
function love.load(arg)
    -- Settup the window
    WIDTH = 1280
    HEIGHT = 720
    love.window.setTitle("Love2d Midi Visualizer")
    love.window.setMode(WIDTH, HEIGHT)

    -- Settup the random seed and fonts
    math.randomseed(os.time())
    defFont = love.graphics.getFont()
    -- bigFont = love.graphics.newFont('fonts/MontserratBoldItalic.ttf', 50)
    love.graphics.setFont(love.graphics.newFont('fonts/MontserratBoldItalic.ttf'))

    --[[
        Colors
    ]]
    bgColor = Color('232221')
    blackishColor = Color('282c34')
    trailColor = Color('189cf8')
    whiteColor = Color('f3f0e0')
    -- Colors for the each track.
    COLORS_FOR_TRAILS = {Color('fb606a'), Color('15A7EB'), Color('ff753f'), Color('189cf8'), Color('16F547'),
                         Color('ffe23f'), Color('cc5d32'), Color('D36FF7'), Color('CCED82'), Color('BA5B4A')}

    --[[
        Midi File
    ]]
    if not arg[1] then
        assert(false, "Usage: love . file.json")
    end
    midiFile = json:decode(tostring(readAll(arg[1])))

    -- Keep track of each track in the midi file
    tracks = {}
    for i, v in ipairs(midiFile['tracks']) do
        if v['notes'] then
            table.insert(tracks, v)
        end
    end
    -- Make sure the Colors are enough!
    if #COLORS_FOR_TRAILS < #tracks then
        for i = #COLORS_FOR_TRAILS + 1, #tracks do
            COLORS_FOR_TRAILS[i] = Color.Random()
        end
    end

    -- Keep track of the range of the midi values in
    -- the file for to help with the drawing rage.
    lowestMidi = 1000
    highestMidi = 0
    for i, q in ipairs(tracks) do
        for j, v in ipairs(q["notes"]) do
            if v["midi"] > highestMidi then
                highestMidi = v["midi"]
            elseif v["midi"] < lowestMidi then
                lowestMidi = v["midi"]
            end
        end
    end
    midiRange = highestMidi - lowestMidi
    midiRepresentedByPixels = WIDTH / midiRange

    -- Keep track of currently playing notes
    midiPlaying = {}

    --[[
        BOIDS
    `]]
    flocks = {}
    for i = 1, #tracks do
        table.insert(flocks, {})
    end

end
function love.update(dt)
    Timer.update(dt)
    time = time + dt

    -- Play the tracks
    for i, q in ipairs(tracks) do
        for j, v in ipairs(q["notes"]) do
            -- Make sure the note's range is in the range of a
            -- (delta time) before and after the current time.
            if time >= v["time"] and time - v["time"] <= dt then
                -- Play the note with the velocity (volume) of it.
                -- port, note, [vel], [channel]
                midi.noteOn(0, v["midi"], v["velocity"] * 100)
                table.insert(midiPlaying, {
                    indexOfPlaying = i,
                    midi = v["midi"],
                    duration = v["duration"],
                    playedTime = time
                })
                -- Trigger the boids
                table.insert(flocks[i], Boid(Vector(getXFromMidi(v["midi"]), 500), Vector(0, -v["velocity"] * 1000)))
                Timer.after(v["duration"], function()
                    table.removekeyIndexOfPlaying(midiPlaying, i)
                end)
                v["played"] = time
                v["time"] = 10 ^ 10
            end
        end
    end

    -- Update the flocking simultaion
    for q, r in ipairs(flocks) do
        for i, v in ipairs(r) do
            v:edges()
            v:flock(r)
            v:update(dt)
            if v.position.x > WIDTH * 1.5 or v.position.x < -WIDTH / 2 or v.position.y > HEIGHT * 1.5 or v.position.y <
                -HEIGHT / 2 then
                table.remove(r, i)
            end
        end
    end
end

function love.draw()
    bgColor:SetBackground()

    -- love.graphics.setFont(bigFont)
    -- love.graphics.print("Ahmed Dawoud", 820, 650)

    -- Draw the white circles (Where the boids are triggered from).
    for i = lowestMidi, highestMidi do
        whiteColor:Set()
        -- love.graphics.rectangle("fill", getXFromMidi(i), 500, midiRepresentedByPixels /2, 10)
        love.graphics.circle("fill", getXFromMidi(i), 500, midiRepresentedByPixels / 2)
        blackishColor:Set()
        -- love.graphics.rectangle("line", getXFromMidi(i), 500, midiRepresentedByPixels /2, 10)
        love.graphics.circle("line", getXFromMidi(i), 500, midiRepresentedByPixels / 2)

    end
    for i, v in ipairs(midiPlaying) do
        -- print((time - v.playedTime) / v.duration)
        blackishColor:Set((v.playedTime + v.duration - time) / v.duration)
        -- love.graphics.rectangle("fill", getXFromMidi(v.midi), 500, midiRepresentedByPixels /2, 10)
        love.graphics.circle("fill", getXFromMidi(v.midi), 500, midiRepresentedByPixels / 2)
        -- love.graphics.circle('fill', getXFromMidi(v.midi), 500, midiRepresentedByPixels )
    end

    -- Draw the boids
    numOfBoids = 0
    for q, r in ipairs(flocks) do
        for i, v in ipairs(r) do
            numOfBoids = numOfBoids + 1
            if COLORS_FOR_TRAILS[q] then
                COLORS_FOR_TRAILS[q]:Set()
            else
                Color.Random:Set()
            end
            v:show()
        end
    end

    --[[
        Stats
    ]]
    love.graphics.setFont(defFont)
    Color.Reset()
    love.graphics.print("Time: " .. TimeGSUB(time, 2) .. "   Number of boids: " .. numOfBoids, 55, 5)
    DisplayFPS()
    -- reset keys pressed
    love.keyboard.keysPressed = {}
    love.mouse.keysPressed = {}
    love.mouse.keysReleased = {}
    love.mouse.scrolled = 0
end

function getXFromMidi(midi)
    return (midi - lowestMidi) * midiRepresentedByPixels
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
        midi.gc()
    end
end

function DisplayFPS()
    -- simple FPS display across all states
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
end
