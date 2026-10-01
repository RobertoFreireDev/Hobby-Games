using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.Utils;
using System;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.UIComponents.ConfigEditor;

internal class ConfigCard : IDisposable
{
    public List<ConfigOption> Configurations = new List<ConfigOption>();

    public ConfigCard(Rectangle bounds)
    {
        var options = new List<int>();
        int i = 0;
        do
        {
            options.Add(i);
            i++;
        } while (i < ColorUtils.PaletteList.Count);

        Configurations.Add(new ConfigOption(
            new TextField(new Vector2(bounds.X + 10, bounds.Y + 10), "Palette: "), 
            new Dropdown(new Rectangle(bounds.X + 100, bounds.Y + 5, 285, 25), options, Games.GetCurrentGame().PaletteIndex)));

        foreach (var config in Configurations)
        {
            config.Dropdown.Clicked += Button_Clicked;
        }
    }

    private void Button_Clicked(object sender, EventArgs e)
    {
        int? selectedIndex = ((Dropdown)sender)?.GetSelectedIndex();

        if (selectedIndex is null)
        {
            return;
        }

        ColorUtils.SetPalette((int)selectedIndex);
        Games.GetCurrentGame().PaletteIndex = (int)selectedIndex;
    }

    public void Update()
    {
        foreach (var config in Configurations)
        {
            config.Update();
        }
    }

    public void Draw()
    {
        foreach (var config in Configurations)
        {
            config.Draw();
        }
    }

    public void Dispose()
    {
        foreach (var config in Configurations)
        {
            config.Dropdown.Clicked -= Button_Clicked;
        }
    }
}
