local love = require "love"
local CARD_WIDTH = 134
local CARD_HEIGHT = 176       
-- Fundo das cartas de conflito
local conflito = {
        transform = {
            x = 0,
            y = 0,
            width = CARD_WIDTH,
            height = CARD_HEIGHT,
            sprite= love.graphics.newImage("sprites/FUNDO CARTA VERMELHA.png")
        }
    }

local function fundoConflito()
    love.graphics.draw(conflito.transform.sprite, conflito.transform.x, conflito.transform.y)
end
return {fundoConflito = fundoConflito}
-- Efeito das cartas de conflito

-- local lista_conflitos{}