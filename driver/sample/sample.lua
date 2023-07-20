
local ret = {}

ret.cp = {}


ret.compatible = function(adr)
    return ret.cp.proxy(adr).type == "sample"
end



ret.getName = function()
    return "MightyPirates OC GPU Driver by InPixel Inc."
end

ret.getVersion = function()
    return 1
end



ret.new = function(adr)
    local com = {}
    local methods = component.methods(adr)
    for k,v in pairs(methods) do
        com[k] = "sa"
    end
    local drv = {}

    function drv.sample(sample)
        return com.sample(sample)
    end

    return drv
end

return ret