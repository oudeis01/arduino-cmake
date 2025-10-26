#include "ws2812b.h"
#include <Arduino.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

WS2812B::WS2812B(uint8_t pin, uint16_t num_leds) 
    : pin_(pin), num_leds_(num_leds), brightness_(255) {
    pixels_ = new RGB[num_leds];
    
    uint8_t port = digitalPinToPort(pin);
    port_ = portOutputRegister(port);
    pin_mask_ = digitalPinToBitMask(pin);
}

WS2812B::~WS2812B() {
    delete[] pixels_;
}

void WS2812B::begin() {
    pinMode(pin_, OUTPUT);
    digitalWrite(pin_, LOW);
    clear();
    show();
}

void WS2812B::setPixel(uint16_t index, uint8_t r, uint8_t g, uint8_t b) {
    if (index < num_leds_) {
        if (brightness_ < 255) {
            r = (r * brightness_) >> 8;
            g = (g * brightness_) >> 8;
            b = (b * brightness_) >> 8;
        }
        pixels_[index].r = r;
        pixels_[index].g = g;
        pixels_[index].b = b;
    }
}

void WS2812B::setPixel(uint16_t index, const RGB& color) {
    setPixel(index, color.r, color.g, color.b);
}

void WS2812B::clear() {
    for (uint16_t i = 0; i < num_leds_; i++) {
        pixels_[i].r = 0;
        pixels_[i].g = 0;
        pixels_[i].b = 0;
    }
}

void WS2812B::setBrightness(uint8_t brightness) {
    brightness_ = brightness;
}

void WS2812B::sendByte(uint8_t byte) {
    volatile uint8_t* port = port_;
    uint8_t pin_mask = pin_mask_;
    uint8_t high = *port | pin_mask;
    uint8_t low = *port & ~pin_mask;
    
    for (uint8_t bit = 0; bit < 8; bit++) {
        if (byte & 0x80) {
            asm volatile(
                "st %a[port], %[high]\n\t"
                "nop\n\t" "nop\n\t" "nop\n\t" "nop\n\t"
                "nop\n\t" "nop\n\t" "nop\n\t" "nop\n\t"
                "nop\n\t" "nop\n\t"
                "st %a[port], %[low]\n\t"
                "nop\n\t" "nop\n\t" "nop\n\t"
                ::
                [port] "e" (port),
                [high] "r" (high),
                [low] "r" (low)
            );
        } else {
            asm volatile(
                "st %a[port], %[high]\n\t"
                "nop\n\t" "nop\n\t" "nop\n\t" "nop\n\t"
                "st %a[port], %[low]\n\t"
                "nop\n\t" "nop\n\t" "nop\n\t" "nop\n\t"
                "nop\n\t" "nop\n\t" "nop\n\t" "nop\n\t"
                "nop\n\t"
                ::
                [port] "e" (port),
                [high] "r" (high),
                [low] "r" (low)
            );
        }
        byte <<= 1;
    }
}

void WS2812B::show() {
    uint8_t old_sreg = SREG;
    cli();
    
    for (uint16_t i = 0; i < num_leds_; i++) {
        sendByte(pixels_[i].g);
        sendByte(pixels_[i].r);
        sendByte(pixels_[i].b);
    }
    
    SREG = old_sreg;
    
    _delay_us(50);
}
