--[[

  Author: Panzer1119
  
  Date: Edited 27 Jun 2018 - 02:54 AM
  
  Original Source: https://github.com/Panzer1119/CCStargate/blob/master/stargate_control.lua
  
  Direct Download: https://raw.githubusercontent.com/Panzer1119/CCStargate/master/stargate_control.lua

]]--

-- This program is mainly made by thatParadox with some extra features from Panzer1119

-- Panzer1119 Changelog:
-- Now you can easily open a StarGate go to the computer click on add address and paste it in with hyphons
-- Prints the name of a StarGate that dials you if you gave the address a name
-- Checks if the StarGate has enough energy before dialing another one, if not it prints "No Energy" on the screen
-- Changed the defense system so you can now toggle for each entry if the address is denied, allowed or do nothing
-- If yout get called and the iris state was changed due to the address is in the defense system the iris goes after the connection was canceled back to its original state
-- Refreshes every second to update all things
-- In the main menu on the top left corner is now the minecraft time shown
-- Shows energy costs for all addresses in the dial list and if you have enough to dial the address
-- Changed energy unit from SU to RF

os.loadAPI("lib/utils.lua")

mon = peripheral.find("monitor")
sg = peripheral.find("stargate")

mon.setBackgroundColor(colors.black)
mon.clear()
dialling = {}
menu = ""

bookmarks = {}
security = {}
settings = {irisState = "Opened", irisOnIncomingDial = security_none, alarmOutputSides = {}, maxEnergy = 50000}
history = {incoming = {}, outgoing = {}}

filename_bookmarks = "stargate/bookmarks.lon"
filename_security = "stargate/security.lon"
filename_settings = "stargate/settings.lon"
filename_history = "stargate/history.lon"

security_allow = "ALLOW"
security_deny = "DENY"
security_none = "NONE"

-- ########## LOAD BEGIN

function loadBookmarks()
	if (not fs.exists(filename_bookmarks)) then
		bookmarks = {}
		saveBookmarks()
	end
	bookmarks = utils.readTableFromFile(filename_bookmarks)
end

function loadSecurity()
	if (not fs.exists(filename_security)) then
		security = {}
		saveSecurity()
	end
	security = utils.readTableFromFile(filename_security)
end

function loadSettings()
	if (not fs.exists(filename_settings)) then
		settings = {irisState = "Opened", irisOnIncomingDial = security_none, alarmOutputSides = {}, maxEnergy = 50000}
		saveSettings()
	end
	settings = utils.readTableFromFile(filename_settings)
end

function loadHistory()
	if (not fs.exists(filename_history)) then
		history = {incoming = {}, outgoing = {}}
		saveHistory()
	end
	history = utils.readTableFromFile(filename_history)
end

function loadAll()
	loadBookmarks()
	loadSecurity()
	loadSettings()
	loadHistory()
end

-- ########## LOAD END
-- ########## SAVE BEGIN

function saveBookmarks()
	utils.writeTableToFile(filename_bookmarks, bookmarks)
end

function saveSecurity()
	utils.writeTableToFile(filename_security, security)
end

function saveSettings()
	utils.writeTableToFile(filename_settings, settings)
end

function saveHistory()
	utils.writeTableToFile(filename_history, history)
end

function saveAll()
	saveBookmarks()
	saveSecurity()
	saveSettings()
	saveHistory()
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

function getGateByAddress(gates, address)
	if (string.len(address) == 7) then
		return utils.getTableFromArray(gates, address, getAddressShort)
	elseif (string.len(address) == 9) then
		local gate = utils.getTableFromArray(gates, address, getAddress)
		if (gate == nil) then
			gate = utils.getTableFromArray(gates, string.sub(address, 1, 7), getAddressShort)
		end
		return gate
	end
	return nil
end

