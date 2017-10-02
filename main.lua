local Camera = require "camera"

function drawPolygon(vertices)
  love.graphics.setColor(210, 150, 175, 120)
  love.graphics.polygon("fill", unpack(vertices))
  love.graphics.setColor(210, 150, 175, 255)
  love.graphics.polygon("line", unpack(vertices))
  love.graphics.polygon("line", unpack(vertices))
end

function drawCircle(x, y, radius)
  love.graphics.setColor(190, 230, 185, 120)
  love.graphics.circle("fill", x, y, radius)
  love.graphics.setColor(190, 230, 185, 255)
  love.graphics.circle("line", x, y, radius)
  love.graphics.circle("line", x, y, radius)
end

function table.clone(org)
  return {table.unpack(org)}
end

function love.load()
  activeX, activeY = love.mouse.getX(), love.mouse.getY()
  activeShapeType = ""
  activeRadius = 0
  activeVertices = {}

  data = {}

  cameraX, cameraY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
  cameraSpeed = 300

  cam = Camera(cameraX, cameraY)

  love.graphics.setBackgroundColor(230, 237, 247)
  gridSize = 32
  viewControls = true
end

function love.draw()
  cam:attach()

  for i=#data, 1, -1 do
    local object = data[i]
    if object.shapeType == "polygon" then
      drawPolygon(unpack(object.vertices))
    elseif object.shapeType == "circle" then
      drawCircle(object.x, object.y, object.radius)
    end
  end

  if viewControls then
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Press '1' for a polygon, '2' for a circle, '3' for a rectangle", 15, 15)
  end

  love.graphics.circle("line", activeX, activeY, 10)

  love.graphics.setColor(10, 10, 10, 255)
  for x = -gridSize*4, gridSize*85, gridSize do
    for y = -gridSize*4, gridSize * 85, gridSize do
      love.graphics.points(x, y)
    end
  end

  if #activeVertices > 4 then
    for i = 1, #activeVertices-3 do
      local current = {activeVertices[i], activeVertices[i+1]}
      local nextOne = {activeVertices[i+2], activeVertices[i+3]}
      love.graphics.line(current[1], current[2], nextOne[1], nextOne[2])
    end
  else
    love.graphics.line(activeVertices[1], activeVertices[2], activeVertices[3], activeVertices[4])
  end

  cam:detach()
end

function love.update(dt)
  cam:lookAt(cameraX, cameraY)

  local x, y = love.mouse.getX(), love.mouse.getY()
  activeX = x - (x % gridSize)
  activeY = y - (y % gridSize)

  if love.keyboard.isDown("right") then
    cameraX = cameraX + cameraSpeed * dt
  elseif love.keyboard.isDown("left") then
    cameraX = cameraX - cameraSpeed * dt
  end
  if love.keyboard.isDown("up") then
    cameraY = cameraY - cameraSpeed * dt
  elseif love.keyboard.isDown("down") then
    cameraY = cameraY + cameraSpeed * dt
  end

  local microcontrol = 20
  if love.keyboard.isDown("pageup") then
    cameraSpeed = cameraSpeed - microcontrol * dt
  elseif love.keyboard.isDown("pagedown") then
    cameraSpeed = cameraSpeed + microcontrol * dt
  end
end

function love.mousepressed(x, y, button)
  if button == 1 then
    activeVertices[#activeVertices+1] = activeX
    activeVertices[#activeVertices+1] = activeY
    print (true)
  end
end

function love.keypressed(key)
  if key == "1" then
    activeShapeType = "polygon"
  elseif key == "2" then
    activeShapeType = "circle"
  elseif key == "3" then
    activeShapeType = "rectangle"
  end

  if key == "return" then
    local object
    if activeShapeType == "circle" then
      table.insert(data, {
        radius = activeRadius,
        x = activeX,
        y = activeY,
        shapeType = activeShapeType
      })
    elseif activeShapeType == "polygon" then
      print("p[", #activeVertices)
      table.insert(data, {
        vertices = table.clone(activeVertices),
        x = activeX,
        y = activeY,
        shapeType = activeShapeType
      })
      for i=#activeVertices, 1, -1 do
        table.remove(activeVertices, i)
      end
    end
  end
end