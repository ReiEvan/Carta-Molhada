local love = require("love")

local alterarAgua = nil
local alterarMovimento = nil
local getContagemVerdes = nil
local sabotagemProximaRodada = nil
local bloquearMovimentoDoGuarda = nil
local corromperAreas = nil
local conflitoAtual = nil
local getAgua = nil
local terrenoDificil = nil
local cartasEscolhaConflito = nil
local escolhaConflito = false

local virtual_Width = 1280
local virtual_Height = 720
local mx_virtual, my_virtual = 0, 0
local hoverIndex = nil

local efeitosAtivos = {
    garrafaTermica = false,
    protecaoVerde = false,
    anularConflito = false,
    sabotagem = false,
    terrenoDificil = false,
}

function resetarEfeitosRodada()
    efeitosAtivos.garrafaTermica = false
    efeitosAtivos.protecaoVerde = false
    efeitosAtivos.anularConflito = false
    efeitosAtivos.sabotagem = false
    efeitosAtivos.terrenoDificil = false
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

local eraAtual = 1

-- CARTAS ALIADAS

local primeirasAliadas = {
    {
        id = "Garrafa termica",
        img = love.graphics.newImage("sprites/carta garrafa termica.png"),
        descricao = "ganhe 1 água."
    },

-- ver sobre a permandencia da carta de clarividencia nesse contexto

    {
        id = "Movimento Livre",
        img = love.graphics.newImage("sprites/carta mov livre.png"),
        descricao = "Comece a rodada\ncom um movimento a mais"
    },

    {
        id = "Procurando água",
        img = love.graphics.newImage("sprites/carta Procurando agua.png"),
        descricao =
            "Troque 1 ação\npor 1 ficha de água.\n(3 é o limite)"
    },
}

local segundasAliadas = {
    {
        id = "Carta da Nascente",
        img = love.graphics.newImage("sprites/carta nascente.png"),
        descricao = "Ganhe 2 águas e um movimento."
    },

    {
        id = "Clarividência",
        img = love.graphics.newImage("sprites/carta 8 clarividencia.png"),
        descricao = "troque o conflito atual por um outro"
    },

    {
        id = "Esforço recompensado",
        img = love.graphics.newImage("sprites/carta Esforco recompensado.png"),
        descricao =
            "Se tiver no mínimo 5 áreas verdes\n" ..
            "(sem contar o centro)\n" ..
            "ganhe 3 fichas de água."
    },

    {
        id = "Brigada de incendio",
        img = love.graphics.newImage("sprites/carta Dissolvendo problemas.png"),
        descricao =
            "Gaste 2 fichas de águas e anule\n" ..
            "o conflitos da rodada"
    },
}

local escolhendoTroca = false
local movimentosDisponiveis = 0

local mensagemErro = ""
local tempoErro = 0

-----------------------------------------------------------------------------------------
-- EFEITOS ALIADOS
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
        mensagemErro = ""
        return
    end

    if carta.id == "Esforço recompensado" and getContagemVerdes and alterarAgua then
        local verdes = getContagemVerdes()

        if verdes > 5 then
            alterarAgua(3)
        end
    end

    if carta.id == "Clarividência" and baralhoConflitos then
        local proximoConflito = baralhoConflitos[1]
        local conflitoAtualAntesDaEscolha = conflitoAtual

        cartasEscolhaConflito = { conflitoAtualAntesDaEscolha, proximoConflito }
        efeitoDaCarta = "Escolha o conflito desta rodada (1 ou 2)"
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
local OFFSET_BETWEEN_CARDS = 5
local contadorBaralho = #primeirasAliadas
local HOVER_OFFSET = 120

local descarte = {}
local baralho = {}
local cartaSelecionada = nil
local efeitoDaCarta = nil
local escolhaBloqueada = false

