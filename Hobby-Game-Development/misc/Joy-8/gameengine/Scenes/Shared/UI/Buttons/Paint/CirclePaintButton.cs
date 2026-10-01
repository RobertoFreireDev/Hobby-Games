using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class CirclePaintButton : PaintButton
{
    public CirclePaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.Circle, component, GameEngineData.Images["circle_button"]
        )
    {

    }
}