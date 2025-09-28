#!/bin/bash

# Arduino/STM32 Upload Script

set -e

show_help() {
    echo "Arduino/STM32 Upload Script"
    echo ""
    echo "Usage: $0 -b BOARD -d DEVICE -f FIRMWARE"
    echo ""
    echo "Options:"
    echo "  -b, --board BOARD       Target board (arduino_uno | klst_panda)"
    echo "  -d, --device DEVICE     Device path or upload method"
    echo "                          Arduino UNO: /dev/ttyACM0, /dev/ttyUSB0, etc."
    echo "                          STM32: dfu, openocd, or ST-Link device path"
    echo "  -f, --firmware FILE     Firmware file to upload"
    echo "                          Arduino UNO: .hex file"
    echo "                          STM32: .bin/.hex file (depends on method)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -b arduino_uno -d /dev/ttyACM0 -f firmware.hex"
    echo "  $0 -b klst_panda -d dfu -f firmware.bin"
    echo "  $0 -b klst_panda -d openocd -f firmware.elf"
    echo "  $0 --board arduino_uno --device /dev/ttyUSB0 --firmware project.hex"
}

BOARD=""
DEVICE=""
FIRMWARE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--board)
            BOARD="$2"
            shift 2
            ;;
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -f|--firmware)
            FIRMWARE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$BOARD" ] || [ -z "$DEVICE" ] || [ -z "$FIRMWARE" ]; then
    echo "Error: Missing required arguments"
    echo ""
    show_help
    exit 1
fi

if [[ "$BOARD" != "arduino_uno" && "$BOARD" != "klst_panda" ]]; then
    echo "Error: Unsupported board '$BOARD'"
    echo "Supported boards: arduino_uno, klst_panda"
    exit 1
fi

if [ ! -f "$FIRMWARE" ]; then
    echo "Error: Firmware file '$FIRMWARE' not found"
    exit 1
fi

echo "======================================"
echo "Arduino/STM32 Upload"
echo "======================================"
echo "Board: $BOARD"
echo "Device: $DEVICE"
echo "Firmware: $FIRMWARE"
echo "======================================"

if [ "$BOARD" = "arduino_uno" ]; then
    echo "Uploading to Arduino UNO..."

    if [[ "$FIRMWARE" != *.hex ]]; then
        echo "Warning: Arduino UNO typically uses .hex files"
    fi

    if [ ! -e "$DEVICE" ]; then
        echo "Error: Device '$DEVICE' not found"
        echo "Available serial devices:"
        ls /dev/tty* | grep -E "(ACM|USB)" 2>/dev/null || echo "  No serial devices found"
        exit 1
    fi

    echo "Running avrdude..."
    avrdude -p atmega328p -c arduino -P "$DEVICE" -b 115200 \
            -U flash:w:"$FIRMWARE":i || {
        echo "Upload failed. Check:"
        echo "  1. Board connection"
        echo "  2. Correct device path"
        echo "  3. Board is not in use by other programs"
        exit 1
    }

elif [ "$BOARD" = "klst_panda" ]; then
    echo "Uploading to STM32 KLST_PANDA..."

    case "$DEVICE" in
        dfu)
            echo "Using DFU upload method..."

            if [[ "$FIRMWARE" != *.bin ]]; then
                echo "Error: DFU upload requires .bin file"
                exit 1
            fi

            if ! command -v dfu-util &> /dev/null; then
                echo "Error: dfu-util not found. Please install dfu-util"
                exit 1
            fi

            echo "Make sure the board is in DFU mode (boot button pressed during reset)"
            echo "Running dfu-util..."
            dfu-util -a 0 -s 0x08000000:leave -D "$FIRMWARE" || {
                echo "DFU upload failed. Check:"
                echo "  1. Board is in DFU mode"
                echo "  2. USB connection"
                echo "  3. dfu-util is installed"
                exit 1
            }
            ;;

        openocd)
            echo "Using OpenOCD upload method..."

            if [[ "$FIRMWARE" != *.elf && "$FIRMWARE" != *.bin && "$FIRMWARE" != *.hex ]]; then
                echo "Error: OpenOCD upload requires .elf, .bin, or .hex file"
                exit 1
            fi

            if ! command -v openocd &> /dev/null; then
                echo "Error: openocd not found. Please install openocd"
                exit 1
            fi

            echo "Running OpenOCD (ST-Link required)..."
            openocd -f interface/stlink.cfg -f target/stm32h7x.cfg \
                    -c "program $FIRMWARE verify reset exit" || {
                echo "OpenOCD upload failed. Check:"
                echo "  1. ST-Link connection"
                echo "  2. OpenOCD configuration"
                echo "  3. Board power"
                exit 1
            }
            ;;

        *)
            echo "Error: Unknown upload method for STM32: '$DEVICE'"
            echo "Supported methods: dfu, openocd"
            echo ""
            echo "For DFU mode:"
            echo "  1. Hold BOOT button and press RESET"
            echo "  2. Release RESET, then release BOOT"
            echo "  3. Use: $0 -b klst_panda -d dfu -f firmware.bin"
            echo ""
            echo "For OpenOCD (ST-Link):"
            echo "  1. Connect ST-Link debugger"
            echo "  2. Use: $0 -b klst_panda -d openocd -f firmware.elf"
            exit 1
            ;;
    esac
fi

echo ""
echo "======================================"
echo "Upload completed successfully!"
echo "======================================"