local cartaPreview = nil
local PREVIEW_MARGIN = 30
local PREVIEW_WIDTH = 430
local PREVIEW_HEIGHT = 260

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
    local startX = virtual_Width - CARD_WIDTH
    local startY = virtual_Height - CARD_HEIGHT

    baralho = {}
    contadorBaralho = #primeirasAliadas

    for i = 0, contadorBaralho - 1 do
        local offsetY = i * OFFSET_BETWEEN_CARDS
        table.insert(baralho, criarFundo(startX, startY - offsetY))
    end
end

local function desenharBaralho()
    local escalaBaralho= 1.2
    for i = #baralho, 1, -1 do
        love.graphics.draw(baralho[i].transform.sprite, baralho[i].transform.x, baralho[i].transform.y,0,escalaBaralho,escalaBaralho)
    end

    if #baralho > 0 then
        local cx = baralho[#baralho].transform.x - 65
        local cy = baralho[#baralho].transform.y + 173
        love.graphics.print("Cartas: " .. contadorBaralho, cx, cy)
    end
end

local function reposicionarBaralho()
    for i, card in ipairs(baralho) do
        local offsetY = (i - 1) * OFFSET_BETWEEN_CARDS
        card.transform.x = virtual_Width - CARD_WIDTH
        card.transform.y = virtual_Height - CARD_HEIGHT - offsetY
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

    for i = 1, #primeirasAliadas do
        copia[i] = primeirasAliadas[i]
    end

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

local function selecionarCartasRodada(rodadaAtual)
    cartasRodada = {}
    cartaSelecionada = nil
    escolhaBloqueada = false
    efeitoDaCarta = nil
    cartaPreview = nil

    if #primeirasAliadas < 2 then
        for i = 1, #descarte do
            table.insert(primeirasAliadas, descarte[i])
        end

        descarte = {}
        construirBaralho()
    end

    local rodadaSabotada = sabotagemProximaRodada == true

    local carta1 = puxarCartaGarantido()
    local carta2 = puxarCartaGarantido()

    if rodadaSabotada then
        cartasRodada = {
            carta1,
            {
                real = carta2,
                id = "Sabotagem",
                img = love.graphics.newImage("sprites/conflitos/sabotagem.png"),
                descricao = "Carta sabotada: sem efeito",
                sabotada = true,
                naoSelecionavel = true
            }
        }
    else
        cartasRodada = { carta1, carta2 }
    end

    sabotagemProximaRodada = false
    contadorBaralho = #primeirasAliadas

    if rodadaAtual == 1 then
        for i, carta in ipairs(cartasRodada) do
            if carta.id == "Clarividência" then
                cartasRodada[i] = puxarCartaGarantido()
            end
        end
    end
end

-----------------------------------------------------------------------------------------
-- HOVER E DESENHO
-----------------------------------------------------------------------------------------

local function getPosicaoCarta(i)
    local v_Width = 1280
    local v_Height = 720

    local totalWidth = (#cartasRodada * CARD_WIDTH) + ((#cartasRodada - 1) * 30)
    local startX = (v_Width - totalWidth) / 2
    local posY = v_Height * 0.90

    local x = startX + (i - 1) * (CARD_WIDTH + 30)
    local y = posY

    return x, y
end

local function atualizarInteracaoCartas()
    hoverIndex = nil

    if not vx or not vy then
        mx_virtual, my_virtual = -1000, -1000
        return
    end

    mx_virtual, my_virtual = vx, vy

    for i = 1, #cartasRodada do
        local x, y = getPosicaoCarta(i)

        if mx_virtual >= x and mx_virtual <= x + CARD_WIDTH and
            my_virtual >= y and my_virtual <= y + CARD_HEIGHT then
            hoverIndex = i
        end
    end
end

local function desenharInventarioCartas()
    if not escolhendoTroca then
        local startX = 50
        local startY = 140
        local spacing = 180

        for i, c in ipairs(primeirasAliadas) do
            local x = startX + (i - 1) * spacing
            local y = startY

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

local function confirmarTroca(qtd)
    if not escolhendoTroca then
        return false
    end

    if qtd < 1 or qtd > 3 then
        return false
    end

    if qtd > (movimentosDisponiveis or 0) then
        mensagemErro = "Você não tem movimentos suficientes!"
        tempoErro = 2
        return true
    end

    if alterarMovimento then
        alterarMovimento(-qtd)
    end

    if alterarAgua then
        alterarAgua(qtd)
    end

    escolhendoTroca = false

    for i, carta in ipairs(cartasRodada) do
        if carta.id == "Procurando água" then
            cartaSelecionada = carta
            efeitoDaCarta = "Troca concluída: + água!"
            escolhaBloqueada = true
            break
        end
    end

    if conflitoAtual and conflitoAtual.efeito then
        conflitoAtual.efeito()
    end

    return true
end

local function getBotaoTrocaRect(i)
    local sw = virtual_Width
    local sh = virtual_Height

    local largura = 300
    local altura = 190

    local x = sw - largura - 20
    local y = (sh - altura) / 2

    local botaoX = x + 20
    --Espaçamento entre os botões, primeiro valor (Depois do y +) é entre o título e a primeira opção
    --Segundo valor (depois do * ) é o espaçamento de um botão para o outro
    local botaoY = y + 42 + ((i - 1) * 52)
    local botaoW = largura - 40
    local botaoH = 35

    return botaoX, botaoY, botaoW, botaoH
end


local fonte = {}
fonte.media = love.graphics.newFont(40)
fonte.normal = love.graphics.newFont(15)

local ESCURECER_ALPHA = 0.75

local function getPreviewRect()
    local w = math.min(PREVIEW_WIDTH, virtual_Width * 0.36)
    local h = math.min(PREVIEW_HEIGHT, virtual_Height * 0.42)

    local x = virtual_Width - w - PREVIEW_MARGIN
    local y = (virtual_Height - h) / 2

    return x, y, w, h
end

local function mouseDentroPreview(mx, my)
    if not cartaPreview then
        return false
    end

    local x, y, w, h = getPreviewRect()

    return mx >= x and mx <= x + w and
        my >= y and my <= y + h
end

local function desenharCartaPreview()
    if not cartaPreview then
        return
    end

    local carta = cartaPreview
    local x, y, w, h = getPreviewRect()

    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)

    local padding = 16
    local imageW = w * 0.42
    local imageH = h - padding * 2
    local imageX = x + padding
    local imageY = y + padding

    if carta.img then
        local imgW = carta.img:getWidth()
        local imgH = carta.img:getHeight()
        local escala = math.min(imageW / imgW, imageH / imgH)

        love.graphics.draw(
            carta.img,
            imageX + (imageW - imgW * escala) / 2,
            imageY + (imageH - imgH * escala) / 2,
            0,
            escala,
            escala
        )
    else
        love.graphics.rectangle("line", imageX, imageY, imageW, imageH)
    end

    local textX = imageX + imageW + 18
    local textW = w - imageW - padding * 3 - 18

    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.setFont(fonte.media)
    love.graphics.printf(carta.id or "", textX, y + padding, textW, "left")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonte.normal)
    love.graphics.printf(carta.descricao or "", textX, y + 78, textW, "left")

    love.graphics.setColor(1, 0.6, 0)
    --love.graphics.printf("Clique para selecionar", textX, y + h - 42, textW, "center")

    love.graphics.setColor(1, 1, 1)
end

local function desenharCartasRodada()
    if escolhaConflito and cartasEscolhaConflito then
        local sw, sh = virtual_Width, virtual_Height
        local largura, altura = 300, 550
        local espaco = 50
        local startX = (sw - (2 * largura + espaco)) / 2
        local startY = sh * 0.3

        love.graphics.setColor(0, 0, 0, ESCURECER_ALPHA)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        love.graphics.setColor(1, 1, 1)

        love.graphics.setFont(fonte.media)
        love.graphics.printf("Escolha o conflito para esta rodada", 0, sh * 0.02, sw, "center")

        for i, c in ipairs(cartasEscolhaConflito) do
            local x = startX + (i - 1) * (largura + espaco)
            local y = startY

            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", x , y - 150, largura, altura + 50, 12, 12)
            love.graphics.setColor(1, 1, 1)

            if c and c.img then
                local imgW, imgH = c.img:getWidth(), c.img:getHeight()
                local scale = math.min(largura / imgW, (altura - 80) / imgH)
                love.graphics.draw(c.img, x + (largura - imgW * scale) / 2, y - 130, 0, scale, scale)
            end

            love.graphics.setFont(fonte.normal)
            love.graphics.setColor(1,0,0)
            love.graphics.printf(c and c.id or "", x, y + altura - 280, largura, "center")
            love.graphics.setColor(1, 1, 1)

            love.graphics.setFont(fonte.normal)
            love.graphics.printf(c and c.descricao or "", x + 5, y + altura - 250, largura - 10)
        end

        return
    end

    for i, card in ipairs(cartasRodada) do
        if escolhaBloqueada and card == cartaSelecionada then
            goto continue
        end

        local x, y = getPosicaoCarta(i)
        local offset = (hoverIndex == i) and -HOVER_OFFSET or 0

        if card.img then
            love.graphics.draw(card.img, x, y + offset)
        end

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
            love.graphics.printf("CLIQUE PARA VER", textoX, y + offset + 120, larguraCaixa, "center")

            love.graphics.setColor(1, 1, 1)
        end

        ::continue::
    end

    desenharCartaPreview()
end

-----------------------------------------------------------------------------------------
-- RESULTADO DA ESCOLHA
-----------------------------------------------------------------------------------------

local function desenharResultadoEscolha()
    if escolhaConflito then
        return
    end

    if efeitoDaCarta then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(efeitoDaCarta, 50, 100)
        love.graphics.setColor(1, 1, 1)
    end
end

-- CONFLITOS

fonte = {}
fonte.media = love.graphics.newFont(30)
fonte.normal = love.graphics.newFont(25)

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
        descricao = "Perca uma área segura,\nou em tratamento,\naleatória exceto a que \no guarda estiver.",
        eraMinima = 1,
        efeito = function()
            if corromperAreas then
                corromperAreas(1)
            end
        end
    },

    {
        id = "Guarda inoperante",
        img = love.graphics.newImage("sprites/conflitos/Guarda inoperante.png"),
        descricao = "O guarda ficará inoperante \naté o fim da rodada",
        eraMinima = 1,
        efeito = function()
            if bloquearMovimentoDoGuarda then
                bloquearMovimentoDoGuarda()
            end
        end,
    },

    {
        id = "Sabotagem",
        img = love.graphics.newImage("sprites/conflitos/sabotagem.png"),
        descricao = "na proxima rodada \nsó tera uma carta",
        eraMinima = 1,
        efeito = function()
            sabotagemProximaRodada = true
        end
    },

    {
        id = "Terreno difícil",
        img = love.graphics.newImage("sprites/conflitos/Terreno dificil.png"),
        descricao = "Retarde o tratamento de \ntodas as áreas desse turno",
        eraMinima = 1,
        efeito = function()
            efeitosAtivos.terrenoDificil = true

            if terrenoDificil then
                terrenoDificil()
            end
        end
    }
}

