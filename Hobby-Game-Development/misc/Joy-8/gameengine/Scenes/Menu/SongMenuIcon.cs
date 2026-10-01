using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class SongMenuIcon : MenuIcon
{
    public SongMenuIcon() : base(MenuOptionEnum.Song, UIComponentEnum.SongMenu, GameEngineData.Images["song_button"])
    {
    }
}