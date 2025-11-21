local love = require "love"
local button = require "Button"


local agua = 5
local rodada = 1

local game = {
    state = {
        menu = false,
        paused = false,
        running = true,
        ended = false,
        
    },
    points = 0,
}

local player ={
    radius = 20,
    x = 30,
    y = 30
}

local buttons = {
    menu_state = {}
}

local function startNewGame()
    game.state["menu"] = false
    game.state["running"] = true


    
end

--função para o mouse no menu
function love.mousepressed(x, y, button, istouch, presses)
    if not game.state["running"] then
        if button == 1 then
            if game.state["menu"] then
                for index in pairs(buttons.menu_state) do
                    buttons.menu_state[index] : checkPressed(x, y, player.radius)
                end
            end
        end
    end   
end


function love.load()
    love.mouse.setVisible(false)
    love.window.setTitle("Última Gota")
--Butões da tela do menu
    buttons.menu_state.play_game = button("Iniciar", startNewGame, nil, 80, 30)
    buttons.menu_state.settings = button("Configurações", nil, nil, 120, 30)
    buttons.menu_state.exit_game = button("Sair", love.event.quit, nil, 80, 30)
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
        love.graphics.circle("fill", player.x, player.y, player.radius)
        -- Desenhar mapa As coordenadas x crescem para a direita e y para baixo
        love.graphics.draw(mapa, 0, 0, 0, .35, .35)
        love.graphics.circle("fill", player.x, player.y, player.radius)
        -- Guardinha florestal
        --love.graphics.draw(drawable,x,y,r,sx,sy,ox,oy)
        love.graphics.draw(guardinha, 400, 250, 0, 0.35, 0.35)
    elseif game.state["menu"] then
        buttons.menu_state.play_game:draw(10, 20, 10, 10)
        buttons.menu_state.settings:draw(10, 70, 10, 10)
        buttons.menu_state.exit_game:draw(10, 120, 10, 10)
    end

        if not game.state["running"] then
        love.graphics.circle("fill", player.x, player.y, player.radius / 2)
    end
end

