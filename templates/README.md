# Arduino Project Template

Simple Arduino project using the Arduino CMake build system.

## Quick Start

1. **Copy this template** to your project directory
2. **Build Arduino Core** (one-time setup):
   ```bash
   cd ../arduino-cmake
   cmake -B build -DARDUINO_BOARD=uno
   cmake --build build
   cmake --build build --target install
   ```

3. **Build your project**:
   ```bash
   cd your-project
   cmake -B build
   cmake --build build
   ```

4. **Upload to Arduino**:
   ```bash
   cmake --build build --target upload
   ```

## Project Structure

```
your-project/
├── CMakeLists.txt       # Build configuration
└── src/
    └── main.cpp         # Your Arduino sketch
```

## Configuration

Edit `CMakeLists.txt` to customize:
- Board type: `arduino_init(BOARD uno)` (uno, nano, mega2560)
- Upload port: `arduino_upload_target(firmware PORT /dev/ttyACM0)`

## Adding Libraries

1. Download library to `../arduino-cmake/libraries/`
2. Add to your project:
   ```cmake
   include(ArduinoLibrary)
   arduino_add_library(firmware FastLED)
   ```
