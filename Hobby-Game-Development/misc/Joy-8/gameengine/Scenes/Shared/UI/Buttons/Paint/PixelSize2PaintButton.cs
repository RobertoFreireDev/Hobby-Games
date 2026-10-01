using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class PixelSize2PaintButton : PaintButton
{
    public PixelSize2PaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.PixelSize2, component, GameEngineData.Images["pixel_size_2_button"])
    {

    }
}
