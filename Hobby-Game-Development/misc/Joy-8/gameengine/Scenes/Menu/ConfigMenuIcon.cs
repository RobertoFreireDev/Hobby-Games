using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class ConfigMenuIcon : MenuIcon
{
    public ConfigMenuIcon() : base(MenuOptionEnum.Config, UIComponentEnum.ConfigMenu, GameEngineData.Images["config_button"])
    {
    }
}