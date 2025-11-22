local love = require "love"
local CARD_WIDTH = 134
local CARD_HEIGHT = 176       
local cardSprite
-- Fundo das cartas de conflito
local card = {
        transform = {
            x = 0,
            y = 0,
            width = CARD_WIDTH,
            height = CARD_HEIGHT
        }
    }

function love.load()
    -- Carregar o sprite único
    cardSprite = love.graphics.newImage("Carta-Molhada/sprites/FUNDO CARTA VERMELHA.png")

function love.draw()
    
    love.graphics.draw(cardSprite, card.transform.x, card.transform.y)
    end
end
-- Efeito das cartas de conflito

-- local lista_conflitos{}