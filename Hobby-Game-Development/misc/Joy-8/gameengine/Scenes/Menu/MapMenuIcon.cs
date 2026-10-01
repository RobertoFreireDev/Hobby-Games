using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class MapMenuIcon : MenuIcon
{
    public MapMenuIcon() : base(MenuOptionEnum.Map, UIComponentEnum.MapMenu, GameEngineData.Images["map_button"])
    {
    }
}