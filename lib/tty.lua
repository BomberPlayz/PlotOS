local tty = {}
tty.__index = tty

function tty.new()
    local self = setmetatable({}, tty)
    self.buffer = {}
    self.cursor = {x = 1, y = 1}
    self.size = {w = 80, h = 25}
    return self
end


return tty