![image](https://github.com/carrcreative/prism/assets/173332208/3589c826-9bcd-4981-a8d4-d467307f21ea)



Find latest release: 
[https://github.com/carrcreative/prism/releases/tag/1.2
](https://github.com/carrcreative/prism/releases/tag/1.2)
# Prism Framework Documentation

## Overview
Prism is a powerful framework that provides a secure network of apps within the Roblox environment. It allows apps to authenticate, verify identity, and call functions in a secure and efficient manner.




### Prism Security 
![image](https://github.com/carrcreative/fusion/assets/173332208/500088ab-dfc5-46d6-a059-9098a6056a91)

**Introducing the Prism Security Network –** the pinnacle of secure, interconnected app development for Roblox Lua. With our unique registration system, each app receives a private key, ensuring secure interactions within the Prism ecosystem. Leverage the power of shared APIs, robust internal functions, and protected information storage, all under the Prism umbrella. Build with confidence and join the revolution in secure app design with Prism Security Network – where innovation meets security.


## Functions (after authentication)

### external:Authenticate(App, AppData)
This function authenticates an app and provides it with a unique key and console table. It takes two parameters:
- **App**: The app to be authenticated.
- **AppData**: A table containing the app’s details, including its version, description, and API.

### AppAPI:Fcn(PrivateKey,…)
This function calls ProcessFcn() with the provided private key and arguments. It takes at least one parameter:
- **PrivateKey**: The private key for the app.
- **...**: The arguments to be passed to the function.

### AppAPI:FcnAsync(PrivateKey, …)
This function calls ProcessFcn() asynchronously with the provided private key and arguments. It takes at least one parameter:
- **PrivateKey**: The private key for the app.
- **...**: The arguments to be passed to the function.

### AppAPI:f(PrivateKey,…)
This is a short form version of Fcn. It takes at least one parameter:
- **PrivateKey**: The private key for the app.
- **...**: The arguments to be passed to the function.

### AppAPI:fa(PrivateKey, …)
This is a short form version of FcnAsync. It takes at least one parameter:
- **PrivateKey**: The private key for the app.
- **...**: The arguments to be passed to the function.

## Sample Script

```lua
-- AppData for DataPlus, containing metadata
local AppData = {
	Version = "1.0",
	Description = "n/a",
	API = {},
	FriendlyName = "Git's Test App"
}

-- Authenticates with the Prism framework and starts the service
local Data = {}
local function AuthenticateWithPrism()
	local APIPackage = Prism:Authenticate(script, AppData) -- Prism will return our API package
	Data.PrivateKey = APIPackage.Key -- This is our private key. Without this, you cannot use Prism's API 
	Data.Console = APIPackage.AppAPI -- This is the table featuring important functions from Prism's core systems 
end

AuthenticateWithPrism()

-- Putting API calls in functions is easier if you're using the same API a lot 
local function CoolerPrint(...)
	Data.Console:Write(Data.PrivateKey, ...)
end

CoolerPrint("Hey cool dudes")

-- If this were a real function: 
-- Data.Console:f(Data.PrivateKey, "Ping")
-- It would return Pong! 
```

