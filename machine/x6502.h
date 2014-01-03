#ifndef TWD_HEADER
#define TWD_HEADER

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;

typedef  int8_t  i8;
typedef  int16_t i16;
typedef  int32_t i32;

void *bailMalloc(u32 size);
void *bailCalloc(u32 size);
void *bailSalloc(u32 size, u8 byte);

#endif //TWD_HEADER
