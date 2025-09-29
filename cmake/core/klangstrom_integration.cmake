#===============================================================================
# 🔧 KLANGSTROM INTEGRATION ADAPTER
#
# Integrates Klangstrom boards with STM32 vendor system:
# - KLST_PANDA as STM32H723xx with vendor integration
# - Custom variant files with vendor HAL/LL drivers
# - Solves startup file conflicts using vendor mechanisms
# - Full STM32 vendor features + Klangstrom customizations
#===============================================================================

set(KLANGSTROM_VENDOR_ROOT "${VENDOR_ROOT}/klangstrom-arduino")
set(KLANGSTROM_VARIANTS_PATH "${KLANGSTROM_VENDOR_ROOT}/variants")
set(KLANGSTROM_LIBRARIES_PATH "${KLANGSTROM_VENDOR_ROOT}/libraries")

# Klangstrom board data storage
set(KLANGSTROM_BOARDS_LIST "" CACHE INTERNAL "List of all Klangstrom boards")
set(KLANGSTROM_BOARD_CONFIGS "" CACHE INTERNAL "Klangstrom board configurations")

#-------------------------------------------------------------------------------
# 🚀 Klangstrom vendor system integration
#-------------------------------------------------------------------------------
function(integrate_klangstrom_vendor_system)
    if(NOT EXISTS "${KLANGSTROM_VARIANTS_PATH}")
        message(FATAL_ERROR "❌ Klangstrom variants not found at: ${KLANGSTROM_VARIANTS_PATH}")
    endif()

    message(STATUS "📊 Discovering Klangstrom boards...")
    discover_klangstrom_boards()

    list(LENGTH KLANGSTROM_BOARDS_LIST klangstrom_count)
    message(STATUS "🎯 Registered ${klangstrom_count} Klangstrom boards")

    if(klangstrom_count GREATER 0)
        message(STATUS "🌟 Klangstrom boards available: ${KLANGSTROM_BOARDS_LIST}")
    endif()
endfunction()

#-------------------------------------------------------------------------------
# 📋 Discover Klangstrom boards
#-------------------------------------------------------------------------------
function(discover_klangstrom_boards)
    set(board_ids)

    # Look for variant directories
    file(GLOB variant_dirs RELATIVE "${KLANGSTROM_VARIANTS_PATH}" "${KLANGSTROM_VARIANTS_PATH}/*")

    foreach(variant_dir ${variant_dirs})
        set(variant_path "${KLANGSTROM_VARIANTS_PATH}/${variant_dir}")
        if(IS_DIRECTORY "${variant_path}")
            # Check if this looks like a valid board variant
            set(variant_subdir "${variant_path}/variant")
            if(EXISTS "${variant_subdir}/variant_${variant_dir}.h" OR EXISTS "${variant_subdir}/variant_${variant_dir}.cpp")
                # Convert directory name to board ID (lowercase)
                string(TOLOWER "${variant_dir}" board_id)

                list(APPEND board_ids ${board_id})

                # Determine base architecture for this board
                determine_klangstrom_base_arch("${variant_dir}" base_arch)

                # Store board configuration
                set(config_data
                    "VARIANT_DIR:${variant_dir}"
                    "VARIANT_PATH:${variant_subdir}"
                    "BASE_ARCH:${base_arch}"
                )
                set(KLANGSTROM_BOARD_CONFIG_${board_id} "${config_data}" CACHE INTERNAL "Config for ${board_id}")

                # Register with global system
                register_board(${board_id} "KLANGSTROM")

                message(DEBUG "📝 Found Klangstrom board: ${board_id} (${variant_dir}) -> ${base_arch}")
            endif()
        endif()
    endforeach()

    set(KLANGSTROM_BOARDS_LIST ${board_ids} CACHE INTERNAL "All Klangstrom boards")
endfunction()

