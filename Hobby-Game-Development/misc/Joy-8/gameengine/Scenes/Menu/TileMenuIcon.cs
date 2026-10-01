using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class TileMenuIcon : MenuIcon
{
    public TileMenuIcon() : base(MenuOptionEnum.Tile, UIComponentEnum.TileMenu, GameEngineData.Images["tile_button"])
    {
    }
}