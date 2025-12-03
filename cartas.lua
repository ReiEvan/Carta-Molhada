local love = require ("love")
local alterarAgua = nil
local alterarMovimento = nil
local getContagemVerdes= nil
local sabotagemProximaRodada = nil
local bloquearMovimentoDoGuarda = nil
local corromperAreas = nil
local conflitoAtual = nil
local getAgua = nil
local cartasEscolhaConflito = nil
local escolhaConflito = false

-- Tabela que guarda os poderes ativos
local efeitosAtivos = {
    garrafaTermica = false,
    protecaoVerde = false,
    anularConflito = false,
    sabotagem = false,
}
-- Função para limpar os poderes quando o dia vira
function resetarEfeitosRodada()
    efeitosAtivos.garrafaTermica = false
    efeitosAtivos.protecaoVerde = false
    efeitosAtivos.anularConflito = false
    efeitosAtivos.sabotagem = false 
end

function setCallbacks(funcAgua, funcMov, funcVer, funcBloquearGuarda, funcCorromper, funcGetAgua, funcTerrenoDificil)
    alterarAgua = funcAgua
    alterarMovimento = funcMov
    getContagemVerdes = funcVer
    bloquearMovimentoDoGuarda = funcBloquearGuarda
    corromperAreas = funcCorromper
    getAgua = funcGetAgua
    terrenoDificil = funcTerrenoDificil
end



--Variavel para controlar a dificuldade
local eraAtual = 1

--//////////////////////////////////////////////////////////////////////////////////////////
--                                   CARTAS ALIADAS
--//////////////////////////////////////////////////////////////////////////////////////////

local primeirasAliadas = {
    {   
        id = "Garrafa termica",
        img = love.graphics.newImage("sprites/carta garrafa termica.png"),
        descricao = "ganhe 1 água."
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
            'Comece a rodada com um movimento a mais'
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
        id = "Carta da Nascente",
        img = love.graphics.newImage("sprites/carta nascente.png"),
        descricao = "Ganhe 2 águas e um movimento."
    },
    {
        id = "Esforço recompensado",
        img = love.graphics.newImage('sprites/carta Esforco recompensado.png'),
        descricao=
            'Se tiver no mínimo 5 áreas verdes\n'..
            '(sem contar o centro)\n'..
            'ganhe 3 fichas de água.'
    },
    {
        id = "Brigada de incendio",
        img = love.graphics.newImage("sprites/carta Dissolvendo problemas.png"),
        descricao=
            'Gaste 2 águas e anule\n'..
            'o conflitos da rodada'

    },
    
      

}  
--id = "Carta Dourada",
       -- img = love.graphics.newImage("sprites/carta dourada.png"),
        --descricao =
         --   "Escolha uma área verde\n".. 
        --    "(exceto o ponto de origem).\n" ..
        --    "Ela não pode ser perdida \n".. 
        --    "por cartas de conflito"

-- estado de troca
local escolhendoTroca = false
local movimentosDisponiveis = 0

-- erro
local mensagemErro = ""
local tempoErro = 0


-----------------------------------------------------------------------------------------
-- efeitos aliados
----------------------------------------------------------------------------------------- 

function aplicarEfeito(carta, valorMove)
    if carta.id == "Carta da Nascente" and alterarAgua and alterarMovimento then
        alterarAgua(2) 
        alterarMovimento(1)
    end

    if carta.id == "Garrafa termica" and alterarAgua then
        alterarAgua(1)
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

    if carta.id == "Esforço recompensado" and getContagemVerdes and alterarAgua then
        local verdes = getContagemVerdes()
        if verdes > 5 then -->5 pois a área do centro não conta
            alterarAgua(3)
        end
    end

   if carta.id == "Clarividência" and baralhoConflitos then
    -- Pega o conflito atual e o próximo
    local proximoConflito = baralhoConflitos[1]  -- próximo conflito
    local conflitoAtualAntesDaEscolha = conflitoAtual  -- conflito atual antes da escolha

    -- Coloca ambos disponíveis para escolha
    cartasEscolhaConflito = { conflitoAtualAntesDaEscolha, proximoConflito }

    -- Aviso visual
    efeitoDaCarta = "Escolha o conflito desta rodada (1 ou 2)"

    -- Bloqueia seleção normal de cartas até escolher o conflito
    escolhendoTroca = true
    escolhaConflito = true
    return
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

    -- Garante baralho funcional
    if #primeirasAliadas < 2 then
        for i = 1, #descarte do
            table.insert(primeirasAliadas, descarte[i])
        end
        descarte = {}
        construirBaralho()
    end

    -- Se a sabotagem foi ativada na rodada anterior
    local rodadaSabotada = sabotagemProximaRodada == true

    -- Sempre puxamos DUAS cartas
    local carta1 = puxarCartaGarantido()
    local carta2 = puxarCartaGarantido()

    if rodadaSabotada then
        -- A rodada tem 2 cartas, mas uma delas é sabotada
        cartasRodada = {
            carta1,
            {
                -- copia da carta2, porém sabotada visualmente
                real = carta2,
                id = "Sabotagem",
                img = love.graphics.newImage("sprites/conflitos/sabotagem.png"),
                descricao = "Carta sabotada: sem efeito",
                sabotada = true,
                naoSelecionavel = true

            }
        }

    else
        -- Rodada normal
        cartasRodada = { carta1, carta2 }
    end



    -- Consome a sabotagem
    sabotagemProximaRodada = false

    contadorBaralho = #primeirasAliadas
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





