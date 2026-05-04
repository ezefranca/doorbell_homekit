# iOS Doorbell Panel

This folder contains a native SwiftUI iOS app that mimics a smart doorbell panel:

- full-screen live camera preview from the iPhone or iPad camera
- a large ring button
- optional Homebridge webhook forwarding for HomeKit doorbell events

## Important limitation

This app can present the camera and send a ring event, but a native iOS app does not directly publish itself as a HomeKit accessory inside the Home app. The HomeKit integration in this repo is therefore routed through Homebridge:

```text
iOS app ring button -> HTTP webhook -> Homebridge plugin -> HomeKit doorbell event
```

The camera preview remains native to the app, which keeps it separate from the ESP8266 accessory video path.

## Project files

- Tuist manifest: [Project.swift](Project.swift)
- App sources: [DoorbellPanel](DoorbellPanel/)
- Root integration guide: [../SYSTEM_GUIDE.md](../SYSTEM_GUIDE.md)

## Generate and open in Xcode

```bash
cd iOS
tuist generate
open DoorbellPanel.xcodeproj
```

## Homebridge webhook

Set the webhook URL in the app’s settings sheet to point to the Homebridge plugin endpoint, for example:

```text
http://homebridge.local:51849/doorbell/ring
```

That endpoint is added by the Homebridge plugin in this repository.

