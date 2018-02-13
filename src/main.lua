function save(result)
    filename = "stats.bin"
    print(string.format("saving results to %s", filename))
    local bitser = require "bitser"
    if love.filesystem.exists(filename) then
        stats = bitser.loadLoveFile(filename)
    else
        print("no stats available")
        stats = {}
    end
    stats[result.timestamp] = result
    print(string.format('%s %-10s %-10s', result.timestamp, result.distance, result.type))
    --for key,value in pairs(stats) do print(string.format('%s %-10s %-10s', key,value.distance, value.type)) end
    bitser.dumpLoveFile(filename, stats)
end

function update_square(dt)
    SPEED = 50
    if love.keyboard.isDown("right") then
        player_square.width = player_square.width + dt*SPEED
    elseif love.keyboard.isDown("left") then
        player_square.width = player_square.width - dt*SPEED
    elseif love.keyboard.isDown("up") then
        player_square.height = player_square.height - dt*SPEED
    elseif love.keyboard.isDown("down") then
        player_square.height = player_square.height + dt*SPEED
    end
end

function update_noop(dt)
end

function set_square()
    reference_square = makeRandomSquare()
    player_square = makeSquare()
end

function love.load()
    BORDER = 10
    WIDTH, HEIGHT = love.graphics.getDimensions( )
    SIZE = math.floor((math.min(WIDTH, HEIGHT)-BORDER)/2)
    RED = {255, 0,0}
    WHITE = {255, 255,255 }
    PLAY='PLAY'
    EVALUATE='EVALUATE'
    --Drawing stuff
    --love.graphics.setColor(255,255,255) -- reset colours
    state2color = {PLAY=WHITE, EVALUATE=RED}
    state2pos =   {PLAY={x=SIZE, y=SIZE}, EVALUATE={x=1,y=1}}
    state2next =  {PLAY=EVALUATE, EVALUATE=PLAY}
    state2update = {EVALUATE=update_noop, PLAY=update_square}

    player_state = 'PLAY'
    set_square()
end

metasquare = {}
function metasquare.__sub(s1, s2)
  s = {}
  s.width = s1.width - s2.width
  s.height= s1.height - s2.height 
  return s
end

function makeRandomSquare()
    sqr={
        height = love.math.random(50, SIZE),  
        width = love.math.random(50, SIZE)}
    setmetatable(sqr, metasquare)
    return sqr
end

function makeSquare()
    sqr= { height = 50 ,width = 50}
    setmetatable(sqr, metasquare)
    return sqr
end



function love.keypressed( key, scancode, isrepeat )
    if scancode == "space" then
        if player_state == PLAY then
            result=evaluate_square()
            save(result)
            player_state = EVALUATE
        elseif player_state == EVALUATE then
            set_square()
            player_state = PLAY
        end
    end
end

function evaluate_square()
    diff = player_square - reference_square
    stats= {
        timestamp=os.date("%Y-%m-%d %H:%M:%S"),
        type="rectangle",
        reference=reference_square,
        actual=player_square,
        diff=diff,
        distance=math.sqrt(diff.width^2 + diff.height^2)
    }
    if stats.diff.width > 0 then
        print(string.format("Rectangle too wide by %s pixels", stats.diff.width))  
    else
        print(string.format("Rectangle too narrow by %s pixels", stats.diff.width))  
    end
    if stats.diff.height > 0 then
        print(string.format("Rectangle too high by %s pixels", stats.diff.height))  
    else
        print(string.format("Rectangle too short by %s pixels", stats.diff.height))  
    end

    print(string.format("%s: diff width/height %s/%s. Distance %s",  
        stats.timestamp,
        math.floor(stats.diff.width),
        math.floor(stats.diff.height),
        math.floor(stats.distance))
        )
   return stats 
end


function love.update(dt)
    state2update[player_state](dt)
end

function draw_square()
    love.graphics.setColor(WHITE)
    love.graphics.rectangle("line", 1, 1, reference_square.width, reference_square.height)
    color = state2color[player_state]
    pos = state2pos[player_state]
    love.graphics.setColor(color) -- reset colours
    love.graphics.rectangle("line", pos.x, pos.y , player_square.width, player_square.height)
end

function love.draw()
    draw_square()
end
