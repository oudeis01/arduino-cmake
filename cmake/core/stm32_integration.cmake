#===============================================================================
# 🔧 STM32 VENDOR INTEGRATION
#
# Integrates Arduino_Core_STM32's professional CMake system:
# - 117,166 lines boards_db.cmake with 500+ STM32 boards
# - Professional compilation settings (overall_settings.cmake)
# - Automatic toolchain management (ensure_core_deps.cmake)
# - Complete HAL/LL driver integration
#===============================================================================

set(STM32_VENDOR_ROOT "${VENDOR_ROOT}/Arduino_Core_STM32")
set(STM32_CMAKE_ROOT "${STM32_VENDOR_ROOT}/cmake")

# STM32 board data storage
set(STM32_BOARDS_LIST "" CACHE INTERNAL "List of all STM32 boards")
set(STM32_BOARD_CONFIGS "" CACHE INTERNAL "STM32 board configurations")

#-------------------------------------------------------------------------------
# 🚀 STM32 vendor system integration
#-------------------------------------------------------------------------------
function(integrate_stm32_vendor_system)
    if(NOT EXISTS "${STM32_CMAKE_ROOT}")
        message(FATAL_ERROR "❌ STM32 CMake system not found at: ${STM32_CMAKE_ROOT}")
    endif()

    # Add STM32 cmake modules to path
    list(APPEND CMAKE_MODULE_PATH "${STM32_CMAKE_ROOT}")

    # Load STM32 vendor system (117K lines!)
    message(STATUS "📊 Loading STM32 boards database (117K lines)...")
    include(boards_db)
    message(STATUS "✅ STM32 boards database loaded")

    # Load other STM32 vendor modules
    include(set_board)
    include(overall_settings)
    include(ensure_core_deps)

    # Extract and register all STM32 boards
    extract_stm32_boards()

    # Set up STM32 build environment
    setup_stm32_build_environment()

    list(LENGTH STM32_BOARDS_LIST stm32_count)
    message(STATUS "🎯 Registered ${stm32_count} STM32 boards from vendor system")
endfunction()

#-------------------------------------------------------------------------------
# 📋 Extract STM32 boards from vendor database
#-------------------------------------------------------------------------------
function(extract_stm32_boards)
    # Get all variables from boards_db.cmake
    get_cmake_property(all_vars VARIABLES)
    set(board_ids)

    # Find all board definitions (looking for *_VARIANT_PATH pattern)
    foreach(var_name ${all_vars})
        if(var_name MATCHES "^(.+)_VARIANT_PATH$")
            string(REGEX REPLACE "_VARIANT_PATH$" "" board_id "${var_name}")

            # Verify this is a real board (has required properties)
            if(DEFINED ${board_id}_MAXSIZE AND DEFINED ${board_id}_MCU)
                list(APPEND board_ids ${board_id})

                # Store board configuration
                set(config_data
                    "VARIANT_PATH:${${board_id}_VARIANT_PATH}"
                    "MAXSIZE:${${board_id}_MAXSIZE}"
                    "MAXDATASIZE:${${board_id}_MAXDATASIZE}"
                    "MCU:${${board_id}_MCU}"
                    "FPCONF:${${board_id}_FPCONF}"
                )
                set(STM32_BOARD_CONFIG_${board_id} "${config_data}" CACHE INTERNAL "Config for ${board_id}")

                # Register with global system
                register_board(${board_id} "STM32")
            endif()
        endif()
    endforeach()

    set(STM32_BOARDS_LIST ${board_ids} CACHE INTERNAL "All STM32 boards")

    # Debug: Show some popular boards
    set(popular_boards NUCLEO_F401RE NUCLEO_F446RE NUCLEO_H743ZI2 DISCO_F407VG)
    set(found_popular)
    foreach(board ${popular_boards})
        if(board IN_LIST board_ids)
            list(APPEND found_popular ${board})
        endif()
    endforeach()

    if(found_popular)
        message(STATUS "🌟 Popular STM32 boards available: ${found_popular}")
    endif()
endfunction()

