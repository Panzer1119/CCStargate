--[[

  Author: Panzer1119
  
  Date: Edited 08 Jul 2019 - 09:07 PM
  
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

if (width ~= MON_WIDTH) then
	error("Monitor size does not match the requirements! (width is " .. width .. ", but should be " .. MON_WIDTH .. ")")
end
if (height ~= MON_HEIGHT) then
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

-- Misc END

stargates = {}
history = {}
settings = {} -- TODO!!!

folder_stargate = "stargate"
file_stargates = folder_stargate .. "/stargates.lon"
file_history = folder_stargate .. "/history.lon"

security_allow = "ALLOW"
security_deny = "DENY"
security_none = "NONE"

-- ###### LOAD BEGIN

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
	loadStargates()
	loadHistory()
end

-- ###### LOAD END

-- ###### SAVE BEGIN

function saveStargates()
	utils.writeTableToFile(file_stargates, stargates)
end

function saveHistory()
	utils.writeTableToFile(file_history, history)
end

function saveAll()
	saveStargates()
	saveHistory()
end

-- ###### SAVE END

-- ### Iris Functions BEGIN

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

function drawMenu(menu_to_draw, clear, color_back)
	if (clear or menu ~= menu_to_draw) then
		term.setBackgroundColor(color_back and color_back or colors.black)
		term.clear()
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

function repaintMenu(clear, color_back)
	drawMenu(menu, clear, color_back)
end


-- #### Header BEGIN

function drawHeader(color_back, color_text)
	color_back = color_back and color_back or colors.black
	color_text = color_text and color_text or colors.white
	mon.setBackgroundColor(color_back)
	mon.setTextColor(color_text)
	drawTime()
end

function drawTime()
	
end

-- #### Header EMD

-- #### Main Menu BEGIN

function drawMainMenu()
	drawHeader()
end

-- #### Main Menu END
