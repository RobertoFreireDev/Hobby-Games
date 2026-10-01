using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Input;
using Mono_boy.SpriteEditor.Utils;
using Mono_boy.SpriteEditor.UIComponents.PlayGame;
using NLua;
using System.Collections.Generic;
using System.Linq;
using Mono_boy.SpriteEditor.Models;
using System;
using Mono_boy.SpriteEditor.UIComponents.SongEditor;

namespace Mono_boy.SpriteEditor.Manager;

internal class PlayGameManager : ISceneManager
{
    public List<Tile> GridColorsList;

    public List<int[,]> Tiles;

    public SceneEnum SceneType { get; set; }

    public NavButtonEnum NavButton { get; set; }

    public Lua Lua;

    public bool _hasLoaded = false;

    public int Width = 36;

    public int Height = 18;

    public int CellSize = 32;

    public Point Position = new Point(0, 80);

    public Rectangle GameRectangle;

    public Rectangle ScreenRectangle;

    public Texture2D ScreenWithHole;

    private FpsCounter fpsCounter;

    private string _scriptName = "gescript";

    public PlayGameManager()
    {
        SceneType = SceneEnum.PLAYGAME;
        NavButton = NavButtonEnum.PlayGame;
    }

    public void LoadContent()
    {
        var viewportWidth = GlobalManager.GraphicsDevice.Viewport.Width;
        var viewportHeight = GlobalManager.GraphicsDevice.Viewport.Height;
        var width = Width * CellSize;
        var height = Height * CellSize;
        GameRectangle = new Rectangle((viewportWidth - width) / 2, Position.Y, width, height);
        ScreenRectangle = new Rectangle(0, 0, viewportWidth, viewportHeight);
        CameraManipulator.LoadCamera(GameRectangle);
        GridColorsList = SpriteEditorManager.Sprites.Sprites.Select(s => s.Sprite.GridColors.ConvertToTexture2D()).ToList();
        Tiles = Games.GetCurrentGame().LoadTiles();
        ScreenWithHole = Texture2DExtensions.CreateRectangleWithHole(
                viewportWidth,
                viewportHeight,
                GameRectangle,
                4
            );
        fpsCounter = new FpsCounter();
        for (int i = 0; i < SongEditorManager.Songs.Count; i++)
        {
            Sfx.AddOrUpdateMelody(
                $"melody{i}",
                Sfx.CreateMelody(
                    SongEditorManager.Songs[i],
                    SongEditorManager.SongMinLength,
                    Piano.SongLength,
                    Piano.NotesNumber,
                    Piano.StartNote));
        }
    }

    public void Reload()
    {
        LoadContent();
        Lua = new Lua();

        // Register the C# Draw functions method in Lua
        Lua.RegisterFunction("drawpixel", this, GetType().GetMethod("DrawPixel"));
        Lua.RegisterFunction("drawrect", this, GetType().GetMethod("DrawRect"));
        Lua.RegisterFunction("drawsprite", this, GetType().GetMethod("DrawSprite"));
        Lua.RegisterFunction("drawmap", this, GetType().GetMethod("DrawMap"));
        Lua.RegisterFunction("drawtext", this, GetType().GetMethod("DrawText"));

        // Register the C# Utils functions method in Lua
        Lua.RegisterFunction("button", this, GetType().GetMethod("Button"));
        Lua.RegisterFunction("normalizevector", this, GetType().GetMethod("NormalizeVector"));
        Lua.RegisterFunction("collidetilewithrect", this, GetType().GetMethod("CollideTile"));
        Lua.RegisterFunction("collidetilewithcircle", this, GetType().GetMethod("CollideCircle"));
        Lua.RegisterFunction("gameseconds", this, GetType().GetMethod("GameTotalSeconds"));
        Lua.RegisterFunction("gameshowtime", this, GetType().GetMethod("GameTotalSecondsFullFormat"));
        Lua.RegisterFunction("getcurrenttime", this, GetType().GetMethod("GetCurrentTime"));
        Lua.RegisterFunction("getfps", this, GetType().GetMethod("GetFps"));

        // Register the C# Map functions method in Lua
        Lua.RegisterFunction("cameragrid", this, GetType().GetMethod("CameraGrid"));
        Lua.RegisterFunction("camerafollow", this, GetType().GetMethod("CameraFollow"));

        // Register the C# Sounds functions method in Lua
        Lua.RegisterFunction("playmusic", this, GetType().GetMethod("PlayMusic"));

        // Load and execute the Lua script from GameData
        Lua.DoString(Games.GetCurrentGame().Script, _scriptName);
        Init();

        GameTimer.Reset();
        _hasLoaded = true;
    }

