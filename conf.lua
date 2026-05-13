function love.conf(t)
    t.window.title = "Última Gota"
    t.window.width = 1280
    t.window.height = 720
    --Parte importante pro mobile
    t.modules.joystick = true
    t.modules.audio = true
    t.modules.touch = true
    t.window.fullscreen = false
    t.window.resizable = true
    --Orientação da tela, nesse caso horizontal
    t.window.usedpiscale = true
end