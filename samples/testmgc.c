#include "minigame.h"

#pragma code-name("MINIGAME")
#pragma rodata-name("MINIGAME")

void testmg_init()
{

}

unsigned char testmg_update(unsigned char key)
{
    return (key & PAD_START);
}