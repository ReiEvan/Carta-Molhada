local love = require "love"
local button = require "Button"
--local conflitos = require "conflitos"
local hitbox = require "hitbox"
local ost = require "OST"
local cartas = require "cartas"
-- função que gerencia a quantidade de água
local agua = 5
local aguaMax = 10
function adicionarAgua(qtd)
    agua = agua + qtd
end
local function adicionarAgua(valor)
    agua = agua + valor
    if agua < 0 then agua = -1 end
end
-- VINCULAR A FUNÇÃO DAS CARTAS AOS MÓDULOS
-- vincula a função de água
cartas.setAdicionarAgua(adicionarAgua)



local movimento={
        mx=10,
        my=220
}

local bg_escalax = 0.7
local bg_escalay = 0.5
local escala = 0.5
local rodada = 1
local numGuardas = 1
local movimentosRestantes = 3
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
local objetivosExternos =  {}

-- função que gerencia a quantidade de água
local agua = 5
local aguaMax = 10
local function adicionarAgua(valor)
    agua = agua + valor
end
local function alterarmovimento(pes)
    movimentosRestantes= movimentosRestantes + pes
end
-- VINCULAR A FUNÇÃO DAS CARTAS AOS MÓDULOS
-- vincula a função de água
cartas.setAdicionarAgua(adicionarAgua)
-- vincula a função de movimento
cartas.setalterarmovimento(alterarmovimento)
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
        fx=movimento.mx-5, fy=movimento.my+60     
    }


local confirmacao = {
    ativa = false,
    indiceDestino = nil,
    posicaoX = 0,
    posicaoY = 0,
    botoes= {}
}
local rodadaAtiva = false
local efeitoConflitoAplicado = false


    cartas.selecionarCartasRodada()
    if rodada ~=1 then
        cartas.sortearConflitoRodada()
    end
    
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
    imagem = love.graphics.newImage("sprites/Guarda Provisorio.png"),
    destino = nil,
    velocidade = 200,
    raioColisao = 30,
    interagindo = false,
    direcao = "direita",
    frameAtual = 1,
    quadros = {}
}
local function cancelarMovimento()
    confirmacao.ativa = false
    confirmacao.indiceDestino = nil
end
local function confirmarMovimento()
    local destIndex = confirmacao.indiceDestino

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

local function proxRodada()
        rodada = rodada + 1
        movimentosRestantes = 3
        cartas.selecionarCartasRodada()
        adicionarAgua(-1)
        cartas.prepararConflitoDaRodada(rodada)


--verifica e remove as imagens q foram transformadas depois de duas rodadas
    for i = 1, #pontosMovimentacao do
        if rodadasPorPonto[i] then
            rodadasPorPonto[i] = rodadasPorPonto[i] + 1

            --só remove se a imagem foi transformada e completou duas rodadas
            if estadoTransformacao[i] and rodadasPorPonto[i] >= 2 then
                hexAtivos[i] = nil
                estadoTransformacao[i] = nil
                rodadasPorPonto[i] = nil
                pontosBloqueados[i] = true
            end
        end
        
    end


end

local function startNewGame()
    game.state["menu"] = false
    game.state["running"] = true 
    definirObjetivos()

    --Resetar variaveis de jogo se necessário
    rodada = 1
    agua = 5
    numGuardas = 1
    fimDeJogo.ativo = false
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
    if rodada > 20 then
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
--Ficar sem guardas
    if numGuardas <= 0 then
        fimDeJogo.ativo = true
        fimDeJogo.mensagem = "DERROTA\nSem guardas!"
        fimDeJogo.cor = {0.5, 0, 0}
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
        fimDeJogo.mensagem =string.format("TRIUNFO!\nVocê salvou a ilha\n em %s dias",rodada)
        fimDeJogo.cor = {0.18, 0.44, 0.25}
    end
end

--função para o mouse no menu e in game
function love.mousepressed(x, y, button, isTouch, presses)
    if button == 1 and not game.state["paused"] then
        
        if confirmacao.ativa then
            confirmacao.botoes.sim:checkPressed(x, y, player.radius)
            confirmacao.botoes.nao:checkPressed(x, y, player.radius)
            return
        end

        --Garante que o guarda não está em movimento
        if movGuarda.destino ~= nil then
            return
        end

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

                    return
                end
            end
        end
    end
    handle_button_click(x, y, player.radius)
end


