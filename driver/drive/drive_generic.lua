local ret = {}

ret.cp = {}

local cp = ret.cp

ret.compatible = function(adr)
    --print("targonca: "..ret.cp.proxy(adr).type)
    return ret.cp.proxy(adr).type == "drive" and ret.cp.proxy(adr).readSector(1):sub(1, 4) ~= "POFS"
end


ret.getName = function()
    return "Generic Unmanaged Disk Driver"
end

ret.getVersion = function()
    return 1
end

local component = cp


ret.new = function(adr)
    kern_log("Disk!")
    local com = ret.cp.proxy(adr)

    local drv = {}

    function drv.checkCompatible()
        return false
    end

    function drv.getPartitions()
        return nil, "Incompatible filesystem"
    end

    return drv
end

return ret
