local M = {}

function makeCircle()
    return {radius= 50}
end

function makeRandomCircle()
    return {radius= love.math.random(50, 0.4*LENGTH)}
end

function M.set()
    love.window.setTitle('Circle')
    reference_circle = makeRandomCircle(LENGTH)
    player_circle = makeCircle()
end

function M.update(dt)
    SPEED = 15 
    if love.keyboard.isDown('lshift') then
        SPEED = 200
    end
    if love.keyboard.isDown("right") then

        player_circle.radius = player_circle.radius + dt*SPEED
    elseif love.keyboard.isDown("left") then
        player_circle.radius = player_circle.radius - dt*SPEED
    end
end




local CIRCLE_CENTER = {x=LENGTH*0.5, y=LENGTH*0.5}

function M.mousemoved( x, y, dx, dy, istouch )
    if player_state == PLAY then
        x, y = mouse2world(x, y)
        local radius =math.sqrt((x-CIRCLE_CENTER.x)^2 + (y-CIRCLE_CENTER.y)^2)
        if radius < LENGTH * 0.5 then
            player_circle.radius = radius 
            love.mouse.setVisible(false)
        else
            love.mouse.setVisible(true)
        end
    end
end

function M.draw_reference()
    love.graphics.setColor(REFERENCE_COLOR)
    love.graphics.circle("line", CIRCLE_CENTER.x, CIRCLE_CENTER.y, reference_circle.radius)
end

function M.draw_player()
    love.graphics.setColor(get_player_color())
    love.graphics.circle("line", CIRCLE_CENTER.x, CIRCLE_CENTER.y, player_circle.radius)
end

function M.evaluate()
    diff = player_circle.radius - reference_circle.radius
    area = function(circle) return math.pi * (circle.radius^2) end
    stats= {
        timestamp=get_timestamp(), 
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
    return stats
end


return M


