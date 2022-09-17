Boid = Class {}

function Boid:init(pos, vel)
    self.position = pos or Vector(math.random(love.graphics.getWidth()), math.random(love.graphics.getHeight()))
    local a = math.random() * math.pi * 2
    self.velocity = vel or Vector(math.cos(a), math.sin(a))
    self.velocity:setmag(math.random(2, 4))
    self.acceleration = Vector()
    self.angle = 0
    self.maxForce = 0.2
    self.maxSpeed = 4
    self.trail = {}
end

function Boid:update(dt)
    self.position = self.position + self.velocity
    self.velocity = self.velocity + self.acceleration
    self.velocity:limit(self.maxSpeed)
    self.acceleration = self.acceleration * 0
    if self.velocity:getmag() ~= 0 then
        self.angle = getAngle(0, 0, self.velocity.x, self.velocity.y)
    end
    table.insert(self.trail, self.position.x)
    table.insert(self.trail, self.position.y)
    -- if #self.trail > 100 then
    --     table.remove( self.trail,1 )
    --     table.remove( self.trail,1 )
    -- end
end

function Boid:edges()
    -- if self.position.x > love.graphics.getWidth() then
    --     self.position.x = 0
    -- elseif self.position.x < 0 then
    --     self.position.x = love.graphics.getWidth()
    -- end

    -- if self.position.y > love.graphics.getHeight() then
    --     self.position.y = 0
    -- elseif self.position.y < 0 then
    --     self.position.y = love.graphics.getHeight()
    -- end
end

function Boid:align(boids)
    perceptionRadius = 100
    total = 0
    steering = Vector()
    for _, other in ipairs(boids) do
        if other ~= self and Vector.dist(self.position, other.position) < perceptionRadius then
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

function Boid:cohesion(boids)
    perceptionRadius = 150
    steering = Vector()
    total = 0
    for _, other in ipairs(boids) do
        if other ~= self and Vector.dist(self.position, other.position) < perceptionRadius then
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

function Boid:separation(boids)
    perceptionRadius = 150
    steering = Vector()
    total = 0
    for _, other in ipairs(boids) do
        d = Vector.dist(self.position, other.position)
        if other ~= self and d < perceptionRadius then
            diff = self.position - other.position
            diff = diff / d
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

function Boid:flock(boids)
    alignment = self:align(boids)
    cohesion = self:cohesion(boids)
    separation = self:separation(boids)
    self.acceleration = self.acceleration + separation + alignment + cohesion
end

function Boid:show()
    -- love.graphics.setColor(1, 1, 1, 1)
    -- love.graphics.push()
    -- love.graphics.translate(self.position.x, self.position.y)
    --   love.graphics.rotate(self.angle)
    -- love.graphics.polygon('fill', {-5, 5, -5, -5, 5 * 2, 0})
    --    love.graphics.pop()
    love.graphics.points(self.trail)
    love.graphics.circle("fill", self.position.x, self.position.y, 3)
end

-- get the distance between two Vectors
function Vector.dist(a, b)
    return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end
