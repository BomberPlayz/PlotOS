local args = ({...})[1]

table.remove(args, 1)

bsod(#args > 0 and table.concat(args, " ") or "Debug BSOD")