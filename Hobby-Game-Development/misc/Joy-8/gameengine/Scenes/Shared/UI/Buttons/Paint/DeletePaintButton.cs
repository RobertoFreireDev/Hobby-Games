using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class DeletePaintButton : PaintButton
{
    public DeletePaintButton(UIComponentEnum component)
        : base(new ClickButtonEffect(), PaintOptionEnum.Delete, component, GameEngineData.Images["delete_button"])
    {

    }
}