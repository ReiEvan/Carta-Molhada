--[[circuloTamanho = 50
quadradoTamanho = 50
textoDoMouse = 0



function love.draw()
    --Circulo vermelho
    love.graphics.setColor(1,0,0)
    love.graphics.circle("fill",200,200,circuloTamanho)

    --Circulo verde
    love.graphics.setColor(0,1,0)
    love.graphics.circle("fill",600,200,circuloTamanho)

    --cursor do mouse
    love.graphics.setColor(0,0,1)
    love.graphics.print(

--[[function love.draw(jogador)
    --Quadrado branco
    love.graphics.setColor(144,144,144)
    love.graphics.rectangle("fill", 500,200,quadradoTamanho,quadradoTamanho)


    --Cursor do mouse
   -- love.graphics.print('Eixo X do mouse:' ,love.mouse.getX() ,"Eixo Y do mouse:",love.mouse.getY(), " !")
   end

function love.load()
    cursor = love.mouse.getSystemCursor("hand")
end

function love.mousepressed(x, y, button)
    if button == 1 then
        love.mouse.setCursor(cursor)
    
    end
end

function love.mousereleased(x, y, button)
        if button == 1 then
            love.mouse.setCursor()
    end
end

function love.update(dt)


end]]
