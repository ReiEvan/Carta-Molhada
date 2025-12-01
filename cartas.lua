local love = require ("love")

local primeirasAliadas = {

     {
        id = "Garrafa termica",
        img = love.graphics.newImage("sprites/carta garrafa termica.png"),
        descricao = "Seu guarda não vai gastar água nessa rodada."
    },
    
    {
        id = "Carta da Nascente",
        img = love.graphics.newImage("sprites/carta nascente.png"),
        descricao = "Ganhe 2 águas."
    },

    {
        id = "Clarividência",
        img = love.graphics.newImage("sprites/carta 8 clarividencia.png"),
        descricao = 
        "Descubra qual será o conflito do próximo turno."
    },

    {
        id = "Movimento Livre",
        img = love.graphics.newImage("sprites/carta mov livre.png"),
        descricao =
            "Use esta carta para se \n".. 
            "mover para qualquer espaço\n".. 
            "sem gastar uma ação\n" ..
            "(mantendo a regra de \n".. 
            "movimento padrão)"
    },

    {
        id = "Carta Dourada",
        img = love.graphics.newImage("sprites/carta dourada.png"),
        descricao =
            "Escolha uma área verde\n".. 
            "(exceto o ponto de origem).\n" ..
            "Ela não pode ser perdida \n".. 
            "por cartas de conflito"
    },
    {
        id = "Dissolvendo problemas",
        img = love.graphics.newImage("sprites/carta Dissolvendo problemas.png"),
        descricao=
            'Gaste 2 águas e anule\n'..
            'o conflitos da rodada'
    },
    {
        id = "Esforço recompensado",
        img = love.graphics.newImage('sprites/carta Esforco recompensado.png'),
        descricao=
            'Se tiver 3 áreas verdes\n'..
            'ganhe 3 fichas de água.'
    },
    {
        id = "Procurando água",
        img = love.graphics.newImage('sprites/carta Procurando agua.png'),
        descricao = 
            'Troque 1 ação por\n'..
            '1 ficha de água\n'..
            '(até o limite de 3)'
    }
}
local adicionarAgua = nil
local function aplicarEfeito(carta)
    if carta.id == "Carta da Nascente" and adicionarAgua then
        print("EFEITO: +2 água")
        adicionarAgua(2)   
    end
    if carta.id == "Movimento Livre" and alterarmovimento then
        alterarmovimento(1)
    end
    if carta.id == "Procurando água" and alterarmovimento and adicionarAgua then
        alterarmovimento(-1)
        adicionarAgua(1)
    end
end


local function setAdicionarAgua(func)
    adicionarAgua = func
end
local function setalterarmovimento(func)
    alterarmovimento = func
end
local CARD_WIDTH = 140
local CARD_HEIGHT = 185
local OFFSET_BETWEEN_CARDS = 3  
local CARDS_IN_BARALHO = #primeirasAliadas
local contadorBaralho = CARDS_IN_BARALHO  

local HOVER_OFFSET = 120
local descarte = {}
local baralho = {}
local cartaSelecionada = nil
local efeitoDaCarta = nil
local escolhaBloqueada = false

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

    contadorBaralho = #primeirasAliadas

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
   if escolhaBloqueada then
        return
    end

    if key == "1" and cartasRodada[1] then
        cartaSelecionada = cartasRodada[1]
        aplicarEfeito(cartaSelecionada)
        --efeitoDaCarta = "Você escolheu a carta da ESQUERDA!"
        escolhaBloqueada = true  -- agora trava corretamente
        print("Carta da esquerda ativada: " .. cartaSelecionada.descricao)

    elseif key == "2" and cartasRodada[2] then
        cartaSelecionada = cartasRodada[2]
        aplicarEfeito(cartaSelecionada)
        --efeitoDaCarta = "Você escolheu a carta da DIREITA!"
        escolhaBloqueada = true
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
    if #primeirasAliadas == 0 then
        for i = 1, #descarte do
            table.insert(primeirasAliadas, descarte[i])
        end
        descarte = {}
        construirBaralho()
    end

    -- embaralha lista auxiliar
    local copia = {}
    for i = 1, #primeirasAliadas do copia[i] = primeirasAliadas[i] end
    for i = #copia, 2, -1 do
        local j = love.math.random(1, i)
        copia[i], copia[j] = copia[j], copia[i]
    end

    -- pega a carta do topo
    local carta = copia[1]

    -- remove da lista original e joga no descarte
    for i = #primeirasAliadas, 1, -1 do
        if primeirasAliadas[i] == carta then
            table.insert(descarte, carta)
            table.remove(primeirasAliadas, i)
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
    cartaSelecionada = nil
    escolhaBloqueada = false
    efeitoDaCarta = nil
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

        
    -- ESCONDER CARTA NÃO ESCOLHIDA
    if escolhaBloqueada and cartasRodada[i] == cartaSelecionada then
        goto continue
    end


        local x = startX + (i - 1) * (CARD_WIDTH + 30)
        local y = posY

        local offset = (hoverIndex == i) and -HOVER_OFFSET or 0
        love.graphics.draw(card.img, x, y + offset)

        if hoverIndex == i then
       

    local textoX
    if i == 1 then
        textoX = x - 220
    else
        textoX = x + CARD_WIDTH + 20
    end

    --------------------------------------------------------
    -- SEPARAR TÍTULO (1ª linha) E CORPO DO TEXTO
    --------------------------------------------------------
    local titulo= card.id
    local corpo = card.descricao
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
 --------------------------------------------------------
-- TEXTO "APERTE 1/2 PARA ATIVAR" (AGORA LARANJA E MAIS ACIMA)
--------------------------------------------------------
love.graphics.setColor(1, 0.6, 0)  -- laranja

