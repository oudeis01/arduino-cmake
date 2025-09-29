#===============================================================================
# 🎯 VENDOR DISPATCHER - Central Vendor System Integration
#
# This module coordinates between different vendor systems:
# - STM32: Arduino_Core_STM32 (117K lines professional system)
# - AVR: ArduinoCore-avr (Arduino official boards.txt)
# - Klangstrom: Custom boards integrated with vendor systems
#===============================================================================

# Global vendor configuration
set(VENDOR_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/vendor")
set(ARDUINO_CMAKE_MINIMUM_VERSION 3.21)

# Board registry - will be populated by vendor systems
set(GLOBAL_BOARD_REGISTRY "" CACHE INTERNAL "All available boards from all vendors")
set(BOARD_VENDOR_MAP "" CACHE INTERNAL "Mapping of board -> vendor system")

#-------------------------------------------------------------------------------
# 🚀 Main vendor system initialization
#-------------------------------------------------------------------------------
function(initialize_vendor_systems)
    message(STATUS "🔧 Initializing vendor systems...")

    # Load vendor integration modules
    include(cmake/core/stm32_integration.cmake)
    include(cmake/core/avr_integration.cmake)
    include(cmake/core/klangstrom_integration.cmake)

    # Initialize each vendor system
    if(EXISTS "${VENDOR_ROOT}/Arduino_Core_STM32")
        message(STATUS "📡 Integrating Arduino_Core_STM32...")
        integrate_stm32_vendor_system()
    else()
        message(WARNING "⚠️  Arduino_Core_STM32 not found - STM32 boards unavailable")
    endif()

    if(EXISTS "${VENDOR_ROOT}/ArduinoCore-avr")
        message(STATUS "📡 Integrating ArduinoCore-avr...")
        integrate_avr_vendor_system()
    else()
        message(WARNING "⚠️  ArduinoCore-avr not found - Arduino boards unavailable")
    endif()

    if(EXISTS "${VENDOR_ROOT}/klangstrom-arduino")
        message(STATUS "📡 Integrating Klangstrom...")
        integrate_klangstrom_vendor_system()
    else()
        message(WARNING "⚠️  klangstrom-arduino not found - Klangstrom boards unavailable")
    endif()

    message(STATUS "✅ Vendor system initialization complete")
endfunction()

#-------------------------------------------------------------------------------
# 📋 Board detection and registration
#-------------------------------------------------------------------------------
function(detect_all_boards output_var)
    get_property(all_boards CACHE GLOBAL_BOARD_REGISTRY PROPERTY VALUE)

    if(NOT all_boards)
        message(WARNING "⚠️  No boards detected from vendor systems")
        set(all_boards "")
    endif()

    list(LENGTH all_boards board_count)
    message(STATUS "🔍 Detected ${board_count} boards from vendor systems")

    set(${output_var} ${all_boards} PARENT_SCOPE)
endfunction()

function(register_board board_id vendor_system)
    # Add board to global registry
    get_property(current_boards CACHE GLOBAL_BOARD_REGISTRY PROPERTY VALUE)
    list(APPEND current_boards ${board_id})
    list(REMOVE_DUPLICATES current_boards)
    set_property(CACHE GLOBAL_BOARD_REGISTRY PROPERTY VALUE "${current_boards}")

    # Map board to vendor system
    set_property(CACHE BOARD_VENDOR_MAP PROPERTY VALUE
        "${BOARD_VENDOR_MAP};${board_id}:${vendor_system}")

    message(DEBUG "📝 Registered board: ${board_id} -> ${vendor_system}")
endfunction()

function(get_board_vendor board_id output_var)
    get_property(vendor_map CACHE BOARD_VENDOR_MAP PROPERTY VALUE)

    foreach(mapping ${vendor_map})
        if(mapping MATCHES "^${board_id}:(.+)$")
            set(${output_var} ${CMAKE_MATCH_1} PARENT_SCOPE)
            return()
        endif()
    endforeach()

    message(FATAL_ERROR "❌ Board '${board_id}' not found in vendor mapping")
endfunction()

#-------------------------------------------------------------------------------
# 🎯 Board environment setup
#-------------------------------------------------------------------------------
function(setup_board_environment board_id)
    # Determine which vendor system handles this board
    get_board_vendor(${board_id} vendor_system)

    message(STATUS "🔧 Setting up board '${board_id}' using ${vendor_system} system")

    # Dispatch to appropriate vendor system
    if(vendor_system STREQUAL "STM32")
        setup_stm32_board(${board_id})
    elseif(vendor_system STREQUAL "AVR")
        setup_avr_board(${board_id})
    elseif(vendor_system STREQUAL "KLANGSTROM")
        setup_klangstrom_board(${board_id})
    else()
        message(FATAL_ERROR "❌ Unknown vendor system: ${vendor_system}")
    endif()

    # Set global variables for main CMakeLists.txt
    set(BOARD_VENDOR_SYSTEM ${vendor_system} PARENT_SCOPE)

    # Debug information
    message(STATUS "🔍 PROJECT_NAME after setup: ${PROJECT_NAME}")
    message(STATUS "🔍 VENDOR_CORE_SOURCES after setup: ${VENDOR_CORE_SOURCES}")
endfunction()

#-------------------------------------------------------------------------------
# 🔄 .ino file processing
#-------------------------------------------------------------------------------
function(process_ino_files source_list_var)
    set(source_list ${${source_list_var}})
    set(processed_sources)

    foreach(source_file ${source_list})
        if(source_file MATCHES "\\.ino$")
            get_filename_component(file_dir ${source_file} DIRECTORY)
            get_filename_component(file_name ${source_file} NAME_WE)
            set(cpp_file "${CMAKE_CURRENT_BINARY_DIR}/ino_generated/${file_name}.cpp")

            # Create directory if needed
            get_filename_component(cpp_dir ${cpp_file} DIRECTORY)
            file(MAKE_DIRECTORY ${cpp_dir})

            # Add Arduino.h include and copy content
            file(READ ${source_file} ino_content)
            file(WRITE ${cpp_file} "#include <Arduino.h>\n${ino_content}")

            list(APPEND processed_sources ${cpp_file})
            message(STATUS "🔄 Converted: ${source_file} -> ${cpp_file}")
        else()
            list(APPEND processed_sources ${source_file})
        endif()
    endforeach()

    set(${source_list_var} ${processed_sources} PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------------
# 📦 Vendor source collection (before target creation)
#-------------------------------------------------------------------------------
function(collect_vendor_sources)
    # Determine which vendor system handles the selected board
    get_board_vendor(${TARGET_BOARD} vendor_system)

    message(STATUS "📦 Collecting vendor sources for '${TARGET_BOARD}' using ${vendor_system} system")

    # Dispatch to appropriate vendor system for source collection
    if(vendor_system STREQUAL "STM32")
        collect_stm32_sources()
    elseif(vendor_system STREQUAL "AVR")
        collect_avr_sources()
    elseif(vendor_system STREQUAL "KLANGSTROM")
        collect_klangstrom_sources()
    else()
        message(FATAL_ERROR "❌ Unknown vendor system for source collection: ${vendor_system}")
    endif()

    # Set global variables for CMakeLists.txt
    set(VENDOR_CORE_SOURCES ${VENDOR_CORE_SOURCES} PARENT_SCOPE)

    list(LENGTH VENDOR_CORE_SOURCES source_count)
    message(STATUS "📦 Collected ${source_count} vendor sources")
endfunction()

#-------------------------------------------------------------------------------
# ⚙️ Build configuration application
#-------------------------------------------------------------------------------
function(apply_vendor_build_config target_name)
    # Apply vendor-specific build configuration
    get_board_vendor(${TARGET_BOARD} vendor_system)

    # Initialize local variable
    set(local_vendor_sources "")

    if(vendor_system STREQUAL "STM32")
        apply_stm32_build_config(${target_name})
        set(local_vendor_sources ${VENDOR_CORE_SOURCES})
    elseif(vendor_system STREQUAL "AVR")
        apply_avr_build_config(${target_name})
        set(local_vendor_sources ${VENDOR_CORE_SOURCES})
    elseif(vendor_system STREQUAL "KLANGSTROM")
        apply_klangstrom_build_config(${target_name})
        list(LENGTH VENDOR_CORE_SOURCES before_count)
        message(STATUS "🔍 VENDOR_CORE_SOURCES after apply_klangstrom_build_config: ${before_count} sources")
        set(local_vendor_sources ${VENDOR_CORE_SOURCES})
    endif()

    # Ensure VENDOR_CORE_SOURCES is set in parent scope
    set(VENDOR_CORE_SOURCES ${local_vendor_sources} PARENT_SCOPE)
    list(LENGTH local_vendor_sources source_count)
    message(STATUS "🔍 VENDOR_CORE_SOURCES in apply_vendor_build_config: ${source_count} sources")
endfunction()

function(execute_vendor_post_build target_name)
    # Execute vendor-specific post-build steps
    get_board_vendor(${TARGET_BOARD} vendor_system)

    if(vendor_system STREQUAL "STM32")
        execute_stm32_post_build(${target_name})
    elseif(vendor_system STREQUAL "AVR")
        execute_avr_post_build(${target_name})
    elseif(vendor_system STREQUAL "KLANGSTROM")
        execute_klangstrom_post_build(${target_name})
    endif()
endfunction()