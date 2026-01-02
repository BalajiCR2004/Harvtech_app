#pragma once
#include <TFT_eSPI.h>
#include <PNGdec.h>
#include "Images.h"

// Callback must be static or global
int pngDraw(PNGDRAW *pDraw) {
    uint16_t lineBuffer[240]; // Max width for this display
    TFT_eSPI* tftPtr = (TFT_eSPI*)pDraw->pUser; // Pass tft via pUser
    
    // PixelType is RGB565 (2 bytes)
    png.getLineAsRGB565(pDraw, lineBuffer, PNG_RGB565_BIG_ENDIAN, 0xffffffff);
    tftPtr->pushImage(pDraw->x, pDraw->y, pDraw->iWidth, 1, lineBuffer);
    return 1;
}

class DisplayManager {
public:
    TFT_eSPI tft = TFT_eSPI(); // Make Public for callback access
private:
    TFT_eSprite sprite = TFT_eSprite(&tft);
    PNG png; // PNG Decoder

    int currentPage = 0; // 0=Grid, 1=Big Speed
    bool highBrightness = true;

    // Cache values to avoid flicker
    int lastSpeed = -1;
    int lastSoC = -1;
    int lastRPM = -1;
    float lastVolt = -1;
    float lastThrottle = -1;

public:
    void init() {
        tft.init();
        tft.setRotation(0); // Portrait 240x320
        tft.fillScreen(TFT_BLACK);
        
        // Turn on Backlight
        pinMode(TFT_BL, OUTPUT);
        digitalWrite(TFT_BL, HIGH);

        // Don't draw Static UI yet, let main call showLogo first
    }
    
    void showLogo() {
        tft.fillScreen(TFT_BLACK);
        
        // img_app_icon is defined in Images.h
        // Name in script was: img_app_icon => actually based on filename 'ic_launcher.png'
        // Script used: final name = 'img_app_icon'; // Simplified name
        // So variable is `img_app_icon`
        
        int rc = png.openRAM((uint8_t *)img_app_icon, img_app_icon_len, pngDraw);
        if (rc == PNG_SUCCESS) {
            // Center the image
            int x = (240 - png.getWidth()) / 2;
            int y = (320 - png.getHeight()) / 2;
            
            tft.startWrite();
            // Pass tft pointer as pUser
            rc = png.decode((void*)&tft, 0);
            tft.endWrite();
            png.close();
        } else {
            tft.drawString("PNG Logic Fail", 20, 20, 2);
        }
    }
    // ... rest of methods
    
    void toggleBrightness() {
        highBrightness = !highBrightness;
        // Simple PWM or just Digital toggle if BL pin allows
        // Assuming BL pin is PWM capable, typically default HIGH/LOW is simplest.
        // For PWM we need ledcSetup (ESP32). Let's stick to simple High/Low, or simulate dimming with alpha if not supported? 
        // No, standard is PWM on BL pin.
        // Let's us simple analogWrite equivalent in Arduino ESP32 context:
        analogWrite(TFT_BL, highBrightness ? 255 : 50);
    }
    
    void nextPage() {
        currentPage++;
        if(currentPage > 1) currentPage = 0;
        
        // Full Redraw
        tft.fillScreen(TFT_BLACK);
        lastSpeed = -1; lastSoC = -1; lastRPM = -1; // Force redraw of values
        
        if(currentPage == 0) {
            drawStaticUI();
        } else {
            // Page 1 Static
            tft.setTextColor(TFT_GREEN, TFT_BLACK);
            tft.setTextDatum(MC_DATUM);
            tft.drawString("SPEED", 120, 40, 4);
        }
    }

    void drawStaticUI() {
        tft.setTextColor(TFT_WHITE, TFT_BLACK);
        tft.setTextDatum(MC_DATUM);
        
        // Header
        tft.fillRect(0, 0, 240, 40, TFT_NAVY);
        tft.drawString("HarvTech", 120, 20, 4);

        // Labels
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(TFT_SILVER);
        tft.drawString("SoC %", 20, 60, 2);
        tft.drawString("Throttle V", 140, 60, 2);
        
        tft.drawString("SPEED km/h", 70, 120, 2);

        tft.drawString("RPM", 20, 220, 2);
        tft.drawString("VOLTAGE", 140, 220, 2);
        
        // Extra Metrics Row
        tft.drawString("PWR", 20, 280, 2);
        tft.drawString("CUR", 100, 280, 2);
        tft.drawString("TMP", 180, 280, 2);
    }
    
