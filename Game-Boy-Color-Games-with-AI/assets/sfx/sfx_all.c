#include "engine/engine.h"
/*                                     frames sweep duty  env   note */
static const uint8_t d_jump[]   = { SFX_TONE(10, 0x15, 0x80, 0xF3, A4), SFX_END };                /* rising */
static const uint8_t d_coin[]   = { SFX_TONE(4,  0x00, 0x80, 0xF1, B5),
                                    SFX_TONE(12, 0x00, 0x80, 0xF3, E6), SFX_END };                /* two notes */
static const uint8_t d_hurt[]   = { SFX_TONE(14, 0x2E, 0x40, 0xF2, E5), SFX_END };                /* falling */
static const uint8_t d_bump[]   = { SFX_TONE(6,  0x00, 0x80, 0xF1, C4), SFX_END };                /* low knock */
static const uint8_t d_spring[] = { SFX_TONE(16, 0x16, 0x40, 0xF3, C5), SFX_END };                /* long rise */
static const uint8_t d_flag[]   = { SFX_TONE(5,  0x00, 0x80, 0xE1, E5), SFX_TONE(5, 0x00, 0x80, 0xE1, G5),
                                    SFX_TONE(10, 0x00, 0x80, 0xE3, C6), SFX_END };                /* arpeggio */
/*                                      frames env   poly */
static const uint8_t d_stomp[]  = { SFX_NOISE(3,  0xF1, 0x50), SFX_NOISE(6, 0xC2, 0x6D), SFX_END };  /* squish */
static const uint8_t d_boom[]   = { SFX_NOISE(4,  0xF1, 0x20), SFX_NOISE(40, 0xF7, 0x74), SFX_END }; /* explosion */

const sfx_t sfx_jump   = { SFX_CH1, 1, d_jump };
const sfx_t sfx_coin   = { SFX_CH1, 2, d_coin };
const sfx_t sfx_hurt   = { SFX_CH1, 3, d_hurt };
const sfx_t sfx_bump   = { SFX_CH1, 1, d_bump };
const sfx_t sfx_spring = { SFX_CH1, 2, d_spring };
const sfx_t sfx_flag   = { SFX_CH1, 2, d_flag };
const sfx_t sfx_stomp  = { SFX_CH4, 2, d_stomp };
const sfx_t sfx_boom   = { SFX_CH4, 3, d_boom };
