cmake_minimum_required(VERSION 3.20)

# 조기 보드 설정을 위한 임시 변수
set(TARGET_BOARD "uno" CACHE STRING "Target board")

# 보드별 툴체인 설정 로드 (프로젝트 선언 전에 필요)
if(TARGET_BOARD STREQUAL "uno" OR TARGET_BOARD STREQUAL "nano" OR TARGET_BOARD STREQUAL "mega2560" OR TARGET_BOARD STREQUAL "leonardo" OR TARGET_BOARD STREQUAL "micro")
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/avr-gcc.cmake")
elseif(TARGET_BOARD STREQUAL "klst_panda" OR TARGET_BOARD MATCHES "nucleo_.*")
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/arm-none-eabi.cmake")
endif()

# 유틸리티 로드
include(cmake/utils/vendor-paths.cmake)
include(cmake/utils/board-finder.cmake)

# 사용 가능한 보드 탐지
discover_available_boards(AVAILABLE_BOARDS)

# 보드 선택 검증
set_property(CACHE TARGET_BOARD PROPERTY STRINGS ${AVAILABLE_BOARDS})

# 소스 디렉토리 옵션
set(SOURCE_DIR "src" CACHE STRING "Source directory")

# 보드 유효성 검사
if(NOT TARGET_BOARD IN_LIST AVAILABLE_BOARDS)
    message(FATAL_ERROR "Unsupported board: ${TARGET_BOARD}. Available boards: ${AVAILABLE_BOARDS}")
endif()

message(STATUS "Building for target board: ${TARGET_BOARD}")
message(STATUS "Available boards: ${AVAILABLE_BOARDS}")

# 보드 설정 자동 로드
load_board_config(${TARGET_BOARD})

# 프로젝트 선언 (보드 설정에서 PROJECT_NAME이 정의됨)
project(${PROJECT_NAME} C CXX ASM)

# 공통 컴파일 옵션
set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 17)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# 소스 파일 수집 (.ino 파일 포함)
file(GLOB_RECURSE USER_SOURCES
    "${SOURCE_DIR}/*.c"
    "${SOURCE_DIR}/*.cpp"
    "${SOURCE_DIR}/*.ino"
    "${SOURCE_DIR}/*.S"
)

# .ino 파일을 .cpp로 변환
convert_ino_files(USER_SOURCES)

# 실행 파일 생성
add_executable(${PROJECT_NAME}
    ${USER_SOURCES}
    ${BOARD_CORE_SOURCES}
)

# 보드별 설정 적용
target_compile_definitions(${PROJECT_NAME} PRIVATE ${BOARD_COMPILE_DEFINITIONS})
target_include_directories(${PROJECT_NAME} PRIVATE ${BOARD_INCLUDE_DIRECTORIES})
target_compile_options(${PROJECT_NAME} PRIVATE ${BOARD_COMPILE_OPTIONS})
target_link_options(${PROJECT_NAME} PRIVATE ${BOARD_LINK_OPTIONS})

if(BOARD_LIBRARIES)
    target_link_libraries(${PROJECT_NAME} ${BOARD_LIBRARIES})
endif()

# 보드별 후처리
if(COMMAND board_post_build)
    board_post_build(${PROJECT_NAME})
endif()

# 빌드 정보 출력
message(STATUS "Project: ${PROJECT_NAME}")
message(STATUS "Board: ${TARGET_BOARD}")  
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Source files: ${USER_SOURCES}")
if(CMAKE_TOOLCHAIN_FILE)
    message(STATUS "Toolchain: ${CMAKE_TOOLCHAIN_FILE}")
endif()