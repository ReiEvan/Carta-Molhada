largura = love.graphics.getWidth()
altura = love.graphics.getHeight()
mouseX = love.mouse.getX()
mouseY = love.mouse.getY()


function love.update(dt)
    mouseX = love.mouse.getX() - largura / 2
    mouseY = love.mouse.getY() - altura / 2
    end
end

function love.draw()
    love.graphics.setColor(0,0,1)
    love.graphics.print("Esse é o ponto X: "mouseX" e esse é o ponto Y: "mouseY, mouseX, mouseY)
end
