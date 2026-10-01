#ifndef FX_H
#define FX_H
#include "engine/engine.h"

/* Particle styles, shared by every scene. They live in bank 0 (not banked) because particles_update()
   reads them every frame from whatever bank the calling scene runs in. A scene that emits particles
   loads spr_spark into fx_spark first. */
extern sprite_t fx_spark;
extern const particle_style_t fx_burst;     /* coin pickup: small upward burst */
extern const particle_style_t fx_dust;      /* stomp: low puff */
extern const particle_style_t fx_blast;     /* death: big burst with gravity */
extern const particle_style_t fx_fountain;  /* CPU stress: tall fountain */
extern const particle_style_t fx_firework;  /* win screen: slow round burst */
#endif
