#===============================================================================
# AVR VENDOR INTEGRATION
#
# Integrates ArduinoCore-avr's boards.txt system:
# - Parses official Arduino boards.txt (100+ boards)
# - Automatic board property extraction
# - Complete Arduino compatibility
# - Zero external dependencies
#===============================================================================

set(AVR_VENDOR_ROOT "${VENDOR_ROOT}/ArduinoCore-avr")
set(AVR_BOARDS_TXT "${AVR_VENDOR_ROOT}/boards.txt")

# AVR board data storage
set(AVR_BOARDS_LIST "" CACHE INTERNAL "List of all AVR boards")
set(AVR_BOARD_CONFIGS "" CACHE INTERNAL "AVR board configurations")

#-------------------------------------------------------------------------------
# AVR vendor system integration
#-------------------------------------------------------------------------------
function(integrate_avr_vendor_system)
    if(NOT EXISTS "${AVR_BOARDS_TXT}")
        message(FATAL_ERROR "AVR boards.txt not found at: ${AVR_BOARDS_TXT}")
    endif()

    message(STATUS "Parsing Arduino boards.txt...")
    parse_arduino_boards_txt()

    list(LENGTH AVR_BOARDS_LIST avr_count)
    message(STATUS "Registered ${avr_count} Arduino boards from boards.txt")

    set(popular_avr uno nano mega2560 leonardo micro)
    set(found_popular)
    foreach(board ${popular_avr})
        if(board IN_LIST AVR_BOARDS_LIST)
            list(APPEND found_popular ${board})
        endif()
    endforeach()

    if(found_popular)
        message(STATUS "Popular Arduino boards available: ${found_popular}")
    endif()
endfunction()

#-------------------------------------------------------------------------------
# Parse Arduino boards.txt file
#-------------------------------------------------------------------------------
function(parse_arduino_boards_txt)
    file(READ "${AVR_BOARDS_TXT}" boards_content)

    # Remove comments and empty lines
    string(REGEX REPLACE "#[^\r\n]*" "" boards_content "${boards_content}")
    string(REGEX REPLACE "[\r\n]+" "\n" boards_content "${boards_content}")

    # Extract all board definitions
    set(board_ids)
    string(REGEX MATCHALL "([a-zA-Z0-9_]+)\\.name=" name_matches "${boards_content}")

    foreach(name_match ${name_matches})
        string(REGEX REPLACE "\\.name=" "" board_id "${name_match}")

        if(NOT board_id STREQUAL "menu" AND NOT board_id IN_LIST board_ids)
            list(APPEND board_ids ${board_id})

            extract_avr_board_properties("${board_id}" "${boards_content}")

            register_board(${board_id} "AVR")
        endif()
    endforeach()

    set(AVR_BOARDS_LIST ${board_ids} CACHE INTERNAL "All AVR boards")
endfunction()

function(extract_avr_board_properties board_id boards_content)
    set(board_config)

    string(REGEX MATCH "${board_id}\\.name=([^\r\n]+)" match "${boards_content}")
    if(CMAKE_MATCH_1)
        list(APPEND board_config "NAME:${CMAKE_MATCH_1}")
    endif()

    string(REGEX MATCH "${board_id}\\.build\\.mcu=([^\r\n]+)" match "${boards_content}")
    if(CMAKE_MATCH_1)
        list(APPEND board_config "MCU:${CMAKE_MATCH_1}")
    endif()

    string(REGEX MATCH "${board_id}\\.build\\.f_cpu=([^\r\n]+)" match "${boards_content}")
    if(CMAKE_MATCH_1)
        list(APPEND board_config "F_CPU:${CMAKE_MATCH_1}")
    endif()

    string(REGEX MATCH "${board_id}\\.upload\\.maximum_size=([^\r\n]+)" match "${boards_content}")
    if(CMAKE_MATCH_1)
        list(APPEND board_config "MAX_SIZE:${CMAKE_MATCH_1}")
    endif()

    string(REGEX MATCH "${board_id}\\.upload\\.maximum_data_size=([^\r\n]+)" match "${boards_content}")
    if(CMAKE_MATCH_1)
        list(APPEND board_config "MAX_DATA_SIZE:${CMAKE_MATCH_1}")
    endif()

    string(REGEX MATCH "${board_id}\\.build\\.variant=([^\r\n]+)" match "${boards_content}")
    if(CMAKE_MATCH_1)
        list(APPEND board_config "VARIANT:${CMAKE_MATCH_1}")
    else()
        list(APPEND board_config "VARIANT:standard")
    endif()

    string(REGEX MATCH "${board_id}\\.build\\.core=([^\r\n]+)" match "${boards_content}")
    if(CMAKE_MATCH_1)
        list(APPEND board_config "CORE:${CMAKE_MATCH_1}")
    else()
        list(APPEND board_config "CORE:arduino")
    endif()

    string(REGEX MATCH "${board_id}\\.upload\\.protocol=([^\r\n]+)" match "${boards_content}")
    if(CMAKE_MATCH_1)
        list(APPEND board_config "UPLOAD_PROTOCOL:${CMAKE_MATCH_1}")
    endif()

    string(REGEX MATCH "${board_id}\\.upload\\.speed=([^\r\n]+)" match "${boards_content}")
    if(CMAKE_MATCH_1)
        list(APPEND board_config "UPLOAD_SPEED:${CMAKE_MATCH_1}")
    endif()

    set(AVR_BOARD_CONFIG_${board_id} "${board_config}" CACHE INTERNAL "Config for ${board_id}")

    message(DEBUG "Extracted AVR board: ${board_id}")
