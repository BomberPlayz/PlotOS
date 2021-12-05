local fs = require("fs")
for k,v in fs.list(os.currentDirectory) do
  print(k)
end