// Input definitions
#define PAD_A 0x80
#define PAD_B 0x40
#define PAD_SELECT 0x20
#define PAD_START 0x10
#define PAD_U 0x08
#define PAD_D 0x04
#define PAD_L 0x02
#define PAD_R 0x01

#define oam ((unsigned char *)0x0200)

#define SPRITE(num, x, y, tile, flags) \
    *((unsigned char *)0x0200+(num<<2)) = y; \
    *((unsigned char *)0x0201+(num<<2)) = tile; \
    *((unsigned char *)0x0202+(num<<2)) = flags; \
    *((unsigned char *)0x0203+(num<<2)) = x;

#define ppu_send ((unsigned char*)0x0100)    
unsigned char (*ppu_reserve)(unsigned short addr, unsigned char count) = (unsigned char(*)(unsigned short, unsigned char))0x0406;

extern void copydata(); // NOTE: This must be the first thing called in your init function
