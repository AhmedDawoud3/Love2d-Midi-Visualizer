local module = {
  _version = "color.lua V1.0",
  _description = "a simple Love2d Color lib",
  _license = [[
    Copyright (c) 2022 Ahmed Dawoud
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  ]]
}
local brighteningValue = 1.25
local dimmingValue = 0.75
local Color = {}
Color.__index = Color
--[[
  Initialize the color
  -The RGB values (0 to 255 OR 0 to 1 OR HEX string)
]]
local function new(r, g, b, a)
  if r and not g and not b and not a then
    r, g, b = Color.HEXToRGB(r)
    a = 1
  else
    if r <= 1 and g <= 1 and b <= 1 then
      r, g, b = r, g, b
    else
      r = r / 255
      g = g / 255
      b = b / 255

      a = a or 1
    end
  end
  return setmetatable({
    r = r,
    g = g,
    b = b,
    a = a
  }, Color)
end

function Color:SetBackground()
  love.graphics.clear(self.r, self.g, self.b)
end

-- a-> alpha value from 0 to 1
function Color:Set(a)
  love.graphics.setColor(self.r, self.g, self.b, a or self.a)
end

local function Random()
  return new(math.random(), math.random(), math.random())
end

local function Reset()
  return new(1, 1, 1):Set()
end

function Color:SetBrightened(a)
  love.graphics.setColor(self.r * brighteningValue, self.g * brighteningValue, self.b * brighteningValue, a or self.a)
end

function Color:SetDimmed(a)
  love.graphics.setColor(self.r * dimmingValue, self.g * dimmingValue, self.b * dimmingValue, a or self.a)
end

function Color.HEXToRGB(hex)
  local hex = hex:gsub("#", "")
  if hex:len() == 3 then
    return (tonumber("0x" .. hex:sub(1, 1)) * 17) / 255, (tonumber("0x" .. hex:sub(2, 2)) * 17) / 255,
      (tonumber("0x" .. hex:sub(3, 3)) * 17) / 255
  else
    return tonumber("0x" .. hex:sub(1, 2)) / 255, tonumber("0x" .. hex:sub(3, 4)) / 255,
      tonumber("0x" .. hex:sub(5, 6)) / 255
  end
end

module.new = new
module.Random = Random
module.Reset = Reset
return setmetatable(module, {
  __call = function(_, ...)
    return new(...)
  end
})
