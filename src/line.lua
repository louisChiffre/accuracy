local M={}



function M.set()
    love.window.setTitle('Line')
    reference_line = {
        angle = love.math.random(0, 360)/360.0 * 2 * math.pi,
        length = love.math.random(50, LENGTH*0.5)
    } 
    angle = normalize_angle(reference_line.angle + love.math.random(-30, 30)/360.0 * 2 * math.pi)
    length = LENGTH * 0.4
    player_vector = {
        dx = length * math.cos(angle),
        dy = length * math.sin(angle)
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
    if love.keyboard.isDown("right") then
        player_vector.dx = player_vector.dx + dt*SPEED
    elseif love.keyboard.isDown("left") then
        player_vector.dx = player_vector.dx - dt*SPEED
    elseif love.keyboard.isDown("up") then
        player_vector.dy = player_vector.dy - dt*SPEED
    elseif love.keyboard.isDown("down") then
        player_vector.dy = player_vector.dy + dt*SPEED
    end

end

function draw_line(line)
    x = CENTER.x + math.cos(line.angle)*line.length
    y = CENTER.y + math.sin(line.angle)*line.length

    love.graphics.line(CENTER.x, CENTER.y, x, y)
end

function M.draw_reference()
    love.graphics.setColor(REFERENCE_COLOR)
    draw_line(reference_line)
end

function M.draw_player()
    love.graphics.setColor(get_player_color())
    love.graphics.line(CENTER.x, CENTER.y, CENTER.x + player_vector.dx, CENTER.y + player_vector.dy)
end

function cartesian2radial(vector)
    return {
        length = math.sqrt(vector.dx^2 + vector.dy^2),
        angle =  math.atan2(vector.dy, vector.dx)
    }
end

function M.evaluate()
    player_line = cartesian2radial(player_vector)
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



