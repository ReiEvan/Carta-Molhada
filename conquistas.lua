local love = require("love")
local Conquistas = {}

--Caminho do arquivo de save persistente
local ARQUIVO_SAVE = "conquistas_save.txt"

--Lista de conquistas e dados educativos
Conquistas.lista = {
    primeira_gota = {
        id = "primeira_gota",
        nome = "Primeiro Passo",
        desc = "Limpe a primeira bandeira da ilha.",
        fato = "Mais de 50% do oxigênio da Terra vem de microalgas marinhas.",
        desbloqueada = false
    },
    era_industrial = {
        id = "era_industrial",
        nome = "Alerta Ecológico",
        desc = "Avance para a Era II da partida.",
        fato = "A atividade industrial costeira acelera a acidificação dos mares.",
        desbloqueada = false
    },
    guardiao_ilha = {
        id = "guardiao_ilha",
        nome = "Guardião das Águas",
        desc = "Vença uma partida limpando as 4 bandeiras.",
        fato = "Zonas marinhas preservadas conseguem quadruplicar a biodiversidade local.",
        desbloqueada = false
    },
    reserva_cheia = {
        id = "reserva_cheia",
        nome = "Mestre da Gestão",
        desc = "Acumule 6 ou mais gotas de água na reserva.",
        fato = "Menos de 1% de toda a água da Terra é doce e diretamente aproveitável.",
        desbloqueada = false
    }
--[[    primeira_gota = {
        id = ,
        nome = ,
        desc = ,
        fato = ,
        desbloqueada = false
    },
    primeira_gota = {
        id = ,
        nome = ,
        desc = ,
        fato = ,
        desbloqueada = false
    },
    primeira_gota = {
        id = ,
        nome = ,
        desc = ,
        fato = ,
        desbloqueada = false
    },
    primeira_gota = {
        id = ,
        nome = ,
        desc = ,
        fato = ,
        desbloqueada = false
    }]]
}

local toast = {
    ativo = false,
    titulo = "",
    nomeConquista = "",
    timer = 0,
    duracao = 4.0,
    yAtual = -80,
    yAlvo = 20,
}

function Conquistas.carregar()
    if love.filesystem.getInfo(ARQUIVO_SAVE) then
        local conteudo = love.filesystem.read(ARQUIVO_SAVE)
        if conteudo then
            for id in string.gmatch(conteudo, "([%w_]+)") do
                if Conquistas.lista[id] then
                    Conquistas.lista[id].desbloqueada = true
                end
            end
        end
    end
end

function Conquistas.salvar()
    local str = ""
    for id, dados in pairs(Conquistas.lista) do
        if dados.desbloqueada then
            str = str .. id .. "\n"
        end
    end
    love.filesystem.write(ARQUIVO_SAVE, str)
end

function Conquistas.desbloquear(id)
    local c = Conquistas.lista[id]
    if c and not c.desbloqueada then
        c.desbloqueada = true
        Conquistas.salvar()
        toast.ativo = true
        toast.titulo = "CONQUISTA DESBLOQUEADA!"
        toast.nomeConquista = c.nome
        toast.timer = toast.duracao
        toast.yAtual = -80
    end
end

function Conquistas.update(dt)
    dt = dt or love.timer.getDelta()

    if toast.ativo then
        toast.timer = toast.timer - dt

        if toast.timer > 0.5 then
            toast.yAtual = toast.yAtual + (toast.yAlvo - toast.yAtual) * 10 * dt
        else
            toast.yAtual = toast.yAtual + (-80 - toast.yAtual) * 10 * dt
        end

        if toast.timer <= 0 then
            toast.ativo = false
        end
    end
end

function Conquistas.drawToast(virtual_Width)
    if not toast.ativo then return end

    local largura = 420
    local altura = 65
    local x = (virtual_Width - largura) / 2
    local y = toast.yAtual

    love.graphics.setColor(0.08, 0.12, 0.2, 0.95)
    love.graphics.rectangle("fill", x, y, largura, altura, 10, 10)

    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, largura, altura, 10, 10)

    love.graphics.circle("fill", x + 30, y + 32, 14)
    love.graphics.setColor(0.08, 0.12, 0.2, 1)
    love.graphics.print("★", x + 23, y + 21)

    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.print(toast.titulo, x + 55, y + 10)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(toast.nomeConquista, x + 55, y + 32)

    love.graphics.setColor(1, 1, 1, 1)
end

return Conquistas