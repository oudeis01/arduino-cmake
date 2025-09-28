# Arduino Nano Board Configuration

# 툴체인을 가장 먼저 설정
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/avr-gcc.cmake")

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/cores/arduino-avr.cmake)

set(PROJECT_NAME "arduino_nano_project")

# AVR 보드 설정 (보드명, MCU, F_CPU, variant)
setup_avr_board("AVR_NANO" "atmega328p" "16000000L" "eightanaloginputs")

# 후처리 함수 등록
function(board_post_build target_name)
    avr_post_build(${target_name} "atmega328p")
    
    # 업로드 타겟 생성 (Nano는 구버전 부트로더 사용할 수 있음)
    if(NOT DEFINED UPLOAD_DEVICE)
        set(UPLOAD_DEVICE "/dev/ttyUSB0")
    endif()

    add_custom_target(upload_${target_name}
        COMMAND avrdude -p atmega328p -c arduino -P ${UPLOAD_DEVICE} -b 57600
                -U flash:w:${CMAKE_CURRENT_BINARY_DIR}/${target_name}.hex:i
        DEPENDS ${target_name}
        COMMENT "Uploading ${target_name}.hex to Arduino Nano via ${UPLOAD_DEVICE}"
    )
endfunction()