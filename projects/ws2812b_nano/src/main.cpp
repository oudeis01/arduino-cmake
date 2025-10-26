#include <Arduino.h>
#include "ws2812b.h"

#define LED_PIN 10
#define NUM_LEDS 8

WS2812B strip(LED_PIN, NUM_LEDS);

void pattern1_whiteGradientRotate(uint32_t elapsed) {
    uint8_t center = (elapsed / 125) % NUM_LEDS;
    
    strip.clear();
    strip.setPixel(center, 255, 255, 255);
    strip.setPixel((center + 1) % NUM_LEDS, 128, 128, 128);
    strip.setPixel((center + 2) % NUM_LEDS, 64, 64, 64);
    strip.setPixel((center + NUM_LEDS - 1) % NUM_LEDS, 128, 128, 128);
    strip.setPixel((center + NUM_LEDS - 2) % NUM_LEDS, 64, 64, 64);
}

void pattern2_blueGradientRotate(uint32_t elapsed) {
    uint8_t center = (elapsed / 125) % NUM_LEDS;
    
    strip.clear();
    strip.setPixel(center, 0, 0, 255);
    strip.setPixel((center + 1) % NUM_LEDS, 0, 0, 180);
    strip.setPixel((center + 2) % NUM_LEDS, 0, 0, 100);
    strip.setPixel((center + 3) % NUM_LEDS, 0, 0, 40);
    strip.setPixel((center + NUM_LEDS - 1) % NUM_LEDS, 0, 0, 180);
    strip.setPixel((center + NUM_LEDS - 2) % NUM_LEDS, 0, 0, 100);
    strip.setPixel((center + NUM_LEDS - 3) % NUM_LEDS, 0, 0, 40);
}

void pattern3_redPulseWave(uint32_t elapsed) {
    uint8_t pos = (elapsed / 125) % NUM_LEDS;
    
    strip.clear();
    strip.setPixel(pos, 255, 0, 0);
    strip.setPixel((pos + 1) % NUM_LEDS, 200, 0, 0);
    strip.setPixel((pos + 2) % NUM_LEDS, 120, 0, 0);
    strip.setPixel((pos + 4) % NUM_LEDS, 255, 0, 0);
    strip.setPixel((pos + 5) % NUM_LEDS, 200, 0, 0);
    strip.setPixel((pos + 6) % NUM_LEDS, 120, 0, 0);
}

void pattern4_greenDoubleGradient(uint32_t elapsed) {
    uint8_t center = (elapsed / 125) % NUM_LEDS;
    
    strip.clear();
    strip.setPixel(center, 0, 255, 0);
    strip.setPixel((center + 1) % NUM_LEDS, 0, 150, 0);
    strip.setPixel((center + 2) % NUM_LEDS, 0, 80, 0);
    strip.setPixel((center + NUM_LEDS - 1) % NUM_LEDS, 0, 150, 0);
    strip.setPixel((center + NUM_LEDS - 2) % NUM_LEDS, 0, 80, 0);
    
    uint8_t opposite = (center + 4) % NUM_LEDS;
    strip.setPixel(opposite, 0, 255, 0);
    strip.setPixel((opposite + 1) % NUM_LEDS, 0, 150, 0);
    strip.setPixel((opposite + NUM_LEDS - 1) % NUM_LEDS, 0, 150, 0);
}

void pattern5_purpleCometTail(uint32_t elapsed) {
    uint8_t head = (elapsed / 125) % NUM_LEDS;
    
    strip.clear();
    strip.setPixel(head, 128, 0, 128);
    strip.setPixel((head + NUM_LEDS - 1) % NUM_LEDS, 90, 0, 90);
    strip.setPixel((head + NUM_LEDS - 2) % NUM_LEDS, 60, 0, 60);
    strip.setPixel((head + NUM_LEDS - 3) % NUM_LEDS, 30, 0, 30);
    strip.setPixel((head + NUM_LEDS - 4) % NUM_LEDS, 10, 0, 10);
}

void setup() {
    strip.begin();
    strip.setBrightness(100);
}

void loop() {
    static uint32_t patternStartTime = 0;
    static uint8_t currentPattern = 0;
    
    uint32_t now = millis();
    uint32_t elapsed = now - patternStartTime;
    
    if (elapsed >= 3000) {
        currentPattern = (currentPattern + 1) % 5;
        patternStartTime = now;
        elapsed = 0;
    }
    
    switch (currentPattern) {
        case 0:
            pattern1_whiteGradientRotate(elapsed);
            break;
        case 1:
            pattern2_blueGradientRotate(elapsed);
            break;
        case 2:
            pattern3_redPulseWave(elapsed);
            break;
        case 3:
            pattern4_greenDoubleGradient(elapsed);
            break;
        case 4:
            pattern5_purpleCometTail(elapsed);
            break;
    }
    
    strip.show();
    delay(20);
}
