using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class LoadMenuIcon : MenuIcon
{
    public LoadMenuIcon() : base(MenuOptionEnum.Load, UIComponentEnum.LoadMenu, GameEngineData.Images["load_file_button"])
    {
    }
}