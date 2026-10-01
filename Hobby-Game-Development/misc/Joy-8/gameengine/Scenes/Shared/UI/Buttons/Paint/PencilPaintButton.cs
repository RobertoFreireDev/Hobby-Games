using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class PencilPaintButton : PaintButton
{
    public PencilPaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.Pencil, component, GameEngineData.Images["pencil_button"])
    {

    }
}