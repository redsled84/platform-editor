local inspect = require "inspect"
local level = require "level"
world = love.physics.newWorld(0, 300, true)

function newPolygon(x, y, vertices)
  local poly = {
    x = 0,
    y = 0,
    vertices = vertices,
  }
  poly.body = love.physics.newBody(world, 0, 0, "static")
  print(inspect(vertices))
  poly.shape = love.physics.newPolygonShape(vertices)
  poly.fixture = love.physics.newFixture(poly.body, poly.shape)
  return poly
end

local objects = {}

function love.load()
  local tables = level[1]
  print (#tables)
  for i = 1, #tables do
    local n = tables[i][1]

    local polygon = level[n]
    objects[#objects+1] = newPolygon(polygon.x, polygon.y, level[polygon.vertices[1]])
  end

  objects.ball = {}
  objects.ball.body = love.physics.newBody(world, 200, 2, "dynamic")
  objects.ball.shape = love.physics.newCircleShape(20)
  objects.ball.fixture = love.physics.newFixture(objects.ball.body, objects.ball.shape)

  objects.awesome = {}
  objects.awesome.body = love.physics.newBody(world, 0, 0, "dynamic")
  objects.awesome.shape = love.physics.newPolygonShape({
    0,
    384,
    224,
    384,
    0,
    160,
  })
  objects.awesome.fixture = love.physics.newFixture(objects.awesome.body, objects.awesome.shape)
end

function love.update(dt)
  world:update(dt)
end

function love.draw()
  love.graphics.setColor(255, 255, 255, 100)
  for i = 1, #objects do
    -- print (objects[i].body:getWorldPoints(objects[i].shape:getPoints()))
    love.graphics.polygon("line", objects[i].body:getWorldPoints(objects[i].shape:getPoints()))
  end
  love.graphics.polygon("line", objects.awesome.body:getWorldPoints(objects.awesome.shape:getPoints()))

  love.graphics.points(100, 100)

  love.graphics.setColor(255, 0, 0)
  love.graphics.circle("line", objects.ball.body:getX(), objects.ball.body:getY(), 20)
end