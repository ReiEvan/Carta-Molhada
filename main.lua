local love = require "love"
local button = require "Button"

local game = {
    state = {
        menu = true,
        paused = false,
        running = false,
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
end

function love.update(dt)
    player.x, player.y = love.mouse.getPosition()
end

function love.draw()
    love.graphics.printf("FPS: " .. love.timer.getFPS(), love.graphics.newFont(16), 10, love.graphics.getHeight() - 30, love.graphics.getWidth())

    if game.state["running"] then
        love.graphics.circle("fill", player.x, player.y, player.radius)
    elseif game.state["menu"] then
        buttons.menu_state.play_game:draw(10, 20, 10, 20)
    end

        if not game.state["running"] then
        love.graphics.circle("fill", player.x, player.y, player.radius / 2)
    end
end

