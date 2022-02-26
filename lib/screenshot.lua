local gpu = require("driver").load("gpu")
local function screenshot()
    local x,y = gpu.getResolution() 
    local screen = {}

    for i=1,y do
        screen[i] = {}
        for j=1,x do
            screen[i][j] = {gpu.get(j,i)}
        end
    end

    return screen
end

return screenshot