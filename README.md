## 1. Core Dependencies (Required for all boards)

These packages are essential for the build system to function.

```bash
sudo pacman -S --needed cmake base-devel
```

## 2. Toolchain & Uploader Dependencies

Install the packages corresponding to the microcontroller architecture of your board.

### For AVR-based boards (e.g., Arduino Uno, Nano)

This provides the AVR compiler toolchain and the `avrdude` upload tool.

```bash
sudo pacman -S --needed avr-gcc avr-binutils avr-libc avrdude
```

### For ARM-based boards (e.g., STM32 series)

This provides the ARM embedded compiler toolchain and common upload tools (`st-flash` from `stlink`, and `dfu-util`).

```bash
sudo pacman -S --needed arm-none-eabi-gcc arm-none-eabi-binutils arm-none-eabi-newlib stlink dfu-util
```
