local modem = component.modem

for i=1,10 do
for ii=1,10 do
  modem.broadcast(199,"{startx="..math.random(1,50)..",starty="..math.random(1,50)..",{'ERROR'}}")
end
end