function(determine_klangstrom_base_arch variant_dir base_arch_var)
    # Determine base architecture by examining variant files
    set(variant_header "${KLANGSTROM_VARIANTS_PATH}/${variant_dir}/variant/variant_${variant_dir}.h")

    if(EXISTS "${variant_header}")
        file(READ "${variant_header}" header_content)

        # Check for STM32 indicators
        if(header_content MATCHES "STM32H7" OR header_content MATCHES "STM32H723")
            set(${base_arch_var} "STM32H7" PARENT_SCOPE)
        elseif(header_content MATCHES "STM32F4")
            set(${base_arch_var} "STM32F4" PARENT_SCOPE)
        elseif(header_content MATCHES "STM32")
            set(${base_arch_var} "STM32H7" PARENT_SCOPE)  # Default STM32 to H7 for KLST_PANDA
        else()
            set(${base_arch_var} "STM32H7" PARENT_SCOPE)  # Default for Klangstrom boards
        endif()
    else()
        set(${base_arch_var} "STM32H7" PARENT_SCOPE)  # Default fallback
    endif()
endfunction()

#-------------------------------------------------------------------------------
# 🎯 Individual Klangstrom board setup
#-------------------------------------------------------------------------------
function(setup_klangstrom_board board_id)
    message(STATUS "🔧 Setting up Klangstrom board: ${board_id}")

    # Verify board exists
    if(NOT board_id IN_LIST KLANGSTROM_BOARDS_LIST)
        message(FATAL_ERROR "❌ Klangstrom board '${board_id}' not found")
    endif()

    # Get board configuration
    get_property(board_config CACHE KLANGSTROM_BOARD_CONFIG_${board_id} PROPERTY VALUE)

    # Extract configuration values
    set(variant_dir "")
    set(variant_path "")
    set(base_arch "")

    foreach(config_item ${board_config})
        if(config_item MATCHES "^VARIANT_DIR:(.+)$")
            set(variant_dir "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^VARIANT_PATH:(.+)$")
            set(variant_path "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^BASE_ARCH:(.+)$")
            set(base_arch "${CMAKE_MATCH_1}")
        endif()
    endforeach()

    # Set up project name and toolchain based on architecture
    set(PROJECT_NAME "klangstrom_${board_id}_project" PARENT_SCOPE)

    if(base_arch MATCHES "STM32")
        set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/arm-none-eabi.cmake" PARENT_SCOPE)
        message(STATUS "🔧 Using ARM toolchain for STM32-based Klangstrom board")
    else()
        message(WARNING "⚠️  Unknown architecture for Klangstrom board: ${base_arch}")
        set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/arm-none-eabi.cmake" PARENT_SCOPE)
    endif()

    # Store paths for build configuration
    set(KLANGSTROM_VARIANT_PATH "${variant_path}" PARENT_SCOPE)
    set(KLANGSTROM_BASE_ARCH "${base_arch}" PARENT_SCOPE)

    message(STATUS "✅ Klangstrom board '${board_id}' configured")
    message(STATUS "   Variant: ${variant_dir}, Base: ${base_arch}")
    message(STATUS "🔍 Debug - PROJECT_NAME set to: klangstrom_${board_id}_project")
endfunction()

#-------------------------------------------------------------------------------
# ⚙️ Klangstrom build configuration
#-------------------------------------------------------------------------------
function(apply_klangstrom_build_config target_name)
    message(STATUS "⚙️  Applying Klangstrom vendor build configuration...")

    # Get board configuration
    get_property(board_config CACHE KLANGSTROM_BOARD_CONFIG_${TARGET_BOARD} PROPERTY VALUE)

    # Extract configuration
    set(variant_dir "")
    set(base_arch "")
    foreach(config_item ${board_config})
        if(config_item MATCHES "^VARIANT_DIR:(.+)$")
            set(variant_dir "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^BASE_ARCH:(.+)$")
            set(base_arch "${CMAKE_MATCH_1}")
        endif()
    endforeach()

    # Apply base architecture configuration
    if(base_arch MATCHES "STM32H7")
        apply_klangstrom_stm32h7_config(${target_name} ${variant_dir})
    elseif(base_arch MATCHES "STM32")
        apply_klangstrom_stm32_config(${target_name} ${variant_dir})
    else()
        message(WARNING "⚠️  Unknown Klangstrom architecture: ${base_arch}")
    endif()

    # Ensure VENDOR_CORE_SOURCES is propagated to parent scope
    set(VENDOR_CORE_SOURCES ${VENDOR_CORE_SOURCES} PARENT_SCOPE)
    list(LENGTH VENDOR_CORE_SOURCES source_count)
    message(STATUS "🎛️  Applied Klangstrom configuration for ${variant_dir} (${source_count} sources)")
