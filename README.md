![image](https://github.com/carrcreative/prism/assets/173332208/3589c826-9bcd-4981-a8d4-d467307f21ea)



Find latest release: 
[https://github.com/carrcreative/prism/releases/tag/1.2
](https://github.com/carrcreative/prism/releases/tag/1.2)


# Prism

Prism is a robust and secure framework for managing apps and drivers in a Roblox environment. It provides a variety of functionalities for key management, data storage, function processing, and more. It also includes several safety measures such as secret keys and defined access levels.

## Security Clearance Levels

Prism defines three levels of security clearance:

1. **PrismExt**: Functions accessible to every script.
2. **PrismCore**: Functions accessible only within Prism's core. These are sensitive functions that drivers are allowed to configure.
3. **SharedAPI**: Functions accessible by apps compatible with Prism, only after they have been authenticated.

## Key Functions

### Data Storage

- `SharedAPI:BitSet(PrivateKey, ValName, Val, Expiration)`: Sets a value for an app in the protected PrismMemory table. The value can have an optional expiration time.
- `SharedAPI:BitGet(PrivateKey, ValName)`: Retrieves a value for an app from the protected PrismMemory table.

### Function Processing

- `PrismCore:ProcessFcn(PrivateKey, ...)`, `SharedAPI:Fcn(PrivateKey,...)`, `SharedAPI:FcnAsync(PrivateKey, ...)`, `SharedAPI:f(PrivateKey,...)`, and `SharedAPI:fa(PrivateKey, ...)`: These functions process a function call with the provided private key and arguments. The function to be called and its arguments are passed as parameters. The `Async` versions execute the function asynchronously, but also cannot return any data.

### Platform Detection

- `SharedAPI:GetPlatform()`: Returns the current platform or environment.

### Authentication

- `PrismExt:Authenticate(App, AppData)` and `PrismExt:AuthenticateDriver(Driver, DriverData)`: These functions authenticate an app or a driver based on its data. It validates the app data, checks for dependencies, processes the entity's API, and creates an API package for the entity.

 ## Build on Prism

![image](https://github.com/carrcreative/prism/assets/173332208/c4eb6703-bd49-4609-9750-560d4b967a0b)


 ### Sample Application Structure
```lua
local AppData = {
    Version = "1.0",
    API = {
        MyFunction = function(...)
            -- Function implementation goes here
        end,
    },
    FriendlyName = "MyApp",
}

local APIPackage = PrismExt:Authenticate(script, AppData)

if APIPackage then
    local Key = APIPackage.Key
    local AppAPI = APIPackage.AppAPI
    -- Use the Key and AppAPI as needed

    -- Example of using AppAPI.Write() function
    AppAPI:Write(Key, "This is a message from MyApp.")
end
```

### Sample Driver Structure
```lua
local DriverData = {
    Version = "1.0",
    API = {
        MyFunction = function(...)
            -- Function implementation goes here
        end,
    },
    FriendlyName = "MyDriver",
}

local APIPackage = PrismExt:AuthenticateDriver(script, DriverData)

if APIPackage then
    local Key = APIPackage.Key
    local AppAPI = APIPackage.AppAPI
    local PrismCore = APIPackage.PrismCore
    -- Use the Key, AppAPI, and PrismCore as needed

    -- Example of using AppAPI.Write() function
    AppAPI:Write(Key, "This is a message from MyDriver.")
end
```
### How are drivers different?

The big difference here is the PrismCore table. This lets you access majority of Prism's internal configurations, functions, and variables. You can use this to build on-to Prism and allow even bigger and stronger applications. 

This is what you can access with your driver:

 **Variables**
- ``PrismCore.Terminal`` - Table of all output messages
- ``PrismCore.ProdProducedInstances`` - Table of all produced instances under the ``Prod()`` function
- ``PrismCore.FunctionExecutionsOnHeartbeat`` - Table of functions that execute on each Prism heartbeat
- ``PrismCore.Flags`` - Configurations that can be updated in a live installation
- ``PrismCore.SelfSign`` - String certificate that is required for many PrismCore functions

**Functions**
- ``PrismCore:AppFgpt(CondensedData)`` - Our App Fingerprint function handles a lot of the indexing/data verification processing in Prism
- ``PrismCore:HeartBeat(...)`` - This function is designed to execute each time any function is called. You can integrate this feature into your driver and have it show up as part of Prism. 
- ``PrismCore:ValidateVersionString(str)`` - This uses simple string manipulation to verify that the app/driver is not trying to break Prism with their string in AppData 
- ``PrismCore:BlockApp(AppName)`` - This immediately cuts all access to the aforementioned app so it is not part of Prism anymore. This will also not allow it to communicate with other Prism apps. 
- ``PrismCore:ProcessFcn(PrivateKey, ...)`` - This function can be used to execute API. 

## Deprecated Functions

The following functions are deprecated and are no longer recommended for use:

- `PrismExt:VerifyIdentity(OneTimeKey)`,`SharedAPI:TerminateOneTimeKeys(AppRealKey, SpecificKey)`: These functions are deprecated because the OneTimeKey system is obsolete after security improvements throughout the entire framework.
- `PrismExt:Fcn(PrivateKey, ...)`, `PrismExt:FcnAsync(PrivateKey, ...)`, `PrismExt:f(PrivateKey,...)`, and `PrismExt:fa(PrivateKey, ...)`: These functions are deprecated because all Fcn and FcnAsync calls are now available in the AppAPI table.

Please note that while these functions are still present in the code for backward compatibility, their use is not recommended due to improvements in the security framework. It's always best to use the most up-to-date functions to ensure the highest level of security and performance.
