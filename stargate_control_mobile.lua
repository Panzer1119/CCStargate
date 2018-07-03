--[[

  Author: Panzer1119
  
  Date: Edited 03 Jul 2018 - 02:03 AM
  
  Original Source: https://github.com/Panzer1119/CCStargate/blob/master/stargate_control_mobile.lua
  
  Direct Download: https://raw.githubusercontent.com/Panzer1119/CCStargate/master/stargate_control_mobile.lua

]]--

os.loadAPI("lib/security.lua")
x, y = term.getSize() -- Pocket Computers are always x=26 and y=20

serverId = nil
protocol = "stargate"
side = "back"
rednet.open(side)

---- Test START

sg = {
stargateState = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="stargateState", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
energyAvailable = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="energyAvailable", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
energyToDial = function(address)
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="energyToDial", args=address}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
localAddress = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="localAddress", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
remoteAddress = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="remoteAddress", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
dial = function(address)
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="dial", args=address}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
disconnect = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="disconnect", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
irisState = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="irisState", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
closeIris = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="closeIris", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
openIris = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="openIris", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
sendMessage = function(message)
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="sendMessage", args=message}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
loadBookmarks = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="loadBookmarks", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
loadSettings = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="loadSettings", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
loadHistory = function()
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="loadHistory", args=nil}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
saveBookmarks = function(bookmarks)
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="saveBookmarks", args=bookmarks}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
saveSettings = function(settings)
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="saveSettings", args=settings}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end,
saveHistory = function(history)
	if (not isConnected()) then
		return nil
	end
	rednet.send(serverId, {call="saveHistory", args=history}, protocol)
	local sid, msg, ptc = rednet.receive(protocol)
	return msg
end
}

---- Test END

menu_main = "main"
menu_security = "security"
menu_history = "history"
menu_dial = "dial"
menu_gates = "gates"
menu = nil

bookmarks_remote = {}
bookmarks_local = {}
settings_remote = {irisState = "Opened", irisOnIncomingDial = security_none, alarmOutputSides = {}, maxEnergy = 50000}
settings_local = {gate = nil}
history = {incoming = {}, outgoing = {}}
gates_local = {}
gate_remote = nil
index_list = 1
list_active = false

setting_showBookmarksRemote = true
setting_showHistoryIncoming = true

filename_bookmarks = "stargate/bookmarks.lon"
filename_settings = "stargate/settings.lon"
filename_gates = "stargate/gates.lon"

security_allow = "ALLOW"
security_deny = "DENY"
security_none = "NONE"

function isConnected()
	loadSettingsLocal()
	return gate_remote ~= nil and serverId ~= nil
end

-- ########## LOAD BEGIN

function loadBookmarksRemote()
	bookmarks_remote = sg.loadBookmarks()
end

function loadBookmarksLocal()
	if (not fs.exists(filename_bookmarks)) then
		bookmarks_local = {}
		saveBookmarksLocal()
	end
	bookmarks_local = utils.readTableFromFile(filename_bookmarks)
end

function loadHistory()
	history = sg.loadHistory()
end

function loadSettingsRemote()
	settings_remote = sg.loadSettings()
end

function loadSettingsLocal()
	if (not fs.exists(filename_settings)) then
		settings_local = {gate = nil}
		saveSettingsLocal()
	end
	settings_local = utils.readTableFromFile(filename_settings)
	loadGatesLocal()
	gate_remote = getGateById(settings_local.gate)
	serverId = gate_remote and gate_remote.serverId or nil
end

function loadGatesLocal()
	if (not fs.exists(filename_gates)) then
		gates_local = {}
		saveGatesLocal()
	end
	gates_local = utils.readTableFromFile(filename_gates)
end

function loadAll()
	loadBookmarksRemote()
	loadBookmarksLocal()
	loadHistory()
	loadSettingsRemote()
	loadSettingsLocal()
	loadGatesLocal()
end

-- ########## LOAD END
-- ########## SAVE BEGIN

function saveBookmarksRemote()
	sg.saveBookmarks(bookmarks_remote)
end

function saveBookmarksLocal()
	utils.writeTableToFile(filename_bookmarks, bookmarks_local)
end

function saveHistory()
	sg.saveHistory(history)
end

function saveSettingsRemote()
	sg.saveSettings(settings_remote)
