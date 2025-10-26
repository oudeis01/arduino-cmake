cmake_minimum_required(VERSION 3.15)

set(ARDUINO_CORE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/vendor/ArduinoCore-avr")
set(ARDUINO_CORE_SRC "${ARDUINO_CORE_DIR}/cores/arduino")

if(NOT EXISTS "${ARDUINO_CORE_SRC}")
    message(FATAL_ERROR "Arduino core not found at: ${ARDUINO_CORE_SRC}")
endif()

function(build_arduino_core BOARD_NAME MCU F_CPU VARIANT)
    message(STATUS "Building Arduino Core for ${BOARD_NAME}...")
    
    set(CORE_TARGET "ArduinoCore-${BOARD_NAME}")
    set(VARIANT_DIR "${ARDUINO_CORE_DIR}/variants/${VARIANT}")
    
    if(NOT EXISTS "${VARIANT_DIR}")
        message(FATAL_ERROR "Variant not found: ${VARIANT_DIR}")
    endif()
    
    file(GLOB CORE_SOURCES
        "${ARDUINO_CORE_SRC}/*.c"
        "${ARDUINO_CORE_SRC}/*.cpp"
        "${ARDUINO_CORE_SRC}/*.S"
    )
    
    list(LENGTH CORE_SOURCES CORE_COUNT)
    message(STATUS "Found ${CORE_COUNT} core source files")
    
    add_library(${CORE_TARGET} STATIC ${CORE_SOURCES})
    
    target_compile_definitions(${CORE_TARGET} PUBLIC
        F_CPU=${F_CPU}
        ARDUINO=10607
        ARDUINO_AVR_${BOARD_NAME}
        ARDUINO_ARCH_AVR
    )
    
    target_compile_options(${CORE_TARGET} PRIVATE
        -mmcu=${MCU}
        -Os
        -Wall
        -ffunction-sections
        -fdata-sections
        -flto
    )
    
    target_include_directories(${CORE_TARGET} PUBLIC
        "${ARDUINO_CORE_SRC}"
        "${VARIANT_DIR}"
    )
    
    install(TARGETS ${CORE_TARGET}
        ARCHIVE DESTINATION lib
    )
    
    install(DIRECTORY "${ARDUINO_CORE_SRC}/"
        DESTINATION include/arduino
        FILES_MATCHING PATTERN "*.h"
    )
    
    install(DIRECTORY "${VARIANT_DIR}/"
        DESTINATION include/variant
        FILES_MATCHING PATTERN "*.h"
    )
    
    set(ARDUINO_CORE_MCU ${MCU} CACHE STRING "Arduino MCU type")
    set(ARDUINO_CORE_F_CPU ${F_CPU} CACHE STRING "Arduino CPU frequency")
    
    message(STATUS "Arduino Core configured: ${BOARD_NAME} (${MCU} @ ${F_CPU})")
endfunction()
