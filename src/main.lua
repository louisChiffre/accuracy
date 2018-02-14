function save(result)
    filename = FILENAME
    local json = require "json"
    if love.filesystem.exists(filename) then
        txt = love.filesystem.read(filename)
        stats = json.decode(txt) 
    else
        print("no stats available")
        stats = {}
    end
    stats[#stats+1] = result
    --print(string.format('%s %-10s %-10s', result.timestamp, result.distance, result.type))
    -- for key,value in ipairs(stats) do print(string.format('%s %-10s %-10s', value.timestamp ,value.distance, value.type)) end
    --bitser.dumpLoveFile(filename, stats)
    txt=json.encode(stats)
    love.filesystem.write(filename, txt, string.len(txt))
end


function update_square(dt)
    SPEED = 30 
    if love.keyboard.isDown('lshift') then
        SPEED = 200
    end
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

function set_circle()
    reference_circle = makeRandomCircle()
    player_circle = makeCircle()
end

function love.load()
    FILENAME = "stats.json"
    --normalize()
    BORDER = 10
    WIDTH, HEIGHT = love.graphics.getDimensions( )
    SIZE = math.floor((math.min(WIDTH, HEIGHT)-BORDER)/2)
    RED = {255, 0,0}
    WHITE = {255, 255,255 }
    PLAY='PLAY'
    EVALUATE='EVALUATE'
    REFERENCE_POSITION ={x=1,y=1}
    state2color = {PLAY=WHITE, EVALUATE=RED}
    state2next =  {PLAY=EVALUATE, EVALUATE=PLAY}

    SQUARE='SQUARE'
    TRAINING_TYPE = SQUARE

    TYPES = {
        SQUARE={
            SET=set_square,
            UPDATE={EVALUATE=update_noop, PLAY=update_square},
            DRAW=draw_square,
            EVALUATE=evaluate_square,
        },
        CIRCLE={
            SET=set_circle,
            UPDATE={EVALUATE=update_noop, PLAY=update_circle},
            DRAW=draw_circle,
            EVALUATE=evaluate_circle,
        }
    }

    --state2update = {EVALUATE=update_noop, PLAY=update_square}
    player_state = 'PLAY'
    TYPES[TRAINING_TYPE].SET()
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

function makeRandomCircle()
    return {radius= love.math.random(50, SIZE)}
end

function makeSquare()
    sqr= { height = 50 ,width = 50}
    setmetatable(sqr, metasquare)
    return sqr
end

function makeCircle()
    return {radius= 50}
end


function love.keypressed( key, scancode, isrepeat )
    if scancode == "s" then
        show()
    end

    if scancode == "space" then
        if player_state == PLAY then
            result=TYPES[TRAINING_TYPE].EVALUATE()
            save(result)
            player_state = EVALUATE
        elseif player_state == EVALUATE then
            TYPES[TRAINING_TYPE].SET()
            player_state = PLAY
        end
    end
end
function show()
    filename = FILENAME
    local bitser = require "bitser"
    assert(love.filesystem.exists(filename))
    stats = bitser.loadLoveFile(filename)
    for key,m in pairs(stats) do 
        --print(string.format('%s,%s', key, ds/s )) 
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
    m = stats
    ds = m.reference.width * math.abs(m.actual.height - m.reference.height) +
        m.reference.height * math.abs(m.actual.width - m.reference.width) 
    s = m.reference.width * m.reference.height
    stats.normalized_error =  ds/s
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
    print(string.format("error %s %%", math.floor(stats.normalized_error*100))) 

    print(string.format("%s: diff width/height %s/%s. Distance %s",  
        stats.timestamp,
        math.floor(stats.diff.width),
        math.floor(stats.diff.height),
        math.floor(stats.distance))
        )
   return stats 
end

function draw_square()
    state2pos =   {PLAY={x=SIZE, y=SIZE}, EVALUATE=REFERENCE_POSITION}
    love.graphics.setColor(WHITE)
    love.graphics.rectangle("line", 1, 1, reference_square.width, reference_square.height)
    color = state2color[player_state]
    pos = state2pos[player_state]
    love.graphics.setColor(color) -- reset colours
    love.graphics.rectangle("line", pos.x, pos.y , player_square.width, player_square.height)
end


function love.update(dt)
    TYPES[TRAINING_TYPE].UPDATE[player_state](dt)
end


function love.draw()
    TYPES[TRAINING_TYPE].DRAW()
end
