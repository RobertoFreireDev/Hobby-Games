using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class PixelSize4PaintButton : PaintButton
{
    public PixelSize4PaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.PixelSize4, component, GameEngineData.Images["pixel_size_4_button"])
    {

    }
}
