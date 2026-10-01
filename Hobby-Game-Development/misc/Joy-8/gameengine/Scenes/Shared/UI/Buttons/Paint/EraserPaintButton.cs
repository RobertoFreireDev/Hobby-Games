using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class EraserPaintButton : PaintButton
{
    public EraserPaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.Eraser, component, GameEngineData.Images["eraser_button"])
    {

    }
}