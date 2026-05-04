#include <Arduino.h>
#include <EEPROM.h>
#include <ESP8266WiFi.h>
#include <arduino_homekit_server.h>
#include "wifi_info.h"

#if !defined(ARDUINO_ARCH_ESP8266)
#error This sketch requires an ESP8266 board package.
#endif

constexpr uint8_t kDoorbellButtonPin = 0;  // GPIO0 / Flash button on many ESP8266 dev boards
constexpr uint32_t kDebounceMs = 40;
constexpr uint32_t kFactoryResetHoldMs = 10000;
constexpr uint32_t kLoopDelayMs = 10;
constexpr uint32_t kHeapLogIntervalMs = 5000;
constexpr uint8_t kHomeKitSinglePress = 0;
constexpr size_t kEepromSize = 4096;
constexpr int kInitialResetMarkerAddress = 1500;
constexpr uint8_t kInitialResetMarkerValue = 0x42;

bool last_button_reading = HIGH;
bool stable_button_state = HIGH;
uint32_t last_button_change_ms = 0;
uint32_t button_pressed_ms = 0;
uint32_t next_heap_log_ms = 0;
bool factory_reset_fired = false;

extern "C" {
extern homekit_server_config_t config;
extern homekit_characteristic_t cha_programmable_switch_event;
}

homekit_value_t doorbell_event_getter() {
  return HOMEKIT_NULL_CPP();
}

void ring_doorbell() {
  Serial.println(F("Doorbell pressed"));
  cha_programmable_switch_event.value.uint8_value = kHomeKitSinglePress;
  homekit_characteristic_notify(
      &cha_programmable_switch_event, cha_programmable_switch_event.value);
}

void reset_homekit_pairing() {
  Serial.println(F("Resetting HomeKit pairing storage"));
  homekit_storage_reset();
  delay(1000);
  ESP.restart();
}

void maybe_run_initial_homekit_reset() {
  EEPROM.begin(kEepromSize);
  const uint8_t marker = EEPROM.read(kInitialResetMarkerAddress);
  if (marker == kInitialResetMarkerValue) {
    EEPROM.end();
    return;
  }

  Serial.println(F("First boot detected, clearing old HomeKit pairing data"));
  homekit_storage_reset();

  // homekit_storage_reset() reformats the same EEPROM-backed flash sector,
  // so the marker must be written only after the reset is complete.
  EEPROM.begin(kEepromSize);
  EEPROM.write(kInitialResetMarkerAddress, kInitialResetMarkerValue);
  EEPROM.commit();
  EEPROM.end();
  Serial.println(F("Initial HomeKit reset complete, restarting"));
  delay(1000);
  ESP.restart();
}

void poll_doorbell_button() {
  const bool reading = digitalRead(kDoorbellButtonPin);
  const uint32_t now = millis();

  if (reading != last_button_reading) {
    last_button_reading = reading;
    last_button_change_ms = now;
  }

  if ((now - last_button_change_ms) < kDebounceMs) {
    return;
  }

  if (reading == stable_button_state) {
    if (stable_button_state == LOW &&
        !factory_reset_fired &&
        (now - button_pressed_ms) >= kFactoryResetHoldMs) {
      factory_reset_fired = true;
      reset_homekit_pairing();
    }
    return;
  }

  stable_button_state = reading;
  if (stable_button_state == LOW) {
    button_pressed_ms = now;
    factory_reset_fired = false;
    ring_doorbell();
  } else {
    button_pressed_ms = 0;
    factory_reset_fired = false;
  }
}

void log_heap_if_needed() {
  const uint32_t now = millis();
  if (now < next_heap_log_ms) {
    return;
  }

  next_heap_log_ms = now + kHeapLogIntervalMs;
  Serial.printf("Free heap: %u, HomeKit clients: %d\n",
                ESP.getFreeHeap(),
                arduino_homekit_connected_clients_count());
}

void setup() {
  Serial.begin(115200);
  pinMode(kDoorbellButtonPin, INPUT_PULLUP);
  last_button_reading = digitalRead(kDoorbellButtonPin);
  stable_button_state = last_button_reading;
  button_pressed_ms = (stable_button_state == LOW) ? millis() : 0;

  maybe_run_initial_homekit_reset();

  wifi_connect();

  // Uncomment once if you need to force a fresh HomeKit pairing on next boot.
  // homekit_storage_reset();

  cha_programmable_switch_event.getter = doorbell_event_getter;
  arduino_homekit_setup(&config);
}

void loop() {
  if (wifi_just_reconnected()) {
    // Work around the pairing/discovery failure reported in issue #265:
    // after Wi-Fi returns, restart so HomeKit is advertised over mDNS again.
    Serial.println(F("WiFi reconnected, restarting HomeKit advertisement"));
    delay(1000);
    ESP.restart();
  }

  poll_doorbell_button();
  arduino_homekit_loop();
  log_heap_if_needed();
  delay(kLoopDelayMs);
}