function keypressed(key)
    -- Se não estamos na troca, apenas ignoramos teclas
    if not escolhendoTroca then return end

    -- Aceita apenas 1,2 ou 3
    local qtd = tonumber(key)
    if not qtd then return end
    if qtd < 1 or qtd > 3 then return end

    -- Checa se tem movimentos suficientes
    if qtd > movimentosDisponiveis then
        mensagemErro = "Você não tem movimentos suficientes!"
        tempoErro = 2
        return
    end

    -- Aplica troca (movimento negativo)
    if alterarMovimento then
        alterarMovimento(-qtd)
    end
    if alterarAgua then
        alterarAgua(qtd)
    end

    -- Sai do modo troca
    escolhendoTroca = false

    -- Marca a carta como selecionada
    for i, carta in ipairs(cartasRodada) do
        if carta.id == "Procurando água" then
            cartaSelecionada = carta
            efeitoDaCarta = "Troca concluída: + água!"
            escolhaBloqueada = true
            break
        end
    end

    -- Agora aplica o conflito da rodada
    if conflitoAtual and conflitoAtual.efeito then
        conflitoAtual.efeito()
    end
end


function notificarErro(dt)
    if tempoErro > 0 then
        tempoErro = tempoErro - dt
        if tempoErro <= 0 then mensagemErro = "" end
    end
end

local fonte = {}
fonte.media = love.graphics.newFont(20)
fonte.normal = love.graphics.newFont(15)

local ESCURECER_ALPHA = 0.75  -- opacidade do fundo escuro durante a escolha

