-- carta unica(check),baralho todo(check),animação baralho único(?),retirar 2 cartas p turno
local love = require "love"

local todasAliadas = {
    {
        img = love.graphics.newImage("sprites/carta super eficiente.png"),
        descricao = "Super Eficiente\nComece está rodada com 1 ação a mais."
    },
 {
        img = love.graphics.newImage("sprites/carta nascente.png"),
        descricao = "Carta da Nascente\nGanhe 2 águas."
    },
    
    {
        img = love.graphics.newImage("sprites/carta 8 clarividencia.png"),
        descricao = 
        "Clarividência\nDescubra qual será o conflito do próximo turno."
    },

    {
        img = love.graphics.newImage("sprites/carta mov livre.png"),
        descricao =
            "Movimento Livre\n" ..
            "Use esta carta para se \n".. 
            "mover para qualquer espaço\n".. 
            "sem gastar uma ação\n" ..
            "(mantendo a regra de \n".. 
            "movimento padrão)"
    },

    {
        img = love.graphics.newImage("sprites/carta dourada.png"),
        descricao =
            "Carta Dourada\n" ..
            "Escolha uma área verde\n".. 
            "(exceto o ponto de origem).\n" ..
            "Ela não pode ser perdida \n".. 
            "por cartas de conflito"
    },
    {
        img = love.graphics.newImage("sprites/carta Dissolvendo problemas.png"),
        descricao=
            'Dissolvendo problemas\n'..
            'Gaste 2 águas e anule\n'..
            'o conflitos da rodada'
    },
    {
        img = love.graphics.newImage('sprites/carta Esforco recompensado.png'),
        descricao=
            'Esforço recompensado\n'..
            'Se tiver 3 áreas verdes\n'..
            'ganhe 3 fichas de água.'
    },
    {
        img = love.graphics.newImage('sprites/carta Procurando agua.png'),
        descricao = 
            'Procurando água\n'..
            'Troque 1 ação por\n'..
            '1 ficha de água\n'..
            '(até o limite de 3)'
    }
}

local CARD_WIDTH = 140
local CARD_HEIGHT = 185
local OFFSET_BETWEEN_CARDS = 3  
local CARDS_IN_BARALHO = #todasAliadas
local contadorBaralho = CARDS_IN_BARALHO  

local HOVER_OFFSET = 120
local descarte = {}
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

    baralho = {}

    contadorBaralho = #todasAliadas

    for i = 0, contadorBaralho - 1 do
        local offsetY = i * OFFSET_BETWEEN_CARDS      
        table.insert(baralho, criarFundo(startY - offsetY, startX))
    end
end

