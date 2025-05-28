//
// NES/C base library
// based on: https://github.com/bbbradsmith/boingnes
//

typedef unsigned char      uint8;
typedef   signed char      sint8;
typedef unsigned short int uint16;
typedef   signed short int sint16;
typedef unsigned long  int uint32;
typedef   signed long  int sint32;

extern uint8 nmi_count;    // every NMI increments this value
extern uint8 input;        // gamepad inputs
extern uint8 input_new;    // new buttons pressed at last poll
extern uint8 ascii_offset; // offset from CHR index to ASCII in ppu_string
extern uint8 i,j,k,l;      // convenient zeropage temporaries
extern uint16 mx,nx,ox,px; // 16-bit ZP temporaries
#pragma zpsym("nmi_count")
#pragma zpsym("input")
#pragma zpsym("input_new")
#pragma zpsym("ascii_offset")
#pragma zpsym("i")
#pragma zpsym("j")
#pragma zpsym("k")
#pragma zpsym("l")
#pragma zpsym("mx")
#pragma zpsym("nx")
#pragma zpsym("ox")
#pragma zpsym("px")

extern uint8 palette[32];  // NES render palette
extern uint8 ppu_send[72]; // data packets uploaded to PPU (see ppu_packet)
extern uint8 oam[256];     // sprite OAM data

// PPU updates while rendering is off
extern void ppu_latch(uint16 addr); // sets PPU write address
extern void ppu_latch_at(uint8 x, uint8 y); // latches a nametable tile (x>32=$2400, y>32=$2800, etc.)
extern void ppu_write(uint8 value); // writes one byte at latched address
extern void ppu_load(const uint8* data, uint16 count); // writes block of data
extern void ppu_fill(uint8 value, uint16 count); // writes repeating byte
extern void ppu_string(const char* s); // writes a string (set ascii_offset before using)
extern void ppu_char(char c); // write a character (set ascii_offset before using)

// PPU updates while rendering is on, during vblank
extern void ppu_packet(uint16 addr, const uint8* data, uint8 count);
extern uint8 ppu_packet_reserve(uint16 addr, uint8 count); // reserve space for packet without copying data, return is pointer to data
extern void ppu_packet_apply(); // immediately apply packets while rendering is off
// Internal packet format, stored in ppu_send:
//   uint8: count (number of bytes to update), 0 = end of packets
//   uint16: address (PPU address for data)
//   uint8 * count: bytes of data

// PPU controls
extern void ppu_ctrl(uint8 v); // new value for $2000 at next render
extern void ppu_ctrl_apply(uint8 v); // set immediately
extern uint8 ppu_ctrl_get();
extern void ppu_mask(uint8 v); // $2001 at next render
extern void ppu_mask_apply(uint8 v);
extern void ppu_scroll(uint16 x, uint16 y); // scroll at next render (note 240<=y<256 is "between" nametables)
extern void ppu_render_frame(); // send updates to renderer and wait for next frame
extern void ppu_wait_frame(); // wait 1 frame without applying updates
extern void ppu_render_off(); // turn renderer off
extern void ppu_nmi_off(); // disable NMI
extern void ppu_nmi_on();

// Sprites
extern void sprite_begin(); // begin a new sprite list
extern void sprite_end(); // conclude the sprite list
extern void sprite_tile(uint8 t, uint8 a, uint8 x, uint8 y); // add a single tile
//extern void sprite(uint8 e, uint8 x, uint8 y); // add sprite "e" at x/y
//extern void sprite_flip(uint8 e, uint8 x, uint8 y); // sprite with horizontal flip

extern uint8 input_poll(); // poll the first player gamepad (result also in input/input_new)

extern void nescopy(void* dst, const void* src, uint8 count); // copies bytes (memcpy replacement), but count is <256
extern void nesset(void* dst, uint8 value, uint8 count); // fills bytes (memset replacement)

//#define PAD_A       0x80
//#define PAD_B       0x40
//#define PAD_SELECT  0x20
//#define PAD_START   0x10
//#define PAD_U       0x08
//#define PAD_D       0x04
//#define PAD_L       0x02
//#define PAD_R       0x01

#define NMT(x_,y_) (0x2000+(x_)+((y_)*32))
