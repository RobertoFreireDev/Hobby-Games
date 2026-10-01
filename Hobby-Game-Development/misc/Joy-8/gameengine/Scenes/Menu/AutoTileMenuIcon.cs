using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class AutoTileMenuIcon : MenuIcon
{
    public AutoTileMenuIcon() : base(MenuOptionEnum.AutoTile, UIComponentEnum.AutoTileMenu, GameEngineData.Images["autotile_button"])
    {
    }
}