endfunction()

#-------------------------------------------------------------------------------
# Individual AVR board setup
#-------------------------------------------------------------------------------
function(setup_avr_board board_id)
    message(STATUS "Setting up AVR board: ${board_id}")

    if(NOT board_id IN_LIST AVR_BOARDS_LIST)
        message(FATAL_ERROR "AVR board '${board_id}' not found in boards.txt")
    endif()

    get_property(board_config CACHE AVR_BOARD_CONFIG_${board_id} PROPERTY VALUE)

    set(board_name "")
    set(board_mcu "")
    set(board_f_cpu "")
    set(board_variant "standard")
    set(board_core "arduino")

    foreach(config_item ${board_config})
        if(config_item MATCHES "^NAME:(.+)$")
            set(board_name "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^MCU:(.+)$")
            set(board_mcu "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^F_CPU:(.+)$")
            set(board_f_cpu "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^VARIANT:(.+)$")
            set(board_variant "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^CORE:(.+)$")
            set(board_core "${CMAKE_MATCH_1}")
        endif()
    endforeach()

    set(PROJECT_NAME "${board_id}_project" PARENT_SCOPE)
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/avr-gcc.cmake" PARENT_SCOPE)

    setup_avr_paths("${board_variant}" "${board_core}")

    message(STATUS "AVR board '${board_id}' (${board_name}) configured")
    message(STATUS "   MCU: ${board_mcu}, F_CPU: ${board_f_cpu}")
endfunction()

function(setup_avr_paths variant core)
    set(AVR_CORE_PATH "${AVR_VENDOR_ROOT}/cores/${core}" PARENT_SCOPE)
    set(AVR_VARIANT_PATH "${AVR_VENDOR_ROOT}/variants/${variant}" PARENT_SCOPE)
    set(AVR_LIBRARIES_PATH "${AVR_VENDOR_ROOT}/libraries" PARENT_SCOPE)

    message(DEBUG "AVR paths - Core: ${AVR_VENDOR_ROOT}/cores/${core}, Variant: ${AVR_VENDOR_ROOT}/variants/${variant}")
endfunction()

