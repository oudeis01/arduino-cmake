# 자동 보드 탐지 및 설정
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/utils/vendor-paths.cmake)

# 지원 가능한 모든 보드 목록 생성
function(discover_available_boards result_var)
    set(available_boards)
    
    # AVR 보드들 (기본적인 것들)
    if(ARDUINO_AVR_AVAILABLE)
        list(APPEND available_boards 
            "uno" "nano" "mega2560" "leonardo" "micro"
        )
    endif()
    
    # STM32 보드들 (일반적인 것들)
    if(ARDUINO_STM32_AVAILABLE)
        list(APPEND available_boards 
            "nucleo_f401re" "nucleo_f446re" "nucleo_f103rb"
        )
    endif()
    
    # Klangstrom 보드들
    if(KLANGSTROM_AVAILABLE)
        list(APPEND available_boards "klst_panda")
    endif()
    
    set(${result_var} ${available_boards} PARENT_SCOPE)
    message(STATUS "Available boards: ${available_boards}")
endfunction()

# 보드별 설정 파일 자동 로드
function(load_board_config board_name)
    # 보드별 cmake 파일 경로 탐색
    set(board_paths
        "cmake/boards/avr/${board_name}.cmake"
        "cmake/boards/stm32/${board_name}.cmake" 
        "cmake/boards/klangstrom/${board_name}.cmake"
        "cmake/boards/generated/${board_name}.cmake"
        "cmake/boards/${board_name}.cmake"  # 하위 호환성
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

# .ino 파일을 .cpp로 변환하는 함수
function(convert_ino_files source_list)
    set(converted_sources)
    
    foreach(source_file ${${source_list}})
        if(source_file MATCHES "\\.ino$")
            get_filename_component(file_dir ${source_file} DIRECTORY)
            get_filename_component(file_name ${source_file} NAME_WE)
            set(cpp_file "${file_dir}/${file_name}.cpp")
            
            # .ino 파일을 .cpp로 복사
            configure_file(${source_file} ${cpp_file} COPYONLY)
            list(APPEND converted_sources ${cpp_file})
            message(STATUS "Converted ${source_file} -> ${cpp_file}")
        else()
            list(APPEND converted_sources ${source_file})
        endif()
    endforeach()
    
    set(${source_list} ${converted_sources} PARENT_SCOPE)
endfunction()