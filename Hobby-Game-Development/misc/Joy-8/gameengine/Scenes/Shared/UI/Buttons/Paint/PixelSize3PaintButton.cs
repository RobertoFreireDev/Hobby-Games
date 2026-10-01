using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class PixelSize3PaintButton : PaintButton
{
    public PixelSize3PaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.PixelSize3, component, GameEngineData.Images["pixel_size_3_button"])
    {

    }
}
