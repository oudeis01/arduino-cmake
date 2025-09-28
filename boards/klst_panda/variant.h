#ifndef _VARIANT_KLST_PANDA_
#define _VARIANT_KLST_PANDA_

// STM32H723xx 기본 설정
#define STM32H723xx

// LED 핀 정의 (실제 보드에 맞게 수정 필요)
#define LED_BUILTIN PA5

// 디지털 핀 개수
#define NUM_DIGITAL_PINS 64
#define NUM_ANALOG_INPUTS 16

// SPI 핀 정의 (실제 보드에 맞게 수정 필요)
#define SS   PA4
#define MOSI PA7
#define MISO PA6
#define SCK  PA5

// I2C 핀 정의 (실제 보드에 맞게 수정 필요)
#define SDA  PB7
#define SCL  PB6

// UART 핀 정의
#define SERIAL_TX PA9
#define SERIAL_RX PA10

// 아날로그 핀 정의
#define A0  PA0
#define A1  PA1
#define A2  PA2
#define A3  PA3

#endif /* _VARIANT_KLST_PANDA_ */