#-------------------------------------------------------------------------------
# AVR build configuration
#-------------------------------------------------------------------------------
function(apply_avr_build_config target_name)
    message(STATUS "Applying AVR vendor build configuration...")

    get_property(board_config CACHE AVR_BOARD_CONFIG_${TARGET_BOARD} PROPERTY VALUE)

    set(board_mcu "")
    set(board_f_cpu "")
    set(board_variant "standard")
    set(board_core "arduino")

    foreach(config_item ${board_config})
        if(config_item MATCHES "^MCU:(.+)$")
            set(board_mcu "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^F_CPU:(.+)$")
            set(board_f_cpu "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^VARIANT:(.+)$")
            set(board_variant "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^CORE:(.+)$")
            set(board_core "${CMAKE_MATCH_1}")
        endif()
    endforeach()

    target_compile_definitions(${target_name} PRIVATE
        F_CPU=${board_f_cpu}
        ARDUINO=10607
        ARDUINO_AVR_${TARGET_BOARD}
        ARDUINO_ARCH_AVR
    )
    
    target_compile_options(${target_name} PRIVATE
        -mmcu=${board_mcu}
    )
    
    target_link_options(${target_name} PRIVATE
        -mmcu=${board_mcu}
    )

    target_include_directories(${target_name} PRIVATE
        "${AVR_VENDOR_ROOT}/cores/${board_core}"
        "${AVR_VENDOR_ROOT}/variants/${board_variant}"
    )
    
    set(LIBRARY_INCLUDE_DIRS "")
    
    if(EXISTS "${CMAKE_SOURCE_DIR}/libraries")
        file(GLOB PROJECT_LIBRARY_DIRS "${CMAKE_SOURCE_DIR}/libraries/*")
        foreach(LIB_DIR ${PROJECT_LIBRARY_DIRS})
            if(IS_DIRECTORY "${LIB_DIR}")
                if(IS_DIRECTORY "${LIB_DIR}/src")
                    list(APPEND LIBRARY_INCLUDE_DIRS "${LIB_DIR}/src")
                    file(GLOB SUBDIRS "${LIB_DIR}/src/*")
                    foreach(SUBDIR ${SUBDIRS})
                        if(IS_DIRECTORY "${SUBDIR}")
                            list(APPEND LIBRARY_INCLUDE_DIRS "${SUBDIR}")
                        endif()
                    endforeach()
                else()
                    list(APPEND LIBRARY_INCLUDE_DIRS "${LIB_DIR}")
                endif()
            endif()
        endforeach()
    endif()
    
    file(GLOB LIBRARY_DIRS "${AVR_VENDOR_ROOT}/libraries/*")
    foreach(LIB_DIR ${LIBRARY_DIRS})
        if(IS_DIRECTORY "${LIB_DIR}")
            if(IS_DIRECTORY "${LIB_DIR}/src")
                list(APPEND LIBRARY_INCLUDE_DIRS "${LIB_DIR}/src")
            else()
                list(APPEND LIBRARY_INCLUDE_DIRS "${LIB_DIR}")
            endif()
        endif()
    endforeach()
    
    set(USER_SOURCES "")
    foreach(SOURCE ${ARGN})
        if(SOURCE MATCHES "^${CMAKE_CURRENT_SOURCE_DIR}")
            list(APPEND USER_SOURCES ${SOURCE})
        endif()
    endforeach()
    
    foreach(INC_DIR ${LIBRARY_INCLUDE_DIRS})
        foreach(USER_SOURCE ${USER_SOURCES})
            if(USER_SOURCE MATCHES "\\.cpp$" OR USER_SOURCE MATCHES "\\.cxx$" OR USER_SOURCE MATCHES "\\.cc$")
                get_filename_component(SOURCE_OBJ ${USER_SOURCE} NAME_WE)
                set_source_files_properties(${USER_SOURCE} PROPERTIES 
                    COMPILE_FLAGS "-I${INC_DIR}"
                )
            endif()
        endforeach()
    endforeach()

    get_avr_vendor_sources("${board_core}")
    set(VENDOR_CORE_SOURCES ${AVR_VENDOR_SOURCES} PARENT_SCOPE)

    message(STATUS "Applied AVR configuration for ${board_mcu} @ ${board_f_cpu}")
endfunction()

