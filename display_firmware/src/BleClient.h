#pragma once
#include <NimBLEDevice.h>
#include "Protocol.h"

class BleClientManager {
public:
    bool isConnected = false;
    bool isScanning = false;
    NimBLEClient* pClient = nullptr;
    NimBLERemoteService* pService = nullptr;
    NimBLERemoteCharacteristic* pWriteChar = nullptr;
    NimBLERemoteCharacteristic* pNotifyChar = nullptr;

    typedef std::function<void(uint16_t addr, float val)> DataCallback;
    DataCallback onDataReceived;

    void init() {
        NimBLEDevice::init("HarvTech-Display");
        NimBLEDevice::setPower(ESP_PWR_LVL_P9);
    }

    void startScan() {
        if(isConnected) return;
        auto pScan = NimBLEDevice::getScan();
        pScan->setInterval(45);
        pScan->setWindow(15);
        pScan->setActiveScan(true);
        pScan->start(0, scanEndedCB);
        isScanning = true;
    }

    static void scanEndedCB(NimBLEScanResults results) {
        // restart scan in main loop if needed
    }

    bool connectToServer(NimBLEAdvertisedDevice* device) {
        pClient = NimBLEDevice::createClient();
        
        if(pClient->connect(device)) {
            isConnected = true;
            
            // Discover Service
            pService = pClient->getService(SERVICE_UUID);
            if(pService) {
                pWriteChar = pService->getCharacteristic(WRITE_CHAR_UUID);
                pNotifyChar = pService->getCharacteristic(NOTIFY_CHAR_UUID);
                
                if(pNotifyChar) {
                     if(pNotifyChar->canNotify()) {
                         pNotifyChar->subscribe(true, notifyCallback);
                     }
                }
                return true;
            }
        }
        return false;
    }

    void configureDataStream() {
        if(!pWriteChar) return;

        // 1. Stop Upload
        auto stopCmd = Protocol::createControlCommand(CMD_STOP_UPLOAD);
        pWriteChar->writeValue(stopCmd, false);
        delay(200);

        // 2. Clear Data
        auto clearCmd = Protocol::createControlCommand(CMD_CLEAR_DATA);
        pWriteChar->writeValue(clearCmd, false);
        delay(200);

        // 3. Setup Channels
        for(int i=0; i<NUM_FIELDS; i++) {
            auto setupCmd = Protocol::createChannelSetupCommand(
                TARGET_FIELDS[i].address, 
                TARGET_FIELDS[i].size
            );
            pWriteChar->writeValue(setupCmd, false);
            delay(50);
        }
        delay(100);

        // 4. Start Upload
        auto startCmd = Protocol::createControlCommand(CMD_START_UPLOAD);
        pWriteChar->writeValue(startCmd, false);
    }

    static void notifyCallback(NimBLERemoteCharacteristic* pChar, uint8_t* pData, size_t length, bool isNotify) {
        Protocol::ParsedData data = Protocol::parsePacket(pData, length);
        if(data.valid && instance && instance->onDataReceived) {
            instance->onDataReceived(data.address, data.value);
        }
    }
    
    // Singleton access helper
    static BleClientManager* instance;
    BleClientManager() { instance = this; }
};

BleClientManager* BleClientManager::instance = nullptr;
