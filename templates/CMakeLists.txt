cmake_minimum_required(VERSION 3.15)

set(ARDUINO_CMAKE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../arduino-cmake")

if(NOT EXISTS "${ARDUINO_CMAKE_ROOT}")
    message(FATAL_ERROR "Arduino CMake system not found at: ${ARDUINO_CMAKE_ROOT}")
endif()

list(APPEND CMAKE_MODULE_PATH "${ARDUINO_CMAKE_ROOT}/cmake/modules")

include(ArduinoProject)

arduino_init(BOARD uno)

project(MyArduinoProject)

arduino_executable(firmware
    SOURCES
        src/main.cpp
)

arduino_upload_target(firmware
    PORT /dev/ttyACM0
)
