#pragma once
#include <Arduino.h>

class Button {
private:
    uint8_t pin;
    bool lastState = false;
    unsigned long lastDebounceTime = 0;
    unsigned long debounceDelay = 50;

public:
    Button(uint8_t p) : pin(p) {}

    void init() {
        // High Level Output module -> Active High
        // Use PULLDOWN to keep it LOW when not pressed
        pinMode(pin, INPUT_PULLDOWN);
    }

    // Returns true only on Rising Edge (Press)
    bool isPressed() {
        int reading = digitalRead(pin);
        bool pressed = false;

        if (reading != lastState) {
            lastDebounceTime = millis();
        }

        if ((millis() - lastDebounceTime) > debounceDelay) {
            // Whatever the reading is at, it's been there for longer than the debounce delay,
            // so take it as the actual current state:
            // But we store 'state' implicitly.
            
            // Actually, simplified debounce for rising edge:
            // If stable HIGH and previously was LOW (tracked externally or simple check?)
            // Let's implement simple state tracking inside logic:
             return false; // Handled below in update() pattern if needed, but for simple poling:
        }
        
        lastState = reading;
        return false;
    }
    
    // Simple stateful check helper
    bool state = false;
    bool checkPressed() {
        bool reading = digitalRead(pin); // HIGH = Pressed
        bool result = false;

        if (reading != lastState) {
            lastDebounceTime = millis();
        }

        if ((millis() - lastDebounceTime) > debounceDelay) {
            if (reading != state) {
                state = reading;
                if (state == HIGH) {
                    result = true;
                }
            }
        }
        lastState = reading;
        return result;
    }
};
