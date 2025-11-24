local love = require "love"

local sounds= {}
sounds.music = love.audio.newSource('musicas/som teste do pyxabay .mp3','stream')
sounds.music:setLooping(true)
local function somteste()
    sounds.music:play()
end
return {somteste = somteste}