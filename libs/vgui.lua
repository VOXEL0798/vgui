local class = require "libs.class.class"
local r = {}
local love = love

local function aabb(px, py, x, y, w, h)
    return px > x and px < x + w and py > y and py < y + h
end

local function clamp(min, val, max)
    return val > max and max or val < min and min or val
end

local function lerp(a,b,t)
    return a * (1-t) + b * t
end

local function list(source)
    local t = source or {}
    setmetatable(t, {
        __call = function(self, data)
            rawset(self, #self + 1, data)
        end
    })
    return t
end

local function pointOnSegment(px, py, x1, y1, x2, y2)
    local cx, cy = px - x1, py - y1
    local dx, dy = x2 - x1, y2 - y1
    local d = (dx*dx + dy*dy)
    if d == 0 then
        return x1, y1
    end
    local u = (cx*dx + cy*dy)/d
    if u < 0 then
        u = 0
    elseif u > 1 then
        u = 1
    end
    return x1 + u*dx, y1 + u*dy
end

local function distance (x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt ( dx * dx + dy * dy )
end

local pp = {x=0, y=0, stack={}}
local orig_translate = love.graphics.translate
function love.graphics.translate(x, y)
    pp.x = pp.x + x
    pp.y = pp.y + y
    orig_translate(x, y)
end

local orig_push = love.graphics.push
function love.graphics.push()
    pp.stack[#pp.stack + 1] = {x=pp.x, y=pp.y}
    orig_push()
end

local orig_pop = love.graphics.pop
function love.graphics.pop()
    orig_pop()
    pp.x = pp.stack[#pp.stack].x
    pp.y = pp.stack[#pp.stack].y
    table.remove(pp.stack, #pp.stack)
end

local orig_cursor = love.mouse.getPosition
function love.mouse.getPosition()
    local mx, my = orig_cursor()
    return (mx-pp.x), (my-pp.y)
end

function love.mouse.getGlobalPosition()
    return orig_cursor()
end

---@FRAME
r.frame = class("vgui.frame")
function r.frame:initialize(x, y, w, h)
    self.X = x
    self.Y = y
    self.W = w
    self.H = h
    self.enabled = true
    self.child   = {} --Child objects
    self.mousestate = {
        enter = false,
        down = false,
        downevent = function() return love.mouse.isDown(1) end
    }

    function self:setPos(x, y)
        self.X = x
        self.Y = y
    end

    function self:addPos( x, y )
        self.X = self.X + (x or 0)
        self.Y = self.Y + (y or 0)
    end

    self.onDraw = list({
        function(self)
            love.graphics.setColor(0.4, 0.4, 0.45)
            love.graphics.rectangle("fill", 0, 0, self.W, self.H, 3, 3)
        end
    })

    self.onUpdate     = list()
    self.onMouseEnter = list()
    self.onMouseLeave = list()
    self.onMouseHover = list()
    self.onMouseDown  = list()
    self.onMouseUp    = list()
    self.onMouseHold  = list()

    function self:add(object)
        if object.base == nil then
            self.child[#self.child + 1] = object
            object.base = self
        end
        return self
    end

    function self:draw()
        if self.enabled then
            love.graphics.push()
            love.graphics.translate(self.X, self.Y)
            for k, v in pairs(self.onDraw) do
                v(self)
            end
            for k, v in pairs(self.child) do
                v:draw()
            end
            love.graphics.pop()
        end
    end

    function self:update(dt)
        if self.enabled then
            love.graphics.push()
            love.graphics.translate(self.X, self.Y)
            for k, v in pairs(self.onUpdate) do
                v(self, dt)
            end
            for k, v in pairs(self.child) do
                v:update()
            end
            local mx, my = love.mouse.getPosition()
            local ab = aabb(mx, my, 0, 0, self.W, self.H)
            if ab then
                if self.mousestate.enter == false then
                    for k, v in pairs(self.onMouseEnter) do
                        v(self, dt)
                    end
                    self.mousestate.enter = true
                end
                for k, v in pairs(self.onMouseHover) do
                    v(self, dt)
                end
                if self.mousestate.downevent() then
                    for k, v in pairs(self.onMouseHold) do
                        v(self, dt)
                    end
                end
            else
                if self.mousestate.enter == true then
                    for k, v in pairs(self.onMouseLeave) do
                        v(self, dt)
                    end
                    self.mousestate.enter = false
                end

                self.mousestate.down = false
            end
            if self.mousestate.downevent() then
                if self.mousestate.down == false then
                    if ab then
                        for k, v in pairs(self.onMouseDown) do
                            v(self, dt)
                        end
                    end
                    self.mousestate.down = true
                end
            else
                if self.mousestate.down == true then
                    if ab then
                        for k, v in pairs(self.onMouseUp) do
                            v(self, dt)
                        end
                    end
                    self.mousestate.down = false
                end
            end
            love.graphics.pop()
        end
    end
end

---@SLDIER

r.slider = class("vgui.slider")
function r.slider:initialize(ax, ay, bx, by, def_value)
    self.AX = ax/2
    self.AY = ay/2
    self.BX = bx-(ax / 2)
    self.BY = by-(ay / 2)
    self.__private = {
        ax = ax,
        ay = ay,
        bx = bx,
        by = by
    }
    
    self.value = def_value or 0
    self.enabled = true
    self.mousestate = {
        enter = false,
        down = false,
        targ = {},
        downevent = function() return love.mouse.isDown(1) end
    }

    function self:setPos(ax, ay, bx, by)
        self.AX = (ax or self.__private.ax) * .5
        self.AY = (ay or self.__private.ay) * .5
        self.BX = (bx or self.__private.bx)-((ax or self.__private.ax) * .5)
        self.BY = (by or self.__private.by)-((ay or self.__private.ay) * .5)
    end

    function self:addPos(ax, ay, bx, by)
        self.AX = ((ax or 0) * .5) + self.AX
        self.AY = ((ay or 0) * .5) + self.AY
        self.BX = ((bx or 0)-((ax or 0) * .5)) + self.BX
        self.BY = ((by or 0)-((ay or 0) * .5)) + self.BY
    end

    self.onDraw = list({
        function(self)
            local x = lerp(self.AX, self.BX, self.value)
            local y = lerp(self.AY, self.BY, self.value)
            love.graphics.setColor(0.3, 0.3, 0.35)
            love.graphics.line(self.AX, self.AY, self.BX, self.BY)
            love.graphics.circle("fill", x, y, 6)
        end
    })
    self.onUpdate     = list()
    self.onMouseEnter = list()
    self.onMouseLeave = list()
    self.onMouseHover = list()
    self.onMouseDown  = list()
    self.onMouseUp    = list()
    self.onMouseHold  = list({
        function(self, dt)
            local mx, my = love.mouse.getPosition()
            local x, y = pointOnSegment(mx, my, self.AX, self.AY, self.BX, self.BY)
            self.value = distance(self.AX, self.AY, x, y) / distance(self.AX, self.AY, self.BX, self.BY)
        end
    })

    function self:draw()
        if self.enabled then
            love.graphics.push()
            love.graphics.translate(self.AX, self.AY)
            for k, v in pairs(self.onDraw) do
                v(self)
            end
            love.graphics.pop()
        end
    end

    function self:update(dt)
        if self.enabled then
            love.graphics.push()
            love.graphics.translate(self.AX, self.AY)
            for k, v in pairs(self.onUpdate) do
                v(self, dt)
            end
            local mx, my = love.mouse.getPosition()
            local x, y = pointOnSegment(mx, my, self.AX, self.AY, self.BX, self.BY)
            local ab = distance(mx, my, x, y) < 3
            if ab then
                if self.mousestate.enter == false then
                    for k, v in pairs(self.onMouseEnter) do
                        v(self, dt)
                    end
                    self.mousestate.enter = true
                end
                for k, v in pairs(self.onMouseHover) do
                    v(self, dt)
                end
            else
                if self.mousestate.enter == true then
                    for k, v in pairs(self.onMouseLeave) do
                        v(self, dt)
                    end
                    self.mousestate.enter = false
                end

                self.mousestate.down = false
            end

            if self.mousestate.downevent() then
                if self.mousestate.down == false then
                    if ab then
                        self.mousestate.targ = self
                        for k, v in pairs(self.onMouseDown) do
                            v(self, dt)
                        end
                    end
                    self.mousestate.down = true
                end
                if self.mousestate.targ == self then
                    for k, v in pairs(self.onMouseHold) do
                        v(self, dt)
                    end
                end
            else
                self.mousestate.targ = {}
                if self.mousestate.down == true then
                    if ab then
                        for k, v in pairs(self.onMouseUp) do
                            v(self, dt)
                        end
                    end
                    self.mousestate.down = false
                end
            end
            love.graphics.pop()
        end
    end
end

return r