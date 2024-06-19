-- Importing the Fusion framework from the ReplicatedStorage
local FusionFramework = require(game.ReplicatedStorage:WaitForChild("Fusion"))

-- Configuration settings for DataPlus
local Config = {
	LudacrisMode = false, -- If true, bypasses caching and pulls directly from DataStore
	DisableBackupService = false, -- If true, disables the backup service
	BackupInterval = 200, -- Time in seconds between each backup
}

-- Main DataPlus table
local DataPlus = {}

-- Accessing Roblox DataStore services
local DataStoreService = game:GetService("DataStoreService")
local mainDataStore = DataStoreService:GetDataStore("MainDataStore")
local versionDataStore = DataStoreService:GetDataStore("VersionDataStore")

-- Variables for internal use
local cache = {} -- Cache to store data and reduce DataStore calls
local UpdateQueue = {} -- Queue to manage batch updates
local VersionHistory = {} -- History of data versions for rollback
local internal = {} -- Internal table for private functions and variables
local BatchSize = 10 -- Number of updates per batch
local BatchInterval = 50 -- Time in seconds between batches

-- Retrieves data, checking cache first if LudacrisMode is off
function DataPlus:GetData(Key)
	if Config.LudacrisMode then
		return cache[Key]
	else
		if not cache[Key] then
			local success, result = pcall(mainDataStore.GetAsync, mainDataStore, Key)
			if success then
				cache[Key] = result
			end
		end
		return cache[Key]
	end
end

-- Helper function to write logs using Fusion's API
local function Write(...)
	internal.AppAPI:Write(internal.PrivateKey, ...)
end

-- Sets data, adds it to the update queue, and updates cache
function DataPlus:SetData(Key, Value)
	UpdateQueue[Key] = Value
	cache[Key] = Value
	if not Config.DisableBackupService then
		internal:SaveVersion(Key, Value)
		return true 
	end
end

-- Saves a new version of the data for rollback purposes
function internal:SaveVersion(Key, Value)
	local versions = VersionHistory[Key] or {}
	if #versions >= 3 then
		table.remove(versions, 1)
	end
	table.insert(versions, {timestamp = os.time(), value = Value})
	VersionHistory[Key] = versions
end

-- Retrieves the last three versions of the data
function DataPlus:GetVersions(Key)
	return VersionHistory[Key] or {}
end

-- Batch updates the DataStore and attempts repairs on failure
local function BatchUpdateDataStore()
	for Key, Value in pairs(UpdateQueue) do
		local success = pcall(function()
			mainDataStore:SetAsync(Key, Value)
		end)

		if success then
			UpdateQueue[Key] = nil
			cache[Key] = Value
		else
			local repairSuccess = pcall(function()
				mainDataStore:UpdateAsync(Key, function(oldValue)
					return Value
				end)
			end)

			if repairSuccess then
				cache[Key] = Value
				Write("Repair successful for key: " .. Key)
			else
				Write("Failed to repair data for key: " .. Key)
			end
			UpdateQueue[Key] = nil
		end
		Write("DataPlus batch upload completed")
	end
end

-- Authenticates with the Fusion framework and starts the service
function internal:AuthenticateWithFusion(AppData)
	local APIPackage = FusionFramework:Authenticate(script, AppData)
	internal.PrivateKey = APIPackage.Key
	internal.AppAPI = APIPackage.AppAPI

	Write("DataPlus daemon has been started")
end

-- Initiates the batch update process at intervals defined in Config
spawn(function()
	while wait((Config.BackupInterval or 100)) do
		BatchUpdateDataStore()
	end
end)

-- AppData for DataPlus, containing metadata
local AppData = {
	Version = "0.85b",
	Description = "DataPlus Service",
	API = DataPlus,
	FriendlyName = "DataPlus"
}

-- Ensures DataPlus performs a final batch update before the game closes
game:BindToClose(BatchUpdateDataStore) 

-- Starts the DataPlus service by authenticating with Fusion
internal:AuthenticateWithFusion(AppData)
