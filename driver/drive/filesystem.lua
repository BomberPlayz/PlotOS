local cp = require("component")
local ret = {}

ret.compatible = function(adr)
    return cp.proxy(adr).type == "filesystem"
end


ret.getName = function()
    return "MightyPirates OC Managed Disk Driver by InPixel Inc."
end

ret.getVersion = function()
    return 1
end



ret.new = function(adr)
    local com = cp.proxy(adr)
    local drv = {}

    drv.spaceUsed = function()
        return com.spaceUsed()
    end

    drv.open = function(p,m)
        return com.open(p,m)
    end
    
    drv.seek = function(h,w,o)
        return com.seek(h,w,o)
    end

    drv.makeDirectory = function(p)
        return com.makeDirectory(p)
    end

    drv.exists = function(p)
        return com.exists(p)
    end

    drv.isReadOnly = function()
        return com.isReadOnly()
    end

    drv.write = function(ha,va)
        return com.write(ha,va)
    end

    drv.spaceTotal = function()
        return com.spaceTotal()
    end

    drv.isDirectory = function(pat)
        return com.isDirectory(pat)
    end

    drv.rename = function(papa, toto)
        return com.rename(papa, toto)
    end

    drv.list = function(pata)
        return com.list(pata)
    end

    drv.lastModified = function(fili)
        return com.lastModified(fili)
    end

    drv.getLabel = function()
        return com.getLabel()
    end

    drv.remove = function(pata)
        return com.remove(pata)
    end

    drv.close = function(han)
        return com.close(han)
    end

    drv.size = function(pak)
        return com.size(pak)
    end

    drv.read = function(han, cou)
        return com.read(han, cou)
    end

    drv.setLabel = function(lab)
        return com.setLabel(lab)
    end

    return drv
end

return ret