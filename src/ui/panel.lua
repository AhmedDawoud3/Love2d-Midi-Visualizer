--[[
    Control Panel Module
    Provides an imgui-like control panel for adjusting parameters
]]

local Color = require "lib.color"
local Config = require "src.config"

local Panel = {}

-- Panel state
local state = {
    visible = false,
    x = 10,
    y = 40,
    width = Config.UI.PANEL_WIDTH,
    sliders = {},
    buttons = {},
    isDragging = false,
    dragOffsetX = 0,
    dragOffsetY = 0,
    activeSlider = nil
}

-- Colors (initialized in setup)
local colors = {
    panel = nil,
    border = nil,
    text = nil,
    slider_bg = nil,
    slider_fill = nil,
    button = nil,
    button_hover = nil
}

--- Initialize panel colors
function Panel.setup()
    colors.panel = Color(Config.COLORS.UI_PANEL or "1a1a1a")
    colors.border = Color(Config.COLORS.UI_PANEL_BORDER or "444444")
    colors.text = Color(Config.COLORS.UI_TEXT or "ffffff")
    colors.slider_bg = Color("333333")
    colors.slider_fill = Color(Config.COLORS.TIMELINE_PROGRESS or "4a9eff")
    colors.button = Color("444444")
    colors.button_hover = Color("555555")
end

--- Toggle panel visibility
function Panel.toggle()
    state.visible = not state.visible
end

--- Check if panel is visible
function Panel.isVisible()
    return state.visible
end

--- Register a slider control
-- @param id string Unique identifier
-- @param label string Display label
-- @param min number Minimum value
-- @param max number Maximum value
-- @param value number Current value
-- @param callback function Called when value changes
function Panel.addSlider(id, label, min, max, value, callback)
    state.sliders[id] = {
        label = label,
        min = min,
        max = max,
        value = value,
        callback = callback
    }
end

--- Update a slider value
-- @param id string Slider identifier
-- @param value number New value
function Panel.setSliderValue(id, value)
    if state.sliders[id] then
        state.sliders[id].value = value
    end
end

--- Get a slider value
-- @param id string Slider identifier
-- @return number Current value
function Panel.getSliderValue(id)
    if state.sliders[id] then
        return state.sliders[id].value
    end
    return 0
end

--- Register a button control
-- @param id string Unique identifier
-- @param label string Display label
-- @param callback function Called when clicked
function Panel.addButton(id, label, callback)
    state.buttons[id] = {
        label = label,
        callback = callback,
        hover = false
    }
end

--- Update button label
-- @param id string Button identifier
-- @param label string New label
function Panel.setButtonLabel(id, label)
    if state.buttons[id] then
        state.buttons[id].label = label
    end
end

--- Handle mouse press
-- @param x number Mouse X
-- @param y number Mouse Y
-- @param button number Mouse button
-- @return boolean True if panel handled the click
function Panel.mousepressed(x, y, button)
    if not state.visible then return false end
    
    -- Check if click is on panel header (for dragging)
    if x >= state.x and x <= state.x + state.width and
       y >= state.y and y <= state.y + 25 then
        state.isDragging = true
        state.dragOffsetX = x - state.x
        state.dragOffsetY = y - state.y
        return true
    end
    
    -- Check sliders
    local sliderY = state.y + 35
    for id, slider in pairs(state.sliders) do
        local sliderX = state.x + Config.UI.PANEL_PADDING
        local sliderWidth = state.width - Config.UI.PANEL_PADDING * 2
        
        if x >= sliderX and x <= sliderX + sliderWidth and
           y >= sliderY and y <= sliderY + Config.UI.SLIDER_HEIGHT then
            state.activeSlider = id
            -- Update value based on click position
            local ratio = (x - sliderX) / sliderWidth
            ratio = math.max(0, math.min(1, ratio))
            slider.value = slider.min + ratio * (slider.max - slider.min)
            if slider.callback then
                slider.callback(slider.value)
            end
            return true
        end
        sliderY = sliderY + 45
    end
    
    -- Check buttons
    local buttonY = sliderY + 10
    local buttonHeight = 30
    for id, btn in pairs(state.buttons) do
        local buttonX = state.x + Config.UI.PANEL_PADDING
        local buttonWidth = state.width - Config.UI.PANEL_PADDING * 2
        
        if x >= buttonX and x <= buttonX + buttonWidth and
           y >= buttonY and y <= buttonY + buttonHeight then
            if btn.callback then
                btn.callback()
            end
            return true
        end
        buttonY = buttonY + buttonHeight + 5
    end
    
    -- Check if click is inside panel (consume event)
    if x >= state.x and x <= state.x + state.width and
       y >= state.y and y <= state.y + Panel.getHeight() then
        return true
    end
    
    return false
end

--- Handle mouse release
function Panel.mousereleased()
    state.isDragging = false
    state.activeSlider = nil
