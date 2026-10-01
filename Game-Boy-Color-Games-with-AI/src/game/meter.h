#ifndef METER_H
#define METER_H
#include "engine/engine.h"

/* CPU load meter for the stress scenes. meter_begin() first thing in update, meter_end() last:
   load = scanlines elapsed since VBlank started (LY), out of 154 per frame; an update that runs past
   the next VBlank counts as 100% and as a dropped frame. Values refresh once per second (60 VBlanks). */
extern uint8_t meter_avg, meter_peak, meter_fps;   /* percent, percent, frames per 60 VBlanks */

void meter_reset(void) BANKED;
void meter_begin(void) BANKED;
void meter_end(void) BANKED;
void meter_labels(uint8_t x, uint8_t y, uint8_t win) BANKED;  /* once: "CPU    % PK    %" */
void meter_print(uint8_t x, uint8_t y, uint8_t win) BANKED;   /* numbers only: text costs ~2-3K cycles per char */
#endif
