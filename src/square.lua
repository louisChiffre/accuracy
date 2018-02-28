local M = {}
function makeRandomSquare()
    return make_random_square(50, LENGTH, 50, LENGTH)
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
    SPEED = 20 
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

function M.mousemoved( x, y, dx, dy, istouch )
    if player_state == PLAY then
        width, height = mouse2world(x, y)
        if is_mouse_in_player_space(width, height) then
            player_square.width = width
            player_square.height = height
            love.mouse.setVisible(false)
        else
            love.mouse.setVisible(true)
        end
    end
end

function M.evaluate()
    return evaluate_square(player_square, reference_square)
end

function M.draw_reference()
    love.graphics.setColor(REFERENCE_COLOR)
    love.graphics.rectangle("line", 0, 0,  reference_square.width, reference_square.height)
end

function M.draw_player()
    love.graphics.setColor(get_player_color())
    love.graphics.rectangle("line", 0, 0 , player_square.width, player_square.height)
end

return M

