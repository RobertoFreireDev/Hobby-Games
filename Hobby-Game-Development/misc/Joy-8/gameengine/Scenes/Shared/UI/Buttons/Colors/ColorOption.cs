using gameengine.Data;

namespace gameengine.Scenes.Shared.UI.Buttons.Colors;

internal class ColorOption : UIComponent
{
    public bool Selected = false;

    public ColorOption(int color, UIComponentEnum component) : base(GameEngineData.PixelTexture, component, color)
    {
    }

    public override void Update()
    {
        var isMouseOver = IsMouseOver();
        var isClicked = false;

        if (isMouseOver)
        {
            isClicked = IsClicked();
        }
    }

    public override void AdditionalDraw()
    {
        if (!Selected)
        {
            return;
        }
    }
}