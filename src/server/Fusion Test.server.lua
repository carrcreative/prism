local Console = {} 
local internal = {}

local ServerStorage = game:GetService("ServerStorage")

math.randomseed(tick()) 

internal.Info = {
	Version = 0.2;
	Name = "Fusion"
}

internal.Flags = { 

    -- This enables more debug information in the output when running Fusion
	DebugMode = true;

	-------------------------------------------
	--[[Allow Live Installs 

	This is a optional configuration available for Fusion. 
	Due to potential security concerns, we strongly suggest keeping this disabled. 
	
	This allows any script or plugin to install applications to Fusion. This is good for tinkering and development,
	but not safe to run in live servers or insecure Studio environments. 

	Note: This flag is permanently disabled when using Fusion in a plugin environment.]]
	AllowLiveInstalls = false;
	-------------------------------------------

	-------------------------------------------
	--[[Fusion Nicknaming
	
	This allows you to nickname the Fusion framework, which will help organize the output / terminal activity 
	when using multiple portable installations. 	
	]]
	Nickname = internal.Info.Name;

	APIFunctionName = "FusionFcn";
	APIEventName = "FusionEvt";
}


pcall(function() 
	if game.Players.LocalPlayer then 
		internal.Client = true
	end
end)

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

function internal:Print(Data)
	Console.WriteLine(internal.SelfSigned, tostring(Data))
end

function internal:DebugPrint(str)
	if internal.Flags.DebugMode then 
		internal:Print("[DebugMode] "..str)
	end
end

function internal:GenerateAPI(service)
	
	local APIFcnGen = Console:Create("BindableFunction", ServerStorage {
		Name = internal:GenerateKey()
	})

	local APIFEvtGen = Console:Create("BindableFunction", ServerStorage {
		Name = internal:GenerateKey()
	})



	return {
		Fcn = APIFcnGen
		Evt = APIEvtGen
	}
end

-- Generating our match table 
internal.MatchTable = {}
internal.Alphanumeric = "qwertyuioplkjhgfdsazxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM0987654321/ .,;'[]-=)(*&^+%$#@!~"..'"'
internal.UsedHex = {}
internal.StandaloneMode = true 
local Applications = game.ServerStorage:FindFirstChild("applications")

if (not Applications) then 
	internal.StandaloneMode = false
end


function internal:CheckArray(Table, SearchValue)
	--internal:DebugPrint("function CheckArray() used, which is a deprecated function. This will be removed soon. ")
	for Integer, Value in ipairs(Table) do
		if Value == SearchValue then
			return URC.Found
		end
	end
	return URC.NotFound
end

-- Type = Classname, Parent = Object parent, Data = dictionary of the properties you want. Ie:
-- internal:create("Part", workspace, { 
--     Name = "Hello";
--     BrickColor = BrickColor.Random();
-- })



function Console:Create(Type, Parent, Data)
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
	game:GetService('RunService').Heartbeat:wait()
	NewObj.Parent = Parent
	return NewObj -- Back to station!
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
		warn("Cipher fail.. Incorrect private Key")
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


-- This is a very useful function to track apps by their private Key
-- Since only the app knows its private Key, we don't need any other identification as we already got all the info
function internal:KeyToSource(Key, Name) --PATCH: Variables were seperated as per security patch 0013nhb. Before, an attacker could fool CS into executing malicious commands by passing the name instead of the Key
	-- Check registered applications based on their private Key, these would be the ones kept under this very script.
	for Application,PossibleKey in pairs(internal.RegisteredServices) do -- Start loop
		if PossibleKey == Key or Name == Application then -- If PrivateKey matches the Key kept on file
			return {Application, "Application"} -- We know that since only that application would have that private Key, then the userdata info MUST be correct.
		end  
	end

	-- Now we're checking the registered apps for matching private Keys. These are scripts that have gotten OAuth API access to CS.
	for Applic,PossibleKey in pairs(internal.RegisteredApps) do -- Start loop
		if PossibleKey == Key or Applic == Name then -- Chec kif private Key matches again
			return {Applic, "App"} -- Return the application, under the "App" protocol instead of the "Application" one before.
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
		MatchingSector = (internal.Flags.Nickname or script.Name)
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
		print(tostring(Prefix)..tostring(Str)) 

		-- Send to any internal applications that are listening in
		for _,Push in ipairs(internal.SharedConsoleData) do
			spawn(function()
				Push(tostring(MatchingSector), Str)
			end)
		end
	end
end

-- Quick notice for the user if universal response codes are in effect.
if not ResponseLibrary then
	internal:Print("This server does not support universal response codes. As such, we have a function in place to downgrade the signal to work for compatibility. [1/2]")
	internal:Print("Universal response codes are a great way to organize future scripts. You can read up more on it at the Fusion Framework github! [2/2]")
end