local function desenharBaralho()
    for i = #baralho, 1, -1 do
        local card = baralho[i]
        love.graphics.draw(card.transform.sprite, card.transform.x, card.transform.y)  
    end

    -- contador movido mais para baixo
    if #baralho > 0 then
        local cx = baralho[#baralho].transform.x - 65
        local cy = baralho[#baralho].transform.y + 173  
        love.graphics.setColor(1,1,1)
        love.graphics.print("Cartas: " .. contadorBaralho, cx, cy)
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

local cartasRodada = {}
local hoverIndex = nil

-----------------------------------------------------
-- SELEÇÃO DE CARTAS (TECLAS 1 E 2)
-----------------------------------------------------

local cartaSelecionada = nil  -- armazena qual foi escolhida
local efeitoDaCarta = nil     -- string mostrando qual efeito ocorreu

local function selecionarCartaPorTecla(key)
    if key == "1" and cartasRodada[1] then
        cartaSelecionada = cartasRodada[1]
        efeitoDaCarta = "Você escolheu a carta da ESQUERDA!"
        print("Carta da esquerda ativada: " .. cartaSelecionada.descricao)

    elseif key == "2" and cartasRodada[2] then
        cartaSelecionada = cartasRodada[2]
        efeitoDaCarta = "Você escolheu a carta da DIREITA!"
        print("Carta da direita ativada: " .. cartaSelecionada.descricao)
    end
end

-----------------------------------------------------
-- DESENHAR RESULTADO DA ESCOLHA NA TELA
-----------------------------------------------------
local function desenharResultadoEscolha()
    if efeitoDaCarta then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(efeitoDaCarta, 50, 100)
        love.graphics.setColor(1, 1, 1)
    end
end

local function puxarCartaGarantido()
    -- caso o baralho tenha 0 cartas, recarrega
    if #todasAliadas == 0 then
        for i = 1, #descarte do
            table.insert(todasAliadas, descarte[i])
        end
        descarte = {}
        construirBaralho()
    end

    -- embaralha lista auxiliar
    local copia = {}
    for i = 1, #todasAliadas do copia[i] = todasAliadas[i] end
    for i = #copia, 2, -1 do
        local j = love.math.random(1, i)
        copia[i], copia[j] = copia[j], copia[i]
    end

    -- pega a carta do topo
    local carta = copia[1]

    -- remove da lista original e joga no descarte
    for i = #todasAliadas, 1, -1 do
        if todasAliadas[i] == carta then
            table.insert(descarte, carta)
            table.remove(todasAliadas, i)
            break
        end
    end

    -- atualiza baralho visual
    if #baralho > 0 then
        table.remove(baralho, 1)
        contadorBaralho = math.max(0, contadorBaralho - 1)
    end

    return carta
end

-- SORTEIO DE 2 CARTAS
local function selecionarCartasRodada()
    cartasRodada = {}

    -- 1° carta garantida
    cartasRodada[1] = puxarCartaGarantido()

    -- 2° carta garantida (se faltar carta, recicla automático)
    cartasRodada[2] = puxarCartaGarantido()
end


-- HOVER
local function atualizarInteracaoCartas()
    hoverIndex = nil

    local mx, my = love.mouse.getPosition()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local totalWidth = (CARD_WIDTH * 2) + 30
    local startX = (screenWidth - totalWidth) / 2
    local posY = screenHeight * 0.90

    for i = 1, 2 do
        local x = startX + (i - 1) * (CARD_WIDTH + 30)
        local y = posY

        if mx > x and mx < x + CARD_WIDTH
        and my > y and my < y + CARD_HEIGHT then
            hoverIndex = i
        end
    end
end


local function desenharCartasRodada()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local totalWidth = (CARD_WIDTH * 2) + 30
    local startX = (screenWidth - totalWidth) / 2
    local posY = screenHeight * 0.90

    for i = 1, 2 do
        local card = cartasRodada[i]
        if not card then goto continue end

        local x = startX + (i - 1) * (CARD_WIDTH + 30)
        local y = posY

        local offset = (hoverIndex == i) and -HOVER_OFFSET or 0
        love.graphics.draw(card.img, x, y + offset)

        if hoverIndex == i then
    local texto = card.descricao

    local textoX
    if i == 1 then
        textoX = x - 220
    else
        textoX = x + CARD_WIDTH + 20
    end

    --------------------------------------------------------
    -- SEPARAR TÍTULO (1ª linha) E CORPO DO TEXTO
    --------------------------------------------------------
    local titulo, corpo = texto:match("([^\n]+)\n?(.*)")
    corpo = corpo or ""

    --------------------------------------------------------
    -- DESENHAR O QUADRADO CINZA
    --------------------------------------------------------
    local larguraCaixa = 200
    local alturaCaixa = 150

    love.graphics.setColor(0.2, 0.2, 0.2, 0.75) -- cinza com transparência
    love.graphics.rectangle(
        "fill",
        textoX - 10,
        y + offset + 10,
        larguraCaixa + 20,
        alturaCaixa
    )

    --------------------------------------------------------
    -- DESENHAR O TÍTULO COLORIDO
    --------------------------------------------------------
    love.graphics.setColor(0.2, 0.4, 1, 1)
    love.graphics.printf(
        titulo,
        textoX,
        y + offset + 20,
        larguraCaixa
    )

    --------------------------------------------------------
    -- DESENHAR O CORPO DO TEXTO
    --------------------------------------------------------
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        corpo,
        textoX,
        y + offset + 45,
        larguraCaixa
    )
end

        ::continue::
    end
end

return {
    construirBaralho = construirBaralho,
    desenharBaralho = desenharBaralho,
    reposicionarBaralho = reposicionarBaralho,

    selecionarCartasRodada = selecionarCartasRodada,
    atualizarInteracaoCartas = atualizarInteracaoCartas,
    desenharCartasRodada = desenharCartasRodada,

    selecionarCartaPorTecla = selecionarCartaPorTecla,
    desenharResultadoEscolha = desenharResultadoEscolha
}