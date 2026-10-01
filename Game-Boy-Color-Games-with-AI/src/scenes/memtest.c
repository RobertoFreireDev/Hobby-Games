#pragma bank 255
#include "engine/engine.h"
#include "assets.h"
#include "scenes.h"
#include "game/save.h"
#include "game/romcheck.h"
#include "romtest/rom_blob.h"

/* Memory test, a few chunks per frame so the screen stays live:
   1. WRAM banks 1-7 at D000-DBFF (21 KB): two inverse patterns, then a per-bank signature
   2. WRAM bank switching: the signatures read back distinct in every bank
   3. Cartridge SRAM A100-BFFF (the save at A000 is left alone)
   4. VRAM bank 1 tiles 0-127 (free in the engine layout): write, read back, clear
   5. ROM: the 24 stress blobs (372 KB), every byte against its formula
   A reruns, START goes back. */

enum { ST_WRAM, ST_BANKS, ST_SRAM, ST_VRAM, ST_ROM, ST_DONE };

#define WRAM_START 0xD000
#define WRAM_END   0xDC00       /* DC00-DFFF untouched: the stack sits at the top of this window */
#define SRAM_END   0xC000
#define VRAM_TILES 128

static uint8_t st, first;
static uint16_t frames, errors;
static uint8_t blob_bank[BLOB_COUNT];
static uint8_t rom_blob, rom_group;
static uint8_t vram_tile;
static uint8_t vbuf[256];

static const uint8_t * const blob_ptr[BLOB_COUNT] = {
    rom_blob_01, rom_blob_02, rom_blob_03, rom_blob_04, rom_blob_05, rom_blob_06, rom_blob_07, rom_blob_08,
    rom_blob_09, rom_blob_10, rom_blob_11, rom_blob_12, rom_blob_13, rom_blob_14, rom_blob_15, rom_blob_16,
    rom_blob_17, rom_blob_18, rom_blob_19, rom_blob_20, rom_blob_21, rom_blob_22, rom_blob_23, rom_blob_24
};

/* WRAM chunk state: statics only. While another WRAM bank is mapped at D000-DFFF, the stack (at the top
   of that window) is that bank's memory, so wram_chunk() keeps nothing on the stack and never calls. */
static uint8_t *w_p;
static uint8_t w_bank, w_i, w_sig;
static uint16_t w_bad;

static void wram_chunk(void) {              /* 256 bytes at w_p in bank w_bank */
    disable_interrupts();
    SVBK_REG = w_bank;
    w_i = 0; do { w_p[w_i] = w_i ^ 0x55; } while (++w_i);
    w_i = 0; do { if (w_p[w_i] != (uint8_t)(w_i ^ 0x55)) w_bad++; } while (++w_i);
    w_i = 0; do { w_p[w_i] = w_i ^ 0xAA; } while (++w_i);
    w_i = 0; do { if (w_p[w_i] != (uint8_t)(w_i ^ 0xAA)) w_bad++; } while (++w_i);
    w_i = 0; do { w_p[w_i] = w_i + w_sig; } while (++w_i);      /* per-bank signature for step 2 */
    SVBK_REG = 1;
    enable_interrupts();
}

static void wram_check_sig(void) {          /* first chunk of bank w_bank must still hold its signature */
    disable_interrupts();
    SVBK_REG = w_bank;
    w_i = 0; do { if (w_p[w_i] != (uint8_t)(w_i + w_sig)) w_bad++; } while (++w_i);
    SVBK_REG = 1;
    enable_interrupts();
}

static void sram_chunk(void) {              /* 256 bytes at w_p in cartridge RAM */
    uint8_t hi = (uint8_t)((uint16_t)w_p >> 8);
    ENABLE_RAM;
    SWITCH_RAM(0);
    w_i = 0; do { w_p[w_i] = w_i ^ 0x55; } while (++w_i);
    w_i = 0; do { if (w_p[w_i] != (uint8_t)(w_i ^ 0x55)) w_bad++; } while (++w_i);
    w_i = 0; do { w_p[w_i] = w_i ^ 0xAA; } while (++w_i);
    w_i = 0; do { if (w_p[w_i] != (uint8_t)(w_i ^ 0xAA)) w_bad++; } while (++w_i);
    w_i = 0; do { w_p[w_i] = w_i ^ hi; } while (++w_i);          /* address pattern, left in place */
    w_i = 0; do { if (w_p[w_i] != (uint8_t)(w_i ^ hi)) w_bad++; } while (++w_i);
    DISABLE_RAM;
}

static void vram_chunk(void) {              /* 16 tiles of VRAM bank 1 from vram_tile */
    uint8_t salt = vram_tile * 3;
    w_i = 0; do { vbuf[w_i] = w_i ^ salt; } while (++w_i);
    VBK_REG = 1;
    set_sprite_data(vram_tile, 16, vbuf);
    w_i = 0; do { vbuf[w_i] = 0; } while (++w_i);
    get_sprite_data(vram_tile, 16, vbuf);
    w_i = 0; do { if (vbuf[w_i] != (uint8_t)(w_i ^ salt)) w_bad++; } while (++w_i);
    w_i = 0; do { vbuf[w_i] = 0; } while (++w_i);
    set_sprite_data(vram_tile, 16, vbuf);   /* leave the free area blank */
    VBK_REG = 0;
}

static void status(uint8_t row, uint8_t s) {    /* 0 = waiting, 1 = running, 2 = done (w_bad decides) */
    text_print(16, row, s == 0 ? "----" : s == 1 ? "RUN " : w_bad ? "FAIL" : "PASS");
}

static void finish_step(uint8_t row) {
    status(row, 2);
    errors += w_bad;
    text_print_num(7, 11, errors, 5);
    w_bad = 0;
    st++;
}

