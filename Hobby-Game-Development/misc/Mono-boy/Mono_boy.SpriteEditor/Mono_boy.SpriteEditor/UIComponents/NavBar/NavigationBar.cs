using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Utils;
using System;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.UIComponents.NavBar;

internal class NavigationBar : IDisposable
{
    private Rectangle _bounds;
    protected List<NavButton> _components = new List<NavButton>();
    private bool _show = true;

    public NavigationBar(Rectangle bounds)
    {
        var y = 10;
        var end = bounds.Right;
        var icon = 50;
        _components.Add(new NavButton(GlobalManager.Textures["save_button"], new Rectangle(4, y, 32, 32), NavButtonEnum.Save, 0));
        _components.Add(new NavButton(GlobalManager.Textures["new_file_button"], new Rectangle(4 + icon, y, 32, 32), NavButtonEnum.New, 0));
        _components.Add(new NavButton(GlobalManager.Textures["load_file_button"], new Rectangle(4 + 2 * icon, y, 32, 32), NavButtonEnum.Load, 1));
        _components.Add(new NavButton(GlobalManager.Textures["sprite_button"], new Rectangle(end - 6 * icon, y, 32, 32), NavButtonEnum.Sprite, 1));
        _components.Add(new NavButton(GlobalManager.Textures["map_button"], new Rectangle(end - 5 * icon, y, 32, 32), NavButtonEnum.Map, 1));
        _components.Add(new NavButton(GlobalManager.Textures["sfx_button"], new Rectangle(end - 4 * icon, y, 32, 32), NavButtonEnum.Sfx, 1));
        _components.Add(new NavButton(GlobalManager.Textures["song_button"], new Rectangle(end - 3* icon, y, 32, 32), NavButtonEnum.Song, 1));
        _components.Add(new NavButton(GlobalManager.Textures["config_button"], new Rectangle(end - 2 * icon, y, 32, 32), NavButtonEnum.Config, 1));
        _components.Add(new NavButton(GlobalManager.Textures["play_button"], new Rectangle(end - icon, y, 32, 32), NavButtonEnum.PlayGame, 1));

        _bounds = bounds;
        foreach (var component in _components)
        {
            component.UpdateBounds(_bounds);
        }

        foreach (var button in _components)
        {
            button.Clicked += Button_Clicked;
        }
    }

    public void Toogle()
    {
        _show = !_show;
    }

    public bool GetShow()
    {
        return _show;
    }

    public void Update()
    {
        if (!_show)
        {
            return;
        }

        foreach (var component in _components)
        {
            component.Selected = GlobalManager.Scenes[GlobalManager.CurrentScene].NavButton == component.Type;
            
            if (GlobalManager.CurrentScene == SceneEnum.PLAYGAME
                && (component.Type == NavButtonEnum.Save 
                || component.Type == NavButtonEnum.New))
            {
                continue;
            }
            component.Update();
        }
    }

    public void Draw()
    {
        if (!_show)
        {
            return;
        }

        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.CustomDraw(GlobalManager.PixelTexture, _bounds, ColorUtils.GetColor(4));
        spriteBatch.CustomDraw(GlobalManager.PixelTexture, new Rectangle(4, _bounds.Bottom + 2, _bounds.Width, 2), ColorUtils.GetColor(1));
        spriteBatch.CustomDraw(GlobalManager.PixelTexture, new Rectangle(4, _bounds.Bottom + 6, _bounds.Width, 1), ColorUtils.GetColor(1));
        spriteBatch.DrawCardBorder(_bounds);

        foreach (var component in _components)
        {
            if (GlobalManager.CurrentScene == SceneEnum.PLAYGAME
                && (component.Type == NavButtonEnum.Save
                || component.Type == NavButtonEnum.New))
            {
                continue;
            }
            component.Draw();
        }
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
            if (component is NavButton && sender is NavButton && component == sender)
            {
                switch (((NavButton)component).Type)
                {
                    case NavButtonEnum.Save:
                        FileUtils.SaveGame();
                        break;
                    case NavButtonEnum.New:
                        Games.AddNewGame();
                        break;
                    case NavButtonEnum.Load:
                        GlobalManager.CurrentScene = SceneEnum.LOADGAME;
                        break;
                    case NavButtonEnum.Sprite:
                        GlobalManager.CurrentScene = SceneEnum.SPRITE;
                        break;
                    case NavButtonEnum.Map:
                        GlobalManager.CurrentScene = SceneEnum.MAP;
                        break;
                    case NavButtonEnum.Sfx:
                        GlobalManager.CurrentScene = SceneEnum.SFX;
                        break;
                    case NavButtonEnum.Song:
                        GlobalManager.CurrentScene = SceneEnum.SONG;
                        break;
                    case NavButtonEnum.Config:
                        GlobalManager.CurrentScene = SceneEnum.CONFIG;
                        break;
                    case NavButtonEnum.PlayGame:
                        GlobalManager.CurrentScene = SceneEnum.PLAYGAME;
                        break;
                }
            }
        }
    }
}
