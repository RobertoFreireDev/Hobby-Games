using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class LinePaintButton : PaintButton
{
    public LinePaintButton(UIComponentEnum component)
        : base(new NoEffect(), PaintOptionEnum.Line, component, GameEngineData.Images["line_button"])
    {

    }
}