end

function saveSettingsLocal()
	utils.writeTableToFile(filename_settings, settings_local)
end

function saveGatesLocal()
	utils.writeTableToFile(filename_gates, gates_local)
end

function saveAll()
	saveBookmarksRemote()
	saveBookmarksLocal()
	saveHistory()
	saveSettingsRemote()
	saveSettingsLocal()
	saveGatesLocal()
end

-- ########## SAVE END

-- Functions for searching an array for a table BEGIN

function getId(entry)
	if (entry ~= nil) then
		return entry.id
	else
		return nil
	end
end

function getName(entry)
	if (entry ~= nil) then
		return entry.name
	else
		return nil
	end
end

function getAddress(entry)
	if (entry ~= nil) then
		return entry.address
	else
		return nil
	end
end

function getAddressShort(entry)
	if (entry ~= nil and string.len(entry.address) >= 7) then
		return string.sub(entry.address, 1, 7)
	else
		return nil
	end
end

-- Functions for searching an array for a table END

function getGateById(id)
	return utils.getTableFromArray(gates_local, id, getId)
end

function getGateByAddress(gates_, address)
	if (string.len(address) == 7) then
		return utils.getTableFromArray(gates_, address, getAddressShort)
	elseif (string.len(address) == 9) then
		local gate = utils.getTableFromArray(gates_, address, getAddress)
		if (gate == nil) then
			gate = utils.getTableFromArray(gates_, string.sub(address, 1, 7), getAddressShort)
		end
		return gate
	end
	return nil
end

function formatRFEnergy(energy)
	local temp = ""
	if (energy < 1000) then
		temp = string.sub(tostring(energy), 1, 5)
	elseif (energy < 1000000) then
		temp = string.sub(tostring(energy / 1000), 1, 5) .. " k"
	elseif (energy < 1000000000) then
		temp = string.sub(tostring(energy / 1000000), 1, 5) .. " M"
	elseif (energy < 1000000000000) then
		temp = string.sub(tostring(energy / 1000000000), 1, 5) .. " G"
	end
	return temp .. "RF"
end

