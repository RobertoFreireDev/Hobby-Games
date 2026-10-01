using Microsoft.Xna.Framework;
using System.Collections.Generic;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Manager;

namespace Mono_boy.SpriteEditor.UIComponents.Base;

internal class Card
{
    protected Rectangle _bounds;
    protected List<UIComponent> _components;

    public Card(Rectangle bounds, List<UIComponent> components)
    {
        _bounds = bounds;
        _components = components;
        foreach (var component in components)
        {
            component.UpdateBounds(_bounds);
        }
    }

    public void Update()
    {
        foreach (var component in _components)
        {
            component.Update();
        }
    }

    public void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.DrawCardBorder(_bounds);
        foreach (var component in _components)
        {
            component.Draw();
        }
    }
}
