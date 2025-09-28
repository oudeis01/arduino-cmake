# STM32 KLST_PANDA Board Configuration

# 프로젝트 이름 설정
set(PROJECT_NAME "klst_panda_project")

# 툴체인 파일 설정
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/arm-none-eabi.cmake")

# STM32 KLST_PANDA 보드 정의
set(BOARD_COMPILE_DEFINITIONS
    STM32H7xx
    STM32H723xx
    CORE_CM7
    USE_HAL_DRIVER
    USE_FULL_LL_DRIVER
    ARDUINO=10607
    ARDUINO_KLST_PANDA
    ARDUINO_ARCH_STM32
    BOARD_NAME="KLST_PANDA"
    VARIANT_H="variant_KLST_PANDA.h"
    CUSTOM_PERIPHERAL_PINS
    HAL_UART_MODULE_ENABLED
    KLST_ENV=0x36
    VECT_TAB_OFFSET=0x0
)

# vendor 기반 경로 설정
set(VENDOR_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/vendor")
set(STM32_CORE_PATH "${VENDOR_ROOT}/Arduino_Core_STM32")
set(KLANGSTROM_ROOT "${VENDOR_ROOT}/klangstrom-arduino")

# KLST_PANDA variant 경로 (klangstrom-arduino에서)
set(KLST_PANDA_VARIANT "${KLANGSTROM_ROOT}/variants/KLST_PANDA/variant")

# STM32 H7 variant 경로 (Arduino_Core_STM32에서)
set(STM32_H7_VARIANT "${STM32_CORE_PATH}/variants/STM32H7xx/H723Z(E-G)T_H730ZBT_H733ZGT")

# 인클루드 디렉토리
set(BOARD_INCLUDE_DIRECTORIES
    # KLST_PANDA variant 헤더 (최우선순위)
    "${KLST_PANDA_VARIANT}"

    # Arduino 코어 헤더
    "${STM32_CORE_PATH}/cores/arduino"
    "${STM32_CORE_PATH}/cores/arduino/avr"
    "${STM32_CORE_PATH}/cores/arduino/stm32"

    # STM32 H7 variant 헤더 (백업)
    "${STM32_H7_VARIANT}"

    # SrcWrapper 라이브러리 (Arduino IDE 순서: 첫 번째)
    "${STM32_CORE_PATH}/libraries/SrcWrapper/inc"
    "${STM32_CORE_PATH}/libraries/SrcWrapper/inc/LL"

    # STM32 HAL 드라이버 (Arduino IDE 순서: 두 번째)
    "${STM32_CORE_PATH}/system/Drivers/STM32H7xx_HAL_Driver/Inc"
    "${STM32_CORE_PATH}/system/Drivers/STM32H7xx_HAL_Driver/Src"
    "${STM32_CORE_PATH}/system/STM32H7xx"

    # CMSIS (Arduino IDE 순서: 마지막)
    "${STM32_CORE_PATH}/system/Drivers/CMSIS/Device/ST/STM32H7xx/Include"
    "${STM32_CORE_PATH}/system/Drivers/CMSIS/Include"
    "${STM32_CORE_PATH}/system/Drivers/CMSIS/Device/ST/STM32H7xx/Source/Templates/gcc"

    # USB 및 미들웨어
    "${STM32_CORE_PATH}/libraries/USBDevice/inc"
    "${STM32_CORE_PATH}/system/Middlewares/ST/STM32_USB_Device_Library/Core/Inc"
    "${STM32_CORE_PATH}/libraries/VirtIO/inc"
    "${STM32_CORE_PATH}/system/Middlewares/OpenAMP"
    "${STM32_CORE_PATH}/system/Middlewares/OpenAMP/open-amp/lib/include"
    "${STM32_CORE_PATH}/system/Middlewares/OpenAMP/libmetal/lib/include"
    "${STM32_CORE_PATH}/system/Middlewares/OpenAMP/virtual_driver"

    # Klangstrom 라이브러리 (vendor 기반)
    "${KLANGSTROM_ROOT}/libraries/Klangstrom/src"
    "${KLANGSTROM_ROOT}/libraries/Klangstrom_KLST_PANDA_STM32/src"
    "${KLANGSTROM_ROOT}/libraries/Klangstrom_KLST_PANDA_STM32_CubeMX/src"
)

# 컴파일 옵션
set(BOARD_COMPILE_OPTIONS
    # 여기에 추가 컴파일 옵션 추가 가능
)

# 링크 옵션 (링커 스크립트 포함)
set(BOARD_LINK_OPTIONS
    -u _printf_float
    -Wl,--defsym=LD_FLASH_OFFSET=0x0
    -Wl,--defsym=LD_MAX_SIZE=1048576
    -Wl,--defsym=LD_MAX_DATA_SIZE=577536
    -Wl,--cref
    -Wl,--check-sections
    -Wl,--gc-sections
    -Wl,--entry=Reset_Handler
    -Wl,--unresolved-symbols=report-all
    -Wl,--warn-common
    -Wl,--no-warn-rwx-segments
    "-Wl,--default-script=${KLST_PANDA_VARIANT}/variant_KLST_PANDA.ld"
    "-Wl,--script=${STM32_CORE_PATH}/system/ldscript.ld"
    "-Wl,-Map,${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.map"
)

# STM32 Arduino 코어 소스 파일들
file(GLOB_RECURSE STM32_CORE_SOURCES
    "${STM32_CORE_PATH}/cores/arduino/*.c"
    "${STM32_CORE_PATH}/cores/arduino/*.cpp"
    "${STM32_CORE_PATH}/cores/arduino/*.S"
)

# SrcWrapper 라이브러리 (Arduino IDE 방식: 하위 디렉토리별 분리)
file(GLOB SRCWRAPPER_HAL_SOURCES
    "${STM32_CORE_PATH}/libraries/SrcWrapper/src/HAL/*.c"
    "${STM32_CORE_PATH}/libraries/SrcWrapper/src/HAL/*.cpp"
)

file(GLOB SRCWRAPPER_LL_SOURCES
    "${STM32_CORE_PATH}/libraries/SrcWrapper/src/LL/*.c"
    "${STM32_CORE_PATH}/libraries/SrcWrapper/src/LL/*.cpp"
)

file(GLOB SRCWRAPPER_STM32_SOURCES
    "${STM32_CORE_PATH}/libraries/SrcWrapper/src/stm32/*.c"
    "${STM32_CORE_PATH}/libraries/SrcWrapper/src/stm32/*.cpp"
)

file(GLOB SRCWRAPPER_MAIN_SOURCES
    "${STM32_CORE_PATH}/libraries/SrcWrapper/src/*.c"
    "${STM32_CORE_PATH}/libraries/SrcWrapper/src/*.cpp"
)

# KLST_PANDA variant 소스 파일들
file(GLOB KLST_VARIANT_SOURCES
    "${KLST_PANDA_VARIANT}/*.c"
    "${KLST_PANDA_VARIANT}/*.cpp"
)

# STM32 H7 variant 소스 파일들 (백업)
file(GLOB STM32_VARIANT_SOURCES
    "${STM32_H7_VARIANT}/*.c"
    "${STM32_H7_VARIANT}/*.cpp"
)

# SrcWrapper의 모든 하위 디렉토리를 include path에 자동 추가
file(GLOB_RECURSE SRCWRAPPER_SUBDIRS
    LIST_DIRECTORIES true
    "${STM32_CORE_PATH}/libraries/SrcWrapper/inc/*")
foreach(DIR ${SRCWRAPPER_SUBDIRS})
    if(IS_DIRECTORY ${DIR})
        list(APPEND BOARD_INCLUDE_DIRECTORIES "${DIR}")
    endif()
endforeach()

# Klangstrom 라이브러리 소스 파일들 (vendor 기반)
file(GLOB_RECURSE KLANGSTROM_SOURCES
    "${KLANGSTROM_ROOT}/libraries/Klangstrom/src/*.c"
    "${KLANGSTROM_ROOT}/libraries/Klangstrom/src/*.cpp"
)

file(GLOB_RECURSE KLANGSTROM_PANDA_SOURCES
    "${KLANGSTROM_ROOT}/libraries/Klangstrom_KLST_PANDA_STM32/src/*.c"
    "${KLANGSTROM_ROOT}/libraries/Klangstrom_KLST_PANDA_STM32/src/*.cpp"
)

file(GLOB_RECURSE KLANGSTROM_CUBEMX_SOURCES
    "${KLANGSTROM_ROOT}/libraries/Klangstrom_KLST_PANDA_STM32_CubeMX/src/*.c"
    "${KLANGSTROM_ROOT}/libraries/Klangstrom_KLST_PANDA_STM32_CubeMX/src/*.cpp"
)

# 보드 코어 소스 설정
set(BOARD_CORE_SOURCES
    ${STM32_CORE_SOURCES}
    ${SRCWRAPPER_HAL_SOURCES}
    ${SRCWRAPPER_LL_SOURCES}
    ${SRCWRAPPER_STM32_SOURCES}
    ${SRCWRAPPER_MAIN_SOURCES}
    ${KLST_VARIANT_SOURCES}
    ${STM32_VARIANT_SOURCES}
    ${KLANGSTROM_SOURCES}
    ${KLANGSTROM_PANDA_SOURCES}
    ${KLANGSTROM_CUBEMX_SOURCES}
)

# 라이브러리 설정
set(BOARD_LIBRARIES
    # ARM CMSIS DSP 라이브러리 (필요한 경우)
    # arm_cortexM7lfsp_math
)

# 후처리 함수 정의 (bin, hex 파일 생성)
function(board_post_build target_name)
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

    # DFU 업로드 타겟 생성 (DFU 모드 사용)
    add_custom_target(upload_dfu_${target_name}
        COMMAND dfu-util -a 0 -s 0x08000000:leave -D ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.bin
        DEPENDS ${target_name}
        COMMENT "Uploading ${target_name}.bin via DFU"
    )

    # OpenOCD 업로드 타겟 생성 (ST-Link 사용)
    add_custom_target(upload_openocd_${target_name}
        COMMAND openocd -f interface/stlink.cfg -f target/stm32h7x.cfg
                -c "program ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.elf verify reset exit"
        DEPENDS ${target_name}
        COMMENT "Uploading ${target_name}.elf via OpenOCD"
    )

    message(STATUS "To upload via DFU: make upload_dfu_${target_name}")
    message(STATUS "To upload via OpenOCD: make upload_openocd_${target_name}")
endfunction()