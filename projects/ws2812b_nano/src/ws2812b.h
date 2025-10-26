#pragma once

#include <stdint.h>

class WS2812B {
public:
    struct RGB {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        
        RGB() : r(0), g(0), b(0) {}
        RGB(uint8_t red, uint8_t green, uint8_t blue) : r(red), g(green), b(blue) {}
    };
    
    WS2812B(uint8_t pin, uint16_t num_leds);
    ~WS2812B();
    
    void begin();
    void setPixel(uint16_t index, uint8_t r, uint8_t g, uint8_t b);
    void setPixel(uint16_t index, const RGB& color);
    void clear();
    void show();
    void setBrightness(uint8_t brightness);
    
    RGB* getPixels() { return pixels_; }
    uint16_t numPixels() const { return num_leds_; }

private:
    void sendByte(uint8_t byte);
    
    uint8_t pin_;
    uint16_t num_leds_;
    RGB* pixels_;
    uint8_t brightness_;
    
    volatile uint8_t* port_;
    uint8_t pin_mask_;
};
