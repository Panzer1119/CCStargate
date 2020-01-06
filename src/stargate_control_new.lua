--[[

  Author: Panzer1119
  
  Date: Edited 05 Jan 2020 - 03:02 PM
  
  Original Source: https://github.com/Panzer1119/CCStargate/blob/master/stargate_control_new.lua
  
  Direct Download: https://raw.githubusercontent.com/Panzer1119/CCStargate/master/stargate_control_new.lua

]]--

os.loadAPI("lib/utils.lua")

PROGRAM_NAME = "Stargate Control"
PROGRAM_NAME_SHORT = "SG Control"

sg = peripheral.find("stargate")
mon = peripheral.find("monitor")

MON_WIDTH = 50
MON_HEIGHT = 19
--MON_HEIGHT = 26 -- REMOVE

width, height = mon.getSize()

remoteAddress = ""
remoteAddressColor = colors.black
remoteIrisOpen = nil
firstTimeGate = true

function clear(x, y, color_back)
	mon.setBackgroundColor(color_back and color_back or colors.black)
	mon.clear()
	mon.setCursorPos(x, y)
end

if (width ~= MON_WIDTH) then
	clear(1, 1)
	mon.write("Monitor size does not match the requirements! (width is " .. width .. ", but should be " .. MON_WIDTH .. ")")
	error("Monitor size does not match the requirements! (width is " .. width .. ", but should be " .. MON_WIDTH .. ")")
end
if (height ~= MON_HEIGHT) then
	clear(1, 1)
	mon.write("Monitor size does not match the requirements! (height is " .. height .. ", but should be " .. MON_HEIGHT .. ")")
	error("Monitor size does not match the requirements! (height is " .. height .. ", but should be " .. MON_HEIGHT .. ")")
end

menu_main = "main"
menu_security = "security"
menu_history = "history"
menu_dial = "dial"
menu = nil

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

-- Misc BEGIN

function getStargateByAddress(stargates_, address)
	return utils.getTableFromArray(stargates_, address, getAddress)
	--[[ -- REMOVE
	if (string.len(address) == 7) then
		return utils.getTableFromArray(stargates_, address, getAddressShort)
	else
		local stargate = utils.getTableFromArray(stargates_, address, getAddress)
		if (not stargate) then
			stargate = utils.getTableFromArray(stargates_, string.sub(address, 1, 7), getAddressShort)
		end
		return stargate
	end
	]]--
end

function formatRFEnergy(energy)
	local temp = ""
	if (energy < 1000) then
		temp = string.sub(tostring(energy), 1, 5) .. " "
	elseif (energy < 1000000) then
		temp = string.sub(tostring(energy / 1000), 1, 5) .. " k"
	elseif (energy < 1000000000) then
		temp = string.sub(tostring(energy / 1000000), 1, 5) .. " M"
	elseif (energy < 1000000000000) then
		temp = string.sub(tostring(energy / 1000000000), 1, 5) .. " G"
	end
	return temp .. "RF"
end

function formatAddressToHiphons(address)
	if (address == nil) then
		return "Not connected"
	end
	local temp = string.sub(address, 1, 4) .. "-" .. string.sub(address, 5, 7)
	if (string.len(address) == 9) then
		temp = temp .. "-" .. string.sub(address, 8, 9)
	else
		temp = temp .. "   "
	end
	return temp
end

function isHistoryEmpty()
	return not history or #history == 0
end

timerId = nil

function resetTimer(time_)
	if (not time_ or time_ <= 0) then
		time_ = 4
	end
	timerId = os.startTimer(time_)
end

-- Misc END

-- ## STATIC VALUES BEGIN

security_allow = "ALLOW"
security_deny = "DENY"
security_none = "NONE"

security_locked = "LOCKED"
security_diable = "DIABLE"

settings = {maxEnergy = 51000, twentyFourHour = true, dateInDays = true, keepOpen = false, irisOnIncomingDial = security_none, history_distinct = false}
currentPages = {dialPage = 1, securityPage = 1, historyPageMode1 = 1, historyPageMode2 = 1}
stargates = {}
history = {}

folder_stargate = "stargate"
file_settings = folder_stargate .. "/settings.lon"
file_stargates = folder_stargate .. "/stargates.lon"
file_history = folder_stargate .. "/history.lon"

security_color_allow = colors.white
security_color_text_allow = colors.black
security_color_deny = colors.black
security_color_text_deny = colors.white
security_color_none = colors.gray
security_color_text_none = colors.white

security_color_locked = colors.gray
security_color_text_locked = colors.red
security_color_diable = colors.gray
security_color_text_diable = colors.black

iris_state_offline = "Offline"
iris_state_closed = "Closed"
iris_state_open = "Open"
iris_state_opening = "Opening"
iris_state_closing = "Closing"

stargate_state_connected = "Connected"
stargate_state_connecting = "Connecting"
stargate_state_dialling = "Dialling"
stargate_state_closing = "Closing"
stargate_state_idle = "Idle"

dial_button_standard = "DIAL"
dial_button_keep = "KEEP"
dial_button_hold = "HOLD"

history_distinct = "DISTINCT"
history_normal = "NORMAL"

term_button_standard = "TERM"

ring_width = 19
ring_height = 11

list_offset = 1
entries_per_page = 15

average_days_per_year = 365.25
last_date_length = 0
last_time_length = 0

button_add_address = "Add Address"
button_back = "BACK"
button_block = "BLOCK"
button_save = "SAVE"

event_rednet_message = "rednet_message"
event_timer = "timer"
event_monitor_touch = "monitor_touch"
event_sgDialIn = "sgDialIn"
event_sgDialOut = "sgDialOut"
event_sgMessageReceived = "sgMessageReceived"
event_sgIrisStateChange = "sgIrisStateChange"
event_sgStargateStateChange = "sgStargateStateChange"
event_sgChevronEngaged = "sgChevronEngaged"

message_remoteIrisState = "remoteIrisState"

-- ## STATIC VALUES END

-- ###### UTIL BEGIN

