local M = {}


function makeCircle()
    return {radius= 50}
end

function make_random_base()
    H = love.math.random(300, 0.9*LENGTH) 
    points = {
        H/2, H, -- bottom left corner
        0, H,   -- bottom right corner
        0, 0,   -- top left corner
        H/2, 0  -- top right corner
    }
    return points
end

function M.set()
    love.window.setTitle('Blob')
    reference = make_random_base()
    BASE_N = #reference
    player = {}
    for i, k in ipairs(reference) do table.insert(player, k) end
    table.insert(player, reference[#reference-1])
    table.insert(player, reference[#reference-1])

    -- we generate random points along the axe
    N_POINTS = 2 
    y_ = {} 
    for i = 1,N_POINTS do
        table.insert(y_, love.math.random(25, 75)/100.0*H)
    end
    table.sort(y_)
    for i = 1,N_POINTS do
        table.insert(reference, love.math.random(50, 100)/100.0*H)
        table.insert(reference, y_[i])
    end
end

function get()
    return player[#player-1], player[#player]
end

function set(x, y)
    player[#player-1] = x
    player[#player] = y
end

function M.update(dt)
    SPEED = 150 
    if love.keyboard.isDown('lshift') then
        SPEED = 30 
    end
    x, y = get()
    if love.keyboard.isDown("right") then
        x = x + dt*SPEED
    elseif love.keyboard.isDown("left") then
        x = x - dt*SPEED
    elseif love.keyboard.isDown("up") then
        y = y - dt*SPEED
    elseif love.keyboard.isDown("down") then
        y = y + dt*SPEED
    end
    set(x, y)
end

function M.keypressed(key, scancode, isrepeat)
    if scancode == 'rctrl' then
        if #player > BASE_N + 2 then
            table.remove(player)
            table.remove(player)
        end
    end
    if scancode == 'rshift' then
        if #player < BASE_N + 2*N_POINTS then
            P = player
            dx = P[#P-1] - P[#P-3]
            dy = P[#P]   - P[#P-2] 
            scale = 0.5
            new_x = P[#P-1] + scale*dx
            new_y = P[#P]   + scale*dy
            table.insert(player, new_x)
            table.insert(player, new_y) 
        end
    end

end

function M.draw_reference()
    love.graphics.setColor(REFERENCE_COLOR)
    love.graphics.polygon('line', reference)
end

function draw_filled_polygon(polygon)
    -- if the polygon is not convex we have to break it down in triangles to render it correctly
    if love.math.isConvex(polygon) then
        love.graphics.polygon('fill', polygon)
    else
        triangles = love.math.triangulate(polygon)
        for i, triangle in ipairs(triangles) do
            for i, v in ipairs(triangle) do
                love.graphics.polygon('fill', triangle)
            end
        end
    end
end

function M.draw_player()
    love.graphics.setColor(get_player_color())
    if player_state == PLAY then
        if #player==#reference then
            love.graphics.polygon('line', player)
        else
            love.graphics.line(player)
        end
    else
        love.graphics.polygon('line', player)
    end
end

function M.evaluate()
    stats= {
        timestamp=get_timestamp(), 
        reference=reference,
        actual=player,
        diff=diff,
        distance=0,
        normalized_error=0
    }
    canvas = love.graphics.newCanvas(LENGTH, LENGTH)
    love.graphics.setCanvas(canvas)
        love.graphics.setBlendMode('add') -- see https://love2d.org/wiki/BlendMode_Formulas
        love.graphics.clear()
        love.graphics.setColor({ 255, 0, 0, 255})
        draw_filled_polygon(reference)
        love.graphics.setColor({ 0, 255, 0, 255})
        draw_filled_polygon(player)
        data = canvas:newImageData( )
        area_reference = 0
        area_player_only = 0
        area_reference_only = 0
        w = data:getWidth()
        h = data:getHeight()
        total_area = w * h
        for i=H/2, w-1 do
            for j=0, h-1 do
                r, g, b,a = data:getPixel(i , j) 
                if r>0 then area_reference = area_reference + 1 end
                if (r>0) and (g==0) then area_reference_only = area_reference_only + 1 end
                if (r==0) and (g>0) then area_player_only = area_player_only + 1 end
            end
        end
    love.graphics.setCanvas()
    stats.normalized_error = (area_player_only + area_reference_only)/area_reference 
    return stats
end


return M


