using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.UIComponents.Common;
using System;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.UIComponents.MapEditor;

internal class TileEditorButtonsCard : Card
{
    private SelectedTile SelectedTile;

    public TileEditorButtonsCard(Rectangle bounds) : base(bounds, InitializeComponents())
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
            new SpriteCellButton(GlobalManager.Textures["double_left_arrow_button"], new Rectangle(2,10,16,16), NavPageEnum.First, 0),
            new SpriteCellButton(GlobalManager.Textures["left_arrow_button"], new Rectangle(24,10,16,16), NavPageEnum.Previous, 0),
            new SpriteCellButton(GlobalManager.Textures["right_arrow_button"], new Rectangle(48,10,16,16), NavPageEnum.Next, 0),
            new SpriteCellButton(GlobalManager.Textures["double_right_arrow_button"], new Rectangle(74,10,16,16), NavPageEnum.Last, 0),
            new SelectedTile(new Vector2(96,4), 32)
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
                        MapEditorManager.TileEditor.Pagination.FirstPage();
                        break;
                    case NavPageEnum.Previous:
                        MapEditorManager.TileEditor.Pagination.PreviousPage();
                        break;
                    case NavPageEnum.Next:
                        MapEditorManager.TileEditor.Pagination.NextPage();
                        break;
                    case NavPageEnum.Last:
                        MapEditorManager.TileEditor.Pagination.LastPage();
                        break;
                }
            }
        }
    }
}

