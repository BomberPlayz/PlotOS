local net = require("internet")

for line in io.lines("/ver") do
 if not line == net.request("https://raw.githubusercontent.com/BomberPlayz/PlotOS/master/ver") then
  shell.execute("/home/posinst")
 end
end
