# Arduino AVR Core 추상화
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/utils/vendor-paths.cmake)

if(NOT ARDUINO_AVR_AVAILABLE)
    message(FATAL_ERROR "Arduino AVR core not available")
endif()

# 코어 기본 정보
set(ARDUINO_AVR_CORES "${ARDUINO_AVR_ROOT}/cores/arduino")
set(ARDUINO_AVR_VARIANTS "${ARDUINO_AVR_ROOT}/variants")
set(ARDUINO_AVR_LIBRARIES "${ARDUINO_AVR_ROOT}/libraries")

# 공통 컴파일 정의
set(ARDUINO_AVR_COMPILE_DEFINITIONS
    ARDUINO=10607
    ARDUINO_ARCH_AVR
)

# 공통 include 디렉토리
set(ARDUINO_AVR_INCLUDE_DIRECTORIES
    "${ARDUINO_AVR_CORES}"
)

# 코어 소스 파일들
file(GLOB ARDUINO_AVR_CORE_SOURCES
    "${ARDUINO_AVR_CORES}/*.c"
    "${ARDUINO_AVR_CORES}/*.cpp"
    "${ARDUINO_AVR_CORES}/*.S"
)

# AVR 보드 설정 함수
function(setup_avr_board board_name mcu_name f_cpu variant_name)
    # 보드별 정의 추가 - 글로벌 스코프로 설정
    set(BOARD_COMPILE_DEFINITIONS 
        ${ARDUINO_AVR_COMPILE_DEFINITIONS}
        F_CPU=${f_cpu}
        ARDUINO_${board_name}
        CACHE INTERNAL ""
    )
    
    # 보드별 include 경로 - 글로벌 스코프로 설정
    set(BOARD_INCLUDE_DIRECTORIES
        ${ARDUINO_AVR_INCLUDE_DIRECTORIES}
        "${ARDUINO_AVR_VARIANTS}/${variant_name}"
        CACHE INTERNAL ""
    )
    
    # 코어 소스 설정 - 글로벌 스코프로 설정
    set(BOARD_CORE_SOURCES ${ARDUINO_AVR_CORE_SOURCES} CACHE INTERNAL "")
    
    # MCU별 컴파일 옵션 추가 - 글로벌 스코프로 설정
    set(BOARD_COMPILE_OPTIONS -mmcu=${mcu_name} CACHE INTERNAL "")
    set(BOARD_LINK_OPTIONS 
        -mmcu=${mcu_name}
        -Wl,--gc-sections
        -flto
        -fuse-linker-plugin
        CACHE INTERNAL ""
    )
    
    message(STATUS "AVR Board configured: ${board_name} (${mcu_name}, ${f_cpu})")
    message(STATUS "Include directories: ${ARDUINO_AVR_INCLUDE_DIRECTORIES};${ARDUINO_AVR_VARIANTS}/${variant_name}")
endfunction()

# 후처리 함수 (hex 파일 생성)
function(avr_post_build target_name mcu_name)
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex -R .eeprom
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.hex
        COMMENT "Creating Intel HEX file: ${target_name}.hex"
    )
    
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex -j .eeprom
                --set-section-flags=.eeprom=alloc,load
                --no-change-warnings --change-section-lma .eeprom=0
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.eep
        COMMENT "Creating EEPROM file: ${target_name}.eep"
    )
    
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_SIZE} -A $<TARGET_FILE:${target_name}>
        COMMENT "Program size information:"
    )
endfunction()