using gameengine.Data;
using gameengine.Input;
using gameengine.Utils;
using Microsoft.Xna.Framework.Graphics;
using System;

namespace gameengine.Scenes.Shared.UI;

internal abstract class UIComponent
{
    public event ClickEventHandler Clicked;
    public int ColorIndex;
    protected UIComponentEnum _type;
    protected float _transparency = 1f;
    private Texture2D _texture;
    public bool Disabled = false;

    public UIComponent(
        Texture2D texture,
        UIComponentEnum type,
        int color)
    {
        _texture = texture;
        _type = type;
        ColorIndex = color;
    }

    public abstract void Update();

    public abstract void AdditionalDraw();

    public void Draw()
    {
        if (Disabled)
        {
            return;
        }

        if (_texture is not null)
        {
            var spriteBatch = FrameworkData.SpriteBatch;
            spriteBatch.CustomDraw(_texture, GameEngineData.UIComponentBounds[_type], ColorIndex, _transparency);
        }

        AdditionalDraw();
    }

    protected bool IsMouseOver()
    {
        var uiComponent = GameEngineData.UIComponentBounds[_type];
        var isMouseOver = uiComponent.Contains(MouseInput.MousePosition());

        // If you want to see pointer mouse cursor, call IsMouseOver()
        // if you don't want to see pointer mouse cursor, DON'T call IsMouseOver(). Example: a button is disabled
        if (isMouseOver)
        {
            MouseInput.TryUpdateStatus(MouseInput.Pointer_mouse);
        }

        return isMouseOver;
    }

    protected bool IsClicked()
    {
        var clicked = IsMouseOver() && MouseInput.LeftButton_JustPressed();
        if (clicked)
        {
            Clicked?.Invoke(this, EventArgs.Empty);
        }
        return clicked;
    }

    public delegate void ClickEventHandler(object sender, EventArgs e);
}
