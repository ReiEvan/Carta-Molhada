local love = require "love"

local sounds= {}
sounds.music = love.audio.newSource('musicas/rascunho trilha padrao.mp3','stream')
sounds.music:setLooping(true)
local function somteste()
    sounds.music:play()
end
return {somteste = somteste}