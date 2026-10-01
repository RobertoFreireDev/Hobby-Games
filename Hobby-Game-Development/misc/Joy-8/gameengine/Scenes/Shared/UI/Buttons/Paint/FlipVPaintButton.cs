using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class FlipVPaintButton : PaintButton
{
    public FlipVPaintButton(UIComponentEnum component)
        : base(new ClickButtonEffect(), PaintOptionEnum.FlipV, component, GameEngineData.Images["flip_v_button"])
    {

    }
}
