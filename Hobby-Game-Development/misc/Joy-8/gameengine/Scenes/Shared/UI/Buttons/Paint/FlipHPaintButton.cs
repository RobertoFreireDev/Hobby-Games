using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class FlipHPaintButton : PaintButton
{
    public FlipHPaintButton(UIComponentEnum component)
        : base(new ClickButtonEffect(), PaintOptionEnum.FlipH, component, GameEngineData.Images["flip_h_button"])
    {

    }
}
