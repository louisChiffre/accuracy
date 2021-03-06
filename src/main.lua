INFO = {}
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
    print(string.format("error %s %%", math.floor(result.normalized_error*100))) 
    if result == nil then
        print("nothing to save")
        return
    end
    local JSON = require "JSON"
    result.system_id = get_system_id()
    stats = get_stats()
    filename = FILENAME
    stats[#stats+1] = result
    print(string.format("%s values saved", #stats))
    txt = JSON:encode_pretty(stats)
    --print(JSON:encode_pretty(result))
    love.filesystem.write(filename, txt, string.len(txt))
end


function update_noop(dt)
end


function love.load()
    set_info('Session Started')
    FILENAME = "stats.json"
    print(string.format('File will be saved in directory %s',
        love.filesystem.getSaveDirectory()))
    BORDER = 10
    WIDTH = 640
    HEIGHT = 640

    LENGTH = math.floor((math.min(WIDTH, HEIGHT)-BORDER)/2)
    RED = {255, 0,0}
    WHITE = {255, 255,255 }
    PLAY='PLAY'
    EVALUATE='EVALUATE'
    IS_RANDOM=false
    HAS_DEBUG_BOX = false
    --font = love.graphics.newFont('VeraMono.ttf')
    --love.graphics.setFont(font)


    REFERENCE_ORIGIN ={x=3,y=3}
    PLAYER_ORIGIN = {x=LENGTH, y=LENGTH} 
    STATS_ORIGIN = {x=REFERENCE_ORIGIN.x, y=LENGTH}

    TEXT_HEIGHT = 15


    REFERENCE_COLOR = WHITE
    state2color = {PLAY=WHITE, EVALUATE=RED}
    state2next =  {PLAY=EVALUATE, EVALUATE=PLAY}


    TRAINING_TYPES = {}
    TRAINING_TYPES_NAMES =   {'circle', 'blob', 'square', 'proportion'}
    for i ,training_type in ipairs(TRAINING_TYPES_NAMES) do
        TRAINING_TYPES[i] = require(training_type)
        TRAINING_TYPES[i].name = training_type -- to be able to add type to result
    end

    player_state = 'PLAY'
    TRAINING_TYPE = TRAINING_TYPES[1]
    initialize_state()

    initialize_running_stats()


end

function initialize_state()
    player_state = 'PLAY'
    shuffle_player_position()
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

function get_randome_training_type()
    return TRAINING_TYPES[love.math.random(1, #TRAINING_TYPES)]
end

function compute_running_stats(values, value)
    local stats = require('stats')
    if values == nil then
        values = {}
    end
    table.insert(values, value)
    return {
        median=stats.median(values),
        mean=stats.mean(values)
    } 

end

function initialize_running_stats()
    -- initialize stats
    STATS = {counter=0}
    STATS.list = {}
    STATS.normalized_errors = {}
    STATS.normalized_errors_stats = {}
    STATS.types = {}
    for i ,training_type in ipairs(TRAINING_TYPES_NAMES) do
        STATS.normalized_errors[training_type] = {}
        STATS.normalized_errors_stats[training_type] = {}
    end
    STATS.normalized_errors['all'] = {}
    STATS.normalized_errors_stats['all'] = {}
end


function update_running_stats(result)
    STATS.counter = STATS.counter+1
    table.insert(STATS.list, 1, result)
    STATS.normalized_errors_stats[result.type] =  
        compute_running_stats(STATS.normalized_errors[result.type], result.normalized_error)
    STATS.normalized_errors_stats['all'] =  
        compute_running_stats(STATS.normalized_errors['all'], result.normalized_error)
    STATS.last = result
end

function love.mousemoved( x, y, dx, dy, istouch )
    if TRAINING_TYPE['mousemoved'] then 
        TRAINING_TYPE.mousemoved( x, y, dx, dy, istouch )
    end
end

function love.mousepressed( x, y, button, istouch )
    if TRAINING_TYPE['mousepressed'] then 
        TRAINING_TYPE.mousepressed( x, y, button, istouch )
    else
        if button==LEFT_CLICK_BUTTON then
            start()
        end
    end
end

function start()
    if player_state == PLAY then
        result = TRAINING_TYPE.evaluate()
        result.type = TRAINING_TYPE.name
        update_running_stats(result)
        save(result)
        player_state = EVALUATE
    elseif player_state == EVALUATE then
        if IS_RANDOM then
            TRAINING_TYPE = get_randome_training_type()
        end
        initialize_state()
    end
end

function love.keypressed( key, scancode, isrepeat )
    if scancode == "s" then
        show()
    end

    if scancode == "r" then
        if IS_RANDOM then
            IS_RANDOM = false
            set_info('Random mode disabled')
        else
            IS_RANDOM = true
            set_info('Random mode enabled')
        end
    end

    -- if keypressed is available call it
    if TRAINING_TYPE.keypressed ~=nil then
        TRAINING_TYPE.keypressed(key, scancode, isrepeat)
    end


    if scancode == "space" then
        start()
    end

    num = tonumber(scancode)
    if num~=nil then
        if TRAINING_TYPES[num]~= nil then
            TRAINING_TYPE = TRAINING_TYPES[num]
            IS_RANDOM = true
            initialize_state()
        end
        return
    end
end





function love.update(dt)
    if player_state == PLAY then
        TRAINING_TYPE.update(dt)
    else
        update_noop()
    end
end


function love.quit()
    print('done')
end

function set_player_viewport()
    if player_state == PLAY then 
        love.graphics.translate(PLAYER_ORIGIN.x, PLAYER_ORIGIN.y)
    else
        set_reference_viewport()
    end
end

function set_reference_viewport()
    love.graphics.translate(REFERENCE_ORIGIN.x, REFERENCE_ORIGIN.y)
end

function set_stats_viewport()
    love.graphics.translate(STATS_ORIGIN.x, STATS_ORIGIN.y)
end


function set_fps_viewport()
    w, h = love.graphics.getDimensions()
    love.graphics.translate(w - 60, 20)
end

function set_info_viewport()
    w, h = love.graphics.getDimensions()
    love.graphics.translate(w/2, 20)
end

function shuffle_player_position()
    w, h = love.graphics.getDimensions()
    PLAYER_ORIGIN = {
        x = love.math.random(LENGTH, w - LENGTH),
        y = love.math.random(LENGTH, h - LENGTH)
    }
end

function love.draw()

    set_info_viewport()
    draw_info()
    love.graphics.origin()

    set_fps_viewport()
    love.graphics.print('FPS:'..tostring(love.timer.getFPS( )), 1, 1)
    love.graphics.origin()

    function draw_box()
        if HAS_DEBUG_BOX then
            love.graphics.rectangle("line", 0, 0, LENGTH, LENGTH)
        end    
    end    


    set_reference_viewport()
    TRAINING_TYPE.draw_reference()
    draw_box()
    love.graphics.origin()

    set_player_viewport()
    TRAINING_TYPE.draw_player()
    draw_box()
    love.graphics.origin()

    love.graphics.setColor(REFERENCE_COLOR)
    set_stats_viewport()
    draw_stats()
    love.graphics.origin()

end


function draw_stats()
    MAX_STATS = 5 
    COLUMN_SIZE = 150 
    results = STATS.list
    n = #results
    
    row = 1
    love.graphics.print('LOGS', 1, row * TEXT_HEIGHT)
    row = row +1
    love.graphics.print('TYPE', 1, row * TEXT_HEIGHT)
    love.graphics.print('ERROR', COLUMN_SIZE, row * TEXT_HEIGHT)
    row = row + 1
    for i, k in ipairs(results) do
        if i <= MAX_STATS then
            num = n + 1 - i
            love.graphics.print(string.format('%s %-20s', num , k.type), 1, row * TEXT_HEIGHT)
            love.graphics.print(string.format('%.1f', 100*k.normalized_error), COLUMN_SIZE, row * TEXT_HEIGHT)
            row = row + 1
        end
    end
    row = row + 2 
    love.graphics.print('STATS', 1, row * TEXT_HEIGHT)
    love.graphics.print('MEDIAN', COLUMN_SIZE, row * TEXT_HEIGHT)
    row = row +1
    for _, training_type in ipairs(TRAINING_TYPES_NAMES) do
        s = STATS.normalized_errors_stats[training_type]
        love.graphics.print(training_type, 1, row * TEXT_HEIGHT)
        if s.median ~=nil then
            love.graphics.print(string.format('%.1f', 100*s.median), COLUMN_SIZE, row * TEXT_HEIGHT)
        end
        row = row + 1

    end
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

function mouse2world(x,y )
    return x - PLAYER_ORIGIN.x, y - PLAYER_ORIGIN.y
end
function world2mouse(x,y )
    return x + PLAYER_ORIGIN.x, y + PLAYER_ORIGIN.y
end

function is_mouse_in_player_space(x, y)
    return (x < 1.5*LENGTH) and 
            (y < 1.5*LENGTH) and
            (y > -0.5*LENGTH) and
            (x > -0.5*LENGTH)
end


function set_info(txt)
    INFO = {txt=txt, timestamp=love.timer.getTime()}
end

function draw_info(txt)
    if INFO.txt then
        love.graphics.print(INFO.txt)
    end
end