local function desenharCartasRodada()
    --=== SE ESTÁ ESCOLHENDO CLARIVIDÊNCIA ===
    if escolhaConflito and cartasEscolhaConflito then
        local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
        local largura, altura = 200, 250
        local espaco = 50
        local startX = (sw - (2 * largura + espaco)) / 2
        local startY = sh * 0.3

        -- Fundo escurecido
        love.graphics.setColor(0, 0, 0, ESCURECER_ALPHA)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        love.graphics.setColor(1,1,1)

        -- Título
        love.graphics.setFont(fonte.media)
        love.graphics.printf("Escolha o conflito para esta rodada", 0, sh*0.15, sw, "center")

        -- Desenha os dois conflitos
        for i, c in ipairs(cartasEscolhaConflito) do
            local x = startX + (i-1) * (largura + espaco)
            local y = startY

            -- Carta/fundo
            love.graphics.setColor(0.2,0.2,0.2,1)
            love.graphics.rectangle("fill", x, y, largura, altura, 12, 12)
            love.graphics.setColor(1,1,1)

            -- Imagem do conflito
            if c.img then
                local imgW, imgH = c.img:getWidth(), c.img:getHeight()
                local scale = math.min(largura/imgW, (altura-80)/imgH)
                love.graphics.draw(c.img, x + (largura-imgW*scale)/2, y + 10, 0, scale, scale)
            end

            -- Título e descrição
            love.graphics.setFont(fonte.media)
            love.graphics.printf(c.id, x, y + altura - 65, largura, "center")
            love.graphics.setFont(fonte.normal)
            love.graphics.printf(c.descricao, x + 5, y + altura - 50, largura-10, "center")
        end

        return
    end

    --=== DESENHO NORMAL DAS CARTAS DE RODADA ===
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local totalWidth = (#cartasRodada * CARD_WIDTH) + ((#cartasRodada - 1) * 30)
    local startX = (screenWidth - totalWidth) / 2
    local posY = screenHeight * 0.90

    for i, card in ipairs(cartasRodada) do
        if escolhaBloqueada and card == cartaSelecionada then
            goto continue
        end

        local x = startX + (i - 1) * (CARD_WIDTH + 30)
        local y = posY
        local offset = (hoverIndex == i) and -HOVER_OFFSET or 0

        if card.img then
            love.graphics.draw(card.img, x, y + offset)
        end

        -- Hover visual
        if hoverIndex == i then
            local textoX = (i == 1) and (x - 220) or (x + CARD_WIDTH + 20)
            local larguraCaixa, alturaCaixa = 200, 150

            love.graphics.setColor(0.2, 0.2, 0.2, 0.75)
            love.graphics.rectangle("fill", textoX - 10, y + offset + 10, larguraCaixa + 20, alturaCaixa)

            love.graphics.setColor(0.2, 0.4, 1)
            love.graphics.printf(card.id, textoX, y + offset + 20, larguraCaixa)

            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(card.descricao, textoX, y + offset + 45, larguraCaixa)

            love.graphics.setColor(1, 0.6, 0)
            love.graphics.printf("CLIQUE NA CARTA", textoX, y + offset + 120, larguraCaixa, "center")

            love.graphics.setColor(1, 1, 1)
        end

        ::continue::
    end
end






-----------------------------------------------------------------------------------------
-- RESULTADO DA ESCOLHA
-----------------------------------------------------------------------------------------

local function desenharResultadoEscolha()
    if escolhaConflito and cartasEscolhaConflito then
        local sw = love.graphics.getWidth()
        local sh = love.graphics.getHeight()

        local largura = 150
        local altura = 200
        local espaco = 50
        local startX = (sw - (2 * largura + espaco)) / 2
        local startY = sh * 0.3

        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", startX-10, startY-10, 2*largura + espaco + 20, altura + 20)
        love.graphics.setColor(1,1,1)

        love.graphics.print("Escolha o conflito da rodada:", startX, startY-30)

        for i, c in ipairs(cartasEscolhaConflito) do
            local x = startX + (i-1) * (largura + espaco)
            love.graphics.draw(c.img, x, startY)
            love.graphics.printf(i, x, startY + altura + 5, largura, "center")
            love.graphics.printf(c.id, x, startY + altura + 25, largura, "center")
            love.graphics.printf(c.descricao, x, startY + altura + 45, largura, "center")
        end

        return
    end

    -- Caso normal: desenha o efeitoDaCarta
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
        descricao = "Perca uma área segura ou em tratamento aleatória, exceto a que o guarda estiver.", -- Descrição ajustada
        eraMinima = 1,
        -- BLOCO NOVO ABAIXO:
        efeito = function()
            if corromperAreas then
                corromperAreas(1) -- Transforma 1 hex
            end
        end
    },

    {
    id = "Guarda inoperante",
    img = love.graphics.newImage("sprites/conflitos/Guarda inoperante.png"),
    descricao = "O guarda ficará inoperante até o fim da rodada",
    eraMinima = 1,
    efeito = function()
        -- usa o callback para bloquear o guarda por esta rodada
        if bloquearMovimentoDoGuarda then
            bloquearMovimentoDoGuarda()
        end
    end,
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
    descricao = "Retarde o tratamento de todas as áreas desse turno",
    eraMinima = 1,
    efeito = function()
        tratamentoDasAreasPausado = true
    end
    }

}
local conflitos2={
    {
        id = "A carta cinza",
        img = love.graphics.newImage("sprites/conflitos/A carta cinza.png"),
        descricao = "Perca duas áreas seguras", -- Descrição ajustada
        eraMinima = 2,
        -- BLOCO NOVO ABAIXO:
        efeito = function()
            if corromperAreas then
                corromperAreas(2) -- Transforma 2 hexs
            end
        end
    },
    {
        id = "Dia quente de trabalho",
        img = love.graphics.newImage("sprites/conflitos/dia quente de trabalho.png"),
        descricao = "O guarda gasta 3 águas ao invés de 1 e o movimento cai em 2",
        eraMinima = 2,
        efeito = function ()
            if alterarAgua and alterarMovimento then 
                alterarAgua(-2)
                alterarMovimento(-2)
            end
        end
    },
}

-----------------------------------------------------------------------------------------
-- BARALHO DE CONFLITOS
-----------------------------------------------------------------------------------------

