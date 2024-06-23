
--[[

8888888888                d8b                   
888                       Y8P                   
888                                             
8888888 888  888 .d8888b  888  .d88b.  88888b.  
888     888  888 88K      888 d88""88b 888 "88b 
888     888  888 "Y8888b. 888 888  888 888  888 
888     Y88b 888      X88 888 Y88..88P 888  888 
888      "Y88888  88888P' 888  "Y88P"  888  888 
                                                
]]


-- These are three security clearance levels we want to create
local external          = {} -- Functions accessable to every server script
local internal          = {} -- Functions accessable only within Fusion's core, these are the most sensitive functions.
local console           = {} -- Functions accessable by apps compatible with Fusion, only after they 

local RunService = game:GetService("RunService")

-- Protected internal registry 
internal.LogEntries     = {}
internal.AppDataStorage = {}
internal.AppKeys        = {}
internal.AppInst        = {}
internal.APITable		= {}
internal.AppLibs        = {}
internal.AppNames		= {}
internal.OneTimeKeys	= {}
internal.DriverNames    = {}
internal.RequestTimeout = 10 -- Time in seconds to wait before allowing another request from the same app
internal.KeyValPeriod   = 30 -- Time in seconds for which a one-time key is valid
internal.Version 		= "1.0"

internal.AllowedDrivers = {
	"drivertest"
}

internal.FlagConfiguration = {
	AllowInsecureConnections = true; -- By default, only apps inside the Fusion security network can utilize each other. Setting this to false will allow app functions to be used from any Script	
}


-- Function to verify the app's key before providing access to console functions
function internal:AppFgpt(CondensedData)
	local ModeLogic = {
		GNFK = function() -- Get Name From Key 
			local Key = CondensedData.Key 

			for Name, AppKey in pairs(internal.AppKeys) do
				wait() -- Update this for custom heartbeat in future 
				if AppKey == Key then 
					return Name 
				end
			end
			return nil
		end,

		GKFN = function() -- Get Key From Name
			return internal.AppKeys[CondensedData.Name] 
		end,

		GFDT = function() 

			local FunctionString = CondensedData.FcnName 

			if internal.APITable[FunctionString] then  -- 
				return internal.APITable[FunctionString]
			end

		end,

	}

	-- Checking for proper input!
	if not CondensedData or not (type(CondensedData)=="table") or not (CondensedData.Mode) then return end 

	local AppKey = CondensedData.Key
	local AppName = CondensedData.Name
	local Mode = CondensedData.Mode 

	if ModeLogic[Mode] then 
		return ModeLogic[Mode]()
	else
		error("Fatal internal:AppFgpt() failure: Incorrect ModeLogic")
	end

end

function internal:VerifyDriver()
	return true 
end

function internal:ForceAppName(Key)
	for AppName, intKey in pairs (internal.AppKeys) do
		if intKey == Key then 
			return AppName
		end
	end
	return nil
end

function internal:ValidateVersionString(str)
	-- Condense the string to no more than 5 characters
	local condensedStr = string.sub(str, 1, 5)

	-- Initialize a counter for lowercase letters
	local lowerCaseCount = 0

	-- Check each character to ensure it's a number, period, or one lowercase letter
	for i = 1, #condensedStr do
		local char = string.sub(condensedStr, i, i)
		if char:match("%l") then
			lowerCaseCount = lowerCaseCount + 1
			-- If more than one lowercase letter is found, return false
			if lowerCaseCount > 1 then
				return false
			end
		elseif not (char:match("%d") or char == ".") then
			return false
		end
	end

	return condensedStr
end