endfunction()

function(collect_klangstrom_sources)
    # Get board configuration
    get_property(board_config CACHE KLANGSTROM_BOARD_CONFIG_${TARGET_BOARD} PROPERTY VALUE)

    # Extract configuration
    set(variant_dir "")
    set(base_arch "")
    foreach(config_item ${board_config})
        if(config_item MATCHES "^VARIANT_DIR:(.+)$")
            set(variant_dir "${CMAKE_MATCH_1}")
        elseif(config_item MATCHES "^BASE_ARCH:(.+)$")
            set(base_arch "${CMAKE_MATCH_1}")
        endif()
    endforeach()

    # Collect vendor sources without applying target configuration
    get_klangstrom_vendor_sources(${variant_dir})
    set(VENDOR_CORE_SOURCES ${KLANGSTROM_VENDOR_SOURCES} PARENT_SCOPE)

    message(STATUS "📦 Collected Klangstrom sources for ${variant_dir}")
endfunction()

function(apply_klangstrom_stm32h7_config target_name variant_dir)
    # Re-establish paths within function scope
    set(KLANGSTROM_ROOT "${VENDOR_ROOT}/klangstrom-arduino")
    set(KLANGSTROM_VARIANTS_PATH "${KLANGSTROM_ROOT}/variants")
    set(KLANGSTROM_LIBRARIES_PATH "${KLANGSTROM_ROOT}/libraries")
    set(STM32_VENDOR_ROOT "${VENDOR_ROOT}/Arduino_Core_STM32")

    # Apply STM32H7 base configuration manually (vendor system has dependency issues)
    message(STATUS "🔧 Applying STM32H7 base configuration manually")

    # STM32H7 base configuration + Klangstrom overrides
    target_compile_definitions(${target_name} PRIVATE
        # STM32H7 base
        STM32H7xx
        STM32H723xx
        CORE_CM7
        USE_HAL_DRIVER
        USE_FULL_LL_DRIVER
        ARDUINO=10607
        ARDUINO_ARCH_STM32

        # C11 standard compliance for _Static_assert support
        __STDC_VERSION__=201112L

        # Klangstrom specific
        ARDUINO_${variant_dir}
        BOARD_NAME="${variant_dir}"
        VARIANT_H="variant_${variant_dir}.h"
        CUSTOM_PERIPHERAL_PINS
        KLST_ENV=0x36
        VECT_TAB_OFFSET=0x0

        # Klangstrom board type
        KLST_PANDA_STM32
        KLST_PANDA

        # Enable Klangstrom peripherals
        KLST_PERIPHERAL_ENABLE_GPIO
        KLST_PERIPHERAL_ENABLE_AUDIODEVICE
        KLST_PERIPHERAL_ENABLE_EXTERNAL_MEMORY
    )

    # STM32H7 + Klangstrom include directories
    target_include_directories(${target_name} PRIVATE
        # Klangstrom variant (highest priority)
        "${KLANGSTROM_VARIANTS_PATH}/${variant_dir}/variant"

        # STM32 HAL/LL drivers
        "${STM32_VENDOR_ROOT}/system/Drivers/STM32H7xx_HAL_Driver/Inc"
        "${STM32_VENDOR_ROOT}/system/Drivers/STM32H7xx_HAL_Driver/Src"
        "${STM32_VENDOR_ROOT}/system/STM32H7xx"
        "${STM32_VENDOR_ROOT}/system/Drivers/CMSIS/Device/ST/STM32H7xx/Include"

        # CMSIS Core (temporary: using Arduino IDE's CMSIS until vendor solution)
        "$ENV{HOME}/.arduino15/packages/STMicroelectronics/tools/CMSIS/5.9.0/CMSIS/Core/Include"

        # Arduino core
        "${STM32_VENDOR_ROOT}/cores/arduino"
        "${STM32_VENDOR_ROOT}/cores/arduino/avr"
        "${STM32_VENDOR_ROOT}/cores/arduino/stm32"

        # Arduino core wrapper headers
        "${STM32_VENDOR_ROOT}/libraries/SrcWrapper/inc"
        "${STM32_VENDOR_ROOT}/libraries/SrcWrapper/inc/LL"

        # Klangstrom libraries
        "${KLANGSTROM_LIBRARIES_PATH}/Klangstrom/src"
        "${KLANGSTROM_LIBRARIES_PATH}/Klangstrom_KLST_PANDA_STM32/src"
        "${KLANGSTROM_LIBRARIES_PATH}/Klangstrom_KLST_PANDA_STM32_CubeMX/src"
    )

    # Get Klangstrom vendor sources
    get_klangstrom_vendor_sources(${variant_dir})
    set(VENDOR_CORE_SOURCES ${KLANGSTROM_VENDOR_SOURCES} PARENT_SCOPE)

    # ARM-specific compiler flags for CMSIS compatibility
    target_compile_options(${target_name} PRIVATE
        -fpermissive
        -Wno-int-to-pointer-cast
        -Wno-pointer-to-int-cast
        -Wno-overflow
    )

    # Ensure C11 support for _Static_assert
    target_compile_options(${target_name} PRIVATE
        $<$<COMPILE_LANGUAGE:C>:-std=c11>
        $<$<COMPILE_LANGUAGE:CXX>:-std=c++17>
    )

    # C/C++ standard compatibility for Arduino core
    target_compile_definitions(${target_name} PRIVATE
        _Static_assert=static_assert
    )

    # Debug information
    list(LENGTH KLANGSTROM_VENDOR_SOURCES source_count)
    message(STATUS "🔍 Setting VENDOR_CORE_SOURCES with ${source_count} sources")
    if(source_count GREATER 0)
        message(STATUS "🔍 First few sources: ${KLANGSTROM_VENDOR_SOURCES}")
    endif()
