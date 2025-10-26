# Arduino CMake Build System

CMake 기반 Arduino 빌드 시스템. Arduino IDE 없이 AVR 기반 보드를 빌드 및 업로드.

## 시스템 요구사항

### 기본 도구
```bash
# Arch Linux
sudo pacman -S cmake base-devel

# Ubuntu/Debian  
sudo apt install cmake build-essential
```

### AVR 툴체인
```bash
# Arch Linux
sudo pacman -S avr-gcc avr-binutils avr-libc avrdude

# Ubuntu/Debian
sudo apt install gcc-avr avr-libc avrdude
```

### 장치 권한 설정
```bash
# 영구 설정 (재로그인 필요)
sudo usermod -a -G uucp $USER

# 임시 설정
sudo chmod 666 /dev/ttyUSB0
```

## 프로젝트 구조

```
arduino-cmake/
├── CMakeLists.txt                  # 코어 라이브러리 빌드
├── cmake/
│   ├── toolchains/
│   │   └── avr-gcc.cmake          # AVR 툴체인 설정
│   ├── core/
│   │   ├── ArduinoCore.cmake      # 코어 빌드 로직
│   │   └── avr_integration.cmake  # AVR 통합
│   ├── boards/avr/
│   │   ├── uno.cmake              # Uno 설정
│   │   └── nano.cmake             # Nano 설정
│   └── modules/
│       ├── ArduinoProject.cmake   # 프로젝트 함수
│       └── ArduinoLibrary.cmake   # 라이브러리 함수
├── install/                        # 빌드된 코어 라이브러리
│   ├── include/                   # 헤더 파일
│   └── lib/                       # .a 라이브러리
├── projects/                       # 사용자 프로젝트
│   ├── test_nano/                 # Blink 예제
│   ├── ws2812b_nano/              # WS2812B 8-LED 패턴
│   └── ws2812b_simple/            # WS2812B 기본 예제
├── templates/                      # 프로젝트 템플릿
└── vendor/
    └── ArduinoCore-avr/           # Arduino 공식 코어
```

## 빠른 시작

### 1. 코어 라이브러리 빌드
```bash
cd /path/to/arduino-cmake

# Uno 코어 빌드
cmake -B build -DARDUINO_BOARD=uno
cmake --build build
cmake --build build --target install

# Nano 코어 빌드
cmake -B build -DARDUINO_BOARD=nano
cmake --build build
cmake --build build --target install
```

빌드 결과: `install/lib/libArduinoCore-{board}.a`

### 2. 프로젝트 빌드 및 업로드
```bash
cd projects/test_nano
cmake -B build
cmake --build build

# 업로드 (포트 자동 설정됨)
cmake --build build --target upload
```

## 새 프로젝트 생성

### 1. 템플릿 복사
```bash
cp -r templates/ my_project/
cd my_project
```

### 2. CMakeLists.txt 작성
```cmake
cmake_minimum_required(VERSION 3.20)

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/toolchains/avr-gcc.cmake)
project(my_project C CXX ASM)

include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/modules/ArduinoProject.cmake)

# 보드 선택: uno, nano, mega2560
arduino_init(BOARD nano)

arduino_executable(
    firmware
    SOURCES
        src/main.cpp
        src/mylib.cpp
)

# 포트 자동 감지: /dev/ttyUSB*, /dev/ttyACM*
arduino_upload_target(firmware PORT /dev/ttyUSB0 BAUDRATE 57600)
```

### 3. 소스 코드 작성
```cpp
// src/main.cpp
#include <Arduino.h>

void setup() {
    pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(1000);
    digitalWrite(LED_BUILTIN, LOW);
    delay(1000);
}
```

### 4. 빌드 및 업로드
```bash
cmake -B build
cmake --build build
cmake --build build --target upload
```

## 프로젝트 예제

### test_nano: Blink
기본 LED 깜빡이기 예제.
```bash
cd projects/test_nano
cmake -B build && cmake --build build
cmake --build build --target upload
```

### ws2812b_simple: 기본 WS2812B
30개 LED 무지개 패턴.
```bash
cd projects/ws2812b_simple
cmake -B build && cmake --build build
```

**특징:**
- 메모리 효율적: ~500 bytes 코드, LED당 3 bytes RAM
- 인라인 어셈블리 타이밍 제어
- API: `setPixel()`, `clear()`, `show()`, `setBrightness()`

### ws2812b_nano: 8-LED 원형 패턴
8개 LED 원형 배치용 5가지 회전 패턴.
```bash
cd projects/ws2812b_nano
cmake -B build && cmake --build build
cmake --build build --target upload
```

**설정:**
- LED 핀: D10
- LED 개수: 8
- 밝기: 100/255
- 회전 속도: 1초/바퀴
- 패턴 전환: 3초마다

**패턴:**
1. 흰색 그라데이션: 중심(255) + 좌우 2칸(128, 64)
2. 파란색 그라데이션: 중심(255) + 좌우 3칸(180, 100, 40)
3. 빨간색 펄스 웨이브: 2개 중심점 그라데이션
4. 초록색 더블 그라데이션: 0번/4번 LED 동시 회전
5. 보라색 혜성 꼬리: 5칸 긴 꼬리 효과

## CMake 함수 API

### arduino_init(BOARD <board>)
보드 설정 초기화. 코어 라이브러리를 링크하고 컴파일 옵션 설정.

**매개변수:**
- `BOARD`: uno, nano, mega2560

**내부 동작:**
- 보드별 MCU/F_CPU 설정 로드
- 코어 라이브러리 경로 설정
- 컴파일러 플래그 적용

### arduino_executable(target SOURCES ...)
실행 파일 생성. 코어 라이브러리 자동 링크.

