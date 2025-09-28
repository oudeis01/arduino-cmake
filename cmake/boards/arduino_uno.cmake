# Arduino UNO Board Configuration

# 프로젝트 이름 설정
set(PROJECT_NAME "arduino_uno_project")

# 툴체인 파일 설정
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/avr-gcc.cmake")

# Arduino UNO 보드 정의
set(BOARD_COMPILE_DEFINITIONS
    F_CPU=16000000L
    ARDUINO=10607
    ARDUINO_AVR_UNO
    ARDUINO_ARCH_AVR
)

# vendor 기반 경로 설정
set(VENDOR_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/vendor")
set(ARDUINO_CORE_PATH "${VENDOR_ROOT}/ArduinoCore-avr")

# 인클루드 디렉토리
set(BOARD_INCLUDE_DIRECTORIES
    "${ARDUINO_CORE_PATH}/cores/arduino"
    "${ARDUINO_CORE_PATH}/variants/standard"
)

# 컴파일 옵션 (추가적인 보드별 옵션)
set(BOARD_COMPILE_OPTIONS
    # 여기에 추가 컴파일 옵션 추가 가능
)

# 링크 옵션
set(BOARD_LINK_OPTIONS
    # 여기에 추가 링크 옵션 추가 가능
)

# Arduino 코어 소스 파일들
file(GLOB ARDUINO_CORE_SOURCES
    "${ARDUINO_CORE_PATH}/cores/arduino/*.c"
    "${ARDUINO_CORE_PATH}/cores/arduino/*.cpp"
    "${ARDUINO_CORE_PATH}/cores/arduino/*.S"
)

# 보드 코어 소스 설정
set(BOARD_CORE_SOURCES ${ARDUINO_CORE_SOURCES})

# 라이브러리 설정
set(BOARD_LIBRARIES
    # 필요한 라이브러리 추가
)

# 후처리 함수 정의 (hex 파일 생성)
function(board_post_build target_name)
    # Intel HEX 파일 생성
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex -R .eeprom
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.hex
        COMMENT "Creating Intel HEX file: ${target_name}.hex"
    )

    # EEPROM 파일 생성
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex -j .eeprom
                --set-section-flags=.eeprom=alloc,load
                --no-change-warnings --change-section-lma .eeprom=0
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.eep
        COMMENT "Creating EEPROM file: ${target_name}.eep"
    )

    # 크기 정보 출력
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_SIZE} -A $<TARGET_FILE:${target_name}>
        COMMENT "Program size information:"
    )

    # 업로드 타겟 생성 (디바이스 경로를 변수로 설정)
    if(NOT DEFINED UPLOAD_DEVICE)
        set(UPLOAD_DEVICE "/dev/ttyACM0")
    endif()

    add_custom_target(upload_${target_name}
        COMMAND avrdude -p atmega328p -c arduino -P ${UPLOAD_DEVICE} -b 115200
                -U flash:w:${CMAKE_CURRENT_BINARY_DIR}/${target_name}.hex:i
        DEPENDS ${target_name}
        COMMENT "Uploading ${target_name}.hex to Arduino UNO via ${UPLOAD_DEVICE}"
    )

    message(STATUS "To upload: make upload_${target_name}")
endfunction()