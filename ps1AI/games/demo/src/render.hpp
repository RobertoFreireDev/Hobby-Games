#pragma once
// Draws world::g: sky, floor, boxes, player, balls, shadows, then the 2D HUD.
namespace render {
struct HudInfo {
    int  fps;
    bool paused;
    bool noPad;
};
void init();                 // builds the meshes (after gte3d::init)
void scene();
void hud(const HudInfo& info);
}  // namespace render
