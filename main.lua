local love = require "love"
local button = require "Button"


local agua = 5
local rodada = 1

local game = {
    state = {
        menu = true,
        paused = false,
        running = false,
        ended = false,
        
    },
    points = 0,
}

local function proxRodada()
    if rodada == rodada then
        rodada = rodada + 1
    end

end

local player ={
    radius = 15,
    x = 30,
    y = 30
}


local buttons = {
    menu_state = {},
    running_state = {}
 
}

local function startNewGame()
    game.state["menu"] = false
    game.state["running"] = true


    
end

--função para o mouse no menu
function love.mousepressed(x, y, button, isTouch, presses)
    if not game.state["paused"] then
        if button == 1 then
            if game.state["menu"] then
                for index in pairs(buttons.menu_state) do
                    buttons.menu_state[index] : checkPressed(x, y, player.radius)
                end
            elseif game.state["running"] then
                    for index in pairs(buttons.running_state) do
                        buttons.running_state[index] : checkPressed(x, y, player.radius)
                end
            end
        end
    end   
end


function love.load()
    love.mouse.setVisible(false)
    love.window.setTitle("Última Gota")
--Botões da tela do menu
    buttons.menu_state.play_game = button("Iniciar", startNewGame, nil, 80, 30)
    buttons.menu_state.settings = button("Configurações", nil, nil, 120, 30)
    buttons.menu_state.exit_game = button("Sair", love.event.quit, nil, 80, 30)
--Botões no jogo rodando
    buttons.running_state.pass_rodada = button("Passar Rodada", proxRodada, nil, 120, 30)
    buttons.running_state.exit_in_game = button("Sair", love.event.quit, nil, 80, 30)
end

function love.update(dt)
    player.x, player.y = love.mouse.getPosition()

end 

-- Carregamento do mapa
local mapa = love.graphics.newImage("sprites/mapagradeado.png")
-- Sprite do guardinha
local guardinha = love.graphics.newImage("sprites/Guarda Provisorio.png")

function love.draw()
    love.graphics.printf("FPS: " .. love.timer.getFPS(), love.graphics.newFont(16), 10, love.graphics.getHeight() - 30, love.graphics.getWidth())

    if game.state["running"] then
        --Numeração da rodada atual
        love.graphics.print("Rodada " .. rodada, 10, 10, 0)
        --love.graphics.clear(.937,.946,.96,1) para fazer o dundo do jogo
        --love.graphics.draw(fundo, 100, 100)
        -- Desenhar mapa As coordenadas x crescem para a direita e y para baixo
        love.graphics.draw(mapa, 0, 0, 0, .35, .35)
        
        -- Guardinha florestal
        love.graphics.draw(guardinha, 400, 250, 0, 0.35, 0.35)
        
        --Desenhar os botões enquato o jogo ta rodando
        buttons.running_state.pass_rodada:draw(500, 20, 10, 10)
        buttons.running_state.exit_in_game:draw(700, 10, 10, 10)
        
        love.graphics.circle("fill", player.x, player.y, player.radius)
    elseif game.state["menu"] then
        buttons.menu_state.play_game:draw(10, 20, 10, 10)
        buttons.menu_state.settings:draw(10, 70, 10, 10)
        buttons.menu_state.exit_game:draw(10, 120, 10, 10)

        love.graphics.circle("fill", player.x, player.y, player.radius)
    end

end

