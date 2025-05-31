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
unsigned char displayedScore;

void csample_init()
{
    unsigned char i;

    // NOTE: This must be the first thing called in your init function
    copydata();

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
    displayedScore = 0xff;
}

unsigned char csample_update(unsigned char key)
{
    unsigned char i;

    if (score != displayedScore)
    {
    
        i = ppu_reserve(0x2024, 2);

        if (score < 10)
        {
            ppu_send[i] = 0x10;
            ppu_send[i+1] = 0x10+score;
        }
        else
        {
            unsigned char tens;

            tens = 0;
            displayedScore = score;
            while (displayedScore >= 10)
            {
                tens++;
                displayedScore -= 10;
            }

            ppu_send[i] = 0x10+tens;
            ppu_send[i+1] = 0x10+displayedScore;
        }
        displayedScore = score;
    }

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

            if (ufoX != 0xff && ufoY != 0xff)
            {
                if (shotX[i]+6 >= ufoX && shotX[i]+2 <= ufoX+8)
                {
                    if (shotY[i]+6 >= ufoY+3 && shotY[i]+2 <= ufoY+5)
                    {
                        score++;
                        if (score > 99) score = 99;
                        shotLife[i] = 0;
                        ufoX = 0xff;
                        ufoY = 0xff;
                    }
                }
            }
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
    else if (ufoX != 0xff && ufoY != 0xff)
    {
        ufoX--;
    }

    SPRITE(8, ufoX, ufoY, 3, 1);

    return 0;
}