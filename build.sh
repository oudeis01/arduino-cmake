#!/bin/bash

# Arduino CMake Build Script

set -e

# 기본값 설정
BOARD="uno"
BUILD_TYPE="Release"
SOURCE_DIR="src"
BUILD_DIR="build"
CLEAN_BUILD=false

# 도움말 함수
show_help() {
    echo "Arduino CMake Build Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b, --board BOARD       Target board (uno | nano | mega2560 | leonardo | micro | klst_panda | etc.) [default: uno]"
    echo "  -l, --list-boards       List all available boards"
    echo "  -t, --type TYPE         Build type (Debug | Release) [default: Release]"
    echo "  -s, --source DIR        Source directory [default: src]"
    echo "  -o, --output DIR        Build output directory [default: build]"
    echo "  -c, --clean             Clean build (remove build directory)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -b uno -t Debug"
    echo "  $0 -b klst_panda -s src -o build_draw -c"
    echo "  $0 --board nano --source src --output build --clean"
    echo "  $0 --list-boards"
}

# 명령행 인수 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--board)
            BOARD="$2"
            shift 2
            ;;
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -s|--source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -o|--output)
            BUILD_DIR="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -l|--list-boards)
            echo "Discovering available boards..."
            cmake -B .temp_discovery -DTARGET_BOARD=uno . 2>/dev/null | grep "Available boards:" || echo "No boards found"
            rm -rf .temp_discovery
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

echo "====================================="
echo "Arduino CMake Build"
echo "====================================="
echo "Board: $BOARD"
echo "Build Type: $BUILD_TYPE"
echo "Source Directory: $SOURCE_DIR"
echo "Build Directory: $BUILD_DIR"
echo "Clean Build: $CLEAN_BUILD"
echo "====================================="

# 클린 빌드인 경우 빌드 디렉토리 삭제
if [ "$CLEAN_BUILD" = true ]; then
    echo "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

# 빌드 디렉토리 생성
mkdir -p "$BUILD_DIR"

# CMake 설정
echo "Configuring CMake..."
cmake -B "$BUILD_DIR" \
    -DTARGET_BOARD="$BOARD" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DSOURCE_DIR="$SOURCE_DIR" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# 빌드 실행
echo "Building project..."
cmake --build "$BUILD_DIR" --parallel

# 빌드 결과 정보
echo ""
echo "====================================="
echo "Build completed successfully!"
echo "====================================="

# 생성된 파일 목록
echo "Generated files:"
if [[ "$BOARD" == "uno" || "$BOARD" == "nano" || "$BOARD" == "mega2560" || "$BOARD" == "leonardo" || "$BOARD" == "micro" ]]; then
    # Arduino AVR 보드들
    PROJECT_NAME="${BOARD}_project"
    (cd "$BUILD_DIR" && ls -la "${PROJECT_NAME}.elf" "${PROJECT_NAME}.hex" "${PROJECT_NAME}.eep" 2>/dev/null) || true
elif [[ "$BOARD" == "klst_panda" || "$BOARD" == nucleo_* || "$BOARD" == "stm32"* ]]; then
    # STM32 보드들
    PROJECT_NAME="${BOARD}_project"
    (cd "$BUILD_DIR" && ls -la "${PROJECT_NAME}.elf" "${PROJECT_NAME}.bin" "${PROJECT_NAME}.hex" 2>/dev/null) || true
else
    # 기타 보드들
    PROJECT_NAME="${BOARD}_project"
    (cd "$BUILD_DIR" && find . -name "${PROJECT_NAME}.*" -exec ls -la {} \; 2>/dev/null) || true
fi

echo ""
echo "To upload firmware, use: ./upload.sh -b $BOARD -d <device> -f <firmware_file>"
echo ""
echo "====================================="
echo "Build script completed!"
echo "====================================="