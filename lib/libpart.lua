-- libpart is a library that provides partitioning system for unmanaged disks.

local libpart = {}

---@param disk table
function libpart.getProxy(disk)
    local p = {}
    --- Checks if the disk is partitioned
    function p.isPartitioned()
        -- if readsector is defined and the first sector's magic data is "POSPART"
        return disk.readSector and string.unpack("<c7", disk.readSector(2)) == "POSPART"
    end

    function p.getMetadata()
        if not p.isPartitioned() then
            return nil
        end
        local meta = disk.readSector(2)
        --print(meta)
        -- unpack
        local magic, version, partcount = string.unpack("<c7HH", meta)
        printk("Partition magic: " .. magic .. " with version " .. version .. " and " .. partcount .. " partitions")
        if magic ~= "POSPART" then
            return nil
        end
        local partitions = {}
        for i = 1, partcount do
            local partname, partstart, partsize = string.unpack("<c20I4I4", meta, 12 + (i - 1) * 28)
            partname = partname:sub(1, partname:find("\0") - 1)
            printk("Partition " .. i .. ": " .. partname .. " at " .. partstart .. " with size " .. partsize)
            partitions[partname] = { start = partstart, size = partsize, name = partname }
        end

        return { magic = magic, version = version, partcount = partcount, partitions = partitions }
    end

    --[[function p.formatPartitioned()
        -- just write some test data for now
        local data = string.pack("<c7HHc20I4I4", "POSPART", 1, 1, "root\0", 3, 100)
        disk.writeSector(2, data)
        end]]

    function p.formatPartitioned()
        -- write the magic data and the requried datat
        -- magic, version, partcount. Partcount will be 0 for now
        local nulls = string.rep("\0", 512)
        disk.writeSector(1, nulls)
        local data = string.pack("<c7HH", "POSPART", 1, 0)
        disk.writeSector(2, data)
    end

    function p.createPartition(name, size)
        local meta = p.getMetadata()
        if not meta then
            return false
        end
        local partcount = meta.partcount + 1
        local start = 0
        local nospace = false
        -- find any gap that fits the size
        for k, v in pairs(meta.partitions) do
            -- we also need to consider the size of the partition
            if v.start - start >= size then
                break
            end
            start = v.start + v.size
            if start + size > disk.getCapacity() then
                nospace = true
                break
            end
        end
        if nospace then
            return false
        end
        -- write the partition data
        local data = string.pack("<c20I4I4", name, start, size)
        --print("packsize: " .. string.packsize("<c20I4I4"))
        local writepos = 12 + (partcount - 1) * 28

        local sector = disk.readSector(2)
        sector = sector:sub(1, writepos - 1) .. data .. sector:sub(writepos + 28)
        -- partition count
        sector = sector:sub(1, 9) .. string.pack("<H", partcount) .. sector:sub(12)
        --printk(sector)
        disk.writeSector(2, sector)
    end

    function p.openPartition(name)
        local meta = p.getMetadata()
        if not meta then
            return nil
        end
        local part = meta.partitions[name]
        if not part then
            return nil
        end
        return {
            readSector = function(sector)
                if sector < 1 or sector * disk.getSectorSize() > part.size then
                    return nil
                end
                return disk.readSector(part.start + sector)
            end,
            writeSector = function(sector, data)
                if sector < 1 or sector * disk.getSectorSize() > part.size then
                    return false
                end
                return disk.writeSector(part.start + sector, data)
            end,
        }
    end

    return p
end

return libpart
