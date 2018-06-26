--[[
  Author: Panzer1119
  
  Date: Edited 26 Jun 2018 - 04:07 PM
  
  Original Source: https://github.com/Panzer1119/CCStargate/blob/master/install.lua
  
  Direct Download: https://raw.githubusercontent.com/Panzer1119/CCStargate/master/install.lua
]]--

args = {...}

filename_files = "downloads/files.lon"
print("Downloading " .. filename_files)
fs.delete(filename_files)
shell.run("wget https://raw.githubusercontent.com/Panzer1119/CCStargate/master/files.lon " .. filename_files)

local f = fs.open(filename_files, "r")
files = textutils.unserialise(f.readAll())
f.close()

overwrite = false

if (#args >= 1) then
	if (args[1] == "yes") then
		overwrite = true
	end
end

installed = true

for i = 1, #files do
	print("")
	local download = true
	local file = files[i]
	if (file == nil or file.name == nil or file.path == nil or file.url == nil) then
		print("Error with a file!")
	else
		if (fs.exists(file.path)) then
			local input = nil
			if (not overwrite) then
				download = false
				print(file.name .. " is already installed,")
				write("do you want to update it? (Y/n): ")
				input = read()
			end
			if (overwrite or input == "Y") then
				fs.delete(file.path)
				download = true
			end
		end
		if (download) then
			print("Downloading " .. file.name .. " to " .. file.path .. "...")
			shell.run("wget " .. file.url .. " " .. file.path)
			if not (fs.exists(file.path)) then
				installed = false
			end
		end
	end
end

if (installed) then
	print("")
	print("")
	print("Installation was successful, do you want to")
	print("delete the cache and installation files?")
	write("(the installation file can be used to update the library) (yes/n): ")
	local input = read()
	if (input == "yes") then
		fs.delete(filename_files)
		fs.delete(shell.getRunningProgram())
	end
else
	print("")
	print("")
	print("Some files failed and could not be installed,")
	write("do you want to try it again? (yes/n): ")
	local input = read()
	if (input == "yes") then
		if (overwrite) then
			shell.run(shell.getRunningProgram() .. " yes")
		else
			shell.run(shell.getRunningProgram())
		end
	end
end
