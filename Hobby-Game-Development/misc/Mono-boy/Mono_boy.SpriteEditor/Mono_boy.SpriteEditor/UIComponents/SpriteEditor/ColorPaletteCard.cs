using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.UIComponents.Base;
using System;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class ColorPaletteCard : Card, IDisposable
{
    public static int SelectedColor;

    public ColorPaletteCard(Rectangle bounds) : base(bounds, InitializeComponents())
    {
        foreach (var button in _components)
        {
            button.Clicked += Button_Clicked;
        }
    }

    private static List<UIComponent> InitializeComponents()
    {
        // default color
        SelectedColor = 1;
        var defaultColor = new ColorPaletteOption(new Rectangle(6, 6, 32, 32), 1);
        defaultColor.Selected = true;

        var buttons = new List<UIComponent>()
        {
            defaultColor,
            new ColorPaletteOption(new Rectangle(6,44,32,32), 2),
            new ColorPaletteOption(new Rectangle(6,82,32,32), 3),
            new ColorPaletteOption(new Rectangle(6,120,32,32), 4),
            new ColorPaletteOption(new Rectangle(6,158,32,32), 5),
            new ColorPaletteOption(new Rectangle(6,196,32,32), 6),
            new ColorPaletteOption(new Rectangle(6,234,32,32), 7),
            new ColorPaletteOption(new Rectangle(6,272,32,32), 8),
            new ColorPaletteOption(new Rectangle(44,6,32,32), 9),
            new ColorPaletteOption(new Rectangle(44,44,32,32), 10),
            new ColorPaletteOption(new Rectangle(44,82,32,32), 11),
            new ColorPaletteOption(new Rectangle(44,120,32,32), 12),
            new ColorPaletteOption(new Rectangle(44,158,32,32), 13),
            new ColorPaletteOption(new Rectangle(44,196,32,32), 14),
            new ColorPaletteOption(new Rectangle(44,234,32,32), 15),
            new ColorPaletteOption(new Rectangle(44,272,32,32), 16)
        };

        return buttons;
    }

    public void Dispose()
    {
        foreach (var button in _components)
        {
            button.Clicked -= Button_Clicked;
        }
    }

    private void Button_Clicked(object sender, EventArgs e)
    {
        foreach (var component in _components)
        {
            component.Selected = component is ColorPaletteOption && sender is ColorPaletteOption && component == sender;
            if (component.Selected)
            {
                SelectedColor = ((ColorPaletteOption)component).GetColor();
            }
        }
    }
}
