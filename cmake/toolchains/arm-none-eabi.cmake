# ARM-None-EABI Toolchain for STM32
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

# 시스템 툴체인 우선 탐지 (인라인)
find_program(FOUND_ARM_GCC arm-none-eabi-gcc PATHS
    /usr/bin
    /usr/local/bin
    /opt/homebrew/bin
)
if(FOUND_ARM_GCC)
    set(SYSTEM_ARM_AVAILABLE TRUE)
    message(STATUS "Found system toolchain: ${FOUND_ARM_GCC}")
    # 풀 패스를 사용하여 명시적으로 설정
    set(CMAKE_C_COMPILER ${FOUND_ARM_GCC})
    set(CMAKE_CXX_COMPILER "/usr/bin/arm-none-eabi-g++")
    set(CMAKE_ASM_COMPILER ${FOUND_ARM_GCC})
    unset(FOUND_ARM_GCC CACHE)
else()
    set(SYSTEM_ARM_AVAILABLE FALSE)
    message(WARNING "System toolchain arm-none-eabi-gcc not found")
    # 폴백 설정
    set(CMAKE_C_COMPILER "arm-none-eabi-gcc")
    set(CMAKE_CXX_COMPILER "arm-none-eabi-g++")
    set(CMAKE_ASM_COMPILER "arm-none-eabi-gcc")
endif()

if(SYSTEM_ARM_AVAILABLE)
    # 시스템 툴체인 사용 (컴파일러는 이미 위에서 설정됨)
    set(CMAKE_AR "arm-none-eabi-ar")
    set(CMAKE_OBJCOPY "arm-none-eabi-objcopy")
    set(CMAKE_OBJDUMP "arm-none-eabi-objdump")
    set(CMAKE_SIZE "arm-none-eabi-size")
    
    # 시스템 ARM newlib 헤더 경로 추가 - 순서가 중요함
    set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES 
        /usr/arm-none-eabi/include
        /usr/lib/gcc/arm-none-eabi/14.2.0/include
    )
    set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES 
        /usr/arm-none-eabi/include/c++/14.2.0
        /usr/arm-none-eabi/include/c++/14.2.0/arm-none-eabi  
        /usr/arm-none-eabi/include
        /usr/lib/gcc/arm-none-eabi/14.2.0/include
    )
    
    message(STATUS "Using system ARM toolchain")
else()
    # Arduino IDE 툴체인 폴백
    set(ARM_GCC_PATH "/home/choiharam/.arduino15/packages/STMicroelectronics/tools/xpack-arm-none-eabi-gcc/14.2.1-1.1")
    
    if(NOT EXISTS ${ARM_GCC_PATH})
        message(FATAL_ERROR "ARM-None-EABI GCC not found. Please install: sudo pacman -S arm-none-eabi-gcc arm-none-eabi-newlib")
    endif()
    
    set(CMAKE_C_COMPILER "${ARM_GCC_PATH}/bin/arm-none-eabi-gcc")
    set(CMAKE_CXX_COMPILER "${ARM_GCC_PATH}/bin/arm-none-eabi-g++")
    set(CMAKE_ASM_COMPILER "${ARM_GCC_PATH}/bin/arm-none-eabi-gcc")
    set(CMAKE_AR "${ARM_GCC_PATH}/bin/arm-none-eabi-ar")
    set(CMAKE_OBJCOPY "${ARM_GCC_PATH}/bin/arm-none-eabi-objcopy")
    set(CMAKE_OBJDUMP "${ARM_GCC_PATH}/bin/arm-none-eabi-objdump")
    set(CMAKE_SIZE "${ARM_GCC_PATH}/bin/arm-none-eabi-size")
    message(STATUS "Using Arduino IDE ARM toolchain")
endif()

# 실행 파일 확장자 설정
set(CMAKE_EXECUTABLE_SUFFIX ".elf")

# CMake가 컴파일러를 테스트하지 않도록 설정
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_ASM_COMPILER_WORKS TRUE)

# 크로스 컴파일 설정
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# ARM Cortex-M7 공통 컴파일러 플래그
set(ARM_COMMON_FLAGS "-mcpu=cortex-m7 -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb")

# C 컴파일러 플래그
set(CMAKE_C_FLAGS "${ARM_COMMON_FLAGS} -std=gnu17 -ffunction-sections -fdata-sections --param max-inline-insns-single=500 -MMD" CACHE STRING "")
set(CMAKE_C_FLAGS_DEBUG "-g -Og -Wall -Wextra" CACHE STRING "")
set(CMAKE_C_FLAGS_RELEASE "-Os -DNDEBUG -Wall -Wextra" CACHE STRING "")

# C++ 컴파일러 플래그
set(CMAKE_CXX_FLAGS "${ARM_COMMON_FLAGS} -std=gnu++17 -ffunction-sections -fdata-sections -fno-threadsafe-statics --param max-inline-insns-single=500 -fno-rtti -fno-exceptions -fno-use-cxa-atexit -MMD" CACHE STRING "")
set(CMAKE_CXX_FLAGS_DEBUG "-g -Og -Wall -Wextra" CACHE STRING "")
set(CMAKE_CXX_FLAGS_RELEASE "-Os -DNDEBUG -Wall -Wextra" CACHE STRING "")

# 어셈블러 플래그
set(CMAKE_ASM_FLAGS "${ARM_COMMON_FLAGS} -x assembler-with-cpp" CACHE STRING "")

# 링커 플래그
set(CMAKE_EXE_LINKER_FLAGS "${ARM_COMMON_FLAGS} --specs=nano.specs" CACHE STRING "")

# 링크 라이브러리
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lc -lm -lgcc -lstdc++")

# 디버그 정보 제거 (Release 빌드용)
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "-Wl,--strip-debug" CACHE STRING "")