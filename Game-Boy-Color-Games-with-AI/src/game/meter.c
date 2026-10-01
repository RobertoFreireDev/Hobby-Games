#pragma bank 255
#include "engine/engine.h"
#include "meter.h"

uint8_t meter_avg, meter_peak, meter_fps;
static uint16_t start_time, last_time, lines_acc;
static uint8_t frames, vbls, peak_lines;

void meter_reset(void) BANKED {
    last_time = sys_time;
    lines_acc = 0; frames = 0; vbls = 0; peak_lines = 0;
    meter_avg = meter_peak = 0; meter_fps = 60;
}

void meter_begin(void) BANKED {
    start_time = sys_time;
    vbls += (uint8_t)(start_time - last_time);
    last_time = start_time;
}

/* percent of a 154-line frame: lines * 100 / 154 ~= (lines * 167) >> 8 */
#define PCT(lines) ((uint8_t)(((uint16_t)(lines) * 167) >> 8))

void meter_end(void) BANKED {
    uint8_t ly = LY_REG, lines;
    if (sys_time != start_time) lines = 154;        /* ran past the next VBlank */
    else lines = ly >= 144 ? ly - 144 : ly + 10;
    lines_acc += lines;
    if (lines > peak_lines) peak_lines = lines;
    frames++;
    if (vbls >= 60) {                               /* once per second: one division, not per frame */
        meter_avg = PCT(lines_acc / frames);
        meter_peak = PCT(peak_lines);
        meter_fps = (uint8_t)(((uint16_t)frames * 60) / vbls);
        lines_acc = 0; frames = 0; vbls = 0; peak_lines = 0;
    }
}

void meter_labels(uint8_t x, uint8_t y, uint8_t win) BANKED {
    if (win) text_print_win(x, y, "CPU    % PK    %");
    else text_print(x, y, "CPU    % PK    %");
}

void meter_print(uint8_t x, uint8_t y, uint8_t win) BANKED {
    if (win) {
        text_print_num_win(x + 4, y, meter_avg, 3);
        text_print_num_win(x + 12, y, meter_peak, 3);
        text_print_num_win(x + 17, y, meter_fps, 2);
    } else {
        text_print_num(x + 4, y, meter_avg, 3);
        text_print_num(x + 12, y, meter_peak, 3);
        text_print_num(x + 17, y, meter_fps, 2);
    }
}
