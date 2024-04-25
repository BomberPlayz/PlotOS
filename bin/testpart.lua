local libpart = require("libpart")
local driver = require("driver")

print("We are gonna try to format any disk now.")
local disk = driver.load("rdrive")
if not disk then
    print("No disk driver found!")
    return
end

local parted = libpart.getProxy(disk)
if not parted then
    print("No partitioning support found!")
    return
end
parted.formatPartitioned()
local meta = parted.getMetadata()
print("Partition magic: " .. meta.magic .. " with version " .. meta.version .. " and " .. meta.partcount .. " partitions")
for k, v in pairs(meta.partitions) do
    print("Partition " .. k .. " at " .. v.start .. " with size " .. v.size)
end

print("And now we'll create a partition named root with a size of 100")
print("")

parted.createPartition("root", 100)
local meta = parted.getMetadata()
print("Partition magic: " .. meta.magic .. " with version " .. meta.version .. " and " .. meta.partcount .. " partitions")
for k, v in pairs(meta.partitions) do
    print("Partition " .. k .. " at " .. v.start .. " with size " .. v.size)
end

print("Now, we will make another partition, called windows, with a size of 400")
print("")
parted.createPartition("windows", 400)
local meta = parted.getMetadata()
print("Partition magic: " ..
    meta.magic .. " with version " .. meta.version .. " and " .. meta.partcount .. " partitions")
for k, v in pairs(meta.partitions) do
    print("Partition " .. k .. " at " .. v.start .. " with size " .. v.size)
end
