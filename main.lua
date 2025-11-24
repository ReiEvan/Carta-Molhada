local love = require "love"
local button = require "Button"
local cartas = require "cartas"
local conflitos = require "conflitos"
local hitbox = require "Hitbox"
local ost = require "OST"


local agua = 5
local imagemAgua
local escala = 0.4
local rodada = 1
local card_back_image


local deck = {}
--lista de pontos de movimentação
local pontosMovimentação = {

    {x = love.graphics.getWidth()/2 + 15, y = love.graphics.getHeight()/2 - 245, raio = 45},
    {x = love.graphics.getWidth()/2 + 15, y = love.graphics.getHeight()/2 - 145, raio = 45},
    {x = love.graphics.getWidth()/2 + 15, y = love.graphics.getHeight()/2 - 45, raio = 45},
    {x = love.graphics.getWidth()/2 + 15, y = love.graphics.getHeight()/2 + 55, raio = 45},
    {x = love.graphics.getWidth()/2 + 15, y = love.graphics.getHeight()/2 + 155, raio = 45},
    {x = love.graphics.getWidth()/2 + 190, y = love.graphics.getHeight()/2 - 145, raio = 45},
    {x = love.graphics.getWidth()/2 + 190, y = love.graphics.getHeight()/2 - 45, raio = 45},
    {x = love.graphics.getWidth()/2 + 190, y = love.graphics.getHeight()/2 + 55, raio = 45},
    {x = love.graphics.getWidth()/2 - 160, y = love.graphics.getHeight()/2 - 145, raio = 45},
    {x = love.graphics.getWidth()/2 - 160, y = love.graphics.getHeight()/2 - 45, raio = 45},
    {x = love.graphics.getWidth()/2 - 160, y = love.graphics.getHeight()/2 + 55, raio = 45},
    {x = love.graphics.getWidth()/2 + 100, y = love.graphics.getHeight()/2 - 195, raio = 45},
    {x = love.graphics.getWidth()/2 + 100, y = love.graphics.getHeight()/2 - 95, raio = 45},
    {x = love.graphics.getWidth()/2 + 100, y = love.graphics.getHeight()/2 + 5, raio = 45},
    {x = love.graphics.getWidth()/2 + 100, y = love.graphics.getHeight()/2 + 105, raio = 45},
    {x = love.graphics.getWidth()/2 + 100, y = love.graphics.getHeight()/2 + 205, raio = 45},
    {x = love.graphics.getWidth()/2 - 75, y = love.graphics.getHeight()/2 - 195, raio = 45},
    {x = love.graphics.getWidth()/2 - 75, y = love.graphics.getHeight()/2 - 95, raio = 45},
    {x = love.graphics.getWidth()/2 - 75, y = love.graphics.getHeight()/2 + 5, raio = 45},
    {x = love.graphics.getWidth()/2 - 75, y = love.graphics.getHeight()/2 + 105, raio = 45}

}

--Estado do guarda (onde ele está)
local movGuarda = {
    x = pontosMovimentação[3].x,
    y = pontosMovimentação[3].y,
    imagem = love.graphics.newImage("sprites/Guarda Provisorio.png"),
    destino = nil,
    velocidade = 200,
    raioColisão = 30,
    interagindo = false,
    direcao = "direita",
    frameAtual = 1,
    quadros = {}
}

local game = {
    state = {
        menu = true,
        paused = false,
        running =false,
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
    if rodada == rodada then
        rodada = rodada + 1
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
    if button == 1 then
        --verfica colisão com cada ponto de movimentação
        for _, ponto in ipairs(pontosMovimentação) do
        local distancia = math.sqrt((ponto.x - x)^2 + (ponto.y - y)^2)
            if distancia <= ponto.raio then
            movGuarda.destino = {x = ponto.x, y = ponto.y}
            return
        end
    end

    handle_button_click(x, y, player.radius)
    end

end


function love.load()
    love.mouse.setVisible(false)
    love.window.setTitle("Última Gota")
    ost.somteste()
   
--Imagem da agua
    imagemAgua = love.graphics.newImage("sprites/Gota-provisoria.jpeg")
--baralho azul
     cartas.construirBaralho()
-- carregar cartas aleatórias     
    cartas.selecionarCartasRodada()
--Botões da tela do menu
    buttons.menu_state.play_game = button("Iniciar", startNewGame, nil, 80, 30)
    buttons.menu_state.settings = button("Configurações", nil, nil, 120, 30)
    buttons.menu_state.exit_game = button("Sair", love.event.quit, nil, 80, 30)
--Botões no jogo rodando
    buttons.running_state.pass_rodada = button("Passar Rodada", proxRodada, nil, 120, 30)
    buttons.running_state.exit_in_game = button("Sair", love.event.quit, nil, 80, 30)

--Guarda florestal
    movGuarda.imagem = love.graphics.newImage("sprites/Guarda Provisorio.png")

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
            movGuarda.destino = nil
            
        end
    end
end 

-- Carregamento do mapa
local mapa = love.graphics.newImage("sprites/mapagradeado.png")

function love.draw()
    love.graphics.printf("FPS: " .. love.timer.getFPS(), love.graphics.newFont(16), 10, love.graphics.getHeight() - 30, love.graphics.getWidth())
    --cardSprite = love.graphics.newImage("sprites/fundo carta azul-pitico.png")
     if game.state["running"] then
        --Feddback visual da quantidade de agua
        for i = 1, agua do
            local x = (i - 1) * (imagemAgua:getWidth() * escala + 10)

            love.graphics.draw(imagemAgua, x + 135, 10, 0, escala, escala)
            
        end
        --Numeração da rodada atual
        love.graphics.print("Rodada " .. rodada, 10, 550, 0)
        --love.graphics.clear(.937,.946,.96,1) para fazer o dundo do jogo
        --Saber a posição do mouse
        love.graphics.print("Mouse x: " .. love.mouse.getX() .. " y: " .. love.mouse.getY(), 500, 10, 0)
        --love.graphics.draw(fundo, 100, 100)
        -- Desenhar mapa As coordenadas x crescem para a direita e y para baixo
        cartas.desenharBaralho()
        
        conflitos.fundoConflito()
        love.graphics.draw(mapa, love.graphics.getWidth()/4 - 200, love.graphics.getHeight()/2 - 370, 0, .35, .35)
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
        hitbox.desenhar(love.graphics.getWidth()/2 + 100, love.graphics.getHeight()/2 + 205, 45)
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
    if key == "space" then
        cartas.escolherCartasAleatorias()
    end
    if key == "escape" then
        game.state["paused"] = not game.state["paused"]
    end
end

