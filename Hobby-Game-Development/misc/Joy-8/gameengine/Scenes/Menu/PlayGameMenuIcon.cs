using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class PlayGameMenuIcon : MenuIcon
{
    public PlayGameMenuIcon() : base(MenuOptionEnum.PlayGame, UIComponentEnum.PlayGameMenu, GameEngineData.Images["play_button"])
    {
    }
}
