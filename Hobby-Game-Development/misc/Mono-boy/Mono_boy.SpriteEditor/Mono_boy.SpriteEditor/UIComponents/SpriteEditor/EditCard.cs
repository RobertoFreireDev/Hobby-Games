using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using System;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class EditCard : Card, IDisposable
{
    public static bool HasCopied;

    public EditCard(Rectangle bounds) : base(bounds, InitializeComponents())
    {
        foreach (var button in _components)
        {
            button.Clicked += Button_Clicked;
        }
    }

    private static List<UIComponent> InitializeComponents()
    {
        var buttons = new List<UIComponent>()
        {
            new EditButton(GlobalManager.Textures["copy_button"], new Rectangle(6,4,32,32),EditEnum.Copy, 0),
            new EditButton(GlobalManager.Textures["paste_button"], new Rectangle(6,44,32,32),EditEnum.Paste, 0),
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
            component.Selected = component is EditButton && sender is EditButton && component == sender;
            if (component.Selected)
            {
                switch (((EditButton)component).Type)
                {
                    case EditEnum.Copy:
                        SpriteGrid.CopyGrid.GridColors = SpriteGrid.CopyColorArray(SpriteGrid.Grid.Sprite.GridColors, (Rectangle) SpriteGrid.CopyRectangleSelection);
                        HasCopied = true;
                        break;
                    case EditEnum.Paste:
                        SpriteGrid.ReplaceColorArray(SpriteGrid.CopyGrid.GridColors, SpriteGrid.Grid.Sprite.GridColors, (Rectangle)SpriteGrid.CopyRectangleSelection);
                        break;
                }
            }
        }
    }
}