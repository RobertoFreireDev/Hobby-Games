using gameengine.Data;
using gameengine.Utils;
using Microsoft.Xna.Framework;

namespace gameengine.Scenes.Shared.UI.Buttons.Page;

internal class PageButton : UIComponent
{
    public bool Selected = false;
    public int Page;
    private int _numberColor;

    public PageButton(int page, UIComponentEnum component) : base(GameEngineData.Images["page_selected_button"], component, 1)
    {
        Page = page;
        _transparency = 0.2f;
    }

    public override void Update()
    {
        var isMouseOver = IsMouseOver();
        var isClicked = false;

        if (isMouseOver)
        {
            isClicked = IsClicked();
        }

        if (Selected)
        {
            ColorIndex = 2;
            _transparency = 1f;
        }
        else
        {
            ColorIndex = 1;
            _transparency = 0.2f;
        }
    }

    public override void AdditionalDraw()
    {
        var spriteBatch = FrameworkData.SpriteBatch;
        var bounds = GameEngineData.UIComponentBounds[_type];
        spriteBatch.DrawText_MediumFont(Page.ToString(), new Vector2(bounds.X + 5, bounds.Y + 7), 4, 1f, 2f, -1);

        if (!Selected)
        {
            return;
        }
    }
}