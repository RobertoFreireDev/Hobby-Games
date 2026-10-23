// floattext.c - floating words and pinned words (see floattext.h).
#include <string.h>
#include "floattext.h"
#include "config.h"
#include "actor.h"
#include "sprites.h"

#define FT_LIFE  45             // ticks a text stays
#define FT_LEN   15
#define PIN_LEN  15
#define SCR_LEN  30
#define MAX_SCREEN_TEXTS 4      // HUD texts in a sprite font on screen at once

typedef struct {
    u8 active, len;
    u16 life;
    s32 x, y;                   // world: center, bottom (fixed point y so it rises smoothly)
    fixed rise;
    const FontData *font;
    const PaletteData *pal;
    char text[FT_LEN + 1];
} FText;

// A word pinned over an actor for this frame.
typedef struct {
    const Actor *anchor;
    const FontData *font;
    const PaletteData *pal;
    s16 dy;                     // its bottom, from the actor's origin y
    u8 len;
    char text[PIN_LEN + 1];
} Pin;

// A word at a fixed screen spot for one frame (a HUD text drawn in a sprite font).
typedef struct {
    const FontData *font;
    const PaletteData *pal;
    s16 x, y;                   // screen: top-left
    u8 len;
    char text[SCR_LEN + 1];
} ScreenText;

EWRAM_BSS static FText s_texts[MAX_FLOAT_TEXTS];    // cleared on scene load
EWRAM_BSS static Pin s_pins[MAX_PINNED_TEXTS];
EWRAM_BSS static ScreenText s_screen[MAX_SCREEN_TEXTS];
static int s_pin_count, s_screen_count;
static const FontData *s_fonts[MAX_SPRITE_FONTS];   // fonts whose glyphs are in OBJ VRAM
static int s_bases[MAX_SPRITE_FONTS];               // first OBJ tile of each one's glyphs

void ftext_reset(void) {
    for (int i = 0; i < MAX_FLOAT_TEXTS; i++) s_texts[i].active = 0;
    s_pin_count = 0;
    s_screen_count = 0;
    for (int i = 0; i < MAX_SPRITE_FONTS; i++) {
        s_fonts[i] = NULL;
        s_bases[i] = -1;
    }
}

void ftext_show(s32 x, s32 y, const char *text, const FontData *font, const PaletteData *pal) {
    if (!text || !font) return;
    FText *t = &s_texts[0];
    for (int i = 0; i < MAX_FLOAT_TEXTS; i++) {         // a free slot, else the oldest text
        if (!s_texts[i].active) { t = &s_texts[i]; break; }
        if (s_texts[i].life < t->life) t = &s_texts[i];
    }
    int n = 0;
    while (text[n] && n < FT_LEN) { t->text[n] = text[n]; n++; }
    t->text[n] = 0;
    t->len = (u8)n;
    t->active = 1;
    t->life = FT_LIFE;
    t->x = x;
    t->y = y;
    t->rise = 0;
    t->font = font;
    t->pal = pal ? pal : font->palette;
}

void ftext_pin(const Actor *anchor, s32 dy, const char *text, const FontData *font,
               const PaletteData *pal) {
    if (!anchor || !text || !font || s_pin_count >= MAX_PINNED_TEXTS) return;
    Pin *p = &s_pins[s_pin_count++];
    int n = 0;
    while (text[n] && n < PIN_LEN) { p->text[n] = text[n]; n++; }
    p->text[n] = 0;
    p->len = (u8)n;
    p->anchor = anchor;
    p->dy = (s16)dy;
    p->font = font;
    p->pal = pal ? pal : font->palette;
}

void ftext_screen(s32 x, s32 y, const char *text, const FontData *font, const PaletteData *pal) {
    if (!text || !font || s_screen_count >= MAX_SCREEN_TEXTS) return;
    ScreenText *t = &s_screen[s_screen_count++];
    int n = 0;
    while (text[n] && n < SCR_LEN) { t->text[n] = text[n]; n++; }
    t->text[n] = 0;
    t->len = (u8)n;
    t->x = (s16)x;
    t->y = (s16)y;
    t->font = font;
    t->pal = pal ? pal : font->palette;
}

void ftext_unpin(const Actor *anchor) {
    for (int i = 0; i < s_pin_count; i++)
        if (s_pins[i].anchor == anchor) s_pins[i].anchor = NULL;
}

void ftext_pins_clear(void) { s_pin_count = 0; }

void ftext_update(void) {
    for (int i = 0; i < MAX_FLOAT_TEXTS; i++) {
        FText *t = &s_texts[i];
        if (!t->active) continue;
        if (--t->life == 0) { t->active = 0; continue; }
        // Quick pop up, then a slow drift: 1 px a tick for 8 ticks, then 1/4 px.
        t->rise += t->life > FT_LIFE - 8 ? FX_ONE : FX_ONE / 4;
    }
}

// The first OBJ tile of a font's glyphs, uploaded on first use (MAX_SPRITE_FONTS fonts' glyphs per
// scene: -1 for one more, or when VRAM is full).
static int glyphs_of(const FontData *font) {
    for (int i = 0; i < MAX_SPRITE_FONTS; i++) {
        if (s_fonts[i] == font) return s_bases[i];
        if (!s_fonts[i]) {
            s_fonts[i] = font;
            s_bases[i] = sprites_upload(font->tiles, font->glyph_count);
            return s_bases[i];
        }
    }
    return -1;
}

// One word as 8x8 sprites: centered on screen x, its top at screen y.
static void draw_word(const char *text, int len, const FontData *font, const PaletteData *pal, s32 sx, s32 sy) {
    int base = glyphs_of(font);
    if (base < 0) return;
    int bank = sprites_palette(pal);
    sx -= len * 4;
    for (int k = 0; k < len; k++, sx += 8) {
        u8 g = font->map[(u8)text[k] & 127];
        if (g) sprites_tile(base + g - 1, bank, sx, sy);
    }
}

void ftext_draw(s32 cx, s32 cy) {
    for (int i = 0; i < MAX_FLOAT_TEXTS; i++) {
        const FText *t = &s_texts[i];
        if (!t->active) continue;
        if (t->life < 10 && (t->life & 2)) continue;    // blink out at the end
        draw_word(t->text, t->len, t->font, t->pal, t->x - cx, t->y - 8 - fx_to_int(t->rise) - cy);
    }
    for (int i = 0; i < s_pin_count; i++) {
        const Pin *p = &s_pins[i];
        if (!p->anchor || !p->anchor->active) continue;
        draw_word(p->text, p->len, p->font, p->pal, fx_to_int(p->anchor->x) - cx,
                  fx_to_int(p->anchor->y) + p->dy - 8 - cy);
    }
    for (int i = 0; i < s_screen_count; i++) {      // queued again by the HUD every frame
        const ScreenText *t = &s_screen[i];
        draw_word(t->text, t->len, t->font, t->pal, t->x + t->len * 4, t->y);
    }
    s_screen_count = 0;
}
