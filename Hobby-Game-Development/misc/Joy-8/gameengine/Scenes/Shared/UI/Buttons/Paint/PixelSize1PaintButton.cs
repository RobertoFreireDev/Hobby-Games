using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class PixelSize1PaintButton : PaintButton
{
    public PixelSize1PaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.PixelSize1, component, GameEngineData.Images["pixel_size_1_button"])
    {

    }
}