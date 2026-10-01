using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Manager;
using System;

namespace Mono_boy.SpriteEditor.Utils;

internal static class Resolution
{
    public static Point GameResolution;

    public static void SetResolution(int w, int h, int x = 0, int y = 35)
    {
        GameResolution = new Point(Math.Max(w, 1366), Math.Max(h, 680));
        ApplyChanges();
        GlobalManager.Window.Position = new Point(x, y);
    }

    private static void ApplyChanges()
    {
        var graphics = GlobalManager.GraphicsDeviceManager;
        var graphicsDevice = GlobalManager.GraphicsDevice;
        if (graphics.IsFullScreen)
        {
            graphics.PreferredBackBufferWidth = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Width;
            graphics.PreferredBackBufferHeight = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Height;
        }
        else
        {
            graphics.PreferredBackBufferWidth = GameResolution.X;
            graphics.PreferredBackBufferHeight = GameResolution.Y;
        }

        graphics.ApplyChanges();
    }

    public static void ToggleFullScreen()
    {
        var graphics = GlobalManager.GraphicsDeviceManager;
        graphics.IsFullScreen = !graphics.IsFullScreen;
        ApplyChanges();
    }
}