function alarmSet(state)
	if (settings.alarmOutputSides ~= nil and #settings.alarmOutputSides >= 1) then
		if (state) then
			for i = 1, #settings.alarmOutputSides do
				rs.setOutput(settings.alarmOutputSides[i], true)
			end
		else
			utils.resetAllRedstoneOutputs()
		end
	else 
		utils.resetAllRedstoneOutputs()
	end
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
  
function drawPowerBar() -- checks power levels and writes power bar to monitor
	local x, y = mon.getSize()
	local engPercent = (sg.energyAvailable() / ((settings.maxEnergy == nil and 50000 or settings.maxEnergy) + 1)) * 100 -- returns percent
	for i = y, (y - y / 100 * engPercent), -1 do
		mon.setCursorPos(x - 2,i)
		if i > y / 4 * 3 then 
			mon.setBackgroundColor(colors.red)
			mon.setTextColor(colors.red)
		elseif i > y / 2 then
			mon.setBackgroundColor(colors.orange)
			mon.setTextColor(colors.orange)
		elseif i > y / 4 then
			mon.setBackgroundColor(colors.green)
			mon.setTextColor(colors.green)
		else
			mon.setBackgroundColor(colors.lime)
			mon.setTextColor(colors.lime)
		end
		mon.write("  ")
	end
	mon.setBackgroundColor(colors.black)
	mon.setCursorPos(x - 11, y)
	mon.write(formatRFEnergy(sg.energyAvailable() * 80))
end

function drawTime()
	local x, y = mon.getSize()
	mon.setCursorPos(1, 1)
	mon.setBackgroundColor(colors.black)
	mon.setTextColor(colors.white)
	local time_test = textutils.formatTime(os.time(), true)
	if (string.len(time_test) == 4) then
		time_test = "0" .. time_test
	end
	mon.write(time_test)
end

function drawChevrons() --draws cheyvrons on the screen
	local x, y = mon.getSize()
	local chevX1 = x / 3
	local chevX2 = x / 3 * 2 + 1
	local chevY1 = y / 3 - 2
	local chevY2 = y / 3 * 2 + 2
	mon.setBackgroundColor(colors.black)
	for yc = chevY1 - 2, chevY2 - 2 do
		for xc = chevX1 - 2, chevX2 - 2 do
			mon.setCursorPos(xc, yc)
			mon.write(" ")
		end
	end
	mon.setBackgroundColor(colors.lightGray)
	for i = chevX1 + 2, chevX2 - 2 do
		mon.setCursorPos(i, chevY1)
		mon.write(" ")
	end
	for i = chevX1 + 2, chevX2 - 2 do
		mon.setCursorPos(i, chevY2)
		mon.write(" ")
	end
	for i = chevY1 + 2, chevY2 - 2 do
		mon.setCursorPos(chevX1, i)
		mon.write(" ")
	end
	for i = chevY1 + 2, chevY2 - 2 do
		mon.setCursorPos(chevX2, i)
		mon.write(" ")
	end
	local chev1pos = {chevX1, chevY2}
	mon.setBackgroundColor(colors.gray)
	mon.setTextColor(colors.black)
	mon.setCursorPos(math.floor(chev1pos[1]), math.floor(chev1pos[2]) - 1)
	mon.write(" > ")
	local chev2pos = {chevX1, chevY1 + ((chevY2 - chevY1) / 2)}
	mon.setCursorPos(math.floor(chev2pos[1] - 1), math.floor(chev2pos[2]))
	mon.write(" > ")
	local chev3pos = {chevX1, chevY1}
	mon.setCursorPos(math.floor(chev3pos[1]), math.floor(chev3pos[2] + 1))
	mon.write(" > ")
	local chev4pos = {chevX1 + ((chevX2 - chevX1) / 2), chevY1}
	mon.setCursorPos(math.floor(chev4pos[1] - 1), math.floor(chev4pos[2]))
	mon.write(" V ")
	local chev5pos = {chevX2, chevY1}
	mon.setCursorPos(math.floor(chev5pos[1] - 2), math.floor(chev5pos[2]) + 1)
	mon.write(" < ")
	local chev6pos = {chevX2, chevY1 + ((chevY2 - chevY1) / 2)}
	mon.setCursorPos(math.floor(chev6pos[1] - 1), math.floor(chev6pos[2]))
	mon.write(" < ")
	local chev7pos = {chevX2, chevY2}
	mon.setCursorPos(math.floor(chev7pos[1] - 2), math.floor(chev7pos[2] - 1))
	mon.write(" < ")
	--[[ -- old positions
	chev8pos = {chevX1 + ((chevX2 - chevX1) /2), chevY2 }
	mon.setCursorPos(math.floor(chev8pos[1]-1), math.floor(chev8pos[2]))
	mon.write("   ")
	]]--
	local chev8pos = {chevX1 + ((chevX2 - chevX1) / 2) + 2, chevY2}
	mon.setCursorPos(math.floor(chev8pos[1] - 1), math.floor(chev8pos[2]))
	mon.write(" ^ ")
	local chev9pos = {chevX1 + ((chevX2 - chevX1) / 2) - 2, chevY2}
	mon.setCursorPos(math.floor(chev9pos[1] - 1), math.floor(chev9pos[2]))
	mon.write(" ^ ")
	--  local chev9pos = {chevX1 + ((chevX2 - chevX1) /2), chevY2 }
	--  mon.setCursorPos(math.floor(chev8pos[1]-1), chevY1 + ((chevY2 - chevY1) / 2))
	--  mon.write(" 9 ")
	mon.setBackgroundColor(colors.black)
	mon.setCursorPos(x / 2 - 4, y / 2 - 1)
	mon.write("           ")
	mon.setCursorPos(x / 2 - 1, y / 2 + 4)
	mon.write("     ")
end

function drawChev(chevInfo)
	mon.setBackgroundColor(colors.gray)
	local x, y = mon.getSize()
	local chevX1 = x / 3
	local chevX2 = x / 3 * 2 + 1
	local chevY1 = y / 3 - 2
	local chevY2 = y / 3 * 2 + 2
	if (chevInfo[1] == 1) then
		local chev1pos = {chevX1, chevY2}
		mon.setBackgroundColor(colors.gray)
		mon.setCursorPos(math.floor(chev1pos[1]), math.floor(chev1pos[2]) - 1)
		mon.write(" " .. chevInfo[2] .. " ")
	elseif (chevInfo[1] == 2) then
		local chev2pos = {chevX1, chevY1 + ((chevY2 - chevY1) / 2)}
		mon.setCursorPos(math.floor(chev2pos[1] - 1), math.floor(chev2pos[2]))
		mon.write(" " .. chevInfo[2] .. " ")
	elseif (chevInfo[1] == 3) then
		local chev3pos = {chevX1, chevY1}
		mon.setCursorPos(math.floor(chev3pos[1]), math.floor(chev3pos[2] + 1))
		mon.write(" " .. chevInfo[2] .. " ")
	elseif (chevInfo[1] == 4) then
		local chev4pos = {chevX1 + ((chevX2 - chevX1) / 2), chevY1}
		mon.setCursorPos(math.floor(chev4pos[1] - 1), math.floor(chev4pos[2]))
		mon.write(" " .. chevInfo[2] .. " ")
	elseif (chevInfo[1] == 5) then
		local chev5pos = {chevX2, chevY1}
		mon.setCursorPos(math.floor(chev5pos[1] - 2), math.floor(chev5pos[2]) + 1)
		mon.write(" " .. chevInfo[2] .. " ")
	elseif (chevInfo[1] == 6) then
		local chev6pos = {chevX2, chevY1 + ((chevY2 - chevY1) / 2)}
		mon.setCursorPos(math.floor(chev6pos[1] - 1), math.floor(chev6pos[2]))
		mon.write(" " .. chevInfo[2] .. " ")
	elseif (chevInfo[1] == 7) then
		local chev7pos = {chevX2, chevY2}
		mon.setCursorPos(math.floor(chev7pos[1] - 2), math.floor(chev7pos[2] - 1))
		mon.write(" " .. chevInfo[2] .. " ")
	elseif (chevInfo[1] == 8) then
		local  chev8pos = {chevX1 + ((chevX2 - chevX1) / 2) + 2, chevY2}
		mon.setCursorPos(math.floor(chev8pos[1] - 1), math.floor(chev8pos[2]))
		mon.write(" " .. chevInfo[2] .. " ")
	elseif (chevInfo[1] == 9) then
		local chev9pos = {chevX1 + ((chevX2 - chevX1) /2) - 2, chevY2}
		--mon.setCursorPos(math.floor(chev9pos[1]-1), chevY1 + ((chevY2 - chevY1) / 2))
		mon.setCursorPos(math.floor(chev9pos[1] - 1), math.floor(chev9pos[2]))
		mon.write(" " .. chevInfo[2] .. " ")
		mon.setBackgroundColor(colors.black)
	end
end

function drawSgStatus(status) -- draws stargate status
	if (status ~= "Idle") then
		--term.setCursorPos(1, 2)
		--write(status) --needed for sting length because string.len() won't work with stargateStatus()
		--local xc, yc = term.getCursorPos()
		local xc = string.len(status)
		term.clear()
		term.setCursorPos(1, 2)
		write("> ")
		if (xc % 2 == 1) then
			xc = xc + 1
			even = true
		else
			even = false
		end
		mon.setBackgroundColor(colors.black)
		if (status == "Connected") then
			mon.setTextColor(colors.lightBlue)
			drawRemoteAddress()
			sg.sendMessage("irisState")
		elseif (status == "Dialling") then
			mon.setTextColor(colors.orange)
		else
			mon.setTextColor(colors.green)
		end
		local x, y = mon.getSize()
		mon.setCursorPos((x / 2 + 1) - 6, y / 2 + 2)
		mon.write("            ")
		mon.setCursorPos((x / 2 + 1) - (xc / 2 - 1), y / 2 + 2)
		mon.write(status)
		if (even) then
			mon.write(" ")
		end
	end
end

function drawIris(state) --draws button to control the Iris
	local x, y = mon.getSize()
	mon.setBackgroundColor(colors.lightGray)
	--ok, result = pcall(sg.openIris)
	local ok = forceIrisState(false)
	if (sg.irisState() == "Offline" or ok == nil or not ok) then
		mon.setTextColor(colors.red)
	elseif (state) then
		sg.closeIris()
		mon.setTextColor(colors.lime)
	else
		mon.setTextColor(colors.black)
		sg.openIris()
	end
	local s = "   IRIS   "
	local i = 1
	for  yc = y / 3 - 1, y / 3 * 2 + 1 do
		local char_ = string.sub(s, i, i)
		mon.setCursorPos(6, yc)
		mon.write(" " .. char_ .. " ")
		i = i + 1
	end
	if (state) then
		mon.setTextColor(colors.lime)
	else
		mon.setTextColor(colors.black)
	end
end

function drawLocalAddress() -- draws the address stargate being controlled 
	local x, y = mon.getSize()
	mon.setBackgroundColor(colors.black)
	mon.setTextColor(colors.lightGray)
	mon.setCursorPos(x / 2 - 7, 1)
	mon.write("Stargate Address:")
	mon.setCursorPos(x / 2 - 3, 2)
	mon.write(sg.localAddress())
end

function drawDial() -- draws the button to access the dialing menu
	local x, y = mon.getSize()
	local state, int = sg.stargateState()
	for yc = y - 3, y - 1 do
		for xc = x / 2 - 5, x / 2 do
			if (state == "Idle") then
				mon.setBackgroundColor(colors.lightGray)
			else
				mon.setBackgroundColor(colors.gray)
			end
			mon.setCursorPos(xc, yc)
			mon.write(" ")
		end
	end
	mon.setCursorPos(x / 2 - 4, y - 2)
	mon.setTextColor(colors.black)
	mon.write("DIAL")
end

function drawTerm() -- draws the button to terminate the stargate connection to another gate
	local x, y = mon.getSize()
	local state, int = sg.stargateState()
	for yc = y - 3, y - 1 do
		for xc = x / 2 + 2, x / 2 + 7 do
			if (state == "Connected" or state == "Connecting" or state == "Dialling") then
				mon.setBackgroundColor(colors.lightGray)
			else
				mon.setBackgroundColor(colors.gray)
			end
			mon.setCursorPos(xc,yc)
			mon.write(" ")
		end
	end
	mon.setCursorPos(x / 2 + 3, y - 2)
	mon.setTextColor(colors.black)
	mon.write("TERM")
end 

function securityButton() -- draws the button to access the security menu
	local x, y = mon.getSize()
	mon.setBackgroundColor(colors.lightGray)
	--sOK, result = pcall(sg.openIris)
	local sOK = forceIrisState(false)
	if (not sOK) then
		mon.setTextColor(colors.red)
	else
		mon.setTextColor(colors.black)
	end
	local s = " DEFENSE "
	local i = 1
	for  yc = y / 3 - 1, y / 3 * 2 + 1 do
		char_ = string.sub(s, i, i)
		mon.setCursorPos(2, yc)
		mon.write(" " .. char_ .. " ")
		i = i + 1
	end
	mon.setBackgroundColor(colors.black)
end

function drawSecurityPageTop() --draws the top of the security menu, all the addresses stored in the security table
	mon.setBackgroundColor(colors.black)
	mon.clear()
	mon.setTextColor(colors.black)
	local x, y = mon.getSize()
	for yc = 1, y - 3 do
		if (yc % 2 == 1) then
			mon.setBackgroundColor(colors.lightBlue)
		else
			mon.setBackgroundColor(colors.lightGray)
		end
		for xc = 1, x do
			mon.setCursorPos(xc, yc)
			mon.write(" ")
		end
		mon.setCursorPos(x / 2 - 4, yc)
		mon.write("Add Address")
	end
	loadSecurity()
	if (#security >= 1) then
		for i = 1, y do
			local gate = utils.getTableFromArray(security, i, getId)
			if (gate ~= nil) then
				if (i % 2 == 1) then
					mon.setBackgroundColor(colors.lightBlue)
				else
					mon.setBackgroundColor(colors.lightGray)
				end
				mon.setCursorPos(1, i)
				mon.write(gate.name)
				mon.setCursorPos(x / 2 - 4, i)
				mon.write("           ")
				mon.setCursorPos(x / 2 - string.len(gate.address) / 2 + 1, i)
				mon.write(gate.address)
				mon.setCursorPos(x - 7, i)
				if (gate.mode == security_allow) then
					mon.setBackgroundColor(colors.white)
					mon.setTextColor(colors.black)
				elseif (gate.mode == security_deny) then
					mon.setBackgroundColor(colors.black)
					mon.setTextColor(colors.white)
				elseif (gate.mode == security_none) then
					mon.setBackgroundColor(colors.gray)
					mon.setTextColor(colors.white)
				end
				mon.write(gate.mode) -- ALLOW, DENY, NONE
				mon.setCursorPos(x, i)
				mon.setBackgroundColor(colors.red)
				mon.setTextColor(colors.black)
				mon.write("X")
			end
		end
	end 
	mon.setBackgroundColor(colors.black)
end
  
function drawSecurityPageBottom(listType) -- draws the buttons at the bottom of the security page
	local x, y = mon.getSize()
	local s = listType
	for yc = y - 2, y do
		for xc = 1, x do
			mon.setCursorPos(xc, yc)
			if (listType == security_deny) then
				mon.setBackgroundColor(colors.black)
				mon.setTextColor(colors.white)
				s = listType .. " OTHER"
			elseif (listType == security_allow) then
				mon.setBackgroundColor(colors.white)
				mon.setTextColor(colors.black)
				s = listType .. " OTHER"
			elseif (listType == security_none) then
				mon.setBackgroundColor(colors.gray)
				mon.setTextColor(colors.white)
			end
			mon.write(" ")
		end
	end
	mon.setCursorPos((x / 2 - tonumber(string.len(s) / 2) + 1), y - 1)
	mon.write(s)
	--mon.write("DEFENSE")
	mon.setCursorPos(x - 5, y - 1)
	mon.write("BACK")
	mon.setBackgroundColor(colors.black)
end  

function drawHome() -- draws the home screen
	menu = "main"
	mon.setBackgroundColor(colors.black)
	local x, y = mon.getSize()
	mon.clear()
	mon.setCursorPos(1, y - 1)
	mon.setTextColor(colors.gray)
	mon.setBackgroundColor(colors.black)
	mon.write("Panzer1119")
	mon.setCursorPos(1, y)
	mon.setTextColor(colors.gray)
	mon.setBackgroundColor(colors.black)
	mon.write("thatParadox")
	drawTime()
	drawPowerBar()
	drawChevrons()
	local status, int = sg.stargateState()
	drawSgStatus(tostring(status))
	drawHistoryButton()
	if (sg.irisState()  == "Open") then
		drawIris(false)
	else
		drawIris(true)
	end
	drawLocalAddress()
	securityButton()
	drawDial()
	mon.setCursorBlink(false)
	drawTerm()
end

function updateBookmarksPage()
	if (menu == "dial") then
		local x, y = mon.getSize()
		local energyAvailable = sg.energyAvailable()
		loadBookmarks()
		for i = 1, y do
			if (i % 2 == 1) then
				mon.setBackgroundColor(colors.lightBlue)
			else
				mon.setBackgroundColor(colors.lightGray)
			end
			local bookmark = utils.getTableFromArray(bookmarks, i, getId)
			if (bookmark ~= nil) then
				mon.setCursorPos(1, i)
				mon.setTextColor(colors.black)	
				local ok, energyNeeded = pcall(sg.energyToDial, bookmark.address)
				if (energyNeeded == nil) then
					ok = false
				end
				--[[
				mon.write(bookmark.name)
				mon.setCursorPos(x / 2 - 3, i)
				mon.write(bookmark.address)
				]]--
				mon.setCursorPos(x / 2 + 10, i)
				if (ok) then
					if (energyAvailable >= energyNeeded) then
						mon.setTextColor(colors.green)
					else
						mon.setTextColor(colors.red)
					end
					mon.write(formatRFEnergy(energyNeeded * 80))
				else
					mon.setCursorPos(x / 2 + 10, i)
					mon.setTextColor(colors.white)
					mon.write("--")
				end
				--[[
				mon.setCursorPos(x, i)
				mon.setBackgroundColor(colors.red)
				mon.setTextColor(colors.black)
				mon.write("X")
				]]--
			elseif (i < y - 2) then
				--[[
				mon.setTextColor(colors.black)
				for xc = 1,x do
					mon.setCursorPos(xc, i)
					mon.write(" ")
				end
				mon.setCursorPos(1, i)
				mon.write("Add Address")
				]]--
			end
		end
	end
end

function drawBookmarksPage()
	mon.setBackgroundColor(colors.black)
	mon.clear()
	mon.setTextColor(colors.black)
	local x, y = mon.getSize()
	for yc = 1, y - 3 do
		if (yc % 2 == 1) then
			mon.setBackgroundColor(colors.lightBlue)
		else
			mon.setBackgroundColor(colors.lightGray)
		end
		for xc = 1, x do
			mon.setCursorPos(xc, yc)
			mon.write(" ")
		end
	end
	local energyAvailable = sg.energyAvailable()
	loadBookmarks()
	for i = 1, y do
		if (i % 2 == 1) then
			mon.setBackgroundColor(colors.lightBlue)
		else
			mon.setBackgroundColor(colors.lightGray)
		end
		local bookmark = utils.getTableFromArray(bookmarks, i, getId)
		if (bookmark ~= nil) then
			mon.setCursorPos(1, i)
			mon.setTextColor(colors.black)	
			local ok, energyNeeded = pcall(sg.energyToDial, bookmark.address)
			if (energyNeeded == nil) then
				ok = false
			end
			mon.write(bookmark.name)
			mon.setCursorPos(x / 2 - 3, i)
			mon.write(bookmark.address)
			mon.setCursorPos(x / 2 + 10, i)
			if (ok) then
				if (energyAvailable >= energyNeeded) then
					mon.setTextColor(colors.green)
				else
					mon.setTextColor(colors.red)
				end
				mon.write(formatRFEnergy(energyNeeded * 80))
			else
				mon.setCursorPos(x / 2 + 10, i)
				mon.setTextColor(colors.white)
				mon.write("--")
			end
			mon.setCursorPos(x, i)
			mon.setBackgroundColor(colors.red)
			mon.setTextColor(colors.black)
			mon.write("X")
		elseif (i < y - 2) then
			mon.setTextColor(colors.black)
			mon.setCursorPos(1, i)
			mon.write("Add Address")
		end
	end
	mon.setCursorPos(x / 2, y - 1)
	mon.setBackgroundColor(colors.black)
	mon.setTextColor(colors.white)
	mon.write("BACK")
end

function drawRemoteIris()
	mon.setBackgroundColor(colors.black)
	local x, y = mon.getSize()
	mon.setCursorPos(x / 2 - 1, y / 2 + 4)
	mon.write("IRIS ")
end

function inputPage()
	mon.clear()
	term.redirect(mon)
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.white)
	term.clear()
	local x, y = term.getSize()
	term.setCursorPos(x / 2 - 8, y / 2 - 2)
	print("Set an address name")
	term.setCursorPos(x / 2 - 4, y / 2)
	print("         ")
	term.setCursorPos(x / 2 - 4, y / 2)
	nameInput = read()
	addressInput = "nil"
	term.setBackgroundColor(colors.lightGray)
	term.clear()
	term.setCursorPos(x / 2 - 9, y / 2 - 4)
	print("Enter Stargate address")
	term.setBackgroundColor(colors.black)
	term.setCursorPos(x / 2 - 5, y / 2)
	print("           ")
	term.setCursorPos(x / 2 - 5, y / 2)
	addressInput = string.upper(string.gsub(read(), "-", "")) --Changed this
	newGate = {name = nameInput, address = addressInput, mode = security_none, id = -1}
	term.redirect(term.native())
	return newGate
end

function drawRemoteAddress()
	local address = sg.remoteAddress()
	if (address ~= nil and address ~= "") then
		mon.setBackgroundColor(colors.black)
		local x, y = mon.getSize()
		local state, engaged, direction = sg.stargateState()
		mon.setCursorPos((x / 2 + 1) - string.len(direction) / 2, y / 2 - 4)
		mon.write(direction)
		mon.setCursorPos((x / 2 + 1) - string.len(address) / 2, y / 2 - 2)
		mon.write(address)
		loadBookmarks()
		local gate = getGateByAddress(bookmarks, address)
		if (gate ~= nil) then
			mon.setCursorPos((x / 2 + 1) - string.len(gate.name) / 2, y / 2)
			mon.write(gate.name)
		else
			loadSecurity()
			gate = getGateByAddress(security, address)
			if (gate ~= nil) then
				mon.setCursorPos((x / 2 + 1) - string.len(gate.name) / 2, y / 2)
				mon.write(gate.name)
			end
		end
	end
end

function drawHistoryButton()
	local x, y = mon.getSize()
	mon.setBackgroundColor(colors.lightGray)
	mon.setTextColor(colors.black)
	local s = " HISTORY "
	local i = 1
	for yc = y / 3 - 1, y / 3 * 2 + 1 do
		local char_ = string.sub(s, i, i)
		mon.setCursorPos(x - 7, yc)
		mon.write(" " .. char_ .. " ")
		i = i + 1
	end
end

function addToHistory(address, incoming)
	loadHistory()
	if (incoming) then
		if (not utils.arrayContains(history.incoming, address)) then
			table.insert(history.incoming, 1, address)
		end
	else
		if (not utils.arrayContains(history.outgoing, address)) then
			table.insert(history.outgoing, 1, address)
		end
	end
	saveHistory()
end

function drawHistoryPage()
	mon.setBackgroundColor(colors.black)
	mon.clear()
	mon.setTextColor(colors.black)
	local x,y = mon.getSize()
	for yc = 1, y - 3 do
		if (yc % 2 == 1) then
			mon.setBackgroundColor(colors.lightBlue)
		else
			mon.setBackgroundColor(colors.lightGray)
		end
		for xc = 1, x do
			mon.setCursorPos(xc, yc)
			mon.write(" ")
		end
	end
	loadHistory()
	for k, v in pairs(history.incoming) do
		if (k % 2 == 1) then
			mon.setBackgroundColor(colors.lightBlue)
		else
			mon.setBackgroundColor(colors.lightGray)
		end
		mon.setCursorPos(1, k)
		mon.write(v)
		mon.setCursorPos(x / 2 + 7, k)
		mon.setBackgroundColor(colors.blue)
		mon.write("SAVE")
		mon.setCursorPos(x - 8, k)
		mon.setBackgroundColor(colors.red)
		mon.write("BAN/ALLOW")
		clickLimit = k
	end 
	mon.setBackgroundColor(colors.black)
	for yc = y - 2, y do
		for xc = 1, x do
			mon.setCursorPos(xc, yc)
			mon.write(" ")
		end
	end
	mon.setCursorPos(x / 2, y - 1)
	mon.setTextColor(colors.white)
	mon.write("BACK")
end

function historyInputPage(address)
	local cx, cy = term.getCursorPos()
	mon.clear()
	term.redirect(mon)
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.white)
	term.clear()
	local x, y = term.getSize()
	term.setCursorPos(x / 2 - 8, y / 2 - 2)
	print("Set an address name")
	term.setCursorPos(x / 2 - 4, y / 2)
	print("         ")
	term.setCursorPos(x / 2 - 4, y / 2)
	nameInput = read()
	addressInput = "nil"
	newGate = {name = nameInput, address = address, mode = security_none, id = -1}
	term.redirect(term.native())
	utils.clear()
	return newGate