local conflitos2 = {
    {
        id = "A carta cinza",
        img = love.graphics.newImage("sprites/conflitos/A carta cinza.png"),
        descricao = "Perca duas áreas seguras",
        eraMinima = 2,
        efeito = function()
            if corromperAreas then
                corromperAreas(2)
            end
        end
    },

    {
        id = "Dia quente de trabalho",
        img = love.graphics.newImage("sprites/conflitos/dia quente de trabalho.png"),
        descricao = "O guarda gasta 3 águas\nao invés de 1\ne o movimento cai em 2",
        eraMinima = 2,
        efeito = function()
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
        local j = love.math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

local function inicializarConflitos()
    baralhoConflitos = {}
    descarteConflitos = {}

    for i = 1, #conflitos1 do
        local requisito = conflitos1[i].eraMinima or 1

        if requisito <= eraAtual then
            table.insert(baralhoConflitos, conflitos1[i])
        end
    end

    embaralhar(baralhoConflitos)
end

inicializarConflitos()

local function puxarConflito()
    if #baralhoConflitos == 0 then
        for i = 1, #descarteConflitos do
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

    if conflitoAtual and conflitoAtual.id == "Terreno difícil" then
        if conflitoAtual.efeito then
            conflitoAtual.efeito()
        end
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
    local escalaConflitoF = 1.5
    love.graphics.draw(fundoConflitoSprite, conflitoX, conflitoY,0,escalaConflitoF,escalaConflitoF)
end

local function desenharConflito()
    if escolhaConflito and cartasEscolhaConflito then
        return
    elseif conflitoAtual then
        local escalaConflito = 1.5

        love.graphics.draw(conflitoAtual.img, conflitoX, conflitoY, 0, escalaConflito, escalaConflito)

        love.graphics.setColor(1, 0, 0)
        love.graphics.setFont(fonte.media)
        love.graphics.print(conflitoAtual.id, conflitoX + 202, conflitoY + 5)

        love.graphics.setFont(fonte.normal)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(conflitoAtual.descricao, conflitoX + 205, conflitoY + CONFLITO_HEIGHT - 130)

        love.graphics.setColor(1, 1, 1)
    end
end

-----------------------------------------------------------------------------------------
-- MENU DE TROCA
-----------------------------------------------------------------------------------------

local function desenharTroca()
    if not escolhendoTroca then
        return
    end

    local sw = virtual_Width
    local sh = virtual_Height

    local largura = 300
    local altura = 190

    local x = sw - largura - 20
    local y = (sh - altura) / 2

    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle("fill", x, y, largura, altura, 12, 12)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("TROCA DE MOVIMENTOS", x + 20, y + 12)

    for i = 1, 3 do
        local bx, by, bw, bh = getBotaoTrocaRect(i)

        love.graphics.setColor(0.18, 0.28, 0.45, 1)
        love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", bx, by, bw, bh, 6, 6)

        love.graphics.printf(
            "Trocar " .. i .. " movimento" .. (i > 1 and "s" or ""),
            bx,
            by + 7,
            bw,
            "center"
        )
    end



    if mensagemErro ~= "" then
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.printf(mensagemErro, x + 20, y + 162, largura - 40, "center")
    end

    love.graphics.setColor(1, 1, 1)
end

function limparMensagens()
    mensagemErro = ""
    tempoErro = 0
    escolhendoTroca = false
    cartaPreview = nil
end

local function confirmarCartaPreview(carta, moveAtual)
    if not carta then
        return false
    end

    if carta.sabotada then
        efeitoDaCarta = "Carta sabotada — escolha a outra carta."
        tempoErro=2
        cartaPreview = nil
        return false
    end

    if carta.id == "Procurando água" and alterarMovimento and alterarAgua then
        escolhendoTroca = true
        movimentosDisponiveis = tonumber(moveAtual) or 0
        mensagemErro = ""

        cartaSelecionada = carta
        escolhaBloqueada = true
        cartaPreview = nil

        return true
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

    if carta.id == "Clarividência" then
        local proximoConflito = puxarConflito()

        if proximoConflito then
            cartasEscolhaConflito = { conflitoAtual, proximoConflito }
            escolhaConflito = true

            cartaSelecionada = carta
            escolhaBloqueada = true
            efeitoDaCarta = "Futuro alterado!"
            cartaPreview = nil

            return true
        end
    end

    aplicarEfeito(carta, moveAtual)

    if conflitoAtual and conflitoAtual.efeito and not vaiAnularConflito then
        conflitoAtual.efeito()
    end

    cartaSelecionada = carta
    escolhaBloqueada = true
    cartaPreview = nil

    return true
end

local function mouseDentroBotoesTroca(mx, my)
    if not escolhendoTroca then
        return false
    end

    for i = 1, 3 do
        local x, y, w, h = getBotaoTrocaRect(i)

        if mx >= x and mx <= x + w and my >= y and my <= y + h then
            return confirmarTroca(i)
        end
    end

    return false
end


function mousepressed(mx, my, btn, moveAtual)
    if btn ~= 1 then return false end

    if escolhaBloqueada and not escolhaConflito and not escolhendoTroca then
    return false
end

    if mouseDentroBotoesTroca(mx, my) then
        return true
    end
    if escolhaConflito and cartasEscolhaConflito then
        for i, c in ipairs(cartasEscolhaConflito) do
            local sw, sh = virtual_Width, virtual_Height
            local largura, altura = 200, 250
            local espaco = 50
            local startX = (sw - (2 * largura + espaco)) / 2
            local x = startX + (i - 1) * (largura + espaco)
            local y = sh * 0.3

            if mx > x and mx < x + largura and my > y and my < y + altura then
                conflitoAtual = c

                for j, outra in ipairs(cartasEscolhaConflito) do
                    if outra ~= c then
                        table.insert(baralhoConflitos, outra)
                        embaralhar(baralhoConflitos)
                    end
                end

                if conflitoAtual.efeito then
                    conflitoAtual.efeito()
                end

                escolhaConflito = false
                cartasEscolhaConflito = nil

                return true
            end
        end

        return false
    end

    -- Primeiro clique no preview grande confirma a carta e ativa o efeito.
    if mouseDentroPreview(mx, my) then
        return confirmarCartaPreview(cartaPreview, moveAtual)
    end

    -- Clique na carta pequena apenas abre o preview.
    for i, carta in ipairs(cartasRodada) do
        local x, y = getPosicaoCarta(i)
        local offset = (hoverIndex == i) and -HOVER_OFFSET or 0

        if mx > x and mx < x + CARD_WIDTH and
            my > y + offset and my < y + offset + CARD_HEIGHT then

            if carta.sabotada then
                mensagemErro= "Carta sabotada — escolha outra carta"
                tempoErro=2
                cartaPreview=nil
                return false
            end

            cartaPreview = carta
            mensagemErro = ""
            return true
        end
    end

    return false
end

local function setEra(novaEra)
    if novaEra ~= eraAtual then
        eraAtual = novaEra

        if segundasAliadas and #segundasAliadas > 0 then
            for _, carta in ipairs(segundasAliadas) do
                table.insert(primeirasAliadas, carta)
            end

            segundasAliadas = {}
        end

        if conflitos2 and #conflitos2 > 0 then
            for _, c in ipairs(conflitos2) do
                table.insert(conflitos1, c)
            end

            conflitos2 = {}
        end

        construirBaralho()
        inicializarConflitos()
    end
end

function notificarErro(dt)
    if tempoErro > 0 then
        tempoErro = tempoErro - dt

        if tempoErro <= 0 then
            mensagemErro = ""
        end
    end
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

    getEscolhendoTroca = function()
        return escolhendoTroca
    end,

    setCallbacks = setCallbacks,
    aplicarEfeito = aplicarEfeito,
    mousepressed = mousepressed,
    desenharTroca = desenharTroca,
    notificarErro = notificarErro,
    limparMensagens = limparMensagens,

    prepararConflitoDaRodada = prepararConflitoDaRodada,
    desenharFundoConflito = desenharFundoConflito,
    desenharConflito = desenharConflito,

    setEra = setEra,
    resetarEfeitosRodada = resetarEfeitosRodada,

    efeitosAtivos = efeitosAtivos,

    getConflitoAtual = function()
        return conflitoAtual
    end
}