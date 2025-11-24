local love = require "love"

sounds= {}
sounds.music = love.audio.newSource('musicas/som teste do pyxabay .mp3','stream')
local function somteste()
    sounds.music:play()
end
return {somteste = somteste}