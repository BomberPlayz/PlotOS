local ramfs = package.require("ramfs")
local stream = package.require("fakeStream")
local fs = package.require("fs")

local devfs = ramfs.new()

devfs:addFile("test", {
    buffer = stream.new({
        onRead = function(self, n)
            return "Hello, world!"
        end,
        onWrite = function(self, data)
            printk("Writing to test file:", data)
        end
    })
})

fs.mount(devfs:getfakefs(), "/dev")
