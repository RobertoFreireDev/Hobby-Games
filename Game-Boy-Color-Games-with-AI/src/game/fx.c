#include "engine/engine.h"
#include "fx.h"

sprite_t fx_spark;
/*                                          spr        speed up   gravity life */
const particle_style_t fx_burst    = { &fx_spark, 20,  -24, 2,      20 };
const particle_style_t fx_dust     = { &fx_spark, 16,  -8,  1,      14 };
const particle_style_t fx_blast    = { &fx_spark, 32,  -24, 3,      30 };
const particle_style_t fx_fountain = { &fx_spark, 10,  -48, 3,      36 };
const particle_style_t fx_firework = { &fx_spark, 28,  0,   1,      32 };
