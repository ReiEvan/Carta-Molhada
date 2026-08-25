local love = require "love"
local os = love.system.getOS()

local button = require "Button"
local hitbox = require "hitbox"
local ost = require "OST"
cartas = require ("cartas")
local push = require "push"
local FonteNumeros = require "FonteNumeros"
local ManualTutorial = require "ManualTutorial"
local Conquistas = require "conquistas"

mostrarAvisoCarta = true --Controla se o aviso de escolha de carta deve aparecer ou não
local volumeMaster = 0.5 -- 50% do volume
local manualAberto = false --Controla se o manual está aberto ou não
local primeiraVezAberto = true --Controla se é a primeira vez que o manual é aberto, para mostrar a primeira página
local totalBandeirasConquistadas = 0 --Controla quantas bandeiras foram conquistadas no total, para mostrar o fato educativo correspondente

--------------ALTURA E LARGURA QUE IREMOS USAR AGORA-----------------
local virtual_Width = 1280
local virtual_Height = 720
---------------------------------------------------------------------

local ehMobile = (os == "Android" or os == "iOS")

local game = {
    state = {
        menu = true,
        config = false,
        paused = false,
        running = false,
        ended = false,
        creditos = false,
        conquistas = false
    },
    points = 0,
}

local telaAnterior = "menu"

--Pra explicar bem esse caso aqui, ele faz uma verificação com o "ehMobile"
--Depois ele faz o booleano, se for true é a primeira opção se for false é a segunda
local volumeSlider = {
    x = virtual_Width / 2 - (ehMobile and 200 or 100), --Posição inicial de X
    y = virtual_Height / 2, --Posição Y
    largura = ehMobile and 400 or 200, --Tamanho da barra
    altura = ehMobile and 25 or 10, --Grossura da barra
    raioBola = ehMobile and 24 or 12, --Tamanho do circulo de arrastar
    valor = 0.5, --O volume vai de 0.0 a 1.0
    arrastando = false --Controla se o mouse está clicando/arrastando
}

-- função que gerencia a quantidade de água
local agua = 5
local movimentosRestantes = 3
function alterarAgua(qtd)
    agua = agua + qtd
    if agua >= 6 then
        Conquistas.desbloquear("reserva_cheia")
    end
    if agua < 0 then agua = -1 end
end
local function getAgua()
    return agua
end
function alterarMovimento(qtd)
    movimentosRestantes = movimentosRestantes + qtd
end

local guardasBloqueados = false
local guardaBloqueado = false
function setBloqueioGuardas(ativo)
    guardasBloqueados = ativo or false
end
local terrenoDificil = false
local function setTerrenoDificil(ativo)
    terrenoDificil = ativo or false
end

function voltarMenu()
    game.state["config"] = false
    game.state["paused"] = false
    game.state["creditos"] = false
    game.state["menu"] = true
end

function voltarDasConfiguracoes()
    game.state["config"] = false

    if telaAnterior == "paused" then
        game.state["paused"] = true --Se veio da pausa, volta pra pausa
    else
        game.state["menu"] = true --Se veio do menu, volta pro menu
    end
end

function creditosParaMenu()

   if game.state["creditos"] then
        game.state["creditos"] = false
        game.state["menu"] = true
        game.state["config"] = false
        game.state["paused"] = false
        game.state["running"] = false
    end
end

function pausarJogo()
    if game.state["running"] then
        game.state["running"] = false
        game.state["paused"] = true
    end
end

function voltarJogo()
    game.state["menu"] = false
    game.state["config"] = false
    game.state["paused"] = false
    game.state["running"] = true
end

local function abrirConquistas()
    game.state["menu"] = false
    game.state["conquistas"] = true
end

local function fecharConquistas()
    game.state["conquistas"] = false
    game.state["menu"] = true
end

function love.resize(width, height)
    push:resize(width, height)
end

local movimento={
        mx=10,
        my=220
}

local esperandoEscolhaCarta = true --Começa true para obrigar a escolha no dia 1

local bg_escalax = 1
local bg_escalay = 1
local escala = 0.5
local rodada = 1
local numGuardas = 1

local card_back_image
local fonte= {}
local hexAtivos = {}
local hexVermelho = love.graphics.newImage("sprites/HEXÁGONO-Vermelho.png")
local hexMarrom = love.graphics.newImage("sprites/HEXÁGONO-Marrom.png")
local escalaHex = 0.1111
local rodadasPorPonto = {}
local estadoTransformacao = {}
local pontosBloqueados = {}


--Variaveis de Vitória/Derrota
local imgBandeira = love.graphics.newImage("sprites/Bandeira_vermelha.png")
local imgBandeiraConquistada = love.graphics.newImage("sprites/bandeira_branca.png")
local objetivosExternos =  {}
local objetivosRecompensados = {}
local totalAreasVerdes = 0

--Textos de fim de jogo

local fimDeJogo = {
    ativo = false,
    mensagem = "",
    cor = {1, 1, 1}
}

local fatosEducativos = {
    {
        titulo = "BANDEIRA I: O PULMÃO DO PLANETA",
        texto = "Mais de 50% do oxigênio da Terra vem dos oceanos, produzido por algas microscópicas (fitoplâncton). Proteger as águas é proteger o próprio ar que respiramos!",
        fonte = "Fonte: NOAA & UNESCO"
    },
    {
        titulo = "BANDEIRA II: A FORÇA DAS MARÉS",
        texto = "A atração da Lua e do Sol move trilhões de litros de água diariamente. Esse fluxo distribui nutrientes vitais e equilibra a temperatura do planeta.",
        fonte = "Fonte: NASA Ocean Motion & IPCC"
    },
    {
        titulo = "BANDEIRA III: CIDADES SUBMARINAS",
        texto = "Os recifes de coral cobrem menos de 1% do solo oceânico, mas abrigam mais de 25% de toda a vida marinha conhecida na Terra.",
        fonte = "Fonte: UNEP / PNUMA & ICRI"
    },
    {
        titulo = "BANDEIRA IV: COMBATE AOS PLASTICOS",
        texto = "Cerca de 8 milhões de toneladas de lixo entram no oceano por ano, virando microplásticos. Sua vitória ajudou a conter esse ciclo na ilha!",
        fonte = "Fonte: Science (Jambeck et al.)"
    }
}

local modalFato = {
    ativo = false,
    fila = {},
    titulo = "",
    texto = "",
    fonte = "",
    largura = 620,
    altura = 300,
    --Posição do botão para continuar dentro desse modal
    btnX = 0,
    btnY = 0,
    btnW = 180,
    btnH = 45
}

local function exibirProximoFato()
    if #modalFato.fila > 0 then
        local fato = table.remove(modalFato.fila, 1)
        modalFato.titulo = fato.titulo
        modalFato.texto = fato.texto
        modalFato.fonte = fato.fonte
        modalFato.ativo = true
    else
        modalFato.ativo = false
    end
end

function enfileirarFato(indiceFato)
    if fatosEducativos[indiceFato] then
        table.insert(modalFato.fila, fatosEducativos[indiceFato])
        if not modalFato.ativo then
            exibirProximoFato()
        end
    end
end


local movimento={
    mx=10,
    my=220
}

local imagemAgua={
        ficha=love.graphics.newImage("sprites/ficha gota.png"),
        fx=movimento.mx-5, fy=movimento.my+25
    }


--Nova lógica de movimento para o double click
local hexFocado = nil

