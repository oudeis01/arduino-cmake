# Arduino CMake Build System

전문가급 Arduino 개발을 위한 현대적인 CMake 기반 빌드 시스템입니다. STM32, AVR, Klangstrom 등 다양한 벤더 시스템을 지원하며, Arduino IDE 없이도 완전한 개발 환경을 제공합니다.

## 🚀 특징

- **다중 벤더 지원**: STM32 (1697+ 보드), AVR (27+ 보드), Klangstrom (2+ 보드)
- **제로 의존성**: 외부 Arduino IDE 설치 불필요
- **전문가급 빌드**: CMake 3.21+ 기반 현대적 빌드 시스템
- **자동 보드 감지**: 벤더별 boards.txt 자동 파싱
- **크로스 플랫폼**: Linux, macOS, Windows 지원

## 📋 시스템 요구사항

### 1. 핵심 의존성 (모든 보드 필수)

```bash
# Arch Linux
sudo pacman -S --needed cmake base-devel

# Ubuntu/Debian
sudo apt-get install cmake build-essential

# macOS (Homebrew)
brew install cmake
```

### 2. 툴체인 및 업로더 의존성

#### AVR 기반 보드 (Arduino Uno, Nano 등)

```bash
# Arch Linux
sudo pacman -S --needed avr-gcc avr-binutils avr-libc avrdude

# Ubuntu/Debian
sudo apt-get install gcc-avr avr-libc avrdude

# macOS
brew install avr-gcc avrdude
```

#### ARM 기반 보드 (STM32 시리즈)

```bash
# Arch Linux
sudo pacman -S --needed arm-none-eabi-gcc arm-none-eabi-binutils arm-none-eabi-newlib stlink dfu-util

# Ubuntu/Debian
sudo apt-get install gcc-arm-none-eabi libnewlib-arm-none-eabi stlink-tools dfu-util

# macOS
brew install arm-none-eabi-gcc stlink dfu-util
```

## 🔧 빠른 시작 (Arduino Uno)

### 1. 저장소 클론 및 초기 설정

```bash
cd /home/choiharam/works/projects/arduino_ws2812b/arduino-cmake
```

### 2. 권한 설정 (Linux)

Arduino 장치에 접근하려면 dialout 그룹에 추가해야 합니다:

```bash
# 영구적 권한 설정 (재로그인 필요)
sudo usermod -a -G dialout $USER

# 임시 권한 설정 (재부팅 시 초기화)
sudo chmod 666 /dev/ttyACM0
```

### 3. 빌드 및 업로드

```bash
# 클린 빌드
./build.sh -b uno -s src-arduino -c

# 업로드
./upload.sh -b arduino_uno -d /dev/ttyACM0 -f build/uno_project.hex
```

## 📖 상세 사용법

### 빌드 스크립트 (build.sh)

#### 기본 사용법

```bash
./build.sh [OPTIONS]
```

#### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `-b, --board BOARD` | 타겟 보드 | uno |
| `-t, --type TYPE` | 빌드 타입 (Debug/Release) | Release |
| `-s, --source DIR` | 소스 디렉토리 | src |
| `-o, --output DIR` | 빌드 출력 디렉토리 | build |
| `-c, --clean` | 클린 빌드 (빌드 디렉토리 삭제) | false |
| `-l, --list-boards` | 사용 가능한 보드 목록 표시 | - |
| `-h, --help` | 도움말 표시 | - |

#### 지원 보드

**AVR 보드:**
- `uno` - Arduino UNO
- `nano` - Arduino Nano  
- `mega2560` - Arduino Mega 2560
- `leonardo` - Arduino Leonardo
- `micro` - Arduino Micro

**STM32 보드:**
- `NUCLEO_F401RE`, `NUCLEO_F446RE`, `NUCLEO_H743ZI2`
- `DISCO_F407VG` 등 1697+ 보드

**Klangstrom 보드:**
- `klst_caterpillar`
- `klst_panda`

