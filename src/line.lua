local M={}



function M.set()
    love.window.setTitle('Line')
    reference_line = {
        angle = love.math.random(0, 360)/360.0 * 2 * math.pi,
        length = love.math.random(50, LENGTH*0.5)
    } 
    player_line = {
        angle = normalize_angle(reference_line.angle + love.math.random(-30, 30)/360.0 * 2 * math.pi),
        length = LENGTH * 0.4
    }
end

local CENTER = {x=LENGTH*0.5, y=LENGTH*0.5}

function normalize_angle(angle)
    if angle < 0 then
        angle = 2*math.pi + angle
    end
    if angle > 2*math.pi then
        angle = angle - 2*math.pi
    end
    return angle
end

function M.update(dt)
    SPEED = 30 
    if love.keyboard.isDown('lshift') then
        SPEED = 200
    end
    ANGLE_FACTOR = 0.01 
    if love.keyboard.isDown("right") then
        player_line.length = player_line.length + dt*SPEED
    elseif love.keyboard.isDown("left") then
        player_line.length = player_line.length - dt*SPEED
    elseif love.keyboard.isDown("up") then
        player_line.angle = player_line.angle - dt*SPEED * ANGLE_FACTOR 
    elseif love.keyboard.isDown("down") then
        player_line.angle = player_line.angle + dt*SPEED * ANGLE_FACTOR
    end
    player_line.angle = normalize_angle(player_line.angle)
end

function draw_line(line)
    x = CENTER.x + math.cos(line.angle)*line.length
    y = CENTER.y + math.sin(line.angle)*line.length

    love.graphics.line(CENTER.x, CENTER.y, x, y)
    love.graphics.circle("line", x, y, 2)
end

function M.draw_reference()
    love.graphics.setColor(REFERENCE_COLOR)
    draw_line(reference_line)
end

function M.draw_player()
    love.graphics.setColor(get_player_color())
    draw_line(player_line)
end

function M.evaluate()
    dlength = math.abs(player_line.length-reference_line.length)/reference_line.length
    dangle = math.abs(player_line.angle-reference_line.angle)/(0.5*math.pi)
    stats= {
        timestamp=get_timestamp(), 
        type="line",
        reference=reference_line,
        actual=player_line,
        normalized_error=math.sqrt(dlength^2 + dangle^2)
    }
    return stats
    
end


return M