end

--- Handle mouse movement
-- @param x number Mouse X
-- @param y number Mouse Y
function Panel.mousemoved(x, y)
    if not state.visible then return end
    
    -- Handle panel dragging
    if state.isDragging then
        state.x = x - state.dragOffsetX
        state.y = y - state.dragOffsetY
        return
    end
    
    -- Handle slider dragging
    if state.activeSlider then
        local slider = state.sliders[state.activeSlider]
        if slider then
            local sliderX = state.x + Config.UI.PANEL_PADDING
            local sliderWidth = state.width - Config.UI.PANEL_PADDING * 2
            local ratio = (x - sliderX) / sliderWidth
            ratio = math.max(0, math.min(1, ratio))
            slider.value = slider.min + ratio * (slider.max - slider.min)
            if slider.callback then
                slider.callback(slider.value)
            end
        end
    end
    
    -- Update button hover states
    local sliderY = state.y + 35
    for _ in pairs(state.sliders) do
        sliderY = sliderY + 45
    end
    
    local buttonY = sliderY + 10
    local buttonHeight = 30
    for id, btn in pairs(state.buttons) do
        local buttonX = state.x + Config.UI.PANEL_PADDING
        local buttonWidth = state.width - Config.UI.PANEL_PADDING * 2
        
        btn.hover = x >= buttonX and x <= buttonX + buttonWidth and
                   y >= buttonY and y <= buttonY + buttonHeight
        buttonY = buttonY + buttonHeight + 5
    end
end

--- Calculate panel height based on content
-- @return number Panel height
function Panel.getHeight()
    local height = 35  -- Header
    
    -- Sliders
    local sliderCount = 0
    for _ in pairs(state.sliders) do
        sliderCount = sliderCount + 1
    end
    height = height + sliderCount * 45
    
    -- Buttons
    local buttonCount = 0
    for _ in pairs(state.buttons) do
        buttonCount = buttonCount + 1
    end
    height = height + 10 + buttonCount * 35
    
    return height + Config.UI.PANEL_PADDING
end

--- Draw the control panel
function Panel.draw()
    if not state.visible then return end
    
    local panelHeight = Panel.getHeight()
    
    -- Draw panel background
    colors.panel:Set(0.95)
    love.graphics.rectangle("fill", state.x, state.y, state.width, panelHeight, 5, 5)
    
    -- Draw border
    colors.border:Set()
    love.graphics.rectangle("line", state.x, state.y, state.width, panelHeight, 5, 5)
    
    -- Draw header
    colors.text:Set()
    love.graphics.print("Control Panel", state.x + Config.UI.PANEL_PADDING, state.y + 5)
    
    -- Draw header line
    colors.border:Set()
    love.graphics.line(state.x, state.y + 25, state.x + state.width, state.y + 25)
    
    -- Draw sliders
    local sliderY = state.y + 35
    for id, slider in pairs(state.sliders) do
        local sliderX = state.x + Config.UI.PANEL_PADDING
        local sliderWidth = state.width - Config.UI.PANEL_PADDING * 2
        
        -- Label
        colors.text:Set()
        love.graphics.print(slider.label .. ": " .. string.format("%.2f", slider.value), sliderX, sliderY)
        
        -- Slider background
        colors.slider_bg:Set()
        love.graphics.rectangle("fill", sliderX, sliderY + 18, sliderWidth, Config.UI.SLIDER_HEIGHT, 3, 3)
        
        -- Slider fill
        local ratio = (slider.value - slider.min) / (slider.max - slider.min)
        colors.slider_fill:Set()
        love.graphics.rectangle("fill", sliderX, sliderY + 18, sliderWidth * ratio, Config.UI.SLIDER_HEIGHT, 3, 3)
        
        -- Slider knob
        love.graphics.setColor(1, 1, 1, 1)
        local knobX = sliderX + sliderWidth * ratio
        love.graphics.circle("fill", knobX, sliderY + 18 + Config.UI.SLIDER_HEIGHT / 2, Config.UI.SLIDER_KNOB_SIZE / 2)
        
        sliderY = sliderY + 45
    end
    
    -- Draw buttons
    local buttonY = sliderY + 10
    local buttonHeight = 30
    for id, btn in pairs(state.buttons) do
        local buttonX = state.x + Config.UI.PANEL_PADDING
        local buttonWidth = state.width - Config.UI.PANEL_PADDING * 2
        
        -- Button background
        if btn.hover then
            colors.button_hover:Set()
        else
            colors.button:Set()
        end
        love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 3, 3)
        
        -- Button text
        colors.text:Set()
        local textWidth = love.graphics.getFont():getWidth(btn.label)
        love.graphics.print(btn.label, buttonX + (buttonWidth - textWidth) / 2, buttonY + 7)
        
        buttonY = buttonY + buttonHeight + 5
    end
end

return Panel
