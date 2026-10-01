using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class SelectionRectanglePaintButton : PaintButton
{
    public SelectionRectanglePaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.SelectionRectangle, component, GameEngineData.Images["selection_rectangle_button"])
    {

    }
}
