local FonteNumeros = {}
local imagens = {}

function FonteNumeros.load(caminhoPasta)
    -- Remove barras extras no final do caminho, se houver
    local pasta = caminhoPasta:gsub("/$", "")

    for i = 0, 9 do
        local path = pasta .. "/" .. i .. ".png"
        
        -- Carrega a imagem se o arquivo existir
        if love.filesystem.getInfo(path) then
            imagens[i] = love.graphics.newImage(path)
            print("[Fonte] Carregado com sucesso: " .. path)
        else
            print("[Fonte] AVISO: Arquivo nao encontrado em: " .. path)
        end
    end
end

function FonteNumeros.desenhar(texto, x, y, escala)
    local stringTexto = tostring(texto)
    local cursorX = x
    -- CORREÇÃO: Usamos 'multiplicador' para não conflitar com o argumento 'escala'
    local multiplicador = escala or 1

    for i = 1, #stringTexto do
        local digito = tonumber(stringTexto:sub(i, i))
        
        if digito and imagens[digito] then
            local img = imagens[digito]
            
            -- Desenha usando o multiplicador correto
            love.graphics.draw(img, cursorX, y, 0, multiplicador, multiplicador)
            
            -- Avança o cursor baseado na largura da imagem e na escala
            cursorX = cursorX + (img:getWidth() * multiplicador) + 2
        end
    end
end

return FonteNumeros