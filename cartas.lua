local love = require ("love")
local alterarAgua = nil
local alterarMovimento = nil
local getContagemVerdes= nil
local sabotagemProximaRodada = nil
-- Tabela que guarda os poderes ativos
local efeitosAtivos = {
    garrafaTermica = false,
    protecaoVerde = false,
    anularConflito = false,
    sabotagem = false
}

-- Função para limpar os poderes quando o dia vira
function resetarEfeitosRodada()
    efeitosAtivos.garrafaTermica = false
    efeitosAtivos.protecaoVerde = false
    efeitosAtivos.anularConflito = false
    efeitosAtivos.sabotagem = false 
end

function setCallbacks(funcAgua, funcMov,funcver)
    alterarAgua = funcAgua
    alterarMovimento = funcMov
    getContagemVerdes=funcver
end

--Variavel para controlar a dificuldade
local eraAtual = 1

--//////////////////////////////////////////////////////////////////////////////////////////
--                                   CARTAS ALIADAS
--//////////////////////////////////////////////////////////////////////////////////////////

local primeirasAliadas = {
      
    {
        id = "Carta da Nascente",
        img = love.graphics.newImage("sprites/carta nascente.png"),
        descricao = "Ganhe 2 águas."
    },

    {
        id = "Clarividência",
        img = love.graphics.newImage("sprites/carta 8 clarividencia.png"),
        descricao = "Descubra qual será o conflito do próximo turno."
        -- DICA: no main, ao final da rodada:
        -- mostre na tela conflitos[1] ou conflito que será puxado no próximo turno
    },

    {
        id = "Movimento Livre",
        img = love.graphics.newImage("sprites/carta mov livre.png"),
        descricao =
            'Começe a rodada com um movimento a mais'
    },
    {
        id = "Procurando água",
        img = love.graphics.newImage('sprites/carta Procurando agua.png'),
        descricao = 
            'Troque 1 ação por\n'..
            '1 ficha de água\n'..
            '(até o limite de 3)'
    },
    
}
local segundasAliadas={
    {
        id = "Esforço recompensado",
        img = love.graphics.newImage('sprites/carta Esforco recompensado.png'),
        descricao=
            'Se tiver 3 áreas verdes\n'..
            'ganhe 3 fichas de água.'
    },
    {
        id = "Dissolvendo problemas",
        img = love.graphics.newImage("sprites/carta Dissolvendo problemas.png"),
        descricao=
            'Gaste 2 águas e anule\n'..
            'o conflitos da rodada'
        -- DICA: no main, antes de aplicar conflito:
        -- if dissolvendoAtivo then conflitoAtual = nil
    },
    {   
        id = "Garrafa termica",
        img = love.graphics.newImage("sprites/carta garrafa termica.png"),
        descricao = "Seu guarda não vai gastar água nessa rodada."
        -- DICA: no main, antes de gastar água do guarda, coloque:
        -- if garrafaTermicaAtiva then não gastar água
    },
    {
        id = "Carta Dourada",
        img = love.graphics.newImage("sprites/carta dourada.png"),
        descricao =
            "Escolha uma área verde\n".. 
            "(exceto o ponto de origem).\n" ..
            "Ela não pode ser perdida \n".. 
            "por cartas de conflito"
        -- DICA: marque area.protegida = true e ao aplicar conflito pule áreas protegidas
    },

}
-- estado de troca
local escolhendoTroca = false
local movimentosDisponiveis = 0

-- erro
local mensagemErro = ""
local tempoErro = 0
-----------------------------------------------------------------------------------------
-- efeitos aliados
----------------------------------------------------------------------------------------- 

 function aplicarEfeito(carta,valorMove)
    if carta.id == "Carta da Nascente" and alterarAgua then
       alterarAgua(2)
    end

    if carta.id == "Movimento Livre" and alterarMovimento then
        alterarMovimento(1)
    end

    if carta.id == "Procurando água" and alterarMovimento and alterarAgua then
        escolhendoTroca = true
        movimentosDisponiveis = tonumber(valorMove) or 0
        mensagemErro = ""
        return
    end
    if carta.id== "Esforço recompensado" and getContagemVerdes and alterarAgua then
        local verdes=getContagemVerdes()
        if verdes >= 3 then
            alterarAgua(3)
        end
    end
end

-----------------------------------------------------------------------------------------
-- VISUAL DAS CARTAS
-----------------------------------------------------------------------------------------
local CARD_WIDTH = 140
local CARD_HEIGHT = 185
local OFFSET_BETWEEN_CARDS = 3  
local contadorBaralho = #primeirasAliadas
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
        table.insert(baralho, criarFundo(startX, startY - offsetY))
    end
