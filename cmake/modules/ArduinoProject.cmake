set(ARDUINO_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}/../..")
set(ARDUINO_INSTALL_DIR "${ARDUINO_CMAKE_DIR}/install")

function(arduino_init)
    cmake_parse_arguments(ARG "" "BOARD" "" ${ARGN})
    
    if(NOT ARG_BOARD)
        message(FATAL_ERROR "arduino_init: BOARD parameter is required")
    endif()
    
    set(BOARD_CONFIG_FILE "${ARDUINO_CMAKE_DIR}/cmake/boards/avr/${ARG_BOARD}.cmake")
    
    if(NOT EXISTS "${BOARD_CONFIG_FILE}")
        message(FATAL_ERROR "Board configuration not found: ${ARG_BOARD}")
    endif()
    
    include("${BOARD_CONFIG_FILE}")
    
    if(NOT DEFINED BOARD_MCU OR NOT DEFINED BOARD_F_CPU)
        message(FATAL_ERROR "Board configuration incomplete for: ${ARG_BOARD}")
    endif()
    
    set(CMAKE_SYSTEM_NAME Generic PARENT_SCOPE)
    set(CMAKE_SYSTEM_PROCESSOR avr PARENT_SCOPE)
    
    find_program(CMAKE_C_COMPILER avr-gcc REQUIRED)
    find_program(CMAKE_CXX_COMPILER avr-g++ REQUIRED)
    find_program(CMAKE_AR avr-ar REQUIRED)
    find_program(CMAKE_RANLIB avr-ranlib REQUIRED)
    
    set(CMAKE_C_COMPILER ${CMAKE_C_COMPILER} PARENT_SCOPE)
    set(CMAKE_CXX_COMPILER ${CMAKE_CXX_COMPILER} PARENT_SCOPE)
    set(CMAKE_AR ${CMAKE_AR} PARENT_SCOPE)
    set(CMAKE_RANLIB ${CMAKE_RANLIB} PARENT_SCOPE)
    
    set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY PARENT_SCOPE)
    
    set(ARDUINO_BOARD ${ARG_BOARD} PARENT_SCOPE)
    set(ARDUINO_MCU ${BOARD_MCU} PARENT_SCOPE)
    set(ARDUINO_F_CPU ${BOARD_F_CPU} PARENT_SCOPE)
    
    message(STATUS "Arduino initialized: ${ARG_BOARD} (${BOARD_MCU} @ ${BOARD_F_CPU})")
endfunction()

function(arduino_executable TARGET_NAME)
    cmake_parse_arguments(ARG "" "" "SOURCES" ${ARGN})
    
    if(NOT ARG_SOURCES)
        message(FATAL_ERROR "arduino_executable: SOURCES parameter is required")
    endif()
    
    if(NOT DEFINED ARDUINO_BOARD)
        message(FATAL_ERROR "arduino_executable: Call arduino_init() first")
    endif()
    
    set(CORE_LIB "${ARDUINO_INSTALL_DIR}/lib/libArduinoCore-${ARDUINO_BOARD}.a")
    
    if(NOT EXISTS "${CORE_LIB}")
        message(FATAL_ERROR "Arduino core library not found. Build the core first: cd ${ARDUINO_CMAKE_DIR} && cmake -B build && cmake --build build --target install")
    endif()
    
    add_executable(${TARGET_NAME} ${ARG_SOURCES})
    
    target_compile_definitions(${TARGET_NAME} PRIVATE
        F_CPU=${ARDUINO_F_CPU}
        ARDUINO=10607
        ARDUINO_AVR_${ARDUINO_BOARD}
        ARDUINO_ARCH_AVR
        FASTLED_INTERNAL
        NO_HARDWARE_PIN_SUPPORT
    )
    
    target_compile_options(${TARGET_NAME} PRIVATE
        -mmcu=${ARDUINO_MCU}
        -Os
        -Wall
        -ffunction-sections
        -fdata-sections
        -flto
    )
    
    target_include_directories(${TARGET_NAME} PRIVATE
        "${ARDUINO_INSTALL_DIR}/include/arduino"
        "${ARDUINO_INSTALL_DIR}/include/variant"
    )
    
    target_link_libraries(${TARGET_NAME} PRIVATE ${CORE_LIB})
    
    target_link_options(${TARGET_NAME} PRIVATE
        -mmcu=${ARDUINO_MCU}
        -Wl,--gc-sections
        -flto
        -fuse-linker-plugin
    )
    
    find_program(AVROBJCOPY avr-objcopy REQUIRED)
    find_program(AVRSIZE avr-size REQUIRED)
    
    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        COMMAND ${AVROBJCOPY} -O ihex -R .eeprom $<TARGET_FILE:${TARGET_NAME}> ${TARGET_NAME}.hex
        COMMENT "Creating HEX file: ${TARGET_NAME}.hex"
    )
    
    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        COMMAND ${AVRSIZE} -C --mcu=${ARDUINO_MCU} $<TARGET_FILE:${TARGET_NAME}>
        COMMENT "Program size:"
    )
    
    message(STATUS "Arduino executable configured: ${TARGET_NAME}")
endfunction()

function(arduino_upload_target TARGET_NAME)
    cmake_parse_arguments(ARG "" "PORT;PROGRAMMER;BAUDRATE" "" ${ARGN})
    
    if(NOT ARG_PORT)
        set(ARG_PORT "/dev/ttyACM0")
    endif()
    
    if(NOT ARG_PROGRAMMER)
        set(ARG_PROGRAMMER "arduino")
    endif()
    
    if(NOT ARG_BAUDRATE)
        set(ARG_BAUDRATE "115200")
    endif()
    
    find_program(AVRDUDE avrdude)
    
    if(NOT AVRDUDE)
        message(WARNING "avrdude not found. Upload target will not be created.")
        return()
    endif()
    
    add_custom_target(upload
        COMMAND ${AVRDUDE} -p ${ARDUINO_MCU} -c ${ARG_PROGRAMMER} -P ${ARG_PORT} -b ${ARG_BAUDRATE}
                -U flash:w:${TARGET_NAME}.hex:i
        DEPENDS ${TARGET_NAME}
        COMMENT "Uploading ${TARGET_NAME}.hex to ${ARG_PORT}"
    )
    
    message(STATUS "Upload target created: make upload")
endfunction()