local baralhoConflitos = {}
local descarteConflitos = {}

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
    --if conflitoAtual and conflitoAtual.efeito then 
    --    conflitoAtual.efeito() 
    --end
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
    if escolhaConflito and cartasEscolhaConflito then
        -- MOSTRA OS DOIS CONFLITOS LADO A LADO
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        
        local totalWidth = (#cartasEscolhaConflito * CONFLITO_WIDTH) + 30
        local startX = (screenWidth - totalWidth) / 2
        local posY = screenHeight * 0.2

        for i, c in ipairs(cartasEscolhaConflito) do
            love.graphics.draw(fundoConflitoSprite, startX + (i-1)*(CONFLITO_WIDTH + 30), posY)
            love.graphics.draw(c.img, startX + (i-1)*(CONFLITO_WIDTH + 30), posY)

            love.graphics.setColor(1,0,0)
            love.graphics.setFont(fonte.media)
            love.graphics.print(c.id, startX + (i-1)*(CONFLITO_WIDTH + 30) + 140, posY + 5)

            love.graphics.setFont(fonte.normal)
            love.graphics.setColor(1,1,1)
            love.graphics.print(c.descricao, startX + (i-1)*(CONFLITO_WIDTH + 30) + 140, posY + CONFLITO_HEIGHT - 130)

            -- número da escolha
            love.graphics.setColor(1,1,0)
            love.graphics.print("Pressione "..i, startX + (i-1)*(CONFLITO_WIDTH + 30) + 50, posY + CONFLITO_HEIGHT + 10)
            love.graphics.setColor(1,1,1)
        end

    elseif conflitoAtual then
        -- comportamento normal
        love.graphics.draw(conflitoAtual.img, conflitoX, conflitoY)

        love.graphics.setColor(1,0,0)
        love.graphics.setFont(fonte.media)
        love.graphics.print(conflitoAtual.id, conflitoX+140, conflitoY+5)

        love.graphics.setFont(fonte.normal)
        love.graphics.setColor(1,1,1)
        love.graphics.print(conflitoAtual.descricao, conflitoX+140, conflitoY + CONFLITO_HEIGHT - 130)
    end
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


function mousepressed(mx, my, btn, moveAtual)
    if btn ~= 1 then return false end
    if escolhaBloqueada then return false end

    --=== SE ESTAMOS ESCOLHENDO CONFLITO COM CLARIVIDÊNCIA ===
    if escolhaConflito and cartasEscolhaConflito then
        for i, c in ipairs(cartasEscolhaConflito) do
            local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
            local largura, altura = 200, 250
            local espaco = 50
            local startX = (sw - (2 * largura + espaco)) / 2
            local x = startX + (i-1) * (largura + espaco)
            local y = sh * 0.3

            if mx > x and mx < x + largura and my > y and my < y + altura then
                -- Carta escolhida se torna conflito da rodada
                conflitoAtual = c

                -- Retorna o outro conflito para o baralho e embaralha
                for j, outra in ipairs(cartasEscolhaConflito) do
                    if outra ~= c then
                        table.insert(baralhoConflitos, outra)
                        embaralhar(baralhoConflitos)
                    end
                end

                -- Aplica efeito do conflito agora
                if conflitoAtual.efeito then
                    conflitoAtual.efeito()
                end

                -- Limpa estado de escolha
                escolhaConflito = false
                cartasEscolhaConflito = nil
                return true
            end
        end
        return false
    end

    --=== SELEÇÃO NORMAL DE CARTAS ===
    for i, carta in ipairs(cartasRodada) do
        local x, y = getPosicaoCarta(i)
        if mx > x and mx < x + CARD_WIDTH and my > y and my < y + CARD_HEIGHT then

            if carta.sabotada then
                efeitoDaCarta = "Carta sabotada — sem efeito."
                return false
            end

            -- Procurando água ativa troca
            if carta.id == "Procurando água" and alterarMovimento and alterarAgua then
                escolhendoTroca = true
                movimentosDisponiveis = tonumber(moveAtual) or 0
                mensagemErro = ""
                return true  -- não aplica conflito nem marca cartaSelecionada
            end

            local vaiAnularConflito = false
            if carta.id == "Brigada de incendio" then
                if getAgua and getAgua() < 2 then
                    mensagemErro = "Água insuficiente! Custo: 2"
                    tempoErro = 2
                    return false
                end
                if alterarAgua then alterarAgua(-2) end
                vaiAnularConflito = true
                efeitoDaCarta = "Conflito Anulado!"
            end

            -- Clarividência ativa escolha de conflitos
            if carta.id == "Clarividência" then
                local proximoConflito = puxarConflito()
                if proximoConflito then
                    cartasEscolhaConflito = { conflitoAtual, proximoConflito }
                    escolhaConflito = true
                    return true
                end
            end

            -- Aplica efeito da carta
            aplicarEfeito(carta, moveAtual)

            -- Aplica conflito somente se não anula
            if conflitoAtual and conflitoAtual.efeito and not vaiAnularConflito then
                conflitoAtual.efeito()
            end

            cartaSelecionada = carta
            escolhaBloqueada = true
            return true
        end
    end
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