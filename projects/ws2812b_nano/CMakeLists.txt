cmake_minimum_required(VERSION 3.20)

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/toolchains/avr-gcc.cmake)

project(ws2812b_nano C CXX ASM)

include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/modules/ArduinoProject.cmake)

arduino_init(BOARD nano)

arduino_executable(
    firmware
    SOURCES
        src/main.cpp
        src/ws2812b.cpp
)

arduino_upload_target(firmware PORT /dev/ttyUSB0 BAUDRATE 57600)
