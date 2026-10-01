using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class RedoPaintButton : PaintButton
{
    public RedoPaintButton(UIComponentEnum component)
        : base(new ClickButtonEffect(), PaintOptionEnum.Redo, component, GameEngineData.Images["redo_button"])
    {

    }
}
