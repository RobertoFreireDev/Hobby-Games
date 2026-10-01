using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class RotateLeftPaintButton : PaintButton
{
    public RotateLeftPaintButton(UIComponentEnum component)
        : base(new ClickButtonEffect(), PaintOptionEnum.RotateLeft, component, GameEngineData.Images["rotate_left_button"])
    {

    }
}