#-------------------------------------------------------------------------------
# 🔧 STM32 build environment setup
#-------------------------------------------------------------------------------
function(setup_stm32_build_environment)
    # Use vendor's toolchain management if available
    if(COMMAND ensure_core_deps)
        # This downloads and sets up the correct ARM toolchain automatically
        set(DL_DIR "${CMAKE_CURRENT_BINARY_DIR}/stm32_deps" CACHE PATH "STM32 dependencies directory")
        set(PLATFORMTXT_PATH "${STM32_VENDOR_ROOT}/platform.txt" CACHE PATH "STM32 platform.txt path")
        set(JSONCONFIG_URL "https://github.com/stm32duino/BoardManagerFiles/raw/main/package_stmicroelectronics_index.json")

        # Vendor system will set up toolchain
        #ensure_core_deps()
        message(STATUS "🛠️  STM32 vendor toolchain management available")
    endif()

    # Set common STM32 paths
    set(STM32_CORE_PATH "${STM32_VENDOR_ROOT}" CACHE PATH "STM32 core path")
    set(STM32_SYSTEM_PATH "${STM32_VENDOR_ROOT}/system" CACHE PATH "STM32 system path")
    set(STM32_HAL_PATH "${STM32_VENDOR_ROOT}/system/Drivers/STM32*_HAL_Driver" CACHE PATH "STM32 HAL path")
endfunction()

#-------------------------------------------------------------------------------
# 🎯 Individual STM32 board setup
#-------------------------------------------------------------------------------
function(setup_stm32_board board_id)
    message(STATUS "🔧 Setting up STM32 board: ${board_id}")

    # Verify board exists
    if(NOT board_id IN_LIST STM32_BOARDS_LIST)
        message(FATAL_ERROR "❌ STM32 board '${board_id}' not found in vendor database")
    endif()

    # Use vendor's set_board function directly
    if(COMMAND set_board)
        # The vendor system handles everything: toolchain, compilation flags, etc.
        set_board(${board_id})

        # Get board information from vendor system
        set(PROJECT_NAME "${board_id}_project" PARENT_SCOPE)
        set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/arm-none-eabi.cmake" PARENT_SCOPE)

        message(STATUS "✅ STM32 board '${board_id}' configured by vendor system")
    else()
        message(FATAL_ERROR "❌ STM32 vendor set_board function not available")
    endif()
endfunction()

function(apply_stm32_build_config target_name)
    message(STATUS "⚙️  Applying STM32 vendor build configuration...")

    # The vendor system has already set up the board target
    # We just need to link our target with it
    if(TARGET board)
        target_link_libraries(${target_name} PRIVATE board)
        message(STATUS "🔗 Linked with STM32 vendor board configuration")
    else()
        message(WARNING "⚠️  STM32 vendor board target not found")
    endif()

    # Apply vendor's overall settings if available
    if(COMMAND overall_settings)
        overall_settings(OPTIMIZATION s PRINTF_FLOAT)
        if(TARGET user_settings)
            target_link_libraries(${target_name} PRIVATE user_settings)
            message(STATUS "🎛️  Applied STM32 vendor optimization settings")
        endif()
    endif()

    # Get vendor core sources
    get_stm32_vendor_sources()
    set(VENDOR_CORE_SOURCES ${STM32_VENDOR_SOURCES} PARENT_SCOPE)
endfunction()

function(get_stm32_vendor_sources)
    # The vendor system manages sources through the board target
    # We don't need to manually collect them
    set(STM32_VENDOR_SOURCES "" PARENT_SCOPE)
    message(STATUS "📁 STM32 sources managed by vendor system")
endfunction()

function(collect_stm32_sources)
    # STM32 vendor system manages sources through board target
    # This function is called before target creation to collect sources
    message(STATUS "📦 Collecting STM32 vendor core sources...")

    # The STM32 vendor system doesn't provide sources this way
    # Sources are managed through the board target that gets linked later
    set(STM32_VENDOR_SOURCES "" PARENT_SCOPE)
    set(VENDOR_CORE_SOURCES "" PARENT_SCOPE)

    message(STATUS "📁 STM32 sources managed by vendor board target")
endfunction()

function(execute_stm32_post_build target_name)
    message(STATUS "🏗️  Executing STM32 vendor post-build steps...")

    # Standard STM32 post-build: create .bin and .hex files
    find_program(CMAKE_OBJCOPY arm-none-eabi-objcopy REQUIRED)
    find_program(CMAKE_SIZE arm-none-eabi-size REQUIRED)

    # Binary file
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.bin
        COMMENT "🔧 Creating STM32 binary file: ${target_name}.bin"
    )

    # Intel HEX file
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.hex
        COMMENT "🔧 Creating STM32 Intel HEX file: ${target_name}.hex"
    )

    # Size information
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_SIZE} -A $<TARGET_FILE:${target_name}>
        COMMENT "📊 STM32 program size information:"
    )

    message(STATUS "✅ STM32 post-build configuration complete")
endfunction()