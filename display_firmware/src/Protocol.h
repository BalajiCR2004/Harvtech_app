#pragma once
#include <Arduino.h>
#include <vector>
#include "Config.h"

class Protocol {
public:
    // Create command to setup a Time Data channel
    static std::vector<uint8_t> createChannelSetupCommand(uint16_t address, uint8_t size) {
        // 1. Create Read Command: [AddrLow] [AddrHigh | 0x80] [Size]
        uint8_t low = address & 0xFF;
        uint8_t high = (address >> 8) & 0xFF;
        
        // Note: For channel setup, we actually need the "clean" read command structure
        // but modified as the payload for Address 12.
        // Flutter logic: modifiedCmd[1] = modifiedCmd[1] & 0x1F;
        // The original read command construct in Flutter: [Low, High | 0x80, Size]
        // The modification clears the 0x80 bit? 
        // Let's replicate logic exactly:
        // Flutter: [Low, High | 0x80, Size] -> Then & 0x1F on byte 1 -> [Low, High & 0x1F, Size]
        
        // Effective payload for addr 12: [AddrLow, AddrHigh & 0x1F, Size]
        uint8_t payload[] = {
            low,
            (uint8_t)(high & 0x1F), // Ensure high bit is clear
            size
        };

        // Wrap in Write Command to Address 12: [12, 0, Payload...]
        // Write Command: [AddrLow, AddrHigh & 0x1F, Data...]
        // Addr 12 is 0x0C.
        std::vector<uint8_t> cmd;
        cmd.push_back(ADDR_TIME_CHANNEL & 0xFF);
        cmd.push_back((ADDR_TIME_CHANNEL >> 8) & 0x1F);
        
        for(int i=0; i<3; i++) {
            cmd.push_back(payload[i]);
        }
        
        return cmd;
    }

    static std::vector<uint8_t> createControlCommand(uint8_t subCmd) {
        // Write to Address 11 (0x0B)
        std::vector<uint8_t> cmd;
        cmd.push_back(ADDR_CONTROL & 0xFF);
        cmd.push_back((ADDR_CONTROL >> 8) & 0x1F);
        cmd.push_back(subCmd);
        return cmd;
    }

    struct ParsedData {
        uint16_t address;
        float value;
        bool valid;
    };

    static ParsedData parsePacket(const uint8_t* data, size_t length) {
        ParsedData result = {0, 0, false};
        if(length < 3) return result;

        // Header: [AddrLow] [AddrHigh | Flags]
        uint8_t low = data[0];
        uint8_t highByte = data[1];
        
        // Extract Address (Mask out flags 0xE0)
        uint16_t address = ((highByte & 0x1F) << 8) | low;
        result.address = address;

        // Find config for this address
        const DataFieldConfig* cfg = nullptr;
        for(int i=0; i<NUM_FIELDS; i++) {
            if(TARGET_FIELDS[i].address == address) {
                cfg = &TARGET_FIELDS[i];
                break;
            }
        }

        if(!cfg) return result;
        
        // payload starts at index 2
        // Check size
        if(length < 2 + cfg->size) return result;

        // Convert Raw
        int32_t raw = 0;
        if(cfg->size == 1) {
            raw = (int8_t)data[2]; // signed char ? or unsigned. Context says u8 for temp, i8 for motor temp.
            // Our config says u8 for Temp(222).
             if(address == 222) raw = (uint8_t)data[2];
             else raw = (int8_t)data[2]; // Default assume signed for others if size 1
        } else if(cfg->size == 2) {
             // Little Endian
             int16_t val16 = (int16_t)(data[2] | (data[3] << 8));
             // Check if u16
             if(address == 24 || address == 26 || address == 113 || address == 220) {
                 raw = (uint16_t)(data[2] | (data[3] << 8));
             } else {
                 raw = val16;
             }
        } else if (cfg->size == 4) {
             raw = (int32_t)(data[2] | (data[3] << 8) | (data[4] << 16) | (data[5] << 24));
        }

        // Calibrate: (Raw - B) / K
        result.value = (raw - cfg->b) / cfg->k;
        result.valid = true;
        
        return result;
    }
};