function(get_avr_vendor_sources core)
    file(GLOB AVR_CORE_SOURCES
        "${AVR_VENDOR_ROOT}/cores/${core}/*.c"
        "${AVR_VENDOR_ROOT}/cores/${core}/*.cpp"
        "${AVR_VENDOR_ROOT}/cores/${core}/*.S"
    )

    file(GLOB LIBRARY_SOURCES
        "${AVR_VENDOR_ROOT}/libraries/*/src/*.c"
        "${AVR_VENDOR_ROOT}/libraries/*/src/*.cpp"
        "${AVR_VENDOR_ROOT}/libraries/*/src/*.S"
    )
    
    list(FILTER LIBRARY_SOURCES EXCLUDE REGEX ".*FastLED.*")

    set(AVR_VENDOR_SOURCES ${AVR_CORE_SOURCES} ${LIBRARY_SOURCES} PARENT_SCOPE)
    set(VENDOR_CORE_SOURCES ${AVR_CORE_SOURCES} ${LIBRARY_SOURCES} PARENT_SCOPE)

    list(LENGTH AVR_CORE_SOURCES core_count)
    list(LENGTH LIBRARY_SOURCES lib_count)
    math(EXPR total_count "${core_count} + ${lib_count}")
    
    message(STATUS "Collected ${core_count} AVR core sources")
    message(STATUS "Collected ${lib_count} vendor library sources")
    message(STATUS "Total vendor sources: ${total_count}")
endfunction()

#-------------------------------------------------------------------------------
# AVR post-build processing
#-------------------------------------------------------------------------------
function(execute_avr_post_build target_name)
    message(STATUS "Executing AVR vendor post-build steps...")

    find_program(CMAKE_OBJCOPY avr-objcopy REQUIRED)
    find_program(CMAKE_SIZE avr-size REQUIRED)
    find_program(AVRDUDE avrdude)

    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex -R .eeprom
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.hex
        COMMENT "Creating Arduino HEX file: ${target_name}.hex"
    )

    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex -j .eeprom
                --set-section-flags=.eeprom=alloc,load
                --no-change-warnings --change-section-lma .eeprom=0
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.eep
        COMMENT "Creating Arduino EEPROM file: ${target_name}.eep"
    )

    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_SIZE} -A $<TARGET_FILE:${target_name}>
        COMMENT "Arduino program size information:"
    )

    if(AVRDUDE)
        create_avr_upload_target(${target_name})
    endif()

    message(STATUS "AVR post-build configuration complete")
endfunction()

function(collect_avr_sources)
    message(STATUS "Collecting AVR vendor core sources...")

    get_property(board_config CACHE AVR_BOARD_CONFIG_${TARGET_BOARD} PROPERTY VALUE)

    set(board_core "arduino")
    foreach(config_item ${board_config})
        if(config_item MATCHES "^CORE:(.+)$")
            set(board_core "${CMAKE_MATCH_1}")
        endif()
    endforeach()

    file(GLOB AVR_CORE_SOURCES
        "${AVR_VENDOR_ROOT}/cores/${board_core}/*.c"
        "${AVR_VENDOR_ROOT}/cores/${board_core}/*.cpp"
        "${AVR_VENDOR_ROOT}/cores/${board_core}/*.S"
    )

    set(AVR_VENDOR_SOURCES ${AVR_CORE_SOURCES} PARENT_SCOPE)
    set(VENDOR_CORE_SOURCES ${AVR_CORE_SOURCES} PARENT_SCOPE)

    list(LENGTH AVR_CORE_SOURCES source_count)
    message(STATUS "Collected ${source_count} AVR core sources")
endfunction()

function(create_avr_upload_target target_name)
    get_property(board_config CACHE AVR_BOARD_CONFIG_${TARGET_BOARD} PROPERTY VALUE)

    set(upload_protocol "arduino")
    set(upload_speed "115200")
    set(board_mcu "atmega328p")

    foreach(config_item ${board_config})
        if(config_item MATCHES "^UPLOAD_PROTOCOL:(.+)$")
            set(upload_protocol "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^UPLOAD_SPEED:(.+)$")
            set(upload_speed "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^MCU:(.+)$")
            set(board_mcu "${CMAKE_MATCH_1}")
        endif()
    endforeach()

    if(NOT DEFINED UPLOAD_DEVICE)
        set(UPLOAD_DEVICE "/dev/ttyACM0")
    endif()

    add_custom_target(upload_${target_name}
        COMMAND avrdude -p ${board_mcu} -c ${upload_protocol} -P ${UPLOAD_DEVICE} -b ${upload_speed}
                -U flash:w:${CMAKE_CURRENT_BINARY_DIR}/${target_name}.hex:i
        DEPENDS ${target_name}
        COMMENT "Uploading ${target_name}.hex to Arduino via ${UPLOAD_DEVICE}"
    )

    message(STATUS "Upload target created: make upload_${target_name}")
endfunction()