local love = require "love"

local todasAliadas = {
    {
        id = "Super Eficiente",
        img = love.graphics.newImage("sprites/carta super eficiente.png"),
        descricao = "Comece esta rodada com 1 ação a mais."
    },

    {
        id = "Carta da Nascente",
        img = love.graphics.newImage("sprites/carta nascente.png"),
        descricao = "Ganhe 2 águas.",
        efeito = function()
            adicionarAgua(2)
        end
    },

    {
        id = "Clarividência",
        img = love.graphics.newImage("sprites/carta 8 clarividencia.png"),
        descricao = "Descubra qual será o conflito do próximo turno."
    },

    {
        id = "Movimento Livre",
        img = love.graphics.newImage("sprites/carta mov livre.png"),
        descricao =
            "Use esta carta para se\n" ..
            "mover para qualquer espaço\n" ..
            "sem gastar uma ação\n" ..
            "(mantendo a regra de movimento padrão)"
    },

    {
        id = "Carta Dourada",
        img = love.graphics.newImage("sprites/carta dourada.png"),
        descricao =
            "Escolha uma área verde\n" ..
            "(exceto o ponto de origem).\n" ..
            "Ela não pode ser perdida\n" ..
            "por cartas de conflito."
    },

    {
        id = "Dissolvendo problemas",
        img = love.graphics.newImage("sprites/carta Dissolvendo problemas.png"),
        descricao =
            "Gaste 2 águas e anule\n" ..
            "os conflitos da rodada."
    },

    {
        id = "Esforço recompensado",
        img = love.graphics.newImage("sprites/carta Esforco recompensado.png"),
        descricao =
            "\nSe tiver 3 áreas verdes,\n" ..
            "ganhe 3 fichas de água."
    },

    {
        id = "Procurando água",
        img = love.graphics.newImage("sprites/carta Procurando agua.png"),
        descricao =
            "Troque 1 ação por 1 ficha de água\n(até o limite de 3)",
        efeito = function()
            adicionarAgua(1)
        end
    }
}

---------------------------------------------------------
-- FUNÇÕES DE SINCRONIZAÇÃO COM O MAIN
---------------------------------------------------------
local adicionarAgua = nil

function setAdicionarAgua(func)
    adicionarAgua = func
end

---------------------------------------------------------
-- CONFIGURAÇÕES GERAIS
---------------------------------------------------------

local CARD_WIDTH = 140
local CARD_HEIGHT = 185
local OFFSET_BETWEEN_CARDS = 3

local baralho = {}
local descarte = {}
local contadorBaralho = #todasAliadas

local HOVER_OFFSET = 120

local cartasRodada = {}
local hoverIndex = nil

local cartaSelecionada = nil
local efeitoDaCarta = nil
local escolhaBloqueada = false

---------------------------------------------------------
-- FUNÇÃO DE EFEITO UNIVERSAL
---------------------------------------------------------

local function aplicarEfeito(carta)
    if carta.efeito then
        carta.efeito()
    end
end

---------------------------------------------------------
-- GERAR FUNDO DAS CARTAS DO BARALHO
---------------------------------------------------------
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

---------------------------------------------------------
-- MONTAR BARALHO VISUAL
---------------------------------------------------------
local function construirBaralho()
    baralho = {}
    contadorBaralho = #todasAliadas

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local startX = w - CARD_WIDTH
    local startY = h - CARD_HEIGHT

    for i = 0, contadorBaralho - 1 do
        local offsetY = i * OFFSET_BETWEEN_CARDS
        table.insert(baralho, criarFundo(startY - offsetY, startX))
    end
end

---------------------------------------------------------
-- REPOSICIONAR BARALHO NA TELA
---------------------------------------------------------
local function reposicionarBaralho()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    for i, card in ipairs(baralho) do
        local offsetY = (i - 1) * OFFSET_BETWEEN_CARDS
        card.transform.x = w - CARD_WIDTH
        card.transform.y = h - CARD_HEIGHT - offsetY
    end
end

