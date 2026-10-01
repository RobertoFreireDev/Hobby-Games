using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class ParticlesMenuIcon : MenuIcon
{
    public ParticlesMenuIcon() : base(MenuOptionEnum.Particles, UIComponentEnum.ParticlesMenu, GameEngineData.Images["particles_button"])
    {
    }
}
