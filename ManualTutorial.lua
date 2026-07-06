local ManualTutorial = {}

--Controle de página
local paginaAtual = 1
local totalPaginas = 4 --Dá pra aumentar ou diminuir se quiser

--Dados do tutorial para melhor explicação // Coloquei qualquer coisa só pra ter uma ideia de como vai ficar
local paginas = {
    [1] = {
        titulo = "Bem-vindo ao Tutorial",
        texto = "Este é o início do tutorial. Aqui você aprenderá os conceitos básicos do jogo."
    },
    [2] = {
        titulo = "Controles do Jogo",
        texto = "Lorem ipsum"
    },
    [3] = {
        titulo = "Objetivos do Jogo",
        texto = "Lorem ipsum"
    },
    [4] = {
        titulo = "Dicas e Truques",
        texto = "Lorem ipsum"
    }
}

--Config dos botões (coordenadas baseadas no tamanho vitual do canva)
local setaEsq = {x = 250, y = 350, w = 50, h = 50}
local setaDir = {x = 980, y = 350, w = 50, h = 50}
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

    --Texto da página atual
    love.graphics.setColor(0, 0, 0, 1) -- Cor preta
    local conteudo = paginas[paginaAtual]
    love.graphics.printf(conteudo.titulo, 300, 160, 680, "center", 0, 1.5, 1.5) -- Título maior
    love.graphics.printf(conteudo.texto, 320, 260, 640, "center")



    --Indicador de páginas ex: de 1/4
    love.graphics.printf(paginaAtual .. " / " .. totalPaginas, 300, 480, 680, "center")

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

function ManualTutorial.mousepressed(mx, my, button)
    if button ~= 1 then return false end -- Apenas botão esquerdo do mouse

    --Clique Seta Esquerda
    if paginaAtual > 1 and mx >= setaEsq.x and mx <= setaEsq.x + setaEsq.w and my >= setaEsq.y and my <= setaEsq.y + setaEsq.h then
        paginaAtual = paginaAtual - 1
        return true
    end

    --Clique Seta Direita
    if paginaAtual > 1 and mx >= setaEsq.x and mx <= setaEsq.x + setaEsq.w and my >= setaEsq.y and my <= setaEsq.y + setaEsq.h then
        paginaAtual = paginaAtual + 1
        return true
    end

    --Clique no botão fechar (Retorna false para fechar o manual no main)
    if mx >= btnFechar.x and mx <= btnFechar.x + btnFechar.w and my <= btnFechar.y + btnFechar.h then
        paginaAtual = 1 --Reseta a página atual para 1 ao fechar o tutorial
        return "fechar"
    end

    return true -- Retorna true para indicar que o clique foi tratado
end

return ManualTutorial