
local ret = {}

ret.cp = {}

local cp = ret.cp

ret.compatible = function(adr)
    return ret.cp.proxy(adr).type == "sample"
end



ret.getName = function()
    return "OpenPrinter OC driver by InPixel Inc."
end

ret.getVersion = function()
    return 1
end



ret.new = function(adr)
    local com = cp.proxy(adr)
    local drv = {}

    function drv.sample(sample)
        return com.sample(sample)
    end

    return drv
end

return ret