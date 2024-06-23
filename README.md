![image](https://github.com/carrcreative/fusion/assets/173332208/207bf28e-d697-4502-a85a-51794a1ddf66)
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

Find latest release: 
https://github.com/dylancarr99/fusion/releases/tag/stable

## Introduction 
Fusion is a security-centric framework that streamlines the development process on Roblox, offering developers a seamless and secure way to manage their game’s operations. It emphasizes ease of use, allowing creators to implement robust features without compromising on safety. Fusion’s architecture is designed to protect data integrity and provide a trustworthy environment for both developers and players. It’s an indispensable tool for building resilient and secure Roblox applications with confidence.

# Fusion Framework Documentation

## Overview
Fusion is a powerful framework that provides a secure network of apps within the Roblox environment. It allows apps to authenticate, verify identity, and call functions in a secure and efficient manner.

## Functions

### external:Authenticate(App, AppData)
This function authenticates an app and provides it with a unique key and console table. It takes two parameters:
- **App**: The app to be authenticated.
- **AppData**: A table containing the app’s details, including its version, description, and API.

### external:VerifyIdentity(OneTimeKey)
This function verifies the identity of an app using a one-time key. It takes one parameter:
- **OneTimeKey**: The one-time key used for verification.

### external:Fcn(PrivateKey,…)
This function calls ProcessFcn() with the provided private key and arguments. It takes at least one parameter:
- **PrivateKey**: The private key for the app.
- **...**: The arguments to be passed to the function.

### external:FcnAsync(PrivateKey, …)
This function calls ProcessFcn() asynchronously with the provided private key and arguments. It takes at least one parameter:
- **PrivateKey**: The private key for the app.
- **...**: The arguments to be passed to the function.

### external:f(PrivateKey,…)
This is a short form version of Fcn. It takes at least one parameter:
- **PrivateKey**: The private key for the app.
- **...**: The arguments to be passed to the function.

### external:fa(PrivateKey, …)
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

-- Authenticates with the Fusion framework and starts the service
local Data = {}
local function AuthenticateWithFusion()
	local APIPackage = Fusion:Authenticate(script, AppData) -- Fusion will return our API package
	Data.PrivateKey = APIPackage.Key -- This is our private key. Without this, you cannot use Fusion's API 
	Data.Console = APIPackage.AppAPI -- This is the table featuring important functions from Fusion's core systems 
	Data.API = APIPackage.External 
end

AuthenticateWithFusion()

-- Putting API calls in functions is easier if you're using the same API a lot 
local function CoolerPrint(...)
	Data.Console:Write(Data.PrivateKey, ...)
end

CoolerPrint("Hey cool dudes")

-- If this were a real function: 
-- Data.API:f(Data.PrivateKey, "Ping")
-- It would return Pong! 
```

