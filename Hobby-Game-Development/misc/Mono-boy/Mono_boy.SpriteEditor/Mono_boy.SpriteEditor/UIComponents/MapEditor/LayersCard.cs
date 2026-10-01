using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using System.Collections.Generic;
using System;
using Microsoft.Xna.Framework;

namespace Mono_boy.SpriteEditor.UIComponents.MapEditor;

internal class LayersCard : Card
{
    private SelectedTile SelectedTile;

    public LayersCard(Rectangle bounds) : base(bounds, InitializeComponents())
    {
        foreach (var button in _components)
        {
            button.Clicked += Button_Clicked;
        }
    }

    private static List<UIComponent> InitializeComponents()
    {
        var ofx = 5;
        var ofy = 4;
        var size = 24;
        var ofy2 = size + 2* ofy;
        var buttons = new List<UIComponent>()
        {
            new LayerButton(GlobalManager.Textures["see_button"], new Rectangle(ofx,ofy,size,size),0, true, 0),
            new LayerButton(GlobalManager.Textures["see_button"], new Rectangle(ofx + 1*size,ofy,size,size),0, true, 1),
            new LayerButton(GlobalManager.Textures["see_button"], new Rectangle(ofx + 2*size,ofy,size,size),0, true, 2),
            new LayerButton(GlobalManager.Textures["see_button"], new Rectangle(ofx + 3*size,ofy,size,size),0, true, 3),
            new LayerButton(GlobalManager.Textures["see_button"], new Rectangle(ofx + 4*size,ofy,size,size),0, true, 4),
            new LayerButton(GlobalManager.Textures["selected_button"], new Rectangle(ofx,ofy2,size,size),1, true, 0),
            new LayerButton(GlobalManager.Textures["selected_button"], new Rectangle(ofx + 1*size,ofy2,size,size),1, false, 1),
            new LayerButton(GlobalManager.Textures["selected_button"], new Rectangle(ofx + 2*size,ofy2,size,size),1, false, 2),
            new LayerButton(GlobalManager.Textures["selected_button"], new Rectangle(ofx + 3*size,ofy2,size,size),1, false, 3),
            new LayerButton(GlobalManager.Textures["selected_button"], new Rectangle(ofx + 4*size,ofy2,size,size),1, false, 4)
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
        foreach (LayerButton component in _components)
        {
            if (component is not LayerButton || sender is not LayerButton)
            {
                continue;
            }

            var componentSender = (LayerButton)sender;

            var isClicked = component == componentSender;

            if (component.Type == 1 && component.Type == componentSender.Type)
            {
                component.Selected = isClicked;

                if (isClicked)
                {
                    MapEditorManager.CurrentLayer = component.Layer;
                }
            }
            else if (component.Type == 0 && isClicked && component.Type == componentSender.Type)
            {
                component.Selected = !component.Selected;
                MapEditorManager.DisplayLayer[component.Layer] = !MapEditorManager.DisplayLayer[component.Layer];
            }
        }
    }
}