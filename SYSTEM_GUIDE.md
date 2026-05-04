# Doorbell System Guide

This repository now contains two separate HomeKit-related pieces:

1. An ESP8266 firmware project that exposes a native HomeKit doorbell accessory.
2. A Homebridge plugin that exposes a tappable digital button tile and a matching virtual doorbell.

They solve different problems:

- The firmware gives you a direct HomeKit doorbell on the ESP8266.
- The Homebridge plugin gives you a software-only button inside the Home app for testing or manual triggering.

Important:

- The ESP8266 firmware and the Homebridge plugin are separate accessories.
- The plugin does not call the ESP8266 over HTTP or GPIO.
- The user-facing effect is similar: both create a HomeKit doorbell press event.

## Repository Layout

- Firmware guide and quick start: [README.md](README.md)
- Combined system guide: [SYSTEM_GUIDE.md](SYSTEM_GUIDE.md)
- ESP8266 sketch: [doorbell_homekit.ino](doorbell_homekit.ino)
- ESP8266 Wi-Fi helper: [wifi_info.h](wifi_info.h)
- ESP8266 HomeKit accessory definition: [my_accessory.c](my_accessory.c)
- Homebridge plugin: [homebridge-digital-doorbell-button](homebridge-digital-doorbell-button/)

## Component Summary

### 1. ESP8266 Firmware

Purpose:

- Runs directly on an ESP8266.
- Exposes a HomeKit `DOORBELL` service using `Mixiaoxiao/Arduino-HomeKit-ESP8266`.
- Uses the onboard Flash button (`GPIO0`) as the test button by default.

Current behavior:

- Press Flash button -> sends a single HomeKit doorbell event.
- Hold Flash button for 10 seconds -> clears stored HomeKit pairing data and reboots.
- First boot after flashing -> clears old HomeKit pairing data once, then reboots.
- If Wi-Fi reconnects later -> reboots once to re-advertise HomeKit, working around issue `#265`.

### 2. Homebridge Plugin

Purpose:

- Runs inside Homebridge on another machine, or the same machine if you want.
- Exposes:
  - one `Switch` tile you can tap in the Home app
  - one virtual `Doorbell` accessory
- Turning on the switch tile triggers the virtual doorbell and then auto-resets the switch back to off.

Current behavior:

- Tap switch tile in Home -> plugin triggers a doorbell event.
- The plugin does not talk to the ESP8266 directly.

## Text Flow Diagram

### Physical Doorbell Flow

```text
[User presses ESP8266 Flash button]
            |
            v
[GPIO0 goes LOW]
            |
            v
[doorbell_homekit.ino debounces button]
            |
            v
[Firmware sends HomeKit ProgrammableSwitchEvent = Single Press]
            |
            v
[Apple Home receives doorbell event]
            |
            v
[User sees / hears doorbell event in Home ecosystem]
```

### Digital Doorbell Flow

```text
[User taps Home app switch tile]
            |
            v
[Homebridge plugin receives Switch = ON]
            |
            v
[Plugin triggers virtual Doorbell ProgrammableSwitchEvent = Single Press]
            |
            +-----------------------> [Plugin auto-resets switch tile to OFF]
            |
            v
[Apple Home receives doorbell event]
            |
            v
[User sees / hears doorbell event in Home ecosystem]
```

### Combined Architecture

```text
              DIRECT ACCESSORY PATH

 [ESP8266 Firmware]
        |
        | HomeKit / HAP over Wi-Fi
        v
   [Apple Home]


               BRIDGED ACCESSORY PATH

 [Homebridge Plugin]
        |
        | Homebridge bridge -> HomeKit
        v
   [Apple Home]
```

## Firmware Installation

### Requirements

- Arduino IDE 2.x
- ESP8266 board package for Arduino
- `Mixiaoxiao/Arduino-HomeKit-ESP8266` library
- An ESP8266 board such as NodeMCU or Wemos D1 Mini

### Install Arduino IDE Support

1. Open Arduino IDE 2.x.
2. Go to `File > Preferences`.
3. Add this board manager URL:

```text
https://arduino.esp8266.com/stable/package_esp8266com_index.json
```

4. Open `Boards Manager`.
5. Install `esp8266` by ESP8266 Community.

### Install the HomeKit Library

1. Download the library ZIP:

```text
https://github.com/Mixiaoxiao/Arduino-HomeKit-ESP8266/archive/refs/heads/master.zip
```

2. In Arduino IDE, go to `Sketch > Include Library > Add .ZIP Library...`
3. Select the downloaded ZIP.

### Configure the Firmware

Get the code first:

```bash
git clone https://github.com/ezefranca/doorbell_homekit.git
cd doorbell_homekit
```

1. Open this folder in Arduino IDE.
2. Open [wifi_info.h](wifi_info.h).
3. Set:

```cpp
const char *ssid = "YOUR_WIFI_SSID";
const char *password = "YOUR_WIFI_PASSWORD";
```

### Required Arduino IDE Board Options

Set these in `Tools`:

- Board: your ESP8266 board, or `Generic ESP8266 Module`
- CPU Frequency: `160 MHz`
- LwIP Variant: `v2 Lower Memory`
- Debug Level: `None`
- SSL Support: `Basic SSL ciphers`
- Erase Flash: `All Flash Contents` on the first upload

### Upload the Firmware

1. Select the correct serial port.
2. Upload [doorbell_homekit.ino](doorbell_homekit.ino).
3. Open `Tools > Serial Monitor`.
4. Set baud rate to `115200`.

Expected first boot behavior:

- The ESP8266 clears old HomeKit pairing data once.
- It reboots once automatically.
- Then it connects to Wi-Fi and starts HomeKit normally.

### Add the Firmware Accessory to Apple Home

