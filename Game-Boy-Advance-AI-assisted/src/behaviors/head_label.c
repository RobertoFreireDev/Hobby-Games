// head_label - a word over the actor's head while a variable picks one: `words` is a list split
// by '|', and the variable's value picks one (0 = the first). An empty word, or a value outside
// the list, shows nothing. The word is drawn with a font's glyphs as sprites, `gap` pixels above
// the top of its picture, and follows it exactly. The menu map's monster shows the name of the
// sign it stands by ('spot') this way.
#include "head_label.h"
#include "behavior_params.h"
#include "engine/floattext.h"
#include "engine/vars.h"

void bhv_head_label_update(Actor *a, const void *params) {
    const Params_head_label *p = params;
    if ((a->flags & ACTOR_HIDDEN) || !a->body || !p->words || !p->font) return;
    s32 k = vars_get(p->var);
    if (k < 0) return;
    const char *w = p->words;
    for (; k > 0 && *w; w++)                            // skip to the k-th word
        if (*w == '|') k--;
    if (k > 0) return;                                  // past the end
    char buf[16];
    int n = 0;
    while (w[n] && w[n] != '|' && n < 15) { buf[n] = w[n]; n++; }
    if (!n) return;
    buf[n] = 0;
    ftext_pin(a, -a->body->origin_y - p->gap, buf, p->font, p->palette);
}
