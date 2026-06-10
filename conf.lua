function love.conf(t)
    t.identity = "UltimaGota"
    t.version = "11.5"

    t.console = true
    t.window.title = "Última Gota"
    t.window.width = 1280
    t.window.height = 720
    --Parte importante pro mobile
    t.window.x = 100
    t.window.y = 100
    t.modules.joystick = true
    t.modules.audio = true
    t.modules.touch = true
    t.window.fullscreen = false
    t.window.resizable = true
    --Escala da tela, importante para mobile
    t.window.usedpiscale = true
    --Orientação da tela, nesse caso horizontal
    t.window.displayorientation = "landscape"
end