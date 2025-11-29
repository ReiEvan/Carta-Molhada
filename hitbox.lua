local love = require "love"

local hit = {}

function hit.desenhar(x, y, raio)

    r = 1
    g = 0
    b = 1

            love.graphics.setColor(r,g,b,"0")
            love.graphics.circle("fill", x, y, raio)
            love.graphics.setColor(255,255,255)
            
end

return hit