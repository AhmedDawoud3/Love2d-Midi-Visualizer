--[[
    Boid Entity Module
    Implements the Boid flocking simulation
]]

local Class = require "lib.class"
local Vector = require "lib.vector"
local Config = require "src.config"

local Boid = Class {}

--- Initialize a new Boid
-- @param pos Vector Initial position
-- @param vel Vector Initial velocity
function Boid:init(pos, vel)
    self.position = pos or Vector(
        math.random(love.graphics.getWidth()),
        math.random(love.graphics.getHeight())
    )
    
    local angle = math.random() * math.pi * 2
    self.velocity = vel or Vector(math.cos(angle), math.sin(angle))
    self.velocity:setmag(math.random(2, 4))
    
    self.acceleration = Vector()
    self.angle = 0
    self.maxForce = Config.BOID.MAX_FORCE
    self.maxSpeed = Config.BOID.MAX_SPEED
    self.trail = {}
end

--- Update boid position and physics
-- @param dt number Delta time
function Boid:update(dt)
    self.position = self.position + self.velocity
    self.velocity = self.velocity + self.acceleration
    self.velocity:limit(self.maxSpeed)
    self.acceleration = self.acceleration * 0
    
    if self.velocity:getmag() ~= 0 then
        self.angle = math.atan2(self.velocity.y, self.velocity.x)
    end
    
    table.insert(self.trail, self.position.x)
    table.insert(self.trail, self.position.y)
end

--- Handle edge wrapping/boundary behavior (currently disabled)
function Boid:edges()
    -- Edge wrapping is disabled for this visualizer
end

--- Alignment behavior - steer towards average heading of neighbors
-- @param boids table List of boids to consider
-- @return Vector Steering force
function Boid:align(boids)
    local perceptionRadius = Config.BOID.PERCEPTION_RADIUS_ALIGN
    local total = 0
    local steering = Vector()
    
    for _, other in ipairs(boids) do
        local distance = Vector.dist(self.position, other.position)
        if other ~= self and distance < perceptionRadius then
            steering = steering + other.velocity
            total = total + 1
        end
    end
    
    if total > 0 then
        steering = steering / total
        steering:setmag(self.maxSpeed)
        steering = steering - self.velocity
        steering:limit(self.maxForce)
    end
    
    return steering
end

--- Cohesion behavior - steer towards center of mass of neighbors
-- @param boids table List of boids to consider
-- @return Vector Steering force
function Boid:cohesion(boids)
    local perceptionRadius = Config.BOID.PERCEPTION_RADIUS_COHESION
    local steering = Vector()
    local total = 0
    
    for _, other in ipairs(boids) do
        local distance = Vector.dist(self.position, other.position)
        if other ~= self and distance < perceptionRadius then
            steering = steering + other.position
            total = total + 1
        end
    end
    
    if total > 0 then
        steering = steering / total
        steering = steering - self.position
        steering:setmag(self.maxSpeed)
        steering = steering - self.velocity
        steering:limit(self.maxForce)
    end
    
    return steering
end

--- Separation behavior - steer away from nearby boids
-- @param boids table List of boids to consider
-- @return Vector Steering force
function Boid:separation(boids)
    local perceptionRadius = Config.BOID.PERCEPTION_RADIUS_SEPARATION
    local steering = Vector()
    local total = 0
    
    for _, other in ipairs(boids) do
        local distance = Vector.dist(self.position, other.position)
        if other ~= self and distance < perceptionRadius then
            local diff = self.position - other.position
            diff = diff / distance
            steering = steering + diff
            total = total + 1
        end
    end
    
    if total > 0 then
        steering = steering / total
        steering:setmag(self.maxSpeed)
        steering = steering - self.velocity
        steering:limit(self.maxForce)
    end
    
    return steering
end

--- Apply all flocking behaviors
-- @param boids table List of boids to consider
function Boid:flock(boids)
    local alignment = self:align(boids)
    local cohesion = self:cohesion(boids)
    local separation = self:separation(boids)
    
    self.acceleration = self.acceleration + separation + alignment + cohesion
end

--- Render the boid
function Boid:show()
    love.graphics.points(self.trail)
    love.graphics.circle("fill", self.position.x, self.position.y, Config.BOID.SIZE)
end

--- Check if boid is out of bounds
-- @param width number Screen width
-- @param height number Screen height
-- @return boolean True if out of bounds
function Boid:isOutOfBounds(width, height)
    return self.position.x > width * 1.5 or
           self.position.x < -width / 2 or
           self.position.y > height * 1.5 or
           self.position.y < -height / 2
end

return Boid
