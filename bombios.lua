local gpu = component.proxy(component.list("gpu")())
--local screen = component.proxy()
local eeprom = component.proxy(component.list("eeprom")())
local setfg = gpu.setForeground
local setbg = gpu.setBackground
local gray = 0xaaaaaa

gpu.bind(component.list("screen")(), true)

gpu.setResolution(80,25)
local w,h = gpu.getResolution()

--error(tostring(w)..","..tostring(h))

local savedata = {}

local d = eeprom.getData()

function encode(tab)
	local out = ""
	for k,v in ipairs(tab) do
		out = out ..(type(v) == "boolean" and  string.char(1) or string.char(#v))..v
	end
	return out
end

function decode(data)
	local out = {}
	local ptr = 1
	while ptr <= #data do
		local len = string.byte(data, ptr)
		ptr = ptr + 1
		out[#out+1] = string.sub(data, ptr, ptr+len-1)
		ptr = ptr + len
	end
	return out
end





function centerText(y, text)
	local x = math.floor((w - #text) / 2)
    gpu.set(x, y, text)
end


setbg(0x00aaaa)
setfg(0)
gpu.fill(1, 1, w, 1, " ")

centerText(1, "BomBIOS Setup Utility")
centerText(25/2, "Loading save data...")

if d then
	savedata = decode(d)
end

local function drawTab(x,y, w, text, sel)
	if sel then
		setbg(gray)
		setfg(0x0000aa)
	else
		setbg(0x0000aa)
		setfg(gray)
	end
	gpu.fill(x, y, w, 1, " ")
	gpu.set(x, y, text)
end

local function drawBorders(x,y,w,h)
	setbg(gray)
	setfg(0)
	-- top
	gpu.set(x, y, string.rep("─", w))
	-- bottom
	gpu.set(x, y+h-1, string.rep("─", w))
	-- left
	for i=y,y+h-1 do
		gpu.fill(x, i, 1, 1, "│")
	end
	-- right
	for i=y,y+h-1 do
		gpu.fill(x+w-1, i, 1, 1, "│")
	end
	-- corners
	gpu.set(x, y, "┌")
	gpu.set(x+w-1, y, "┐")
	gpu.set(x, y+h-1, "└")
	gpu.set(x+w-1, y+h-1, "┘")

end

local tabs = {
	"Main",
	"Advanced",
	"Security",
	"Boot",
	"Info",
	"Exit"
}

local tabcontent = {}

tabcontent = {
	["Main"]={
		{
			["type"]="bool",
			["name"]="Beep on error",
			["value"]=true,
			["desc"]="Beep when an error occurs"
		},
	},

		["Advanced"]={
		{
			["type"]="bool",
			["name"]="Beep on error",
			["value"]=true,
			["desc"]="Beep when an error occurs"
		},
	},

	["Security"]={
		{
			["type"]="bool",
			["name"]="Beep on error",
			["value"]=true,
			["desc"]="Beep when an error occurs"
		},
	},

	["Boot"]={
		{
			["type"]="list",
			["name"]="Boot order",
			["sel"]=1,
			["desc"]="Select the boot order. Use +/- to change the order.",
			["options"]={
				"Hard Disk",
				"Removable Devices",
				"CD-ROM Drive",
				"Network"
			}
		},
	},

	["Info"]={
		{
			["type"]="bool",
			["name"]="Beep on error",
			["value"]=true,
			["desc"]="Beep when an error occurs"
		},
	},

	["Exit"]={
		{
			["type"]="custom",
			["name"]="Save and exit",
			["desc"]="Save and exit",
			["interact"]=function()
				local savedata = {}
				-- key-value pairs
				for k,v in pairs(tabcontent) do
					for j=1,#tabcontent[k] do
						local item = tabcontent[k][j]
						if item.type == "bool" then
							table.insert(savedata, item.value)
						elseif item.type == "list" then
							local val = item.options
							local valdata = ""
							for k=1,#val do
								valdata = valdata..string.char(#val[k])..val[k]
							end
							table.insert(savedata, valdata)
						end
					end
				end
				eeprom.setData(encode(savedata))
				eeprom.setLabel("BomBIOS ("..#savedata.." bytes saved)")
			end
		}
	}}

local selectedTab = 1
local selectedItem = 1

-- load data from savedata
local i = 1
for k,v in ipairs(tabcontent) do
	for j=1,#v do
		local item = v[j]
		if item.type == "bool" then
			item.value = savedata[i]
		elseif item.type == "list" then
			local valdata = savedata[i]
			local val = {}
			local ptr = 1
			while ptr <= #valdata do
				local len = string.byte(valdata, ptr)
				ptr = ptr + 1
				val[#val+1] = string.sub(valdata, ptr, ptr+len-1)
				ptr = ptr + len
			end
			item.sel = 1
			for k=1,#item.options do
				if item.options[k] == val then
					item.sel = k
					break
				end
			end
		end
		i = i + 1
	end
end

function drawTabs()
	local xx = 1
	setbg(0x0000aa)
	setfg(gray)
	gpu.fill(1, 2, w, 1, " ")
	for i=1,#tabs do
		drawTab(xx+2, 2, #tabs[i]+2, " "..tabs[i], i == selectedTab)
		xx = xx + #tabs[i] + 4
	end
end

function drawTabContent()
	setbg(gray)
	setfg(0)
	gpu.fill(1, 3, w, h-2, " ")

	drawBorders(1, 3, w, h-4)
	-- item specific help
	gpu.fill(53, 3, 1, h-4, "┃")
	gpu.set(53, 3, "┰")
	gpu.set(53, h-2, "┸")

	gpu.set(53, 5, string.rep("─", w-53))
	gpu.set(53, 5, "┠")
	gpu.set(w, 5, "┤")

	gpu.set(58, 4, "Item Specific Help")
end

function drawItemHelp(txt)
	-- we need to limit the text to 25 chars per line
	setbg(gray)
	setfg(0)
	local lines = {}
	local ptr = 1
	while ptr <= #txt do
		local line = txt:sub(ptr, ptr+25)
		table.insert(lines, line)
		ptr = ptr + 26
	end
	for i=1, #lines do
		gpu.set(54, 6+i, lines[i])
	end
end

function getVal(item)
	if item.type == "bool" then
		return item.value and "Enabled" or "Disabled"
	elseif item.type == "int" then
		return tostring(item.value)..(item.unit or "")
	elseif item.type == "string" then
		return item.value
	end
end

function interactItem()
	local item = tabcontent[tabs[selectedTab]][selectedItem]
	if item.type == "bool" then
		item.value = not item.value
	elseif item.type == "int" then
		local val = tonumber(item.value)
		if val then
			val = val + 1
			if val > item.max then
				val = item.min
			end
			item.value = val
		end
	elseif item.type == "string" then
		local val = item.value
		local ptr = 1
		while ptr <= #val do
			local c = val:sub(ptr, ptr)
			if c == " " then
				c = "_"
			end
			val = val:sub(1, ptr-1)..c..val:sub(ptr+1)
			ptr = ptr + 1
		end
		item.value = val
	elseif item.type == "custom" then
		item.interact()
	end

end

function drawTabItems()
	-- refill the tab content area and the item help area
	setbg(gray)
	setfg(0)
	gpu.fill(2, 4, 51, h-6, " ")
	gpu.fill(54, 6, w-54, h-8, " ")

	-- draw the items
	local xx = 3
	local yy = 4

	local maxw = 0
	for i=1,#tabcontent[tabs[selectedTab]] do
		local item = tabcontent[tabs[selectedTab]][i]
		maxw = math.max(maxw, #item.name)
	end
	maxw = maxw+2

	for i=1,#tabcontent[tabs[selectedTab]] do
		local item = tabcontent[tabs[selectedTab]][i]
		if i == selectedItem and item.type ~= "list" then

			setbg(gray)
			setfg(0xffffff)

		else
			setbg(gray)
			setfg(0x0000aa)
		end
		if i == selectedItem then drawItemHelp(item.desc) end
		-- gpu.set is faster than gpu.fill
		gpu.set(xx, yy, string.rep(" ", 50))
		gpu.set(xx, yy, item.name)
		if getVal(item) then
			setfg(0x000000)
			gpu.set(xx+maxw, yy, "["..string.rep(" ", #getVal(item)).."]")
			if i == selectedItem then
				setbg(0x000000)
				setfg(gray)
			end
			gpu.set(xx+maxw+1, yy, getVal(item))
		end

		-- display the items in a list
		if item.type == "list" then
			yy = yy + 1
			local list = item.options
			for j=1,#list do
				if j == item.sel then
					setfg(0xffffff)
				else
					setfg(0x0000aa)
				end
				gpu.set(xx+2, yy, string.rep(" ", 48))
				gpu.set(xx+2, yy, list[j])
				yy = yy + 1
			end
		end


		yy = yy + 1
	end
end


drawTabs()
drawTabContent()
drawTabItems()
while true do



	-- draw the main content
	-- first, draw the borders


	local e = {computer.pullSignal()}
	if e[1] == "key_down" then
		if e[4] == 203 then
			selectedTab = math.max(1, selectedTab - 1)
			selectedItem = 1
			drawTabs()
			drawTabContent()
			drawTabItems()
		elseif e[4] == 205 then
			selectedTab = math.min(#tabs, selectedTab + 1)
			selectedItem = 1
			drawTabs()
			drawTabContent()
			drawTabItems()
		elseif e[4] == 200 then
			if tabcontent[tabs[selectedTab]][selectedItem].type == "list" then
				local item = tabcontent[tabs[selectedTab]][selectedItem]
				item.sel = item.sel - 1
				if item.sel < 1 then
					item.sel = #item.options
				end
			else
				selectedItem = math.max(1, selectedItem - 1)
			end

			drawTabItems()
		elseif e[4] == 208 then
			if tabcontent[tabs[selectedTab]][selectedItem].type == "list" then
				local item = tabcontent[tabs[selectedTab]][selectedItem]
				item.sel = item.sel + 1
				if item.sel > #item.options then
					item.sel = 1
				end
			else
				selectedItem = math.min(#tabcontent[tabs[selectedTab]], selectedItem + 1)
			end


			drawTabItems()
		elseif e[4] == 28 then
			interactItem()
			drawTabItems()
		-- + and - keys, and space
		elseif e[4] == 13 or e[4] == 12 or e[4] == 57 then
			local item = tabcontent[tabs[selectedTab]][selectedItem]
			if item.type == "list" then
				-- move the selected item up
				local sel = item.sel
				local tmp = item.options[sel]
				if sel > 1 then
					item.options[sel] = item.options[sel-1]
					item.options[sel-1] = tmp
					item.sel = sel - 1
				end

			end
			drawTabItems()
		elseif e[4] == 12 then
			local item = tabcontent[tabs[selectedTab]][selectedItem]
			if item.type == "list" then
				-- move the selected item down
				local sel = item.sel
				local tmp = item.options[sel]
				if sel < #item.options then
					item.options[sel] = item.options[sel+1]
					item.options[sel+1] = tmp
					item.sel = sel + 1
				end

			end
			drawTabItems()
		end
	end
end