1. Make sure the ESP8266 is powered on and connected to Wi-Fi.
2. On iPhone, enable Bluetooth and use the same Wi-Fi network.
3. Open the `Home` app.
4. Tap `+` -> `Add Accessory`.
5. If needed, choose manual code entry.
6. Enter:

```text
111-11-111
```

7. Finish room/name assignment in the Home app.

### Firmware Notes

- The onboard Flash button on many ESP8266 boards is `GPIO0`.
- Do not hold the Flash button during power-on/reset or the board may enter flashing mode instead of booting the sketch.
- Garbled text before your sketch logs is normal ESP8266 ROM output at `74880` baud.
- Your sketch logs themselves use `115200`.

## Homebridge Installation

If you already have a working Homebridge instance, skip to `Plugin Installation`.

### macOS Installation via npm

The current official Homebridge macOS guide uses:

```bash
sudo npm install --location=global --unsafe-perm homebridge homebridge-config-ui-x
sudo hb-service install
```

After that, the Homebridge UI is typically available on port `8581`.

### Windows Installation via npm

The current official Windows guide uses:

```bash
npm install -g --unsafe-perm homebridge homebridge-config-ui-x
hb-service install
```

### Debian / Ubuntu / Raspberry Pi OS

The current official Homebridge recommendation is to install from the Homebridge apt repository rather than via npm. Use the official Debian / Ubuntu guide for the exact current commands:

- https://github.com/homebridge/homebridge/wiki/Install-Homebridge-on-Debian-or-Ubuntu-Linux

### Add Homebridge Itself to Apple Home

After Homebridge is running:

1. Open the Homebridge UI or logs.
2. Find the Homebridge pairing QR code or setup code.
3. In the iPhone `Home` app, tap `+` -> `Add Accessory`.
4. Scan the QR code shown by Homebridge, or enter its code manually.

Once the bridge is added, Homebridge accessories appear in Home automatically.

## Plugin Installation

Plugin folder:

- [homebridge-digital-doorbell-button](homebridge-digital-doorbell-button/)

### Option A: Local Development Install with `npm link`

Use this when the plugin lives in your local repo and you want Homebridge to load it directly from the folder.

```bash
git clone https://github.com/ezefranca/doorbell_homekit.git
cd doorbell_homekit/homebridge-digital-doorbell-button
npm link
```

Then restart Homebridge.

### Option B: Install the Local Folder Globally

If you prefer a direct local install instead of linking:

```bash
git clone https://github.com/ezefranca/doorbell_homekit.git
cd doorbell_homekit
sudo npm install --location=global ./homebridge-digital-doorbell-button
```

Then restart Homebridge.

### Plugin Configuration

Add this to the `platforms` array in your Homebridge `config.json`:

```json
{
  "platform": "DigitalDoorbellBridge",
  "name": "Digital Doorbell",
  "buttonName": "Digital Doorbell Button",
  "doorbellName": "Digital Doorbell Chime",
  "autoOffMilliseconds": 1000
}
```

### What Appears in Apple Home

After Homebridge restarts and the bridge is already paired to Home:

- `Digital Doorbell Button` appears as a switch tile
- `Digital Doorbell Chime` appears as a virtual doorbell accessory

When the switch tile is turned on:

- Homebridge sends a single-press event to the virtual doorbell
- the switch turns itself back off automatically

## End-to-End Usage

### To Test the Physical Doorbell

1. Power on the ESP8266.
2. Wait for Wi-Fi and HomeKit startup messages at `115200`.
3. Press the Flash button briefly.
4. The firmware sends a doorbell event.

### To Test the Digital Doorbell

1. Make sure Homebridge is running with the plugin loaded.
2. Open the `Home` app.
3. Tap the `Digital Doorbell Button` switch tile.
4. The plugin triggers the virtual doorbell event.
5. The switch resets to off automatically.

## Troubleshooting

### Firmware says pairing is disabled

If you see logs like:

```text
Found admin pairing ..., disabling pair setup
```

that means old HomeKit pairing data already exists in the ESP8266 storage. The current firmware already handles this on first boot after flashing by performing a one-time reset. If you still need to clear pairing later:

- hold the Flash button for 10 seconds, or
- uncomment `homekit_storage_reset()` temporarily in the sketch and flash once

### Firmware keeps showing garbled characters

- ROM boot output is at `74880`
- sketch logs are at `115200`
- keep the Serial Monitor at `115200` for the useful application logs

### Plugin does not appear in Homebridge

Check:

```bash
npm list -g --depth=0
```

and verify that Homebridge can see the plugin package.

If using local development mode, run:

```bash
cd doorbell_homekit/homebridge-digital-doorbell-button
npm link
```

again, then restart Homebridge.

### Plugin appears in Homebridge but not in Home

- confirm the Homebridge bridge itself is already paired to Apple Home
- restart Homebridge
- check the Homebridge logs for plugin startup errors

## Source References

Firmware and HomeKit library:

- https://github.com/Mixiaoxiao/Arduino-HomeKit-ESP8266
- https://github.com/Mixiaoxiao/Arduino-HomeKit-ESP8266/issues/265

Homebridge:

- https://developers.homebridge.io/homebridge/
- https://github.com/homebridge/homebridge
- https://github.com/homebridge/homebridge/wiki/Install-Homebridge-on-macOS
- https://github.com/homebridge/homebridge/wiki/Install-Homebridge-on-Windows-10
- https://github.com/homebridge/homebridge/wiki/Install-Homebridge-on-Debian-or-Ubuntu-Linux

HAP-NodeJS:

- https://developers.homebridge.io/HAP-NodeJS/classes/Service.html
- https://developers.homebridge.io/HAP-NodeJS/classes/Characteristic.html
