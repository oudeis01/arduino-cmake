# Klangstrom Core 추상화
# vendor-paths.cmake는 main CMakeLists.txt에서 이미 include되므로 제거
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/cores/arduino-stm32.cmake)

if(NOT KLANGSTROM_AVAILABLE)
    message(FATAL_ERROR "Klangstrom core not available")
endif()

# Klangstrom 기본 정보
set(KLANGSTROM_VARIANTS "${KLANGSTROM_ROOT}/variants")
set(KLANGSTROM_LIBRARIES "${KLANGSTROM_ROOT}/libraries")

# Klangstrom 보드 설정 함수 (STM32 기반 확장)
function(setup_klangstrom_board board_name mcu_series mcu_name variant_path)
    # STM32 기본 설정 먼저 적용
    setup_stm32_board(${board_name} ${mcu_series} ${mcu_name} ${variant_path})
    
    # Klangstrom 특화 정의 추가
    set(BOARD_COMPILE_DEFINITIONS 
        ${BOARD_COMPILE_DEFINITIONS}
        KLST_ENV=0x36
        CUSTOM_PERIPHERAL_PINS
        HAL_UART_MODULE_ENABLED
        VECT_TAB_OFFSET=0x0
        CACHE INTERNAL ""
    )
    
    # Klangstrom 라이브러리 include 경로 추가
    set(BOARD_INCLUDE_DIRECTORIES
        ${BOARD_INCLUDE_DIRECTORIES}
        "${KLANGSTROM_LIBRARIES}/Klangstrom/src"
        "${KLANGSTROM_LIBRARIES}/Klangstrom_${board_name}_STM32/src"
        "${KLANGSTROM_LIBRARIES}/Klangstrom_${board_name}_STM32_CubeMX/src"
        "${KLANGSTROM_VARIANTS}/${board_name}/variant"
        CACHE INTERNAL ""
    )
    
    # Klangstrom 라이브러리 소스 파일들 추가
    file(GLOB_RECURSE KLANGSTROM_CORE_SOURCES
        "${KLANGSTROM_LIBRARIES}/Klangstrom/src/*.c"
        "${KLANGSTROM_LIBRARIES}/Klangstrom/src/*.cpp"
        "${KLANGSTROM_LIBRARIES}/Klangstrom_${board_name}_STM32/src/*.c"
        "${KLANGSTROM_LIBRARIES}/Klangstrom_${board_name}_STM32/src/*.cpp"
        "${KLANGSTROM_LIBRARIES}/Klangstrom_${board_name}_STM32_CubeMX/src/*.c"
        "${KLANGSTROM_LIBRARIES}/Klangstrom_${board_name}_STM32_CubeMX/src/*.cpp"
    )
    
    # 기존 STM32 소스와 Klangstrom 소스 합치기
    set(BOARD_CORE_SOURCES 
        ${BOARD_CORE_SOURCES}
        ${KLANGSTROM_CORE_SOURCES}
        CACHE INTERNAL ""
    )
    
    # list 길이 계산을 별도로 수행
    list(LENGTH KLANGSTROM_CORE_SOURCES KLANGSTROM_SOURCE_COUNT)
    message(STATUS "Klangstrom Board configured: ${board_name} with ${KLANGSTROM_SOURCE_COUNT} additional source files")
endfunction()