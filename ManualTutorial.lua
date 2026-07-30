local love = require("love")
local ManualTutorial = {}

-- Controle de página
local paginaAtual = 1
local totalPaginas = 7
local tempoUltimoClique = 0 -- Armazena o tempo (em segundos) do último clique processado

-- Dados do tutorial
local paginas = {
    [1] = { img = love.graphics.newImage("sprites/tutorial/1.png") },
    [2] = { img = love.graphics.newImage("sprites/tutorial/2.png") },
    [3] = { img = love.graphics.newImage("sprites/tutorial/3.png") },
    [4] = { img = love.graphics.newImage("sprites/tutorial/4.png") },
    [5] = { img = love.graphics.newImage("sprites/tutorial/5.png") },
    [6] = { img = love.graphics.newImage("sprites/tutorial/6.png") },
    [7] = { img = love.graphics.newImage("sprites/tutorial/7.png") }
}

-- Config dos botões
local setaEsq   = {x = 210,  y = 350, w = 50,  h = 50}
local setaDir   = {x = 1020, y = 350, w = 50,  h = 50}
local btnFechar = {x = 540,  y = 550, w = 200, h = 50}

function ManualTutorial.draw()
    -- Desenha o fundo do tutorial
    love.graphics.setColor(0, 0, 0, 0.75) -- Fundo semi-transparente
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    -- Janela do tutorial
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 200, 100, 880, 520, 15, 15)

    -- Borda da janela
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", 200, 100, 880, 520, 15, 15)

    -- Imagem da página atual
    love.graphics.setColor(1, 1, 1)
    local conteudo = paginas[paginaAtual]
    if conteudo and conteudo.img then
        love.graphics.draw(conteudo.img, 200, 100, 0)
    end

    -- Indicador de páginas (ex: 1 / 7)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(paginaAtual .. " / " .. totalPaginas, 300, 520, 680, "center")

    -- Desenhar a seta esquerda
    if paginaAtual > 1 then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", setaEsq.x, setaEsq.y, setaEsq.w, setaEsq.h, 5, 5)
        love.graphics.print("<", setaEsq.x + 18, setaEsq.y + 15, 0, 2, 2)
    end

    -- Desenhar a seta direita
    if paginaAtual < totalPaginas then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", setaDir.x, setaDir.y, setaDir.w, setaDir.h, 5, 5)
        love.graphics.print(">", setaDir.x + 18, setaDir.y + 15, 0, 2, 2)
    end

    -- Desenhar o botão de fechar
    love.graphics.setColor(0.2, 0.6, 0.2, 1) -- Verde
    love.graphics.rectangle("fill", btnFechar.x, btnFechar.y, btnFechar.w, btnFechar.h, 8, 8)
    love.graphics.setColor(1, 1, 1, 1) -- Branco
    love.graphics.rectangle("line", btnFechar.x, btnFechar.y, btnFechar.w, btnFechar.h, 8, 8)
    love.graphics.printf("FECHAR", btnFechar.x, btnFechar.y + 15, btnFechar.w, "center")
end

function ManualTutorial.mousepressed(mx, my, button)
    if button ~= 1 then return true end

    -- TRAVA ANTI-DUPLO CLIQUE (DEBOUNCE):
    -- Se o clique/toque acontecer em menos de 0.25s do anterior, ele é ignorado
    local tempoAtual = love.timer.getTime()
    if tempoAtual - tempoUltimoClique < 0.25 then
        return true
    end

    -- 1. Clique Seta Esquerda
    if paginaAtual > 1 then
        if (mx >= setaEsq.x and mx <= setaEsq.x + setaEsq.w) and
           (my >= setaEsq.y and my <= setaEsq.y + setaEsq.h) then
            paginaAtual = paginaAtual - 1
            tempoUltimoClique = tempoAtual -- Atualiza o timer
            return true
        end
    end

    -- 2. Clique Seta Direita
    if paginaAtual < totalPaginas then
        if (mx >= setaDir.x and mx <= setaDir.x + setaDir.w) and
           (my >= setaDir.y and my <= setaDir.y + setaDir.h) then
            paginaAtual = paginaAtual + 1
            tempoUltimoClique = tempoAtual -- Atualiza o timer
            return true
        end
    end

    -- 3. Clique no botão fechar
    if (mx >= btnFechar.x and mx <= btnFechar.x + btnFechar.w) and
       (my >= btnFechar.y and my <= btnFechar.y + btnFechar.h) then
        paginaAtual = 1
        tempoUltimoClique = tempoAtual
        return "fechar"
    end

    return true -- Consumiu o toque dentro da área do tutorial
end

return ManualTutorial