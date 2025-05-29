#include "../minigame.h"

#pragma code-name("MINIGAME")
#pragma rodata-name("MINIGAME")

#define NUM_SHOTS 4

unsigned char shipX;
unsigned char shipY;

unsigned char shotX[NUM_SHOTS];
unsigned char shotY[NUM_SHOTS];
unsigned char shotLife[NUM_SHOTS];
unsigned char shotDelay;

unsigned char ufoX;
unsigned char ufoY;
unsigned char ufoDelay;

unsigned char score;

void csample_init()
{
    unsigned char i;

    shipX = 120;
    shipY = 180;

    for (i = 0; i < NUM_SHOTS; i++)
    {
        shotLife[i] = 0;
    }
    shotDelay = 15;

    ufoX = 0xff;
    ufoY = 0xff;
    ufoDelay = 0x10;

    score = 0;
}

unsigned char csample_update(unsigned char key)
{
    unsigned char i;

    if (shotDelay > 0) shotDelay--;

    if (key)
    {
        if (key & PAD_START)
        {
            return 1;
        }

        if (key & PAD_L)
        {
            if (shipX > 0) shipX--;
        }
        else if (key & PAD_R)
        {
            if (shipX < 215) shipX++;
        }
    
        if (key & PAD_A && shotDelay == 0)
        {
            for (i = 0; i < NUM_SHOTS; i++)
            {
                if (shotLife[i] == 0)
                {
                    shotX[i] = shipX;
                    shotY[i] = shipY-8;
                    shotLife[i] = 100;
                    shotDelay = 15;
                    break;
                }
            }
        }
    }

    SPRITE(0, shipX, shipY, 1, 0);

    for (i = 0; i < NUM_SHOTS; i++)
    {
        if (shotLife[i] > 0)
        {
            shotLife[i]--;
            shotY[i]-=2;

            SPRITE(i+1, shotX[i], shotY[i], 2, 0);
        }
        else
        {
            SPRITE(i+1, 0xff, 0xff, 2, 0);
        }
    }

    ufoDelay--;
    if (ufoDelay == 0)
    {
        ufoX = 240;
        ufoY = 16;
    }
    else
    {
        ufoX--;
    }

    SPRITE(8, ufoX, ufoY, 3, 1);
    
    return 0;
}