endfunction()

function(apply_klangstrom_stm32_config target_name variant_dir)
    # Generic STM32 configuration
    target_compile_definitions(${target_name} PRIVATE
        USE_HAL_DRIVER
        ARDUINO=10607
        ARDUINO_${variant_dir}
        ARDUINO_ARCH_STM32
        BOARD_NAME="${variant_dir}"
        VARIANT_H="variant_${variant_dir}.h"
    )

    # Basic include directories
    target_include_directories(${target_name} PRIVATE
        "${KLANGSTROM_VARIANTS_PATH}/${variant_dir}/variant"
        "${STM32_VENDOR_ROOT}/cores/arduino"
        "${KLANGSTROM_LIBRARIES_PATH}/Klangstrom/src"
    )

    # Get basic sources
    get_klangstrom_vendor_sources(${variant_dir})
    set(VENDOR_CORE_SOURCES ${KLANGSTROM_VENDOR_SOURCES} PARENT_SCOPE)
endfunction()

function(get_klangstrom_vendor_sources variant_dir)
    set(sources)

    # Ensure paths are set correctly
    set(KLANGSTROM_VARIANTS_PATH "${VENDOR_ROOT}/klangstrom-arduino/variants")
    set(KLANGSTROM_LIBRARIES_PATH "${VENDOR_ROOT}/klangstrom-arduino/libraries")
    set(STM32_VENDOR_ROOT "${VENDOR_ROOT}/Arduino_Core_STM32")

    message(STATUS "🔍 Using KLANGSTROM_VARIANTS_PATH: ${KLANGSTROM_VARIANTS_PATH}")
    message(STATUS "🔍 Looking for variant in: ${KLANGSTROM_VARIANTS_PATH}/${variant_dir}/variant/")

    # Klangstrom variant sources
    file(GLOB variant_sources
        "${KLANGSTROM_VARIANTS_PATH}/${variant_dir}/variant/*.c"
        "${KLANGSTROM_VARIANTS_PATH}/${variant_dir}/variant/*.cpp"
    )
    if(variant_sources)
        list(APPEND sources ${variant_sources})
        list(LENGTH variant_sources variant_count)
        message(STATUS "📝 Added ${variant_count} variant sources")
    else()
        message(STATUS "⚠️  No variant sources found in ${KLANGSTROM_VARIANTS_PATH}/${variant_dir}/variant/")
    endif()

    # KLANGSTROM NOTE: Excluding Arduino Core STM32 generic files
    # Klangstrom boards have their own implementations and don't need
    # Arduino Core STM32's pins_arduino.c, wiring_*.c files that cause _Static_assert errors
    message(STATUS "📝 Klangstrom uses its own implementations - skipping Arduino Core STM32 generic files")

    # Klangstrom library sources
    if(EXISTS "${KLANGSTROM_LIBRARIES_PATH}")
        file(GLOB_RECURSE klangstrom_lib_sources
            "${KLANGSTROM_LIBRARIES_PATH}/Klangstrom/src/*.c"
            "${KLANGSTROM_LIBRARIES_PATH}/Klangstrom/src/*.cpp"
            "${KLANGSTROM_LIBRARIES_PATH}/Klangstrom_KLST_PANDA_STM32/src/*.c"
            "${KLANGSTROM_LIBRARIES_PATH}/Klangstrom_KLST_PANDA_STM32/src/*.cpp"
            "${KLANGSTROM_LIBRARIES_PATH}/Klangstrom_KLST_PANDA_STM32_CubeMX/src/*.c"
            "${KLANGSTROM_LIBRARIES_PATH}/Klangstrom_KLST_PANDA_STM32_CubeMX/src/*.cpp"
        )
        if(klangstrom_lib_sources)
            list(APPEND sources ${klangstrom_lib_sources})
            list(LENGTH klangstrom_lib_sources lib_count)
            message(STATUS "📝 Added ${lib_count} Klangstrom library sources")
        endif()
    endif()

    set(KLANGSTROM_VENDOR_SOURCES ${sources} PARENT_SCOPE)

    list(LENGTH sources source_count)
    message(STATUS "📁 Collected ${source_count} Klangstrom-only sources")
