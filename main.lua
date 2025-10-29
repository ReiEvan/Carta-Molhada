circuloTamanho = 50
quadradoTamanho = 50

function love.draw()
    --Circulo vermelho
    love.graphics.setColor(1,0,0)
    love.graphics.circle("fill",200,200,circuloTamanho)

    --Circulo verde
    love.graphics.setColor(0,1,0)
    love.graphics.circle("fill",600,200,circuloTamanho)

    --Quadrado branco
    love.graphics.setColor(144,144,144)
    love.graphics.rectangle("fill", 500,200,quadradoTamanho,quadradoTamanho)


    --Cursor do mouse
   -- love.graphics.print('Eixo X do mouse:' ,love.mouse.getX() ,"Eixo Y do mouse:",love.mouse.getY(), " !")
   -- end

function love.update(dt)



end