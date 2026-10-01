using gameengine.Data;

namespace gameengine.Scenes.Shared.UI.Buttons.Colors;

internal class SelectedColorOption : UIComponent
{
    public SelectedColorOption(int color, UIComponentEnum component) : base(GameEngineData.PixelTexture, component, color)
    {
    }

    public override void Update()
    {
    }

    public override void AdditionalDraw()
    {
    }
}