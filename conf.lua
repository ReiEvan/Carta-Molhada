function love.conf(t)
    t.window.fullscreen = true
    t.window.width = 1280
    t.window.height = 720
    --Parte importante pro mobile
    t.modules.touch = true
    t.window.resizable = true
    --Orientação da tela, nesse caso horizontal
    t.window.usedpiscale = true
end