function love.load()
    love.mouse.setVisible(false)
    love.window.setTitle("Última Gota") --isso tá funcionando? // É o titulo que aparece na Janela do game
    fonte.grande = love.graphics.newFont(40)
    fonte.media = love.graphics.newFont(30)
    fonte.normal = love.graphics.newFont(13)
    love.graphics.setFont(fonte.normal)
    ost.somteste()
    --Botões da tela do menu
    buttons.menu_state.play_game = button("Iniciar", startNewGame, nil, 80, 30)
    buttons.menu_state.settings = button("Configurações", nil, nil, 120, 30)
    buttons.menu_state.exit_game = button("Sair", love.event.quit, nil, 80, 30)
    --Botões no jogo rodando
    buttons.running_state.pass_rodada = button("Proximo dia", proxRodada, nil, 120, 30)
    buttons.running_state.exit_in_game = button("Sair", love.event.quit, nil, 80, 30)
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
    cartas.setAdicionarAgua(adicionarAgua)
    
    
--baralho azul
    cartas.construirBaralho()
-- carregar cartas aleatórias     
    cartas.selecionarCartasRodada()
--Guarda florestal
    movGuarda.imagem = love.graphics.newImage("sprites/Guarda Provisorio.png")

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
end

function love.update(dt)
    player.x, player.y = love.mouse.getPosition()
    cartas.reposicionarBaralho()
    cartas.atualizarInteracaoCartas()
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
    end
end 

-- Carregamento do mapa
local mapa = love.graphics.newImage("sprites/mapagradeado.png")
local background= love.graphics.newImage("sprites/logo do jogo.png")
function love.draw()
    --Contagem do FPS
    love.graphics.printf("FPS: " .. love.timer.getFPS(), love.graphics.newFont(16),
    10, love.graphics.getHeight() - 30, love.graphics.getWidth())
     if game.state["running"] then
        --Movimentos Restantes
         love.graphics.setFont(fonte.media)
        love.graphics.print("Movimentos: " .. movimentosRestantes, movimento.mx, movimento.my, 0)
        
        --Feddback visual da quantidade de agua
        love.graphics.draw(imagemAgua.ficha, imagemAgua.fx, imagemAgua.fy, 0, escala, escala)
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(fonte.grande)  
        love.graphics.print(tostring(agua), imagemAgua.fx+40, imagemAgua.fy+8)
        love.graphics.setColor(1, 1, 1)

        --Numeração da rodada atual
        love.graphics.print("Dia " .. rodada .. "/20", love.graphics.getWidth()/2-80, 10, 0)
         love.graphics.setFont(fonte.normal)
        --Saber a posição do mouse
        love.graphics.print("Mouse x: " .. love.mouse.getX() .. " y: " .. love.mouse.getY(), 300, 10, 0)
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
            --Desenha a bandeira um pouco acima do centro do hex
            --Ajuste o offset (x, y) e a escala (0.5) conforme o tamanho da imagem
            love.graphics.draw(imgBandeira, p.x - 15, p.y - 30, 0, 0.1, 0.1)
        end
        
        cartas.desenharBaralho()
        cartas.desenharCartasRodada()
        cartas.desenharResultadoEscolha()
    -- Sempre aparece
        cartas.desenharFundoConflito()
    -- Só aparece se não for a 1ª rodada
        cartas.desenharConflito()
    -- Suas outras partes do jogo
        cartas.desenharCartasRodada()
        
        

       

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
        love.graphics.draw(movGuarda.imagem, movGuarda.quadros[movGuarda.frameAtual], movGuarda.x-20, movGuarda.y-20, 0, 0.2, 0.2)
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
        
        
        love.graphics.circle("fill", player.x, player.y, player.radius)
        
    elseif game.state["menu"] then
        --love.graphics.draw(drawable,x,y,r,sx,sy,ox,oy)
        love.graphics.draw(background, 0, 0, 0, bg_escalax, bg_escalay)
        
        buttons.menu_state.play_game:draw(love.graphics.getWidth()/2 - 30, love.graphics.getHeight()/2 - 50, 20, 10, 10)
        buttons.menu_state.settings:draw(love.graphics.getWidth()/2 - 50, love.graphics.getHeight()/2, 10, 10)
        buttons.running_state.exit_in_game:draw(love.graphics.getWidth()/2 - 30, love.graphics.getHeight()/2 + 50, 10, 10)
        love.graphics.circle("fill", player.x, player.y, player.radius)
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
     cartas.selecionarCartaPorTecla(key)

    if key == "f11" then
        local isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen) --Inverte, se tá on desliga, se tá off liga.
    end
    if key == "space" then
        proxRodada()
    end
    if key == "r" then
        startNewGame()
    end
end
