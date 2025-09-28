# KLST_PANDA Board Configuration (Klangstrom)

# 툴체인을 가장 먼저 설정
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/arm-none-eabi.cmake")

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/cores/klangstrom.cmake)

set(PROJECT_NAME "klst_panda_project" CACHE INTERNAL "")

# KLST_PANDA는 STM32H723 기반
setup_klangstrom_board("KLST_PANDA" "H7" "STM32H723xx" "STM32H7xx/H723Z(E-G)T_H730ZBT_H733ZGT")

# 추가 KLST_PANDA 특화 정의들
set(BOARD_COMPILE_DEFINITIONS 
    ${BOARD_COMPILE_DEFINITIONS}
    CORE_CM7
    BOARD_NAME="KLST_PANDA"
    VARIANT_H="variant_KLST_PANDA.h"
    CACHE INTERNAL ""
)

# 링커 스크립트 설정
set(BOARD_LINK_OPTIONS
    ${BOARD_LINK_OPTIONS}
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
    "-Wl,--default-script=${KLANGSTROM_ROOT}/variants/KLST_PANDA/variant/variant_KLST_PANDA.ld"
    "-Wl,--script=${ARDUINO_STM32_SYSTEM}/ldscript.ld"
    "-Wl,-Map,${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.map"
    CACHE INTERNAL ""
)

# 후처리 함수 등록
function(board_post_build target_name)
    stm32_post_build(${target_name})
    
    # DFU 업로드 타겟 (KLST_PANDA는 DFU 지원)
    add_custom_target(upload_${target_name}
        COMMAND dfu-util -a 0 -s 0x08000000:leave -D ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.bin
        DEPENDS ${target_name}
        COMMENT "Uploading ${target_name}.bin to KLST_PANDA via DFU"
    )
    
    message(STATUS "To upload: make upload_${target_name} (put KLST_PANDA in DFU mode first)")
endfunction()