end

local function desenharBaralho()
    for i = #baralho, 1, -1 do
        love.graphics.draw(baralho[i].transform.sprite, baralho[i].transform.x, baralho[i].transform.y)
    end

    if #baralho > 0 then
        local cx = baralho[#baralho].transform.x - 65
        local cy = baralho[#baralho].transform.y + 173  
        love.graphics.print("Cartas: " .. contadorBaralho, cx, cy)
    end
end

local function reposicionarBaralho()
    if not love.window.hasFocus() then return end

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    for i, card in ipairs(baralho) do
        local offsetY = (i - 1) * OFFSET_BETWEEN_CARDS
        card.transform.x = screenWidth - CARD_WIDTH
        card.transform.y = screenHeight - CARD_HEIGHT - offsetY
    end
end

-----------------------------------------------------------------------------------------
-- PUXAR CARTAS
-----------------------------------------------------------------------------------------

local function puxarCartaGarantido()
    if #primeirasAliadas == 0 then
        for i = 1, #descarte do
            table.insert(primeirasAliadas, descarte[i])
        end
        descarte = {}
        construirBaralho()
    end

    local copia = {}
    for i = 1, #primeirasAliadas do copia[i] = primeirasAliadas[i] end

    for i = #copia, 2, -1 do
        local j = love.math.random(1, i)
        copia[i], copia[j] = copia[j], copia[i]
    end

    local carta = copia[1]

    for i = #primeirasAliadas, 1, -1 do
        if primeirasAliadas[i] == carta then
            table.insert(descarte, carta)
            table.remove(primeirasAliadas, i)
            break
        end
    end
    contadorBaralho = #primeirasAliadas
    if #baralho > 0 then
        table.remove(baralho, 1)
        contadorBaralho = math.max(0, contadorBaralho - 1)
    end

    return carta
end

-----------------------------------------------------------------------------------------
-- SELEÇÃO DE 2 CARTAS
-----------------------------------------------------------------------------------------

local cartasRodada = {}
local hoverIndex = nil

local function selecionarCartasRodada()
    -- Limpa a seleção anterior
    cartasRodada = {}
    cartaSelecionada = nil
    escolhaBloqueada = false
    efeitoDaCarta = nil

    -- Garante que temos cartas suficientes no baralho
    if #primeirasAliadas < 2 then
        for i = 1, #descarte do
            table.insert(primeirasAliadas, descarte[i])
        end
        descarte = {}
        construirBaralho()
    end

    -- Define quantas cartas puxar: 1 se sabotagem estiver ativa, senão 2
    local qtdCartas = efeitosAtivos.sabotagem and 1 or 2

    -- Puxa as cartas
    for i = 1, qtdCartas do
        cartasRodada[i] = puxarCartaGarantido()
    end

    -- Desativa o efeito de sabotagem após aplicar
    efeitosAtivos.sabotagem = false

    -- Atualiza o contador de cartas restantes no baralho
    contadorBaralho = #primeirasAliadas
    -- Aplica sabotagem se estava marcada para a próxima rodada
    efeitosAtivos.sabotagem = sabotagemProximaRodada
    sabotagemProximaRodada = false

end

-----------------------------------------------------------------------------------------
-- HOVER E DESENHO
-----------------------------------------------------------------------------------------
local function getPosicaoCarta(i)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local totalWidth = (CARD_WIDTH * 2) + 30
    local startX = (screenWidth - totalWidth) / 2
    local posY = screenHeight * 0.90

    local x = startX + (i - 1) * (CARD_WIDTH + 30)
    local y = posY

    return x, y
end

local function atualizarInteracaoCartas()
    hoverIndex = nil

    local mx, my = love.mouse.getPosition()

    for i = 1, 2 do
        local x, y = getPosicaoCarta(i)

        if mx > x and mx < x + CARD_WIDTH and my > y and my < y + CARD_HEIGHT then
            hoverIndex = i
        end
    end
end

local function desenharInventarioCartas()
    if not escolhendoTroca then
        local startX = 50
        local startY = 140
        local spacing = 180  -- distância entre as cartas

        for i, c in ipairs(primeirasAliadas) do
            local x = startX + (i-1) * spacing
            local y = startY
        
            -- GARANTIR QUE NADA É NIL
            if x and y and CARD_WIDTH and CARD_HEIGHT then
                love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT)
                love.graphics.draw(c.img, x, y)
                love.graphics.printf(c.id, x, y + CARD_HEIGHT + 5, CARD_WIDTH, "center")
            else
                love.graphics.print("ERRO: posição da carta é NIL", 50, 50)
            end
        end
    end
end

function mousepressed(mx, my, btn, moveAtual)
    if btn ~= 1 then return false end
    if escolhendoTroca then return false end
    if escolhaBloqueada then return false end

    for i, carta in ipairs(cartasRodada) do
    local x, y = getPosicaoCarta(i)

    if mx > x and mx < x + CARD_WIDTH and my > y and my < y + CARD_HEIGHT then
        
        -- BLOQUEIO SABOTAGEM: se for a segunda carta e sabotagem ativa
        if efeitosAtivos.sabotagem and i == 2 then
            mensagemErro = "Esta carta foi sabotada!"
            tempoErro = 2
            return true
        end

        cartaSelecionada = carta
        aplicarEfeito(carta, moveAtual)
        escolhaBloqueada = true
        
        return true
    end
end
end

-- keypressed: escolhe 1,2 ou 3 se estiver em troca
function keypressed(key)
    -- se NÃO estamos na troca, apenas ignoramos teclas
    if not escolhendoTroca then
        return
    end

    -- estamos em fase de troca -> só aceita 1,2,3
    local qtd = tonumber(key)
    if not qtd then return end
    if qtd < 1 or qtd > 3 then return end

    -- checa se tem movimentos suficientes
    if qtd > movimentosDisponiveis then
        mensagemErro = "Você não tem movimentos suficientes!"
        tempoErro = 2
        return
    end

    -- aplica troca (movimento negativo)
    if alterarMovimento then
        alterarMovimento(-qtd)
    end

    if alterarAgua then
        alterarAgua(qtd)
    end

    escolhendoTroca = false
end

function notificarErro(dt)
    if tempoErro > 0 then
        tempoErro = tempoErro - dt
        if tempoErro <= 0 then mensagemErro = "" end
    end
end

-- Carregar a imagem da sabotagem
local sabotagemImg = love.graphics.newImage("sprites/conflitos/sabotagem.png")

local function desenharCartasRodada()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local totalWidth = (#cartasRodada * CARD_WIDTH) + ((#cartasRodada - 1) * 30)
    local startX = (screenWidth - totalWidth) / 2
    local posY = screenHeight * 0.90

    for i = 1, #cartasRodada do
        local card = cartasRodada[i]
        if not card then goto continue end

        -- ESCONDE a carta escolhida
        if escolhaBloqueada and cartasRodada[i] == cartaSelecionada then
            goto continue
        end

        local x, y = startX + (i - 1) * (CARD_WIDTH + 30), posY
        local offset = (hoverIndex == i) and -HOVER_OFFSET or 0

        -- SE FOR A CARTA "SABOTADA", desenha a imagem da sabotagem
        local imgParaDesenhar = card.img
        if efeitosAtivos.sabotagem and i == 2 then
            imgParaDesenhar = sabotagemImg
        end

        love.graphics.draw(imgParaDesenhar, x, y + offset)

        -- Hover / descrição
        if hoverIndex == i then
            local textoX = (i==1) and (x - 220) or (x + CARD_WIDTH + 20)
            local larguraCaixa, alturaCaixa = 200, 150

            love.graphics.setColor(0.2,0.2,0.2,0.75)
            love.graphics.rectangle("fill", textoX - 10, y + offset + 10, larguraCaixa + 20, alturaCaixa)

            love.graphics.setColor(0.2,0.4,1)
            love.graphics.printf(card.id, textoX, y + offset + 20, larguraCaixa)

            love.graphics.setColor(1,1,1)
            love.graphics.printf(card.descricao, textoX, y + offset + 45, larguraCaixa)

            love.graphics.setColor(1, 0.6, 0)
            love.graphics.printf("CLIQUE NA CARTA", textoX, y + offset + 120, larguraCaixa, "center")
            love.graphics.setColor(1,1,1)
        end

        ::continue::
    end
end



-----------------------------------------------------------------------------------------
-- RESULTADO DA ESCOLHA
-----------------------------------------------------------------------------------------

local function desenharResultadoEscolha()
    if efeitoDaCarta then
        love.graphics.setColor(1,1,0)
        love.graphics.print(efeitoDaCarta, 50, 100)
        love.graphics.setColor(1,1,1)
    end
end

--///////////////////////////////////////////////////////////////////////////////////////////////
--                                         CONFLITOS
--//////////////////////////////////////////////////////////////////////////////////////////////

local fonte= {}
fonte.media = love.graphics.newFont(20)
fonte.normal = love.graphics.newFont(15)

local CONFLITO_WIDTH = 134
local CONFLITO_HEIGHT = 176

local conflitoX = 0
local conflitoY = 0

local fundoConflitoSprite = love.graphics.newImage("sprites/FUNDO CARTA VERMELHA.png")

-----------------------------------------------------------------------------------------
-- LISTA DE CONFLITOS
-----------------------------------------------------------------------------------------

local conflitos1 = {

    {
        id = "Bomba d'agua quebrou",
        img = love.graphics.newImage("sprites/conflitos/bomba dagua quebrou.png"),
        descricao = "Perca 2 fichas de água",
        eraMinima = 1,
        efeito = function()
            if alterarAgua then alterarAgua(-2) end
        end
    },

    {
        id = "Incendio criminoso",
        img = love.graphics.newImage("sprites/conflitos/incendio criminoso.png"),
        descricao = "Perca uma área verde que não tenha um guarda",
        eraMinima = 1
        -- DICA: no main:
        -- encontre áreas sem guarda e remova 1 aleatória
    },

    {
        id = "Guarda inoperante",
        img = love.graphics.newImage("sprites/conflitos/Guarda inoperante.png"),
        descricao = "Um dos guardas fica inoperante até o fim da rodada",
        eraMinima = 1
        -- DICA: marque guarda.inoperante = true e ignore ações dele no turno
    },

   {
    id = "Sabotagem",
    img = love.graphics.newImage("sprites/conflitos/sabotagem.png"),
    descricao = "na proxima rodada só tera uma carta",
    eraMinima = 1,
    efeito = function()
        sabotagemProximaRodada = true
    end
    },

    {
        id = "Terreno difícil",
        img = love.graphics.newImage("sprites/conflitos/Terreno dificil.png"),
        descricao = "retarde o tratamento de todas as áreas desse turno",
        eraMinima = 1
        -- DICA: no main:
        -- tratamentoDasAreasPausado = true
    }
}
local conflitos2={
    {
        id = "A carta cinza",
        img = love.graphics.newImage("sprites/conflitos/A carta cinza.png"),
        descricao = "Perca 2 áreas verdes",
        eraMinima = 2
        -- DICA: remova 2 áreas verdes aleatórias (ignorando as protegidas)
    },
    {
        id = "Dia quente de trabalho",
        img = love.graphics.newImage("sprites/conflitos/dia quente de trabalho.png"),
        descricao = "Os guardas gastam 2 águas ao invés de 1 e o movimento cai em 1",
        eraMinima = 2
        -- DICA: no gasto de água do guarda → gasto = 2
        -- DICA: reduzir movimento: movimento = movimento - 1
    },
}

-----------------------------------------------------------------------------------------
-- BARALHO DE CONFLITOS
-----------------------------------------------------------------------------------------

local baralhoConflitos = {}
local descarteConflitos = {}
local conflitoAtual = nil

local function embaralhar(t)
    for i = #t, 2, -1 do
        local j = love.math.random(1,i)
        t[i],t[j] = t[j],t[i]
    end
end

local function inicializarConflitos()
    baralhoConflitos = {}
    descarteConflitos = {} --Reseta o descarte ao mudar de era para garantir que as novas entrem

    for i = 1, #conflitos1 do
        --Verifica se a carta pode ser usada na era atual
        local requisito = conflitos1[i].eraMinima or 1

        if requisito <= eraAtual then
            table.insert(baralhoConflitos, conflitos1[i])
        end
    end

    --Embaralha tudo imediatamente
    embaralhar(baralhoConflitos)
end

inicializarConflitos()

local function puxarConflito()
    if #baralhoConflitos == 0 then
        for i = 1,#descarteConflitos do
            table.insert(baralhoConflitos, descarteConflitos[i])
        end
        descarteConflitos = {}
        embaralhar(baralhoConflitos)
    end

    if #baralhoConflitos == 0 then return nil end

    local escolhido = baralhoConflitos[1]
    table.remove(baralhoConflitos, 1)

    table.insert(descarteConflitos, escolhido)

    return escolhido
end

local function sortearConflitoRodada()
    conflitoAtual = puxarConflito()
    if conflitoAtual and conflitoAtual.efeito then 
        conflitoAtual.efeito() 
    end
end

local function prepararConflitoDaRodada(numeroDaRodada)
    if numeroDaRodada == 1 then
        conflitoAtual = nil
    else
        sortearConflitoRodada()
    end
end

local function desenharFundoConflito()
    love.graphics.draw(fundoConflitoSprite, conflitoX, conflitoY)
end

local function desenharConflito()
    if not conflitoAtual then return end

    love.graphics.draw(conflitoAtual.img, conflitoX, conflitoY)

    love.graphics.setColor(1,0,0)
    love.graphics.setFont(fonte.media)
    love.graphics.print(conflitoAtual.id, conflitoX+140, conflitoY+5)

    love.graphics.setFont(fonte.normal)
    love.graphics.setColor(1,1,1)
    love.graphics.print(conflitoAtual.descricao, conflitoX+140, conflitoY + CONFLITO_HEIGHT - 130)
end

---------------------------------------------------------
-- DESENHAR MENU DE TROCA NO CANTO DIREITO DA TELA
---------------------------------------------------------

local function desenharTroca()
    if not escolhendoTroca then
        return
    end

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    local largura = 260
    local altura = 160

    -- canto direito + centralizado verticalmente
    local x = sw - largura - 20
    local y = (sh - altura) / 2

    -- fundo
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", x, y, largura, altura, 12, 12)

    love.graphics.setColor(1,1,1)
    love.graphics.print("TROCA DE MOVIMENTOS", x + 20, y + 10)

    love.graphics.print("1) Trocar 1 movimento", x + 20, y + 45)
    love.graphics.print("2) Trocar 2 movimentos", x + 20, y + 70)
    love.graphics.print("3) Trocar 3 movimentos", x + 20, y + 95)

    -- mensagem de erro
    if mensagemErro ~= "" then
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.print(mensagemErro, x + 20, y + 130)
    end

    love.graphics.setColor(1,1,1)
end

function limparMensagens()
    mensagemErro = ""
    tempoErro = 0
    escolhendoTroca = false
end

--Função para o main.lua chamar quando trocar de Era
local function setEra(novaEra)
    if novaEra ~= eraAtual then
        eraAtual = novaEra

        ----------------------------------------------------
        -- 1. MOVER AS CARTAS DA ERA 2 PARA A ERA 1
        ----------------------------------------------------
        if segundasAliadas and #segundasAliadas > 0 then
            for _, carta in ipairs(segundasAliadas) do
                table.insert(primeirasAliadas, carta)
            end
            segundasAliadas = {} -- esvazia lista antiga
        end

        ----------------------------------------------------
        -- 2. MOVER CONFLITOS2 PARA CONFLITOS1
        ----------------------------------------------------
        if conflitos2 and #conflitos2 > 0 then
            for _, c in ipairs(conflitos2) do
                table.insert(conflitos1, c)
            end
            conflitos2 = {} -- limpa a lista antiga
        end

        ----------------------------------------------------
        -- 3. RECONSTRUIR O BARALHO E OS CONFLITOS
        ----------------------------------------------------
        construirBaralho()      -- usa primeirasAliadas, agora atualizada
        inicializarConflitos()  -- usa conflitos1, agora com tudo dentro
    end
end


function resetarEfeitosRodada()
    efeitosAtivos.garrafaTermica = false
    efeitosAtivos.protecaoVerde = false
    efeitosAtivos.anularConflito = false
    efeitosAtivos.sabotagem = false
end

-----------------------------------------------------------------------------------------
-- EXPORTAÇÃO
-----------------------------------------------------------------------------------------

return {
    construirBaralho = construirBaralho,
    desenharBaralho = desenharBaralho,
    reposicionarBaralho = reposicionarBaralho,

    selecionarCartasRodada = selecionarCartasRodada,
    atualizarInteracaoCartas = atualizarInteracaoCartas,
    desenharCartasRodada = desenharCartasRodada,
    desenharResultadoEscolha = desenharResultadoEscolha,
    desenharInventarioCartas = desenharInventarioCartas,
    
    setCallbacks=setCallbacks,
    aplicarEfeito=aplicarEfeito,
    mousepressed=mousepressed,
    keypressed=keypressed,
    desenharTroca = desenharTroca,
    notificarErro=notificarErro,
    limparMensagens = limparMensagens,

    prepararConflitoDaRodada = prepararConflitoDaRodada,
    desenharFundoConflito = desenharFundoConflito,
    desenharConflito = desenharConflito,

    setEra = setEra,

    resetarEfeitosRodada = resetarEfeitosRodada,

    efeitosAtivos = efeitosAtivos,
    getConflitoAtual = function () return conflitoAtual end
}