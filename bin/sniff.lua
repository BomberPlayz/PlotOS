local event= require("event")
local modem = component.modem

for i=1000,1200 do
    modem.open(i)
    print("opened port "..i)
    if math.random(1,10) > 8 then
        os.sleep(0)
    end
end
while true do
    local _, _, from, port, _, msg = event.pull("modem_message")
    print("Message from "..from.." on port "..port.." with content "..msg)
end