#### 사용 예제

```bash
# Arduino Uno 클린 빌드
./build.sh -b uno -s src-arduino -c

# Arduino Nano 디버그 빌드
./build.sh -b nano -t Debug -s src-nano

# STM32 Nucleo 빌드
./build.sh -b NUCLEO_F401RE -s src-stm32

# 사용 가능한 보드 목록
./build.sh --list-boards
```

### 업로드 스크립트 (upload.sh)

#### 기본 사용법

```bash
./upload.sh -b BOARD -d DEVICE -f FIRMWARE
```

#### 옵션

| 옵션 | 설명 |
|------|------|
| `-b, --board BOARD` | 타겟 보드 (arduino_uno, klst_panda) |
| `-d, --device DEVICE` | 장치 경로 또는 업로드 방법 |
| `-f, --firmware FILE` | 펌웨어 파일 |

#### 업로드 방법

**Arduino UNO:**
```bash
./upload.sh -b arduino_uno -d /dev/ttyACM0 -f build/uno_project.hex
./upload.sh -b arduino_uno -d /dev/ttyUSB0 -f build/uno_project.hex
```

**STM32 (DFU 모드):**
```bash
# 1. 보드를 DFU 모드로 전환 (BOOT 버튼 누른 상태에서 RESET)
# 2. DFU 업로드
./upload.sh -b klst_panda -d dfu -f build/klst_panda_project.bin
```

**STM32 (ST-Link):**
```bash
./upload.sh -b klst_panda -d openocd -f build/klst_panda_project.elf
```

## 🏗️ 프로젝트 구조

```
arduino-cmake/
├── CMakeLists.txt          # 메인 CMake 설정
├── build.sh               # 빌드 스크립트
├── upload.sh              # 업로드 스크립트
├── src/                   # 기본 소스 디렉토리
├── src-arduino/          # Arduino 예제 소스
│   └── main.cpp          # LED 깜빡이기 예제
├── vendor/               # 벤더 코어 라이브러리
│   ├── ArduinoCore-avr/  # AVR Arduino 코어
│   └── klangstrom-arduino/ # Klangstrom 코어
├── cmake/                # CMake 모듈
│   ├── toolchains/      # 툴체인 설정
│   │   └── avr-gcc.cmake
│   ├── core/           # 코어 통합 모듈
│   └── boards/         # 보드별 설정
└── build/               # 빌드 출력 디렉토리
```

## 💻 소스 코드 작성

### Arduino 스타일 코드 (.ino)

```cpp
// src-arduino/main.cpp
#include "Arduino.h"

void setup() {
    // 초기화 코드
    pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
    // 반복 실행 코드
    digitalWrite(LED_BUILTIN, HIGH);
    delay(1000);
    digitalWrite(LED_BUILTIN, LOW);
    delay(1000);
}
```

### C++ 스타일 코드

```cpp
// src/main.cpp
#include <Arduino.h>

class LedBlinker {
private:
    int pin;
    unsigned long previousMillis;
    int interval;
    bool state;

public:
    LedBlinker(int ledPin, int blinkInterval) 
        : pin(ledPin), interval(blinkInterval), previousMillis(0), state(false) {}

    void begin() {
        pinMode(pin, OUTPUT);
        digitalWrite(pin, LOW);
    }

    void update() {
        unsigned long currentMillis = millis();
        if (currentMillis - previousMillis >= interval) {
            previousMillis = currentMillis;
            state = !state;
            digitalWrite(pin, state);
        }
    }
};

LedBlinker led(LED_BUILTIN, 1000);

void setup() {
    led.begin();
}

void loop() {
    led.update();
}
```

## 🔧 고급 설정

### 수동 CMake 빌드

스크립트 없이 직접 CMake를 사용할 수 있습니다:

