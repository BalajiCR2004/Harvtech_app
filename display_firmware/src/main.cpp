#include <Arduino.h>
#include "BleClient.h"
#include "Display.h"
#include "Input.h"

BleClientManager bleClient;
DisplayManager display;

Button btnView(PIN_BTN_VIEW);
Button btnBright(PIN_BTN_BRIGHT);
Button btnReconnect(PIN_BTN_RECONNECT);

bool wasConnected = false;
unsigned long lastScan = 0;

// Scan callback
class AdvertisedDeviceCallbacks: public NimBLEAdvertisedDeviceCallbacks {
    void onResult(NimBLEAdvertisedDevice* advertisedDevice) {
        std::string name = advertisedDevice->getName();
        
        if (name.length() > 0) {
            bool match = false;
            if (name.find("speed") != std::string::npos) match = true;
            if (name.find("cjpower") != std::string::npos) match = true;
            if (name.find("cj-power") != std::string::npos) match = true;
            
            if (match) {
                NimBLEDevice::getScan()->stop();
                display.updateStatus("Connecting...", TFT_BLUE);
                
                if(bleClient.connectToServer(advertisedDevice)) {
                    display.updateStatus("Connected!", TFT_GREEN);
                    delay(500);
                    display.updateStatus("Configuring...", TFT_ORANGE);
                    bleClient.configureDataStream();
                    display.updateStatus("Active", TFT_GREEN);
                } else {
                    display.updateStatus("Failed", TFT_RED);
                    delay(1000);
                    display.updateStatus("Scanning...", TFT_MAGENTA);
                    NimBLEDevice::getScan()->start(0, BleClientManager::scanEndedCB);
                }
            }
        }
    }
};

void setup() {
    Serial.begin(115200);
    
    // Init Buttons
    btnView.init();
    btnBright.init();
    btnReconnect.init();
    
    display.init();
    
    // Init Buttons
    btnView.init();
    btnBright.init();
    btnReconnect.init();
    
    display.init();
    
    // Show Logo
    display.showLogo();
    delay(2000);
    
    // Show Button Help
    display.showButtonHelp();
    delay(3000);
    
    // Clear and show status
    display.tft.fillScreen(TFT_BLACK); // Access tft directly or add clear method
    display.drawStaticUI();
    display.updateStatus("Initializing BLE...", TFT_WHITE);
    
    bleClient.init();
    
    // Setup Data Callback
    bleClient.onDataReceived = [](uint16_t addr, float val) {
        switch(addr) {
            case 24: display.updateSpeed(val); break;
            case 26: display.updateSoC((int)val); break;
            case 220: display.updateThrottle(val); break;
            case 105: display.updateRPM((int)val); break;
            case 113: display.updateVoltage(val); break;
            case 115: display.updatePower(val); break;
            case 119: display.updateCurrent(val); break;
            case 222: display.updateTemp((int)val); break;
        }
    };

    NimBLEDevice::getScan()->setAdvertisedDeviceCallbacks(new AdvertisedDeviceCallbacks());
    
    display.updateStatus("Scanning...", TFT_MAGENTA);
    bleClient.startScan();
}

void loop() {
    // === Button Handling ===
    if (btnView.checkPressed()) {
        display.nextPage();
    }
    
    if (btnBright.checkPressed()) {
        display.toggleBrightness();
    }
    
    if (btnReconnect.checkPressed()) {
        if(bleClient.isConnected) {
            // If connected, do we disconnect? Or just rescan?
            // Let's assume user wants to find a different device or fix connection
             display.updateStatus("Reconnecting...", TFT_ORANGE);
             // Currently BleClient doesn't have explicit disconnect method exposed but we can restart scan logic
             // Ideally we should force disconnect 
        } else {
             display.updateStatus("Scanning...", TFT_MAGENTA);
             bleClient.startScan();
        }
    }

    // Watchdog or Reconnect logic
    if(!bleClient.isConnected && wasConnected) {
        wasConnected = false;
        display.updateStatus("Disconnected", TFT_RED);
        delay(2000);
        display.updateStatus("Scanning...", TFT_MAGENTA);
        bleClient.startScan();
    }
    
    if(bleClient.isConnected) {
        wasConnected = true;
    }
    
    delay(50); // Faster loop for buttons
}
