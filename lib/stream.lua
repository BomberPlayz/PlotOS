local stream = {}

function stream.create()
    local ret = {}
    ret.buffer = ""
    ret.pos = 1
    ret.read = function(self, n)
        local ret = self.buffer:sub(self.pos, self.pos + n - 1)
        self.pos = self.pos + n
        return ret
    end
    ret.write = function(self, str)
        self.buffer = self.buffer .. str
    end
    ret.seek = function(self, whence, offset)
        if whence == "set" then
            self.pos = offset
        elseif whence == "cur" then
            self.pos = self.pos + offset
        elseif whence == "end" then
            self.pos = #self.buffer + offset
        end
    end
    ret.close = function(self)
        self.buffer = ""
        self.pos = 1
    end
    return ret
end

function stream.proxy(h)
    local ret = {}
    ret.read = function(self, n)
        return h.read(n)
    end
    ret.write = function(self, str)
        if type(str) == "number" then
            str = string.char(str)
        end
        h.write(str)
    end
    ret.seek = function(self, whence, offset)
        h.seek(whence, offset)
    end
    ret.close = function(self)
        h.close()
    end
    return ret
end



return stream