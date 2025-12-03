local love = require "love"

local button = require "Button"
local hitbox = require "hitbox"
local ost = require "OST"
local cartas = require ("cartas")
-- REMOVIDO: cartas.selecionarCartasRodada() aqui fora, pois startNewGame já faz isso

-- função que gerencia a quantidade de água
local agua = 5
local movimentosRestantes = 3
function alterarAgua(qtd)
    agua = agua + qtd
    if agua < 0 then agua = -1 end
end

function alterarMovimento(qtd)
    movimentosRestantes = movimentosRestantes + qtd
end

local guardasBloqueados = false
function setBloqueioGuardas(ativo)
    guardasBloqueados = ativo or false
end


local movimento={
        mx=10,
        my=220
}

local esperandoEscolhaCarta = true --Começa true para obrigar a escolha no dia 1

local bg_escalax = 0.8
local bg_escalay = 0.8
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
local imgBandeira = love.graphics.newImage("sprites/bandeira vermelha.png")
local imgBandeiraConquistada = love.graphics.newImage("sprites/Bandeira_branca.png")
local objetivosExternos =  {}
local objetivosRecompensados = {}
local totalAreasVerdes = 0

--Textos de fim de jogo

local fimDeJogo = {
    ativo = false,
    mensagem = "",
    cor = {1, 1, 1}
}

local movimento={
    mx=10,
    my=220
}

local imagemAgua={
        ficha=love.graphics.newImage("sprites/ficha gota.png"),
        fx=movimento.mx-5, fy=movimento.my+25     
    }


local confirmacao = {
    ativa = false,
    indiceDestino = nil,
    posicaoX = 0,
    posicaoY = 0,
    botoes= {}
}
local rodadaAtiva = false


--Desativa a confirmação após escolher
    confirmacao.ativa = false
    confirmacao.indiceDestino = nil



