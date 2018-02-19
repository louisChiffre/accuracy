M = {}

function M.set()
    love.window.setTitle('Proportion')
    reference_square = make_random_square(50, LENGTH*0.5, 50, LENGTH*0.5)
    sides = {'width', 'height'}
    fixed_side = sides[love.math.random(1,2)]
    print(fixed_side)

    if fixed_side == 'width' then 
        if reference_square.height > reference_square.width then
            reference_square = {height = reference_square.width, width=reference_square.height}
        end
        assert(reference_square.width > reference_square.height)
        player_square = {height=10, width=LENGTH}
    elseif fixed_side == 'height' then 
        if reference_square.height < reference_square.width then
            reference_square = {height = reference_square.width, width=reference_square.height}
        end
        assert(reference_square.height > reference_square.width)
        player_square = {height=LENGTH, width=10}
    else
        assert('Something is wrong')
    end

end

function M.evaluate()
    result = evaluate_square(get_scaled_square(), reference_square)
    result.type = string.format('proportion_%s', fixed_side)
    return result
end

function M.update(dt)
    SPEED = 30 
    if love.keyboard.isDown('lshift') then
        SPEED = 200
    end
    if fixed_side == 'width' then 
        if love.keyboard.isDown("up") then
            player_square.height = player_square.height - dt*SPEED
        elseif love.keyboard.isDown("down") then
            player_square.height = player_square.height + dt*SPEED
        end
    else
        if love.keyboard.isDown("right") then
            player_square.width = player_square.width + dt*SPEED
        elseif love.keyboard.isDown("left") then
            player_square.width = player_square.width - dt*SPEED
        end
    end

end

function get_scaled_square()
    if fixed_side == 'width' then 
        ratio = reference_square.width/player_square.width
    else
        ratio = reference_square.height/player_square.height
    end
    local sqr = {width=player_square.width*ratio, height=player_square.height*ratio}
    return setmetatable(sqr, metasquare)
end

function M.draw_reference()
    love.graphics.setColor(REFERENCE_COLOR)
    love.graphics.rectangle("line", REFERENCE_POSITION.x, REFERENCE_POSITION.y, reference_square.width, reference_square.height)
end

function M.draw_player()
    state2square = {PLAY=player_square, EVALUATE=get_scaled_square()}
    actual_square = state2square[player_state]
    love.graphics.setColor(get_player_color())
    love.graphics.rectangle("line", REFERENCE_POSITION.x, REFERENCE_POSITION.y , actual_square.width, actual_square.height)
end

return M

