#pragma once
#include <Arduino.h>

// BLE UUIDs
#define SERVICE_UUID        "0000FFE0-0000-1000-8000-00805F9B34FB"
#define NOTIFY_CHAR_UUID    "0000FFE2-0000-1000-8000-00805F9B34FB"
#define WRITE_CHAR_UUID     "0000FFE1-0000-1000-8000-00805F9B34FB"

// Addresses
#define ADDR_CONTROL          11
#define ADDR_TIME_CHANNEL     12

// Commands
#define CMD_STOP_UPLOAD       0
#define CMD_START_UPLOAD      1
#define CMD_CLEAR_DATA        255

// Button Pins (ESP32-S3 GPIOs)
#define PIN_BTN_VIEW         4  // Button 1: Toggle View
#define PIN_BTN_BRIGHT       5  // Button 2: Toggle Brightness
#define PIN_BTN_RECONNECT    6  // Button 3: Reconnect

// Data Field Configuration
struct DataFieldConfig {
    uint16_t address;
    uint8_t size; // 1=u8, 2=u16, 4=u32
    float k;
    float b;
    const char* name;
    const char* unit;
};

// Target Fields to Monitor
const DataFieldConfig TARGET_FIELDS[] = {
    {24,  2, 10.0f,  0.0f,  "Speed",   "km/h"}, // Speed
    {26,  2, 1.0f,   0.0f,  "SoC",     "%"},    // SoC
    {105, 2, 1.0f,   0.0f,  "RPM",     "rpm"},  // RPM
    {113, 2, 10.0f,  0.0f,  "Volt",    "V"},    // Battery Voltage
    {115, 2, 1000.0f,0.0f,  "Power",   "KW"},   // Power
    {119, 2, 10.0f,  0.0f,  "Current", "A"},    // Current
    {220, 2, 744.3f, 0.0f,  "Throt",   "V"},    // Throttle Voltage
    {222, 1, 1.0f,   40.0f, "Temp",    "C"}     // Controller Temp
};

const int NUM_FIELDS = sizeof(TARGET_FIELDS) / sizeof(TARGET_FIELDS[0]);
