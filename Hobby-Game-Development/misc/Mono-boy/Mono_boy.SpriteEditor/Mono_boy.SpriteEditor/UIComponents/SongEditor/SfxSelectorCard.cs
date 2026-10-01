using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.UIComponents.Common;
using System.Collections.Generic;
using System;
using Microsoft.Xna.Framework;

namespace Mono_boy.SpriteEditor.UIComponents.SongEditor;

internal class SfxSelectorCard : Card
{
    public SfxSelectorCard(Rectangle bounds) : base(bounds, InitializeComponents())
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
            new SpriteCellButton(GlobalManager.Textures["left_arrow_button"], new Rectangle(6,4,32,32), NavPageEnum.Previous, 0),
            new NumberField(new Rectangle(44,10,32,32),SongEditorManager.CurrentSong),
            new SpriteCellButton(GlobalManager.Textures["right_arrow_button"], new Rectangle(80,4,32,32), NavPageEnum.Next, 0)
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
                    case NavPageEnum.Previous:
                        SongEditorManager.CurrentSong = SongEditorManager.CurrentSong - 1 <= 0
                            ? 0 : SongEditorManager.CurrentSong -= 1;
                        break;
                    case NavPageEnum.Next:
                        SongEditorManager.CurrentSong = SongEditorManager.CurrentSong + 1 >= SongEditorManager.TotalSongs
                            ? SongEditorManager.TotalSongs - 1 : SongEditorManager.CurrentSong += 1;
                        break;
                }
            }
        }
    }
}