local Console = {} 
local internal = {}
math.randomseed(tick()) 

internal.DebugMode = false

pcall(function() 
	if game.Players.LocalPlayer then 
		internal.Client = true
	end
end)

-- Establish our variables
local Services = script:FindFirstChild("services")

local ResponseLibrary = game.ReplicatedStorage:FindFirstChild("Response")
if ResponseLibrary then
	URC = require(game.ReplicatedStorage.Response)
else
	-- Downgrading our universal response codes to basic binary output, for games that don't have it installed 
	URC = {
		Valid=true;Found=true;
		Fault=false;InvalidData=false;AccessDenied=false;Timeout=false;NotFound=false;Busy=false;Incompatibility=false;Duplicate=false;
	}
end

-- Generating our match table 
internal.MatchTable = {}
internal.Alphanumeric = "qwertyuioplkjhgfdsazxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM0987654321/ .,;'[]-=)(*&^+%$#@!~"..'"'
internal.UsedHex = {}

function internal:CheckArray(Table, SearchValue)
	for Integer, Value in ipairs(Table) do
		if Value == SearchValue then
			return URC.Found
		end
	end
	return URC.NotFound
end

for Integer = 1, string.len(internal.Alphanumeric), 1 
do local CurrentHex = string.sub(internal.Alphanumeric, Integer, Integer)
	local Block
	local TimeoutCount = 0 
	repeat 
		TimeoutCount = TimeoutCount + 1 -- Queue up the loop timeout timer
		local AlphaAmnt = math.random(1,9) -- Random amount of characters for thie bitmap

		local FullHex = ""
		--First step of generating our string block. We want to generate a random key to assign our block. This will replace the string characters when encrypted
		for i = 1, AlphaAmnt, 1 do
			local HexMath = math.random(1, string.len(internal.Alphanumeric))
			local RandHex = string.sub(internal.Alphanumeric, HexMath, HexMath)
			FullHex = FullHex .. RandHex
		end 


		local SecretMath = math.random(111,999) * math.random(1,9)
		Block = tostring(SecretMath) .. tostring(FullHex)

		local Match = internal:CheckArray(internal.UsedHex, Block)

		if TimeoutCount == 70 then 
			error("Fatal mathematics error with Fusion Framework's security. Potentially caused by a memory malfunction.")
			break
		end
	until Match == URC.NotFound


	TimeoutCount = 0
	internal.MatchTable[CurrentHex] = Block 
	table.insert(internal.UsedHex, Block)
end

function Console:Cipher(newstring, rando)
	if not newstring then return URC.InvalidData end
	
	local CipheredStr = ""

	for IntegerPos = 1, newstring.len(newstring) do
		local CurrentHex = newstring.sub(newstring, IntegerPos,IntegerPos)
		CipheredStr = CipheredStr..tostring(internal.MatchTable[CurrentHex])
	end

	return CipheredStr
end

function Console:Decipher(newstring, rando)
	local function MatchBlock(block)
		for Key,Value in pairs(internal.MatchTable) do
			if block == Value then return Key end
		end
		return URC.NotFound
	end


	local Str = ""
	local Progress = 1
	local MemoryStretchLimit = 20
	local BlockStretch = 1
	local CipherFail = false

	repeat 
		local LockedBlock = string.sub(newstring, Progress, Progress+BlockStretch)
		local CheckLock = MatchBlock(LockedBlock)

		if not (CheckLock == URC.NotFound) then
			Str = Str..CheckLock 
			Progress = Progress + BlockStretch + 1
			BlockStretch = 1
		else
			BlockStretch = BlockStretch + 1
		end

		if BlockStretch >= MemoryStretchLimit then
			CipherFail = true
			break
		end


	until Progress >= string.len(newstring)

	if CipherFail then 
		warn("Cipher fail.. Incorrect private key")
	end

	return Str
end

local rand = math.random(1,999999999) -- 'rand' acts as the salt, which allows us to secure hashes to this current execution session only. So hashes will never be the same between servers for security reasons
internal.SelfSigned = Console:Cipher(script.Name)

-- Create our dictionaries to keep track of all the stuff wanting to use CS.
internal.RegisteredApps = {}
internal.RegisteredServices ={} 
internal.RegisteredDataSpace = {}
internal.SharedConsoleData = {}


-- This is a very useful function to track apps by their private key
-- Since only the app knows its private key, we don't need any other identification as we already got all the info
function internal:KeyToSource(Key, Name) --PATCH: Variables were seperated as per security patch 0013nhb. Before, an attacker could fool CS into executing malicious commands by passing the name instead of the key
	-- Check registered services based on their private key, these would be the ones kept under this very script.
	for Service,PossibleKey in pairs(internal.RegisteredServices) do -- Start loop
		if PossibleKey == Key or Name == Service then -- If PrivateKey matches the Key kept on file
			return {Service, "Service"} -- We know that since only that service would have that private key, then the userdata info MUST be correct.
		end  
	end

	-- Now we're checking the registered apps for matching private keys. These are scripts that have gotten OAuth API access to CS.
	for Applic,PossibleKey in pairs(internal.RegisteredApps) do -- Start loop
		if PossibleKey == Key or Applic == Name then -- Chec kif private key matches again
			return {Applic, "App"} -- Return the application, under the "App" protocol instead of the "Service" one before.
		end 
	end

	return URC.NotFound -- Back to tower!
