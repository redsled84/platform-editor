local inspect = require "inspect"
local Camera = require "camera"

-- declare local variables
--// exportstring( string )
--// returns a "Lua" portable version of the string
local function exportstring( s )
  return string.format("%q", s)
end

--// The Save Function
function table.save(  tbl,filename )
  local charS,charE = "   ","\n"
  local file,err = io.open( filename, "wb" )
  if err then return err end

  -- initiate variables for save procedure
  local tables,lookup = { tbl },{ [tbl] = 1 }
  file:write( "return {"..charE )

  for idx,t in ipairs( tables ) do
     file:write( "-- Table: {"..idx.."}"..charE )
     file:write( "{"..charE )
     local thandled = {}

     for i,v in ipairs( t ) do
        thandled[i] = true
        local stype = type( v )
        -- only handle value
        if stype == "table" then
           if not lookup[v] then
              table.insert( tables, v )
              lookup[v] = #tables
           end
           file:write( charS.."{"..lookup[v].."},"..charE )
        elseif stype == "string" then
           file:write(  charS..exportstring( v )..","..charE )
        elseif stype == "number" then
           file:write(  charS..tostring( v )..","..charE )
        end
     end

     for i,v in pairs( t ) do
        -- escape handled values
        if (not thandled[i]) then
        
           local str = ""
           local stype = type( i )
           -- handle index
           if stype == "table" then
              if not lookup[i] then
                 table.insert( tables,i )
                 lookup[i] = #tables
              end
              str = charS.."[{"..lookup[i].."}]="
           elseif stype == "string" then
              str = charS.."["..exportstring( i ).."]="
           elseif stype == "number" then
              str = charS.."["..tostring( i ).."]="
           end
        
           if str ~= "" then
              stype = type( v )
              -- handle value
              if stype == "table" then
                 if not lookup[v] then
                    table.insert( tables,v )
                    lookup[v] = #tables
                 end
                 file:write( str.."{"..lookup[v].."},"..charE )
              elseif stype == "string" then
                 file:write( str..exportstring( v )..","..charE )
              elseif stype == "number" then
                 file:write( str..tostring( v )..","..charE )
              end
           end
        end
     end
     file:write( "},"..charE )
  end
  file:write( "}" )
  file:close()
end

--// The Load Function
function table.load( sfile )
  local ftables,err = loadfile( sfile )
  if err then return _,err end
  local tables = ftables()
  for idx = 1,#tables do
     local tolinki = {}
     for i,v in pairs( tables[idx] ) do
        if type( v ) == "table" then
           tables[idx][i] = tables[v[1]]
        end
        if type( i ) == "table" and tables[i[1]] then
           table.insert( tolinki,{ i,tables[i[1]] } )
        end
     end
     -- link indices
     for _,v in ipairs( tolinki ) do
        tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
     end
  end
  return tables[1]
end

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
  return {unpack(org)}
end

function love.load()
  activeX, activeY = love.mouse.getX(), love.mouse.getY()
  activeShapeType = "polygon"
  activeRadius = 0
  activeVertices = {}
  clicks = {}

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
      drawPolygon(object.vertices)
    elseif object.shapeType == "circle" then
      drawCircle(object.x, object.y, object.radius)
    end
  end

  if viewControls then
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Press '1' for a polygon, '2' for a circle", 15, 15)
  end

  love.graphics.circle("line", activeX, activeY, 10)

  love.graphics.setColor(10, 10, 10, 255)
  for x = -gridSize*4, gridSize*85, gridSize do
    for y = -gridSize*4, gridSize * 85, gridSize do
      love.graphics.points(x, y)
    end
  end

  if #activeVertices > 4 then
    for i = 2, #activeVertices, 2 do
      local current, nextOne
      if i + 2 > #activeVertices then
        current = {activeVertices[i-1], activeVertices[i]}
        nextOne = {activeVertices[1], activeVertices[2]}
      else
        current = {activeVertices[i-1], activeVertices[i]}
        nextOne = {activeVertices[i+1], activeVertices[i+2]}
      end

      if current and nextOne then
        love.graphics.line(current[1], current[2], nextOne[1], nextOne[2])
      end
    end
  else
    love.graphics.line(activeVertices[1], activeVertices[2], activeVertices[#activeVertices-1], activeVertices[#activeVertices])
  end

  for i = 2, #activeVertices, 2 do
    local verticeRadius = 3
    love.graphics.setColor(0, 235, 80, 130)
    love.graphics.circle("fill", activeVertices[i-1], activeVertices[i], verticeRadius)
    love.graphics.setColor(0, 235, 80, 245)
    love.graphics.circle("line", activeVertices[i-1], activeVertices[i], verticeRadius)
  end

  cam:detach()
end

function love.update(dt)
  cameraX, cameraY = math.ceil(cameraX), math.ceil(cameraY)
  cam:lookAt(cameraX, cameraY)

  local x, y = cam:worldCoords(love.mouse.getX(), love.mouse.getY())
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
  if love.keyboard.isDown("pagedown") then
    cameraSpeed = cameraSpeed - microcontrol * dt
    print (cameraSpeed)
  elseif love.keyboard.isDown("pageup") then
    cameraSpeed = cameraSpeed + microcontrol * dt
    print (cameraSpeed)
  end
end

function love.mousepressed(x, y, button)
  if button == 1 and activeShapeType == "polygon" then
    activeVertices[#activeVertices+1] = activeX
    activeVertices[#activeVertices+1] = activeY
  end
end

function love.mousereleased(x, y, button)
  if button == 1 and activeShapeType == "circle" then
    activeRadius = math.sqrt(math.pow(activeX - (x - x % gridSize), 2) + math.pow(activeY - (y - y % gridSize), 2))
  end
end

function love.keypressed(key)
  if key == "1" then
    activeShapeType = "polygon"
  elseif key == "2" then
    activeShapeType = "circle"
  end

  if key == "escape" then
    love.event.quit()
  elseif key == "r" then
    love.event.quit("restart")
  end

  if key == "return" then
    local object
    local targetX, targetY = cam:worldCoords(activeX, activeY)
    if activeShapeType == "circle" then
      table.insert(data, {
        radius = activeRadius,
        x = activeX,
        y = activeY,
        shapeType = activeShapeType
      })
    elseif activeShapeType == "polygon" then
      print("p[", inspect(table.clone(activeVertices)))
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

  if key == "p" then
    if love.filesystem.exists("level.lua") then
      table.save(data, "level.lua")
      print("data has been saved to level.lua!")
    else
      print("level.lua has not been created!")
    end
  end
end