    private void Init()
    {
        if (Lua is null)
        {
            return;
        }

        // Call the _init function in Lua
        var updateFunc = Lua.GetFunction("_init");
        if (updateFunc != null)
        {
            updateFunc.Call();
        }
    }

    public void Update()
    {
        if (Lua is null || !_hasLoaded)
        {
            return;
        }

        if (ScreenRectangle.Width != GlobalManager.GraphicsDevice.Viewport.Width
            || ScreenRectangle.Height != GlobalManager.GraphicsDevice.Viewport.Height)
        {
            LoadContent();
        }

        fpsCounter.Update();
        GameTimer.Update();

        // Call the _update function in Lua
        var updateFunc = Lua.GetFunction("_update");
        if (updateFunc != null)
        {
            updateFunc.Call();
        }
    }

    public void Draw()
    {
        if (Lua is null || !_hasLoaded)
        {
            return;
        }

        // Call the _draw function in Lua
        var drawFunc = Lua.GetFunction("_draw");
        if (drawFunc != null)
        {
            drawFunc.Call();
        }
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.CustomDraw(ScreenWithHole, ScreenRectangle, Color.White);
    }

    #region draw
    public void DrawPixel(int x, int y, int color)
    {
        var offset = CameraManipulator.GetCameraPosition();
        x += (int)offset.X;
        y += (int)offset.Y;
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.CustomDraw(GlobalManager.PixelTexture, new Vector2(x, y), ColorUtils.GetColor(color));
    }

    public void DrawRect(int x, int y, int w, int h, int color, double transparency)
    {
        if (transparency < 0 || transparency > 1)
        {
            transparency = 1f;
        }
        var offset = CameraManipulator.GetCameraPosition();
        x += (int)offset.X;
        y += (int)offset.Y;
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.CustomDraw(GlobalManager.PixelTexture, new Rectangle(x, y, w, h), ColorUtils.GetColor(color) * (float)transparency);
    }

    public void DrawSprite(int x, int y, int i, int rotate, bool flipX = false, bool flipY = false)
    {
        var offset = CameraManipulator.GetCameraPosition();
        x += (int)offset.X;
        y += (int)offset.Y;
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.CustomDraw(GridColorsList[i].Texture, new Vector2(x, y), Color.White, rotate, flipX, flipY);
    }

    public void DrawMap(int index)
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        var cameraOffset = CameraManipulator.GetOnlyCameraPosition();
        var gameOffset = CameraManipulator.GetCameraPosition();

        if (index < 0 || index >= Tiles.Count)
        {
            return;
        }

        var tile = Tiles[index];
        int x0 = -cameraOffset.X / CellSize >= 0 ? (int)-cameraOffset.X / CellSize : 0;
        int x1 = x0 + Width;
        int y0 = -cameraOffset.Y / CellSize >= 0 ? (int)-cameraOffset.Y / CellSize : 0;
        int y1 = y0 + Height;

