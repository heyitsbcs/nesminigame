// mapper test
// game setup
// title screen
// main menu
// scenario menu

#include "common.h"

#define FAMISTUDIO_CFG_SFX_SUPPORT 1

#include "famistudio_cc65.h"

#pragma code-name("FIXED")
#pragma rodata-name("FIXED")

// forward declarations
#pragma wrapped-call(push,trampoline,bank)
static void init_audio();
static void play_sfx_(uint8 sfx);
#pragma wrapped-call(pop)

void main()
{
	init_audio();

	while(1)
	{
		minigame_launch(0);
	}
}

void play_sfx(uint8 sfx)
{
	play_sfx_(sfx);
}

#pragma code-name("AUDIO")
#pragma rodata-name("AUDIO")

// extern void* music_data_untitled;
// extern unsigned char sounds[];

void init_audio()
{
	// famistudio_sfx_init(&sounds);
	// famistudio_init(FAMISTUDIO_PLATFORM_NTSC, &music_data_untitled);
	// famistudio_music_play(0);
}

void play_sfx_(uint8 sfx)
{
	sfx = 0;
	// famistudio_sfx_play(sfx, FAMISTUDIO_SFX_CH0);
}