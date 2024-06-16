-- These are three security clearance levels we want to create
local external          = {} -- Functions accessable to every server script
local internal          = {} -- Functions accessable only within Fusion's core, these are the most sensitive functions.
local console           = {} -- Functions accessable by apps compatible with Fusion, only after they 

local RunService = game:GetService("RunService")

internal.LogEntries     = {}
internal.AppDataStorage = {}
internal.AppKeys        = {}
internal.AppInst        = {}
internal.OneTimeKeys	= {}
internal.RequestTimeout = 10 -- Time in seconds to wait before allowing another request from the same app
internal.KeyValPeriod   = 30 -- Time in seconds for which a one-time key is valid


-- Function to verify the app's key before providing access to console functions
function internal:VerifyKey(AppName, Key)
    return internal.AppKeys[AppName].Key == Key
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
function console:DataSet(Key, ValName, Val)
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
function console:DataGet(Key, ValName)
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

-- Function to write log entries
function console:Write(Key, ...)
    -- Check if the key is the framework's internal self-sign key
    local AppName
    if Key == internal.SelfSign then
        -- Process the rest of the parameters as before
		AppName = "Fusion"
        -- ...
    else
        -- The message is from an app, find the app name using the key
        AppName = "Unknown"
        for name, data in pairs(internal.AppKeys) do
            if data.Key == Key then
                AppName = name
                break
            end
        end
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
    local LogEntry = "[F][" .. console:GetPlatform() .. "][" .. AppName .. "]: " .. Message
	print(LogEntry) -- Improve in future, but this just prints framwework output to the Roblox output

    -- Prepend the new log entry to ensure newer first
    table.insert(internal.LogEntries, 1, LogEntry)

    -- Return the updated log entries table
    return internal.LogEntries 
end

-- Function to authenticate an app and provide it with a unique key and console table
function external:Authenticate(App, AppData)
    if typeof(AppData) == "table" and AppData.Name and AppData.Version and AppData.Description and AppData.Console then
        local Key = console:GenerateKey()

        internal.AppKeys[AppData.Name] = Key
		internal.AppInst[Key] = App
		console:Write(internal.SelfSign, "Launched app: '"..AppData.Name.."' v"..AppData.Version..".")
        -- Pass the framework's console table along with the key

		return Key, console, external
    else
        console:Write(internal.SelfSign, "Invalid app data provided.")
    end
end

function external:VerifyIdentity(OneTimeKey)
    -- Retrieve the app instance using the one-time key
    local AppInstance = internal.OneTimeKeys[OneTimeKey]

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

-- Function to call a function on the app's console table safely
function external:Post(AppName, Key, FunctionName, ...)
    if internal:VerifyKey(AppName, Key) then
        local AppConsole = internal.AppKeys[AppName].console
        if AppConsole and AppConsole[FunctionName] then
            -- Use pcall to safely call the function
            local Status, Result = pcall(AppConsole[FunctionName], ...)
            if not Status then
                console:Write(internal.SelfSign,"Error calling function: " .. tostring(Result))
            end
            return Result
        else
            console:Write(internal.SelfSign,"Function does not exist on the app's console table.")
        end
    else
        console:Write(internal.SelfSign, "Access denied. Invalid key.")
    end
end

-- Return the 'external' table when the module is required
return external