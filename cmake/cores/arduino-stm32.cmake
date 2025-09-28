# Arduino STM32 Core 추상화
# vendor-paths.cmake는 main CMakeLists.txt에서 이미 include되므로 제거

if(NOT ARDUINO_STM32_AVAILABLE)
    message(FATAL_ERROR "Arduino STM32 core not available")
endif()

# 코어 기본 정보
set(ARDUINO_STM32_CORES "${ARDUINO_STM32_ROOT}/cores/arduino")
set(ARDUINO_STM32_SYSTEM "${ARDUINO_STM32_ROOT}/system")
set(ARDUINO_STM32_VARIANTS "${ARDUINO_STM32_ROOT}/variants")

# 공통 컴파일 정의
set(ARDUINO_STM32_COMPILE_DEFINITIONS
    ARDUINO=10607
    ARDUINO_ARCH_STM32
    USE_HAL_DRIVER
)

# 공통 include 디렉토리
set(ARDUINO_STM32_INCLUDE_DIRECTORIES
    "${ARDUINO_STM32_CORES}"
    "${ARDUINO_STM32_CORES}/avr"
    "${ARDUINO_STM32_CORES}/stm32"
    "${ARDUINO_STM32_ROOT}/libraries/SrcWrapper/inc"
    "${ARDUINO_STM32_ROOT}/libraries/SrcWrapper/inc/LL"
)

# STM32 계열별 설정 함수
function(setup_stm32_board board_name mcu_series mcu_name variant_path)
    # MCU별 정의
    set(BOARD_COMPILE_DEFINITIONS 
        ${ARDUINO_STM32_COMPILE_DEFINITIONS}
        STM32${mcu_series}xx
        ${mcu_name}
        ARDUINO_${board_name}
        CACHE INTERNAL ""
    )
    
    # include 경로 설정
    set(BOARD_INCLUDE_DIRECTORIES
        ${ARDUINO_STM32_INCLUDE_DIRECTORIES}
        "${ARDUINO_STM32_VARIANTS}/${variant_path}"
        "${ARDUINO_STM32_SYSTEM}/Drivers/STM32${mcu_series}xx_HAL_Driver/Inc"
        "${ARDUINO_STM32_SYSTEM}/Drivers/STM32${mcu_series}xx_HAL_Driver/Src"
        "${ARDUINO_STM32_SYSTEM}/Drivers/CMSIS/Device/ST/STM32${mcu_series}xx/Include"
        "${ARDUINO_STM32_SYSTEM}/Drivers/CMSIS/Device/ST/STM32${mcu_series}xx/Source/Templates/gcc"
        "${ARDUINO_STM32_SYSTEM}/STM32${mcu_series}xx"
        "${ARDUINO_STM32_ROOT}/libraries/USBDevice/inc"
        "${ARDUINO_STM32_SYSTEM}/Middlewares/ST/STM32_USB_Device_Library/Core/Inc"
        "${ARDUINO_STM32_SYSTEM}/Middlewares/ST/STM32_USB_Device_Library/Core/Src"
        "${ARDUINO_STM32_ROOT}/libraries/VirtIO/inc"
        "${ARDUINO_STM32_SYSTEM}/Middlewares/OpenAMP"
        "${ARDUINO_STM32_SYSTEM}/Middlewares/OpenAMP/open-amp/lib/include"
        "${ARDUINO_STM32_SYSTEM}/Middlewares/OpenAMP/libmetal/lib/include"
        "${ARDUINO_STM32_SYSTEM}/Middlewares/OpenAMP/virtual_driver"
        "${ARDUINO_STM32_ROOT}/libraries/SrcWrapper/src"
        "/home/choiharam/.arduino15/packages/STMicroelectronics/tools/CMSIS/5.9.0/CMSIS/Core/Include"
        CACHE INTERNAL ""
    )
    
    # 코어 소스 파일들
    file(GLOB_RECURSE STM32_CORE_SOURCES
        "${ARDUINO_STM32_CORES}/*.c"
        "${ARDUINO_STM32_CORES}/*.cpp"
        "${ARDUINO_STM32_CORES}/*.S"
        "${ARDUINO_STM32_VARIANTS}/${variant_path}/*.c"
        "${ARDUINO_STM32_VARIANTS}/${variant_path}/*.cpp"
        "${ARDUINO_STM32_VARIANTS}/${variant_path}/*.S"
    )

    # HAL Driver 소스 파일들 (template 파일 제외)
    file(GLOB HAL_SOURCES "${ARDUINO_STM32_SYSTEM}/Drivers/STM32${mcu_series}xx_HAL_Driver/Src/*.c")
    list(FILTER HAL_SOURCES EXCLUDE REGEX ".*template\\.c$")
    list(APPEND STM32_CORE_SOURCES ${HAL_SOURCES})

    # SrcWrapper는 헤더 파일만 사용하고 소스는 컴파일하지 않음 (Arduino IDE와 동일)

    # CMSIS startup 파일들
    file(GLOB CMSIS_STARTUP_SOURCES
        "${ARDUINO_STM32_SYSTEM}/Drivers/CMSIS/Device/ST/STM32${mcu_series}xx/Source/Templates/gcc/*.s"
    )
    list(APPEND STM32_CORE_SOURCES ${CMSIS_STARTUP_SOURCES})
    
    set(BOARD_CORE_SOURCES ${STM32_CORE_SOURCES} CACHE INTERNAL "")
    
    message(STATUS "STM32 Board configured: ${board_name} (${mcu_name}, ${variant_path})")
endfunction()

# STM32 후처리 함수
function(stm32_post_build target_name)
    # Binary 파일 생성
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.bin
        COMMENT "Creating binary file: ${target_name}.bin"
    )
    
    # Intel HEX 파일 생성
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.hex
        COMMENT "Creating Intel HEX file: ${target_name}.hex"
    )
    
    # 크기 정보 출력
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_SIZE} -A $<TARGET_FILE:${target_name}>
        COMMENT "Program size information:"
    )
endfunction()