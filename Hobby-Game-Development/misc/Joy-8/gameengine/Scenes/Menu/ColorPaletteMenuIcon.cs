using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class ColorPaletteMenuIcon : MenuIcon
{
    public ColorPaletteMenuIcon() : base(MenuOptionEnum.ColorPalette, UIComponentEnum.ColorPaletteMenu, GameEngineData.Images["color_palette_button"])
    {
    }
}
