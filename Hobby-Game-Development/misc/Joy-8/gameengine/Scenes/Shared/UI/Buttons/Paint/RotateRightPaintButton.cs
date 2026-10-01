using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class RotateRightPaintButton : PaintButton
{
    public RotateRightPaintButton(UIComponentEnum component)
        : base(new ClickButtonEffect(), PaintOptionEnum.RotateRight, component, GameEngineData.Images["rotate_right_button"])
    {

    }
}
