
--[[

 ______      _            
(_____ \    (_)           
 _____) )___ _  ___ ____  
|  ____/ ___) |/___)    \ 
| |   | |   | |___ | | | |
|_|   |_|   |_(___/|_|_|_|
An open-source project.
                                                
]]


-- These are three security clearance levels we want to create
local PrismExt  = {} -- Functions accessable to every server script
local PrismCore = {} -- Functions accessable only within Prism's core, these are the most sensitive functions.
local SharedAPI = {} -- Functions accessable by apps compatible with Prism, only after they 

-- These tables are used for indexing apps throughout the framework. 
-- This speeds up a lot of the internal functions by preventing repeated processing each cycle 
local AppStrToKey  = {} -- [App Name]    = Private Key (string)
local KeyToAppInst = {} -- [Private Key] = App Instance (script)
local KeyToAppAPI  = {} -- [Private Key] = App's shared API (table)
local KeyToAppStr  = {} -- [Private Key] = App Name (string)

-- These are protected variables, that cannot be accessed from anything except Prism. 
-- Please note: in client environments, this data can still be accessed through external software
local PrismVersion    = "1.2"
local PrismMemory     = {} -- We are using this table to store data that apps are exchanging with Prism
local AllAppFunctions = {} -- This table contains all gathered API functions from installed apps

-- This is where we can add drivers, just like this {"driver1"} or {"driver1","driver2"}
-- Drivers have enhanced access to live Prism systems. They can read and modify any PrismCore object.
-- Only whitelist drivers you trust!
local WhitelistedDrivers = {}

-- Roblox API's 
PrismCore.Run = game:GetService("RunService")

PrismCore.Terminal                      = {} -- This is a table that stores all output messages from applications. Only accessable by drivers/internally.
PrismCore.ProdProducedInstances         = {} -- This table stores all instances produces by the Prod() function. Only accessable by drivers/internally.
PrismCore.FunctionExecutionsOnHeartbeat = {} -- Every function in this table is executed on each heartbeat. Only accessable by drivers/internally.

-- DEPRECATED //////////////////////////////

PrismCore.ActiveOneTimeKeys                             = {} -- This is stored one-time-keys generated by applications. | Warning: Accessable by drivers
PrismCore.OneTimeKeySystem_RequestTimeout               = 10 -- Time in seconds to wait before allowing another request from the same app. | Warning: Accessable by drivers
PrismCore.OneTimeKeySystem_KeyValidationPeriodInSeconds = 30 -- Time in seconds for which a one-time key is valid. | Warning: Accessable by drivers

-- Convert legacy data points from drivers designed for Prism v1.1
PrismCore.LogEntries        = PrismCore.Terminal
PrismCore.OneTimeKeys       = PrismCore.ActiveOneTimeKeys
PrismCore.ProducedInstances = PrismCore.ProdProducedInstances
PrismCore.RequestTimeout    = PrismCore.OneTimeKeySystem_RequestTimeout
PrismCore.KeyValPeriod      = PrismCore.OneTimeKeySystem_KeyValidationPeriodInSeconds
PrismCore.HeartBeatFcns     = PrismCore.FunctionExecutionsOnHeartbeat


-- ////////////////////////////////////////


PrismCore.Flags = {
	AllowInsecureConnections = false; -- By default, only apps inside the Prism security network can utilize each other. Setting this to false will allow app functions to be used from any Script
	CustomHeartBeatThrottle = nil; -- This allows you to set a custom throttle in seconds to the heartbeat function, yielding the entire Prism framework
}

local function wr(...)
	SharedAPI:Write(PrismCore.SelfSign, ...)
end

