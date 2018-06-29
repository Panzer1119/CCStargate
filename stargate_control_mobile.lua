--[[

  Author: Panzer1119
  
  Date: Edited 30 Jun 2018 - 00:09 AM
  
  Original Source: https://github.com/Panzer1119/CCStargate/blob/master/stargate_control_mobile.lua
  
  Direct Download: https://raw.githubusercontent.com/Panzer1119/CCStargate/master/stargate_control_mobile.lua

]]--

os.loadAPI("lib/security.lua")
x, y = term.getSize() -- Pocket Computers are always x=26 and y=20

sg = {	energyAvailable=function() return (50000 * (5/7)) end,
		localAddress=function() return "DLDBTG5IB" end,
		irisState=function() return "Offline" end,
		stargateState=function() return "Idle" end
	}

menu_main = "main"
menu = nil

bookmarks = {}
security = {}
settings = {irisState = "Opened", irisOnIncomingDial = security_none, alarmOutputSides = {}, maxEnergy = 50000}
history = {incoming = {}, outgoing = {}}

--filename_bookmarks = "stargate/bookmarks.lon"
--filename_security = "stargate/security.lon"
--filename_settings = "stargate/settings.lon"
--filename_history = "stargate/history.lon"

security_allow = "ALLOW"
security_deny = "DENY"
security_none = "NONE"

-- ########## LOAD BEGIN

function loadBookmarks()

end

function loadSecurity()

end

function loadSettings()

end

function loadHistory()

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

end

function saveSecurity()

end

function saveSettings()

end

function saveHistory()

end

function saveAll()
	saveBookmarks()
	saveSecurity()
	saveSettings()
	saveHistory()
end

-- ########## SAVE END

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
	return history == nil or #history == 0 or ((history.incoming == nil or #history.incoming == 0) and (history.outgoing == nil or #history.outgoing == 0))
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

--------- Iris Functions END

function drawMenu(menu_)
	if (menu_ == menu_main) then
		drawMainPage()
	end
end

------------------ Main Page START

function drawMainPage(address)
	drawTime()
	drawLocalAddress()
	drawPowerBar()
	drawDefenseButton()
	drawIrisButton()
	drawStargate(address)
	drawHistoryButton()
	drawCopyRight()
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
	term.write(sg.localAddress())
end

function drawPowerBar()
	loadSettings()
	local energyAvailable = sg.energyAvailable()
	local energyPercent = (energyAvailable / ((settings.maxEnergy == nil and 50000 or settings.maxEnergy) + 1)) * 100
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
	if (not hasIris()) then
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

function drawIrisButton()
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.black)
	if (not hasIris()) then
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

function drawCopyRight()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.gray)
	term.setCursorPos(1, y)
	term.write("Panzer1119")
end

function drawDialButton()
	local state, engaged, direction = sg.stargateState()
	term.setBackgroundColor(colors.lightGray)
	if (state ~= "Idle") then
		term.setBackgroundColor(colors.gray)
	end
	term.setTextColor(colors.black)
	for yc = (y - 4), (y - 2) do
		term.setCursorPos(x / 2 - 5, yc)
		term.write("      ")
	end
	term.setTextColor(colors.black)
	term.setCursorPos(x / 2 - 4, y - 3)
	term.write("DIAL")
end

function drawTermButton()
	local state, engaged, direction = sg.stargateState()
	term.setBackgroundColor(colors.gray)
	if (state == "Connected" or state == "Connecting" or state == "Dialling") then
		term.setBackgroundColor(colors.lightGray)
	end
	term.setTextColor(colors.black)
	for yc = (y - 4), (y - 2) do
		term.setCursorPos(x / 2 + 2, yc)
		term.write("      ")
	end
	term.setTextColor(colors.black)
	term.setCursorPos(x / 2 + 3, y - 3)
	term.write("TERM")
end

------------------ Main Page END



-- ######### Test
term.clear()
drawMenu(menu_main)
term.setCursorPos(1, y)