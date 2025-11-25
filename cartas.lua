-- carta unica(check),baralho todo(check),animação baralho único(?),retirar 2 cartas p turno
local love = require "love"

-----------------------------------------------------
-- CONFIGURAÇÕES GERAIS
-----------------------------------------------------
local CARD_WIDTH = 126
local CARD_HEIGHT = 176
local OFFSET_BETWEEN_CARDS = 3  
local CARDS_IN_BARALHO = 10  

local HOVER_OFFSET = 12   -- quanto a carta sobe no hover

-----------------------------------------------------
-- BARALHO AZUL (NÃO INTERFERE COM AS CARTAS DA RODADA)
-----------------------------------------------------
local baralho = {}

local function criarFundo(x, y)
    return {
        transform = {
            x = x,
            y = y,
            width = CARD_WIDTH,
            height = CARD_HEIGHT,
            sprite = love.graphics.newImage("sprites/fundo carta azul-pitico.png")
        }
    }
end

local function construirBaralho()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local startX = screenWidth - CARD_WIDTH
    local startY = screenHeight - CARD_HEIGHT
    
    for i = 0, CARDS_IN_BARALHO - 1 do
        local offsetY = i * OFFSET_BETWEEN_CARDS      
        table.insert(baralho, criarFundo(startY - offsetY, startX))
    end
end

local function desenharBaralho()
    for i = #baralho, 1, -1 do
        local card = baralho[i]
        love.graphics.draw(card.transform.sprite, card.transform.x, card.transform.y)
    end
end

local function reposicionarBaralho()
    if love.window.hasFocus() then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        
        for i, card in ipairs(baralho) do
            local offsetY = (i - 1) * OFFSET_BETWEEN_CARDS
            card.transform.x = screenWidth - CARD_WIDTH
            card.transform.y = screenHeight - CARD_HEIGHT - offsetY
        end
    end
end

-----------------------------------------------------
-- CARTAS ALIADAS (INTERATIVAS)
-----------------------------------------------------
local todasAliadas = {
    {
        img = love.graphics.newImage("sprites/carta nascente.png"),
        descricao = "Carta da Nascente\nGanhe 2 águas."
    },

    {
        img = love.graphics.newImage("sprites/carta 8 clarividencia.png"),
        descricao = 
        "Clarividência\nDescubra qual será o\n".. 
        "conflito do próximo turno."
    },

    {
        img = love.graphics.newImage("sprites/carta mov livre.png"),
        descricao =
            "Movimento Livre\n" ..
            "Use esta carta para se \n".. 
            "mover para qualquer espaço\n".. 
            "sem gastar uma ação\n" ..
            "(mantendo a regra de \n".. 
            "movimento padrão"
    },

    {
        img = love.graphics.newImage("sprites/carta dourada.png"),
        descricao =
            "Carta Dourada\n" ..
            "Escolha uma área verde\n".. 
            "(exceto o ponto de origem).\n" ..
            "Ela não pode ser perdida \n".. 
            "por cartas de conflito,\n" ..
            "exceto se restar apenas ela\n".. 
            "e o ponto de origem."
    }
}

local cartasRodada = {}
local hoverIndex = nil

-----------------------------------------------------
-- SORTEIO DE CARTAS DA RODADA
-----------------------------------------------------
local function selecionarCartasRodada()
    cartasRodada = {}

    local copia = {}
    for i = 1, #todasAliadas do
        copia[i] = todasAliadas[i]
    end

    for i = #copia, 2, -1 do
        local j = love.math.random(1, i)
        copia[i], copia[j] = copia[j], copia[i]
    end

    cartasRodada[1] = copia[1]
    cartasRodada[2] = copia[2]
end

-----------------------------------------------------
-- DETECTAR HOVER
-----------------------------------------------------
local function atualizarInteracaoCartas(dt)
    hoverIndex = nil

    local mx, my = love.mouse.getPosition()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local totalWidth = (CARD_WIDTH * 2) + 30
    local startX = (screenWidth - totalWidth) / 2
    local posY = screenHeight * 0.70

    for i = 1, 2 do
        local x = startX + (i - 1) * (CARD_WIDTH + 30)
        local y = posY

        if mx > x and mx < x + CARD_WIDTH
        and my > y and my < y + CARD_HEIGHT then
            hoverIndex = i
        end
    end
end

-----------------------------------------------------
-- DESENHAR AS CARTAS DA RODADA (COM DESCRIÇÃO À ESQ/DIR E TÍTULO COLORIDO)
-----------------------------------------------------
local function desenharCartasRodada()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local totalWidth = (CARD_WIDTH * 2) + 30
    local startX = (screenWidth - totalWidth) / 2
    local posY = screenHeight * 0.70

    for i = 1, 2 do
        local card = cartasRodada[i]

        local x = startX + (i - 1) * (CARD_WIDTH + 30)
        local y = posY

        local offset = (hoverIndex == i) and -HOVER_OFFSET or 0

        -- desenhar carta
        love.graphics.draw(card.img, x, y + offset)

        -- descrição somente da carta com hover
        if hoverIndex == i then
            local texto = card.descricao

            local textoX
            if i == 1 then
                textoX = x - 220
            else
                textoX = x + CARD_WIDTH + 20
            end

            --------------------------------------------------------
            -- 🔵 Separar título (1ª linha) e corpo do texto
            --------------------------------------------------------
            local titulo, corpo = texto:match("([^\n]+)\n?(.*)")

            -- 🎨 desenhar o título colorido
            love.graphics.setColor(0.2, 0.4, 1, 1)
            love.graphics.printf(
                titulo,
                textoX,
                y + offset + 20,
                300
            )

            -- reset da cor
            love.graphics.setColor(1, 1, 1, 1)

            -- desenhar corpo abaixo
            if corpo ~= nil and corpo ~= "" then
                love.graphics.printf(
                    corpo,
                    textoX,
                    y + offset + 40,
                    300
                )
            end
        end
    end
end

-----------------------------------------------------
-- RETORNO DO MÓDULO
-----------------------------------------------------
return {
    -- baralho azul
    construirBaralho = construirBaralho,
    desenharBaralho = desenharBaralho,
    reposicionarBaralho = reposicionarBaralho,

    -- cartas interativas
    selecionarCartasRodada = selecionarCartasRodada,
    atualizarInteracaoCartas = atualizarInteracaoCartas,
    desenharCartasRodada = desenharCartasRodada
}
