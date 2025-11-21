-- carta unica(check),baralho todo(check),animação baralho único(?),retirar 2 cartas p turno
local love = require "love"
local CARD_WIDTH = 126
local CARD_HEIGHT = 176
local OFFSET_BETWEEN_CARDS = 3  
local CARDS_IN_BARALHO = 10     

-- armazenar todas as cartas
local cards = {}

-- Estrutura p/ uma carta
local function createCard(x, y)
    return {
        transform = {
            x = x,
            y = y,
            width = CARD_WIDTH,
            height = CARD_HEIGHT
        },
        dragging = false
    }
end

function love.load()
    -- Carregar o sprite único
    cardSprite = love.graphics.newImage("fundo carta azul-pitico.png")

    
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
        table.insert(cards, createCard(startY - offsetY, startX))
    end
end

function love.draw()
    -- Limpa a tela com a cor de fundo
    love.graphics.clear(0.937, 0.945, 0.96, 1)
    
    -- Desenha cada carta usando o mesmo sprite
    -- Ordem invertida para manter a aparência correta do baralho
    for i = #cards, 1, -1 do
        local card = cards[i]
        love.graphics.draw(cardSprite, card.transform.x, card.transform.y)
    end
end

function love.update(dt)
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