-- Function to write log entries
function console:Write(Key, ...)

	-- Check if the key is the framework's internal self-sign key
	local AppName = "Unknown"
	if Key == internal.SelfSign then
		-- Process the rest of the parameters as before
		AppName = script.Name
		-- ...
	else
		-- The message is from an app, find the app name using the key
		AppName = internal:AppFgpt({
			Mode = "GNFK"; 
			Key = Key
		})

		-- If no app is found, the key is invalid
		if AppName == "Unknown" then
			return
		end
	end

	-- Convert all additional parameters to strings and concatenate them
	local MessageParts = {...}
	for i, v in ipairs(MessageParts) do
		MessageParts[i] = tostring(v)
	end
	local Message = table.concat(MessageParts, " ")

	-- Create the log entry
	local LogEntry = "[F🔒][" .. console:GetPlatform() .. "][" .. (AppName or "???" ) .. "]: " .. tostring(Message)
	warn(LogEntry) -- Improve in future, but this just prints framwework output to the Roblox output

	-- Prepend the new log entry to ensure newer first
	table.insert(internal.LogEntries, 1, LogEntry)

	-- Return the updated log entries tables
	return internal.LogEntries 
end


-- This simple function returns the table, it is up to the calling function to save this properly. 
function console:GenerateKey(ForcedKeyLength, ForcedTimeout)
	-- Initialize an empty Key string
	local Key = ""
	-- Table to keep track of used Keys to ensure uniqueness
	local UsedKeys = internal.UsedKeys or {}

	-- Record the start time for the Timeout feature
	local StartTime = os.time()

	-- Define the Timeout duration in seconds. We want 10 seconds to be the default, unless overridden
	local Timeout = (ForcedTimeout or 10)

	-- Local variable for us to make some modifications to the key length if needed. 
	-- We don't want keys to be generated that are under 16 characters, as this can pose security risk and memory errors.
	local KeyLength = (ForcedKeyLength or 16)

	-- Now let's verify that we aren't be asked to generate keys that are too short!
	if not (type(ForcedKeyLength) == "number") or not (ForcedKeyLength >= 16) or ((ForcedKeyLength or ForcedTimeout) > 128)  then 
		-- Fix the key length, and also notify the user with a warning.
		KeyLength = 16 
		Timeout = 10
		--console:Write(internal.SelfSign,"Warning: Attempted to call internal function GenerateKey() with invalid parameters. We let the function through, but we had to override the parameters with default values. ")
	end

	-- Local function for first-time setup only
	-- Function to generate a table of all alphanumeric characters and symbols
	local function GenerateAlphanumericAndSymbolsTable()
		local chars = {}
		-- Add numeric characters (0-9)
		for i = 48, 57 do table.insert(chars, string.char(i)) end
		-- Add uppercase letters (A-Z)
		for i = 65, 90 do table.insert(chars, string.char(i)) end
		-- Add lowercase letters (a-z)
		for i = 97, 122 do table.insert(chars, string.char(i)) end
		-- Add common symbols
		for i = 32, 47 do table.insert(chars, string.char(i)) end -- Space and punctuation
		for i = 58, 64 do table.insert(chars, string.char(i)) end -- Special characters
		for i = 91, 96 do table.insert(chars, string.char(i)) end -- Brackets and caret
		for i = 123, 126 do table.insert(chars, string.char(i)) end -- Braces and tilde
				
		return chars
	end

	-- Generate the CharsTable if it does not exist yet
	if not (type(internal.CharsTable)=="table") then 
		local Generation = GenerateAlphanumericAndSymbolsTable()
		internal.CharsTable = Generation -- Save to our internal table
	end

	-- Inner function to attempt Key generation
	local function TryGenerateKey()
		repeat
			-- Reset Key to an empty string for each attempt
			Key = ""
			-- Build the Key character by character
			for i = 1, KeyLength do
				-- Randomly select an index from the charsTable
				local RandIndex = math.random(#internal.CharsTable)
				-- Append the character at the random index to the Key
				Key = Key .. internal.CharsTable[RandIndex]
			end
			-- Check if the elapsed time has exceeded the Timeout duration
			if os.difftime(os.time(), StartTime) > Timeout then
				-- If Timeout is reached, print a message and return nil
				console:Write(internal.SelfSign,"Fatal Error: Fusion is unable to generate new keys into memory. System needs to shut down.")
				return nil
			end
			-- Yield the coroutine with the current Key
			coroutine.yield(Key)
			-- Continue generating Keys until a unique one is found. We want to add a wait() statement to prevent rare crashes.
			wait()
		until not UsedKeys[Key]
		-- Once a unique Key is found, mark it as used
		UsedKeys[Key] = true
		-- Return the unique Key
		return Key
	end

	-- Create a coroutine with the inner function
	local co = coroutine.create(TryGenerateKey)
	-- Variables to store the status and result of the coroutine
	local status, result
	repeat
		-- Resume the coroutine and capture its status and result
		status, result = coroutine.resume(co)
		-- Continue until the coroutine finishes or a result is obtained
	until status == false or result ~= nil

	-- Return the result, which is either a unique Key or nil if Timeout was reached
	return result
end

internal.SelfSign = console:GenerateKey()

-- Function for apps to terminate their one-time keys using their real key
function console:TerminateOneTimeKeys(AppRealKey, SpecificKey)
	-- Verify that the request is coming from the app itself
	if internal.AppInst[AppRealKey] ~= script then
		-- Future logic for security software 
	end

	if SpecificKey then
		-- Terminate a specific key
		if internal.OneTimeKeys[SpecificKey] == internal.AppInst[AppRealKey] then
			internal.OneTimeKeys[SpecificKey] = nil
		end
	else
		-- Terminate all keys for the app
		for Key, AppInstance in pairs(internal.OneTimeKeys) do
			if AppInstance == internal.AppInst[AppRealKey] then
				internal.OneTimeKeys[Key] = nil
			end
		end
	end
end

-- Function to get the current platform/environment
function console:GetPlatform()
	if RunService:IsStudio() then
		if RunService:IsClient() then
			return "Local"
		elseif RunService:IsServer() then
			return "Server"
		end
	elseif RunService:IsRunMode() then
		return "Plugin"
	else
		-- Default to 'N/A' if none of the conditions match
		-- This is a safeguard and should not typically occur
		return "N/A"
	end
end

-- Function to generate a one-time key for an app using its real key
function console:GenerateOneTimeKey(AppRealKey)

	internal.LastRequestTime = internal.LastRequestTime or {}

	-- Check for rate limiting
	if internal.LastRequestTime[AppRealKey] and os.time() - internal.LastRequestTime[AppRealKey] < internal.RequestTimeout then
		internal:Write(internal.SelfSign, "Request limit exceeded. Please wait before requesting another key.")
	end

	-- Generate a unique one-time key
	local OneTimeKey = "OTK-S"..console.GenerateKey()

	-- Store the one-time key with its associated app instance temporarily
	internal.OneTimeKeys[OneTimeKey] = internal.AppInst[AppRealKey]
	internal.LastRequestTime[AppRealKey] = os.time()

	-- Set a timer to invalidate the one-time key after a short period
	delay(internal.KeyValPeriod, function()
		internal.OneTimeKeys[OneTimeKey] = nil
	end)

	return OneTimeKey
end

-- Function to set data for an app
function console:BitSet(Key, ValName, Val)
	-- Verify the app's key
	local AppName = "Unknown"
	for name, data in pairs(internal.AppKeys) do
		if data == Key then
			AppName = name
			break
		end
	end
	if AppName == "Unknown" then
		return nil
	end

	-- Initialize the scope for the app if it doesn't exist
	internal.AppDataStorage[AppName] = internal.AppDataStorage[AppName] or {}
	internal.AppDataStorage[AppName][ValName] = internal.AppDataStorage[AppName][ValName] or 0

	-- Set the value
	internal.AppDataStorage[AppName][ValName] = Val

	return true
end

-- Function to get data for an app
function console:BitGet(Key, ValName)
	-- Verify the app's key
	local AppName = "Unknown"
	for name, data in pairs(internal.AppKeys) do
		if data == Key then
			AppName = name
			break
		end
	end
	if AppName == "Unknown" then
		return nil
	end

	-- Retrieve the value
	if internal.AppDataStorage[AppName][ValName] then
		return internal.AppDataStorage[AppName][ValName]
	else
		-- Return nil if the value doesn't exist
		return nil
	end
end

-- Function to authenticate an app and provide it with a unique key and console table
function external:Authenticate(App, AppData)
	-- Validate the version string of the app
	local ValVS = internal:ValidateVersionString(AppData.Version)

	-- Check if the AppData is valid
	if typeof(AppData) == "table" and AppData.Version and ValVS and AppData.Description and AppData.API and App then
		local AppAPI = AppData.API

		-- Generate a unique key for the app
		local key = console:GenerateKey()

		-- Store the key, app instance, and API in the internal tables
		internal.AppKeys[App.Name] = key
		internal.AppInst[key] = App
		internal.AppLibs[key] = AppData.API
		internal.AppNames[key] = App.Name -- Add the app name to AppNames

		-- Create an API package for the app
		local APIPackage = {
			Key = key,
			AppAPI = console,
			External = external
		}

		-- Process all the app API's for our central table 
		local Incompatibility = false
		local NameOfConflict
		for FcnName, Fcn in pairs(AppAPI)  do
			-- Check if the function name is already in use
			if not (internal.APITable[FcnName]) then 
				-- If not, add it to the table
				internal.APITable[FcnName] = Fcn 
			else
				-- If it is, mark as incompatible and store the conflicting name
				Incompatibility = true 
				NameOfConflict = FcnName 
			end
		end

		-- If there was a function name conflict, write an error message and return
		if Incompatibility then 
			console:Write(internal.SelfSign, "Launch of '"..App.Name.."-"..string.lower(console:GetPlatform()).."' failed because of a duplicated function compatibility error. Function name: "..tostring(NameOfConflict))
			return
		end

		-- Write a success message and return the API package
		console:Write(internal.SelfSign, "Launched app: '"..AppData.FriendlyName.." ["..string.lower(App.Name).."-".. string.lower(console:GetPlatform()) .."]' v"..tostring(ValVS))
		return APIPackage
	else
		-- If the AppData was not valid, write an error message and return nil
		console:Write(internal.SelfSign, "Launch of '"..App.Name.."-"..string.lower(console:GetPlatform()).."' has been blocked because of compatibility errors.")
		return nil
	end
end

-- Function to authenticate a driver and provide it with a unique key, console table, and internal access
function external:AuthenticateDriver(Driver, DriverData)
	-- Validate the version string of the driver
	local ValVS = internal:ValidateVersionString(DriverData.Version)

	-- Check if the DriverData is valid
	if typeof(DriverData) == "table" and DriverData.Version and ValVS and DriverData.Description and DriverData.API and Driver then
		local DriverAPI = DriverData.API

		-- Check if the driver is in the whitelist
		local isWhitelisted = false
		for _, whitelistedDriver in ipairs(internal.AllowedDrivers) do
			if Driver.Name == whitelistedDriver then
				isWhitelisted = true
				break
			end
		end
		if not isWhitelisted then
			error("Failed to authenticate driver due to whitelist check failure.")
			return
		end

		-- Generate a unique key for the driver
		local key = console:GenerateKey()

		-- Store the key, driver instance, and API in the internal tables
		internal.AppKeys[Driver.Name] = key
		internal.AppInst[key] = Driver
		internal.AppLibs[key] = DriverData.API
		internal.DriverNames[key] = Driver.Name -- Add the driver name to DriverNames

		-- Create an API package for the driver
		local APIPackage = {
			Key = key,
			AppAPI = console,
			External = external,
			Internal = internal -- Provide internal access
		}

		-- Process all the driver API's for our central table 
		local Incompatibility = false
		local NameOfConflict
		for FcnName, Fcn in pairs(DriverAPI)  do
			-- Check if the function name is already in use
			if not (internal.APITable[FcnName]) then 
				-- If not, add it to the table
				internal.APITable[FcnName] = Fcn 
			else
				-- If it is, mark as incompatible and store the conflicting name
				Incompatibility = true 
				NameOfConflict = FcnName 
			end
		end

		-- If there was a function name conflict, write an error message and return
		if Incompatibility then 
			console:Write(internal.SelfSign, "Launch of '"..Driver.Name.."-"..string.lower(console:GetPlatform()).."' failed because of a duplicated function compatibility error. Function name: "..tostring(NameOfConflict))
			return
		end

		-- Write a success message and return the API package
		console:Write(internal.SelfSign, "Launched driver: '"..DriverData.FriendlyName.." ["..string.lower(Driver.Name).."-".. string.lower(console:GetPlatform()) .."]' v"..tostring(ValVS))
		return APIPackage
	else
		-- If the DriverData was not valid, write an error message and return nil
		console:Write(internal.SelfSign, "Launch of '"..Driver.Name.."-"..string.lower(console:GetPlatform()).."' has been blocked because of compatibility errors.")
		return nil
	end
end

-- Function to get a list of all driver names
function external:GetDriverNames()
	local driverNames = {}
	for _, name in pairs(internal.DriverNames) do
		table.insert(driverNames, name)
	end
	return driverNames
end

-- Function to get a list of all app names
function external:GetAppNames()
	local appNames = {}
	for _, name in pairs(internal.AppNames) do
		table.insert(appNames, name)
	end
	return appNames
end


-- Function to verify the identity of an app using a one-time key
function external:VerifyIdentity(OneTimeKey)
	-- Retrieve the app instance using the one-time key
	local AppInstance = internal.OneTimeKeys[OneTimeKey]

	-- Check if the one-time key is valid
	if AppInstance and (string.sub(OneTimeKey, 1, 5) == "OTK-S") then
		-- Invalidate the one-time key
		internal.OneTimeKeys[OneTimeKey] = nil
		-- Return the app instance associated with the one-time key
		return AppInstance
	else
		-- The key is invalid or has expired
		return false, "Invalid or expired one-time key."
	end
end

-- This is our ProcessFcn() 
function internal:ProcessFcn(PrivateKey, ...)
	-- Collect all arguments into a table
	local Arguments = {...}
	local FunctionString = Arguments[1]

	-- Let's kill any spam 
	if not PrivateKey or not FunctionString then return nil end

	-- Let's verify that they are in the Fusion network 
	local AppName = internal:AppFgpt({Key = PrivateKey;Mode = "GNFK";})
	if not AppName then console:Write(internal.SelfSign, "Error1 in ProcessFcn() core module") return nil end 

	-- Grab the actual function from our preprocessed dictionary 
	local Fcn = internal.APITable[FunctionString]
	if not Fcn then console:Write(internal.SelfSign, "Error2 in ProcessFcn() core module") return nil  end

	-- Unpack the arguments when calling the function
	return Fcn(unpack(Arguments))
end

-- Function to call ProcessFcn() with the provided private key and arguments
function external:Fcn(PrivateKey,...)
	return internal:ProcessFcn(PrivateKey, ...)
end

-- Function to call ProcessFcn() asynchronously with the provided private key and arguments
function external:FcnAsync(PrivateKey, ...)
	local Attachments = {...}
	spawn(function()
		internal:ProcessFcn(PrivateKey, unpack(Attachments))
	end)
end

-- Short form function names for ease of scripting
function external:f(PrivateKey,...)
	return internal:ProcessFcn(PrivateKey, ...)
end

function external:fa(PrivateKey, ...)
	local Attachments = {...}
	spawn(function()
		internal:ProcessFcn(PrivateKey, unpack(Attachments))
	end)
end

return external
