-- carta unica(check),baralho todo(check),animação baralho único(?),retirar 2 cartas p turno
local love = require "love"
local CARD_WIDTH = 126
local CARD_HEIGHT = 176
local OFFSET_BETWEEN_CARDS = 3  
local CARDS_IN_BARALHO = 10  

-- armazenar todas as cartas
local cards = {}
cards._index = cards

-- Estrutura p/ uma carta
local function criarFundo(x, y)
    return {
        transform = {
            x = x,
            y = y,
            width = CARD_WIDTH,
            height = CARD_HEIGHT,
            sprite = love.graphics.newImage("Carta-Molhada/sprites/fundo carta azul-pitico.png")
        }
    }
end

local function baralhoAzul()

    --posição inicial 
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local startX = screenWidth - CARD_WIDTH
    local startY = screenHeight - CARD_HEIGHT
    
    -- Criar as cartas do baralho
    for i = 0, CARDS_IN_BARALHO-1 do
        -- separação por cima de cada carta
        local offsetY = i * OFFSET_BETWEEN_CARDS
        
        -- Adiciona nova carta ao armazem de cartas
        table.insert(cards, criarFundo(startY - offsetY, startX))
    end
end

local function fundoCarta()
    -- Desenha cada carta usando o mesmo sprite
    -- Ordem invertida para manter a aparência correta do baralho
    for i = #cards, 1, -1 do
        local card = cards[i]
        love.graphics.draw(card.transform.sprite, card.transform.x, card.transform.y)
    end
end

local function posicaoBaralho(dt)
    -- Atualiza a posição do baralho caso a janela seja redimensionada
    if love.window.hasFocus() then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        
        -- Reorganiza todas as cartas mantendo o baralho no canto inferior direito
        for i, card in ipairs(cards) do
            local offsetY = (i-1) * OFFSET_BETWEEN_CARDS
            card.transform.x = screenWidth - CARD_WIDTH 
            card.transform.y = screenHeight - CARD_HEIGHT - offsetY
        end
    end
end
return {
    criarFundo = criarFundo,
    fundoCarta = fundoCarta,
    posicaoBaralho = posicaoBaralho,
    baralhoAzul = baralhoAzul
}