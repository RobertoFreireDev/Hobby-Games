using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Effects;
using gameengine.Utils;
using Microsoft.Xna.Framework.Graphics;

namespace gameengine.Scenes.Shared.UI.Buttons.Paint;

internal class PaintButton : UIComponent
{
    public bool Selected = false;
    public PaintOptionEnum Type;
    private bool _enableBorder = false;
    private ButtonEffect _effect;

    public PaintButton(ButtonEffect effect, PaintOptionEnum type, UIComponentEnum component, Texture2D texture) : base(texture, component, 1)
    {
        _effect = effect;
        Type = type;
    }

    public override void Update()
    {
        var isMouseOver = IsMouseOver();
        var isClicked = false;

        if (isMouseOver)
        {
            isClicked = IsClicked();
        }

        var isSelected = _effect.IsSelected(isMouseOver, isClicked);

        if (isSelected is not null)
        {
            Selected = (bool)isSelected;
        }

        if (Selected)
        {
            _enableBorder = true;
            ColorIndex = 2;
        }
        else
        {
            _enableBorder = false;
            ColorIndex = 1;
        }
    }

    public override void AdditionalDraw()
    {
        if (!_enableBorder)
        {
            return;
        }

        FrameworkData.SpriteBatch.DrawButtonBorder(_type, ColorIndex);
    }
}