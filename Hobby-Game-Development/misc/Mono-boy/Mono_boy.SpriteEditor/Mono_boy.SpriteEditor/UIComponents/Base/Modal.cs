using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Input;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Utils;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.UIComponents.Base;

internal class Modal
{
    private Rectangle _bounds;
    private List<UIComponent> _components = new List<UIComponent>();
    private bool _isVisible = false;
    private int _backGroundColor = 1;
    private Rectangle _fullScreenRectangle;
    private float _startTimer = 0.0f;

    public void Show(int width, int height, List<UIComponent> components)
    {
        _startTimer = 0.3f;
        _isVisible = true;
        var viewportWidth = GlobalManager.GraphicsDevice.Viewport.Width;
        var viewportHeight = GlobalManager.GraphicsDevice.Viewport.Height;
        _bounds = new Rectangle(
            (viewportWidth - width) / 2,
            (viewportHeight - height) / 2,
            width, height);
        _fullScreenRectangle = new Rectangle(0, 0, viewportWidth, viewportHeight);
        _components = components;
        foreach (var component in components)
        {
            component.UpdateBounds(_bounds);
        }
    }

    public void Hide()
    {
        _isVisible = false;
    }

    public void Update()
    {
        if (_startTimer > 0.0f)
        {
            _startTimer -= GlobalManager.DeltaTime;
        }

        if (HasClickedOutsideModal())
        {
            Hide();
        }

        foreach (var component in _components)
        {
            component.Update();
        }
    }

    public void Draw()
    {
        if (!_isVisible) return;

        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.CustomDraw(GlobalManager.PixelTexture, _fullScreenRectangle, ColorUtils.GetColor(_backGroundColor) * 0.5f);
        spriteBatch.CustomDraw(GlobalManager.PixelTexture, _bounds, ColorUtils.GetColor(4));
        spriteBatch.DrawCardBorder(_bounds);

        foreach (var component in _components)
        {
            component.Draw();
        }
    }

    private bool HasClickedOutsideModal()
    {
        return _startTimer <= 0.0f && _isVisible && InputStateManager.IsMouseLeftButtonJustPressed() && !_bounds.Contains(InputStateManager.MousePosition());
    }
}