--[[

  Author: Panzer1119
  
  Date: Edited 08 Jul 2019 - 06:44 PM
  
  Original Source: https://github.com/Panzer1119/CCStargate/blob/master/stargate_control_new.lua
  
  Direct Download: https://raw.githubusercontent.com/Panzer1119/CCStargate/master/stargate_control_new.lua

]]--

os.loadAPI("lib/utils.lua")

PROGRAM_NAME = "Stargate Control"
PROGRAM_NAME_SHORT = "SG Control"

sg = peripheral.find("stargate")
mon = peripheral.find("monitor")

MON_WIDTH = 50
MON_HEIGHT = 26

width, height = mon.getSize()

if (width ~= MON_WIDTH) then
	error("Monitor size does not match the requirements! (width is " .. width .. ", but should be " .. MON_WIDTH .. ")")
end
if (height ~= MON_HEIGHT) then
	error("Monitor size does not match the requirements! (height is " .. height .. ", but should be " .. MON_HEIGHT .. ")")
end

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
