local love = require "love"
local button = require "Button"
local cartas = require "cartas"
local conflitos = require "conflitos"
local hitbox = require "Hitbox"
local ost = require "OST"

local movimento={
        mx=10,
        my=220
}
local agua = 5
local imagemAgua={
        ficha=love.graphics.newImage("sprites/ficha gota.png"),
        fx=movimento.mx-5, fy=movimento.my+25     
}
local escala = 0.5
local rodada = 1


local card_back_image
local fonte= {}
local hexAtivos = {}
local hexVermelho = love.graphics.newImage("sprites/HEXÁGONO-Vermelho.png")
local hexMarrom = love.graphics.newImage("sprites/HEXÁGONO-Marrom.png")
local escalaHex = 0.1111
local rodadasPorPonto = {}
local estadoTransformacao = {}
local pontosBloqueados = {}


local movimentosRestantes = 2
local acoesRestantes = 4

local deck = {}
--lista de pontos de movimentação
local pontosMovimentação = {

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
    x = pontosMovimentação[3].x,
    y = pontosMovimentação[3].y,
    indiceAtual = 3,
    imagem = love.graphics.newImage("sprites/Guarda Provisorio.png"),
    destino = nil,
    velocidade = 200,
    raioColisão = 30,
    interagindo = false,
    direcao = "direita",
    frameAtual = 1,
    quadros = {}
}

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
        return estadoDestino == 1
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


local game = {
    state = {
        menu = false,
        paused = false,
        running =true,
        ended = false,
        
    },
    points = 0,
}

local player ={
    radius = 15,
    x = 30,
    y = 30
}

local buttons = {
    menu_state = {},
    running_state = {}
    
}


local function proxRodada()
        rodada = rodada + 1
        movimentosRestantes = 2
        cartas.selecionarCartasRodada()

--verifica e remove as imagens q foram transformadas depois de duas rodadas
    for i = 1, #pontosMovimentação do
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

--função para o mouse no menu e in game
function love.mousepressed(x, y, button, isTouch, presses)
    if button == 1 and not game.state["paused"] then

        --Garante que o guarda não está em movimento
        if movGuarda.destino ~= nil then
            return
        end

        local origem = movGuarda.indiceAtual
        --verfica colisão com cada ponto de movimentação
        for i, ponto in ipairs(pontosMovimentação) do
        local distancia = math.sqrt((ponto.x - x)^2 + (ponto.y - y)^2)
            if distancia <= ponto.raio then
                local indiceDestino = i
                if movimentosRestantes > 0 and movimentoPermitido(origem, indiceDestino) then
            movGuarda.destino = {x = ponto.x, y = ponto.y}
            movimentosRestantes = movimentosRestantes - 1
            --Atualiza o estado da imagem num ponto
            if not pontosBloqueados[indiceDestino] then
            if not hexAtivos[indiceDestino] then
                hexAtivos[indiceDestino] = 1
                estadoTransformacao[indiceDestino] = false
                rodadasPorPonto[indiceDestino] = 0 
            elseif hexAtivos[indiceDestino] == 1 then
                hexAtivos[indiceDestino] = 2
                estadoTransformacao[indiceDestino] = true
                rodadasPorPonto[indiceDestino] = 0
            end
        end
        end
    return
    end
end

    handle_button_click(x, y, player.radius)
    end

end


function love.load()
    love.mouse.setVisible(false)
    love.window.setTitle("Última Gota") --isso tá funcionando?
    fonte.grande=love.graphics.newFont(40)
    fonte.normal = love.graphics.newFont(13)
    love.graphics.setFont(fonte.normal)
    ost.somteste()
    --Botões da tela do menu
        buttons.menu_state.play_game = button("Iniciar", startNewGame, nil, 80, 30)
        buttons.menu_state.settings = button("Configurações", nil, nil, 120, 30)
        buttons.menu_state.exit_game = button("Sair", love.event.quit, nil, 80, 30)
    --Botões no jogo rodando
        buttons.running_state.pass_rodada = button("Passar Rodada", proxRodada, nil, 120, 30)
        buttons.running_state.exit_in_game = button("Sair", love.event.quit, nil, 80, 30)

    --Iniciar o jogo com os Hex vermelhos
        for i = 1, #pontosMovimentação do
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

