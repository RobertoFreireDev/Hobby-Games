using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class PastePaintButton : PaintButton
{
    public PastePaintButton(UIComponentEnum component)
        : base(new ClickButtonEffect(), PaintOptionEnum.Paste, component, GameEngineData.Images["paste_button"])
    {

    }
}
