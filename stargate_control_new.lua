--[[

  Author: Panzer1119
  
  Date: Edited 09 Jul 2019 - 00:32 AM
  
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
--MON_HEIGHT = 26

width, height = mon.getSize()

remoteAddress = ""
remoteAddressColor = colors.black
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
	end
	return temp
end

function isHistoryEmpty()
	return (history == nil) or (#history == 0)
end

-- Misc END

settings = {twentyFourHour = true, keepOpen = false} -- TODO!!!
stargates = {}
history = {}

folder_stargate = "stargate"
file_settings = folder_stargate .. "/settings.lon"
file_stargates = folder_stargate .. "/stargates.lon"
file_history = folder_stargate .. "/history.lon"

security_allow = "ALLOW"
security_deny = "DENY"
security_none = "NONE"

iris_state_offline = "Offline"
iris_state_closed = "Closed"
iris_state_open = "Open"
iris_state_opening = "Opening"
iris_state_closing = "Closing"

stargate_state_connected = "Connected"
stargate_state_connecting = "Connecting"
stargate_state_dialling = "Dialling"
stargate_state_idle = "Idle"

dial_button_standard = "DIAL"
dial_button_keep = "KEEP"
dial_button_hold = "HOLD"

term_button_standard = "TERM"

-- ###### LOAD BEGIN

function loadSettings()
	if (not fs.exists(file_settings)) then
		settings = {twentyFourHour = true, keepOpen = false}
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
	color_back = color_back and color_back or colors.black
	color_text = color_text and color_text or colors.white
	mon.setBackgroundColor(color_back)
	mon.setTextColor(color_text)
	drawDate()
	drawTime()
	drawLocalAddress(full)
end

function getFormattedDate()
	return "Day " .. os.day()
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
	mon.write(getFormattedDate())
end

function drawTime()
	local time_formatted = getFormattedTime()
	mon.setCursorPos(width - string.len(time_formatted) + 1, 1)
	mon.write(time_formatted)
end

function drawLocalAddress(full)
	mon.setTextColor(colors.lightGray)
	full = full and full or true
	local address_local_formatted = formatAddressToHiphons(sg.localAddress())
	local y = 1
	if (full) then
		local temp = "Stargate Address:"
		mon.setCursorPos((width - string.len(temp)) / 2, y)
		mon.write(temp)
		y = y + 1
	end
	mon.setCursorPos((width - string.len(address_local_formatted)) / 2, y)
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
	drawStargate(remoteAddress) -- TODO
	drawHistoryButton()
	drawDialButton()
	drawTermButton()
	if (firstTimeGate) then
		firstTimeGate = false
		local state, engaged, direction = sg.stargateState()
		if (state == stargate_state_connected) then
			remoteAddress = sg.remoteAddress()
			remoteAddressColor = colors.lightBlue
			--drawChevrons(remoteAddress) -- TODO
		elseif (state == stargate_state_dialling) then
			remoteAddress = sg.remoteAddress()
			remoteAddressColor = colors.orange
			--drawChevrons(remoteAddress) -- TODO
		end
	end
end

function drawPowerBar()
	local energyAvailable = sg.energyAvailable()
	local energyPercent = (energyAvailable / ((settings.maxEnergy and settings.maxEnergy or 50000) + 1))
	for i = height, (height - (height * energyPercent)), -1 do
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
	mon.setCursorPos(width - 11, height)
	mon.write(formatRFEnergy(energyAvailable * 80))
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
	return (x_ >= 2 and x_ <= 4) and (y_ >= (height / 3 - 2) and y_ <= (height / 3 * 2)) --TODO Test this
end

function drawIrisButton()
	mon.setBackgroundColor(colors.lightGray)
	mon.setTextColor(colors.black)
	if (not hasIris()) then
		mon.setTextColor(colors.red)
	elseif (isIrisClosed()) then
		mon.setTextColor(colors.lime)
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
	return (x_ >= 6 and x_ <= 8) and (y_ >= (height / 3 - 2) and y_ <= (height / 3 * 2)) --TODO Test this
end

-- TODO drawRemoteIris

-- TODO drawRemoteAddress

-- ###### Stargate BEGIN

function drawStargate(address)
	 -- TODO
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
	return (width - x_ >= 6 and width - x_ <= 8) and (y_ >= (height / 3 - 2) and y_ <= (height / 3 * 2)) --TODO Test this
end


function drawDialButton()
	local label = dial_button_standard
	local state, engaged, direction = sg.stargateState()
	mon.setBackgroundColor(colors.lightGray)
	mon.setTextColor(colors.black)
	if (state ~= stargate_state_idle) then
		--mon.setBackgroundColor(colors.gray) -- TODO Remove
		label = dial_button_keep
		if (settings.keepOpen and settings.keepOpen or false) then
			mon.setTextColor(colors.lime)
		end
	end
	for y_ = (height - 4), (height - 2) do
		mon.setCursorPos(width / 2 - 7, y_)
		mon.write("      ")
	end
	mon.setCursorPos(width / 2 - 6, height - 3)
	mon.write(label)
end

function isDialButtonPressed(x_, y_)
	return (x_ >= (width / 2 - 5) and x_ <= (width / 2 - 2)) and (y_ >= (height - 3) and y_ <= (height - 1)) --TODO Test this
end

function drawTermButton()
	local state, engaged, direction = sg.stargateState()
	mon.setBackgroundColor(colors.gray)
	if (state == stargate_state_connected or state == stargate_state_connecting or state == stargate_state_dialling) then
		mon.setBackgroundColor(colors.lightGray)
	end
	mon.setTextColor(colors.black)
	for y_ = (height - 4), (height - 2) do
		mon.setCursorPos(width / 2 + 2, y_)
		mon.write("      ")
	end
	mon.setCursorPos(width / 2 + 3, height - 3)
	mon.write(term_button_standard)
end

function isTermButtonPressed(x_, y_)
	return (x_ >= (width / 2 + 7) and x_ <= (width / 2 + 2)) and (y_ >= (height - 3) and y_ <= (height - 1)) --TODO Test this
end

-- #### Main Menu END

-- #### Security Menu BEGIN

function drawSecurityMenu()
	drawHeader(false)
	-- TODO
end

-- #### Security Menu END

-- #### History Menu BEGIN

function drawHistoryMenu()
	drawHeader(false)
	-- TODO
end

-- #### History Menu END

-- #### Dial Menu BEGIN

function drawDialMenu()
	drawHeader(false)
	-- TODO
end

-- #### Dial Menu END




















loadAll()
drawMenu(menu_main, true)
