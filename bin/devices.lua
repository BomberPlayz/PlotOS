for k,v in pairs(computer.getDeviceInfo()) do
    local device = computer.getDeviceInfo()[k]
    print("============================================================")
    print("Product: "..device.product)
    print("Vendor: "..device.vendor)
    print("description: "..device.description)
    print("============================================================")
    print("")
    os.sleep(1)
end