local deck = {}
--lista de pontos de movimentação
local pontosMovimentacao = {

    {x = love.graphics.getWidth()/2 + 15, y = love.graphics.getHeight()/2 - 245, raio = 45},
    {x = love.graphics.getWidth()/2 + 15, y = love.graphics.getHeight()/2 - 145, raio = 45},
    {x = love.graphics.getWidth()/2 + 15, y = love.graphics.getHeight()/2 - 45, raio = 45},
    {x = love.graphics.getWidth()/2 + 15, y = love.graphics.getHeight()/2 + 55, raio = 45},
    {x = love.graphics.getWidth()/2 + 15, y = love.graphics.getHeight()/2 + 155, raio = 45},--5
    {x = love.graphics.getWidth()/2 + 190, y = love.graphics.getHeight()/2 - 145, raio = 45},
    {x = love.graphics.getWidth()/2 + 190, y = love.graphics.getHeight()/2 - 45, raio = 45},--7
    {x = love.graphics.getWidth()/2 + 190, y = love.graphics.getHeight()/2 + 55, raio = 45},
    {x = love.graphics.getWidth()/2 - 160, y = love.graphics.getHeight()/2 - 145, raio = 45},
    {x = love.graphics.getWidth()/2 - 160, y = love.graphics.getHeight()/2 - 45, raio = 45},--10
    {x = love.graphics.getWidth()/2 - 160, y = love.graphics.getHeight()/2 + 55, raio = 45},
    {x = love.graphics.getWidth()/2 + 100, y = love.graphics.getHeight()/2 - 195, raio = 45},--12
    {x = love.graphics.getWidth()/2 + 100, y = love.graphics.getHeight()/2 - 95, raio = 45},
    {x = love.graphics.getWidth()/2 + 100, y = love.graphics.getHeight()/2 + 5, raio = 45},
    {x = love.graphics.getWidth()/2 + 100, y = love.graphics.getHeight()/2 + 105, raio = 45},
    {x = love.graphics.getWidth()/2 - 75, y = love.graphics.getHeight()/2 - 195, raio = 45},
    {x = love.graphics.getWidth()/2 - 75, y = love.graphics.getHeight()/2 - 95, raio = 45},
    {x = love.graphics.getWidth()/2 - 75, y = love.graphics.getHeight()/2 + 5, raio = 45},
    {x = love.graphics.getWidth()/2 - 75, y = love.graphics.getHeight()/2 + 105, raio = 45}

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

-- Função para transformar áreas limpas de volta em Vermelhas (Tóxicas)
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

-- Flag que indica que o guarda está bloqueado por uma rodada
local guardaBloqueado = false

-- Função que bloqueia o guarda por esta rodada (será passada como callback para cartas.lua)
local function bloquearGuardaPorRodada()
    guardaBloqueado = true
    -- se já estiver indo para algum destino, cancela o movimento imediatamente
    movGuarda.destino = nil
end

local function cancelarMovimento()
    confirmacao.ativa = false
    confirmacao.indiceDestino = nil
end
local function confirmarMovimento()
    local destIndex = confirmacao.indiceDestino
    
    -- Se o guarda está bloqueado por conflito, não permita confirmar movimento
    if guardaBloqueado then
        -- cancela a confirmação e sai (mantém a UI de confirmação fechada)
        cancelarMovimento()
        -- opcional: avisar o jogador (se quiser, use cartas.limparMensagens() / ou outra UI)
        return
    end

    --Recupera a posição do destino baseada no índice salvo
    local pontoDestino = pontosMovimentacao[destIndex]
    --Executa a movimentação
    movGuarda.destino = {x = pontoDestino.x, y = pontoDestino.y}
    movimentosRestantes = movimentosRestantes - 1

    if destIndex ~= 3 and not pontosBloqueados[destIndex] then
        if not hexAtivos[destIndex] then
            hexAtivos[destIndex] = 1
            estadoTransformacao[destIndex] = false
            rodadasPorPonto[destIndex] = 0
            
        elseif hexAtivos[destIndex] == 1 then
            hexAtivos[destIndex] = 2
                estadoTransformacao[destIndex] = true
                rodadasPorPonto[destIndex] = 0
            end
        end
    cancelarMovimento()
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
    local possiveis = {}
    --Lista todos os pontos que não são a base (3) nem adjascentes a ela
    local vizinhosBase = pontosAdjascentes[3]

    for i = 1, #pontosMovimentacao do
        local ehVizinhoDaBase = false

        if vizinhosBase then
            for _, v in ipairs(vizinhosBase) do
                if i == v then ehVizinhoDaBase = true break end
            end
        end

        if i ~= 3 and not ehVizinhoDaBase then
            table.insert(possiveis, i)
        end
    end

    --Sorteia 4 bandeiras com distanciamento
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
                if vizinhoDoEscolhido then
                    for _, vizinho in ipairs(vizinhoDoEscolhido) do
                        if candidato == vizinho then
                            deveManter = false
                            break
                        end
                    end
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

local game = {
    state = {
        menu = true,
        config = false,
        paused = false,
        running = false,
        ended = false
         
    },
    points = 0,
}

local player ={
    radius = 13,
    x = 30,
    y = 30
}

local buttons = {
    menu_state = {},
    running_state = {}
    
}


function proxRodada()
    if esperandoEscolhaCarta then return end
    
    alterarAgua(-1)
    cartas.limparMensagens()

    -- === 1. PROCESSAR ÁREAS (Usando os efeitos da rodada que ACABOU) ===
    local diasNecessarios = 2
    if cartas.efeitosAtivos.terrenoDificil then
        diasNecessarios = 3
    end

    for i = 1, #pontosMovimentacao do
        if rodadasPorPonto[i] then
            rodadasPorPonto[i] = rodadasPorPonto[i] + 1
            
            if estadoTransformacao[i] and rodadasPorPonto[i] >= diasNecessarios then
                hexAtivos[i] = nil
                estadoTransformacao[i] = nil
                rodadasPorPonto[i] = nil
                pontosBloqueados[i] = true
                -- Lógica da recompensa da bandeira
                for _, objIndex in ipairs(objetivosExternos) do
                    if i == objIndex and not objetivosRecompensados[i] then
                        objetivosRecompensados[i] = true
                        alterarAgua(1)
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
    cartas.selecionarCartasRodada()
    cartas.prepararConflitoDaRodada(rodada)
    
    esperandoEscolhaCarta = true

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

local function startNewGame()
    game.state["menu"] = false
    game.state["running"] = true 
    definirObjetivos()

    --Resetar variaveis de jogo se necessário
    rodada = 1
    agua = 5
    numGuardas = 1
    movimentosRestantes = 3
    fimDeJogo.ativo = false

    --Resetar recompensas e eras 
    objetivosRecompensados = {}
    eraAtual = 1
    cartas.setEra(1)
    telaEra.ativa = false

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
    cartas.selecionarCartasRodada()
    esperandoEscolhaCarta = true --Força a escolha no turno 1
end

local button_states = {
    menu = buttons.menu_state,
    running = buttons.running_state
}

function handle_button_click(x, y, radius)
    if game.state.paused then return end

    local current_state = game.state.menu and "menu" or game.state.running and "running"

    if current_state and button_states[current_state] then
        for _, button in pairs(button_states[current_state]) do
            button:checkPressed(x, y, radius)
            
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
        fimDeJogo.mensagem =string.format("TRIUNFO!\nVocê salvou a ilha\n em %s dias com\n %s águas restantes",rodada,agua)
        fimDeJogo.cor = {0.18, 0.44, 0.25}
    end
end

--função para o mouse no menu e in game
function love.mousepressed(x, y, button, isTouch, presses)
    if button ~= 1 then return end
        
    if game.state["menu"] then
        handle_button_click(x, y, player.radius)
        return
    end
    
    if game.state["running"] then
        --Se estiver esperando a escolha de carta, bloqueia o resto
        if esperandoEscolhaCarta then
            local cartaFoiEscolhida = cartas.mousepressed(x, y, button, movimentosRestantes)
            
            if cartaFoiEscolhida then
                esperandoEscolhaCarta = false
                
            end
            return
        end


        if confirmacao.ativa then
            confirmacao.botoes.sim:checkPressed(x, y, player.radius)
            confirmacao.botoes.nao:checkPressed(x, y, player.radius)
            return
        end

        handle_button_click(x, y, player.radius)

        cartas.mousepressed(x, y, button, movimentosRestantes)

        --Garante que o guarda não está em movimento
        if movGuarda.destino == nil then
        local origem = movGuarda.indiceAtual
        --verfica colisão com cada ponto de movimentação
        for i, ponto in ipairs(pontosMovimentacao) do
        local distancia = math.sqrt((ponto.x - x)^2 + (ponto.y - y)^2)
            if distancia <= ponto.raio then
                local indiceDestino = i
                if movimentosRestantes > 0 and movimentoPermitido(origem, indiceDestino) then
        --Ativa o menu de confirmação
                    confirmacao.ativa = true
                    confirmacao.indiceDestino = indiceDestino
        --Define a posição da caixa de confirmação
                    confirmacao.posicaoX = ponto.x
                    confirmacao.posicaoY = ponto.y
        --Posiciona os botões "Sim" e "Não"
                    local yBase = ponto.y + 10
                    local offset = 35

                    confirmacao.botoes.sim.x = ponto.x - offset
                    confirmacao.botoes.sim.y = yBase

                    confirmacao.botoes.nao.x = ponto.x + offset
                    confirmacao.botoes.nao.y = yBase

                    end
                    break
                end
            end
        end
    end
end

function love.load()
    ------------IMAGENS DO JOGO--------------------
    movGuarda.imagem = love.graphics.newImage("sprites/Guardinha.png")
    local startNormal = love.graphics.newImage("sprites/botão_iniciar.png")
    local startClicado = love.graphics.newImage("sprites/botão_iniciar_clicado.png")
    local opcoesNormal = love.graphics.newImage("sprites/botão_opções.png")
    local opcoesClicado = love.graphics.newImage("sprites/botão_opções_clicado.png")
    local sairNormal = love.graphics.newImage("sprites/botão_sair.png")
    local sairClicado = love.graphics.newImage("sprites/botão_sair_clicado.png")
    local prxmDiaNormal = love.graphics.newImage("sprites/botão_prxm_Dia.png")
    local prxmDiaClicado = love.graphics.newImage("sprites/botão_prxm_Dia_Clicado.png")

-------------------------------------------------------------------
    love.mouse.setVisible(false)
    love.window.setTitle("Última Gota") --isso tá funcionando? // É o titulo que aparece na Janela do game
    fonte.grande = love.graphics.newFont(40)
    fonte.media = love.graphics.newFont(30)
    fonte.normal = love.graphics.newFont(13)
    love.graphics.setFont(fonte.normal)
    ost.somteste()
    
    
    --Botões da tela do menu
    local centroX = love.graphics.getWidth() / 2
    local centroY = love.graphics.getHeight() / 2
    --Só pra lembrar button(ImagemNormal, Função, Parametro, Largura, Altura, ImagemPressionada)
    buttons.menu_state.play_game = button(startNormal, startNewGame, nil, 250, nil, startClicado)
    buttons.menu_state.play_game.x = centroX - 30
    buttons.menu_state.play_game.y = centroY - 50

    buttons.menu_state.settings = button(opcoesNormal, nil, nil, 250, nil, opcoesClicado)
    buttons.menu_state.settings.x = centroX - 50
    buttons.menu_state.settings.y = centroY + 3000

    buttons.menu_state.exit_game = button(sairNormal, love.event.quit, nil, 150, 90, sairClicado)
    buttons.menu_state.exit_game.x = centroX - 30 
    buttons.menu_state.exit_game.y = centroY + 250
    
    
    --Botões no jogo rodando
    buttons.running_state.pass_rodada = button(prxmDiaNormal, proxRodada, nil, nil, 40, prxmDiaClicado)
    buttons.running_state.exit_in_game = button(sairNormal, love.event.quit, nil, nil, 60, sairClicado)
    
    
    --Botões de confirmação de movimento
    confirmacao.botoes.sim = button("Sim", confirmarMovimento, nil, 50, 25)
    confirmacao.botoes.nao = button("Não", cancelarMovimento, nil, 50, 25)
    
    
    --Botões do Menu de Água (Carta)
    local cx, cy = love.graphics.getWidth()/2 - 70, love.graphics.getHeight()/2 - 50

    
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
    cartas.selecionarCartasRodada()
    

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
    alterarAgua,
    alterarMovimento,
    getContagemVerdes,
    bloquearGuardaPorRodada,
    corromperAreas,
    getAgua,
    nil
)
end