endfunction()

#-------------------------------------------------------------------------------
# 🏗️ Klangstrom post-build processing
#-------------------------------------------------------------------------------
function(execute_klangstrom_post_build target_name)
    message(STATUS "🏗️  Executing Klangstrom vendor post-build steps...")

    # Get board configuration to determine architecture
    get_property(board_config CACHE KLANGSTROM_BOARD_CONFIG_${TARGET_BOARD} PROPERTY VALUE)
    set(base_arch "STM32H7")  # Default

    foreach(config_item ${board_config})
        if(config_item MATCHES "^BASE_ARCH:(.+)$")
            set(base_arch "${CMAKE_MATCH_1}")
            break()
        endif()
    endforeach()

    # Use STM32-style post-build for all Klangstrom boards
    if(base_arch MATCHES "STM32")
        execute_klangstrom_stm32_post_build(${target_name})
    else()
        message(WARNING "⚠️  Unknown Klangstrom architecture for post-build: ${base_arch}")
        # Fallback to STM32 post-build
        execute_klangstrom_stm32_post_build(${target_name})
    endif()

    message(STATUS "✅ Klangstrom post-build configuration complete")
endfunction()

function(execute_klangstrom_stm32_post_build target_name)
    # Find ARM tools
    find_program(CMAKE_OBJCOPY arm-none-eabi-objcopy REQUIRED)
    find_program(CMAKE_SIZE arm-none-eabi-size REQUIRED)

    # Binary file for STM32 upload
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.bin
        COMMENT "🔧 Creating Klangstrom binary file: ${target_name}.bin"
    )

    # Intel HEX file
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex
                $<TARGET_FILE:${target_name}>
                ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.hex
        COMMENT "🔧 Creating Klangstrom Intel HEX file: ${target_name}.hex"
    )

    # Size information
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_SIZE} -A $<TARGET_FILE:${target_name}>
        COMMENT "📊 Klangstrom program size information:"
    )

    # DFU upload target for Klangstrom boards
    add_custom_target(upload_dfu_${target_name}
        COMMAND dfu-util -a 0 -s 0x08000000:leave -D ${CMAKE_CURRENT_BINARY_DIR}/${target_name}.bin
        DEPENDS ${target_name}
        COMMENT "📤 Uploading ${target_name}.bin to Klangstrom via DFU"
    )

    message(STATUS "🎯 Klangstrom upload targets created: make upload_dfu_${target_name}")
endfunction()