---------------------------------------------------------
-- DESENHAR BARALHO
---------------------------------------------------------
local function desenharBaralho()
    for i = #baralho, 1, -1 do
        local c = baralho[i]
        love.graphics.draw(c.transform.sprite, c.transform.x, c.transform.y)
    end

    if #baralho > 0 then
        local cx = baralho[#baralho].transform.x - 65
        local cy = baralho[#baralho].transform.y + 173
        love.graphics.print("Cartas: " .. contadorBaralho, cx, cy)
    end
end

---------------------------------------------------------
-- SISTEMA DE COMPRAR CARTA
---------------------------------------------------------
local function puxarCartaGarantido()
    if #todasAliadas == 0 then
        for i = 1, #descarte do
            table.insert(todasAliadas, descarte[i])
        end
        descarte = {}
        construirBaralho()
    end

    local copia = {}
    for i = 1, #todasAliadas do copia[i] = todasAliadas[i] end

    for i = #copia, 2, -1 do
        local j = love.math.random(1, i)
        copia[i], copia[j] = copia[j], copia[i]
    end

    local carta = copia[1]

    for i = #todasAliadas, 1, -1 do
        if todasAliadas[i] == carta then
            table.insert(descarte, carta)
            table.remove(todasAliadas, i)
            break
        end
    end

    if #baralho > 0 then
        table.remove(baralho, 1)
        contadorBaralho = math.max(0, contadorBaralho - 1)
    end

    return carta
end

---------------------------------------------------------
-- PEGAR 2 CARTAS DA RODADA
---------------------------------------------------------
local function selecionarCartasRodada()
    cartasRodada = {}
    cartaSelecionada = nil
    escolhaBloqueada = false
    efeitoDaCarta = nil

    cartasRodada[1] = puxarCartaGarantido()
    cartasRodada[2] = puxarCartaGarantido()
end

---------------------------------------------------------
-- HOVER
---------------------------------------------------------
local function atualizarInteracaoCartas()
    hoverIndex = nil

    local mx, my = love.mouse.getPosition()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    local totalWidth = (CARD_WIDTH * 2) + 30
    local startX = (w - totalWidth) / 2
    local posY = h * 0.90

    for i = 1, 2 do
        local x = startX + (i - 1) * (CARD_WIDTH + 30)
        local y = posY

        if mx > x and mx < x + CARD_WIDTH and
           my > y and my < y + CARD_HEIGHT then
            hoverIndex = i
        end
    end
end

---------------------------------------------------------
-- DESENHAR CARTAS DA RODADA
---------------------------------------------------------
local function desenharCartasRodada()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    local totalWidth = (CARD_WIDTH * 2) + 30
    local startX = (w - totalWidth) / 2
    local posY = h * 0.90

    for i = 1, 2 do
        local card = cartasRodada[i]
        if not card then goto continue end

        local x = startX + (i - 1) * (CARD_WIDTH + 30)
        local y = posY
        local offset = hoverIndex == i and -HOVER_OFFSET or 0

        love.graphics.draw(card.img, x, y + offset)

        if hoverIndex == i then
            -----------------------------
            -- CAIXA CINZA DE TEXTO
            -----------------------------
            local textoX
            if i == 1 then
                textoX = x - 220
            else
                textoX = x + CARD_WIDTH + 20
            end

            local largura = 200
            local altura = 150

            love.graphics.setColor(0.2, 0.2, 0.2, 0.75)
            love.graphics.rectangle("fill",
                textoX - 10,
                y + offset + 10,
                largura + 20,
                altura
            )

            -- TÍTULO AZUL
            love.graphics.setColor(0.2, 0.4, 1, 1)
            love.graphics.printf(card.id,
                textoX,
                y + offset + 20,
                largura
            )

            -- CORPO DO TEXTO
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(card.descricao,
                textoX,
                y + offset + 45,
                largura
            )
        end

        ::continue::
    end

    love.graphics.setColor(1,1,1)
end

---------------------------------------------------------
-- SELEÇÃO POR TECLAS
---------------------------------------------------------
local function selecionarCartaPorTecla(key)
    if escolhaBloqueada then return end

    if key == "1" and cartasRodada[1] then
        cartaSelecionada = cartasRodada[1]
        aplicarEfeito(cartaSelecionada)
        escolhaBloqueada = true

    elseif key == "2" and cartasRodada[2] then
        cartaSelecionada = cartasRodada[2]
        aplicarEfeito(cartaSelecionada)
        escolhaBloqueada = true
    end
end

---------------------------------------------------------
-- VISUAL DA ESCOLHA
---------------------------------------------------------
local function desenharResultadoEscolha()
    if cartaSelecionada then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("Carta usada: " .. cartaSelecionada.id, 50, 100)
        love.graphics.setColor(1, 1, 1)
    end
end

---------------------------------------------------------
-- EXPORTAR MÓDULO
---------------------------------------------------------
return {
    construirBaralho = construirBaralho,
    desenharBaralho = desenharBaralho,
    reposicionarBaralho = reposicionarBaralho,

    selecionarCartasRodada = selecionarCartasRodada,
    atualizarInteracaoCartas = atualizarInteracaoCartas,
    desenharCartasRodada = desenharCartasRodada,

    selecionarCartaPorTecla = selecionarCartaPorTecla,
    desenharResultadoEscolha = desenharResultadoEscolha,

    setAdicionarAgua = setAdicionarAgua
}
