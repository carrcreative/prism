![image](https://github.com/dylancarr99/fusion/assets/172750460/9243044b-fbbb-4924-a2c5-288173578681)
```
8888888888                d8b                   
888                       Y8P                   
888                                             
8888888 888  888 .d8888b  888  .d88b.  88888b.  
888     888  888 88K      888 d88""88b 888 "88b 
888     888  888 "Y8888b. 888 888  888 888  888 
888     Y88b 888      X88 888 Y88..88P 888  888 
888      "Y88888  88888P' 888  "Y88P"  888  888
An open-source project
```
> [!CAUTION]
> This is pre-release software, and it should be used for development purposes only. 



## Introduction 
Fusion is a security-centric framework that streamlines the development process on Roblox, offering developers a seamless and secure way to manage their game’s operations. It emphasizes ease of use, allowing creators to implement robust features without compromising on safety. Fusion’s architecture is designed to protect data integrity and provide a trustworthy environment for both developers and players. It’s an indispensable tool for building resilient and secure Roblox applications with confidence.

## Fusion Script Documentation

The Fusion script is a robust framework for Roblox developers, providing secure and interconnected application development. It offers three levels of access: `external`, `internal`, and `console`.

### Security Clearance Levels
- **external**: Functions accessible to all server scripts.
- **internal**: Functions only accessible within Fusion's core, containing the most sensitive functions.
- **console**: Functions accessible by Fusion-compatible apps after authentication.

---

### Key Functions

#### internal:AppFgpt(CondensedData)
Verifies the app's key to provide access to console functions.
- **Parameters**:
  - `CondensedData`: A table with mode and key or name.
- **Returns**: App name for a given key or vice versa.

---

#### internal:ForceAppName(Key)
Retrieves the app name associated with a key.
- **Parameters**:
  - `Key`: The key associated with an app.
- **Returns**: App name or `nil`.

---

#### internal:ValidateVersionString(str)
Validates and condenses a version string.
- **Parameters**:
  - `str`: Version string to validate.
- **Returns**: Condensed version string or `false`.

---

#### console:Write(Key, ...)
Writes log entries and outputs them to the Roblox output.
- **Parameters**:
  - `Key`: App's key.
  - `...`: Additional log parameters.
- **Returns**: Updated log entries table.

---

#### console:GenerateKey(ForcedKeyLength, ForcedTimeout)
Generates a unique key for secure communication.
- **Parameters**:
  - `ForcedKeyLength`: Desired key length.
  - `ForcedTimeout`: Timeout duration.
- **Returns**: Unique key or `nil`.

---

#### console:TerminateOneTimeKeys(AppRealKey, SpecificKey)
Terminates one-time keys using the app's real key.
- **Parameters**:
  - `AppRealKey`: Real key of the app.
  - `SpecificKey`: Specific key to terminate.

---

#### console:GetPlatform()
Retrieves the current platform/environment.
- **Returns**: Platform string.

---

#### console:GenerateOneTimeKey(AppRealKey)
Generates a one-time key using the app's real key.
- **Parameters**:
  - `AppRealKey`: Real key of the app.
- **Returns**: One-time key.

---

#### console:DataSet(Key, ValName, Val)
Sets data for an app.
- **Parameters**:
  - `Key`: App's key.
  - `ValName`: Value name.
  - `Val`: Value to set.
- **Returns**: `true` if successful.

---

#### console:DataGet(Key, ValName)
Retrieves data for an app.
- **Parameters**:
  - `Key`: App's key.
  - `ValName`: Value name.
- **Returns**: Value or `nil`.

---

#### external:Authenticate(App, AppData, LocPlyr)
Authenticates an app and provides a key and console table.
- **Parameters**:
  - `App`: App instance.
  - `AppData`: App data table.
  - `LocPlyr`: Local player instance.
- **Returns**: API package.

---

#### external:VerifyIdentity(OneTimeKey)
Verifies an app's identity using a one-time key.
- **Parameters**:
  - `OneTimeKey`: One-time key.
- **Returns**: App instance or error message.

---

#### external:Post(ScriptOrKey, AppName, FunctionName, ...)
Calls a function on the app's console table safely.
- **Parameters**:
  - `ScriptOrKey`: Script or key of the entity.
  - `AppName`: App name.
  - `FunctionName`: Function name.
  - `...`: Additional arguments.
- **Returns**: Function call result.

---

### Example Usage

```lua
-- Example of an app authenticating with Fusion
local AppData = {
    Version = "1.0",
    Description = "My Fusion App",
    API = {}, -- Your app's API functions
    FriendlyName = "MyApp"
}

local FusionApp = require(FusionFrameworkModule)
local APIPackage = FusionApp:Authenticate(script, AppData)

-- Writing a log entry
APIPackage.AppAPI:Write(APIPackage.Key, "Log message.")

-- Setting and getting data
APIPackage.AppAPI:DataSet(APIPackage.Key, "PlayerScore", 100)
local score = APIPackage.AppAPI:DataGet(APIPackage.Key, "PlayerScore")

-- Using a one-time key
local oneTimeKey = APIPackage.AppAPI:GenerateOneTimeKey(APIPackage.Key)
local verifiedInstance = FusionApp:VerifyIdentity(oneTimeKey)

