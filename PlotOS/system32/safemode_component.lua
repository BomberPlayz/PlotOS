setmetatable(component, {
    __index = function(_,k)
        return component.proxy(component.list(k)())
    end
})