end


-- This is our custom print function. It allows us to change how it looks, and monitor activity in the frameowkr.
function Console.WriteLine(SecurityKey, ...)
	local ParsedData = {...}
	local Str = ""
	local MatchingSector
	if SecurityKey == internal.SelfSigned then 
		MatchingSector = script
		--if not internal.DebugMode then return end
	else
		local PossibleMatch = internal:KeyToSource(SecurityKey)
		if not (PossibleMatch==URC.NotFound) then
			MatchingSector = PossibleMatch[1]
		end
	end

	if MatchingSector then
		local Prefix 
		Prefix = "[F]["..tostring(MatchingSector).."]:" -- Prefix
		-- If client, a different prefix. For organization
		if internal.Client then
			Prefix = "[F-L]["..tostring(MatchingSector).."]:"
		end

		-- Now we want to loop through all data and condense it into a string so the output handles it.
		for _,Object in pairs(ParsedData) do
			Str = Str .." "..tostring(Object)
		end

		-- Warn() prints in orange text so we know to look for that quicker
		print(Prefix..Str) 

		-- Send to any internal services that are listening in
		for _,Push in ipairs(internal.SharedConsoleData) do
			spawn(function()
				Push(tostring(MatchingSector), Str)
			end)
		end
	end
end

function internal:Print(Data)
	Console.WriteLine(internal.SelfSigned, string.upper(tostring(Data)))
end

-- Quick notice for the user if universal response codes are in effect.
if not ResponseLibrary then
	internal:Print("This server does not support universal response codes. As such, we have a function in place to downgrade the signal to work for compatibility. [1/2]")
	internal:Print("Universal response codes are a great way to organize future scripts. You can read up more on it at the Fusion Framework github! [2/2]")
end

-- This is CS's built in Create() libarry!
-- Roblox built something like this a while ago but it has been proven to be incredibly inefficient, so I remade it the proper way
-- Type = Classname, Parent = Object parent, Data = dictionary of the properties you want. Ie:
-- Console.Create("Part", workspace, { 
--     Name = "Hello";
--     BrickColor = BrickColor.Random();
-- })
function Console.Create(Type, Parent, Data)
	if not Type and not Data then return URC.Fault end -- This checks to make sure the data is not malformed, so we know what we're doing
	local NewObj = Instance.new(Type) -- Create the object using Instance.new()

	-- For this part, we're gonna run through the 'Data' dictionary and each iteration apply that specific value to the property.
	for Property, Value in pairs(Data) do -- Start loop
		pcall(function() -- Pcall wrapping in case something doesn't go right, which is often when copying & pasting these API calls everywhere
			NewObj[Property] = Value -- Set the value if its correct!
		end)
	end

	-- Now we will set the parent they they wanted.
	-- The 'Parent' parameter accepts nil too, so thats why we will also return it at the end. So they can handle it themselves for replication or whatever
	NewObj.Parent = Parent
	return NewObj -- Back to station!
end

-- Function for setting up OAuth for our built-in services
-- OAuth is the protocol name for the API handler system that CS uses. It uses Public Keys and Private Keys
-- In order to secure API calls. This way we will always know how to verify any requests/whatever based on their
-- kept private key in their memory. 
function Console.SetupOAuth(Key, API) 
	local Service = internal:KeyToSource(Key) -- Check the key so we know which service is wanting their API used
	if not type(Service)=="table" then return Service end -- This will return the URC code in internal:KeyToService(), which is likely to be URC.NotFound

	-- Build logic
	local function Bridge(Data) -- Reusable bridge function
		local SecurityKey = Data.PrivateKey -- Get the key that sent
		local Function = Data.Function -- The intended usage so we know where to direct it
		local FindSource = internal:KeyToSource(SecurityKey)
		if not (FindSource == URC.NotFound) then -- If key is valid
			--local Details  
			--local success, fail = pcall(function()
				Details = API[Function](nil,Data) -- Second parameter because module limitations, converting it to the right format
			--end)
			
			--if success then
				return Details
			--else
				--Console.WriteLine("Error detected accessing Fusion libraries: "..tostring(fail))
			--end
		else
			internal:Print("OAuth Registration Error: "..FindSource) --Rip 
		end

	end

	-- Here is our interesting thread for creating our API's. Let us take this in steps

	--[[ This is regular, synchronous API calls that will run at the same time are your code.
    These are best for quick calls to the framework that
	 	a) don't get anything in return
	 	b) don't need to take up time 
	 	c) aren't time-sensitive to your variables
	So for example... _G.Whatever({Function = "Lighting";Mode = "Set";Value = 0})
	-- ]]
	_G[Service[1].Name] = function(Data) spawn(function() return Bridge(Data) end) end

	--[[Now this one is asynchronous API calls. These will stop your script from running until CS is done handling your API call.
	These would be useful for:
		a) Gamemode cycles
		b) Loading objects
	Another example... _G.WhateverAsync({Function = "Gamemode";Mode = "StartCycle"}) and your script will resume after that gamemode cycle is done
	-- ]]
	_G[Service[1].Name.."Async"] = function(Data) return Bridge(Data) end

	--[[ For debug synchronous calls
		This simply just passes debug info to your service. It is up to the server to handle it and how it handles it.
		Most ones I made will simply output more info when called with debug, to help find errors.
		Example: _G.WhateverDebug({Function = "Lighting";Mode = "Set";Value = 0})
	--]]
	_G[Service[1].Name.."Debug"] = function(Data) Data["Debug"] = true spawn(function() return Bridge(Data) end) end

	-- The same thing as above but asynchronous.
	-- _G.WhateverDebugAsync({Function = "Lighting";Mode = "Set";Value = 0})
	_G[Service[1].Name.."DebugAsync"] = function(Data) Data["Debug"] = true spawn(function() return Bridge(Data) end) end
