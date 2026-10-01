using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.UIComponents.Common;
using System;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class SpriteCellButtonCard : Card
{
    public SpriteCellButtonCard(Rectangle bounds) : base(bounds, InitializeComponents())
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
            new SpriteCellButton(GlobalManager.Textures["double_left_arrow_button"], new Rectangle(6,4,32,32), NavPageEnum.First, 0),
            new SpriteCellButton(GlobalManager.Textures["left_arrow_button"], new Rectangle(76,4,32,32), NavPageEnum.Previous, 0),
            new SpriteCellButton(GlobalManager.Textures["right_arrow_button"], new Rectangle(146,4,32,32), NavPageEnum.Next, 0),
            new SpriteCellButton(GlobalManager.Textures["double_right_arrow_button"], new Rectangle(216,4,32,32), NavPageEnum.Last, 0)
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
            component.Selected = component is SpriteCellButton && sender is SpriteCellButton && component == sender;
            if (component.Selected)
            {
                switch (((SpriteCellButton)component).Type)
                {
                    case NavPageEnum.First:
                        SpriteEditorManager.Sprites.Pagination.FirstPage();
                        break;
                    case NavPageEnum.Previous:
                        SpriteEditorManager.Sprites.Pagination.PreviousPage();
                        break;
                    case NavPageEnum.Next:
                        SpriteEditorManager.Sprites.Pagination.NextPage();
                        break;
                    case NavPageEnum.Last:
                        SpriteEditorManager.Sprites.Pagination.LastPage();
                        break;
                }
            }
        }
    }
}
