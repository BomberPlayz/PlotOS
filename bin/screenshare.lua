local modem = component.modem
local ser = require("serialization")
local gpu = component.gpu
local maxx = 10
local maxy = 10

gpu.setResolution(151,51)
print("Server started")
    while true do
        for iaaa=1,141,10 do
        for iaa=1,41,10 do
        local tab = {startx=iaaa,starty=iaa}
        for i=iaaa,maxx+iaaa,1 do
            tab[i-tab.startx+1] = {}
            for ia=iaa,maxy+iaa,1 do
                tab[i-tab.startx+1][ia-tab.starty+1] = gpu.get(i,ia)
            end
        end
        modem.broadcast(199, ser.serialize(tab))
        end
        end
        os.sleep(5)
    end