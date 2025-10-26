# Auto board detection and configuration
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/utils/vendor-paths.cmake)

function(discover_available_boards result_var)
    set(available_boards)
    
    if(ARDUINO_AVR_AVAILABLE)
        list(APPEND available_boards 
            "uno" "nano" "mega2560" "leonardo" "micro"
        )
    endif()
    
    set(${result_var} ${available_boards} PARENT_SCOPE)
    message(STATUS "Available boards: ${available_boards}")
endfunction()

function(load_board_config board_name)
    set(board_paths
        "cmake/boards/avr/${board_name}.cmake"
        "cmake/boards/generated/${board_name}.cmake"
        "cmake/boards/${board_name}.cmake"
    )
    
    foreach(board_path ${board_paths})
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${board_path}")
            message(STATUS "Loading board config: ${board_path}")
            include("${CMAKE_CURRENT_SOURCE_DIR}/${board_path}")
            return()
        endif()
    endforeach()
    
    message(FATAL_ERROR "Board configuration not found for: ${board_name}")
endfunction()

function(convert_ino_files source_list)
    set(converted_sources)
    
    foreach(source_file ${${source_list}})
        if(source_file MATCHES "\\.ino$")
            get_filename_component(file_dir ${source_file} DIRECTORY)
            get_filename_component(file_name ${source_file} NAME_WE)
            set(cpp_file "${file_dir}/${file_name}.cpp")
            
            configure_file(${source_file} ${cpp_file} COPYONLY)
            list(APPEND converted_sources ${cpp_file})
            message(STATUS "Converted ${source_file} -> ${cpp_file}")
        else()
            list(APPEND converted_sources ${source_file})
        endif()
    endforeach()
    
    set(${source_list} ${converted_sources} PARENT_SCOPE)
endfunction()