function isHistoryEmpty()
	return (history == nil) or ((history.incoming == nil or #history.incoming == 0) and (history.outgoing == nil or #history.outgoing == 0))
end

timerId = nil

function resetTimer(time_)
	if (time_ == nil or time_ <= 0) then
		time_ = 2
	end
	timerId = os.startTimer(time_)
end

--------- Iris Functions START

function hasIris()
	return sg.irisState() ~= "Offline"
end

function isIrisOpen()
	return sg.irisState() == "Open" 
end

function isIrisClosed()
	return sg.irisState() == "Closed"
end

function isIrisMoving()
	local state = sg.irisState()
	return state == "Opening" or state == "Closing"
end

function toggleIrisOnIncomingDial()
	loadSettingsRemote()
	if (settings_remote.irisOnIncomingDial == security_deny) then
		settings_remote.irisOnIncomingDial = security_allow
	elseif (settings_remote.irisOnIncomingDial == security_allow) then
		settings_remote.irisOnIncomingDial = security_none			
	elseif (settings_remote.irisOnIncomingDial == security_none) then
		settings_remote.irisOnIncomingDial = security_deny
	end
	saveSettingsRemote()
end

function toggleIris()
	while isIrisMoving() do
		sleep(0.25)
	end
	if (isIrisClosed()) then
		sg.openIris()
	elseif (isIrisOpen()) then
		sg.closeIris()
	end
end

--------- Iris Functions END

function drawMenu(menu_, color_back, clear)
	if (clear or menu ~= menu_) then
		term.setBackgroundColor(color_back and color_back or colors.black)
		term.clear()
	end
	if (menu_ == menu_main) then
		drawMainPage()
	elseif (menu_ == menu_security) then
		drawSecurityPage()
	elseif (menu_ == menu_history) then
		drawHistoryPage(index_list)
	elseif (menu_ == menu_dial) then
		drawDialPage()
	elseif (menu_ == menu_gates) then
		drawGatesPage(index_list)
	end
end

function update(color_back, clear)
	drawMenu(menu, color_back, clear)
end

------------------ Main Page START

function drawMainPage(address)
	list_active = false
	index_list = 1
	drawTime()
	drawLocalAddress()
	if (isConnected()) then
		drawPowerBar()
	end
	drawDefenseButton()
	drawIrisButton()
	drawStargate(address)
	drawHistoryButton()
	drawCopyRight()
	drawGatesButton()
	drawDialButton()
	drawTermButton()
	menu = menu_main
end

function drawTime()
	term.setCursorPos(1, 1)
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	local time_f = textutils.formatTime(os.time(), true)
	term.write(string.len(time_f) == 4 and "0" .. time_f or time_f)
end

function drawLocalAddress()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.lightGray)
	term.setCursorPos(x / 2 - 6, 1)
	term.write("Stargate Address")
	term.setCursorPos(x / 2 - 3, 2)
	local address = sg.localAddress()
	term.write(address and address or "Not connected")
	loadSettingsLocal()
	if (gate_remote) then
		term.setCursorPos(1, 2)
		term.write(gate_remote.name)
	end
end

function drawPowerBar()
	loadSettingsRemote()
	local energyAvailable = sg.energyAvailable()
	local energyPercent = (energyAvailable / ((settings_remote.maxEnergy == nil and 50000 or settings_remote.maxEnergy) + 1)) * 100
	for i = y, (y - (y * energyPercent / 100)), -1 do
		if (i > (y * 3 / 4)) then
			term.setBackgroundColor(colors.red)
			term.setTextColor(colors.red)
		elseif (i > (y / 2)) then
			term.setBackgroundColor(colors.orange)
			term.setTextColor(colors.orange)
		elseif (i > (y / 4)) then
			term.setBackgroundColor(colors.green)
			term.setTextColor(colors.green)
		else
			term.setBackgroundColor(colors.lime)
			term.setTextColor(colors.lime)
		end
		term.setCursorPos(x - 1, i)
		term.write("  ")
	end
	term.setBackgroundColor(colors.black)
	term.setCursorPos(x - 11, y)
	term.write(formatRFEnergy(energyAvailable * 80))
end

function drawDefenseButton()
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.black)
	if (not hasIris() or not isConnected()) then
		term.setTextColor(colors.red)
	end
	local s = " DEFENSE "
	local i = 1
	for yc = (y / 3 - 1), (y / 3 * 2 + 1) do
		local c = string.sub(s, i, i)
		term.setCursorPos(2, yc)
		term.write(c)
		i = i + 1
	end
end

function isDefenseButtonPressed(xc, yc)
	return xc == 2 and (yc >= (y / 3 - 2) and yc <= (y / 3 * 2))
end

function drawIrisButton()
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.black)
	if (not hasIris() or not isConnected()) then
		term.setTextColor(colors.red)
	elseif (isIrisClosed()) then
		term.setTextColor(colors.blue)
	end
	local s = "   IRIS  "
	local i = 1
	for yc = (y / 3 - 1), (y / 3 * 2 + 1) do
		local c = string.sub(s, i, i)
		term.setCursorPos(4, yc)
		term.write(c)
		i = i + 1
	end
end

function isIrisButtonPressed(xc, yc)
	return xc == 4 and (yc >= (y / 3 - 2) and yc <= (y / 3 * 2))
end

--------- Stargate START

function drawStargate(address)
	clearRing()
	drawRing()
	drawChevrons(address)
end

function clearRing()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.black)
	for yc = 4, 14 do
		term.setCursorPos(6, yc)
		term.write("                 ")
	end
end

function drawRing()
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.black)
	term.setCursorPos(9, 4) -- top bar
	term.write("           ")
	term.setCursorPos(9, 14) -- bottom bar
	term.write("           ")
	for yc = 6, 12 do
		term.setCursorPos(7, yc) -- left bar
		term.write(" ")
		term.setCursorPos(21, yc) -- right bar
		term.write(" ")
	end
end

function drawChevrons(address)
	if (address == nil) then
		address = ""
	end
	for i = 1, 9 do
		local c = ((address == nil) and nil or string.sub(address, i, i))
		if (c == "") then
			c = nil
		end
		drawChevron(i, c)
	end
end