--Guarda florestal
    movGuarda.imagem = love.graphics.newImage("sprites/Guarda Provisorio.png")

        --Configura a posição inicial do guarda
    movGuarda.x = pontosMovimentação[movGuarda.indiceAtual].x
    movGuarda.y = pontosMovimentação[movGuarda.indiceAtual].y

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
    cartas.atualizarInteracaoCartas(dt)
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
            
            for i, ponto in ipairs(pontosMovimentação) do
                if math.abs(ponto.x - movGuarda.x) < 5 and
                    math.abs(ponto.y - movGuarda.y) < 5 then
                        movGuarda.indiceAtual = i
                    break
                end
                
            end
            
            
            movGuarda.destino = nil
            
        end
    end
end 

-- Carregamento do mapa
local mapa = love.graphics.newImage("sprites/mapagradeado.png")

function love.draw()
    --Contagem do FPS
    love.graphics.printf("FPS: " .. love.timer.getFPS(), love.graphics.newFont(16),
    10, love.graphics.getHeight() - 30, love.graphics.getWidth())
     if game.state["running"] then
        --Ações Restantes
        love.graphics.print("Ações: " .. acoesRestantes, movimento.mx, movimento.my-20,0)
        --Movimentos Restantes
        love.graphics.print("Movimentos: " .. movimentosRestantes, movimento.mx, movimento.my, 0)
        
        --Feddback visual da quantidade de agua
        love.graphics.draw(imagemAgua.ficha, imagemAgua.fx, imagemAgua.fy, 0, escala, escala)
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(fonte.grande)  
        love.graphics.print(tostring(agua), imagemAgua.fx+40, imagemAgua.fy+8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fonte.normal)  
        --Numeração da rodada atual
        love.graphics.print("Rodada " .. rodada, 300, 550, 0)
        --love.graphics.clear(.937,.946,.96,1) para fazer o dundo do jogo
        --Saber a posição do mouse
        love.graphics.print("Mouse x: " .. love.mouse.getX() .. " y: " .. love.mouse.getY(), 500, 10, 0)
        --love.graphics.draw(fundo, 100, 100)
        -- Desenhar mapa As coordenadas x crescem para a direita e y para baixo
        --desenhar o mapa
        love.graphics.draw(mapa, love.graphics.getWidth()/4 - 200, love.graphics.getHeight()/2 - 370, 0, .35, .35)
        --Desenhar os filtros vermelhos e marrons
        for i, ponto in ipairs(pontosMovimentação) do
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
        
        cartas.desenharBaralho()
        conflitos.fundoConflito()
        --Desenhar a hitbox enquanto o jogo ta rodando
        hitbox.desenhar(love.graphics.getWidth()/2 + 15, love.graphics.getHeight()/2 - 245, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 15, love.graphics.getHeight()/2 - 145, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 15, love.graphics.getHeight()/2 - 45, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 15, love.graphics.getHeight()/2 + 55, 45)
        hitbox.desenhar(love.graphics.getWidth()/2 + 15, love.graphics.getHeight()/2 + 155, 45)
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
        cartas.desenharCartasRodada()
        -- Guardinha florestal
        if  movGuarda.quadros[movGuarda.frameAtual] then
        love.graphics.draw(movGuarda.imagem, movGuarda.quadros[movGuarda.frameAtual], movGuarda.x-20, movGuarda.y-20, 0, 0.2, 0.2)
        else
            love.graphics.draw(movGuarda.imagem, movGuarda.x-20, movGuarda.y-20)
        end
        --Desenhar os botões enquato o jogo ta rodando
        buttons.running_state.pass_rodada:draw(675, 350, 10, 10)
        buttons.running_state.exit_in_game:draw(700, 10, 10, 10)
        
        love.graphics.circle("fill", player.x, player.y, player.radius)
        
    elseif game.state["menu"] then
        buttons.menu_state.play_game:draw(10, 20, 10, 10)
        buttons.menu_state.settings:draw(10, 70, 10, 10)
        buttons.menu_state.exit_game:draw(10, 120, 10, 10)

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
end