end

-- Here is where we are going to setup registrations for external applications wanting to use API powered by CS.
_G["SetupOAuth"] = function(Script)
	if URC.NotFound == (internal:KeyToSource(nil, Script.Name)) then
		local Key = Console:Cipher(script.Name.."_app_"..math.random()..script.Parent.Name)
		internal.RegisteredApps[Script.Name] = Key
		return Key
	else
		return URC.Fault
	end
end

-- BitModder is the protocol for writing & reading data. This is a secure function in order to protect sensitive information inside the core of CS. This isn't required to be used but is recommended. 
function Console.BitModder(SecurityKey, Direction, Keyspot, Value)
	if not (SecurityKey and Direction  and Keyspot) then  return URC.NotFound end
	local Source = internal:KeyToSource(SecurityKey)

	if not (Source == URC.NotFound) then
		if not internal.RegisteredDataSpace[SecurityKey] then internal.RegisteredDataSpace[SecurityKey] = {} end
		local ExistingDataModel = internal.RegisteredDataSpace[SecurityKey]

		if Direction == "get" then 
			return ExistingDataModel[Keyspot]


		elseif (Direction == "set" or 1) and (Value~=nil) then
			ExistingDataModel[Keyspot] = Value
			return URC.Valid

		else
			return URC.InvalidData
		end
	else
		return URC.AccessDenied
	end
end

function Console.ReadActivity(SecurityKey, Fcn)
	if not (internal:KeyToSource(SecurityKey) == URC.NotFound) then 
		if #internal.SharedConsoleData > 5 then return URC.Busy end
		internal:Print("Granted root console permissions to '"..Services.Name.."."..internal:KeyToSource(SecurityKey)[1].Name.."'.")

		table.insert(internal.SharedConsoleData, Fcn)
	end
end

function Console.CheckDependancy(name)
	local PossibleMatch = Services:FindFirstChild(name)

	if PossibleMatch then
		return true 
	else
		return false
	end
end

internal:Print("S T A R T I N G    . . .") -- Just for fun
internal:Print("SYSTEM PROCEEDING WITH STARTUP, DETECTED "..tostring(#Services:GetChildren()) .." UNINSTALLED SERVICES.")

for _,Service in ipairs(Services:GetChildren()) do -- Loop through all the modules
	local Count = tick() -- Keep track of the time for installation

	spawn(function() -- Start new thread
		local Activation -- Establish activation variable
		local Key = Console:Cipher(Service.Name) -- Create new cryptographic hash for verification
		internal.RegisteredServices[Service] = Key -- Save the private key in our memory, so we know to verify it later

		spawn(function() Activation = require(Service):initialize(Key, Console) end) -- Spawn this in a different thread, so we can keep track of its behaviour
		local SubCount = 0 -- Gotta keep track again!
		repeat wait(.2) -- Start loop
			SubCount = SubCount + 1	-- Start keeping track of timeout data
			if SubCount == 45 then internal:Print("'"..Services.Name.."."..Service.Name.."' is not responding. The installation will be halted if it does not respond shortly.") end
		until SubCount >= 75 or Activation -- Kill loop

		local TimeSpent = tick() - Count -- Calculate time spent 
		if Activation then -- Base our decision of the fate of the module whether it responded back or not, for security/compatibility reasons.
			pcall(function()Services[tostring(Service)] = require(Service) end)  -- Add the module's libraries to our Services{} table
			local Str = "server"
			if internal.Client then Str = "client" end

			internal:Print("Successfully installed '"..Services.Name.."."..Service.Name.."' to the "..Str.." in "..string.sub(tostring(TimeSpent), 1, 4).." sec. ")
			
		else 
			internal:Print("Failed to install '"..tostring(Services.Name).."."..tostring(Service.Name).."' (Err: "..tostring(URC.Timeout)..".) For security, this service has been destroyed.") -- Print out our error
			Service:Destroy() -- Get rid of the service
		end
	end)
end

