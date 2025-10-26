# WS2812B Simple Library

Lightweight WS2812B (NeoPixel) library for AVR microcontrollers.

## Features

- **Tiny footprint**: ~500 bytes code, 30 bytes RAM for 10 LEDs
- **ATtiny85 compatible**: Works on ATtiny with limited resources
- **Arduino compatible**: Also works on Arduino Uno/Nano/Mega
- **Simple API**: Easy to use, similar to Adafruit NeoPixel
- **No dependencies**: Only uses Arduino core functions

## Memory Usage

- Code size: ~400-600 bytes
- RAM per LED: 3 bytes (RGB)
- Stack: ~50 bytes
- **Total for 10 LEDs**: ~500 bytes (easily fits in ATtiny85's 512 bytes SRAM)

## Hardware Support

### Tested Platforms
- ✅ Arduino Uno (ATmega328P @ 16MHz)
- ✅ Arduino Nano (ATmega328P @ 16MHz)
- ⚠️  ATtiny85 (8/16MHz) - Requires timing adjustment for 8MHz

### Pin Configuration
- Any digital pin can be used
- Default: Pin 6

## Usage

```cpp
#include "ws2812b.h"

#define LED_PIN 6
#define NUM_LEDS 10

WS2812B strip(LED_PIN, NUM_LEDS);

void setup() {
    strip.begin();
    strip.setBrightness(50);  // 0-255
}

void loop() {
    strip.setPixel(0, 255, 0, 0);  // Red
    strip.setPixel(1, 0, 255, 0);  // Green
    strip.setPixel(2, 0, 0, 255);  // Blue
    strip.show();
    delay(100);
}
```

## API Reference

### Constructor
```cpp
WS2812B(uint8_t pin, uint16_t num_leds)
```

### Methods
- `void begin()` - Initialize the strip
- `void setPixel(uint16_t index, uint8_t r, uint8_t g, uint8_t b)` - Set pixel color
- `void clear()` - Turn off all LEDs
- `void show()` - Update the strip with new colors
- `void setBrightness(uint8_t brightness)` - Set global brightness (0-255)

## WS2812B Timing

The library uses inline assembly for precise timing:
- **1 bit**: HIGH ~800ns, LOW ~450ns
- **0 bit**: HIGH ~400ns, LOW ~850ns
- **Reset**: LOW for 50μs

### ATtiny85 Notes

For ATtiny85 running at 8MHz, you need to adjust timing in `ws2812b.cpp`:
- Reduce number of `nop` instructions by half
- Or run ATtiny85 at 16MHz (using PLL or external crystal)

## Build

```bash
cd arduino-cmake/projects/ws2812b_simple
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../../cmake/ArduinoToolchain.cmake
cmake --build .
```

## Upload

```bash
cmake --build . --target upload
```

## License

Public Domain - Use freely
