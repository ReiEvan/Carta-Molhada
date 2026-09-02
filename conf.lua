function love.conf(t)
    t.identity = "UltimaGota"
    t.version = "11.5"

    t.console = false
    t.window.title = "Última Gota"
    t.window.width = 1280
    t.window.height = 720
    --Parte importante pro mobile
    t.accelerometerjoystick = false
    t.modules.audio = true
    t.modules.touch = true
    t.window.fullscreen = false
    t.window.resizable = false
    t.window.fullscreentype = "exclusive"
    --Escala da tela, importante para mobile
    t.window.usedpiscale = false
    --Orientação da tela, nesse caso horizontal
    t.window.displayorientation = "landscape"
    t.window.orientation = "landscape"
end