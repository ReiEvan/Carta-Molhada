local love = require "love"
local button = require "Button"

local game = {
    state = {
        menu = false,
        paused = false,
        running = true,
        ended = false,
        
    }
}

local buttons = {
    menu_state = {}
}

local player ={
    radius = 20,
    x = 30,
    y = 30
}

function love.load()
    love.mouse.setVisible(false)
    love.window.setTitle("Carta Molhada")

    buttons.menu_state.play_game = button("Iniciar", nil, nil, 40, 30)
    buttons.menu_state.settings = button("Configurações", nil, nil, 40, 30)
    buttons.menu_state.exit_game = button("Sair", love.event.quit, nil, 40, 30)
end

function love.mousepressed(x, y, button, istouch, presses)
    if not game.state['running'] then
        if button == 1 then
            if game.state["menu"] then
                for index in pairs(buttons.menu_state) do
                    buttons.menu_state[index]:checkPressed(x, y, player.radius)
                end
            end
        end
    end   
end

function love.update(dt)
    player.x, player.y = love.mouse.getPosition()
end
-- Carregamento do mapa
local mapa = love.graphics.newImage("sprites/mapagradeado.png")

function love.draw()
    love.graphics.printf("FPS: " .. love.timer.getFPS(), love.graphics.newFont(16), 10, love.graphics.getHeight() - 30, love.graphics.getWidth())

    if game.state["running"] then
        love.graphics.circle("fill", player.x, player.y, player.radius)
        -- Desenhar mapa As coordenadas x crescem para a direita e y para baixo
        love.graphics.draw(mapa, 0, 0, 0, .35, .35)
        love.graphics.circle("fill", player.x, player.y, player.radius)
    elseif game.state["menu"] then
        buttons.menu_state.play_game:draw(10, 20, 10, 20)
        buttons.menu_state.settings:draw(10, 70, 10, 20)
        buttons.menu_state.exit_game:draw(10, 120, 10, 20)
    end

        if not game.state["running"] then
        love.graphics.circle("fill", player.x, player.y, player.radius / 2)
    end
end

