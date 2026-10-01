using gameengine.Data;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;

namespace gameengine.Utils;

internal static class ResolutionUtils
{
    public static Point GameResolution;

    public static void SetResolution(int w, int h, int x = 0, int y = 35)
    {
        GameResolution = new Point(Math.Max(w, GameEngineData.BaseBox.Width), Math.Max(h, GameEngineData.BaseBox.Height));
        ApplyChanges();
        FrameworkData.Window.Position = new Point(x, y);
    }

    private static void ApplyChanges()
    {
        var graphics = FrameworkData.GraphicsDeviceManager;

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
        GameEngineData.SetBoxToDraw();
    }

    public static void ToggleFullScreen()
    {
        var graphics = FrameworkData.GraphicsDeviceManager;
        graphics.IsFullScreen = !graphics.IsFullScreen;
        ApplyChanges();
    }
}