function drawChevron(i, letter)
	term.setBackgroundColor(colors.gray)
	term.setTextColor(colors.black)
	if (i == 1) then
		if (not letter) then
			letter = ">"
		end
		term.setCursorPos(7, y - 7)
	elseif (i == 2) then
		if (not letter) then
			letter = ">"
		end
		term.setCursorPos(6, y / 2 - 1)
	elseif (i == 3) then
		if (not letter) then
			letter = ">"
		end
		term.setCursorPos(7, 5)
	elseif (i == 4) then
		if (not letter) then
			letter = "V"
		end
		term.setCursorPos(x / 2, 4)
	elseif (i == 5) then
		if (not letter) then
			letter = "<"
		end
		term.setCursorPos(x - 7, 5)
	elseif (i == 6) then
		if (not letter) then
			letter = "<"
		end
		term.setCursorPos(x - 6, y / 2 - 1)
	elseif (i == 7) then
		if (not letter) then
			letter = "<"
		end
		term.setCursorPos(x - 7, y - 7)
	elseif (i == 8) then
		if (not letter) then
			letter = "^"
		end
		term.setCursorPos(x - 11, y - 6)
	elseif (i == 9) then
		if (not letter) then
			letter = "^"
		end
		term.setCursorPos(11, y - 6)
	end
	term.write(" " .. letter .. " ")
end

--------- Stargate END

function drawHistoryButton()
	loadHistory()
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.black)
	if (isHistoryEmpty()) then
		term.setTextColor(colors.red)
	end
	local s = " HISTORY "
	local i = 1
	for yc = (y / 3 - 1), (y / 3 * 2 + 1) do
		local c = string.sub(s, i, i)
		term.setCursorPos(x - 2, yc)
		term.write(c)
		i = i + 1
	end
end

function isHistoryButtonPressed(xc, yc)
	return xc == (x - 2) and (yc >= (y / 3 - 2) and yc <= (y / 3 * 2))
end

function drawCopyRight()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.gray)
	term.setCursorPos(1, y)
	term.write("Panzer1119")
end

function drawGatesButton()
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.black)
	for yc = (y - 4), (y - 2) do
		term.setCursorPos(2, yc)
		term.write("       ")
	end
	term.setTextColor(colors.black)
	term.setCursorPos(3, y - 3)
	term.write("GATES")
end

function isGatesButtonPressed(xc, yc)
	return (xc >= 2 and xc <= 8) and (yc >= (y - 4) and yc <= (y - 2))
end

function drawDialButton()
	local state, engaged, direction = sg.stargateState()
	term.setBackgroundColor(colors.lightGray)
	if (state ~= "Idle") then
		term.setBackgroundColor(colors.gray)
	end
	term.setTextColor(colors.black)
	for yc = (y - 4), (y - 2) do
		term.setCursorPos(x / 2 - 3, yc)
		term.write("      ")
	end
	term.setTextColor(colors.black)
	term.setCursorPos(x / 2 - 2, y - 3)
	term.write("DIAL")
end

function isDialButtonPressed(xc, yc)
	return (xc >= 10 and xc <= 15) and (yc >= (y - 4) and yc <= (y - 2))
end

function drawTermButton()
	local state, engaged, direction = sg.stargateState()
	term.setBackgroundColor(colors.gray)
	if (state == "Connected" or state == "Connecting" or state == "Dialling") then
		term.setBackgroundColor(colors.lightGray)
	end
	term.setTextColor(colors.black)
	for yc = (y - 4), (y - 2) do
		term.setCursorPos(x / 2 + 4, yc)
		term.write("      ")
	end
	term.setTextColor(colors.black)
	term.setCursorPos(x / 2 + 5, y - 3)
	term.write("TERM")
end

function isTermButtonPressed(xc, yc)
	return (xc >= 17 and xc <= 22) and (yc >= (y - 4) and yc <= (y - 2))
end

------------------ Main Page END


------------------ Security Page START

function drawSecurityPage()
	loadSettingsRemote()
	drawBackButton()
	if (settings_remote.irisOnIncomingDial == security_allow) then
		drawExtraButton(security_allow, colors.white, colors.black)
	elseif (settings_remote.irisOnIncomingDial == security_deny) then
		drawExtraButton(security_deny, colors.black, colors.white)
	elseif (settings_remote.irisOnIncomingDial == security_none) then
		drawExtraButton(security_none, colors.gray, colors.white)
	end
	menu = menu_security
end

------------------ Secutiry Page END


------------------ History Page START