function love.update(dt)
    player.x, player.y = love.mouse.getPosition()
    cartas.reposicionarBaralho()
    cartas.atualizarInteracaoCartas()
    cartas.notificarErro(dt)
    
    --Atualiza o timer da tela de Era
    if telaEra.ativa then
        telaEra.timer = telaEra.timer - dt
        if telaEra.timer <= 0 then
            telaEra.ativa = false
        end
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
local movImg = love.graphics.newImage("sprites/Movimentos_Arte.png")
local diaImg = love.graphics.newImage("sprites/Dia_Arte.png")
function love.draw()
     if game.state["running"] then
        --Movimentos Restantes
        love.graphics.setFont(fonte.media)
        --love.graphics.draw(movImg, movimento.mx, movimento.my, 0, 1, 1)
        love.graphics.print("movimentos: " .. movimentosRestantes, movimento.mx, movimento.my, 0)
        love.graphics.setFont(fonte.normal)
        -- Contador de Áreas Verdes, retirar no fim do jogo
        love.graphics.setColor(0, 1, 0)  -- verde
        love.graphics.print("Áreas verdes: " .. getContagemVerdes(),imagemAgua.fx, imagemAgua.fy-40, 0)
        love.graphics.setColor(1, 1, 1)  -- volta ao normal
        --Feddback visual da quantidade de agua
        love.graphics.draw(imagemAgua.ficha, imagemAgua.fx, imagemAgua.fy, 0, escala, escala)
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(fonte.grande)  
        love.graphics.print(tostring(agua), imagemAgua.fx+40, imagemAgua.fy+8)
        love.graphics.setColor(1, 1, 1)

        --Numeração da rodada atual
        love.graphics.draw(diaImg, love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2 - 410, 0, 0.3, 0.3)
        love.graphics.print(rodada .. "/20", love.graphics.getWidth()/2 + 30, 10, 0)
        love.graphics.setFont(fonte.normal)

        


        -- Desenhar mapa As coordenadas x crescem para a direita e y para baixo
        --desenhar o mapa
        love.graphics.draw(mapa, love.graphics.getWidth()/2 - 400, love.graphics.getHeight()/2 - 370, 0, .35, .35)
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
                
            end
        --Desenhar Bandeira nos Objetivos Externos
        love.graphics.setColor(1, 1, 1)
        for _, indice in ipairs(objetivosExternos) do
            local p = pontosMovimentacao[indice]
            
            local imagemParaDesenhar = imgBandeira --Bandeira Vermelha
            local escalaAtual = 0.1
            local ajusteX = 15
            local ajusteY = 30
            
            if hexAtivos[indice] == nil then
                imagemParaDesenhar = imgBandeiraConquistada --Bandeira branca

                escalaAtual = 0.08
                ajusteX = 50
                ajusteY = 80
            end
            
            --Desenha a bandeira um pouco acima do centro do hex
            --Ajuste o offset (x, y) e a escala (0.5) conforme o tamanho da imagem
            love.graphics.draw(imagemParaDesenhar, p.x - ajusteX, p.y - ajusteY, 0, escalaAtual, escalaAtual)
        end
        cartas.desenharTroca()
        cartas.desenharFundoConflito()   
        cartas.desenharConflito()       
        cartas.desenharBaralho()
        cartas.desenharCartasRodada()
        cartas.desenharResultadoEscolha()
    
        

        --Desenhar a hitbox enquanto o jogo ta rodando
        hitbox.desenhar(love.graphics.getWidth()/2 + 15, love.graphics.getHeight()/2 - 245, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 15, love.graphics.getHeight()/2 - 145, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 15, love.graphics.getHeight()/2 - 45, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 15, love.graphics.getHeight()/2 + 55, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 15, love.graphics.getHeight()/2 + 155, 45) --5
        hitbox.desenhar(love.graphics.getWidth()/2 + 190, love.graphics.getHeight()/2 - 145, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 190, love.graphics.getHeight()/2 + 55, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 190, love.graphics.getHeight()/2 - 45, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 - 160, love.graphics.getHeight()/2 - 145, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 - 160, love.graphics.getHeight()/2 - 45, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 - 160, love.graphics.getHeight()/2 + 55, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 100, love.graphics.getHeight()/2 - 195, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 100, love.graphics.getHeight()/2 - 95, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 100, love.graphics.getHeight()/2 + 105, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 100, love.graphics.getHeight()/2 + 5, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 - 75, love.graphics.getHeight()/2 - 195, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 - 75, love.graphics.getHeight()/2 - 95, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 - 75, love.graphics.getHeight()/2 + 5, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 - 75, love.graphics.getHeight()/2 + 105, 45)
        
        -- Guardinha florestal
        if  movGuarda.quadros[movGuarda.frameAtual] then
        love.graphics.draw(movGuarda.imagem, movGuarda.quadros[movGuarda.frameAtual], movGuarda.x-90, movGuarda.y-50, 0, 0.09, 0.09)
        else
            love.graphics.draw(movGuarda.imagem, movGuarda.x-20, movGuarda.y-20)
        end
        --Desenhar os botões enquato o jogo ta rodando
        buttons.running_state.pass_rodada:draw(love.graphics.getWidth() - 125, love.graphics.getHeight() - 250, 10, 10)
        
        if confirmacao.ativa then
            --Fundinho preto transparente
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", confirmacao.posicaoX - 40, confirmacao.posicaoY - 30, 80, 80, 10, 10)
            love.graphics.setColor(1, 1, 1, 1)
            --Desenho dos botoes
            confirmacao.botoes.sim:draw(confirmacao.botoes.sim.x + 10, confirmacao.botoes.sim.y - 30, 10, 5)
            confirmacao.botoes.nao:draw(confirmacao.botoes.nao.x - 60, confirmacao.botoes.nao.y + 5, 10, 5)
            
            love.graphics.print("Mover ?", confirmacao.posicaoX - 25, confirmacao.posicaoY - 45)
        end
        
        if fimDeJogo.ativo then
            --Fundo preto transparente
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            --Texto
            love.graphics.setFont(fonte.grande)
            love.graphics.setColor(unpack(fimDeJogo.cor))
            love.graphics.printf(fimDeJogo.mensagem, 0, love.graphics.getHeight()/2 - 50, love.graphics.getWidth(), "center")
        end
        --Botão de sair por cima de tudo
        buttons.running_state.exit_in_game:draw(love.graphics.getWidth() - 100, 10, 10, 10)

        --DESENHAR TELA DE TRANSIÇÃO DE ERA
        if telaEra.ativa then
            local w, h = love.graphics.getDimensions()

            --Fundo preto semitransparente
            love.graphics.setColor(0, 0, 0, 0.85)
            love.graphics.rectangle("fill", 0, 0, w, h)

            --Texto
            love.graphics.setColor(1, 1, 1, 1)

            --Título grande
            love.graphics.setFont(fonte.grande)
            love.graphics.printf(telaEra.titulo, 0, h/2 - 60, w, "center")

            --Subtítulo/lore
            love.graphics.setFont(fonte.media)
            love.graphics.printf(telaEra.texto, 0, h/2, w, "center")

            --Restaura a cor
            love.graphics.setColor(1, 1, 1, 1)

        end
        
        love.graphics.circle("fill", player.x, player.y, player.radius)
        
    elseif game.state["menu"] then
        --love.graphics.draw(drawable,x,y,r,sx,sy,ox,oy)
        love.graphics.draw(background, 0, 0, 0, bg_escalax, bg_escalay)
        
        buttons.menu_state.play_game:draw(love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2 - 25, 20, 8, 10)
        buttons.menu_state.settings:draw(love.graphics.getWidth()/2 - 20, love.graphics.getHeight()/2 + 60, 10, 10)
        buttons.menu_state.exit_game:draw(love.graphics.getWidth()/2 + 100, love.graphics.getHeight()/2 + 150, 25, 8, 10)

        love.graphics.setColor(0,1,0)
        love.graphics.circle("fill", player.x, player.y, player.radius)
        love.graphics.setColor(1,1,1)
    end

    if game.state["paused"] then
        love.graphics.setColor(0,0,0.1)
        love.graphics.rectangle("fill",0 ,0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(0,1,1)
        love.graphics.print("Pausado\nPressione ESC para continuar!", love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2)
    end

end

function love.keypressed(key)
    if key == "escape" then
        game.state["paused"] = not game.state["paused"]
    end
     cartas.keypressed(key)

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
end