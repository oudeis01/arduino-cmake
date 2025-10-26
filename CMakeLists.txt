cmake_minimum_required(VERSION 3.15)

set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/avr-gcc.cmake" CACHE FILEPATH "AVR toolchain")

project(ArduinoCore C CXX ASM)

include(cmake/core/ArduinoCore.cmake)

set(ARDUINO_BOARD "uno" CACHE STRING "Arduino board to build core for")
set_property(CACHE ARDUINO_BOARD PROPERTY STRINGS uno nano mega2560)

if(ARDUINO_BOARD STREQUAL "uno")
    build_arduino_core(uno atmega328p 16000000UL standard)
elseif(ARDUINO_BOARD STREQUAL "nano")
    build_arduino_core(nano atmega328p 16000000UL eightanaloginputs)
elseif(ARDUINO_BOARD STREQUAL "mega2560")
    build_arduino_core(mega2560 atmega2560 16000000UL mega)
else()
    message(FATAL_ERROR "Unsupported board: ${ARDUINO_BOARD}")
endif()

set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/install" CACHE PATH "Installation directory" FORCE)

message(STATUS "")
message(STATUS "Arduino Core Build System")
message(STATUS "=========================")
message(STATUS "Board: ${ARDUINO_BOARD}")
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "")
message(STATUS "To build and install:")
message(STATUS "  cmake -B build")
message(STATUS "  cmake --build build")
message(STATUS "  cmake --build build --target install")
message(STATUS "")
