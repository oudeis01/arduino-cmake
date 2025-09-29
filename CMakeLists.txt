cmake_minimum_required(VERSION 3.21)

#===============================================================================
# 🚀 VENDOR-CENTRIC ARDUINO CMAKE SYSTEM
#
# This system leverages vendor-provided CMake systems:
# - Arduino_Core_STM32: 500+ STM32 boards (117K lines boards_db.cmake)
# - ArduinoCore-avr: 100+ Arduino boards (boards.txt parsing)
# - klangstrom-arduino: Custom boards with vendor integration
#
# Key Features:
# - Zero external dependencies (no ~/.arduino15 references)
# - Full vendor system integration
# - Automatic board discovery and registration
# - Professional-grade build configurations
#===============================================================================

# Early board selection for toolchain setup
set(TARGET_BOARD "uno" CACHE STRING "Target board (auto-detected from vendor systems)")
set(SOURCE_DIR "src" CACHE STRING "Source directory")

# Core vendor integration system
include(cmake/core/vendor_dispatcher.cmake)

# Initialize vendor systems and detect all available boards
initialize_vendor_systems()
detect_all_boards(ALL_AVAILABLE_BOARDS)

# Set up available boards for CMake GUI/ccmake
set_property(CACHE TARGET_BOARD PROPERTY STRINGS ${ALL_AVAILABLE_BOARDS})

# Validate board selection
if(NOT TARGET_BOARD IN_LIST ALL_AVAILABLE_BOARDS)
    message(FATAL_ERROR
        "❌ Board '${TARGET_BOARD}' not supported.\n"
        "📋 Available boards: ${ALL_AVAILABLE_BOARDS}\n"
        "💡 Tip: Use 'cmake -DTARGET_BOARD=<board>' to specify a board"
    )
endif()

# Board-specific setup (including toolchain configuration)
setup_board_environment(${TARGET_BOARD})

# Ensure PROJECT_NAME is set properly
if(NOT DEFINED PROJECT_NAME OR PROJECT_NAME STREQUAL "")
    set(PROJECT_NAME "${TARGET_BOARD}_project")
    message(STATUS "🔧 Fallback PROJECT_NAME: ${PROJECT_NAME}")
endif()

# Project declaration with vendor-determined name
project(${PROJECT_NAME} C CXX ASM)

# Display build information
message(STATUS "🎯 Target Board: ${TARGET_BOARD}")
message(STATUS "📦 Project: ${PROJECT_NAME}")
message(STATUS "🔧 Vendor System: ${BOARD_VENDOR_SYSTEM}")
message(STATUS "⚙️  Build Type: ${CMAKE_BUILD_TYPE}")
if(CMAKE_TOOLCHAIN_FILE)
    message(STATUS "🛠️  Toolchain: ${CMAKE_TOOLCHAIN_FILE}")
endif()

# Common build settings
set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# User source collection with .ino support
file(GLOB_RECURSE USER_SOURCES
    "${SOURCE_DIR}/*.c"
    "${SOURCE_DIR}/*.cpp"
    "${SOURCE_DIR}/*.ino"
    "${SOURCE_DIR}/*.S"
)

# Convert .ino files to .cpp (Arduino compatibility)
process_ino_files(USER_SOURCES)

# Collect vendor sources before creating executable
collect_vendor_sources()

# Create executable with vendor-integrated sources
add_executable(${PROJECT_NAME}
    ${USER_SOURCES}
    ${VENDOR_CORE_SOURCES}
)

# Apply vendor-integrated build configuration
apply_vendor_build_config(${PROJECT_NAME})

# Vendor-specific post-build processing
execute_vendor_post_build(${PROJECT_NAME})

# Build summary
list(LENGTH USER_SOURCES SOURCE_COUNT)
list(LENGTH VENDOR_CORE_SOURCES VENDOR_SOURCE_COUNT)
math(EXPR TOTAL_SOURCES "${SOURCE_COUNT} + ${VENDOR_SOURCE_COUNT}")
message(STATUS "📄 Sources: ${SOURCE_COUNT} user + ${VENDOR_SOURCE_COUNT} vendor = ${TOTAL_SOURCES} total")
message(STATUS "✅ Configuration complete!")