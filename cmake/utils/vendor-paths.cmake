# Vendor 기반 경로 관리
set(VENDOR_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/vendor")

# Arduino AVR 코어 경로
if(EXISTS "${VENDOR_ROOT}/ArduinoCore-avr")
    set(ARDUINO_AVR_ROOT "${VENDOR_ROOT}/ArduinoCore-avr")
    set(ARDUINO_AVR_AVAILABLE TRUE)
    message(STATUS "Found ArduinoCore-avr at: ${ARDUINO_AVR_ROOT}")
else()
    set(ARDUINO_AVR_AVAILABLE FALSE)
    message(WARNING "ArduinoCore-avr not found in vendor directory")
endif()

# 시스템 툴체인 탐지 함수
function(find_system_toolchain toolchain_name result_var)
    find_program(FOUND_TOOLCHAIN ${toolchain_name} PATHS
        /usr/bin
        /usr/local/bin
        /opt/homebrew/bin
    )
    if(FOUND_TOOLCHAIN)
        set(${result_var} TRUE PARENT_SCOPE)
        message(STATUS "Found system toolchain: ${FOUND_TOOLCHAIN}")
        unset(FOUND_TOOLCHAIN CACHE)
    else()
        set(${result_var} FALSE PARENT_SCOPE)
        message(WARNING "System toolchain ${toolchain_name} not found")
    endif()
endfunction()