local net = require("internet")
for line in io.lines("/ver") do
 if not line == net.request("https://raw.githubusercontent.com/BomberPlayz/PlotOS/master/ver") then
  print("It is recommanded to update PlotOS from "..io.lines("/ver")[1].." to "..net.request("https://raw.githubusercontent.com/BomberPlayz/PlotOS/master/ver"))
 end
end
