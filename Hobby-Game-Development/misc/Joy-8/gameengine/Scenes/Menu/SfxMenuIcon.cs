using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class SfxMenuIcon : MenuIcon
{
    public SfxMenuIcon() : base(MenuOptionEnum.Sfx, UIComponentEnum.SfxMenu, GameEngineData.Images["sfx_button"])
    {
    }
}