#include <Arduino.h>
#include "ws2812b.h"

#define LED_PIN 10
#define NUM_LEDS 30

WS2812B strip(LED_PIN, NUM_LEDS);

void setup() {
    strip.begin();
    strip.setBrightness(100);
}

void loop() {
    static uint8_t hue = 0;
    
    for (uint16_t i = 0; i < NUM_LEDS; i++) {
        uint8_t h = hue + (i * 256 / NUM_LEDS);
        
        uint8_t region = h / 43;
        uint8_t remainder = (h % 43) * 6;
        
        uint8_t p = 0;
        uint8_t q = (255 * (255 - remainder)) >> 8;
        uint8_t t = (255 * remainder) >> 8;
        
        switch (region) {
            case 0:
                strip.setPixel(i, 255, t, p);
                break;
            case 1:
                strip.setPixel(i, q, 255, p);
                break;
            case 2:
                strip.setPixel(i, p, 255, t);
                break;
            case 3:
                strip.setPixel(i, p, q, 255);
                break;
            case 4:
                strip.setPixel(i, t, p, 255);
                break;
            default:
                strip.setPixel(i, 255, p, q);
                break;
        }
    }
    
    strip.show();
    hue++;
    delay(10);
}
