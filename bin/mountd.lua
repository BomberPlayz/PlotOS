local kernel = require("kernel")
local fs = require("fs")

printk("Mounting daemon started")

if not fs.isDirectory("/mnt") then
    printk("Mounting daemon is creating /mnt directory")
    fs.makeDirectory("/mnt")
end

-- find all not yet mounted filesystems and mount them
for comp in component.list("filesystem") do
    printk("Mounting daemon is checking filesystem " .. comp)
    local drived = require("driver").load("drive", comp)
    if drived then
        local addr = string.sub(comp, 1, 3)
        printk("Mounting filesystem " .. comp .. " at " .. addr)
        fs.mount(drived, "/mnt/" .. addr)
        printk("Mounted filesystem " .. comp .. " at " .. addr)
    end
end

while true do
    local event, rid, type = require("event").pull()
    if event == "component_added" then
        if type == "filesystem" then
            printk("Mount Daemon is mounting filesystem with ID " .. rid)
            local drived = require("driver").load("drive", rid)
            local mount_point = fs.mount(drived, "/mnt/" .. string.sub(rid, 1, 3))
            if mount_point then
                printk("Mount Daemon has mounted filesystem with ID " .. rid .. " at " .. mount_point)
            else
                printk("Mount Daemon failed to mount filesystem with ID " .. rid)
            end
        end
    end
    if event == "component_removed" then
        printk("Mount Daemon is unmounting filesystem with ID " .. rid)
        fs.unmount("/mnt/" .. string.sub(rid, 1, 3))
        printk("Mount Daemon has unmounted filesystem with ID " .. rid)
    end
end
