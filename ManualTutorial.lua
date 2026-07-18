local love = require("love")
local ManualTutorial = {}

--Controle de página
local paginaAtual = 1
local totalPaginas = 7 --Dá pra aumentar ou diminuir se quiser

--Dados do tutorial para melhor explicação // Coloquei qualquer coisa só pra ter uma ideia de como vai ficar
local paginas = {
    [1] = {
        img = love.graphics.newImage("sprites/tutorial/1.png")
    },
    [2] = {
        img = love.graphics.newImage("sprites/tutorial/2.png")
    },
    [3] = {
        img = love.graphics.newImage("sprites/tutorial/3.png")
    },
    [4] = {
        img = love.graphics.newImage("sprites/tutorial/4.png")
    },
    [5] = {
        img = love.graphics.newImage("sprites/tutorial/5.png")
    },
    [6] = {
        img = love.graphics.newImage("sprites/tutorial/6.png")
    },
    [7] = {
        img = love.graphics.newImage("sprites/tutorial/7.png")
    }
}

--Config dos botões (coordenadas baseadas no tamanho vitual do canva)
local setaEsq = {x = 210, y = 350, w = 50, h = 50}
local setaDir = {x = 1020, y = 350, w = 50, h = 50}
local btnFechar = {x = 540, y = 550, w = 200, h = 50} -- botão centralizado embaixo, até o momento

function ManualTutorial.draw()
    --Desenha o fundo do tutorial
    love.graphics.setColor(0, 0, 0, 0.75) -- Fundo semi-transparente
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    --Janela do tutorial
    love.graphics.setColor(1, 1, 1) -- Cor branca
    love.graphics.rectangle("fill", 200, 100, 880, 520, 15, 15) -- Janela com cantos arredondados

    --Borda da janela
    love.graphics.setColor(1, 1, 1, 0.5) -- Cor branca semi-transparente
    love.graphics.rectangle("line", 200, 100, 880, 520, 15, 15)

    --Imagem da página atual
    love.graphics.setColor(1, 1, 1)
    local conteudo = paginas[paginaAtual]
    love.graphics.draw(conteudo.img, 200, 100, 0)



    --Indicador de páginas ex: de 1/7
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(paginaAtual .. " / " .. totalPaginas, 300, 520, 680, "center")

    --Desenhar a seta esquerda

    if paginaAtual > 1 then
        love.graphics.rectangle("line", setaEsq.x, setaEsq.y, setaEsq.w, setaEsq.h, 5, 5)
        love.graphics.print("<", setaEsq.x + 18, setaEsq.y + 15, 0, 2, 2)
    end

    --Desenhar a seta direita
    if paginaAtual < totalPaginas then
        love.graphics.rectangle("line", setaDir.x, setaDir.y, setaDir.w, setaDir.h, 5, 5)
        love.graphics.print(">", setaDir.x + 18, setaDir.y + 15, 0, 2, 2)
    end

    --Desenhar o botão de fechar
    love.graphics.setColor(0.2, 0.6, 0.2, 1) -- Cor verde
    love.graphics.rectangle("fill", btnFechar.x, btnFechar.y, btnFechar.w, btnFechar.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1) -- Cor branca
    love.graphics.rectangle("line", btnFechar.x, btnFechar.y, btnFechar.w, btnFechar.h, 8, 8)
    love.graphics.printf("FECHAR", btnFechar.x, btnFechar.y + 15, btnFechar.w, "center")
end

function ManualTutorial.mousereleased(mx, my, button, isTouch)
    if button ~= 1 then return false end -- Apenas botão esquerdo do mouse

    --Clique Seta Esquerda
    if paginaAtual > 1 then
        if (mx >= setaEsq.x and mx <= setaEsq.x + setaEsq.w) and
           (my >= setaEsq.y and my <= setaEsq.y + setaEsq.h) then
        paginaAtual = paginaAtual - 1
            return true
        end
    end

    --Clique Seta Direita
    if paginaAtual < totalPaginas then
        if (mx >= setaDir.x and mx <= setaDir.x + setaDir.w) and
           (my >= setaDir.y and my <= setaDir.y + setaDir.h) then
            paginaAtual = paginaAtual + 1
            return true
        end
    end

    --Clique no botão fechar (Retorna false para fechar o manual no main)
    if (mx >= btnFechar.x and mx <= btnFechar.x + btnFechar.w) and
       (my >= btnFechar.y and my <= btnFechar.y + btnFechar.h) then
        paginaAtual = 1 --Reseta a página atual para 1 ao fechar o tutorial
        return "fechar"
    end

    return true -- Retorna true para indicar que o clique foi tratado
end

return ManualTutorial