function_printHistoryIncoming = function(term, items, i, index_list)
	local address = history.incoming[i + index_list - 1]
	if (not address) then
		return false
	end
	local gate = getGateByAddress(bookmarks_remote, address)
	term.setCursorPos(1, i)
	term.write(address)
	term.setTextColor(colors.black)
	if (gate) then
		term.setCursorPos(math.max(11, x / 3 * 2 - (string.len(gate.name) / 2) - 1), i)
		term.write(gate.name)
	else
		term.setBackgroundColor(colors.blue)
		term.setCursorPos(x - 5, i)
		term.write("SAVE")
	end
	return true
end

function_printHistoryOutgoing = function(term, items, i, index_list)
	local address = history.outgoing[i + index_list - 1]
	if (not address) then
		return false
	end
	local gate = getGateByAddress(bookmarks_remote, address)
	term.setCursorPos(1, i)
	term.write(address)
	if (gate) then
		term.setCursorPos(math.max(11, x / 3 * 2 - (string.len(gate.name) / 2) - 1), i)
		term.write(gate.name)
	end
	return true
end

function drawHistoryPage(index_list_)
	loadHistory()
	loadBookmarksRemote()
	index_list = index_list_ and index_list_ or 1
	if (setting_showHistoryIncoming) then
		drawList(history.incoming, function_printHistoryIncoming)
	else
		drawList(history.outgoing, function_printHistoryOutgoing)
	end
	drawBackButton()
	if (setting_showHistoryIncoming) then
		drawExtraButton("Incoming")
	else
		drawExtraButton("Outgoing")
	end
	menu = menu_history
end

------------------ History Page END


------------------ Dial Page START

function_printBookmark = function(term, items, i, index_list)
	local gate = items[i + index_list - 1]
	if (not gate) then
		term.setCursorPos(x / 2 - 4, i)
		term.write("Add Gate")
		return "nox"
	end
	term.setCursorPos(1, i)
	term.write(gate.address)
	term.setCursorPos(11, i)
	term.write(gate.name)
	return true
end

function drawDialPage(index_list_)
	loadBookmarksRemote()
	loadBookmarksLocal()
	index_list = index_list_ and index_list_ or 1
	if (setting_showBookmarksRemote) then
		drawList(bookmarks_remote, function_printBookmark)
	else
		drawList(bookmarks_local, function_printBookmark)
	end
	drawBackButton()
	if (setting_showBookmarksRemote) then
		drawExtraButton("Remote")
	else
		drawExtraButton("Local")
	end
	menu = menu_dial
end

------------------ Dial Page END

------------------ Gates Page START

function_printGateLocal = function(term, items, i, index_list)
	local gate = items[i + index_list - 1]
	if (not gate) then
		term.setCursorPos(x / 2 - 4, i)
		term.write("Add Gate")
		return "nox"
	end
	term.setCursorPos(1, i)
	term.write(gate.address)
	term.setCursorPos(math.max(11, x / 3 * 2 - (string.len(gate.name) / 2)), i)
	term.write(gate.name)
	return true
end

function drawGatesPage(index_list_)
	loadSettingsLocal()
	index_list = index_list_ and index_list_ or 1
	drawList(gates_local, function_printGateLocal)
	drawBackButton()
	if (gate_remote) then
		drawExtraButton("Disconnect")
	else
		drawExtraButton("")
	end
	menu = menu_gates
end

------------------ Gates Page END

function drawBackButton()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.setCursorPos(1, y - 2)
	term.write("      ")
	term.setCursorPos(1, y - 1)
	term.write(" BACK ")
	term.setCursorPos(1, y)
	term.write("      ")
end

function isBackButtonPressed(xc, yc)
	return xc <= 6 and yc >= (y - 2) and yc <= y
end

function drawExtraButton(extra, color_back, color_text)
	term.setBackgroundColor(color_back and color_back or colors.lightGray)
	term.setTextColor(color_text and color_text or colors.white)
	term.setCursorPos(7, y - 2)
	term.write("                    ")
	term.setCursorPos(7, y - 1)
	term.write("                    ")
	term.setCursorPos(17 - (string.len(extra) / 2 - 1), y - 1)
	term.write(extra)
	term.setCursorPos(7, y)
	term.write("                    ")
end