local direcao = (i == 1) and "Aperte 1 para ativar" or "Aperte 2 para ativar"

love.graphics.printf(
    direcao,
    textoX,
    y + offset + 120, 
    larguraCaixa,
    "center"
)
love.graphics.setColor(1, 1, 1)
end

        ::continue::
    end
end
--///////////////////////////////////////////////////////////////////////////////////////////////
--                                         CONFLITOS
--//////////////////////////////////////////////////////////////////////////////////////////////
local fonte= {}
local CONFLITO_WIDTH = 134
local CONFLITO_HEIGHT = 176
fonte.media = love.graphics.newFont(20)
fonte.normal = love.graphics.newFont(15)

local conflitoX = 0
local conflitoY = 0

-- Fundo permanente do conflito (sempre aparece)
local fundoConflitoSprite = love.graphics.newImage("sprites/FUNDO CARTA VERMELHA.png")

---------------------------------------------------------
-- LISTA INICIAL DE CONFLITOS
---------------------------------------------------------
local conflitos = {
    {
        id = "Bomba d'agua quebrou",
        img = love.graphics.newImage("sprites/conflitos/bomba dagua quebrou.png"),
        descricao = "Perca 2 fichas de água",
        efeito = 
        function() 
            if adicionarAgua then adicionarAgua(-2) 
            end
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
        descricao = "Os guardas gastam 2 águas ao invés de 1 e o movimento cai em 1"
    },
    {
        id = "Guarda inoperante",
        img = love.graphics.newImage("sprites/conflitos/Guarda inoperante.png"),
        descricao = "Um dos guardas fica inoperante até o fim dessa rodada",
       -- efeito= ele deve impedir de se mover nn gastar todas as movimentações
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
    },
     {
        id = "Terreno difícil",
        img = love.graphics.newImage("sprites/conflitos/Terreno dificil.png"),
        descricao = "retarde o tratamento de todas as áreas desse turno"
    }
}

---------------------------------------------------------
-- BARALHO DE CONFLITOS
---------------------------------------------------------
local baralhoConflitos = {}
local descarteConflitos = {}
local conflitoAtual = nil


-- ==========================
-- FUNÇÃO: Copia base → baralho
-- ==========================
local function inicializarConflitos()
    baralhoConflitos = {}
    for i = 1, #conflitos do
        baralhoConflitos[i] = conflitos[i]
    end
end

inicializarConflitos()

---------------------------------------------------------
-- EMBARALHAR LISTA
---------------------------------------------------------
local function embaralhar(t)
    for i = #t, 2, -1 do
        local j = love.math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

---------------------------------------------------------
-- PUXAR 1 CONFLITO DA PILHA
---------------------------------------------------------
local function puxarConflito()
    if #baralhoConflitos == 0 then
        for i = 1, #descarteConflitos do
            table.insert(baralhoConflitos, descarteConflitos[i])
        end
        descarteConflitos = {}
    end

    local copia = {}
    for i = 1, #baralhoConflitos do copia[i] = baralhoConflitos[i] end
    embaralhar(copia)

    local escolhido = copia[1]

    for i = #baralhoConflitos, 1, -1 do
        if baralhoConflitos[i] == escolhido then
            table.insert(descarteConflitos, escolhido)
            table.remove(baralhoConflitos, i)
            break
        end
    end

    return escolhido
end

---------------------------------------------------------
-- SORTEAR CONFLITO E APLICAR EFEITO
---------------------------------------------------------
local function sortearConflitoRodada()
    conflitoAtual = puxarConflito()
    if conflitoAtual.efeito then conflitoAtual.efeito() end
end

---------------------------------------------------------
-- PREPARAR CONFLITO (USADO PELO MAIN)
---------------------------------------------------------
local function prepararConflitoDaRodada(numeroDaRodada)
    if numeroDaRodada == 1 then
        -- 1ª rodada → sem conflito
        conflitoAtual = nil
        primeiraRodada = false
    else
        -- A partir da 2ª → sorteia um
        sortearConflitoRodada()
    end
end

---------------------------------------------------------
-- DESENHAR FUNDO DO CONFLITO (sempre aparece)
---------------------------------------------------------
local function desenharFundoConflito()
    love.graphics.draw(fundoConflitoSprite, conflitoX, conflitoY)
end

---------------------------------------------------------
-- DESENHAR O CONFLITO (se houver)
---------------------------------------------------------
local function desenharConflito()
    if not conflitoAtual then return end

    love.graphics.draw(conflitoAtual.img, conflitoX, conflitoY)

    love.graphics.setColor(1,0,0)
    love.graphics.setFont(fonte.media)
    love.graphics.print(conflitoAtual.id, conflitoX+140, conflitoY + 5)
    love.graphics.setFont(fonte.normal)
    love.graphics.setColor(1,1,1)
    love.graphics.print(conflitoAtual.descricao, conflitoX+140, conflitoY + CONFLITO_HEIGHT-130)
end

return {
    construirBaralho = construirBaralho,
    desenharBaralho = desenharBaralho,
    reposicionarBaralho = reposicionarBaralho,

    selecionarCartasRodada = selecionarCartasRodada,
    atualizarInteracaoCartas = atualizarInteracaoCartas,
    desenharCartasRodada = desenharCartasRodada,

    selecionarCartaPorTecla = selecionarCartaPorTecla,
    desenharResultadoEscolha = desenharResultadoEscolha,
    setAdicionarAgua = setAdicionarAgua,
    setalterarmovimento = setalterarmovimento,

    -- conflitos
    prepararConflitoDaRodada = prepararConflitoDaRodada,
    desenharFundoConflito = desenharFundoConflito,
    desenharConflito = desenharConflito

}