end

function update()
	if (menu == "main") then
		drawPowerBar()
		drawTime()
	elseif (menu == "dial") then
		--drawBookmarksPage()
		updateBookmarksPage()
	elseif (menu == "history") then
		drawHistoryPage()
	elseif (menu == "security") then
		drawSecurityPageTop()
		drawSecurityPageBottom(settings.irisOnIncomingDial)
		--drawSecurityPageBottom(security_deny)
	end
end

function resetTimer()
	time = 1
	if (menu == "main") then
		time = 1
	elseif (menu == "dial" or menu == "history" or menu == "security") then
		time = 1
	else
		time = 1
	end
	timeout = os.startTimer(time)
end

function forceIrisState(draw)
	if (irisState == "Opened") then
		local ok = sg.openIris()
		if (ok == nil) then
			return nil
		end
		if (ok and draw) then
			drawIris(false)
			irisState = "Opened"
		end
		return ok
	else
		local ok = sg.closeIris()
		if (ok == nil) then
			return nil
		end
		if (ok and draw) then
			drawIris(true)
			irisState = "Closed"
		end
		return ok
	end
end

loadAll()

if (settings.irisOnIncomingDial == nil) then
	settings.irisOnIncomingDial = security_none
	saveSettings()
end
mon.setTextScale(1)
drawHome()
irisState = "Opened"
if (settings.irisState ~= nil and (settings.irisState == "Opened" or settings.irisState == "Closed")) then
	irisState = settings.irisState
