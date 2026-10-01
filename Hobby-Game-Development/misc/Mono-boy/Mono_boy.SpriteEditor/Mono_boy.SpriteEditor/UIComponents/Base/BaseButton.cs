using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Utils;

namespace Mono_boy.SpriteEditor.UIComponents.Base;

internal class BaseButton : UIComponent
{
    private int _primaryColor;
    private int _hoverColor;

    protected Blink blink;

    private int TypeAction = 0; // 0 click 1 selection

    public BaseButton(Texture2D texture, Rectangle bounds, int type) : base(texture, bounds, 1)
    {
        _primaryColor = 1;
        _hoverColor = 2;
        blink = new Blink();
        TypeAction = type;
    }

    public override void Update()
    {
        if (TypeAction == 0)
        {
            UpdateClick();
        }
        else
        {
            UpdateSelection();
        }
    }

    private void UpdateSelection()
    {
        Color = IsMouseOver() ? _hoverColor : _primaryColor;
        IsClicked();
    }

    private void UpdateClick()
    {
        if (blink.IsBlinking())
        {
            blink.Update();
        }
        else
        {
            Color = IsMouseOver() ? _hoverColor : _primaryColor;
        }

        if (IsClicked())
        {
            blink.Enable();
        }
    }

    public override void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        if (TypeAction == 0 ? blink.IsBlinking() : Selected)
        {
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, Bounds, ColorUtils.GetColor(1));
            spriteBatch.CustomDraw(Texture, Bounds, ColorUtils.GetColor(3));
        }
        else
        {
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, Bounds, ColorUtils.GetColor(4));
            spriteBatch.CustomDraw(Texture, Bounds, ColorUtils.GetColor(Color));
        }
    }
}
