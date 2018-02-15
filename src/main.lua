function get_stats()
    filename = FILENAME
    local json = require "json"
    if love.filesystem.exists(filename) then
        txt = love.filesystem.read(filename)
        stats = json.decode(txt) 
    else
        print("no stats available")
        stats = {}
    end
    return stats
end

function save(result)
    local json = require "json"
    stats = get_stats()
    filename = FILENAME
    if result == nil then
        print("nothing to save")
        return
    end
    stats[#stats+1] = result
    print(string.format("%s values saved", #stats))
    --print(string.format('%s %-10s %-10s', result.timestamp, result.distance, result.type))
    -- for key,value in ipairs(stats) do print(string.format('%s %-10s %-10s', value.timestamp ,value.distance, value.type)) end
    --bitser.dumpLoveFile(filename, stats)
    txt=json.encode(stats)
    love.filesystem.write(filename, txt, string.len(txt))
end
function update_circle(dt)
    SPEED = 30 
    if love.keyboard.isDown('lshift') then
        SPEED = 200
    end
    if love.keyboard.isDown("right") then
        player_circle.radius = player_circle.radius + dt*SPEED
    elseif love.keyboard.isDown("left") then
        player_circle.radius = player_circle.radius - dt*SPEED
    end
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
function update_proportion(dt)
    SPEED = 30 
    if love.keyboard.isDown('lshift') then
        SPEED = 200
    end
    if love.keyboard.isDown("up") then
        player_square.height = player_square.height - dt*SPEED
    elseif love.keyboard.isDown("down") then
        player_square.height = player_square.height + dt*SPEED
    end
end

function update_noop(dt)
end

function set_square()
    print("set square")
    reference_square = makeRandomSquare()
    player_square = makeSquare()
end

function set_circle()
    print("set circle")
    reference_circle = makeRandomCircle()
    player_circle = makeCircle()
end

function set_proportion()
    print("set proportion")
    reference_square = makeRandomSquare()
    if reference_square.height > reference_square.width then
        reference_square = {height = reference_square.width, width=reference_square.width}
    end
    player_square = {height=10, width=SIZE}
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
    REFERENCE_COLOR = WHITE
    state2color = {PLAY=WHITE, EVALUATE=RED}
    state2next =  {PLAY=EVALUATE, EVALUATE=PLAY}

    SQUARE='SQUARE'
    CIRCLE='CIRCLE'
    PROPORTION='PROPORTION'

    local circle = require 'circle'

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
        },
        PROPORTION={
            SET=set_proportion,
            UPDATE={EVALUATE=update_noop, PLAY=update_proportion},
            DRAW=draw_proportion,
            EVALUATE=evaluate_proportion,
        }}
    TYPES_LIST = {SQUARE, CIRCLE, PROPORTION}

    player_state = 'PLAY'
    TRAINING_TYPE = SQUARE
    state_init()
end

function state_init()
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
    return {radius= love.math.random(50, 0.4*SIZE)}
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
    num = tonumber(scancode)
    if num==nil then
        return
    end
    type_ = TRAINING_TYPE
    TRAINING_TYPE=TYPES_LIST[num]
    if TRAINING_TYPE==nil then
        TRAINING_TYPE=type_
        return
    end
    state_init()
end
function show()
    stats = get_stats()
    for key,m in pairs(stats) do 
        print(string.format('%s %s', m.type, m.normalized_error))
    end
end
function get_timestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end
function evaluate_proportion()
end

function evaluate_circle()
    
    diff = player_circle.radius - reference_circle.radius
    area = function(circle) return 3.1427*(circle.radius^2) end
    stats= {
        timestamp=get_timestamp(), 
        type="circle",
        reference=reference_circle,
        actual=player_circle,
        diff=diff,
        distance=math.abs(diff),
        normalized_error=math.abs(area(player_circle)-area(reference_circle))/area(reference_circle)
    }
    if stats.diff > 0 then
        print(string.format("Radius too wide by %s pixels", stats.diff))  
    else
        print(string.format("Radius too narrow by %s pixels", stats.diff))  
    end
    print(string.format("error %s %%", math.floor(stats.normalized_error*100))) 
    return stats
end

function evaluate_square()
    diff = player_square - reference_square
    stats= {
        timestamp=get_timestamp(),
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
    love.graphics.setColor(REFERENCE_COLOR)
    love.graphics.rectangle("line", REFERENCE_POSITION.x, REFERENCE_POSITION.y, reference_square.width, reference_square.height)
    pos = state2pos[player_state]
    love.graphics.translate(pos.x, pos.y)
    love.graphics.setColor(state2color[player_state])
    love.graphics.rectangle("line", REFERENCE_POSITION.x, REFERENCE_POSITION.y , player_square.width, player_square.height)
end

function draw_proportion()
    state2pos =   {PLAY={x=SIZE, y=SIZE}, EVALUATE=REFERENCE_POSITION}
    love.graphics.setColor(REFERENCE_COLOR)
    love.graphics.rectangle("line", REFERENCE_POSITION.x, REFERENCE_POSITION.y, reference_square.width, reference_square.height)
    ratio = reference_square.width/player_square.width
    scaled_player_square = {width=reference_square.width, height=player_square.height*ratio}
    state2square = {PLAY=player_square, EVALUATE=scaled_player_square}
    actual_square = state2square[player_state]
    pos = state2pos[player_state]
    love.graphics.translate(pos.x, pos.y)
    love.graphics.setColor(state2color[player_state])
    love.graphics.rectangle("line", REFERENCE_POSITION.x, REFERENCE_POSITION.y , actual_square.width, actual_square.height)
end

function draw_circle()
    state2pos =   {PLAY={x=SIZE*1.5, y=SIZE*1.5}, EVALUATE={x=SIZE*0.5, y=SIZE*0.5}}
    love.graphics.setColor(REFERENCE_COLOR)
    pos_ref = state2pos[EVALUATE]
    love.graphics.circle("line", pos_ref.x, pos_ref.y, reference_circle.radius)
    color = state2color[player_state]
    pos = state2pos[player_state]
    love.graphics.setColor(color) -- reset colours
    love.graphics.circle("line", pos.x, pos.y , player_circle.radius)
end


function love.update(dt)
    TYPES[TRAINING_TYPE].UPDATE[player_state](dt)
end


function love.draw()
    TYPES[TRAINING_TYPE].DRAW()
end
