#ifndef Pins_Arduino_h
#define Pins_Arduino_h

// Arduino UNO 핀 정의
#define LED_BUILTIN 13

// 디지털 핀 매핑
#define NUM_DIGITAL_PINS 20
#define NUM_ANALOG_INPUTS 6

// SPI 핀 정의
#define SS   10
#define MOSI 11
#define MISO 12
#define SCK  13

// I2C 핀 정의
#define SDA  A4
#define SCL  A5

// 아날로그 핀 정의
static const uint8_t A0 = 14;
static const uint8_t A1 = 15;
static const uint8_t A2 = 16;
static const uint8_t A3 = 17;
static const uint8_t A4 = 18;
static const uint8_t A5 = 19;

#endif