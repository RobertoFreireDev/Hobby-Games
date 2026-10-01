using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class RectanglePaintButton : PaintButton
{
    public RectanglePaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.Rectangle, component, GameEngineData.Images["rectangle_button"])
    {

    }
}