local rodadaAtiva = false
local deck = {}
--lista de pontos de movimentação
local pontosMovimentacao = {

    {x = virtual_Width/2 + 15, y = virtual_Height/2 - 245, raio = 45},
    {x = virtual_Width/2 + 15, y = virtual_Height/2 - 145, raio = 45},
    {x = virtual_Width/2 + 15, y = virtual_Height/2 - 45, raio = 45},
    {x = virtual_Width/2 + 15, y = virtual_Height/2 + 55, raio = 45},
    {x = virtual_Width/2 + 15, y = virtual_Height/2 + 155, raio = 45},--5
    {x = virtual_Width/2 + 190, y = virtual_Height/2 - 145, raio = 45},
    {x = virtual_Width/2 + 190, y = virtual_Height/2 - 45, raio = 45},--7
    {x = virtual_Width/2 + 190, y = virtual_Height/2 + 55, raio = 45},
    {x = virtual_Width/2 - 160, y = virtual_Height/2 - 145, raio = 45},
    {x = virtual_Width/2 - 160, y = virtual_Height/2 - 45, raio = 45},--10
    {x = virtual_Width/2 - 160, y = virtual_Height/2 + 55, raio = 45},
    {x = virtual_Width/2 + 100, y = virtual_Height/2 - 195, raio = 45},--12
    {x = virtual_Width/2 + 100, y = virtual_Height/2 - 95, raio = 45},
    {x = virtual_Width/2 + 100, y = virtual_Height/2 + 5, raio = 45},
    {x = virtual_Width/2 + 100, y = virtual_Height/2 + 105, raio = 45},
    {x = virtual_Width/2 - 75, y = virtual_Height/2 - 195, raio = 45},
    {x = virtual_Width/2 - 75, y = virtual_Height/2 - 95, raio = 45},
    {x = virtual_Width/2 - 75, y = virtual_Height/2 + 5, raio = 45},
    {x = virtual_Width/2 - 75, y = virtual_Height/2 + 105, raio = 45}

}

--Pontos adjascentes dos Hex
local pontosAdjascentes = {
    [1] = {2,12,16},
    [2] = {1,3,12,13,16,17},
    [3] = {2,4,13,14,17,18},
    [4] = {3,5,14,15,18,19},
    [5] = {4,15,19},
    [6] = {7,12,13},
    [7] = {6,8,13,14},
    [8] = {7,14,15},
    [9] = {10,16,17},
    [10] = {9,11,17,18},
    [11] = {10,18,19},
    [12] = {1,2,6,13},
    [13] = {2,3,6,7,12,14},
    [14] = {3,4,7,8,13,15},
    [15] = {4,5,8,14},
    [16] = {1,2,9,17},
    [17] = {2,3,9,10,16,18},
    [18] = {3,4,10,11,17,19},
    [19] = {4,5,11,18}
}

--Estado do guarda (onde ele está)
local movGuarda = {
    x = pontosMovimentacao[3].x,
    y = pontosMovimentacao[3].y,
    indiceAtual = 3,
    imagem = love.graphics.newImage("sprites/Guardinha.png"),
    destino = nil,
    velocidade = 200,
    raioColisao = 30,
    interagindo = false,
    direcao = "direita",
    frameAtual = 1,
    quadros = {}
}

function confirmarMovimentoDireto(destIndex)
    if guardasBloqueados or guardaBloqueado then return end

    local pontoDestino = pontosMovimentacao[destIndex]

    movGuarda.destino = {x = pontoDestino.x, y = pontoDestino.y}
    movimentosRestantes = movimentosRestantes - 1

    if destIndex ~= 3 and not pontosBloqueados[destIndex] then
        if objetivosExternos[1] and destIndex == objetivosExternos[1] then
            hexAtivos[destIndex] = 2
            estadoTransformacao[destIndex] = true
            rodadasPorPonto[destIndex] = 0
        elseif not hexAtivos[destIndex] then
                hexAtivos[destIndex] = 1
                estadoTransformacao[destIndex] = false
                rodadasPorPonto[destIndex] = 0
                
        elseif hexAtivos[destIndex] == 1 then
                hexAtivos[destIndex] = 2
                estadoTransformacao[destIndex] = true
                rodadasPorPonto[destIndex] = 0
        end
    end
end

function updateSlider(dt)
    local mx, my = love.mouse.getPosition()

    local vx, vy = push:toGame(mx, my)

    if not vx or not vy then return end

    local mousePressionado = love.mouse.isDown(1)

    --Se o jogador clicar perto da bolinha, começa a arrastar
    if mousePressionado and not volumeSlider.arrastando then
        local bolinhaX = volumeSlider.x + (volumeSlider.largura * volumeSlider.valor)
        local dist = math.sqrt((vx - bolinhaX)^2 + (vy - volumeSlider.y)^2)
        if dist < volumeSlider.raioBola + 10 then
            volumeSlider.arrastando = true
        end
    end

    --Se soltar o mouse, para de arrastar
    if not mousePressionado then
        volumeSlider.arrastando = false
    end

    -- Enquanto arrasta, calcula o novo valor baseado na posição X do mouse
    if volumeSlider.arrastando then
        local novoValor = (vx - volumeSlider.x) / volumeSlider.largura
        --Trava o valor entre 0 e 1
        volumeSlider.valor = math.max(0, math.min(1, novoValor))
        --Aplica o volume no jogo
        love.audio.setVolume(volumeSlider.valor)
    end
end

function desenharSlider()
    --Desenha a barra (fundo)
    love.graphics.setColor(0.2, 0.2, 0.2) --Cinza escuro
    love.graphics.rectangle("fill", volumeSlider.x, volumeSlider.y - volumeSlider.altura/2, volumeSlider.largura, volumeSlider.altura, 5)

    --Desenha a parte preechida
    love.graphics.setColor(0, 0.7, 1) --Azul brilhante
    love.graphics.rectangle("fill", volumeSlider.x, volumeSlider.y - volumeSlider.altura/2, volumeSlider.largura * volumeSlider.valor, volumeSlider.altura, 5)

    --desenha a bolinha
    local bolinhaX = volumeSlider.x + (volumeSlider.largura * volumeSlider.valor)
    love.graphics.setColor(1, 1, 1) -- Branco
    love.graphics.circle("fill", bolinhaX, volumeSlider.y, volumeSlider.raioBola)

    --Texto da porcentagem
    love.graphics.setColor(0, 0, 1) -- Azul
    if ehMobile then
        love.graphics.print(math.floor(volumeSlider.valor * 100) .. "%", volumeSlider.x + volumeSlider.largura + 35, volumeSlider.y - 18, 0.13)
    else
        FonteNumeros.desenhar(math.floor(volumeSlider.valor * 100) .. "%", volumeSlider.x + volumeSlider.largura + 20, volumeSlider.y - 18, 0.13)
    end

    love.graphics.setColor(1, 1, 1) --Resetar cor
end


