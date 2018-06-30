os.loadAPI("lib/security.lua")
clients = {{id=11}}
sg = peripheral.find("stargate")
function getId(entry)
    return entry.id
end

filename_bookmarks = "stargate/bookmarks.lon"
filename_security = "stargate/security.lon"
filename_settings = "stargate/settings.lon"
filename_history = "stargate/history.lon"

-- ########## LOAD BEGIN

function loadBookmarks()
	if (not fs.exists(filename_bookmarks)) then
		saveBookmarks({})
	end
	return utils.readTableFromFile(filename_bookmarks)
end

function loadSecurity()
	if (not fs.exists(filename_security)) then
		saveSecurity({})
	end
	return utils.readTableFromFile(filename_security)
end

function loadSettings()
	if (not fs.exists(filename_settings)) then		
		saveSettings({irisState = "Opened", irisOnIncomingDial = security_none, alarmOutputSides = {}, maxEnergy = 50000})
	end
	return utils.readTableFromFile(filename_settings)
end

function loadHistory()
	if (not fs.exists(filename_history)) then
		saveHistory({incoming = {}, outgoing = {}})
	end
	return utils.readTableFromFile(filename_history)
end

-- ########## LOAD END
-- ########## SAVE BEGIN

function saveBookmarks(bookmarks)
	utils.writeTableToFile(filename_bookmarks, bookmarks)
end

function saveSecurity(security)
	utils.writeTableToFile(filename_security, security)
end

function saveSettings(settings)
	utils.writeTableToFile(filename_settings, settings)
end

function saveHistory(history)
	utils.writeTableToFile(filename_history, history)
end

-- ########## SAVE END


side = "front"
rednet.open(side)
while true do
    local sid, msg, ptc = rednet.receive("stargate")
    local client = utils.getTableFromArray(clients, sid, getId)
    --print("Client: " .. sid)
    if (client ~= nil) then
        if (msg.call == "stargateState") then
            sleep(0.05)
            rednet.send(sid, sg.stargateState(), ptc)
        elseif (msg.call == "energyAvailable") then
            sleep(0.05)
            rednet.send(sid, sg.energyAvailable(), ptc)
        elseif (msg.call == "energyToDial") then
            sleep(0.05)
            rednet.send(sid, sg.energyToDial(msg.args), ptc)
        elseif (msg.call == "localAddress") then
            sleep(0.05)
            rednet.send(sid, sg.localAddress(), ptc)
        elseif (msg.call == "remoteAddress") then
            sleep(0.05)
            rednet.send(sid, sg.remoteAddress(), ptc)
        elseif (msg.call == "dial") then
            sleep(0.05)
            rednet.send(sid, sg.dial(msg.args), ptc)
        elseif (msg.call == "disconnect") then
            sleep(0.05)
            rednet.send(sid, sg.disconnect(), ptc)
        elseif (msg.call == "irisState") then
            sleep(0.05)
            rednet.send(sid, sg.irisState(), ptc)
        elseif (msg.call == "closeIris") then
            sleep(0.05)
            rednet.send(sid, sg.closeIris(), ptc)
        elseif (msg.call == "openIris") then
            sleep(0.05)
            rednet.send(sid, sg.openIris(), ptc)
        elseif (msg.call == "sendMessage") then
            sleep(0.05)
            rednet.send(sid, sg.sendMessage(msg.args), ptc)
        elseif (msg.call == "loadBookmarks") then
            sleep(0.05)
            rednet.send(sid, loadBookmarks(), ptc)
        elseif (msg.call == "loadSecurity") then
            sleep(0.05)
            rednet.send(sid, loadSecurity(), ptc)
        elseif (msg.call == "loadSettings") then
            sleep(0.05)
            rednet.send(sid, loadSettings(), ptc)
        elseif (msg.call == "loadHistory") then
            sleep(0.05)
            rednet.send(sid, loadHistory(), ptc)
        elseif (msg.call == "saveBookmarks") then
            sleep(0.05)
            rednet.send(sid, saveBookmarks(msg.args), ptc)
        elseif (msg.call == "saveSecurity") then
            sleep(0.05)
            rednet.send(sid, saveSecurity(msg.args), ptc)
        elseif (msg.call == "saveSettings") then
            sleep(0.05)
            rednet.send(sid, saveSettings(msg.args), ptc)
        elseif (msg.call == "saveHistory") then
            sleep(0.05)
            rednet.send(sid, saveHistory(msg.args), ptc)
        else
            --print("Call is invalid!")
            sleep(0.05)
            rednet.send(sid, nil, ptc)
        end
    else
        --print("Client is not allowed!")
        sleep(0.05)
        rednet.send(sid, nil, ptc)
    end
end
rednet.close(side)