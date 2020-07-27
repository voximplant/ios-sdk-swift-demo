# Voximplant Video Call Demo (iOS)

This demo demonstrates basic video call functionality of the Voximplant iOS SDK. The application supports video calls between this iOS app and other apps that use any Voximplant SDK.

> This demo application doesn't handle push notifications, so it doesn't receive incoming calls if the application is in the background or killed.

#### Features
The application is able to:
- log in to the Voximplant Cloud
- auto login using access tokens
- make an video call
- receive an incoming call
- put a call on hold / take it off hold
- change an audio device (speaker, receiver, wired headset, bluetooth headset) during a call
- switch camera during a call
- mute video during a call
- send DTMF
- auto reconnect/relogin


## Getting started

To get started, you'll need to [register](https://manage.voximplant.com/auth/sign_up) a free Voximplant developer account.

You'll need the following:
- Voximplant application
- two Voximplant users
- VoxEngine scenario
- routing setup

### Automatic
We've implemented a special template to enable you to quickly use the demo – just 
install [SDK tutorial](https://manage.voximplant.com/marketplace/sdk_tutorial) from our marketplace:
![marketplace](Screenshots/market.png)

### Manual

You can set up it manually using our [Gettins started](https://voximplant.com/docs/introduction) guide and tutorials

#### VoxEngine scenario example:
  ```
  VoxEngine.addEventListener(AppEvents.CallAlerting, (e) => {
  const newCall = VoxEngine.callUserDirect(
    e.call, 
    e.destination,
    e.callerid,
    e.displayName,
    null
  );
  VoxEngine.easyProcess(e.call, newCall, ()=>{}, true);
  });
  ```

## Installing

1. Clone this repo 

1. Run `$ pod install` in the repo folder

1. Open the `Swift.xcworkspace` workspace

1. Target VideoCall and build the project using Xcode

## Usage

### User login
![login](Screenshots/login.png)

Log in using:
* Voximplant user name in the format `user@app.account`
* password

See the following classes for code details:
- [AuthService.swift](Services/AuthService.swift)
- [LoginViewController.swift](Stories/LoginViewController.swift)

### Make or receive calls
![call](Screenshots/call.png)

Enter a Voximplant user name to the input field and press "Call" button to make a call.

See the following classes for code details:
- [CallManager.swift](Services/CallManager.swift)
- [MainViewController.swift](Stories/MainViewController.swift)
- [IncomingCallViewController.swift](Stories/IncomingCallViewController.swift)

### Call controls
![inCall](Screenshots/inCall.png)

Mute, hold, change an audio device or switch camera during a call.

See the following classes for code details:
- [CallViewController.swift](Stories/CallViewController.swift)
  

## Useful links
1. [Getting started](https://voximplant.com/docs/introduction)
2. [Voximplant iOS SDK reference](https://voximplant.com/docs/references/iossdk)
3. [Installing the Voximplant iOS SDK](https://voximplant.com/docs/introduction/integration/adding_sdks/installing/ios_sdk)
4. [HowTo's](https://voximplant.com/docs/howtos) 
