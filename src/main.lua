function get_stats()
    filename = FILENAME
    local JSON = require "JSON"
    if love.filesystem.exists(filename) then
        txt = love.filesystem.read(filename)
        stats = JSON:decode(txt) 
    else
        print("no stats available")
        stats = {}
    end
    return stats
end

function get_system_id()
   local name, version, vendor, device = love.graphics.getRendererInfo( ) 
   local wwidth, wheight, flags = love.window.getMode()
   local width, height = love.window.getDesktopDimensions(flags.display)
   local scale = love.window.getPixelScale( )
   return string.format('%s %sx%s %s %sx%s', version, width, height, scale, wwidth, wheight)
end

function save(result)
    if result == nil then
        print("nothing to save")
        return
    end
    local JSON = require "JSON"
    result.system_id = get_system_id()
    stats = get_stats()
    filename = FILENAME
    stats[#stats+1] = result
    --for key,value in ipairs(stats) do
    --    value.system_id = result.system_id 
    --end
    print(string.format("%s values saved", #stats))
    --print(string.format('%s %-10s %-10s', result.timestamp, result.distance, result.type))
    -- for key,value in ipairs(stats) do print(string.format('%s %-10s %-10s', value.timestamp ,value.distance, value.type)) end
    --bitser.dumpLoveFile(filename, stats)
    --JSON = assert(loadfile "JSON.lua")()
    txt = JSON:encode_pretty(stats)
    -- print(JSON:encode_pretty(result))
    love.filesystem.write(filename, txt, string.len(txt))
end





function update_noop(dt)
end


function love.load()
    FILENAME = "stats.json"
    --normalize()
    BORDER = 10
    WIDTH, HEIGHT = love.graphics.getDimensions( )
    LENGTH = math.floor((math.min(WIDTH, HEIGHT)-BORDER)/2)
    RED = {255, 0,0}
    WHITE = {255, 255,255 }
    PLAY='PLAY'
    EVALUATE='EVALUATE'

    REFERENCE_POSITION ={x=1,y=1}
    PLAYER_POSITION = {x=LENGTH, y=LENGTH} 
    STATE2POS = {PLAY=PLAYER_POSITION, EVALUATE=REFERENCE_POSITION}


    REFERENCE_COLOR = WHITE
    state2color = {PLAY=WHITE, EVALUATE=RED}
    state2next =  {PLAY=EVALUATE, EVALUATE=PLAY}


    local circle = require('circle')
    local square = require('square')
    local proportion = require('proportion')
    local line = require('line')

    
    TRAINING_TYPES = {square, circle, proportion, line}

    player_state = 'PLAY'
    TRAINING_TYPE = square
    state_init()
end

function state_init()
    player_state = 'PLAY'
    TRAINING_TYPE.set()
end

metasquare = {}
function metasquare.__sub(s1, s2)
  s = {}
  s.width = s1.width - s2.width
  s.height= s1.height - s2.height 
  return s
end

function make_random_square(min_height, max_height, min_width, max_width)
    assert(min_height <= max_height)
    assert(min_width <= max_width)
    sqr={
        height = love.math.random(min_height, max_height),  
        width = love.math.random(min_width, max_height)}
    setmetatable(sqr, metasquare)
    return sqr

end

function evaluate_square(player_square, reference_square)
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

function love.keypressed( key, scancode, isrepeat )
    if scancode == "s" then
        show()
    end

    if scancode == "space" then
        if player_state == PLAY then
            result=TRAINING_TYPE.evaluate()
            save(result)
            player_state = EVALUATE
        elseif player_state == EVALUATE then
            TRAINING_TYPE.set()
            player_state = PLAY
        end
    end
    num = tonumber(scancode)
    if num==nil then
        return
    end
    if TRAINING_TYPES[num]~= nil then
        TRAINING_TYPE = TRAINING_TYPES[num]
        state_init()
    end
end





function love.update(dt)
    if player_state == PLAY then
        TRAINING_TYPE.update(dt)
    else
        update_noop()
    end
end

function translate_viewport()
    pos = STATE2POS[player_state]
    love.graphics.translate(pos.x, pos.y)
end

function love.draw()
    TRAINING_TYPE.draw_reference()
    translate_viewport()
    TRAINING_TYPE.draw_player()
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

function get_player_color()
    return state2color[player_state]
end