-- Function for setting up OAuth for our built-in applications
-- OAuth is the protocol name for the API handler system that CS uses. It uses Public Keys and Private Keys
-- In order to secure API calls. This way we will always know how to verify any requests/whatever based on their
-- kept private Key in their memory. 
function Console.SetupAuth(Key, API) 
	local Application = internal:KeyToSource(Key) -- Check the Key so we know which application is wanting their API used
	if not type(Application)=="table" then return Application end -- This will return the URC code in internal:KeyToService(), which is likely to be URC.NotFound

	-- Build logic
	local function Bridge(Data) -- Reusable bridge function
		local SecurityKey = Data.PrivateKey -- Get the Key that sent
		local Function = Data.Function -- The intended usage so we know where to direct it
		local FindSource = internal:KeyToSource(SecurityKey)
		if not (FindSource == URC.NotFound) then -- If Key is valid
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
	_G[Application[1].Name] = function(Data) spawn(function() return Bridge(Data) end) end

	--[[Now this one is asynchronous API calls. These will stop your script from running until CS is done handling your API call.
	These would be useful for:
		a) Gamemode cycles
		b) Loading objects
	Another example... _G.WhateverAsync({Function = "Gamemode";Mode = "StartCycle"}) and your script will resume after that gamemode cycle is done
	-- ]]
	_G[Application[1].Name.."Async"] = function(Data) return Bridge(Data) end

	--[[ For debug synchronous calls
		This simply just passes debug info to your application. It is up to the application and how it handles it.
		Most ones I made will simply output more info when called with debug, to help find errors.
		Example: _G.WhateverDebug({Function = "Lighting";Mode = "Set";Value = 0})
	--]]
	_G[Application[1].Name.."Debug"] = function(Data) Data["Debug"] = true spawn(function() return Bridge(Data) end) end

	-- The same thing as above but asynchronous.
	-- _G.WhateverDebugAsync({Function = "Lighting";Mode = "Set";Value = 0})
	_G[Application[1].Name.."DebugAsync"] = function(Data) Data["Debug"] = true spawn(function() return Bridge(Data) end) end
end

-- Here is where we are going to setup registrations for external applications wanting to use API powered by CS.
_G["SetupAuth"] = function(Script)
	if URC.NotFound == (internal:KeyToSource(nil, Script.Name)) then
		local Key = Console:Cipher(script.Name.."_app_"..math.random()..script.Parent.Name)
		internal.RegisteredApps[Script.Name] = Key
		return Key
	else
		return URC.Fault
	end
end

_G["LoadService"] = function(Application)
	local LoadTimeout = 0
	repeat wait(1) LoadTimeout = LoadTimeout + 1 until internal.Loaded or LoadTimeout >=6

	if (not internal.Loaded) then 
		return URC.Timeout
	end

	if internal.Flags.AllowLiveInstalls then 
		Console.SpawnService(Application)
	else
		if internal.Flags.DebugMode then 
			internal:DebugPrint(Application.Name.." was blocked after attempting to access this Fusion installation. If this is an intentional action, Fusion flag 'AllowLiveInstalls' needs to be enabled.")
		end
		return URC.AccessDenied
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
		internal:Print("Granted root console permissions to '"..Applications.Name.."."..internal:KeyToSource(SecurityKey)[1].Name.."'.")

		table.insert(internal.SharedConsoleData, Fcn)
	end
end

function Console.CheckDependancy(name)
	local PossibleMatch = Applications:FindFirstChild(name)

	if PossibleMatch then
		return true 
	else
		return false
	end
end

function Console.SpawnService(Application)
	local Count = tick() -- Keep track of the time for installation
	spawn(function() -- Start new thread
		local Activation -- Establish activation variable
		local Key = Console:Cipher(Application.Name) -- Create new cryptographic hash for verification
		internal.RegisteredServices[Application] = Key -- Save the private Key in our memory, so we know to verify it later

		spawn(function() Activation = require(Application):initialize(Key, Console) end) -- Spawn this in a different thread, so we can keep track of its behaviour
		local SubCount = 0 -- Gotta keep track again!
		repeat wait(.2) -- Start loop
			SubCount = SubCount + 1	-- Start keeping track of Timeout data
			if SubCount == 45 then internal:Print("App: '"..Application.Name.."' is not responding. The installation will be halted if it does not respond shortly.") end
		until SubCount >= 75 or Activation -- Kill loo

		-- Let's parse any available information! 
		local Info = require(Application).Info

		if not Info then 
			internal:Print(Application.Name.." has been blocked by the Fusion firewall. App isn't following the required behaviour of Fusion.")
			return URC.AccessDenied
		end
		local InfoName = tostring((Info["Name"] or Application.Name))
		local InfoVersion = tostring((Info["Version"] or "?"))
		local InfoEnv = tostring((Info["EnvType"] or "?"))


		local TimeSpent = tick() - Count -- Calculate time spent.
		if (Activation==Key) then -- Base our decision of the fate of the module whether it responded back or not, for security/compatibility reasons.
			pcall(function()Applications[tostring(Application)] = require(Application) end)  -- Add the module's libraries to our Applications{} table
			local Str = "server"
			if internal.Client then Str = "client" end



			internal:Print("Loaded app: "..InfoName.."-"..InfoEnv.." ("..InfoVersion..")".." to the "..Str.." in "..string.sub(tostring(TimeSpent), 1, 4).." sec. ")

		else 
			internal:Print("Failed to load "..InfoName.."-"..InfoEnv.." ("..InfoVersion..") ErrNo:"..tostring(URC.Timeout)..".) For security, this application has been destroyed.") -- Print out our error
			Application:Destroy() -- Get rid of the application
		end
	end)
end 

-- We need to create our application programming interface now.
-- As of June 2024 (v0.02), we changed our API to only allow BindableFunctions and BindableEvents for server communication
-- This is to prevent the associated security concerns with our previously used global namespace based API. 



-- If this is running in standalone mode, we want to automatically import all the saved applications 
if internal.StandaloneMode then 
	for _,Application in ipairs(Applications:GetChildren()) do -- Loop through all the modules
		Console.SpawnService(Application)
	end
	internal.Loaded = true 

else
	internal:Print("Fusion is loaded, however there are no applications installed.")

end


internal:Print("Fusion Framework v"..internal.Info.Version.." has been installed to "..script.Parent.Name)

internal:GenerateAPI()