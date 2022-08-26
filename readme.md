# vgui
`vgui` библиотека для создания графического интерфейса,
`кнопок`, `ползунков`, `крутилок` и тому подобного.

`vgui.frame` имеет возможность быть вложенной в другой `vgui.frame` со своими собственными фреймами и объектами.

`vgui.frame` может являться как корневым окном, так и кнопкой, зависимо от хотелок.
***

### example
```lua
local vgui = require("libs.vgui")
local f = vgui.frame("fill", 100, 100, 256, 256)
math.randomseed(os.time())

f.persist.color = {1, 1, 1}
f.onDraw(function(self) --add new event on draw
    love.graphics.setColor(self.persist.color)
    love.graphics.rectangle("fill", 0, 0, self.W, self.H)
end)

f.onMouseEnter(function(self, dt)  --add new event on mouse enter
    self.persist.color = {math.random(0, 1), math.random(0, 1), math.random(0, 1)}
end)

f.onMouseEnter(function(self, dt)  --add new event on mouse enter
    self.X = self.X + 32
    self.W = self.W - 32
end)

f.onMouseLeave(function(self, dt)  --add new event on mouse leave
    self.persist.color = {math.random(0, 1), math.random(0, 1), math.random(0, 1)}
    f.W = f.W + 32
end)


local f2 = vgui.frame("fill", 128, 128, 64, 64)
math.randomseed(os.time())

f2.persist.color = {1, 1, 1}

f2.onDraw(function(self)
    love.graphics.setColor(self.persist.color)
    love.graphics.rectangle("fill", 0, 0, self.W, self.H)
end)

f2.onMouseDown(function(self, dt)
    self.persist.color = {0, 1, 0}
end)

f2.onMouseUp(function(self, dt)
    self.persist.color = {1, 0, 0}
end)

f2.onMouseLeave(function(self, dt)
    self.persist.color = {1, 0, 0}
end)

f:add(f2)

function love.draw()
    f:draw()
end

function love.update(dt)
    f:update(dt)
end
```
