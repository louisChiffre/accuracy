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

function M.draw()
    CIRCLE_CENTER = {x=LENGTH*0.5, y=LENGTH*0.5}

    love.graphics.setColor(REFERENCE_COLOR)
    love.graphics.circle("line", CIRCLE_CENTER.x, CIRCLE_CENTER.y, reference_circle.radius)

    pos = STATE2POS[player_state]
    love.graphics.translate(pos.x, pos.y)
    love.graphics.setColor(state2color[player_state])
    love.graphics.circle("line", CIRCLE_CENTER.x, CIRCLE_CENTER.y, player_circle.radius)

end

function M.evaluate()
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


return M


