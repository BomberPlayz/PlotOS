
local ret = {}

ret.cp = {}



ret.compatible = function(adr)
    return ret.cp.proxy(adr).type == "internet"
end



ret.getName = function()
    return "MightyPirates OC internet card Driver by InPixel Inc."
end

ret.getVersion = function()
    return 1
end



ret.new = function(adr)
    local com = ret.cp.proxy(adr)

    local drv = {}

    function drv.isTcpEnabled()
        return com.tcpEnabled()
    end

    function drv.isHttpEnabled()
        return com.httpEnabled()
    end

    function drv.connect(addr,port)
        return com.connect(addr,port)
    end

    function drv.request(url,postData,headers)
        return com.request(url,postData,headers)
    end
    
    return drv
end

return ret