local love = require "love"

function Button(textOrImg, func, func_param, width, height, imagePressed)
    
    local isImage = (type(textOrImg) == "userdata")
    local btnWidth = width
    local btnHeight = height
    
    --Se for imagem e não tiver largura definida, usa o tamanho da imagem
    if isImage then
        if not btnWidth then btnWidth = textOrImg:getWidth() end
        if not btnHeight then btnHeight = textOrImg:getHeight() end
    else
        --Se for texto, usa o padrão 100x100 se não for informado
        btnWidth = width or 100
        btnHeight = height or 100
    end

    return{
        width = width or 100,
        height = height or 100,
        func = func or function() print("Esse botão ainda não tem nenhuma função") end,
        func_param = func_param,
        image = isImage and textOrImg or nil,
        imagePressed = imagePressed,
        text = not isImage and textOrImg or "Sem Texto",
        button_x = 0,
        button_y = 0,
        text_x = 0,
        text_y = 0,
        invisivel = false, -- PROPRIEDADE NOVA: Se for true, não desenha nada na tela!

        checkPressed = function (self, mouse_x, mouse_y, cursor_radius)
            if (mouse_x + cursor_radius >= self.button_x) and (mouse_x - cursor_radius <= self.button_x + self.width) then
                if (mouse_y + cursor_radius >= self.button_y) and (mouse_y - cursor_radius <= self.button_y + self.height) then
                    if self.func_param then
                        self.func(self.func_param)
                    else
                        self.func()
                    end
                end
            end
        end,
    
        draw = function (self, button_x, button_y, text_x, text_y)
            -- Atualiza a posição da hitbox
            self.button_x = button_x or self.button_x
            self.button_y = button_y or self.button_y

            -- SE O BOTÃO FOR INVISÍVEL: Para aqui!
            -- Ele atualizou a posição (button_x e button_y) acima, mas não desenha nada na tela.
            if self.invisivel then
                return
            end

            --Detecção de clique visual
            local imgParaDesenhar = self.image

            --Se tivermos uma imagem de "pressionado", verificamos se devemos usá-la
            if self.imagePressed then
                local mx, my = love.mouse.getPosition()
                local isDown = love.mouse.isDown(1) --1 é o botão esquerdo

                --Verifica colisão Mouse vs Retangulo do botão
                local mouseEmCima = (mx >= self.button_x) and (mx <= self.button_x + self.width) and
                                    (my >= self.button_y) and (my <= self.button_y + self.height)

                --Se o mouse ta em cima e botão apertado, troca a imagem
                if mouseEmCima and isDown then
                    imgParaDesenhar = self.imagePressed
                end
            end

            if self.image then
                love.graphics.setColor(1,1,1)

                --Calcula a escala para a imagem caber exatamente na largura/altura definida
                local sx = self.width / imgParaDesenhar:getWidth()
                local sy = self.height / imgParaDesenhar:getHeight()

                love.graphics.draw(imgParaDesenhar, self.button_x, self.button_y, 0, sx, sy)

            else
                if text_x then
                    self.text_x = text_x + self.button_x
                else
                    self.text_x = self.button_x
                end

                if text_y then
                    self.text_y = text_y + self.button_y
                else
                    self.text_y = self.button_y
                end

                love.graphics.setColor(0.6,0.6,0.6)
                love.graphics.rectangle("fill", self.button_x, self.button_y, self.width, self.height)

                love.graphics.setColor(0,0,0)
                love.graphics.print(self.text, self.text_x, self.text_y)

                love.graphics.setColor(1,1,1)
            end
        end
    }

end

return Button