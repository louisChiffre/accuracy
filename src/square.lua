local M = {}
function makeRandomSquare()
    return make_random_square(50, SIZE, 50, SIZE)
end

function makeSquare()
    return make_random_square(50, 50, 50, 50)
end
function M.set()
    love.window.setTitle('Square')
    reference_square = makeRandomSquare()
    player_square = makeSquare()
end


function M.update(dt)
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

function M.evaluate()
    return evaluate_square(player_square, reference_square)
end

function M.draw()
    state2pos =   {PLAY={x=SIZE, y=SIZE}, EVALUATE=REFERENCE_POSITION}
    love.graphics.setColor(REFERENCE_COLOR)
    love.graphics.rectangle("line", REFERENCE_POSITION.x, REFERENCE_POSITION.y, reference_square.width, reference_square.height)
    pos = state2pos[player_state]
    love.graphics.translate(pos.x, pos.y)
    love.graphics.setColor(state2color[player_state])
    love.graphics.rectangle("line", REFERENCE_POSITION.x, REFERENCE_POSITION.y , player_square.width, player_square.height)
end


return M