end
forceIrisState(true)
resetTimer()
while true do
	local event, param1, param2, param3 = os.pullEvent()
	--print(event)
	if (event == "timer" and param1 == timeout) then
		update()
		resetTimer()
	elseif (event == "monitor_touch") then
		local x, y = mon.getSize()
		if (param2 >= 6 and param2 <= 8 and param3 >= y / 3 - 2 and param3 <= y / 3 * 2 + 1) then -- opens or closes the Iris
			if (sg.irisState() == "Closed") then
				local ok = sg.openIris()
				if (ok) then
					drawIris(false)
					irisState = "Opened"
				end
			else
				local ok = sg.closeIris()
				if (ok) then
					drawIris(true)
					irisState = "Closed"
				end
			end
			loadSettings()
			settings.irisState = irisState
			saveSettings()
			if (sg.stargateState() == "Connected") then
				sg.sendMessage(irisState)
			end
		elseif (param2 >= 2 and param2 <= 4 and param3 >= y / 3 - 2 and param3 <= y / 3 * 2 + 1) then -- click has opened the security menu
			menu = "security"
			local sOK = forceIrisState(false)
			if (sOK) then
				loadSettings()
				drawSecurityPageTop()
				drawSecurityPageBottom(settings.irisOnIncomingDial)
				--drawSecurityPageBottom(security_deny)
				while true do
					local event, param1, param2, param3 = os.pullEvent()
					if (event == "timer" and param1 == timeout) then
						update()
						resetTimer()
					elseif (event == "monitor_touch") then
						if (param3 >= y - 2) then -- checks if the user's touch is at the bottom of the screen with the buttons
							if (param2 >= x - 8) then -- "back" button has been pushed, returns user to home menu
								drawHome()
								break
							elseif (param2 < x - 6) then -- click has changed the global security type, cycles through "ALLOW OTHER", "DENY OTHER", "NONE"
								loadSettings()
								if (settings.irisOnIncomingDial == security_deny) then
									settings.irisOnIncomingDial = security_allow
								elseif (settings.irisOnIncomingDial == security_allow) then
									settings.irisOnIncomingDial = security_none			
								elseif (settings.irisOnIncomingDial == security_none) then
									settings.irisOnIncomingDial = security_deny
								end
								saveSettings()
							end
						elseif (param2 > x - 3) then -- delete record
							loadSecurity()
							table.remove(security, param3)
							saveSecurity()
							drawSecurityPageTop()
						elseif (param2 > x - 8 and param2 < x - 3) then -- click has changed the security type, cycles through "ALLOW", "DENY", "NONE"
							loadSecurity()
							for k, v in pairs(security) do
								if (k == param3) then
									if (v.mode == security_allow) then
										v.mode = security_deny
									elseif (v.mode == security_deny) then
										v.mode = security_none
									elseif (v.mode == security_none) then
										v.mode = security_allow
									end
								end
							end
							saveSecurity()
							drawSecurityPageTop()
							drawSecurityPageBottom(settings.irisOnIncomingDial)
							--drawSecurityPageBottom(security_deny)
						elseif (param3 < y - 2) then -- check if empty, if so add new entry
							loadSecurity()
							local gate = inputPage()
							gate.id = #security + 1
							table.insert(security, 1, gate)
							saveSecurity()
							drawSecurityPageTop()
							drawSecurityPageBottom(settings.irisOnIncomingDial)
							--drawSecurityPageBottom(security_deny)
						end
					elseif (event ~= "timer") then -- if an event that isn't a users touch happens the screen will return to the home screen (in case of incoming connection)
						drawHome()
						break
					end
				end
			end
			resetTimer()
		elseif (param2 > x / 2 - 5 and param2 <= x / 2 and param3 >= y - 3 and param3 <= y - 1) then -- click has opened dial menu
			menu = "dial"
			local status, int = sg.stargateState()
			if (status == "Idle") then
				drawBookmarksPage()
				while true do
					local event, param1, param2, param3 = os.pullEvent()
					if (event == "timer" and param1 == timeout) then
						update()
						resetTimer()
					elseif (event == "monitor_touch") then
						if (param3 >= y - 2) then -- user clicked back
							drawHome()
							break
						elseif (param2 > x - 2) then -- user clicked delete on a bookmark
							loadBookmarks()
							table.remove(bookmarks, utils.getTableIndexFromArray(bookmarks, param3, getId))
							saveBookmarks()
							drawBookmarksPage()
							resetTimer()
						else -- user has clicked on a bookmark
							loadBookmarks()
							local gate = utils.getTableFromArray(bookmarks, param3, getId)
							if (gate ~= nil) then
								drawHome() -- Changed energy checkup before dialing (by Panzer1119)
								local energyNeeded = sg.energyToDial(gate.address)
								local energyAvailable = sg.energyAvailable()
								if (energyNeeded > energyAvailable) then
									drawSgStatus("No Energy")
								else
									local ok, result = pcall(sg.dial, gate.address)
									if (ok) then
										local status, int = sg.stargateState()
										drawSgStatus(status)
										addToHistory(gate.address, false)
									else
										drawSgStatus("Error")
									end
								end
								break
							else
								gate = inputPage()
								gate.id = param3
								table.insert(bookmarks, 1, gate)
								saveBookmarks()
								drawBookmarksPage()
								resetTimer()
								break
							end
						end
					elseif (event ~= "timer") then
						drawHome()
						break
					end
				end
			end
			resetTimer()
		elseif (param2 > x - 7 and param2 < x - 4 and param3 >= y / 3 - 2 and param3 <= y / 3 * 2 + 1) then -- click has opened history menu
			menu = "history"
			drawHistoryPage()
			while true do
				local event, param1, param2, param3 = os.pullEvent()
				if (event == "timer" and param1 == timeout) then
					update()
					resetTimer()
				elseif (event == "monitor_touch") then
					if (param3 >= y - 2) then -- user clicked back
						drawHome()
						break -- might break everything
					elseif (param2 >= x / 2 + 7 and param2 <= x / 2 + 10 and param3 <= clickLimit) then -- user has clicked save.
						loadHistory()
						loadBookmarks()
						for i = 1, y do
							if (utils.getTableFromArray(bookmarks, i, getId) == nil) then
								local gate = historyInputPage(history.incoming[param3])
								gate.id = i
								table.insert(bookmarks, gate)
								saveBookmarks()
								break
							end
						end
					elseif (param2 >= x - 9 and param3 <= clickLimit) then -- user click "ban/allow"
						loadHistory()
						loadSecurity()
						local gate = historyInputPage(history.incoming[param3])
						gate.id = #security + 1
						table.insert(security, 1, gate)
						saveSecurity()
					end
					drawHome()
					break  
				end		
			end
			resetTimer()
		elseif (param2 > x / 2 + 2 and param2 <= x / 2 + 7 and param3 >= y - 3 and param3 <= y - 1) then -- user clicked TERM
			local ok, result = pcall(sg.disconnect)
			forceIrisState(true)
			drawChevrons()
		end
	elseif (event == "sgDialIn") then
		mon.setTextColor(colors.orange)
		drawRemoteAddress()
		alarmSet(true)
		loadSecurity()
		local gate = getGateByAddress(security, param2)
		if (gate ~= nil) then
			if (string.sub(gate.address, 1, 7) == param2 or gate.address == param2) then
				if (gate.mode == security_allow) then
					sg.openIris()
					drawIris(false)
				elseif (gate.mode == security_deny) then
					sg.closeIris()
					drawIris(true)
				elseif (gate.mode == security_none) then
					--[[
					-- gate mode overwrites global modes
					if (settings.irisOnIncomingDial == security_deny) then
						sg.closeIris()
						drawIris(true)
					elseif (settings.irisOnIncomingDial == security_allow) then
						sg.openIris()
						drawIris(false)
					end
					]]--
				end
			end
		else
			if (settings.irisOnIncomingDial == security_deny) then
				sg.closeIris()
				drawIris(true)
			elseif (settings.irisOnIncomingDial == security_allow) then
				sg.openIris()
				drawIris(false)
			end
		end
		addToHistory(param2, true)
	elseif (event == "sgMessageReceived") then
		--print("Message from " .. sg.remoteAddress() .. ": " .. param2)
		if (param2 == "Open" or param2 == "Opened") then
			mon.setTextColor(colors.lime)
			drawRemoteIris()
		elseif (param2 == "Closed") then
			mon.setTextColor(colors.red)
			drawRemoteIris()
		elseif (param2 == "irisState") then
			sg.sendMessage(sg.irisState())
		end
	elseif (event == "sgStargateStateChange" or event == "sgChevronEngaged") then
		drawDial()
		drawPowerBar()
		drawTerm()
		local status, int = sg.stargateState()
		drawSgStatus(tostring(status))
		if (status == "idle") then
			isConnected = false
		else
			isConnected = true
		end
		if (event == "sgChevronEngaged") then
			mon.setTextColor(colors.orange)
			drawChev({param2, param3})
			update()
			mon.setTextColor(colors.orange)
			if (param2 == 1) then
				dialling = {}
			end
			table.insert(dialling, param2, param3)
			drawRemoteAddress()
			resetTimer()
		elseif (param2 == "Idle") then
			alarmSet(false)
			forceIrisState(true)
			drawChevrons()
			resetTimer()
		elseif (param2 == "Connected") then
			alarmSet(false)
			mon.setTextColor(colors.lightBlue)
			drawRemoteAddress()
			for k, v in pairs(dialling) do
				drawChev({k, v})
			end
			sg.sendMessage(sg.irisState())
			resetTimer()
		end
	end
end
loadSettings()
settings.irisState = irisState
saveSettings()