        for (int x = x0; x <= x1; x++)
        {
            for (int y = y0; y <= y1; y++)
            {
                int drawX = (int)gameOffset.X + x * CellSize;
                int drawY = (int)gameOffset.Y + y * CellSize;
                spriteBatch.CustomDraw(
                    GridColorsList[tile[x, y]].Texture,
                new Rectangle(drawX, drawY, CellSize, CellSize),
                    Color.White);
            }
        }
    }

    public void DrawText(string text, int x, int y, int color)
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        var offset = CameraManipulator.GetCameraPosition();
        x += (int)offset.X;
        y += (int)offset.Y;
        spriteBatch.DrawText(text, new Vector2(x, y), color);
    }
    #endregion

    #region Utils
    public bool IsVector2NaN(Vector2 vector)
    {
        return float.IsNaN(vector.X) || float.IsNaN(vector.Y);
    }

    public bool Button(int btn)
    {
        var up = InputStateManager.IsUpPressed();
        var down = InputStateManager.IsDownPressed();
        var left = InputStateManager.IsLeftPressed();
        var right = InputStateManager.IsRightPressed();

        if (up && btn == 1)
        {
            return true;
        }
        else if (down && btn == 3)
        {
            return true;
        }
        else if (left && btn == 0)
        {
            return true;
        }
        else if (right && btn == 2)
        {
            return true;
        }
        return false;
    }

    private int GetTile(int x, int y, int layer)
    {
        if (layer < 0 || layer >= Tiles.Count)
        {
            return 0;
        }

        var gameOffset = CameraManipulator.GetCameraPosition();
        var tiles = Tiles[layer];
        int tileX = (int)(x / CellSize) >= 0 ? (int)(x / CellSize) : 0;
        int tileY = (int)(y / CellSize) >= 0 ? (int)(y / CellSize) : 0;

        return tiles[tileX, tileY];
    }

    public bool CollideTile(int x, int y, int w, int h, int layer)
    {
        var b = new Rectangle(0, 0, w, h);
        if (layer < 0 || layer >= Tiles.Count)
        {
            return false;
        }

        for (int i = x + b.X; i < x + b.X + b.Width; i += b.Width - 1)
        {
            if (GetTile(i, (y + b.Y), layer) != 0 ||
                GetTile(i, (y + b.Y + b.Height - 1), layer) != 0)
            {
                return true;
            }
        }

        for (int i = y + b.Y; i < y + b.Y + b.Height; i += b.Height - 1)
        {
            if (GetTile((x + b.X), i, layer) != 0 ||
                GetTile((x + b.X + b.Width - 1), i, layer) != 0)
            {
                return true;
            }
        }

        return false;
    }

    public bool CollideCircle(int x, int y, int w, int h, int layer)
    {
        if (layer < 0 || layer >= Tiles.Count)
        {
            return false;
        }

        // Calculate the center and radius of the circle inscribed in the rectangle
        int cx = x + w / 2; // center x
        int cy = y + h / 2; // center y
        int radius = Math.Min(w, h) / 2; // the radius is half the smaller dimension (width or height)

        // Calculate the bounding box for the circle
        int left = cx - radius;
        int right = cx + radius;
        int top = cy - radius;
        int bottom = cy + radius;

        // Iterate over the bounding box
        for (int tx = left; tx <= right; tx++)
        {
            for (int ty = top; ty <= bottom; ty++)
            {
                // Calculate the distance from the center of the circle to this point
                int dx = cx - tx;
                int dy = cy - ty;
                if (dx * dx + dy * dy <= radius * radius) // Check if point is within the circle
                {
                    if (GetTile(tx, ty, layer) != 0) // Check if tile is not empty
                    {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    public double[] NormalizeVector(int x, int y)
    {
        if (x == 0 && y == 0)
        {
            return new double[] { 0, 0 };
        }

        var vector = new Vector2(x, y);
        if (IsVector2NaN(vector))
        {
            return new double[] { 0, 0 };
        }

        vector.Normalize();
        return new double[] { (double)vector.X, (double)vector.Y };
    }

    public double GameTotalSeconds()
    {
        return GameTimer.ToSeconds();
    }

    public string GameTotalSecondsFullFormat(double time, bool d, bool h, bool m, bool s, bool ms)
    {
        TimeSpan timeSpan = TimeSpan.FromSeconds(time);
        int days = timeSpan.Days;
        int hours = timeSpan.Hours;
        int minutes = timeSpan.Minutes;
        int seconds = timeSpan.Seconds;
        int milliseconds = timeSpan.Milliseconds;

        var result = string.Empty;

        if (d)
            result += $"{days:D2}d:";

        if (h)
            result += $"{hours:D2}h:";

        if (m)
            result += $"{minutes:D2}m:";

        if (s)
            result += $"{seconds:D2}s:";

        if (ms)
            result += $"{milliseconds:D3}ms";

        if (result.EndsWith(":"))
            result = result.Remove(result.Length - 1);

        return result;
    }

    public CurrentTime GetCurrentTime()
    {
        return new CurrentTime();
    }

    public int GetFps()
    {
        return fpsCounter.Fps;
    }
    #endregion

    #region Camera
    public void CameraGrid(int x, int y)
    {
        CameraManipulator.UpdateForGridCamera(new Vector2(x, y));
    }

    public void CameraFollow(int x, int y)
    {
        CameraManipulator.UpdateForFollowPosition(new Vector2(x, y), 0.05f);
    }
    #endregion

    #region Sounds
    public void PlayMusic(int i)
    {
        if (i < 0 || i >= SongEditorManager.TotalSongs)
        {
            return;
        }

        Sfx.Play($"melody{i}");
    }
    #endregion
}