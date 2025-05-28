// common C header

typedef unsigned char      uint8;
typedef   signed char      sint8;
typedef unsigned short int uint16;
typedef   signed short int sint16;
typedef unsigned long  int uint32;
typedef   signed long  int sint32;

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif


typedef struct {
	uint8 x;
	uint8 y;
} uint8xy;

// converting 8-bit to 16-bit
#define TO16(a_,b_) ((a_)|((b_)<<8))
#define LO(a_) ((a_)&0xFF)
#define HI(b_) (((b_)>>8))
// accessing striped arrays
#define RA16(a_,i_) TO16((a_##0)[i_],(a_##1)[i_])
#define WA16(a_,i_,v_) { (a_##0)[i_]=LO(v_); (a_##1)[i_]=HI(v_); }

// for size of arrays (don't use on a pointer)
#define ARRAYSIZE(a_) (sizeof(a_)/sizeof((a_)[0]))

// suppress unused variable warnings but keep them searchable
#define UNUSED(v_) {(void)(v_);}

// 1-screen nametable address
#define NMT(x_,y_) (0x2000^(x_)^((y_)*32))

#define ABS(v_) (((v_)>=0)?(v_):(-(v_)))

//
// zeropage
//

// ZP temporaries and C framework (oss/cnes.h)
extern uint8 nmi_count;    // every NMI increments this value
extern uint8 ppu_send_pos; // !=0 if packets are waiting to send in ppu_send (see ppu_packet)
extern uint8 input;        // gamepad inputs
extern uint8 input_new;    // new buttons pressed at last poll
extern uint8 ascii_offset; // offset from CHR index to ASCII in ppu_string
extern uint8 i,j,k,l;      // convenient zeropage temporaries
extern uint16 mx,nx,ox,px; // 16-bit ZP temporaries

extern void play_sfx(uint8 sfx); // play the sound effect (always plays on triangle channel for now...)


#pragma zpsym("nmi_count")
#pragma zpsym("ppu_send_pos")
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

// C framework (oss/cnes.h)
extern uint8 palette[32];  // NES render palette
extern uint8 ppu_send[72]; // data packets uploaded to PPU (see ppu_packet)
extern uint8 oam[256];     // sprite OAM data

// temporary storage, used for short-lived needs (e.g. dynamically created menus)
extern uint8 scratch[256];

// Minigames
extern void minigame_launch(uint8 minigame_index);	// index into the minigame, must be valid or crash

// Banking
extern void trampoline(); // for wrapped-call (trampoline.s)