static void start_tests(void) {
    uint8_t r;
    st = ST_WRAM; frames = 0; errors = 0; w_bad = 0;
    w_bank = 1; w_p = (uint8_t *)WRAM_START; w_sig = 37;
    for (r = 2; r <= 7; r++) if (r != 3) status(r, 0);
    status(2, 1);
    text_print_num(7, 11, 0, 5);
}

void memory_enter(void) BANKED {
    uint8_t i = 0;
    blob_bank[i++] = BANK(rom_blob_01); blob_bank[i++] = BANK(rom_blob_02); blob_bank[i++] = BANK(rom_blob_03);
    blob_bank[i++] = BANK(rom_blob_04); blob_bank[i++] = BANK(rom_blob_05); blob_bank[i++] = BANK(rom_blob_06);
    blob_bank[i++] = BANK(rom_blob_07); blob_bank[i++] = BANK(rom_blob_08); blob_bank[i++] = BANK(rom_blob_09);
    blob_bank[i++] = BANK(rom_blob_10); blob_bank[i++] = BANK(rom_blob_11); blob_bank[i++] = BANK(rom_blob_12);
    blob_bank[i++] = BANK(rom_blob_13); blob_bank[i++] = BANK(rom_blob_14); blob_bank[i++] = BANK(rom_blob_15);
    blob_bank[i++] = BANK(rom_blob_16); blob_bank[i++] = BANK(rom_blob_17); blob_bank[i++] = BANK(rom_blob_18);
    blob_bank[i++] = BANK(rom_blob_19); blob_bank[i++] = BANK(rom_blob_20); blob_bank[i++] = BANK(rom_blob_21);
    blob_bank[i++] = BANK(rom_blob_22); blob_bank[i++] = BANK(rom_blob_23); blob_bank[i++] = BANK(rom_blob_24);

    text_print(4, 0, "MEMORY  TEST");
    text_print(0, 2, "WRAM BANKS 1-7");
    text_print(0, 3, " 21KB D000-DBFF");
    text_print(0, 4, "WRAM BANK SWITCH");
    text_print(0, 5, "SRAM A100-BFFF");
    text_print(0, 6, "VRAM BANK1 2KB");
    text_print(0, 7, "ROM 24 BANKS");
    text_print(0, 8, " 372KB OF PATTERNS");
    text_print(0, 10, "NOW");
    text_print(0, 11, "ERRORS");
    text_print(0, 12, "FRAMES");
    save_load();
    if (save_found) { text_print(0, 14, "SAVE OK BOOTS"); text_print_num(14, 14, save.boots, 5); }
    else text_print(0, 14, "NO VALID SAVE");
    text_print(0, 16, "A RERUN  START BACK");
    start_tests();
    first = 1;
}

void memory_update(void) BANKED {
    uint8_t n;
    if (KEY_PRESSED(J_START)) { scene_goto(&scene_menu, TRANS_FADE_BLACK); return; }
    if (first) { first = 0; return; }       /* run after the fade-in */
    if (st == ST_DONE) {
        if (KEY_PRESSED(J_A)) start_tests();
        return;
    }
    frames++;
    if ((frames & 7) == 0) text_print_num(7, 12, frames, 4);

    switch (st) {
    case ST_WRAM:
        for (n = 0; n < 2; n++) {
            wram_chunk();
            w_p += 256;
            if ((uint16_t)w_p >= WRAM_END) {
                w_p = (uint8_t *)WRAM_START;
                w_sig += 37;
                if (++w_bank > 7) {
                    finish_step(2);
                    w_bank = 1; w_sig = 37;
                    status(4, 1);
                    break;
                }
            }
        }
        text_print(4, 10, "WRAM BANK ");
        text_print_num(14, 10, w_bank, 1);
        break;
    case ST_BANKS:
        for (w_bank = 1, w_sig = 37; w_bank <= 7; w_bank++, w_sig += 37) wram_check_sig();
        finish_step(4);
        w_p = (uint8_t *)SAVE_TEST_START;
        status(5, 1);
        break;
    case ST_SRAM:
        for (n = 0; n < 2 && st == ST_SRAM; n++) {
            sram_chunk();
            w_p += 256;
            if ((uint16_t)w_p >= SRAM_END) { finish_step(5); vram_tile = 0; status(6, 1); }
        }
        text_print(4, 10, "SRAM      ");
        break;
    case ST_VRAM:
        vram_chunk();
        vram_tile += 16;
        if (vram_tile >= VRAM_TILES) { finish_step(6); rom_blob = 0; rom_group = 0; status(7, 1); }
        text_print(4, 10, "VRAM TILE ");
        text_print_num(14, 10, vram_tile, 3);
        break;
    case ST_ROM:
        n = BLOB_GROUPS - rom_group;            /* 8 groups (2 KB) per frame, 6 on the last call */
        if (n > 8) n = 8;
        w_bad += romcheck_groups(blob_bank[rom_blob], blob_ptr[rom_blob], rom_blob + 1, rom_group, n);
        rom_group += n;
        if (rom_group >= BLOB_GROUPS) {
            rom_group = 0;
            if (++rom_blob >= BLOB_COUNT) finish_step(7);
        }
        text_print(4, 10, "ROM BANK  ");
        text_print_num(14, 10, rom_blob < BLOB_COUNT ? blob_bank[rom_blob] : 0, 3);
        break;
    }
    if (st == ST_DONE) {
        text_print(4, 10, errors ? "SOME FAILED  " : "ALL PASSED   ");
        text_print_num(7, 12, frames, 4);
        sfx_play(errors ? &sfx_hurt : &sfx_coin);
    }
}
