# ESP8266 HomeKit Doorbell

Minimal HomeKit doorbell firmware for ESP8266, plus a separate Homebridge plugin for a digital Home app trigger.

Full combined documentation is in [SYSTEM_GUIDE.md](/Users/ezequiel.santos/Documents/Arduino/doorbell_homekit/SYSTEM_GUIDE.md).

## Sketch layout

- Primary sketch: [doorbell_homekit.ino](/Users/ezequiel.santos/Documents/Arduino/doorbell_homekit/doorbell_homekit.ino)
- Wi-Fi config and reconnect logic: [wifi_info.h](/Users/ezequiel.santos/Documents/Arduino/doorbell_homekit/wifi_info.h)
- HomeKit accessory definition: [my_accessory.c](/Users/ezequiel.santos/Documents/Arduino/doorbell_homekit/my_accessory.c)
- Homebridge plugin: [homebridge-digital-doorbell-button](/Users/ezequiel.santos/Documents/Arduino/doorbell_homekit/homebridge-digital-doorbell-button)

## What it does

- Connects an ESP8266 to Wi-Fi
- Exposes one HomeKit accessory with the `DOORBELL` service
- Sends a `PROGRAMMABLE_SWITCH_EVENT` single-press event whenever the button is pressed
- Restarts the ESP after Wi-Fi reconnects so HomeKit is advertised again
- Automatically clears old HomeKit pairing data on the first boot after upload, then restarts once
- Clears stored HomeKit pairing data if the button is held for 10 seconds

For the full firmware + Homebridge + Home app setup flow, use [SYSTEM_GUIDE.md](/Users/ezequiel.santos/Documents/Arduino/doorbell_homekit/SYSTEM_GUIDE.md).

## Wiring

- Configure `kDoorbellButtonPin` in [doorbell_homekit.ino](/Users/ezequiel.santos/Documents/Arduino/doorbell_homekit/doorbell_homekit.ino)
- Current default is `GPIO0`, using the onboard `Flash` button on many NodeMCU / Wemos D1 Mini style ESP8266 boards
- If you want to use an external button instead, change the pin and wire a normally-open button between that pin and `GND`
- The sketch uses `INPUT_PULLUP`, so idle is `HIGH` and a press pulls the pin `LOW`

## Arduino IDE 2.x setup

1. Open this folder in Arduino IDE 2.x.
2. Install the ESP8266 board package if needed:
   File: `Preferences` -> add `https://arduino.esp8266.com/stable/package_esp8266com_index.json` to `Additional boards manager URLs`.
3. Open `Boards Manager` and install `esp8266` by ESP8266 Community.
4. Install the HomeKit library:
   Download `https://github.com/Mixiaoxiao/Arduino-HomeKit-ESP8266/archive/refs/heads/master.zip`
   Then use `Sketch > Include Library > Add .ZIP Library...`
5. Edit Wi-Fi credentials in [wifi_info.h](/Users/ezequiel.santos/Documents/Arduino/doorbell_homekit/wifi_info.h).
6. Select your board and set the important tool options:
   Board: your ESP8266 board, or `Generic ESP8266 Module` if you want the full option set
   CPU Frequency: `160 MHz`
   LwIP Variant: `v2 Lower Memory`
   Debug Level: `None`
   SSL Support: `Basic SSL ciphers`
   Erase Flash: `All Flash Contents` on the first upload
7. Upload the sketch.
8. Open `Tools > Serial Monitor` and set the baud rate to `115200`.
9. On the first boot after upload, the sketch clears old HomeKit pairing data and restarts once. Wait for that reboot to finish.
10. Pair it in Apple Home with setup code `111-11-111`.

## Add to iOS Home App

1. Make sure the ESP8266 is powered on, connected to Wi-Fi, and showing no boot errors in Serial Monitor at `115200`.
   On the very first boot after flashing, expect one automatic reset before pairing.
2. On your iPhone, turn on `Bluetooth` and make sure the iPhone is on the same Wi-Fi network you want to use with Home.
3. Open the `Home` app.
4. Tap `+`, then tap `Add Accessory`.
5. Because this sketch uses a manual HomeKit setup code and does not provide a QR code, choose the path to enter a code manually if iOS first asks to scan.
6. Enter the HomeKit setup code: `111-11-111`.
7. When the accessory appears, tap it. If iOS asks to add the accessory to your network, tap `Allow`.
8. Choose a room, name the accessory, tap `Continue`, then tap `Done`.

If the accessory was previously paired and iOS says it was already added, hold the doorbell button for 10 seconds to clear stored HomeKit pairing data, then try again.

## Notes

- The restart-after-reconnect behavior is a workaround for the pairing/discovery problem discussed in issue `#265`, where accessories can stop appearing after Wi-Fi or router interruptions.
- The sketch uses `Serial.begin(115200)`, so use `115200` in Arduino IDE's Serial Monitor.
- The sketch stores a one-time marker at EEPROM address `1500`, which is outside the HomeKit library's documented storage range (`0` to `1408`). That marker is written only after the HomeKit reset completes, so the initial pairing reset runs once and does not loop.
- The default test button is `GPIO0` / the onboard Flash button. Do not hold it while powering on or resetting the ESP8266, or the board may enter flashing/program mode instead of starting the sketch.
- Hold the doorbell button for 10 seconds to clear stored HomeKit pairing data and reboot.
- If you want an immediate one-time reset during development, uncomment `homekit_storage_reset()` in [doorbell_homekit.ino](/Users/ezequiel.santos/Documents/Arduino/doorbell_homekit/doorbell_homekit.ino), upload once, then comment it again.
- The upstream library documents `DOORBELL` as mainly intended for video doorbells and notes it may not work standalone on every HomeKit client. If Home does not present it correctly, the fallback is to switch the service to `STATELESS_PROGRAMMABLE_SWITCH`.
- [platformio.ini](/Users/ezequiel.santos/Documents/Arduino/doorbell_homekit/platformio.ini) is optional and not used by Arduino IDE.
