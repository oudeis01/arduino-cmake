# AVR-GCC Toolchain for Arduino
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)

# 시스템 툴체인 우선 탐지 (인라인)
find_program(FOUND_AVR_GCC avr-gcc PATHS
    /usr/bin
    /usr/local/bin
    /opt/homebrew/bin
)
if(FOUND_AVR_GCC)
    set(SYSTEM_AVR_AVAILABLE TRUE)
    message(STATUS "Found system toolchain: ${FOUND_AVR_GCC}")
    # 풀 패스를 사용하여 명시적으로 설정 - 언어 검출 이전에 설정
    set(CMAKE_C_COMPILER ${FOUND_AVR_GCC})
    set(CMAKE_CXX_COMPILER "/usr/bin/avr-g++") 
    set(CMAKE_ASM_COMPILER ${FOUND_AVR_GCC})
    unset(FOUND_AVR_GCC CACHE)
else()
    set(SYSTEM_AVR_AVAILABLE FALSE)
    message(WARNING "System toolchain avr-gcc not found")
    # 폴백 설정
    set(CMAKE_C_COMPILER "avr-gcc")
    set(CMAKE_CXX_COMPILER "avr-g++")
    set(CMAKE_ASM_COMPILER "avr-gcc")
endif()

# CMake가 컴파일러를 테스트하지 않도록 설정 (임베디드 툴체인용)
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_ASM_COMPILER_WORKS TRUE)

# 크로스 컴파일 설정
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

if(SYSTEM_AVR_AVAILABLE)
    # 시스템 툴체인 사용 (컴파일러는 이미 위에서 설정됨)
    set(CMAKE_AR "avr-gcc-ar")
    set(CMAKE_OBJCOPY "avr-objcopy")
    set(CMAKE_OBJDUMP "avr-objdump") 
    set(CMAKE_SIZE "avr-size")
    
    # 시스템 AVR-libc 헤더 경로 추가
    set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES /usr/avr/include)
    set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES /usr/avr/include)
    
    message(STATUS "Using system AVR toolchain")
else()
    # Arduino IDE 툴체인 폴백
    set(AVR_GCC_PATH "/home/choiharam/.arduino15/packages/arduino/tools/avr-gcc/7.3.0-atmel3.6.1-arduino7")
    
    if(NOT EXISTS ${AVR_GCC_PATH})
        message(FATAL_ERROR "AVR-GCC not found. Please install: sudo pacman -S avr-gcc avr-libc")
    endif()
    
    set(CMAKE_C_COMPILER "${AVR_GCC_PATH}/bin/avr-gcc")
    set(CMAKE_CXX_COMPILER "${AVR_GCC_PATH}/bin/avr-g++")
    set(CMAKE_ASM_COMPILER "${AVR_GCC_PATH}/bin/avr-gcc")
    set(CMAKE_AR "${AVR_GCC_PATH}/bin/avr-gcc-ar")
    set(CMAKE_OBJCOPY "${AVR_GCC_PATH}/bin/avr-objcopy")
    set(CMAKE_OBJDUMP "${AVR_GCC_PATH}/bin/avr-objdump")
    set(CMAKE_SIZE "${AVR_GCC_PATH}/bin/avr-size")
    message(STATUS "Using Arduino IDE AVR toolchain")
endif()

# AVR 공통 컴파일러 플래그 (보드에서 MCU 지정)
set(AVR_BASE_FLAGS "-ffunction-sections -fdata-sections -MMD -flto -fno-fat-lto-objects")

# C 컴파일러 플래그
set(CMAKE_C_FLAGS "${AVR_BASE_FLAGS} -std=gnu11" CACHE STRING "")
set(CMAKE_C_FLAGS_DEBUG "-g -Os -Wall -Wextra" CACHE STRING "")
set(CMAKE_C_FLAGS_RELEASE "-Os -DNDEBUG -Wall -Wextra" CACHE STRING "")

# C++ 컴파일러 플래그
set(CMAKE_CXX_FLAGS "${AVR_BASE_FLAGS} -std=gnu++11 -fpermissive -fno-exceptions -fno-threadsafe-statics -Wno-error=narrowing" CACHE STRING "")
set(CMAKE_CXX_FLAGS_DEBUG "-g -Os -Wall -Wextra" CACHE STRING "")
set(CMAKE_CXX_FLAGS_RELEASE "-Os -DNDEBUG -Wall -Wextra" CACHE STRING "")

# 어셈블러 플래그
set(CMAKE_ASM_FLAGS "-x assembler-with-cpp -flto -MMD" CACHE STRING "")

# 기본 링커 플래그 (보드에서 MCU와 추가 플래그 지정)
set(CMAKE_EXE_LINKER_FLAGS "-lm" CACHE STRING "")

# 디버그 정보 제거 (Release 빌드용)
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "-Wl,--strip-debug" CACHE STRING "")