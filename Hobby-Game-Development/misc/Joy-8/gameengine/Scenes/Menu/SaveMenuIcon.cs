using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class SaveMenuIcon : MenuIcon
{
    public SaveMenuIcon() : base(MenuOptionEnum.Save, UIComponentEnum.SaveMenu, GameEngineData.Images["save_button"])
    {
    }
}