-- Function to verify the app's key before providing access to SharedAPI functions
function PrismCore:AppFgpt(CondensedData)
	local ModeLogic = {
		GNFK = function() -- Get Name From Key 
			local Key = CondensedData.Key 

			for Name, AppKey in pairs(AppStrToKey) do
				wait() -- Update this for custom heartbeat in future 
				if AppKey == Key then 
					return Name 
				end
			end
			return nil
		end,

		GKFN = function() -- Get Key From Name
			return AppStrToKey[CondensedData.Name] 
		end,

		GFDT = function() 

			local FunctionString = CondensedData.FcnName 

			if AllAppFunctions[FunctionString] then  -- 
				return AllAppFunctions[FunctionString]
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
		error("Fatal PrismCore:AppFgpt() failure: Incorrect ModeLogic")
	end
end

function SharedAPI:CheckDepends(data, entity)
	for _, dependency in ipairs(data) do
		-- Check if the dependency is not loaded
		local dependencyFound = false
		local startTime = os.time()
		while not dependencyFound and os.difftime(os.time(), startTime) <= 10 do
			for _, appName in pairs(KeyToAppStr) do
				if appName == dependency then
					dependencyFound = true
					break
				end
			end
			if not dependencyFound then
				wait(1) -- Wait for 1 second before checking again
			else
			end
		end

		if not dependencyFound then
			return false, tostring(dependency)
		end
	end
	return true
end

function PrismCore:HeartBeat(...)
	for _, func in pairs(PrismCore.FunctionExecutionsOnHeartbeat) do
		if PrismCore.Flags.CustomHeartBeatThrottle then
			wait(PrismCore.Flags.CustomHeartBeatThrottle)
		end
		func({...})
	end
end

function PrismCore:ValidateVersionString(str)
	PrismCore:HeartBeat("ValidateVersionStr", str) 

	-- Make sure the str argument is fired
	if not str then return nil end

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

-- Function to forcibly disconnect an app from the Prism framework
function PrismCore:BlockApp(AppName)
	PrismCore:HeartBeat("BlockApp", AppName)
	-- Check if the app is connected
	local key = AppStrToKey[AppName]
	if key then
		-- If the app is connected, remove it from the PrismCore tables
		AppStrToKey[AppName] = nil
		KeyToAppInst[key] = nil
		KeyToAppAPI[key] = nil
		KeyToAppStr[key] = nil

		-- Print a message to confirm the disconnection
		wr("App '" .. AppName .. "' has been blocked from Prism Security Network.")
	end
end

-- Function to create an instance with the given Properties
function SharedAPI:Prod(PrivateKey, Properties)

	if type(PrivateKey) == "table" then
		Properties = PrivateKey	
	end

	-- Check if the ClassName property is provided
	if (not Properties.ClassName) or type(Properties.ClassName) ~= "string" then
		wr("ClassName property must be provided and must be a string.")
		return
	end

	-- Create an instance of the given class
	local instance = Instance.new(Properties.ClassName)

	-- Iterate over the rest of the Properties and set them on the instance
	for propertyName, propertyValue in pairs(Properties) do
		-- Skip the ClassName property
		if propertyName ~= "ClassName" then
			-- Check if the property name is valid
			if type(propertyName) ~= "string" then
				wr("Prod(): property name must be a string.")
				return
			end

			-- Set the property on the instance
			instance[propertyName] = propertyValue
		end
	end

	if instance then 
		PrismCore.ProdProducedInstances[instance.Name] = instance
	end

	-- Return the created instance
	return instance
end

-- Function to write log entries
function SharedAPI:Write(Key, ...)
	PrismCore:HeartBeat("SharedAPI:Write()", unpack({...}))
	-- Check if the key is the framework's PrismCore self-sign key
	local AppName = "Unknown"
	if Key == PrismCore.SelfSign then
		-- Process the rest of the parameters as before
		AppName = script.Name
		-- ...
	else
		-- The message is from an app, find the app name using the key
		AppName = PrismCore:AppFgpt({
			Mode = "GNFK"; 
			Key = Key
		})



		-- If no app is found, the key is invalid
		if (AppName == "Unknown") or (AppName == nil) then
			return
		end
	end

	-- Convert all additional parameters to strings and concatenate them
	local MessageParts = {...}
	for i, v in ipairs(MessageParts) do
		MessageParts[i] = tostring(v)
	end
	local Message
	
	pcall(function()
		Message = table.concat(MessageParts, " ")
	end)
	
	-- Create the log entry
	local LogEntry = "🔒 ["..string.sub(SharedAPI:GetPlatform(),1,1).."] " .. (AppName or "???" ) .. " ::: " .. tostring(Message)
	warn(LogEntry) -- Improve in future, but this just prints framwework output to the Roblox output

	-- Prepend the new log entry to ensure newer first
	table.insert(PrismCore.Terminal, 1, LogEntry)

	-- Return the updated log entries tables
	return PrismCore.Terminal 
end


-- This simple function returns the table, it is up to the calling function to save this properly. 
function SharedAPI:GenerateKey(ForcedKeyLength, ForcedTimeout)
	PrismCore:HeartBeat("GenerateKey", ForcedKeyLength, ForcedTimeout)
	-- Initialize an empty Key string
	local Key = ""
	-- Table to keep track of used Keys to ensure uniqueness
	local UsedKeys = PrismCore.UsedKeys or {}

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
		--SharedAPI:Write(PrismCore.SelfSign,"Warning: Attempted to call PrismCore function GenerateKey() with invalid parameters. We let the function through, but we had to override the parameters with default values. ")
	end

	-- Local function for first-time setup only
	-- Function to generate a table of all alphanumeric characters and symbols
	local function GenerateAlphanumericAndSymbolsTable()
		PrismCore:HeartBeat("GenerateAlphanumericAndSymbolsTable")
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
	if not (type(PrismCore.CharsTable)=="table") then 
		local Generation = GenerateAlphanumericAndSymbolsTable()
		PrismCore.CharsTable = Generation -- Save to our PrismCore table
	end

	-- Inner function to attempt Key generation
	local function TryGenerateKey()
		
		repeat
			-- Reset Key to an empty string for each attempt
			Key = ""
			-- Build the Key character by character
			for i = 1, KeyLength do
				-- Randomly select an index from the charsTable
				local RandIndex = math.random(#PrismCore.CharsTable)
				-- Append the character at the random index to the Key
				Key = Key .. PrismCore.CharsTable[RandIndex]
			end
			-- Check if the elapsed time has exceeded the Timeout duration
			if os.difftime(os.time(), StartTime) > Timeout then
				-- If Timeout is reached, print a message and return nil
				SharedAPI:Write(PrismCore.SelfSign,"Fatal Error: Prism is unable to generate new keys into memory. System needs to shut down.")
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

PrismCore.SelfSign = SharedAPI:GenerateKey()

-- Function for apps to terminate their one-time keys using their real key
function SharedAPI:TerminateOneTimeKeys(AppRealKey, SpecificKey)
	wr("TerminateOneTimeKeys() is deprecated and no longer recommended for use. The OneTimeKey system is obsolete after security improvements through the entire framework.")
	PrismCore:HeartBeat("TerminateOneTimeKeys", AppRealKey, SpecificKey) 
	-- Verify that the request is coming from the app itself
	if KeyToAppInst[AppRealKey] ~= script then
		-- Future logic for security software 
	end
	if SpecificKey then
		-- Terminate a specific key
		if PrismCore.ActiveOneTimeKeys[SpecificKey] == KeyToAppInst[AppRealKey] then
			PrismCore.ActiveOneTimeKeys[SpecificKey] = nil
		end
	else
		-- Terminate all keys for the app
		for Key, AppInstance in pairs(PrismCore.ActiveOneTimeKeys) do
			if AppInstance == KeyToAppInst[AppRealKey] then
				PrismCore.ActiveOneTimeKeys[Key] = nil
			end
		end
	end
end

-- Function to get the current platform/environment
function SharedAPI:GetPlatform()
	PrismCore:HeartBeat("GetPlatform()") 
	if PrismCore.Run:IsStudio() then
		if PrismCore.Run:IsClient() then
			return "Local"
		elseif PrismCore.Run:IsServer() then
			return "Server"
		end
	elseif PrismCore.Run:IsRunMode() then
		return "Plugin"
	else
		-- Default to 'N/A' if none of the conditions match
		-- This is a safeguard and should not typically occur
		return "N/A"
	end
end

-- Function to generate a one-time key for an app using its real key
function SharedAPI:GenerateOneTimeKey(AppRealKey)
	PrismCore:HeartBeat("GenerateOneTimeKey", AppRealKey) 
	wr("GenerateOneTimeKey() is deprecated and no longer recommended for use. The OneTimeKey system is obsolete after security improvements through the entire framework.")
	PrismCore.LastRequestTime = PrismCore.LastRequestTime or {}

	-- Check for rate limiting
	if PrismCore.LastRequestTime[AppRealKey] and os.time() - PrismCore.LastRequestTime[AppRealKey] < PrismCore.OneTimeKeySystem_RequestTimeout then
		PrismCore:Write(PrismCore.SelfSign, "Request limit exceeded. Please wait before requesting another key.")
	end

	-- Generate a unique one-time key
	local OneTimeKey = "OTK-S"..SharedAPI.GenerateKey()

	-- Store the one-time key with its associated app instance temporarily
	PrismCore.ActiveOneTimeKeys[OneTimeKey] = KeyToAppInst[AppRealKey]
	PrismCore.LastRequestTime[AppRealKey] = os.time()

	-- Set a timer to invalidate the one-time key after a short period
	delay(PrismCore.OneTimeKeySystem_KeyValidationPeriodInSeconds, function()
		PrismCore.ActiveOneTimeKeys[OneTimeKey] = nil
	end)

	return OneTimeKey
end

-- Function to set data for an app
function SharedAPI:BitSet(PrivateKey, ValName, Val, Expiration)
	PrismCore:HeartBeat("BitSet", PrivateKey, ValName, Val, Expiration)
	-- Verify the app's key
	local AppName = PrismCore:AppFgpt({Key = PrivateKey;Mode = "GNFK";})
	if not AppName then 
		wr("BitSet: Invalid private key.")
		return
	end

	-- Initialize the scope for the app if it doesn't exist
	PrismMemory[AppName] = PrismMemory[AppName] or {}
	PrismMemory[AppName][ValName] = Val

	-- Set an expiration time for the data if provided
	if Expiration then
		delay(Expiration, function()
			PrismMemory[AppName][ValName] = nil
		end)
	end

	return true
end

-- Function to get data for an app
function SharedAPI:BitGet(PrivateKey, ValName)
	PrismCore:HeartBeat("BitGet", PrivateKey, ValName)
	-- Verify the app's key
	local AppName = PrismCore:AppFgpt({Key = PrivateKey;Mode = "GNFK";})
	if not AppName then 
		wr("BitGet: Invalid private key.")
		return nil
	end

	-- Retrieve the value
	if PrismMemory[AppName] and PrismMemory[AppName][ValName] then
		return PrismMemory[AppName][ValName]
	else
		-- Return an error message if the value doesn't exist
		wr("Error: Value does not exist.")
		return nil
	end
end

local function AuthenticateCommon(Entity, EntityData, isDriver)
	-- Validate the version string
	local ValVS
	local FriendlyName

	pcall(function()
		FriendlyName = EntityData.FriendlyName
		ValVS = PrismCore:ValidateVersionString(EntityData.Version)
	end)

	if not ValVS then 		
		wr("Install failed for ".. (FriendlyName or Entity.Name) ..". Compatibility error. ")
		return nil
	end

	-- Check if the EntityData is valid
	if typeof(EntityData) == "table" and EntityData.Version and ValVS and EntityData.API and Entity then
		local EntityAPI = EntityData.API

		-- Generate a unique key for the entity
		local key = SharedAPI:GenerateKey()

		-- Store the key, entity instance, and API in the PrismCore tables
		AppStrToKey[Entity.Name] = key
		KeyToAppInst[key] = Entity
		KeyToAppAPI[key] = EntityAPI
		KeyToAppStr[key] = Entity.Name -- Add the entity name to AppNames

		local Incompatibility = false

		if EntityData.Depends then 
			local Finished, MissingDependancy = SharedAPI:CheckDepends(EntityData.Depends, EntityData.FriendlyName)

			if not Finished then
				wr("'"..tostring(Entity).."' cannot be installed due to missing dependency ('"..tostring(MissingDependancy).."')")
				Incompatibility = true 
			end
		end

		-- Process all the entity API's for our central table 
		local NameOfConflict
		for FcnName, Fcn in pairs(EntityAPI)  do
			-- Check if the function name is already in use
			if not (AllAppFunctions[FcnName]) then 
				-- If not, add it to the table
				AllAppFunctions[FcnName] = Fcn 
			else
				-- If it is, mark as incompatible and store the conflicting name
				Incompatibility = true 
				NameOfConflict = FcnName 
			end
		end

		if Incompatibility then 
			wr("Install of '"..Entity.Name.."' failed due to a compatibility error.")
			return
		end

		-- Create an API package for the entity
		local APIPackage = {
			Key = key,
			AppAPI = SharedAPI,
			PrismExt = PrismExt,
		}

		-- If the entity is a driver, provide PrismCore access
		if isDriver then
			APIPackage.PrismCore = PrismCore
			APIPackage.Internal = PrismCore
		end

		-- Write a success message and return the API package
		wr((isDriver and "Driver" or "App") .. " installation complete: "..EntityData.FriendlyName.." v"..tostring(ValVS))
		return APIPackage
	else
		-- If the EntityData was not valid, write an error message and return nil
		wr("Launch of '"..Entity.Name.."-"..string.lower(SharedAPI:GetPlatform()).."' has been blocked because of compatibility errors.")
		return nil
	end
end

function PrismExt:Authenticate(App, AppData)
	return AuthenticateCommon(App, AppData, false)
end

function PrismExt:AuthenticateDriver(Driver, DriverData)
	return AuthenticateCommon(Driver, DriverData, true)
end

-- Function to get a list of all driver names
function PrismExt:GetDriverNames()
	PrismCore:HeartBeat("GetDriverNames","DEPRECATED")

	wr("Per best security practices, GetDriverNames() has been removed. It will instead return a table of all apps")

	return PrismExt:GetAppNames()
end

-- Function to get a list of all app names
function PrismExt:GetAppNames()
	PrismCore:HeartBeat("GetAppNames")
	local appNames = {}
	for _, name in pairs(KeyToAppStr) do
		table.insert(appNames, name)
	end
	return appNames
end


-- Function to verify the identity of an app using a one-time key
function PrismExt:VerifyIdentity(OneTimeKey)
	wr("VerifyIdentity() is deprecated and no longer recommended for use. The OneTimeKey system is obsolete after security improvements through the entire framework.")
	PrismCore:HeartBeat("VerifyIdentity", OneTimeKey)
	-- Retrieve the app instance using the one-time key
	local AppInstance = PrismCore.ActiveOneTimeKeys[OneTimeKey]

	-- Check if the one-time key is valid
	if AppInstance and (string.sub(OneTimeKey, 1, 5) == "OTK-S") then
		-- Invalidate the one-time key
		PrismCore.ActiveOneTimeKeys[OneTimeKey] = nil
		-- Return the app instance associated with the one-time key
		return AppInstance
	else
		-- The key is invalid or has expired
		return false, "Invalid or expired one-time key."
	end
end

-- This is our ProcessFcn() 
function PrismCore:ProcessFcn(PrivateKey, ...)
	PrismCore:HeartBeat("ProcessFcn", PrivateKey, unpack({...}))
	-- Collect all arguments into a table
	local Arguments = {...}
	local FunctionString = Arguments[1]

	-- Let's kill any spam 
	if not PrivateKey or not FunctionString then return nil end
	
	local ErrorPrefix = "Prism Bridged API Function '"..FunctionString.."' with "..#{...}.." arguments failed: "
	
	-- Let's verify that they are in the Prism network 
	local AppName = PrismCore:AppFgpt({Key = PrivateKey;Mode = "GNFK";})
	if not AppName then wr(ErrorPrefix.." invalid private key, access denied") return nil  end

	-- Grab the actual function from our preprocessed dictionary 
	local Fcn = AllAppFunctions[FunctionString]
	if not Fcn then wr(ErrorPrefix.." function not found") return nil  end

	-- Unpack the arguments when calling the function
	return Fcn(unpack(Arguments))
end

-- All of Prism's API functions are now available directly in the SharedAPI table. This prevents the need of apps and drivers to 

-- Function to call ProcessFcn() with the provided private key and arguments
function SharedAPI:Fcn(PrivateKey,...)
	return PrismCore:ProcessFcn(PrivateKey, ...)
end

-- Function to call ProcessFcn() asynchronously with the provided private key and arguments
function SharedAPI:FcnAsync(PrivateKey, ...)
	local Attachments = {...}
	spawn(function()
		PrismCore:ProcessFcn(PrivateKey, unpack(Attachments))
	end)
end

-- Short form function names for ease of scripting
function SharedAPI:f(PrivateKey,...)
	return PrismCore:ProcessFcn(PrivateKey, ...)
end

function SharedAPI:fa(PrivateKey, ...)
	local Attachments = {...}
	spawn(function()
		PrismCore:ProcessFcn(PrivateKey, unpack(Attachments))
	end)
end

local AlreadyGotExtDepNotice = false

local function DepNotice(PrivateKey)
	if not AlreadyGotExtDepNotice then 
		wr("ATT:",PrismCore:AppFgpt({Key = PrivateKey;Mode = "GNFK";}),"is using deprecated external functions. All Fcn and FcnAsync calls are now available in the AppAPI table.")
		AlreadyGotExtDepNotice = true 
	end
end

-- DEPRECATED //////////////////////////////

	--These are deprecated functions kept here for backwards compatibility. 

	function PrismExt:Fcn(PrivateKey, ...)      DepNotice(PrivateKey) return SharedAPI:Fcn(PrivateKey, ...) end
	function PrismExt:FcnAsync(PrivateKey, ...) DepNotice(PrivateKey) local Attachments = {...} spawn(function() SharedAPI:Fcn(PrivateKey, unpack(Attachments)) end) end
	function PrismExt:f(PrivateKey, ...)        DepNotice(PrivateKey) return SharedAPI:Fcn(PrivateKey, ...) end
	function PrismExt:fa(PrivateKey, ...)       DepNotice(PrivateKey) local Attachments = {...} spawn(function() SharedAPI:Fcn(PrivateKey, unpack(Attachments)) end) end
-- ////////////////////////////////////////


return PrismExt
