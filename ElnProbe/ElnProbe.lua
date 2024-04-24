local ret = {}

ret.cp = {}

local cp = ret.cp

ret.compatible = function(adr)
    kern_log("targonca: " .. tostring(cp))
    return cp.proxy(adr).type == "ElnProbe"
end

ret.getName = function()
    return "Jrddunbr ELN Computer Probe Driver by InPixel Inc."
end

ret.getVersion = function()
    return 1
end




ret.new = function(adr)
    local com = {}
    local methods = ret.cp.methods(adr)
    for k, v in pairs(methods) do
        com[k] = v
    end
    local drv = {}

    drv.signalSetDir = function(s, sin)
        return com.signalSetDir(s, sin)
    end

    drv.signalGetDir = function(s)
        return com.signalGetDir(s)
    end

    drv.signalGetIn = function(s)
        return com.signalGetIn(s)
    end

    drv.signalSetOut = function()
        return com.signalSetOut()
    end

    drv.wirelessGet = function(ch)
        return com.wirelessGet(ch)
    end

    drv.wirelessSet = function(ch, n)
        return com.wirelessSet(ch, n)
    end

    drv.wirelessRemove = function(ch)
        return com.wirelessRemove(ch)
    end

    drv.wirelessRemoveAll = function()
        return com.wirelessRemoveAll()
    end

    return drv
end

return ret
