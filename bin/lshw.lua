for k,v in pairs(computer.getDeviceInfo()) do
    print("============================================================")
    print("Product:     "..v.product)
    print("Vendor:      "..v.vendor)
    print("Description: "..v.description)
    print("============================================================")
end