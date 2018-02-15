local M = {}

function makeCircle()
    return {radius= 50}
end

function makeRandomCircle()
    return {radius= love.math.random(50, 0.4*SIZE)}
end

function M.set()
    love.window.setTitle('Circle')
    reference_circle = makeRandomCircle(SIZE)
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
    state2pos =   {PLAY={x=SIZE*1.5, y=SIZE*1.5}, EVALUATE={x=SIZE*0.5, y=SIZE*0.5}}
    love.graphics.setColor(REFERENCE_COLOR)
    pos_ref = state2pos[EVALUATE]
    love.graphics.circle("line", pos_ref.x, pos_ref.y, reference_circle.radius)
    color = state2color[player_state]
    pos = state2pos[player_state]
    love.graphics.setColor(color) -- reset colours
    love.graphics.circle("line", pos.x, pos.y , player_circle.radius)
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