**매개변수:**
- `target`: 타겟 이름
- `SOURCES`: 소스 파일 목록

**출력 파일:**
- `{target}.elf`: 실행 파일
- `{target}.hex`: 업로드용 HEX 파일

**자동 처리:**
- 코어 라이브러리 링크
- .hex/.eep 변환
- 크기 정보 출력

### arduino_upload_target(target PORT <port> BAUDRATE <rate>)
업로드 타겟 생성.

**매개변수:**
- `target`: arduino_executable로 생성한 타겟
- `PORT`: 시리얼 포트 (예: /dev/ttyUSB0)
- `BAUDRATE`: Uno=115200, Nano=57600

**사용:**
```bash
cmake --build build --target upload
```

## 보드별 설정

### Arduino Uno
```cmake
arduino_init(BOARD uno)
arduino_upload_target(firmware PORT /dev/ttyACM0 BAUDRATE 115200)
```
- MCU: atmega328p
- F_CPU: 16000000UL
- Variant: standard

### Arduino Nano
```cmake
arduino_init(BOARD nano)
arduino_upload_target(firmware PORT /dev/ttyUSB0 BAUDRATE 57600)
```
- MCU: atmega328p
- F_CPU: 16000000UL
- Variant: eightanaloginputs

### Arduino Mega 2560
```cmake
arduino_init(BOARD mega2560)
arduino_upload_target(firmware PORT /dev/ttyACM0 BAUDRATE 115200)
```
- MCU: atmega2560
- F_CPU: 16000000UL
- Variant: mega

## 문제 해결

### 장치 찾기
```bash
# 연결된 Arduino 확인
ls /dev/tty{USB,ACM}*

# dmesg로 확인
dmesg | grep tty
```

### 업로드 실패
```bash
# avrdude 테스트 (Nano)
avrdude -p atmega328p -c arduino -P /dev/ttyUSB0 -b 57600

# avrdude 테스트 (Uno)
avrdude -p atmega328p -c arduino -P /dev/ttyACM0 -b 115200
```

### 빌드 실패
```bash
# 상세 로그
cmake --build build --verbose

# 클린 빌드
rm -rf build
cmake -B build && cmake --build build
```

### 메모리 사용량 확인
```bash
avr-size build/firmware.elf
```

출력 예시:
```
   text    data     bss     dec     hex filename
   2908      33       0    2941     b7d build/firmware.elf
```

## 라이선스

GNU General Public License v3.0. [LICENSE](LICENSE) 참조.

---

# Arduino CMake Build System

CMake-based build system for Arduino without Arduino IDE. Supports AVR-based boards.

## System Requirements

### Basic Tools
```bash
# Arch Linux
sudo pacman -S cmake base-devel

# Ubuntu/Debian
sudo apt install cmake build-essential
```

### AVR Toolchain
```bash
# Arch Linux
sudo pacman -S avr-gcc avr-binutils avr-libc avrdude

# Ubuntu/Debian
sudo apt install gcc-avr avr-libc avrdude
```

### Device Permissions
```bash
# Permanent (requires re-login)
sudo usermod -a -G uucp $USER

# Temporary
sudo chmod 666 /dev/ttyUSB0
```

## Quick Start

### 1. Build Core Library
```bash
cd /path/to/arduino-cmake

# Build Uno core
cmake -B build -DARDUINO_BOARD=uno
cmake --build build
cmake --build build --target install

# Build Nano core
cmake -B build -DARDUINO_BOARD=nano
cmake --build build
cmake --build build --target install
```

Output: `install/lib/libArduinoCore-{board}.a`

### 2. Build and Upload Project
```bash
cd projects/test_nano
cmake -B build
cmake --build build
cmake --build build --target upload
```

## Create New Project

### 1. Copy Template
```bash
cp -r templates/ my_project/
cd my_project
```

### 2. Edit CMakeLists.txt
```cmake
cmake_minimum_required(VERSION 3.20)

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/toolchains/avr-gcc.cmake)
project(my_project C CXX ASM)

include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/modules/ArduinoProject.cmake)

# Select board: uno, nano, mega2560
arduino_init(BOARD nano)

arduino_executable(
    firmware
    SOURCES
        src/main.cpp
)

arduino_upload_target(firmware PORT /dev/ttyUSB0 BAUDRATE 57600)
```

### 3. Write Code
```cpp
// src/main.cpp
#include <Arduino.h>

void setup() {
    pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(1000);
    digitalWrite(LED_BUILTIN, LOW);
    delay(1000);
}
```

### 4. Build and Upload
```bash
cmake -B build
cmake --build build
cmake --build build --target upload
```

## CMake API

### arduino_init(BOARD <board>)
Initialize board configuration. Links core library and sets compiler flags.

### arduino_executable(target SOURCES ...)
Create executable. Automatically links core library and generates .hex file.

### arduino_upload_target(target PORT <port> BAUDRATE <rate>)
Create upload target for avrdude.

## Board Settings

### Arduino Uno
- MCU: atmega328p, F_CPU: 16MHz
- Upload: `/dev/ttyACM0`, 115200 baud

### Arduino Nano
- MCU: atmega328p, F_CPU: 16MHz
- Upload: `/dev/ttyUSB0`, 57600 baud

### Arduino Mega 2560
- MCU: atmega2560, F_CPU: 16MHz
- Upload: `/dev/ttyACM0`, 115200 baud

## Troubleshooting

### Find Device
```bash
ls /dev/tty{USB,ACM}*
dmesg | grep tty
```

### Upload Failed
```bash
avrdude -p atmega328p -c arduino -P /dev/ttyUSB0 -b 57600
```

### Build Failed
```bash
cmake --build build --verbose
```

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).
