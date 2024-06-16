local console = {} 
local internal = {} 
local Cache = {}
local DataStore = game:GetService("DataStoreService")
local BackupInterval = 60
local TrustedApps = {}

local AppData = {
    Name = "DataPlus",
    Version = "0.1",
    Description = "App for handling DataStore",
    Console = console -- The console table of this datastore app
}

internal.FrameworkConsole = nil 
internal.MainFramework = require(script.Parent["Fusion New"])

-- Function to authenticate with the main framework and obtain a key
local function AuthenticateWithFramework()
    -- Provide the necessary app data to authenticate with the main framework


    -- Call the main framework's authentication function
    local Key, FrameworkConsole = internal.MainFramework:Authenticate(script, AppData)
    internal.FrameworkConsole = FrameworkConsole
    if Key then
        -- Store the key for future operations
        internal.FrameworkKey = Key
        FrameworkConsole:Write(internal.SelfSign, "DataPlus v"..AppData.Version.." has been launched on Fusion")
        return Key
    else
        FrameworkConsole:Write(internal.SelfSign, "Failed to authenticate DataPlus with the main framework.")
        error("Authentication failed.")
    end
end

-- Function to verify the identity of an app within the datastore app
local function VerifyAppIdentity(OneTimeKey, App)
    -- Call the main framework's verification function
    local AppData, ErrorMessage = internal.MainFramework:VerifyIdentity(OneTimeKey)
    if AppData or (TrustedApps[OneTimeKey] == AppData) or (OneTimeKey == internal.SelfSign)  then
        if not TrustedApps[OneTimeKey] then 
            TrustedApps[OneTimeKey] = AppData
        end
        -- The app is verified, return true and the app's data
        return true, AppData
    else
        -- Verification failed, return false and the error message
        return false, ErrorMessage
    end
end

-- Function to get a value from the cache or DataStore
function console:Get(Key, ValName)

    if not VerifyAppIdentity(Key) then return nil end 

    local cacheEntry = Cache[ValName]
    if cacheEntry and (os.time() - cacheEntry.Timestamp) < BackupInterval then
        return cacheEntry.Value
    else
        -- Cache is old or doesn't exist, fetch from DataStore
        local success, result = pcall(function()
            return DataStore:GetAsync(ValName)
        end)
        if success then
            -- Update cache
            Cache[ValName] = { Value = result, Timestamp = os.time() }
            return result
        else
            error("Failed to get value from DataStore.")
        end
    end
end

-- Function to update a value in the cache and DataStore
function console:Update(Key, ValName, Value)

    if not VerifyAppIdentity(Key) then return nil end 

    -- Update cache
    Cache[ValName] = { Value = Value, Timestamp = os.time() }
    print(2)
    -- Update DataStore asynchronously
    local success = pcall(function()
        DataStore:UpdateAsync(ValName, function(oldValue)
            -- Create a backup before updating
            local currentDate = os.date("!%Y-%m-%d")
            local backupKey = "BKU_" .. ValName .. "_" .. currentDate
            DataStore:Set(backupKey, oldValue)

            -- Return new value to update
            print(5)
            return Value
        end)
    end)
    if not success then
        error("Failed to update value in DataStore.")
    end
end


local Key = AuthenticateWithFramework()

local ValName
local NewVal 
game.Players.PlayerAdded:Connect(function(Player)    
    ValName = tostring(Player).."data"
    local NewVal = console:Get(Key, ValName) or 0 
    print(NewVal,"HELLLOOOOOOOOOOOOO")
end)

game.Players.PlayerRemoving:Connect(function(Player)
    ValName = tostring(Player).."data"
    console:Update(Key, ValName, 5)
end)