```bash
# 빌드 디렉토리 생성 및 설정
mkdir -p build
cd build

cmake .. \
    -DTARGET_BOARD=uno \
    -DSOURCE_DIR=src-arduino \
    -DAVR_VENDOR_ROOT=/path/to/vendor/ArduinoCore-avr \
    -DCMAKE_TOOLCHAIN_FILE=/path/to/cmake/toolchains/avr-gcc.cmake

# 빌드
cmake --build . --parallel

# 업로드
make upload_uno_project
```

### 커스텀 보드 설정

새로운 보드를 추가하려면 `cmake/boards/avr/`에 새 파일을 생성:

```cmake
# cmake/boards/avr/my_custom_board.cmake
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/avr-gcc.cmake")
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/cores/arduino-avr.cmake)

set(PROJECT_NAME "my_custom_board_project" CACHE INTERNAL "")

setup_avr_board("MY_CUSTOM_BOARD" "atmega328p" "16000000L" "standard")

function(board_post_build target_name)
    avr_post_build(${target_name} "atmega328p")
    
    add_custom_target(upload_${target_name}
        COMMAND avrdude -p atmega328p -c arduino -P /dev/ttyACM0 -b 115200
                -U flash:w:${CMAKE_CURRENT_BINARY_DIR}/${target_name}.hex:i
        DEPENDS ${target_name}
        COMMENT "Uploading ${target_name}.hex to Custom Board"
    )
endfunction()
```

## 🐛 문제 해결

### 일반적인 문제

#### 1. 권한 오류
```bash
# 장치 권한 오류 시
sudo chmod 666 /dev/ttyACM0
# 또는 영구적 권한 설정
sudo usermod -a -G dialout $USER
```

#### 2. 툴체인 찾기 오류
```bash
# AVR 툴체인 설치 확인
which avr-gcc
avr-gcc --version

# ARM 툴체인 설치 확인
which arm-none-eabi-gcc
arm-none-eabi-gcc --version
```

#### 3. 빌드 실패
```bash
# 클린 빌드 시도
./build.sh -b uno -s src-arduino -c

# 상세 빌드 로그 확인
cmake --build build --verbose
```

#### 4. 업로드 실패
```bash
# 장치 연결 확인
ls /dev/tty* | grep -E "(ACM|USB)"

# avrdude 테스트
avrdude -p atmega328p -c arduino -P /dev/ttyACM0 -b 115200 -v
```

### 디버깅 팁

1. **상세 로그**: `cmake --build build --verbose`
2. **컴파일 명령 확인**: `build/CMakeFiles/uno_project.dir/build.make`
3. **장치 정보**: `dmesg | grep tty` (Arduino 연결 후)
4. **펌웨어 크기**: `avr-size build/uno_project.elf`

## 📚 API 참조

### CMake 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `TARGET_BOARD` | 타겟 보드 이름 | uno |
| `SOURCE_DIR` | 소스 디렉토리 | src |
| `CMAKE_BUILD_TYPE` | 빌드 타입 | Release |
| `AVR_VENDOR_ROOT` | AVR 코어 경로 | vendor/ArduinoCore-avr |

### 보드 설정 함수

- `setup_avr_board(board_id mcu f_cpu variant)`
- `avr_post_build(target_name mcu)`
- `collect_avr_vendor_sources(core)`

## 🤝 기여

1. 이슈 리포트: [GitHub Issues](https://github.com/your-repo/issues)
2. 풀 리퀘스트: [GitHub PRs](https://github.com/your-repo/pulls)
3. 기여 가이드: [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. [LICENSE](LICENSE) 파일을 참조하세요.

## 🙏 감사

- [Arduino](https://www.arduino.cc/) - Arduino 코어 라이브러리
- [STM32duino](https://github.com/stm32duino) - STM32 Arduino 코어
- [CMake](https://cmake.org/) - 빌드 시스템
- [AVR-GCC](https://gcc.gnu.org/wiki/AVR-GCC) - AVR 툴체인

---

**🎯 즐거운 Arduino 개발 되세요!**