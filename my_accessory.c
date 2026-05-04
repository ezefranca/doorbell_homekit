#include <stdio.h>
#include <homekit/characteristics.h>
#include <homekit/homekit.h>

void my_accessory_identify(homekit_value_t _value) {
    printf("accessory identify\n");
}

homekit_characteristic_t cha_programmable_switch_event =
    HOMEKIT_CHARACTERISTIC_(PROGRAMMABLE_SWITCH_EVENT, 0);

homekit_accessory_t *accessories[] = {
    HOMEKIT_ACCESSORY(.id=1, .category=homekit_accessory_category_video_door_bell,
        .services=(homekit_service_t*[]) {
            HOMEKIT_SERVICE(ACCESSORY_INFORMATION, .characteristics=(homekit_characteristic_t*[]) {
                HOMEKIT_CHARACTERISTIC(NAME, "Front Doorbell"),
                HOMEKIT_CHARACTERISTIC(MANUFACTURER, "Custom"),
                HOMEKIT_CHARACTERISTIC(SERIAL_NUMBER, "doorbell-001"),
                HOMEKIT_CHARACTERISTIC(MODEL, "ESP8266 Doorbell"),
                HOMEKIT_CHARACTERISTIC(FIRMWARE_REVISION, "1.0"),
                HOMEKIT_CHARACTERISTIC(IDENTIFY, my_accessory_identify),
                NULL
            }),
            HOMEKIT_SERVICE(DOORBELL, .primary=true, .characteristics=(homekit_characteristic_t*[]) {
                HOMEKIT_CHARACTERISTIC(NAME, "Front Doorbell"),
                &cha_programmable_switch_event,
                NULL
            }),
            NULL
        }),
    NULL
};

homekit_server_config_t config = {
    .accessories = accessories,
    .password = "111-11-111"
};