-- Função para transformar áreas limpas de volta em Vermelhas
local function corromperAreas(qtd)
    local candidatos = {}

    for i = 1, #pontosMovimentacao do
        -- CRITÉRIOS DE SELEÇÃO:
        -- 1. Ignora onde o guarda está (segurança).
        -- 2. Ignora o que já é vermelho (hexAtivos[i] ~= 1).
        -- 3. Ignora a Base (índice 3).
        if i ~= movGuarda.indiceAtual and hexAtivos[i] ~= 1 and i ~= 3 then
            table.insert(candidatos, i)
        end
    end

    -- Se não houver ninguém para corromper, sai da função
    if #candidatos == 0 then return end

    -- Embaralha a lista de candidatos (Sorteio)
    for i = #candidatos, 2, -1 do
        local j = love.math.random(i)
        candidatos[i], candidatos[j] = candidatos[j], candidatos[i]
    end

    -- Aplica a mudança apenas na quantidade pedida
    local limite = math.min(qtd, #candidatos)

    for k = 1, limite do
        local idx = candidatos[k]

        -- AQUI A MÁGICA ACONTECE:
        hexAtivos[idx] = 1              -- 1. Volta visualmente para Vermelho

        pontosBloqueados[idx] = nil     -- 2. CRUCIAL: Desbloqueia o ponto.
                                        -- (Se estava verde, estava bloqueado. Agora precisa ser jogável de novo)

        rodadasPorPonto[idx] = 0        -- 3. Zera contagem de dias acumulados
        estadoTransformacao[idx] = false -- 4. Reseta estado de transformação

        print("Área corrompida (voltou a ser vermelha): " .. idx)
    end
end



-- Função que bloqueia o guarda por esta rodada (será passada como callback para cartas.lua)
local function bloquearGuardaPorRodada()
    guardaBloqueado = true
    -- se já estiver indo para algum destino, cancela o movimento imediatamente
    movGuarda.destino = nil
end

-- Funcao auxiliar para encontrar um valor em uma lista (substitui table.find)
local function findInTable(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

local function atualizarContagemVerdes()
    local contagem = 0
    for i = 1, #pontosMovimentacao do
        --Se for nil, significa que não é vermelho nem marrom
        if hexAtivos[i] == nil then
            contagem = contagem + 1
        end
    end
    totalAreasVerdes = contagem
end

local function getContagemVerdes()
    return totalAreasVerdes
end


local function ehAdjascente(origem, destino)
    return pontosAdjascentes[origem] and findInTable(pontosAdjascentes[origem], destino) ~= nil
end

local function movimentoPermitido(origem, destino)
    if not ehAdjascente(origem, destino) then
        return false
    end
--Estado atual e do destino
    local estadoAtual = hexAtivos[origem]
    local estadoDestino = hexAtivos[destino]
    --Se está em uma zona nil, pode se mover para o vermelho
    if estadoAtual == nil then
        return true
    end
    --Se está em uma zona vermelha ou marrom, não pode mover para o vermelho
    if estadoDestino == 1 then
        return false
    end
    --Se chegou aqui pode mover para vazio ou marrom
    return true
end


-- Sistema de eras
local eraAtual = 1
local telaEra = {
    ativa = false,
    tempoTotal = 4, --O tempo da tela de mudança de era
    timer = 0,
    titulo = "ERA II",
    texto = "AS INDÚSTRIAS TE DESCOBRIRAM...\nNOVOS PERIGOS SURGEM."
}


--Estados possiveis do hexagono
--nil: vazio (permitido)
--1: vermelho (permitido)
--2: marrom (não permitido)
local function atualizarEstadosHexagonos(indice)
    if hexAtivos[indice] == 1 then
        --hexagono vermelho
        return true
    elseif hexAtivos[indice] == 2 then
        --hexagono marrom
        return false
    else
        return true
    end
end






local function definirObjetivos()
    objetivosExternos = {}

    --Bandeira mais próxima, vou pôr num lugar fixo
    local bandeiraTutorial = 2
    table.insert(objetivosExternos, bandeiraTutorial)

    local possiveis = {}
    --Lista todos os pontos que não são a base (3) nem adjascentes a ela
    local vizinhosBase = pontosAdjascentes[3]
    local vizinhosTutorial = pontosAdjascentes[bandeiraTutorial]

    for i = 1, #pontosMovimentacao do
        local ehInvalido = (i == 3) or (i == bandeiraTutorial)

        if vizinhosBase and findInTable(vizinhosBase, i) then
            ehInvalido = true
        end

        if vizinhosTutorial and findInTable(vizinhosBase, i) then
            ehInvalido = true
        end

        if not ehInvalido then
            table.insert(possiveis, i)
        end
    end

    --Sorteia as outras 3 bandeiras com distanciamento
    local qtdDesejada = 4
    --Enquanto não tiver 4 bandeiras e ainda houver lugares possiveis
    while #objetivosExternos < qtdDesejada and #possiveis > 0 do

        --sorteia um índice da lista de possíveis
        local randIndex = love.math.random(1, #possiveis)
        local escolhido = possiveis[randIndex]

        --Adiciona aos objetivos
        table.insert(objetivosExternos, escolhido)

        --Nova lista de possiveis removendo o escolhido
        local novaListaPossiveis = {}

        for _, candidato in ipairs(possiveis) do
            local deveManter = true
            if candidato == escolhido then
                deveManter = false
            else
                local vizinhoDoEscolhido = pontosAdjascentes[escolhido]
                if vizinhoDoEscolhido and findInTable(vizinhoDoEscolhido, candidato) then
                    deveManter = false
                end
            end
            if deveManter then
                table.insert(novaListaPossiveis, candidato)
            end
        end
        possiveis  = novaListaPossiveis
    end
end

local menuAgua = {
    ativa = false,
    botoes = {}
}


local player ={
    radius = 13,
    x = 30,
    y = 30
}

local buttons = {
    menu_state = {},
    config_state = {},
    running_state = {},
    paused_state = {},
    creditos_state = {},
    conquistas_state = {}
}

function proxRodada()
    --Mensagem de escolha a carta
    if esperandoEscolhaCarta then
        mostrarAvisoCarta = true
        return
    end

    alterarAgua(-1)
    cartas.limparMensagens()

    -- === 1. PROCESSAR ÁREAS (Usando os efeitos da rodada que ACABOU) ==
    local diasPadrao = 2
    if cartas.efeitoAtivos and cartas.efeitosAtivos.terrenoDificil then
        diasPadrao = 3
    end

    for i = 1, #pontosMovimentacao do
        if rodadasPorPonto[i] then
            rodadasPorPonto[i] = rodadasPorPonto[i] + 1

            --Para a primeira bandeira
            local diasNecessarios = diasPadrao
            if objetivosExternos[1] and i == objetivosExternos[i] then
                diasNecessarios = 1
            end

            if estadoTransformacao[i] and rodadasPorPonto[i] >= diasNecessarios then
                hexAtivos[i] = nil
                estadoTransformacao[i] = nil
                rodadasPorPonto[i] = nil
                pontosBloqueados[i] = true
                -- Lógica da recompensa da bandeira
                for idxBandeira, objIndex in ipairs(objetivosExternos) do
                    if i == objIndex and not objetivosRecompensados[i] then
                        objetivosRecompensados[i] = true
                        alterarAgua(1)
                        totalBandeirasConquistadas = totalBandeirasConquistadas + 1

                        if totalBandeirasConquistadas == 1 then
                            Conquistas.desbloquear("primeira_gota")
                        end

                        --Fato educativo correspondente a bandeira
                        enfileirarFato(totalBandeirasConquistadas)
                    end
                end
            end
        end
    end

    -- === 2. RESETAR EFEITOS (Prepara terreno limpo para a próxima rodada) ===
    cartas.resetarEfeitosRodada()
    guardaBloqueado = false

    -- === 3. PREPARAR NOVA RODADA (Sorteia novos conflitos e efeitos) ===
    rodada = rodada + 1
    movimentosRestantes = 3

    -- Sorteia cartas novas (pode ativar Terreno Difícil para a PRÓXIMA rodada)
    cartas.selecionarCartasRodada(rodada)
    cartas.prepararConflitoDaRodada(rodada)

    esperandoEscolhaCarta = true
    mostrarAvisoCarta = true

    -- Lógica de mudança de era
    local contagemBandeiras = 0
    for _, idx in ipairs(objetivosExternos) do
        if hexAtivos[idx] == nil then
            contagemBandeiras = contagemBandeiras + 1
        end
    end

    if contagemBandeiras >= 2 and eraAtual == 1 then
        eraAtual = 2
        telaEra.ativa = true
        telaEra.timer = telaEra.tempoTotal
        cartas.setEra(eraAtual)
        Conquistas.desbloquear("era_industrial")
    end
end


--Lógica de mudança de era
local contagemBandeiras = 0
for _, idx in ipairs(objetivosExternos) do
    if hexAtivos[idx] == nil then
        contagemBandeiras = contagemBandeiras + 1
    end
end
--Se conquistou 2 ou mais e ainda está na Era 1
if contagemBandeiras >= 2 and eraAtual == 1 then
    eraAtual = 2

    --Ativa o feedback visual
    telaEra.ativa = true
    telaEra.timer = telaEra.tempoTotal

    --Avisa o módulo de cartas que a era mudou
    cartas.setEra(eraAtual)
end

local function creditos()
    game.state["menu"] = false
    game.state["config"] = false
    game.state["paused"] = false
    game.state["running"] = false
    game.state["creditos"] = true
end

local function configuracoes()
    if game.state["menu"] then
        telaAnterior = "menu"
    elseif game.state["paused"] or game.state["running"] then
        telaAnterior = "paused"
    end

    game.state["menu"] = false
    game.state["config"] = true
    game.state["paused"] = false
    game.state["running"] = false

end

local function startNewGame()
    game.state["menu"] = false
    game.state["config"] = false
    game.state["paused"] = false
    game.state["running"] = true
    definirObjetivos()

    if primeiraVezAberto then
        manualAberto = true
        primeiraVezAberto = false --Garante q o tutorial só apareça na primeira vez que o jogo é iniciado
    end

    --Resetar variaveis de jogo se necessário
    rodada = 1
    agua = 5
    numGuardas = 1
    movimentosRestantes = 3
    fimDeJogo.ativo = false
    modalFato.ativo = false
    modalFato.fila = {}

    --Resetar recompensas, eras e baralhos
    objetivosRecompensados = {}
    eraAtual = 1
    cartas.resetarJogo()
    telaEra.ativa = false
    totalBandeirasConquistadas = 0

    --Resetar o Guarda para a Base
    movGuarda.indiceAtual = 3
    movGuarda.x = pontosMovimentacao[3].x
    movGuarda.y = pontosMovimentacao[3].y
    movGuarda.destino = nil
    guardaBloqueado = false
    --Resetar o mapa
    hexAtivos = {}
    estadoTransformacao = {}
    rodadasPorPonto = {}
    pontosBloqueados = {}

    for i = 1, #pontosMovimentacao do
        if i ~= 3 then
            --configura como vermelho de novo
            hexAtivos[i] = 1
            estadoTransformacao[i] = false
            rodadasPorPonto[i] = 0
        else
            --A base começa limpa
            hexAtivos[i] = nil
        end
    end

    --Refazer os objetivos aleatórios (bandeiras)
    definirObjetivos()

    --Inicio do ciclo de jogo: Escolher carta -> conflito -> ação
    cartas.resetarEfeitosRodada()
    cartas.selecionarCartasRodada(rodada)
    esperandoEscolhaCarta = true --Força a escolha no turno 1
    mostrarAvisoCarta = true
end

local button_states = {
    menu = buttons.menu_state,
    running = buttons.running_state,
    config = buttons.config_state,
    paused = buttons.paused_state,
    creditos = buttons.creditos_state
}

function handle_button_click(x, y, radius)

    local current_state = game.state.menu and "menu_state"
                        or game.state.running and "running_state"
                        or game.state.config and "config_state"
                        or game.state.paused and "paused_state"
                        or game.state.creditos and "creditos_state"

    if current_state and buttons[current_state] then
        for _, btn in pairs(buttons[current_state]) do
            btn:checkPressed(x, y, radius)

        end
    end

end

local function verificarEstadoJogo()
    if fimDeJogo.ativo then return end
-----------------------Condições de Derrota: -----------------------
--Passar da rodada 20
    if rodada >20 then
        fimDeJogo.ativo = true
        fimDeJogo.mensagem = "DERROTA\nO tempo acabou!"
        fimDeJogo.cor = {1, 0, 0}
        return
    end
--Ficar sem areas verdes
    local temVerde = false
    for i = 1, #pontosMovimentacao do
        if hexAtivos[i] == nil and not pontosBloqueados[i] then
            temVerde = true
            break
        end
    end
    if not temVerde then
        fimDeJogo.ativo = true
        fimDeJogo.mensagem = "DERROTA\nEstá tudo contaminado!"
        fimDeJogo.cor = {57, 255, 20}
        return
    end
 --Ficar sem água
    if agua < 0 then
        fimDeJogo.ativo = true
        fimDeJogo.mensagem = "DERROTA\nSem água!"
        fimDeJogo.cor = {0.5, 0, 0}
    end
----------------------- Condições de Vitória (Triunfo) ----------------
    local objetivosConquistados = 0
    for _, objIndex in ipairs(objetivosExternos) do
        if hexAtivos[objIndex] == nil then
            objetivosConquistados = objetivosConquistados + 1
        end
    end
--Checa se cumpriu os dois requisitos (4 bandeiras)
    if objetivosConquistados >= 4 then
        fimDeJogo.ativo = true
        fimDeJogo.mensagem =string.format("TRIUNFO!\nVocê salvou a ilha\n em %s dias com\n %s águas restantes", rodada, agua)
        fimDeJogo.cor = {0.18, 0.44, 0.25}
        Conquistas.desbloquear("guardiao_ilha")
    end
end

--função para o mouse no menu e in game
function love.mousepressed(x, y, button, isTouch, presses)
    local gx, gy = push:toGame(x, y)

    if not gx or not gy then
        return
    end

    x, y = gx, gy

    if button ~= 1 then return end

    if game.state["paused"] then
        handle_button_click(gx, gy, player.radius)
        return
    end

    if game.state["menu"] then
        handle_button_click(gx, gy, player.radius)
        return
    end

    if game.state["config"] then
        handle_button_click(gx, gy, player.radius)
        return
    end

    if game.state["creditos"] then
        handle_button_click(gx, gy, player.radius)
        return
    end

    if game.state["conquistas"] then
        handle_button_click(gx, gy, player.radius)
        return
    end

if game.state["running"] then
    -- Bloqueio e clique do modal educativo
    if modalFato.ativo then
        --Verifica se clicou no botão dentro do modal
        if gx >= modalFato.btnX and gx <= modalFato.btnX + modalFato.btnW and
           gy >= modalFato.btnY and gy <= modalFato.btnY + modalFato.btnH then
            exibirProximoFato()
        end
        return -- Bloqueia qualquer clique no tabuleiro ou nas cartas enquanto o fato estiver aberto
    end

    -- Bloqueio do tutorial: Se o tutorial estiver aberto, não permite clicar em nada fora dele
    if manualAberto then
        -- Mudamos aqui para manualTutorial.mousepressed para manter o seu padrão!
        -- Para evitar que ele pule páginas, dentro do manualTutorial.lua você pode usar uma trava simples de clique se necessário
        -- mas mantendo mousepressed aqui, seu fluxo de entrada fica 100% unificado.
        local acao = ManualTutorial.mousepressed(gx, gy, button)
        if acao == "fechar" then
            manualAberto = false
        end
        return -- Bloqueia os cliques de passar para o tabuleiro ou para as cartas
    end

    -- Verificar se clicou no botão "Tutorial" na hud
    if gx >= 1150 and gx <= 1250 and gy >= 20 and gy <= 60 then
        manualAberto = true
        return
    end

    handle_button_click(gx, gy, player.radius)

    -- >>> AQUI ENTRA A LÓGICA DO AVISO! <<<
    if esperandoEscolhaCarta then
        local cartaFoiEscolhida = cartas.mousepressed(gx, gy, button, movimentosRestantes)
        if cartaFoiEscolhida then
            esperandoEscolhaCarta = false
            mostrarAvisoCarta = false -- O jogador escolheu a carta, então sumimos com o aviso!
        end
        return
    end

    if cartas.getEscolhendoTroca() then
        cartas.mousepressed(gx, gy, button, movimentosRestantes)
        return
    end

    cartas.mousepressed(gx, gy, button, movimentosRestantes)

    -- Teste 1: O jogo está registrando o clique dentro do estado running?
    print("Clique detectado na gameplay! x:", gx, "y:", gy)

    if movGuarda.destino == nil then
        local origem = movGuarda.indiceAtual
        local clicouEmAlgumHex = false

        for i, ponto in ipairs(pontosMovimentacao) do
            local distancia = math.sqrt((ponto.x - gx)^2 + (ponto.y - gy)^2)
            if distancia <= ponto.raio then
                clicouEmAlgumHex = true
                local indiceDestino = i

                -- Teste 2: O clique colidiu com a hitbox de um hexágono?
                print("Colidiu com o Hexágono número: " .. indiceDestino)

                if movimentosRestantes > 0 and movimentoPermitido(origem, indiceDestino) then
                    -- Teste 3: As regras de movimento permitiram o foco?
                    print("Movimento permitido! Hex Focado atual era:", hexFocado)

                    if hexFocado == indiceDestino then
                        print("-> SEGUNDO CLIQUE CONSTITUÍDO! Movendo guarda...")
                        confirmarMovimentoDireto(indiceDestino)
                        hexFocado = nil
                    else
                        print("-> PRIMEIRO CLIQUE! Focando no hex:", indiceDestino)
                        hexFocado = indiceDestino
                    end
                else
                    print("Movimento NÃO permitido pelas regras ou sem movimentos restantes.")
                end
                break
            end
        end

        -- Movemos essa checagem para fora do bloco do guarda para garantir o clique fora
        if not clicouEmAlgumHex then
            print("Clicou fora de qualquer hexágono. Resetando foco.")
            hexFocado = nil
        end
    else
        print("Guarda já está se movendo, clique ignorado.")
    end
end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    volumeSlider.arrastando = false
end


function love.load()
    -------------COISAS DO PUSH LUA------------------
    local gameWidth, gameHeight = 1280, 720 --Resolução que o jogo vai fingir ter

    local windowWidth, windowHeight = love.window.getDesktopDimensions()

    push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, {
        fullscreen = false,
        resizable = true,
        pixelperfect = false,
        canvas = true, --Isso permite que o LOVE trate o jogo como uma textura
        stretched = false,
        highdpi = true
    })

    love.resize(love.graphics.getWidth(), love.graphics.getHeight())


    FonteNumeros.load("sprites/numeros")
    local centroX = virtual_Width / 2
    local centroY = virtual_Height / 2

    --------------------------CONQUISTAS-------------------------
    Conquistas.carregar()

    --Botão para abrir Conquistas no menu
    buttons.menu_state.conquistas = button(opcoesNormal, abrirConquistas, nil, 250, nil, opcoesClicado)
    buttons.menu_state.conquistas.x = centroX - 50
    buttons.menu_state.conquistas.y = centroY + 175

    --Botão voltar da tela de Conquistas
    buttons.conquistas_state.back = button(voltarNormal, fecharConquistas, nil, 150, 50)
    buttons.conquistas_state.back.x = centroX - 75
    buttons.conquistas_state.back.y = centroY + 260

    ------------IMAGENS DO JOGO--------------------
    movGuarda.imagem = love.graphics.newImage("sprites/Guardinha.png")
    local continuarNormal = love.graphics.newImage("sprites/Continuar.png")
    local voltarNormal = love.graphics.newImage("sprites/Voltar.png")
    local menuNormal = love.graphics.newImage("sprites/Menu2.png")
    local pauseBtn = love.graphics.newImage("sprites/pause.png")
    local reiniciarBtn = love.graphics.newImage("sprites/reiniciar2.png")
    local reiniciarNormal = love.graphics.newImage("sprites/ReiniciarMaior2.png")
    local startNormal = love.graphics.newImage("sprites/botão_iniciar.png")
    local startClicado = love.graphics.newImage("sprites/botão_iniciar_clicado.png")
    local opcoesNormal = love.graphics.newImage("sprites/botão_opções.png")
    local opcoesNormal2 = love.graphics.newImage("sprites/botão_opções2.png")
    local opcoesClicado = love.graphics.newImage("sprites/botão_opções_clicado.png")
    local sairNormal = love.graphics.newImage("sprites/botão_sair.png")
    local sairNormal2 = love.graphics.newImage("sprites/botão_sair2.png")
    local sairClicado = love.graphics.newImage("sprites/botão_sair_clicado.png")
    local prxmDiaNormal = love.graphics.newImage("sprites/botão_prxm_Dia.png")
    local prxmDiaClicado = love.graphics.newImage("sprites/botão_prxm_Dia_Clicado.png")

-------------------------------------------------------------------
if not ehMobile then
    love.mouse.setVisible(false)
end

    love.mouse.setVisible(false)
    love.window.setTitle("Última Gota")
    fonte.grande = love.graphics.newFont(40)
    fonte.media = love.graphics.newFont(30)
    fonte.normal = love.graphics.newFont(13)
    love.graphics.setFont(fonte.normal)
    ost.somteste()

    --Só pra lembrar button(ImagemNormal, Função, Parametro, Largura, Altura, ImagemPressionada)
    buttons.menu_state.play_game = button(startNormal, startNewGame, nil, 250, 100, startClicado)
    buttons.menu_state.play_game.x = centroX - 30
    buttons.menu_state.play_game.y = centroY - 50

    buttons.menu_state.settings = button(opcoesNormal, configuracoes, nil, 250, nil, opcoesClicado)
    buttons.menu_state.settings.x = centroX - 50
    buttons.menu_state.settings.y = centroY + 100

    buttons.menu_state.exit_game = button(sairNormal, love.event.quit, nil, 150, 90, sairClicado)
    buttons.menu_state.exit_game.x = centroX - 30
    buttons.menu_state.exit_game.y = centroY + 250

    --Botões nas configurações do jogo
    local cx = virtual_Width / 2
    local cy = virtual_Height / 2

    -- Botão Voltar (Nas configurações)
    buttons.config_state.back = button(voltarNormal, voltarDasConfiguracoes, nil, 150, 50)
    buttons.config_state.back.x = cx - 75
    buttons.config_state.back.y = cy + 150

    buttons.config_state.creditos = button("creditos", creditos, nil, 150, 50)
    buttons.config_state.creditos.x = cx - 75
    buttons.config_state.creditos.y = cy + 150


    --x aumenta pra direita e y pra baixo

    -- Botão Voltar (Nos creditos)
    buttons.creditos_state.back = button(voltarNormal, creditosParaMenu, nil, 150, 50)
    buttons.creditos_state.back.x = cx + 490
    buttons.creditos_state.back.y = cy - 350

    --Botões no jogo pausado
    buttons.paused_state.resume = button(continuarNormal, voltarJogo, nil, 220, 60)
    buttons.paused_state.resume.x = cx - 100
    buttons.paused_state.resume.y = cy - 50
    buttons.paused_state.exit_to_menu = button(menuNormal, voltarMenu, nil, 160, 50)
    buttons.paused_state.exit_to_menu.x = cx + 100
    buttons.paused_state.exit_to_menu.y = cy + 100
    buttons.paused_state.settings = button(opcoesNormal2, configuracoes, nil, 180, 70)
    buttons.paused_state.settings.x = cx - 100
    buttons.paused_state.settings.y = cy + 100
    buttons.paused_state.restart = button(reiniciarNormal, startNewGame, nil, 200, 50)
    buttons.paused_state.restart.x = cx - 100
    buttons.paused_state.restart.y = cy + 100
    buttons.paused_state.exit_game = button(sairNormal2, love.event.quit, nil, 100, 60)
    buttons.paused_state.exit_game.x = cx
    buttons.paused_state.exit_game.y = cy + 150

    --Botões no jogo rodando
    buttons.running_state.pass_rodada = button(prxmDiaNormal, proxRodada, nil, 150, 60, prxmDiaClicado)
    buttons.running_state.pause_in_game = button(pauseBtn, pausarJogo, nil, 50, 50)
    buttons.running_state.restart_in_game = button(reiniciarBtn, startNewGame, nil, 50, 50)
    
    buttons.running_state.baralho_pass_rodada = button("Baralho", proxRodada, nil, 150, 290)
    buttons.running_state.baralho_pass_rodada.invisivel = true

    --Botões do Menu de Água (Carta)
    local cx, cy = virtual_Width/2 - 70, virtual_Height/2 - 50


    --Iniciar o jogo com os Hex vermelhos
        for i = 1, #pontosMovimentacao do
            if i ~= 3 then
                hexAtivos[i] = 1
                estadoTransformacao[i] = false
                rodadasPorPonto[i] = 0

            end

        end

--baralho azul
    cartas.construirBaralho()

-- carregar cartas aleatórias
    cartas.selecionarCartasRodada(rodada)

--Configura a posição inicial do guarda
    movGuarda.x = pontosMovimentacao[movGuarda.indiceAtual].x
    movGuarda.y = pontosMovimentacao[movGuarda.indiceAtual].y

    local larguraQuadro = movGuarda.imagem:getWidth()
    local alturaQuadro = movGuarda.imagem:getHeight()

    movGuarda.quadros = {}
    for i = 1, 4 do
        table.insert(movGuarda.quadros, love.graphics.newQuad(
            (i-1) * larguraQuadro, 0,
            larguraQuadro, alturaQuadro,
            movGuarda.imagem:getDimensions()
        ))
    end
    cartas.setCallbacks(
    alterarAgua,alterarMovimento,getContagemVerdes,bloquearGuardaPorRodada, corromperAreas, getAgua, setTerrenoDificil)
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    local vx, vy = push:toGame(mx, my)

    if vx and vy then
        player.x, player.y = vx, vy
    end

    Conquistas.update(dt)

    cartas.atualizarInteracaoCartas(vx, vy)
    cartas.reposicionarBaralho()
    cartas.notificarErro(dt)
    --Atualiza o timer da tela de Era
    if telaEra.ativa then
        telaEra.timer = telaEra.timer - dt
        if telaEra.timer <= 0 then
            telaEra.ativa = false
        end
    end

    if game.state["config"] then
        updateSlider(dt)
    end

    if movGuarda.destino then
        local dx = movGuarda.destino.x - movGuarda.x
        local dy = movGuarda.destino.y - movGuarda.y
        local distancia = math.sqrt(dx*dx + dy*dy)

        if distancia > movGuarda.velocidade * dt then
            local direcao = {dx = dx/distancia, dy = dy/distancia}
            movGuarda.x = movGuarda.x + direcao.dx * movGuarda.velocidade * dt
            movGuarda.y = movGuarda.y + direcao.dy * movGuarda.velocidade * dt
        else
            movGuarda.x = movGuarda.destino.x
            movGuarda.y = movGuarda.destino.y

            for i, ponto in ipairs(pontosMovimentacao) do
                if math.abs(ponto.x - movGuarda.x) < 5 and
                    math.abs(ponto.y - movGuarda.y) < 5 then
                        movGuarda.indiceAtual = i
                    break
                end
            end
            movGuarda.destino = nil
        end
    end

    if game.state["running"] then
        verificarEstadoJogo()
        atualizarContagemVerdes()
    end
end

-- Carregamento do mapa
local mapa = love.graphics.newImage("sprites/mapagradeado.png")
local background= love.graphics.newImage("sprites/FUNDO TELA INICIAL (20251130094623).png")
local game_bg = love.graphics.newImage("sprites/FUNDO_Gameplay.png")
local pause_bg = love.graphics.newImage("sprites/FUNDO_acinzentado.png")
local config_bg = love.graphics.newImage("sprites/FUNDO_acinzentado.png")
local regras = love.graphics.newImage("sprites/RegrasDoJogo.jpeg")
local movImg = love.graphics.newImage("sprites/Movimentos_Arte.png")
local diaImg = love.graphics.newImage("sprites/Dia_Arte.png")
local configText = love.graphics.newImage("sprites/CONFIG.png")
local diaLimiteImg = love.graphics.newImage("sprites/diaLimite.png")
local creditosimg = love.graphics.newImage("sprites/creditos.png")
function love.draw()
    push:start()--Inicia a renderização na resolução virtual
     if game.state["running"] then
        --Arte do Fundo da gameplay
        --love.graphics.print(text,x,y,r,sx,sy,ox,oy)
        --love.graphics.draw(drawable,x,y,r,sx,sy,ox,oy)
        love.graphics.draw(game_bg, 0, 0, 0, 0.7, 0.7)
        --Movimentos Restantes
        love.graphics.setFont(fonte.grande)
        love.graphics.draw(movImg, movimento.mx, movimento.my + 230, 0, 0.25, 0.25)
        love.graphics.setColor(0,0,1)
        FonteNumeros.desenhar(movimentosRestantes, movimento.mx + 270, movimento.my + 245, 0.23)
        love.graphics.setFont(fonte.normal)
        --love.graphics.setColor(0, 100, 0)  -- verde
        love.graphics.setColor(1,1,1)
        --Feddback visual da quantidade de agua
        love.graphics.draw(imagemAgua.ficha, imagemAgua.fx, imagemAgua.fy + 300, 0, escala + 0.5, escala + 0.5)
        love.graphics.setColor(0, 0, 1)
        FonteNumeros.desenhar(agua, imagemAgua.fx+80, imagemAgua.fy+328, 0.3)
        love.graphics.setColor(1, 1, 1)
        --Numeração da rodada atuals
        love.graphics.draw(diaImg, virtual_Width/2 - 100, 0.5, 0, 0.2, 0.2)
        love.graphics.setColor(0,0,1)
        if rodada > 9 then
            love.graphics.draw(diaLimiteImg, virtual_Width/2 + 40, 15, 0, 0.2, 0.2)
            FonteNumeros.desenhar(rodada, virtual_Width/2 - 15, virtual_Height/2 - 350, 0.24)
        else
            love.graphics.draw(diaLimiteImg, virtual_Width/2 + 10, 15, 0, 0.2, 0.2)
            FonteNumeros.desenhar(rodada, virtual_Width/2 - 10, virtual_Height/2 - 350, 0.24)
        end
        love.graphics.setFont(fonte.normal)
        love.graphics.setColor(1,1,1)
        -- Desenhar mapa As coordenadas x crescem para a direita e y para baixo
        --desenhar o mapa
        love.graphics.draw(mapa, virtual_Width/2 - 400, virtual_Height/2 - 370, 0, .35, .35)
        --Desenhar os filtros vermelhos e marrons
        for i, ponto in ipairs(pontosMovimentacao) do
            if i ~= 3 then
                if hexAtivos[i] == 1 then
                    love.graphics.draw(hexVermelho,
                        ponto.x - hexVermelho:getWidth() * escalaHex / 2,
                        ponto.y - hexVermelho:getHeight() * escalaHex / 2,
                        0, escalaHex, escalaHex)
                    elseif hexAtivos[i] == 2 then
                        love.graphics.draw(hexMarrom,
                        ponto.x - hexMarrom:getWidth() * escalaHex / 2,
                        ponto.y - hexMarrom:getHeight() * escalaHex / 2,
                        0, escalaHex, escalaHex)

                    end
                end
-------------------------------CÓDIGO PRÉ PRONTO PRO SPRITE DA BORDA DO HEX SELECIONADO--------------------
            if hexFocado == i then
                --Quando o sprite tiver pronto é só descomentar as duas linhas de baixo
                --local spriteBorda = love.graphics.newImage("sprites/Borda.png")
                --love.graphics.draw(spriteborda, ponto.x - spriteborda:getWidth() * escalaHex / 2, ponto.y - spriteborda:getHeight() * escalaHex / 2, 0, escalaHex, escalaHex)
                 love.graphics.setColor(1, 1, 0, 0.5) -- Amarelo para destacar
                 love.graphics.circle("line", ponto.x, ponto.y, ponto.raio + 5) -- Círculo ao redor do hex selecionado
                 love.graphics.setColor(1, 1, 1) -- Resetar cor para branco
            end
------------------------------------------------------------------------------------------------------------
        end
        --Desenhar Bandeira nos Objetivos Externos
        love.graphics.setColor(1, 1, 1)
        for _, indice in ipairs(objetivosExternos) do
            local p = pontosMovimentacao[indice]

            local imagemParaDesenhar = imgBandeira --Bandeira Vermelha
            local escalaAtual = 0.25
            local ajusteX = 15
            local ajusteY = 70

            if hexAtivos[indice] == nil then
                imagemParaDesenhar = imgBandeiraConquistada --Bandeira branca

                escalaAtual = 0.25
                ajusteX = 15
                ajusteY = 70
            end

            --Desenha a bandeira um pouco acima do centro do hex
            --Ajuste o offset (x, y) e a escala (0.5) conforme o tamanho da imagem
            love.graphics.draw(imagemParaDesenhar, p.x - ajusteX, p.y - ajusteY, 0, escalaAtual, escalaAtual)
        end

        -- Guardinha florestal
        if  movGuarda.quadros[movGuarda.frameAtual] then
        love.graphics.draw(movGuarda.imagem, movGuarda.quadros[movGuarda.frameAtual], movGuarda.x-90, movGuarda.y-50, 0, 0.09, 0.09)
        else
            love.graphics.draw(movGuarda.imagem, movGuarda.x-20, movGuarda.y-20)
        end
        cartas.desenharTroca()
        cartas.desenharFundoConflito()
        cartas.desenharConflito()
        cartas.desenharBaralho()
        cartas.desenharCartasRodada()
        cartas.desenharResultadoEscolha()


        --Desenhar a hitbox enquanto o jogo ta rodando
        hitbox.desenhar(virtual_Width/2 + 15, virtual_Height/2 - 245, 45)
        hitbox.desenhar(virtual_Width/2 + 15, virtual_Height/2 - 145, 45)
        hitbox.desenhar(virtual_Width/2 + 15, virtual_Height/2 - 45, 45)
        hitbox.desenhar(virtual_Width/2 + 15, virtual_Height/2 + 55, 45)
        hitbox.desenhar(virtual_Width/2 + 15, virtual_Height/2 + 155, 45) --5
        hitbox.desenhar(virtual_Width/2 + 190, virtual_Height/2 - 145, 45)
        hitbox.desenhar(virtual_Width/2 + 190, virtual_Height/2 + 55, 45)
        hitbox.desenhar(virtual_Width/2 + 190, virtual_Height/2 - 45, 45)
        hitbox.desenhar(virtual_Width/2 - 160, virtual_Height/2 - 145, 45)
        hitbox.desenhar(virtual_Width/2 - 160, virtual_Height/2 - 45, 45)
        hitbox.desenhar(virtual_Width/2 - 160, virtual_Height/2 + 55, 45)
        hitbox.desenhar(virtual_Width/2 + 100, virtual_Height/2 - 195, 45)
        hitbox.desenhar(virtual_Width/2 + 100, virtual_Height/2 - 95, 45)
        hitbox.desenhar(virtual_Width/2 + 100, virtual_Height/2 + 105, 45)
        hitbox.desenhar(virtual_Width/2 + 100, virtual_Height/2 + 5, 45)
        hitbox.desenhar(virtual_Width/2 - 75, virtual_Height/2 - 195, 45)
        hitbox.desenhar(virtual_Width/2 - 75, virtual_Height/2 - 95, 45)
        hitbox.desenhar(virtual_Width/2 - 75, virtual_Height/2 + 5, 45)
        hitbox.desenhar(virtual_Width/2 - 75, virtual_Height/2 + 105, 45)

        --Desenhar os botões enquato o jogo ta rodando
        buttons.running_state.pass_rodada:draw(virtual_Width - 155, virtual_Height - 250, 10, 10)
        --Botão invisivel do baralho
        buttons.running_state.baralho_pass_rodada:draw(virtual_Width - 155, virtual_Height - 180)

        if fimDeJogo.ativo then
            --Fundo preto
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", 0, 0, virtual_Width, virtual_Height)
            --Texto
            love.graphics.setFont(fonte.grande)
            love.graphics.setColor(unpack(fimDeJogo.cor))
            love.graphics.printf(fimDeJogo.mensagem, 0, virtual_Height/2 - 50, virtual_Width, "center")
        end
        --Botões por cima do game rodando
        buttons.running_state.pause_in_game:draw(virtual_Width - 250, 10, 0, 0)
        buttons.running_state.restart_in_game:draw(virtual_Width - 150, 10, 0, 0)

        if mostrarAvisoCarta and not telaEra.ativa and not fimDeJogo.ativo then
            local larguraJanela = push:getWidth()
            local alturaJanela = push:getHeight()

            local larguraCaixa = 450
            local alturaCaixa = 80

            local x = (virtual_Width - larguraCaixa) / 2
            local y = 80

            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", x, y, larguraCaixa, alturaCaixa, 10, 10)

            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, larguraCaixa, alturaCaixa, 10, 10)

            love.graphics.setFont(fonte.normal)
            love.graphics.setColor(1, 1, 1, 1)
            local texto = "Escolha uma carta para inicar a rodada!"

            local alturaFonte = love.graphics.getFont():getHeight()
            love.graphics.printf(
                texto,
                x,
                y + (alturaCaixa - alturaFonte) / 2,
                larguraCaixa,
                "center"
            )
        end


        --DESENHAR TELA DE TRANSIÇÃO DE ERA
        if telaEra.ativa then
            --Fundo preto semitransparente
            love.graphics.setColor(0, 0, 0, 0.85)
            love.graphics.rectangle("fill", 0, 0, virtual_Width, virtual_Height)

            --Texto
            love.graphics.setColor(1, 1, 1, 1)

            --Título grande
            love.graphics.setFont(fonte.grande)
            love.graphics.printf(telaEra.titulo, 0, virtual_Height/2 - 60, virtual_Width, "center")

            --Subtítulo/lore
            love.graphics.setFont(fonte.media)
            love.graphics.printf(telaEra.texto, 0, virtual_Height/2, virtual_Width, "center")

            --Restaura a cor
            love.graphics.setColor(1, 1, 1, 1)

        end

        --Tutorial
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", 1200, 20, 30, 40, 5, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("?", 1210, 30)

        if manualAberto then
            ManualTutorial.draw()
        end


        
        --RENDER DO MODAL DOS FATOS EDUCATIVOS
        if modalFato.ativo then
            local mx = (virtual_Width - modalFato.largura) / 2
            local my = (virtual_Height - modalFato.altura) / 2
            
            modalFato.btnX = virtual_Width / 2 - modalFato.btnW / 2
            modalFato.btnY = my + modalFato.altura - 60
            
            --1. Fundo escurecido da tela inteira (Backdrop)
            love.graphics.setColor(0, 0, 0, 0.75)
            love.graphics.rectangle("fill", 0, 0, virtual_Width, virtual_Height)

            --2. Caixa principal do Pop-up
            love.graphics.setColor(0.08, 0.15, 0.25, 0.95)
            love.graphics.rectangle("fill", mx, my, modalFato.largura, modalFato.altura, 12, 12)
            
            --3. Titulo da conquista
            love.graphics.setColor(1, 0.85, 0.2, 1)
            love.graphics.setFont(fonte.media)
            love.graphics.printf(modalFato.titulo, mx + 20, my + 20, modalFato.largura - 40, "center")
            
            --4. Texto Educativo / Curiosidade
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(fonte.normal)
            love.graphics.printf(modalFato.texto, mx + 30, my + 75, modalFato.largura - 60, "center")
            
            --5. Referência / Fonte
            love.graphics.setColor(0.7, 0.7, 0.7, 0.9)
            love.graphics.printf(modalFato.fonte, mx + 30, my + 175, modalFato.largura - 60, "center")
            
            --6. Botão "Continuar"
            love.graphics.setColor(0.18, 0.6, 0.3, 1)
            love.graphics.rectangle("fill", modalFato.btnX, modalFato.btnY, modalFato.btnW, modalFato.btnH, 8, 5)
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", modalFato.btnX, modalFato.btnY, modalFato.btnW, modalFato.btnH, 8, 8)
            
            love.graphics.setFont(fonte.normal)
            love.graphics.printf("CONTINUAR", modalFato.btnX, modalFato.btnY + 16, modalFato.btnW, "center")
            
            --RESETAR A COR
            love.graphics.setColor(1, 1, 1, 1)
        end

        ------------------------------- CONQUISTAS ---------------------------
        if game.state["conquistas"] then
            love.graphics.draw(pause_bg, 0, 0, 0, 1, 1)

            love.graphics.setFont(fonte.grande)
            love.graphics.setColor(1, 0.85, 0.2)
            love.graphics.printf("CONQUISTAS E FATOS", 0, 40, virtual_Width, "center")

            love.graphics.setFont(fonte.normal)
            local yPos = 120

            for _, c in pairs(Conquistas.lista) do
                local larguraCaixa = 820
                local alturaCaixa = 85
                local xBox = (virtual_Width - larguraCaixa) / 2

                if c.desbloqueada then
                    love.graphics.setColor(0.1, 0.18, 0.28, 0.95)
                else
                    love.graphics.setColor(0.12, 0.12, 0.12, 0.75)
                end
                love.graphics.rectangle("fill", xBox, yPos, larguraCaixa, alturaCaixa, 8, 8)

                love.graphics.setColor(c.desbloqueada and {1, 0.85, 0.2} or {0.35, 0.35, 0.35})
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", xBox, yPos, larguraCaixa, alturaCaixa, 8, 8)

                if c.desbloqueada then
                    love.graphics.setColor(1, 0.85, 0.2)
                    love.graphics.print("★ " .. c.nome, xBox + 20, yPos + 10)

                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(c.desc, xBox + 20, yPos + 32)

                    love.graphics.setColor(0.4, 0.85, 1)
                    love.graphics.print("Fato: " .. c.fato, xBox + 20, yPos + 54)
                else
                    love.graphics.setColor(0.6, 0.6, 0.6)
                    love.graphics.print("? ? ? (Bloqueado)", xBox + 20, yPos + 22)
                    love.graphics.print("Continue jogando para desbloquear esta conquista.", xBox + 20, yPos + 46)
                end

                yPos = yPos + 95

            end

            local b = buttons.conquistas_state.back
            b:draw(b.x, b.y)
        end

        --Desenha a notificação do pop-up no topo da tela, caso haja uma conquista desbloqueada
        Conquistas.drawToast(virtual_Width)

        if not ehMobile then
            love.graphics.setColor(0, 0, 1)
            love.graphics.circle("fill", player.x, player.y, player.radius)
            love.graphics.setColor(1, 1, 1)
        end
    elseif game.state["menu"] then
        --love.graphics.draw(drawable,x,y,r,sx,sy,ox,oy)
        love.graphics.draw(background, virtual_Width/2, virtual_Height/2, 0, 0.7, 0.7, background:getWidth()/2, background:getHeight()/2)
        
        buttons.menu_state.play_game:draw(virtual_Width/2 - 100, virtual_Height/2 - 25, 20, 8, 10)
        buttons.menu_state.settings:draw(virtual_Width/2 - 20, virtual_Height/2 + 60, 10, 10)
        buttons.menu_state.exit_game:draw(virtual_Width/2 + 100, virtual_Height/2 + 150, 25, 8, 10)
        
        if not ehMobile then
            love.graphics.setColor(0,1,0)
            love.graphics.circle("fill", player.x, player.y, player.radius)
            love.graphics.setColor(1,1,1)
        end
    end

    if game.state["creditos"] then
        love.graphics.draw(creditosimg, 0, 0)

        local b = buttons.creditos_state.back
        b:draw(b.x, b.y)
    end

    if game.state["paused"] then
        love.graphics.draw(pause_bg, 0, 0, 0, 1, 1)

        --love.graphics.draw(regras, virtual_Width/2 - 300, 100, 0, 0.5, 0.5)
        love.graphics.setColor(0, 0, 0) -- Preto para o texto
        love.graphics.setFont(fonte.grande)
        love.graphics.print("Jogo Pausado", virtual_Width/2 - 150, 10)
        love.graphics.setColor(1, 1, 1) -- Restaura a cor para branco

        --botões do menu de pausa
        buttons.paused_state.resume:draw(virtual_Width/2 - 100, virtual_Height/2 - 200, 1, 1)
        buttons.paused_state.restart:draw(virtual_Width/2 - 90, virtual_Height/2 - 100, 10, 10)
        buttons.paused_state.settings:draw(virtual_Width/2 - 80, virtual_Height/2 - 20, 10, 10)
        buttons.paused_state.exit_to_menu:draw(virtual_Width/2 - 70, virtual_Height/2 + 80, 10, 10)
        buttons.paused_state.exit_game:draw(virtual_Width/2 - 40, virtual_Height/2 + 160, 10, 10)

        --Mouse/click na tela de pausa
        if not ehMobile then
            love.graphics.setColor(0,1,0)
            love.graphics.circle("fill", player.x, player.y, player.radius)
            love.graphics.setColor(1,1,1)
        end
    end

    if game.state["config"] then
        --love.graphics.draw(drawable (Drawable), x (number), y (number), r (number), sx (number), sy (number), ox (number), oy (number), kx (number), ky (number))
        love.graphics.draw(config_bg, 0, 0, 0, 1, 1)

        love.graphics.draw(configText, virtual_Width/2 - 325,  virtual_Height/2 - 450, 0, 0.5, 0.5)

        love.graphics.setFont(fonte.grande)
        love.graphics.setColor(0,0,1)
        love.graphics.print("Volume", virtual_Width/2 - 325, virtual_Height/2 - 35)
        love.graphics.setColor(1,1,1)

        desenharSlider()

        local b = buttons.config_state.back
        b:draw(b.x, b.y)

        buttons.config_state.creditos:draw(buttons.config_state.creditos.x + 100, buttons.config_state.creditos.y + 100)

        if not ehMobile then
            love.graphics.setColor(0,1,0)
            love.graphics.circle("fill", player.x, player.y, player.radius)
            love.graphics.setColor(1,1,1)
        end
    end

    if game.state["creditos"] then

       if not ehMobile then
            love.graphics.setColor(0,1,0)
            love.graphics.circle("fill", player.x, player.y, player.radius)
            love.graphics.setColor(1,1,1)
        end
   end

     push:finish()--Finaliza e estica para a tela real do dispositivo
end

function love.keypressed(key)
    -- Se o modal educativo estiver aberto, avançar com Espaço ou Enter
    if modalFato.ativo and (key == "space" or key == "return") then
        exibirProximoFato()
        return
    end
    if key == "escape" then
        if game.state["running"] then
            game.state["running"] = false
            game.state["paused"] = true
        elseif game.state["paused"] then
            game.state["paused"] = false
            game.state["running"] = true
        end
    end

    if key == "f11" then
        local isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen) --Inverte, se tá on desliga, se tá off liga.
    end
    if key == "space" and game.state["running"] then
        proxRodada()
    end
    if key == "r" then
        startNewGame()
    end
    if key == "t" then
        enfileirarFato(1)
        print("Tentou abrir fato 1. Ativo:", modalFato.ativo)
    end
end