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

function table.flatten(arr)
  local result = { }
  
  local function flatten(arr)
    for _, v in ipairs(arr) do
      if type(v) == "table" then
        flatten(v)
      else
        table.insert(result, v)
      end
    end
  end
  
  flatten(arr)
  return result
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

function vec2(x, y)
  return {x = x, y = y}
end

function verticesList(activeVertices)
  local result = {}

  for i = #activeVertices, 1, -1 do
    local vec = activeVertices[i]
    table.insert(result, vec.x)
    table.insert(result, vec.y)
  end

  return result
end

local function loadSavedFile()
  io.write("Do you want to load an existing file? y/n \n")
  local fileToLoad
  local loadExistingFile = io.read()
  if string.lower(loadExistingFile) == "y" or string.lower(loadExistingFile) == "yes" then
    io.write("Enter name of an existing file: ")
    fileToLoad = io.read()
    fileToLoad = string.find(fileToLoad, ".lua") and fileToLoad or fileToLoad .. ".lua"
    assert(love.filesystem.exists(fileToLoad))
  end
  return fileToLoad
end

function love.load()
  activeX, activeY = love.mouse.getX(), love.mouse.getY()
  activeShapeType = "polygon"
  activeClickerRadius = 8
  activeDeleteIndex = -1
  activeRadius = 0
  activeVertices = {}
  selectedShape = -1

  activeShape = false
  hoveringOnShape = false
  wantToLoad = false

  -- data = table.load("level.lua")

  local fileToLoad
  if wantToLoad then
    fileToLoad = loadSavedFile()
  end
  data = fileToLoad ~= nil and table.load(fileToLoad) or {}
  shapes = {}
  if #data > 0 then
    local n = #data[1]
    for i = 1, #data do
      shapes[#shapes+1] = love.physics.newPolygonShape(data[i].vertices)
      print("new polygon: ", inspect(data[i].vertices))
    end
  end


  cameraScale = 1
  cameraX, cameraY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
  cameraSpeed = 300

  cam = Camera(cameraX, cameraY)

  love.graphics.setBackgroundColor(230, 237, 247)
  gridSize = 32
  gridWidth = 60
  gridHeight = 60
  viewControls = false

  shapeColors = {0, 0, 0}
end


local selected = {230, 140, 0}
local normal = {0, 0, 190}

local function drawOutlinedPolygon(color1, color2, vertices)
  if color2 == nil then
    color2 = color1
  end

  love.graphics.setColor(color1[1], color1[2], color1[3], 65)
  love.graphics.polygon("fill", vertices)
  love.graphics.setColor(color2[1], color2[2], color2[3], 255)
  love.graphics.polygon("line", vertices)
end

function love.draw()
  cam:attach()

  activeShape = false
  activeDeleteIndex = -1
  for i=#shapes, 1, -1 do
    local shape = shapes[i]
    local x, y = activeX, activeY
    if shape:testPoint(0, 0, 0, x, y) and selectedShape ~= i then
      activeDeleteIndex = i
      activeShape = true
      drawOutlinedPolygon(selected, nil, table.flatten(data[i].vertices))
    elseif selectedShape == i then
      drawOutlinedPolygon({160,25,230}, nil, table.flatten(data[selectedShape].vertices))
    else
      drawOutlinedPolygon(normal, nil, table.flatten(data[i].vertices))
    end
  end

  love.graphics.circle("line", activeX, activeY, activeClickerRadius)

  love.graphics.setColor(10, 10, 10, 85)
  for x = 0, gridSize * gridWidth, gridSize do
    for y = 0, gridSize * gridHeight, gridSize do
      love.graphics.circle("line", x, y, 3)
    end
  end

  love.graphics.setColor(0, 0, 0, 255)
  if #activeVertices > 2 then
    for i = #activeVertices, 1, -1 do
      local current, nextOne
      local vec = activeVertices[i]
      if i + 1 > #activeVertices then
        current = vec
        nextOne = activeVertices[1]
      else
        current = vec
        nextOne = activeVertices[i+1]
      end

      if current and nextOne then
        love.graphics.line(current.x, current.y, nextOne.x, nextOne.y)
      end
    end
  elseif #activeVertices == 2 then
    love.graphics.line(activeVertices[1].x, activeVertices[1].y, activeVertices[#activeVertices].x, activeVertices[#activeVertices].y)
  end

  for i = #activeVertices, 1, -1 do
    local verticeRadius = 8
    love.graphics.setColor(0, 235, 80, 130)
    love.graphics.circle("fill", activeVertices[i].x, activeVertices[i].y, verticeRadius)
    love.graphics.setColor(0, 235, 80, 245)
    love.graphics.circle("line", activeVertices[i].x, activeVertices[i].y, verticeRadius)
  end

  cam:detach()

  if viewControls then
    love.graphics.setColor(255, 255, 255, 155)
    love.graphics.rectangle("fill", 0, 0, 490, 130)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Press 'W A S D' to move the camera around \n" ..
    "Press 'q' to zoom out and 'e' to zoom in \n" ..
    "Press 'c' to increase camera speed and 'z' to decrease camera speed \n" ..
    "Press LEFT CLICK to add polygon point \n" ..
    "Press 'space' to add a polygon to the leve \n" ..
    "Press RIGHT CLICK to select a polygon \n" ..
    "Press 'r' remove the last placed point, or a selected polygon \n" ..
    "Press 'm' to minimize this box", 15, 15)
  else
    love.graphics.setColor(255, 255, 255, 155)
    love.graphics.rectangle("fill", 0, 0, 275, 48)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Press 'm' to open the controls list", 15, 15)
  end
end

local clickerTheta = 0
local clickerThetaStep = math.pi / 2
function love.update(dt)

  cam:zoomTo(cameraScale)

  -- Cursor radius manipulation
  activeClickerRadius = math.abs(8 * math.sin(clickerTheta)) + 8
  clickerTheta = clickerTheta + clickerThetaStep * dt

  -- Ensure camera coords are whole numbers
  cameraX, cameraY = math.ceil(cameraX), math.ceil(cameraY)

  cam:lookAt(cameraX, cameraY)

  -- Translating cursor to become grid-locked
  local x, y = cam:worldCoords(love.mouse.getX(), love.mouse.getY())
  local xr, yr = (x % gridSize), (y % gridSize)
  activeX = xr >= gridSize / 2 and x - (xr) + gridSize or x - (xr)
  activeY = yr >= gridSize / 2 and y - (yr) + gridSize or y - (yr)

  -- Camera movement
  if love.keyboard.isDown("d") then
    cameraX = cameraX + cameraSpeed * dt
  elseif love.keyboard.isDown("a") then
    cameraX = cameraX - cameraSpeed * dt
  end
  if love.keyboard.isDown("w") then
    cameraY = cameraY - cameraSpeed * dt
  elseif love.keyboard.isDown("s") then
    cameraY = cameraY + cameraSpeed * dt
  end


  -- Camera speed control
  local microcontrol = 100
  if love.keyboard.isDown("z") then
    cameraSpeed = cameraSpeed - microcontrol * dt > 0 and cameraSpeed - microcontrol * dt or 0
    print("camera speed has been updated to: " .. tostring(cameraSpeed))
  elseif love.keyboard.isDown("c") then
    cameraSpeed = cameraSpeed + microcontrol * dt < 1000 and cameraSpeed + microcontrol * dt or 1000
    print("camera speed has been updated to: " .. tostring(cameraSpeed))
  end

  -- Camera scale control
  local scalecontrol = 1
  if love.keyboard.isDown("q") then
    cameraScale = cameraScale - scalecontrol * dt < .8 and .8 or cameraScale - scalecontrol * dt
    print("camera scale has been updated to: " .. tostring(cameraScale))
  elseif love.keyboard.isDown("e") then
    cameraScale = cameraScale + scalecontrol * dt > 2 and 2 or cameraScale + scalecontrol * dt
    print("camera scale has been updated to: " .. tostring(cameraScale))
  end
end

function love.mousepressed(x, y, button)
  if button == 1 and activeShapeType == "polygon" then
    local found = false
    for i = 1, #activeVertices do
      if activeVertices[i].x == activeX and activeVertices[i].y == activeY then
        found = true
      end
    end

    if not found then
      activeVertices[#activeVertices+1] = vec2(activeX, activeY)
    else
      print("there is already a vertice at that coordinate")
    end
  end
  if button == 2 then
    if selectedShape > 0 then
      selectedShape = -1
    end
    if activeShape then
      selectedShape = activeDeleteIndex
    end
  end
end

function love.mousereleased(x, y, button)
  if button == 1 and activeShapeType == "circle" then
    activeRadius = math.sqrt(math.pow(activeX - (x - x % gridSize), 2) + math.pow(activeY - (y - y % gridSize), 2))
  end
end

--[[
Recursive save function
]]

local n = 0
local saved = false
local function saveNewFile(path)
  n = n + 1
  local fnString = path .. tostring(n)

  if love.filesystem.exists(fnString) then
    print(fnString .. " already exists!")
    saveNewFile(path)
  end

  completePath = string.find(fnString, ".lua") and fnString or fnString .. ".lua"
  if not love.filesystem.exists(completePath) and not saved then
    table.save(data, completePath)
    print("data has been saved to " .. fnString .. "!")
  else
    saveNewFile(path)
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
    if #activeVertices > 0 then
      table.remove(activeVertices, #activeVertices)
    end
    if selectedShape > 0 then
      table.remove(data, selectedShape)
      table.remove(shapes, selectedShape)
      selectedShape = -1
    end
  end

  if key == "space" then
    local object
    local targetX, targetY = cam:worldCoords(activeX, activeY)
    if activeShapeType == "circle" then
      table.insert(data, {
        radius = activeRadius,
        x = activeX,
        y = activeY,
        shapeType = activeShapeType
      })
    elseif activeShapeType == "polygon" and #activeVertices > 2 then
      shapes[#shapes+1] = love.physics.newPolygonShape(verticesList(activeVertices))
      print("new polygon: ", inspect(verticesList(activeVertices)))
      table.insert(data, {
        vertices = verticesList(activeVertices),
        shapeType = activeShapeType
      })
      for i=#activeVertices, 1, -1 do
        table.remove(activeVertices, i)
      end
    end
  end

  if key == "p" then
    saveNewFile("level")
  end

  if key == "m" then
    viewControls = not viewControls
  end
end