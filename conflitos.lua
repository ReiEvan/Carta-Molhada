local love = require "love"
local cartas = require "cartas"

----------------------------------
-- FUNÇÃO DE SINCRONIZAÇÃO COM O MAIN
----------------------------------
local adicionarAgua = nil
local function setAdicionarAgua(func)
    adicionarAgua = func
end

cartas.setAdicionarAgua(adicionarAgua)

----------------------------------
-- TAMANHO DAS CARTAS
----------------------------------
local CARD_WIDTH = 134
local CARD_HEIGHT = 176

----------------------------------
-- FUNDO DA CARTA DE CONFLITO
----------------------------------
local fundoConflito = love.graphics.newImage("sprites/FUNDO CARTA VERMELHA.png")

----------------------------------
-- LISTA DE CONFLITOS
----------------------------------
local todosConflitos = {
    {
        id = "Bomba d'agua quebrou",
        img = love.graphics.newImage("sprites/conflitos/bomba dagua quebrou.png"),
        descricao = "Perca 2 fichas de água",
        efeito = function()
            if adicionarAgua then adicionarAgua(-2) end
        end
    },
    {
        id = "Incendio criminoso",
        img = love.graphics.newImage("sprites/conflitos/incendio criminoso.png"),
        descricao = "Perca uma área verde que não tenha um guarda"
    },
    {
        id = "Dia quente de trabalho",
        img = love.graphics.newImage("sprites/conflitos/dia quente de trabalho.png"),
        descricao = "Os guardas gastaram 2 águas ao invés de 1 e o número de ações cai em 1"
    },
    {
        id = "Guarda inoperante",
        img = love.graphics.newImage("sprites/conflitos/Guarda inoperante.png"),
        descricao = "Um dos guardas ficará inoperante até o fim dessa rodada (ele não gasta água)"
    },
    {
        id = "Sabotagem",
        img = love.graphics.newImage("sprites/conflitos/sabotagem.png"),
        descricao = "Sua próxima carta de Aliados será anulada"
    },
    {
        id = "A carta cinza",
        img = love.graphics.newImage("sprites/conflitos/A carta cinza.png"),
        descricao = "Perca 2 áreas verdes"
    }
}

----------------------------------
-- VARIÁVEL DO CONFLITO ATUAL
----------------------------------
local conflitoAtual = nil

----------------------------------
-- EMBARALHAR
----------------------------------
local function embaralhar(t)
    for i = #t, 2, 1 do
        local j = love.math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

----------------------------------
-- SELECIONAR CONFLITO
----------------------------------
local function selecionarConflito()
    embaralhar(todosConflitos)
    conflitoAtual = todosConflitos[1]

    -- aplica efeito se existir
    if conflitoAtual and conflitoAtual.efeito then
        conflitoAtual.efeito()
    end
end

----------------------------------
-- DESENHAR DESCRIÇÃO
----------------------------------
local function desenharDescricao(c, x, y)
    local largura, altura = 220, 90
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x, y, largura, altura, 8)

    -- título vermelho
    love.graphics.setColor(1, 0, 0)
    love.graphics.print(c.id, x + 10, y + 10)

    -- descrição branca
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(c.descricao, x + 10, y + 34)
end

----------------------------------
-- DRAW
----------------------------------
local function draw()
    if not conflitoAtual then return end

    local x, y = 40, 40  -- canto superior esquerdo

    -- fundo vermelho
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(fundoConflito, x, y)

    -- imagem do conflito
    love.graphics.draw(conflitoAtual.img, x, y)

    -- descrição ao lado da carta
    desenharDescricao(conflitoAtual, x + CARD_WIDTH + 20, y)
end

----------------------------------
-- RETORNO DO MÓDULO
----------------------------------
return {
    selecionar = selecionarConflito,
    draw = draw,
    setAdicionarAgua = setAdicionarAgua
}
