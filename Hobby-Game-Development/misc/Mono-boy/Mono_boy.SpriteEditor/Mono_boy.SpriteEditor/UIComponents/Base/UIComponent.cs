using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Input;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Utils;
using System;

namespace Mono_boy.SpriteEditor.UIComponents.Base;

internal abstract class UIComponent
{
    public bool Selected;
    public event ClickEventHandler Clicked;
    protected Texture2D Texture;
    protected Rectangle Bounds;
    protected int Color;

    public int GetColor()
    {
        return Color;
    }

    public Rectangle GetBounds()
    {
        return Bounds;
    }

    public UIComponent(Texture2D texture, Rectangle bounds, int color)
    {
        Texture = texture;
        Bounds = bounds;
        Color = color;
    }

    public virtual void UpdateBounds(Rectangle outerBound)
    {
        Bounds = new Rectangle(outerBound.Left + Bounds.Left, outerBound.Top + Bounds.Top, Bounds.Width, Bounds.Height);
    }

    public abstract void Update();

    public virtual void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.CustomDraw(Texture, Bounds, ColorUtils.GetColor(Color));
    }

    protected bool IsMouseOver()
    {
        return Bounds.Contains(InputStateManager.MousePosition());
    }

    protected bool IsClicked()
    {
        var clicked = IsMouseOver() && InputStateManager.IsMouseLeftButtonJustPressed();
        if (clicked)
        {
            Clicked?.Invoke(this, EventArgs.Empty);
        }
        return clicked;
    }

    protected void InvokeClick()
    {
        Clicked?.Invoke(this, EventArgs.Empty);
    }

    public delegate void ClickEventHandler(object sender, EventArgs e);
}
