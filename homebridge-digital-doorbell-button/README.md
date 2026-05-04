# homebridge-digital-doorbell-button

Minimal Homebridge plugin that exposes:

- a tappable `Switch` tile in Apple Home
- a separate virtual `Doorbell` accessory
- a local webhook endpoint for the native iOS app in this repository

When the switch tile is turned on, or when the webhook receives a local request, the plugin sends a HomeKit `PROGRAMMABLE_SWITCH_EVENT` single-press notification on the virtual doorbell.

## What this is for

This gives you a "digital doorbell button" inside the Home app for testing or manual triggering, similar to pressing the ESP8266 Flash button on the Arduino sketch in the parent folder.

## Folder

- Plugin root: [homebridge-digital-doorbell-button](.)
- Full system documentation: [SYSTEM_GUIDE.md](../SYSTEM_GUIDE.md)

## Install for local development

1. Open a terminal in this folder.
2. Link the plugin into your Homebridge environment:

```bash
git clone https://github.com/ezefranca/doorbell_homekit.git
cd doorbell_homekit/homebridge-digital-doorbell-button
npm link
```

3. Restart Homebridge.

Homebridge's developer docs recommend `npm link` for loading a plugin from a development directory instead of publishing it first.

## Install from the GitHub repo without `npm link`

If you prefer a direct install:

```bash
git clone https://github.com/ezefranca/doorbell_homekit.git
cd doorbell_homekit
sudo npm install --location=global ./homebridge-digital-doorbell-button
```

## Example `config.json`

Add this to the `platforms` array in your Homebridge config:

```json
{
  "platform": "DigitalDoorbellBridge",
  "name": "Digital Doorbell",
  "buttonName": "Digital Doorbell Button",
  "doorbellName": "Digital Doorbell Chime",
  "autoOffMilliseconds": 1000,
  "webhookEnabled": true,
  "webhookHost": "0.0.0.0",
  "webhookPort": 51849,
  "webhookPath": "/doorbell/ring"
}
```

## Default webhook endpoint

With the default config, the native iOS app should POST to:

```text
http://homebridge.local:51849/doorbell/ring
```

## How it appears in Home

- `Digital Doorbell Button` shows as a switch tile you can tap
- `Digital Doorbell Chime` is the matching virtual doorbell accessory

Turning on the switch tile triggers the doorbell event and the tile resets back to off automatically.

Calling the webhook triggers the same doorbell event, which is how the iOS app forwards its button press into HomeKit.

## Notes

- This plugin is intentionally local and minimal. It does not call the ESP8266 directly.
- The user-facing behavior is the same HomeKit-side effect as pressing the Flash button in the Arduino sketch: a single doorbell press event.
- The iOS app uses its own camera locally; the plugin only bridges the ring event into HomeKit.

## Sources used

- Homebridge plugin API docs: https://developers.homebridge.io/homebridge/
- `AccessoryPlugin` / `StaticPlatformPlugin`: https://developers.homebridge.io/homebridge/interfaces/AccessoryPlugin.html and https://developers.homebridge.io/homebridge/interfaces/StaticPlatformPlugin.html
- HAP-NodeJS `Service.Doorbell`: https://developers.homebridge.io/HAP-NodeJS/classes/Service.html
- HAP-NodeJS `Characteristic.sendEventNotification(...)`: https://developers.homebridge.io/HAP-NodeJS/classes/Characteristic.html
