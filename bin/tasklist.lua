local process = require("process")
local allcputime = 0
local processes = {}
for k,v in ipairs(process.list()) do
    allcputime = allcputime + v.lastCpuTime
    table.insert(processes, v)
end
local mlen = 0
for k,v in ipairs(processes) do
    local lene = v.name:len()
    if lene > mlen then mlen = lene end
end
print("Name"..string.rep(" ", mlen-string.len("Name")).." :: cput :: cpu% :: status :: error")
print("=======================================================")
for k,v in ipairs(processes) do

    print(v.name..string.rep(" ", mlen-string.len(v.name)).." :: "..v.lastCpuTime.." :: "..(v.lastCpuTime > 0 and (((v.lastCpuTime / allcputime) * 100).."%") or "0%").." :: "..v.status.." :: "..(v.error or "none"))
end