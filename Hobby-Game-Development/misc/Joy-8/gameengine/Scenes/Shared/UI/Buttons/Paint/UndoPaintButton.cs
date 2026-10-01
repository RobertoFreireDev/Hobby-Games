using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class UndoPaintButton : PaintButton
{
    public UndoPaintButton(UIComponentEnum component)
        : base(new ClickButtonEffect(), PaintOptionEnum.Undo, component, GameEngineData.Images["undo_button"])
    {

    }
}