    void updateStatus(const char* status, uint16_t color) {
        if(currentPage != 0) return; // Only show status on Grid
        tft.fillRect(0, 305, 240, 15, TFT_BLACK);
        tft.setTextColor(color, TFT_BLACK);
        tft.setTextDatum(BC_DATUM);
        tft.drawString(status, 120, 320, 2);
    }

    void updateSpeed(float speed) {
        int val = (int)speed;
        if(val == lastSpeed) return;
        lastSpeed = val;
        
        if(currentPage == 0) {
            // Speed is central large Text
            tft.setTextColor(TFT_GREEN, TFT_BLACK);
            tft.setTextDatum(MC_DATUM);
            tft.fillRect(40, 140, 160, 60, TFT_BLACK);
            tft.drawNumber(val, 120, 170, 7);
        } else {
            // Big Page
            tft.setTextColor(TFT_GREEN, TFT_BLACK);
            tft.setTextDatum(MC_DATUM);
            tft.fillRect(0, 80, 240, 160, TFT_BLACK);
            tft.drawNumber(val, 120, 160, 8); // Largest font
        }
    }

    void updateSoC(int soc) {
        if((currentPage != 0) || (soc == lastSoC)) return;
        lastSoC = soc;
        
        uint16_t color = (soc > 20) ? TFT_ORANGE : TFT_RED;
        tft.setTextColor(color, TFT_BLACK);
        tft.setTextDatum(TL_DATUM);
        tft.fillRect(20, 80, 80, 30, TFT_BLACK);
        tft.drawNumber(soc, 20, 80, 4);
    }

    void updateThrottle(float v) {
        if((currentPage != 0) || (abs(v - lastThrottle) < 0.1)) return;
        lastThrottle = v;
        
        tft.setTextColor(TFT_RED, TFT_BLACK);
        tft.setTextDatum(TL_DATUM);
        tft.fillRect(140, 80, 80, 30, TFT_BLACK);
        tft.drawFloat(v, 1, 140, 80, 4);
    }

    void updateRPM(int rpm) {
        if((currentPage != 0) || (rpm == lastRPM)) return;
        lastRPM = rpm;

        tft.setTextColor(TFT_SKYBLUE, TFT_BLACK);
        tft.setTextDatum(TL_DATUM);
        tft.fillRect(20, 240, 100, 25, TFT_BLACK);
        tft.drawNumber(rpm, 20, 240, 4);
    }

    void updateVoltage(float volt) {
        if((currentPage != 0) || (abs(volt - lastVolt) < 0.5)) return;
        lastVolt = volt;
        
        tft.setTextColor(TFT_YELLOW, TFT_BLACK);
        tft.setTextDatum(TL_DATUM);
        tft.fillRect(140, 240, 100, 25, TFT_BLACK);
        tft.drawFloat(volt, 1, 140, 240, 4);
    }
    
    // New Metrics
    void updatePower(float kw) {
        if(currentPage != 0) return;
        tft.setTextColor(TFT_ORANGE, TFT_BLACK);
        tft.setTextDatum(TL_DATUM);
        tft.fillRect(20, 295, 60, 15, TFT_BLACK);
        tft.drawFloat(kw, 1, 20, 295, 2);
    }
    
    void updateCurrent(float amps) {
        if(currentPage != 0) return;
        tft.setTextColor(TFT_MAGENTA, TFT_BLACK);
        tft.setTextDatum(TL_DATUM);
        tft.fillRect(100, 295, 60, 15, TFT_BLACK);
        tft.drawFloat(amps, 0, 100, 295, 2);
    }
    
    void updateTemp(int temp) {
        if(currentPage != 0) return;
        tft.setTextColor(TFT_WHITE, TFT_BLACK);
        tft.setTextDatum(TL_DATUM);
        tft.fillRect(180, 295, 40, 15, TFT_BLACK);
        tft.drawNumber(temp, 180, 295, 2);
    }
    
    void showButtonHelp() {
        tft.fillScreen(TFT_BLACK);
        tft.setTextColor(TFT_WHITE, TFT_BLACK);
        tft.setTextDatum(MC_DATUM);
        
        tft.drawString("CONTROLS", 120, 40, 4);
        
        tft.setTextDatum(TL_DATUM);
        tft.setTextColor(TFT_GREEN);
        tft.drawString("Btn 1: Change View", 20, 100, 2);
        
        tft.setTextColor(TFT_YELLOW);
        tft.drawString("Btn 2: Brightness", 20, 150, 2);
        
        tft.setTextColor(TFT_CYAN);
        tft.drawString("Btn 3: Reconnect", 20, 200, 2);
        
        tft.setTextColor(TFT_SILVER);
        tft.setTextDatum(BC_DATUM);
        tft.drawString("Starting...", 120, 300, 2);
    }
};
