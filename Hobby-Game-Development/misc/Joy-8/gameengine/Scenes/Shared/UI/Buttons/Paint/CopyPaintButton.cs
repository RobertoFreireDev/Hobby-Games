using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class CopyPaintButton : PaintButton
{
    public CopyPaintButton(UIComponentEnum component)
        : base(new ClickButtonEffect(), PaintOptionEnum.Copy, component, GameEngineData.Images["copy_button"])
    {

    }
}