set(ARDUINO_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}/../..")
set(ARDUINO_LIBRARIES_DIR "${ARDUINO_CMAKE_DIR}/libraries")

function(arduino_add_library TARGET_NAME LIBRARY_NAME)
    set(LIBRARY_PATH "${ARDUINO_LIBRARIES_DIR}/${LIBRARY_NAME}")
    
    if(NOT EXISTS "${LIBRARY_PATH}")
        message(FATAL_ERROR "Library not found: ${LIBRARY_NAME} at ${LIBRARY_PATH}")
    endif()
    
    if(EXISTS "${LIBRARY_PATH}/src")
        set(LIBRARY_INCLUDE "${LIBRARY_PATH}/src")
        file(GLOB_RECURSE LIBRARY_SOURCES 
            "${LIBRARY_PATH}/src/*.cpp"
            "${LIBRARY_PATH}/src/*.c"
        )
    else()
        set(LIBRARY_INCLUDE "${LIBRARY_PATH}")
        file(GLOB_RECURSE LIBRARY_SOURCES 
            "${LIBRARY_PATH}/*.cpp"
            "${LIBRARY_PATH}/*.c"
        )
    endif()
    
    # Exclude problematic files for AVR
    if(LIBRARY_NAME STREQUAL "FastLED")
        list(FILTER LIBRARY_SOURCES EXCLUDE REGEX ".*/fl/cstring\\.cpp$")
        list(FILTER LIBRARY_SOURCES EXCLUDE REGEX ".*/fl/math\\.cpp$")
    endif()
    
    if(LIBRARY_SOURCES)
        target_sources(${TARGET_NAME} PRIVATE ${LIBRARY_SOURCES})
        
        target_compile_options(${TARGET_NAME} PRIVATE 
            $<$<COMPILE_LANGUAGE:CXX>:-fpermissive>
            $<$<COMPILE_LANGUAGE:CXX>:-include avr/interrupt.h>
        )
        
        # For FastLED: undefine min/max macros from Arduino.h
        if(LIBRARY_NAME STREQUAL "FastLED")
            target_compile_definitions(${TARGET_NAME} PRIVATE NOMINMAX)
        endif()
        
        list(LENGTH LIBRARY_SOURCES SRC_COUNT)
        message(STATUS "Added library ${LIBRARY_NAME}: ${SRC_COUNT} source files")
    endif()
    
    target_include_directories(${TARGET_NAME} PRIVATE ${LIBRARY_INCLUDE})
    
    file(GLOB_RECURSE LIBRARY_SUBDIRS LIST_DIRECTORIES true "${LIBRARY_INCLUDE}/*")
    foreach(SUBDIR ${LIBRARY_SUBDIRS})
        if(IS_DIRECTORY ${SUBDIR})
            target_include_directories(${TARGET_NAME} PRIVATE ${SUBDIR})
        endif()
    endforeach()
endfunction()