function isExtraButtonPressed(xc, yc)
	return xc >= 7 and yc >= (y - 2) and yc <= y
end

function drawList(items, function_format)
	for yc = 1, y - 3 do
		if ((yc + index_list - 1) % 2 == 1) then
			term.setBackgroundColor(colors.lightBlue)
		else
			term.setBackgroundColor(colors.lightGray)
		end
		term.setCursorPos(1, yc)
		term.write("                          ")
	end
	for i = 1, 17 do
		if ((i + index_list - 1) % 2 == 1) then
			term.setBackgroundColor(colors.lightBlue)
		else
			term.setBackgroundColor(colors.lightGray)
		end
		term.setTextColor(colors.black)
		local ok = false
		if (function_format) then
			run, ok = pcall(function_format, term, items, i, index_list)
		else
			term.setCursorPos(1, i)
			pcall(term.write, items[i + index_list - 1])
		end
		if (ok and ok ~= "nox") then
			term.setBackgroundColor(colors.red)
			term.setTextColor(colors.black)
			term.setCursorPos(x, i)
			term.write("X")
		end
	end
	list_active = true
end

-- ######### Test
loadAll()
term.clear()
drawMenu(menu_main)
term.setCursorPos(1, y)
resetTimer()
while true do
	local event, param_1, param_2, param_3, param_4, param_5 = os.pullEvent()
	if (event == "timer" and param_1 == timerId) then -- event timer for gui updating was triggered
		update()
		resetTimer()
	elseif (event == "mouse_click" and param_1 == 1) then -- user mouse clicked the terminal
		local connected = isConnected()
		if (list_active and param_3 <= y - 3) then -- when a list is shown via drawList, this if captures all mouse clicks 3 pixels over the bottom line
			if (menu == menu_gates) then
				local gate = gates_local[param_3 + index_list - 1]
				if (gate) then
					if (param_2 == x) then
						loadGatesLocal()
						table.remove(gates_local, utils.getTableIndexFromArray(gates_local, gate.id, getId))
						saveGatesLocal()
						update()
					else
						loadSettingsLocal()
						settings_local.gate = gate.id
						saveSettingsLocal()
						drawMenu(menu_main)
					end
				end
			end
		elseif (menu == menu_main) then
			if (connected and isDefenseButtonPressed(param_2, param_3)) then -- user clicked the defense button
				drawMenu(menu_security, colors.gray)
			elseif (connected and isIrisButtonPressed(param_2, param_3)) then -- user clicked the iris button
				toggleIris()
			elseif (connected and isHistoryButtonPressed(param_2, param_3)) then  -- user clicked the history button
				drawMenu(menu_history, colors.gray)
			elseif (connected and isDialButtonPressed(param_2, param_3) and sg.stargateState() == "Idle") then -- user clicked the dial button
				drawMenu(menu_dial, colors.gray)
			elseif (connected and isTermButtonPressed(param_2, param_3)) then -- user clicked the term button
				sg.disconnect()
				update()
			elseif (isGatesButtonPressed(param_2, param_3)) then -- user clicked the gates button
				drawMenu(menu_gates, colors.gray)
			end
		elseif (isExtraButtonPressed(param_2, param_3)) then -- user clicked on the extra button (besides the back button)
			if (menu == menu_security) then
				toggleIrisOnIncomingDial()
				update()
			elseif (menu == menu_history) then
				setting_showHistoryIncoming = not setting_showHistoryIncoming
				index_list = 1
				update()
			elseif (menu == menu_dial) then
				setting_showBookmarksRemote = not setting_showBookmarksRemote
				index_list = 1
				update()
			elseif (connected and menu == menu_gates) then
				loadSettingsLocal()
				settings_local.gate = nil
				saveSettingsLocal()
				drawMenu(menu_main)
			end
		elseif (isBackButtonPressed(param_2, param_3)) then -- user clicked the back button
			drawMenu(menu_main)
		end
		resetTimer()
	elseif (event == "mouse_scroll") then
		if (list_active and param_3 <= y - 3) then -- when a list is shown via drawList, this if captures all mouse scrolls 3 pixels over the bottom line
			if (menu == menu_gates) then
				drawGatesPage(math.max(1, index_list + param_1))
			elseif (menu == menu_history) then
				drawHistoryPage(math.max(1, index_list + param_1))
			end
		end
	end
end