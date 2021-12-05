for k,v in pairs(component.list()) do
  component[component.proxy(k).type] = component.proxy(k)
end
component.filesystem = rawFs