-- Page Infos BEGIN

function getMaxPage(array)
	return math.ceil(#array / entries_per_page)
end

function getOrCorrectPage(array, page)
	return math.min(page, getMaxPage(array))
end

function getPageInfos(array, page)
	local page_ = getOrCorrectPage(array, page)
	local pageMax_ = getMaxPage(array)
	local offset_ = (page_ - 1) * entries_per_page
	local maxOnPage_ = math.min(#array, page_ * entries_per_page)
	return page_, pageMax_, offset_, maxOnPage_
end

function getStargatePageInfos(page)
	return getPageInfos(stargates, page)
end

function getDiableStargatePageInfos(page)
	local page_, pageMax_, offset_, maxOnPage_ = getPageInfos(stargates, page)
	local temp = 0
	for i, n in ipairs(stargates) do
		if (not n.locked) then
			temp = temp + 1
		end
	end
	if (maxOnPage_ > temp) then
		maxOnPage_ = temp
	end
	return page_, pageMax_, offset_, maxOnPage_
end

-- TODO Create "get...PageInfos" functions for the security list and both the history lists

-- Page Infos END

-- ###### UTIL END

-- ###### LOAD BEGIN

function loadSettings()
	if (not fs.exists(file_settings)) then
		settings = {maxEnergy = 51000, twentyFourHour = true, dateInDays = true, keepOpen = false, irisOnIncomingDial = security_none, history_distinct = false}
		saveSettings()
	end
	settings = utils.readTableFromFile(file_settings)
end

function loadStargates()
	if (not fs.exists(file_stargates)) then
		stargates = {}
		saveStargates()
	end
	stargates = utils.readTableFromFile(file_stargates)
end

function loadHistory()
	if (not fs.exists(file_history)) then
		history = {}
		saveHistory()
	end
	history = utils.readTableFromFile(file_history)
end

function loadAll()
	loadSettings()
	loadStargates()
	loadHistory()
end

-- ###### LOAD END

-- ###### SAVE BEGIN

function saveSettings()
	utils.writeTableToFile(file_settings, settings)
end

function saveStargates()
	utils.writeTableToFile(file_stargates, stargates)
end

function saveHistory()
	utils.writeTableToFile(file_history, history)
end

function saveAll()
	saveSettings()
	saveStargates()
	saveHistory()
end

-- ###### SAVE END

-- ### Iris Functions BEGIN

function hasIris()
	return sg.irisState() ~= iris_state_offline
end

function isIrisOpen()
	return sg.irisState() == iris_state_open
end

function isIrisClosed()
	return sg.irisState() == iris_state_closed
end

function isIrisMoving()
	local state = sg.irisState()
	return state == iris_state_opening or state == iris_state_closing
end

-- TODO toggleIrisOnIncomingDial?

function toggleIris()
	if (not hasIris()) then
		return
	end
	while (isIrisMoving()) do
		sleep(0.25)
	end
	if (isIrisClosed()) then
		sg.openIris()
	elseif (isIrisOpen()) then
		sg.closeIris()
	end
end

-- ### Iris Functions END

function drawMenu(menu_to_draw, clear_, color_back)
	if (clear_ or menu ~= menu_to_draw) then
		clear(1, 1, color_back)
	end
	menu = menu_to_draw
	if (menu_to_draw == menu_main) then
		drawMainMenu()
	elseif (menu_to_draw == menu_security) then
		drawSecurityMenu()
	elseif (menu_to_draw == menu_history) then
		drawHistoryMenu()
	elseif (menu_to_draw == menu_dial) then
		drawDialMenu()
	end
end

function repaintMenu(clear_, color_back)
	drawMenu(menu, clear_, color_back)
end


-- #### Header BEGIN

function drawHeader(full, color_back, color_text)
	if (full == nil) then
		full = menu == menu_main
	end
	color_back = color_back and color_back or colors.black
	color_text = color_text and color_text or colors.white
	mon.setBackgroundColor(color_back)
	mon.setTextColor(color_text)
	--[[
	for x_ = 1, width do
		mon.setCursorPos(x_, 1)
		mon.write(" ")
	end
	]]--
	drawDate()
	drawTime(full and 5 or 0)
	drawLocalAddress(full)
end

function getFormattedDate()
	if (settings.dateInDays) then
		local day = os.day()
		return "Year " .. math.floor(day / average_days_per_year) .. ", Day " .. (day % average_days_per_year)
	else
		return "Day " .. os.day()
	end
end

function getFormattedTime()
	local time_formatted = textutils.formatTime(os.time(), settings.twentyFourHour and settings.twentyFourHour or false)
	if (string.sub(time_formatted, 3, 3) ~= ":") then
		time_formatted = "0" .. time_formatted
	end
	return time_formatted
end

function drawDate()
	mon.setCursorPos(1, 1)
	local date_ = getFormattedDate()
	last_date_length = string.len(date_)
	mon.write(date_)
end

function drawTime(offset_right)
	if (not offset_right) then
		offset_right = 0
	end
	local time_formatted = getFormattedTime()
	last_time_length = string.len(time_formatted) + 1 - offset_right
	mon.setCursorPos(width - last_time_length, 1)
	mon.write(time_formatted)
end

function isDatePressed(x_, y_)
	return (x_ >= 1 and x_ <= last_date_length) and (y_ == 1)
end

function isTimePressed(x_, y_) -- TODO Test the last_time_length thing
	if (menu == menu_main) then
		return (x_ >= width - 6 - last_time_length and x_ <= width - 6) and (y_ == 1)
	else
		return (x_ >= width - last_time_length and x_ <= width) and (y_ == 1)
	end
	--[[
	if (menu == menu_main) then
		return (x_ >= width - 6 - (settings.twentyFourHour and 5 or 8) and x_ <= width - 6) and (y_ == 1)
	else
		return (x_ >= width - (settings.twentyFourHour and 5 or 8) and x_ <= width) and (y_ == 1)
	end
	]]--
end

function toggleDateFormat()
	loadSettings()
	if (settings.dateInDays == nil) then
		settings.dateInDays = true
	else
		settings.dateInDays = not settings.dateInDays
		mon.setBackgroundColor(colors.black)
		mon.setCursorPos(1, 1)
		for i = 1, last_date_length do
			mon.write(" ")
		end
	end
	saveSettings()
	drawHeader()
end

function toggleTimeFormat()
	loadSettings()
	if (settings.twentyFourHour == nil) then
		settings.twentyFourHour = true
	else
		if (settings.twentyFourHour) then
			settings.twentyFourHour = false
		else
			mon.setBackgroundColor(colors.black)
			mon.setCursorPos(width - 8 + 1 - (menu == menu_main and 5 or 0), 1)
			mon.write("   ")
			settings.twentyFourHour = true
		end
	end
	saveSettings()
	drawHeader()
end

function drawLocalAddress(full)
	mon.setTextColor(colors.lightGray)
	full = full and full or menu == menu_main
	local address_local_formatted = formatAddressToHiphons(sg.localAddress())
	local y = 1
	if (full) then
		local temp = "Stargate Address:"
		mon.setCursorPos((width - string.len(temp)) / 2 + 1, y)
		mon.write(temp)
		y = y + 1
	end
	mon.setCursorPos((width - string.len(address_local_formatted)) / 2 + 1, y)
	mon.write(address_local_formatted)
end

-- #### Header END

-- #### Credits BEGIN

function drawCredits()
	mon.setCursorPos(1, height)
	mon.setBackgroundColor(colors.black)
	mon.setTextColor(colors.gray)
	mon.write("©Panzer1119")
end

-- #### Credits END

-- #### Main Menu BEGIN

function drawMainMenu()
	drawHeader()
	drawCredits()
	drawPowerBar()
	drawDefenseButton()
	drawIrisButton()
	drawStargate(remoteAddress)
	drawHistoryButton()
	drawDialButton()
	drawTermButton()
	if (firstTimeGate) then
		firstTimeGate = false
		local state, engaged, direction = sg.stargateState()
		remoteAddress = sg.remoteAddress()
		if (state == stargate_state_connected) then
			remoteAddressColor = colors.lightBlue
			drawChevrons(remoteAddress)
		elseif (state == stargate_state_dialling) then
			remoteAddressColor = colors.orange
			drawChevrons(string.sub(remoteAddress, 1, engaged))
		elseif (state == stargate_state_connecting) then
			remoteAddressColor = colors.green
			drawChevrons(string.sub(remoteAddress, 1, engaged))
		end
	end
end

function drawPowerBar()
	local energyAvailable = sg.energyAvailable()
	local energyPercent = (energyAvailable / ((settings.maxEnergy and settings.maxEnergy or 50000) + 1))
	local y_m = (height - (height * energyPercent))
	for i = height, y_m, -1 do
		mon.setBackgroundColor(colors.black)
		mon.setTextColor(colors.black)
		mon.setCursorPos(width - 3, i)
		mon.write("    ")
		if (i > (height * 3 / 4)) then
			mon.setBackgroundColor(colors.red)
			mon.setTextColor(colors.red)
		elseif (i > (height / 2)) then
			mon.setBackgroundColor(colors.orange)
			mon.setTextColor(colors.orange)
		elseif (i > (height / 4)) then
			mon.setBackgroundColor(colors.green)
			mon.setTextColor(colors.green)
		else
			mon.setBackgroundColor(colors.lime)
			mon.setTextColor(colors.lime)
		end
		mon.setCursorPos(width - 2, i)
		mon.write("  ")
	end
	mon.setBackgroundColor(colors.black)
	local temp = formatRFEnergy(energyAvailable * 80)
	mon.setCursorPos(width - string.len(temp) - 4, height)
	mon.write(temp)
	for i = y_m, 1, -1 do
		mon.setBackgroundColor(colors.black)
		mon.setTextColor(colors.black)
		mon.setCursorPos(width - 3, i)
		mon.write("    ")
	end
end

function drawDefenseButton()
	mon.setBackgroundColor(colors.lightGray)
	mon.setTextColor(colors.black)
	if (not hasIris()) then
		mon.setTextColor(colors.red)
	end
	local label = " DEFENSE "
	local i = 1
	for y_ = (height / 3 - 1), (height / 3 * 2 + 1) do
		local c = string.sub(label, i, i)
		mon.setCursorPos(2, y_)
		mon.write(" " .. c .. " ")
		i = i + 1
	end
end

function isDefenseButtonPressed(x_, y_)
	return (x_ >= 2 and x_ <= 4) and (y_ >= (height / 3 - 2) and y_ <= (height / 3 * 2 + 1)) -- Tested on 05.01.2020 13:58
end

function drawIrisButton()
	mon.setBackgroundColor(colors.lightGray)
	mon.setTextColor(colors.black)
	if (not hasIris()) then
		mon.setTextColor(colors.red)
	elseif (isIrisClosed()) then
		mon.setTextColor(colors.lime)
	elseif (isIrisMoving()) then
		mon.setTextColor(colors.blue)
	end
	local label = "   IRIS  "
	local i = 1
	for y_ = (height / 3 - 1), (height / 3 * 2 + 1) do
		local c = string.sub(label, i, i)
		mon.setCursorPos(6, y_)
		mon.write(" " .. c .. " ")
		i = i + 1
	end
end

function isIrisButtonPressed(x_, y_)
	return (x_ >= 6 and x_ <= 8) and (y_ >= (height / 3 - 2) and y_ <= (height / 3 * 2 + 1)) -- Tested on 05.01.2020 13:59
end

function drawRemoteIris(open) -- TODO Use this in the drawMainMenu function, because if you were in another Menu, then return to main it should rewrite the remote iris state, if the stargate is still connected to the same stargate
	if (open) then
		mon.setTextColor(colors.lime)
	else
		mon.setTextColor(colors.red)
	end
	mon.setBackgroundColor(colors.black)
	local temp = "IRIS"
	if (open == nil) then
		temp = temp + "?"
	end
	mon.setCursorPos((width - string.len(temp)) / 2, height / 2 + 3) -- TODO Check position
	mon.write(temp)
end

function drawRemoteAddress()
	local address = sg.remoteAddress()
	if (address ~= nil and address ~= "") then
		mon.setBackgroundColor(colors.black)
		local state, engaged, direction = sg.stargateState()
	end
end

-- ###### Stargate BEGIN

function drawStargate(address)
	clearRing()
	drawRing()
	drawChevrons(address)
end

function clearRing()
	mon.setBackgroundColor(colors.black)
	mon.setTextColor(colors.black)
	for y_ = (height - ring_height) / 2, (height + ring_height) / 2 - 1 do
		for x_ = (width - ring_width + 1) / 2, (width + ring_width - 1) / 2 do
			--[[
			if ((x_ % 2) == (y_ % 2)) then
				mon.setBackgroundColor(colors.blue)
			else
				mon.setBackgroundColor(colors.red)
			end
			]]--
			mon.setCursorPos(x_, y_)
			mon.write(" ")
		end
	end
end

function drawRing()
	mon.setBackgroundColor(colors.lightGray)
	mon.setTextColor(colors.black)
	local bar_horizontal = ring_width - 6
	mon.setCursorPos((width - bar_horizontal) / 2 + 1, 4) -- top bar
	local temp = ""
	for i = 1, bar_horizontal do
		temp = temp .. " "
	end
	mon.write(temp)
	mon.setCursorPos((width - bar_horizontal) / 2 + 1, 14) -- bottom bar
	mon.write(temp)
	local bar_vertical = ring_height - 4
	temp = 6
	for y_ = temp, temp + bar_vertical - 1 do
		mon.setCursorPos((width - bar_horizontal) / 2 - 1, y_)
		mon.write(" ") -- left bar
		mon.setCursorPos((width + bar_horizontal) / 2 + 2, y_)
		mon.write(" ") -- right bar
	end
end

function drawChevrons(address)
	if (address == nil) then
		address = ""
	end
	for i = 1, 9 do
		local c = string.sub(address, i, i)
		if (c == "") then
			c = nil
			mon.setTextColor(colors.black)
		else
			mon.setTextColor(remoteAddressColor)
		end
		drawChevron(i, c)
	end
end

function drawChevron(i, c)
	mon.setBackgroundColor(colors.gray)
	if (i == 1) then
		if (not c) then
			c = ">"
		end
		mon.setCursorPos((width - ring_width) / 2 + 2, (height + ring_height) / 2 - 2)
	elseif (i == 2) then
		if (not c) then
			c = ">"
		end
		mon.setCursorPos((width - ring_width) / 2 + 1, height / 2)
	elseif (i == 3) then
		if (not c) then
			c = ">"
		end
		mon.setCursorPos((width - ring_width) / 2 + 2, (height - ring_height) / 2 + 1)
	elseif (i == 4) then
		if (not c) then
			c = "V"
		end
		mon.setCursorPos((width - 2) / 2, (height - ring_height) / 2)
	elseif (i == 5) then
		if (not c) then
			c = "<"
		end
		mon.setCursorPos((width + ring_width) / 2 - 3, (height - ring_height) / 2 + 1)
	elseif (i == 6) then
		if (not c) then
			c = "<"
		end
		mon.setCursorPos((width + ring_width) / 2 - 2, height / 2)
	elseif (i == 7) then
		if (not c) then
			c = "<"
		end
		mon.setCursorPos((width + ring_width) / 2 - 3, (height + ring_height) / 2 - 2)
	elseif (i == 8) then
		if (not c) then
			c = "^"
		end
		mon.setCursorPos((width + 4) / 2, (height + ring_height) / 2 - 1)
	elseif (i == 9) then
		if (not c) then
			c = "^"
		end
		mon.setCursorPos((width - 7) / 2, (height + ring_height) / 2 - 1)
	end
	if (c) then
		mon.write(" " .. c .. " ")
	end
end

function isRingInnerPressed(x_, y_)
	return (x_ >= 19 and x_ <=  31) and (y_ >= 6 and y_ <= 13) -- TODO Make modular <- ?
end

-- ###### Stargate END

function drawHistoryButton()
	loadHistory()
	mon.setBackgroundColor(colors.lightGray)
	mon.setTextColor(colors.black)
	if (isHistoryEmpty()) then
		mon.setBackgroundColor(colors.gray)
	end
	local label = " HISTORY "
	local i = 1
	for y_ = (height / 3 - 1), (height / 3 * 2 + 1) do
		local c = string.sub(label, i, i)
		mon.setCursorPos(width - 8, y_)
		mon.write(" " .. c .. " ")
		i = i + 1
	end
end

function isHistoryButtonPressed(x_, y_)
	return (width - x_ >= 6 and width - x_ <= 8) and (y_ >= (height / 3 - 2) and y_ <= (height / 3 * 2 + 1)) -- Tested on 05.01.2020 14:00
end


function drawDialButton()
	local label = dial_button_standard
	local state, engaged, direction = sg.stargateState()
	mon.setBackgroundColor(colors.lightGray)
	mon.setTextColor(colors.black)
	if (state ~= stargate_state_idle) then
		label = dial_button_keep
		if (settings.keepOpen and settings.keepOpen or false) then
			mon.setTextColor(colors.lime)
		end
	end
	for y_ = (height - 3), (height - 1) do
		mon.setCursorPos(width / 2 - 7, y_)
		mon.write("      ")
	end
	mon.setCursorPos(width / 2 - 6, height - 2)
	mon.write(label)
end

function isDialButtonPressed(x_, y_)
	return (x_ >= (width / 2 - 7) and x_ <= (width / 2 - 2)) and (y_ >= (height - 3) and y_ <= (height - 1)) -- Tested on 05.01.2020 14:02
end

function drawTermButton()
	local state, engaged, direction = sg.stargateState()
	mon.setBackgroundColor(colors.gray)
	if (state == stargate_state_connected or state == stargate_state_connecting or state == stargate_state_dialling) then
		mon.setBackgroundColor(colors.lightGray)
	end
	mon.setTextColor(colors.black)
	for y_ = (height - 3), (height - 1) do
		mon.setCursorPos(width / 2 + 2, y_)
		mon.write("      ")
	end
	mon.setCursorPos(width / 2 + 3, height - 2)
	mon.write(term_button_standard)
end

function isTermButtonPressed(x_, y_)
	return (x_ >= (width / 2 + 2) and x_ <= (width / 2 + 7)) and (y_ >= (height - 3) and y_ <= (height - 1)) -- Tested on 05.01.2020 14:02
end

function toggleKeepOpen()
	loadSettings()
	if (settings.keepOpen == nil) then
		settings.keepOpen = false
	else
		settings.keepOpen = not settings.keepOpen
	end
	saveSettings()
	drawDialButton()
end

function testForKeepOpen() -- TODO The stargate is not showing the dial animation, when redialling?
	loadSettings()
	if (settings.keepOpen and settings.last) then
		sleep(3)
		if (settings.temp_forceTerm) then
			settings.temp_forceTerm = nil
			repaintMenu()
			return
		end
		dial(settings.last)
	end
end

-- #### Main Menu END

-- #### List Menus BEGIN

function drawPreList(page, page_max, color_back)
	loadSettings()
	settings.temp_page = page
	settings.temp_page_max = page_max
	saveSettings()
	for y_ = 1 + list_offset, entries_per_page + list_offset do
		mon.setBackgroundColor(getColorForEntryOnPage(page, y_))
		for x_ = 1, width do
			mon.setCursorPos(x_, y_)
			mon.write(" ")
		end
	end
	drawBottom(color_back)
	drawScrollStuff(page, page_max)
end

function drawBottom(color_back)
	mon.setBackgroundColor(color_back and color_back or colors.black)
	mon.setTextColor(colors.black)
	for y_ = entries_per_page + 1 + list_offset, height do
		for x_ = 1, width - 6 do
			mon.setCursorPos(x_, y_)
			mon.write(" ")
		end
	end
end

function drawScrollStuff(page, page_max)
	mon.setBackgroundColor(colors.white)
	mon.setTextColor(colors.black)
	for y_ = entries_per_page + 1 + list_offset, height do
		mon.setCursorPos(width - 5, y_)
		mon.write("      ")
	end
	mon.setCursorPos(width - 3, height - 2)
	mon.write("UP")
	mon.setCursorPos(width - 4, height)
	mon.write("DOWN")
	mon.setBackgroundColor(colors.lightGray)
	mon.setCursorPos(width - 5, height - 1)
	mon.write(" ")
	if (page < 10) then
		mon.write("0")
	end
	local s = "" .. page
	mon.write(string.sub(s, 1, string.len(s) - 2))
	mon.write("/")
	if (page_max < 10) then
		mon.write("0")
	end
	s = "" .. page_max
	mon.write(string.sub(s, 1, string.len(s) - 2))
end

function getColorForEntryOnPage(page, i)
	if (getIndexForEntryOnPage(page, i) % 2 == 0) then
		return colors.lightGray
	else
		return colors.lightBlue
	end
end

function getIndexForEntryOnPage(page, i)
	return (page - 1) * entries_per_page + (i - list_offset)
end

function getEntryOnPage(list, page, i)
	return list[getIndexForEntryOnPage(page, i)]
end

function drawSmallBackButton()
	mon.setBackgroundColor(colors.black)
	mon.setTextColor(colors.white)
	mon.setCursorPos(1, height - 2)
	mon.write("      ")
	mon.setCursorPos(1, height - 1)
	mon.write("      ")
	mon.setCursorPos(1, height)
	mon.write("      ")
	mon.setCursorPos(2, height - 1)
	mon.write(button_back)
end

function drawBackButton()
	mon.setBackgroundColor(colors.black)
	mon.setTextColor(colors.white)
	for y_ = height - 2, height do
		for x_ = 1, width - 6 do
			mon.setCursorPos(x_, y_)
			mon.write(" ")
		end
	end
	mon.setCursorPos((width - string.len(button_back)) / 2 - 2, height - 1)
	mon.write(button_back)
end

function isSmallBackButtonPressed(x_, y_)
	return (x_ >= 1 and x_ <= 6) and (y_ >= height - 2 and y_ <= height)
end

function isBackButtonPressed(x_, y_)
	return (x_ >= 1 and x_ <= width - 6) and (y_ >= height - 2 and y_ <= height)
end

function drawX(y_)
	mon.setBackgroundColor(colors.red)
	mon.setTextColor(colors.black)
	mon.setCursorPos(width, y_)
	mon.write("X")
end

function isXPressed(x_, y_)
	return x_ == width and (y_ >= 1 + list_offset and y_ <= entries_per_page)
end

-- ###### Security Menu BEGIN

function drawSecurityMenu()
	drawHeader(false)
	drawSecurityList(1)
	-- TODO
end

function drawSecurityList(page)
	loadStargates()
	loadSettings()
	local color_back = getSecurityBackgroundColor(settings.irisOnIncomingDial)
	local color_text = getSecurityTextColor(settings.irisOnIncomingDial)
	local page_max = math.ceil(#stargates / entries_per_page)
	drawPreList(page, page_max, color_back)
	local max_ = page * entries_per_page
	if (max_ > #stargates) then
		max_ = #stargates
	end
	loadSettings()
	settings.temp_max_ = max_
	saveSettings()
	local energyAvailable = sg.energyAvailable()
	for y_ = 1 + list_offset, max_ + list_offset do
		mon.setBackgroundColor(getColorForEntryOnPage(page, y_))
		mon.setTextColor(colors.black)
		mon.setCursorPos(1, y_)
		local stargate = getEntryOnPage(stargates, page, y_)
		local temp = formatAddressToHiphons(stargate.address)
		mon.write(temp)
		mon.setCursorPos((width - string.len(stargate.name)) / 2 - 1, y_)
		mon.write(stargate.name)


		---- ####


		--[[
		local ok, energyNeeded = pcall(sg.energyToDial, stargate.address)
		if (not energyNeeded) then
			ok = false
		end
		if (ok) then
			if (energyAvailable >= energyNeeded) then
				mon.setTextColor(colors.green)
			else
				mon.setTextColor(colors.red)
			end
			local temp = formatRFEnergy(energyNeeded * 80)
			mon.setCursorPos(width - string.len(temp) - 2, y_)
			mon.write(temp)
		else
			mon.setTextColor(colors.white)
			mon.setCursorPos((width + 5) / 2, y_)
			mon.write("--")
		end
		]]--


		---- ####

		drawX(y_)
	end
	updateSecurityList(page)
	mon.setTextColor(colors.black)
	for y_ = max_ + 1 + list_offset, entries_per_page + list_offset do
		mon.setBackgroundColor(getColorForEntryOnPage(page, y_))
		mon.setCursorPos((width - string.len(button_add_address)) / 2 + 1, y_)
		mon.write(button_add_address)
	end
	drawSmallBackButton()
	drawSecurityStandardButton(color_back, color_text)
end

function drawSecurityStandardButton(color_back, color_text)
	mon.setBackgroundColor(color_back)
	mon.setTextColor(color_text)
	mon.setCursorPos((width - string.len(settings.irisOnIncomingDial)) / 2, height - 1)
	mon.write(settings.irisOnIncomingDial)
end

function updateSecurityList(page)
	local max_ = page * entries_per_page
	if (max_ > #stargates) then
		max_ = #stargates
	end
	loadSettings()
	settings.temp_max_ = max_
	saveSettings()
	for y_ = 1 + list_offset, max_ + list_offset do
		local stargate = getEntryOnPage(stargates, page, y_)
		mon.setBackgroundColor(getSecurityBackgroundColor(stargate.state))
		mon.setTextColor(getSecurityTextColor(stargate.state))
		mon.setCursorPos(width - 6, y_)
		mon.write(stargate.state)
		if (stargate.state ~= security_allow) then
			mon.write(" ")
		end
		mon.setBackgroundColor(getSecurity2BackgroundColor(stargate.locked))
		mon.setTextColor(getSecurity2TextColor(stargate.locked))
		mon.setCursorPos(width - 6 - 1 - 6, y_)
		mon.write(stargate.locked and security_locked or security_diable)
	end
end

function updateSecurityStandardButton()
	local color_back = getSecurityBackgroundColor(settings.irisOnIncomingDial)
	local color_text = getSecurityTextColor(settings.irisOnIncomingDial)
	drawBottom(color_back)
	drawSmallBackButton()
	drawSecurityStandardButton(color_back, color_text)
end

function getSecurityBackgroundColor(security)
	if (security == security_allow) then
		return security_color_allow
	elseif (security == security_deny) then
		return security_color_deny
	elseif (security == security_none) then
		return security_color_none
	else
		return colors.black
	end
end

function getSecurityTextColor(security)
	if (security == security_allow) then
		return security_color_text_allow
	elseif (security == security_deny) then
		return security_color_text_deny
	elseif (security == security_none) then
		return security_color_text_none
	else
		return colors.white
	end
end

function getSecurity2BackgroundColor(locked)
	if (locked) then
		return security_color_locked
	else
		return security_color_diable
	end
end

function getSecurity2TextColor(locked)
	if (locked) then
		return security_color_text_locked
	else
		return security_color_text_diable
	end
end

function securityMenuXPressed(y_)
	loadSettings()
	local page = settings.temp_page
	local page_max = settings.temp_page_max
	local max_ = settings.temp_max_
	local i_ = getIndexForEntryOnPage(page, y_)
	if (i_ > max_) then
		return
	end
	table.remove(stargates, i_)
	saveStargates()
	repaintMenu()
end

-- ###### Security Menu END

-- ###### History Menu BEGIN

function drawHistoryMenu()
	drawHeader(false)
	drawHistoryList(1)
	-- TODO
end

function drawHistoryList(page)
	loadSettings()
	loadHistory()
	loadStargates()
	local page_max = math.ceil(#stargates / entries_per_page)
	drawPreList(page, page_max, colors.gray)
	local max_ = page * entries_per_page
	if (settings.history_distinct) then
		if (max_ > #history) then
			max_ = #history
		end
		loadSettings()
		settings.temp_max_ = max_
		saveSettings()
		for y_ = 1 + list_offset, max_ + list_offset do
			local i_ = getIndexForEntryOnPage(page, y_)
			local stargate = history[i_]
			if (stargate.timestamps and #stargate.timestamps > 0) then
				mon.setBackgroundColor(getColorForEntryOnPage(page, y_))
				mon.setTextColor(colors.black)
				mon.setCursorPos(1, y_)
				mon.write(stargate.address)
				--local s = #stargate.timestamps .. " time(s)"
				local ins = 0
				local outs = 0
				for i, n in ipairs(stargate.timestamps) do
					if (n.inc) then
						ins = ins + 1
					else
						outs = outs + 1
					end
				end
				--local s = ins .. " I / " .. outs .. " O"
				--local s = ins .. "I/" .. outs .. "O"
				local s = ins .. "/" .. outs
				mon.setCursorPos(11, y_)
				mon.write(s)
				local stargate_ = getStargateByAddress(stargates, stargate.address)
				if (stargate_) then
					mon.setCursorPos((width - string.len(stargate_.name)) / 2 + 1, y_)
					mon.write(stargate_.name)
				else
					s = "Unknown"
					mon.setTextColor(colors.white)
					mon.setCursorPos((width - string.len(s)) / 2 + 1, y_)
					mon.write(s)
					mon.setBackgroundColor(colors.white)
					mon.setTextColor(colors.black)
					mon.setCursorPos(width - string.len(button_back) - 1 - 1 - string.len(button_save) - 1, y_)
					mon.write(button_save)
				end
				mon.setBackgroundColor(colors.black)
				mon.setTextColor(colors.red)
				mon.setCursorPos(width - string.len(button_back) - 1 - 1, y_)
				mon.write(button_block)
			end
			drawX(y_) -- TODO Move this one up?
		end
	else
		if (max_ > #history) then
			local temp = 0
			for i, n in ipairs(history) do
				temp = temp + #n.timestamps
			end
			if (max_ > temp) then
				max_ = temp
			else
				max_ = #history
			end
		end
		loadSettings()
		settings.temp_max_ = max_
		saveSettings()
		print("TODO") -- TODO
	end
	drawSmallBackButton()
	drawHistoryStandardButton()
	-- TODO Save/Block Screens etc
end

function drawHistoryStandardButton()
	mon.setBackgroundColor(colors.gray)
	mon.setTextColor(colors.white)
	mon.setCursorPos((width - string.len(history_distinct)) / 2, height - 1)
	mon.write(settings.history_distinct and history_distinct or history_normal)
end

function updateHistoryStandardButton()
	drawBottom(colors.gray)
	drawSmallBackButton()
	drawHistoryStandardButton()
end

function logDial(remoteAddress_, timestamp, incoming)
	loadHistory()
	local index = utils.getTableIndexFromArray(history, remoteAddress_, getAddress)
	if (index == nil) then
		table.insert(history, {address = remoteAddress_, timestamps = {{ts = timestamp, inc = incoming}}})
	else
		if (history[index].timestamps == nil) then
			history[index].timestamps = {{ts = timestamp, inc = incoming}}
		else
			history[index].timestamps[#history[index].timestamps + 1] = {ts = timestamp, inc = incoming}
			--table.insert(history[index].timestamps, {ts = timestamp, inc = incoming})
		end
	end
	saveHistory()
end

-- TODO Add a toggle Button, that toggles between showing "ALL", "KNOWN (ONLY)" and "UNKNOWN (ONLY)" so you can filter for connections

-- ###### History Menu END

-- ###### Dial Menu BEGIN

function drawDialMenu()
	drawHeader(false)
	drawDialList(currentPages.dialPage) -- TODO Return to the same page? And go to page 1 if you click between "Up" and "Down"? So you have a way to go fast to the first page
	-- TODO
end

function drawDialList(page)
	currentPages.dialPage = page
	loadStargates()
	local offset_ = (page - 1) * entries_per_page
	local max_ = page * entries_per_page
	if (max_ > #stargates) then
			max_ = #stargates
	end
	local temp = 0
	for i, n in ipairs(stargates) do
		if (not n.locked) then
			temp = temp + 1
		end
	end
	if (max_ > temp) then
		max_ = temp
	end
	local page_max = math.ceil(max_ / entries_per_page)
	drawPreList(page, page_max)
	loadSettings()
	settings.temp_max_ = max_
	saveSettings()
	local energyAvailable = sg.energyAvailable()
	for y_ = 1 + list_offset + offset_, max_ + list_offset + offset_ do
		mon.setBackgroundColor(getColorForEntryOnPage(page, y_))
		mon.setTextColor(colors.black)
		mon.setCursorPos(1, y_)
		--local stargate = getEntryOnPage(stargates, page, y_)
		local stargate = stargates[getIndexForEntryOnDialPage(getIndexForEntryOnPage(page, y_))]
		if (stargate == nil) then
			print("That should not happen... (3t4zj7)") -- DEBUG
			break
		end
		local temp = formatAddressToHiphons(stargate.address)
		mon.write(temp)
		mon.setCursorPos((width - string.len(stargate.name)) / 2 + 1, y_)
		mon.write(stargate.name)
		local ok, energyNeeded = pcall(sg.energyToDial, stargate.address)
		if (not energyNeeded) then
			ok = false
		end
		if (ok) then
			if (energyAvailable >= energyNeeded) then
				mon.setTextColor(colors.green)
			else
				mon.setTextColor(colors.red)
			end
			local temp = formatRFEnergy(energyNeeded * 80)
			mon.setCursorPos(width - string.len(temp) - 2, y_)
			mon.write(temp)
		else
			mon.setTextColor(colors.white)
			mon.setCursorPos(width - 6, y_)
			mon.write("--")
		end
		drawX(y_)
	end
	mon.setTextColor(colors.black)
	for y_ = max_ + 1 + list_offset, entries_per_page + list_offset do
		mon.setBackgroundColor(getColorForEntryOnPage(page, y_))
		mon.setCursorPos((width - string.len(button_add_address)) / 2 + 1, y_)
		mon.write(button_add_address)
	end
	--[[
	mon.setBackgroundColor(colors.black)
	mon.setTextColor(colors.white)
	mon.setCursorPos((width - string.len(button_back)) / 2 + 1, height - 1)
	mon.write(button_back)
	]]--
	--drawSmallBackButton()
	drawBackButton()
end

function dialMenuXPressed(y_)
	loadSettings()
	local page = settings.temp_page
	local page_max = settings.temp_page_max
	local max_ = settings.temp_max_
	local i_ = getIndexForEntryOnPage(page, y_)
	if (i_ > max_) then
		return
	end
	-- FIXME Was ist mit den Verschiebungen, wenn Stargates locked (also nicht diable) sind, dann rutschen die Anderen ja in der Dial Liste nach oben
	--table.remove(stargates, i_)
	-- TODO Just lock the stargate
	local i__ = getIndexForEntryOnDialPage(i_)
	stargates[i__].locked = true
	saveStargates()
	repaintMenu()
end

function isDialEntryPressed(x_, y_)
	return x_ < width and (y_ >= 1 + list_offset and y_ <= entries_per_page)
end

function dialEntryPressed(y_)
	local page = currentPages.dialPage
	--local offset_ = (page - 1) * entries_per_page
	local max_ = page * entries_per_page
	if (max_ > #stargates) then
			max_ = #stargates
	end
	local temp = 0
	for i, n in ipairs(stargates) do
		if (not n.locked) then
			temp = temp + 1
		end
	end
	if (max_ > temp) then
		max_ = temp
	end
	local index = getIndexForEntryOnDialPage(getIndexForEntryOnPage(page, y_))
	if (index > 0) then
		local stargate = stargates[index]
		dial(stargate.address)
		drawMenu(menu_main)
	else
		print("Dial: Add Address") -- TODO Add Address
	end
end

function getIndexForEntryOnDialPage(i_)
	local locked_count = 0
	for i, n in ipairs(stargates) do
		if (n.locked) then
			locked_count = locked_count + 1
		end
		if (i - locked_count == i_) then
			return i
		end
	end
	return -1
end

function dial(address)
	-- FIXME log?
	print("Dialling " .. address) -- DEBUG
	sg.dial(address)
end

-- ###### Dial Menu END

-- #### List Menus END















-- #### #### Test BEGIN -- REMOVE

--##--loadAll()



--drawMenu(menu_main, true)

--drawRemoteIris(true) -- TODO Test only

--drawMenu(menu_dial, true)
--drawMenu(menu_security, true)
--##--drawMenu(menu_history, true)

-- #### #### Test END


loadAll()
settings.temp_forceTerm = nil
settings.temp_page = nil
settings.temp_max_ = nil
settings.temp_page_max = nil
saveSettings()
drawMenu(menu_main, true)
resetTimer()
while true do
	local event, param_1, param_2, param_3, param_4, param_5 = os.pullEvent()
	if (event == event_timer) then
		--repaintMenu() -- FIXME Update?
		drawHeader()
		if (menu == menu_main) then
			drawPowerBar()
		end
		resetTimer()
	elseif (event == event_monitor_touch) then
		local x_ = param_2
		local y_ = param_3
		print(event, param_1, param_2, param_3) -- DEBUG

		--print("isRingInnerPressed=" .. tostring(isRingInnerPressed(x_, y_))) -- REMOVE
		--print("isTermButtonPressed=" .. tostring(isTermButtonPressed(x_, y_))) -- REMOVE

		---- ## ## ## ## BEGIN ## ## ## ## ----

		local state, engaged, direction = sg.stargateState()

		if (menu == menu_dial) then
			if (isBackButtonPressed(x_, y_)) then
				drawMenu(menu_main)
			elseif (isTimePressed(x_, y_)) then
				toggleTimeFormat()
			elseif (isXPressed(x_, y_)) then
				dialMenuXPressed(y_)
			elseif (isDialEntryPressed(x_, y_)) then
				dialEntryPressed(y_)
			end
			-- TODO Page Up/Down?
		elseif (menu == menu_history) then
			if (isSmallBackButtonPressed(x_, y_)) then
				drawMenu(menu_main)
			elseif (isTimePressed(x_, y_)) then
				toggleTimeFormat()
			elseif (isXPressed(x_, y_)) then
				historyMenuXPressed(y_) -- TODO !!!
			end
			-- TODO
			-- TODO Page Up/Down?
		elseif (menu == menu_main) then
			if (isRingInnerPressed(x_, y_)) then
				if (state == stargate_state_idle) then
					if (settings.lastCalled) then
						dial(settings.lastCalled) --TODO Direct call?
						sleep(0.1) -- TODO Necessary?
						repaintMenu() -- TODO Necessary?
					end
				end
			elseif (isTermButtonPressed(x_, y_)) then
				loadSettings()
				settings.temp_forceTerm = true
				saveSettings()
				sg.disconnect()
				sleep(0.1) -- TODO Good?
				repaintMenu()
			elseif (isDialButtonPressed(x_, y_)) then
				local state, engaged, direction = sg.stargateState()
				if (state == stargate_state_idle) then
					drawMenu(menu_dial)
				else
					toggleKeepOpen()
				end
			elseif (isDefenseButtonPressed(x_, y_)) then
				drawMenu(menu_security)
			elseif (isIrisButtonPressed(x_, y_)) then
				toggleIris()
			elseif (isHistoryButtonPressed(x_, y_)) then
				drawMenu(menu_history)
			elseif (isTimePressed(x_, y_)) then
				toggleTimeFormat()
			end
			-- TODO
		elseif (menu == menu_security) then
			if (isSmallBackButtonPressed(x_, y_)) then
				drawMenu(menu_main)
			elseif (isTimePressed(x_, y_)) then
				toggleTimeFormat()
			elseif (isXPressed(x_, y_)) then
				securityMenuXPressed(y_)
			end
			-- TODO
			-- TODO Page Up/Down?
		end

		---- ## ## ## ##  END  ##  ## ## ## ----
	elseif (event == event_sgDialIn) then
		local remoteAddress_ = sg.remoteAddress()
		local timestamp = time_utils.now()
		logDial(remoteAddress_, timestamp, true)
		repaintMenu()
		-- TODO toggleIrisOnIncomingDial?
	elseif (event == event_sgDialOut) then
		local remoteAddress_ = sg.remoteAddress()
		local timestamp = time_utils.now()
		logDial(remoteAddress_, timestamp, false)
		repaintMenu()
		-- TODO toggleIrisOnIncomingDial?
	elseif (event == event_sgMessageReceived) then
		print("Message Received: " .. param_2) -- DEBUG
		if (param_1 == message_remoteIrisState) then
			if (param_2.irisOpen) then
				remoteIrisOpen = true
			else
				remoteIrisOpen = nil
			end
			if (menu == menu_main) then
				drawRemoteIris(param_2.irisOpen) -- REMOVE
			end
		end
	elseif (event == event_sgIrisStateChange) then
		if (menu == menu_main) then
			drawIrisButton()
		end
		if (sg.remoteAddress() ~= nil) then
			sg.sendMessage("remoteIrisState", {irisOpen = param_2 == iris_state_open})
		end
	elseif (event == event_sgStargateStateChange) then
		print("sgStargateStateChange=" .. param_2) -- DEBUG
		if (param_2 == stargate_state_closing) then
			testForKeepOpen()
		else
			repaintMenu()
		end
	elseif (event == event_sgChevronEngaged) then
	end
end
