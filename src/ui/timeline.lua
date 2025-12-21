--[[
    Timeline Module
    Provides a seekable timeline/progress bar for the song
]]

local Color = require "lib.color"
local Config = require "src.config"

local Timeline = {}

-- Timeline state
local state = {
    x = 50,
    y = Config.UI.TIMELINE_Y,
    width = Config.WINDOW.WIDTH - 100,
    height = Config.UI.TIMELINE_HEIGHT,
    duration = 0,
    currentTime = 0,
    isDragging = false,
    visible = true
}

-- Colors
local colors = {
    background = nil,
    progress = nil,
    text = nil
}

--- Initialize timeline colors
function Timeline.setup()
    colors.background = Color(Config.COLORS.TIMELINE_BG or "333333")
    colors.progress = Color(Config.COLORS.TIMELINE_PROGRESS or "4a9eff")
    colors.text = Color(Config.COLORS.UI_TEXT or "ffffff")
end

--- Set the song duration
-- @param duration number Duration in seconds
function Timeline.setDuration(duration)
    state.duration = duration
end

--- Update current playback time
-- @param time number Current time in seconds
function Timeline.setTime(time)
    state.currentTime = time
end

--- Toggle timeline visibility
function Timeline.toggle()
    state.visible = not state.visible
end

--- Check if timeline is visible
function Timeline.isVisible()
    return state.visible
end

--- Handle mouse press on timeline
-- @param x number Mouse X
-- @param y number Mouse Y
-- @return boolean, number True if clicked, and new time position
function Timeline.mousepressed(x, y)
    if not state.visible or state.duration <= 0 then
        return false, 0
    end
    
    if x >= state.x and x <= state.x + state.width and
       y >= state.y and y <= state.y + state.height then
        state.isDragging = true
        local ratio = (x - state.x) / state.width
        local newTime = ratio * state.duration
        return true, newTime
    end
    
    return false, 0
end

--- Handle mouse release
function Timeline.mousereleased()
    state.isDragging = false
end

--- Handle mouse drag on timeline
-- @param x number Mouse X
-- @return boolean, number True if dragging, and new time position
function Timeline.mousemoved(x)
    if not state.isDragging or state.duration <= 0 then
        return false, 0
    end
    
    local ratio = math.max(0, math.min(1, (x - state.x) / state.width))
    local newTime = ratio * state.duration
    return true, newTime
end

--- Check if currently dragging
function Timeline.isDragging()
    return state.isDragging
end

--- Format time as MM:SS
-- @param time number Time in seconds
-- @return string Formatted time string
local function formatTime(time)
    local minutes = math.floor(time / 60)
    local seconds = math.floor(time % 60)
    return string.format("%02d:%02d", minutes, seconds)
end

--- Draw the timeline
function Timeline.draw()
    if not state.visible or state.duration <= 0 then
        return
    end
    
    -- Background
    colors.background:Set(0.8)
    love.graphics.rectangle("fill", state.x, state.y, state.width, state.height, 5, 5)
    
    -- Progress bar
    local progress = state.currentTime / state.duration
    if progress > 0 then
        colors.progress:Set()
        love.graphics.rectangle("fill", state.x, state.y, state.width * progress, state.height, 5, 5)
    end
    
    -- Border
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", state.x, state.y, state.width, state.height, 5, 5)
    
    -- Time labels
    colors.text:Set()
    local currentStr = formatTime(state.currentTime)
    local durationStr = formatTime(state.duration)
    
    love.graphics.print(currentStr, state.x - 45, state.y + 7)
    love.graphics.print(durationStr, state.x + state.width + 5, state.y + 7)
    
    -- Playhead
    local playheadX = state.x + state.width * progress
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", playheadX, state.y + state.height / 2, 8)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.circle("line", playheadX, state.y + state.height / 2, 8)
end

return Timeline
