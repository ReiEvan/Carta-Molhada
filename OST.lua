local love = require "love"

ost = {}

function ost.atualizarVolume(valor)
    volumeMaster = math.max(0, math.min(1, valor)) -- Garante que fique entre 0 e 1
    love.audio.setVolume(volumeMaster)
end

local sounds= {}
sounds.music = love.audio.newSource('musicas/João Cabral - Musica das agua- 5 Nov 2025, 1105 (online-audio-converter.com).mp3','stream')
sounds.music:setLooping(true)
local function somteste()
    sounds.music:play()
end
return {
        somteste = somteste
}