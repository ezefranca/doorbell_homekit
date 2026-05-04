#ifndef WIFI_INFO_H_
#define WIFI_INFO_H_

#include <Arduino.h>
#include <ESP8266WiFi.h>

const char *ssid = "YOUR_WIFI_SSID";
const char *password = "YOUR_WIFI_PASSWORD";

const uint32_t kWiFiCheckIntervalMs = 5000;
const uint32_t kWiFiReconnectRetryMs = 30000;

uint32_t last_wifi_check_ms = 0;
uint32_t last_wifi_retry_ms = 0;
bool wifi_was_connected = false;

void wifi_connect() {
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(ssid, password);

  Serial.print(F("WiFi connecting"));
  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
    Serial.print(F("."));
  }
  Serial.println();
  Serial.print(F("WiFi connected, IP: "));
  Serial.println(WiFi.localIP());

  wifi_was_connected = true;
  last_wifi_check_ms = millis();
  last_wifi_retry_ms = last_wifi_check_ms;
}

bool wifi_just_reconnected() {
  const uint32_t now = millis();
  if ((now - last_wifi_check_ms) < kWiFiCheckIntervalMs) {
    return false;
  }

  last_wifi_check_ms = now;
  const bool wifi_is_connected = (WiFi.status() == WL_CONNECTED);

  if (wifi_was_connected && !wifi_is_connected) {
    wifi_was_connected = false;
    Serial.println(F("WiFi disconnected"));
  } else if (!wifi_was_connected && wifi_is_connected) {
    wifi_was_connected = true;
    return true;
  }

  if (!wifi_is_connected && (now - last_wifi_retry_ms) >= kWiFiReconnectRetryMs) {
    last_wifi_retry_ms = now;
    Serial.println(F("Retrying WiFi connection"));
    WiFi.disconnect();
    WiFi.begin(ssid, password);
  }

  return false;
}

#endif  // WIFI_INFO_H_

