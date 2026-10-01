using blackbox.Graphics;
using blackbox.Assets;
using blackbox.Input;
using blackbox.IOFile;
using blackbox.Utils;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using NLua;
using System;
using blackbox.Sfx;
using System.Text;
using System.Collections;

namespace blackbox.Binding;

public class LuaBinding
{
    private static Lua _lua;
    private string _scriptName = "main";
    private static SfxPlayer _player;

    public LuaBinding(string script)
    {
        _lua = new Lua();
        _lua.UseTraceback = true;
        _player = new SfxPlayer();

        // Config
        _lua.RegisterFunction("_fps30", this, GetType().GetMethod("ConfigFps30"));
        _lua.RegisterFunction("_fps60", this, GetType().GetMethod("ConfigFps60"));

        // Texture
        _lua.RegisterFunction("_limg", this, GetType().GetMethod("LoadTextureFromBase64"));
        _lua.RegisterFunction("_dimg", this, GetType().GetMethod("DrawTexture"));
        _lua.RegisterFunction("_lsimg", this, GetType().GetMethod("LoadSingleImageFromBase64"));
        _lua.RegisterFunction("_dsimg", this, GetType().GetMethod("DrawSingleImage"));
        _lua.RegisterFunction("_dsimgfx", this, GetType().GetMethod("DrawSingleImageWithEffect"));

        // Input
        _lua.RegisterFunction("_mouseshow", this, GetType().GetMethod("ShowHideMouse"));
        _lua.RegisterFunction("_mousepos", this, GetType().GetMethod("GetMousePos"));
        _lua.RegisterFunction("_mouseclick", this, GetType().GetMethod("MouseButtonPressed"));
        _lua.RegisterFunction("_mouseclickp", this, GetType().GetMethod("MouseButtonJustPressed"));
        _lua.RegisterFunction("_mouseclickr", this, GetType().GetMethod("MouseButtonReleased"));
        _lua.RegisterFunction("_mousescroll", this, GetType().GetMethod("Scroll"));
        _lua.RegisterFunction("_mousecursor", this, GetType().GetMethod("UpdateCursor"));

        _lua.RegisterFunction("_btn", this, GetType().GetMethod("Pressed"));
        _lua.RegisterFunction("_btnp", this, GetType().GetMethod("JustPressed"));
        _lua.RegisterFunction("_btnr", this, GetType().GetMethod("Released"));

        _lua.RegisterFunction("_gmpd", this, GetType().GetMethod("GamePadPressed"));
        _lua.RegisterFunction("_gmpdp", this, GetType().GetMethod("GamePadJustPressed"));
        _lua.RegisterFunction("_gmpdr", this, GetType().GetMethod("GamePadReleased"));

        // Draw
        _lua.RegisterFunction("_crtshader", this, GetType().GetMethod("EnableCRTshader"));
        _lua.RegisterFunction("_bckgdclr", this, GetType().GetMethod("ConfigBackGroundColor"));
        _lua.RegisterFunction("_rect", this, GetType().GetMethod("DrawRect"));
        _lua.RegisterFunction("_rectfill", this, GetType().GetMethod("DrawRectFill"));
        _lua.RegisterFunction("_circ", this, GetType().GetMethod("DrawCirc"));      
        _lua.RegisterFunction("_circfill", this, GetType().GetMethod("DrawCircFill"));
        _lua.RegisterFunction("_circ2", this, GetType().GetMethod("DrawCirc2"));
        _lua.RegisterFunction("_circfill2", this, GetType().GetMethod("DrawCircFill2"));
        _lua.RegisterFunction("_line", this, GetType().GetMethod("DrawLine"));
        _lua.RegisterFunction("_pixel", this, GetType().GetMethod("DrawPixel"));
        _lua.RegisterFunction("_print", this, GetType().GetMethod("Print"));
        _lua.RegisterFunction("_camera", this, GetType().GetMethod("Camera"));

        // Status
        _lua.RegisterFunction("_sysfps", this, GetType().GetMethod("GetFps"));
        _lua.RegisterFunction("_isfocused", this, GetType().GetMethod("IsFocused"));
        _lua.RegisterFunction("_getscreen", this, GetType().GetMethod("GetVirtualScreen"));
        
        // File 
        _lua.RegisterFunction("_iohasfile", this, GetType().GetMethod("HasFile"));
        _lua.RegisterFunction("_ioread", this, GetType().GetMethod("ReadFile"));
        _lua.RegisterFunction("_iocreate", this, GetType().GetMethod("CreateFile"));
        _lua.RegisterFunction("_ioupdate", this, GetType().GetMethod("UpdateFile"));
        _lua.RegisterFunction("_iocreateorupdate", this, GetType().GetMethod("CreateOrUpdateFile"));
        _lua.RegisterFunction("_iodelete", this, GetType().GetMethod("DeleteFile"));

        // tables
        _lua.RegisterFunction("_tbct", this, GetType().GetMethod("CreateTable"));
        _lua.RegisterFunction("_tbra", this, GetType().GetMethod("ReadTable"));
        _lua.RegisterFunction("_tbir", this, GetType().GetMethod("InsertRow"));
        _lua.RegisterFunction("_tbur", this, GetType().GetMethod("UpdateRow"));
        _lua.RegisterFunction("_tbuc", this, GetType().GetMethod("UpdateCell"));
        _lua.RegisterFunction("_tbdr", this, GetType().GetMethod("DeleteRow"));

        //Sfx
        _lua.RegisterFunction("_loadsfx", this, GetType().GetMethod("ReadSfx"));
        _lua.RegisterFunction("_savesfx", this, GetType().GetMethod("CreateOrUpdateSfx"));
        _lua.RegisterFunction("_getsfx", this, GetType().GetMethod("GetSfx"));
        _lua.RegisterFunction("_setnotesfx", this, GetType().GetMethod("SetNoteSfx"));
        _lua.RegisterFunction("_spdsfx", this, GetType().GetMethod("SetSfxSpeed"));
        _lua.RegisterFunction("_playsfx", this, GetType().GetMethod("PlaySfx"));
        _lua.RegisterFunction("_validfx", this, GetType().GetMethod("ValidSfx"));

        //Time
        _lua.RegisterFunction("_stimer", this, GetType().GetMethod("StartTimer"));
        _lua.RegisterFunction("_gtimer", this, GetType().GetMethod("GetTimer"));
        _lua.RegisterFunction("_pgame", this, GetType().GetMethod("PauseGame"));
        _lua.RegisterFunction("_rgame", this, GetType().GetMethod("ResumeGame"));
        _lua.RegisterFunction("_gtime", this, GetType().GetMethod("GetDateTime"));
        _lua.RegisterFunction("_gdeltatime", this, GetType().GetMethod("GetDeltaTime"));
        _lua.RegisterFunction("_gelapsedtime", this, GetType().GetMethod("GetElapsedTime"));

        // Grid
        _lua.RegisterFunction("_ngrid", this, GetType().GetMethod("NewGrid"));
        _lua.RegisterFunction("_ggrid", this, GetType().GetMethod("GetGrid"));
        _lua.RegisterFunction("_ggrid64", this, GetType().GetMethod("GetGridAsBase64"));
        _lua.RegisterFunction("_cgrid", this, GetType().GetMethod("CopyGrid"));
        _lua.RegisterFunction("_pgrid", this, GetType().GetMethod("PasteGrid"));
        _lua.RegisterFunction("_mgrid", this, GetType().GetMethod("MoveGrid"));        
        _lua.RegisterFunction("_sgrid", this, GetType().GetMethod("SetGrid"));
        _lua.RegisterFunction("_ugrid", this, GetType().GetMethod("UndoGrid"));
        _lua.RegisterFunction("_rgrid", this, GetType().GetMethod("RedoGrid"));
        _lua.RegisterFunction("_bgrid", this, GetType().GetMethod("PaintBucket"));
        _lua.RegisterFunction("_gpixelgrid", this, GetType().GetMethod("GetPixel"));
        _lua.RegisterFunction("_spixelgrid", this, GetType().GetMethod("SetPixel"));
        _lua.RegisterFunction("_slinegrid", this, GetType().GetMethod("SetLine"));
        _lua.RegisterFunction("_srectgrid", this, GetType().GetMethod("SetRect"));
        _lua.RegisterFunction("_scircgrid", this, GetType().GetMethod("SetCirc"));
        _lua.RegisterFunction("_dgrid", this, GetType().GetMethod("DrawGrid"));

        // Flags
        _lua.RegisterFunction("_gflag", this, GetType().GetMethod("GetFlag"));
        _lua.RegisterFunction("_sflag", this, GetType().GetMethod("SetFlag"));
        _lua.RegisterFunction("_getflags", this, GetType().GetMethod("GetFlags"));
        _lua.RegisterFunction("_loadflags", this, GetType().GetMethod("LoadFlags"));

        // Map
        _lua.RegisterFunction("_lmap", this, GetType().GetMethod("SetMap"));
        _lua.RegisterFunction("_cmap", this, GetType().GetMethod("CreateMap"));
        _lua.RegisterFunction("_gmap", this, GetType().GetMethod("GetMap"));
        _lua.RegisterFunction("_gsprmap", this, GetType().GetMethod("GetSpriteFromMap"));        
        _lua.RegisterFunction("_smap", this, GetType().GetMethod("SetTileInMap"));
        _lua.RegisterFunction("_bmap", this, GetType().GetMethod("UpdateTileInMap"));
        _lua.RegisterFunction("_dmap", this, GetType().GetMethod("DrawMap"));

        try
        {
            _lua.DoString(script, _scriptName);
        }
        catch (Exception ex)
        {
            LuaError.SetError(ex);
        }

        if (LuaError.HasError())
        {
            return;
        }

        try
        {
            TimeUtils.Reset();
            var initFunc = _lua.GetFunction("_init");
            if (initFunc != null)
            {
                initFunc.Call();
            }
        }
        catch (Exception ex)
        {
            LuaError.SetError(ex);
        }
    }

    public void Update()
    {
        if (LuaError.HasError())
        {
            return;
        }

        try
        {
            var updateFunc = _lua.GetFunction("_update");
            if (updateFunc != null)
            {
                updateFunc.Call();
            }
        }
        catch (Exception ex)
        {
            LuaError.SetError(ex);
        }
    }

    public void Draw()
    {
        if (LuaError.HasError())
        {
            Camera(0, 0); 
            LuaError.Draw();
            return;
        }

        try
        {
            var drawFunc = _lua.GetFunction("_draw");
            if (drawFunc != null)
            {
                drawFunc.Call();
            }
        }
        catch (Exception ex)
        {
            LuaError.SetError(ex);
        }
    }

    #region TextureFunctions
    public static void LoadTextureFromBase64(int index, int tileWidth, int tileHeight, string spriteBase64)
    {
        if (string.IsNullOrWhiteSpace(spriteBase64))
        {
            return;
        }
        GameImage.LoadTexture(index, spriteBase64, tileWidth, tileHeight);
    }

    public static void DrawTexture(int index, int i, int x, int y, int colorIndex = -1, int transparency = 10, int w = 1, int h = 1, bool flipX = false, bool flipY = false)
    {
        GameImage.DrawCustomSprite(index, i, x, y, colorIndex < 0 ? Color.White : ColorUtils.GetColor(colorIndex, transparency), w, h, flipX, flipY);
    }

    public static void LoadSingleImageFromBase64(int index, string spriteBase64)
    {
        if (string.IsNullOrWhiteSpace(spriteBase64))
        {
            return;
        }
        GameSingleImage.LoadTexture(index, spriteBase64);
    }

    public static void DrawSingleImage(int index, int x, int y, int colorIndex = -1, int transparency = 10, bool flipX = false, bool flipY = false)
    {
        GameSingleImage.DrawCustomSprite(index, x, y, colorIndex < 0 ? Color.White : ColorUtils.GetColor(colorIndex, transparency), flipX, flipY);
    }

    public static void DrawSingleImageWithEffect(int index, int x, int y, double time, string parameters, int colorIndex = -1, int transparency = 10, bool flipX = false, bool flipY = false)
    {
        parameters = FixLength(parameters, 14);
        GFW.SpriteBatch.End();
        var color = colorIndex < 0 ? new Vector4(1, 1, 1, 1) : ColorUtils.GetColor(colorIndex, transparency).ToVector4();
        GFW.CustomEffect.Parameters["Time"].SetValue((float)time);
        GFW.CustomEffect.Parameters["DistortX"].SetValue(SubstringToInt(parameters, 0, 1) * 0.01f);
        GFW.CustomEffect.Parameters["DistortY"].SetValue(SubstringToInt(parameters, 1, 1) * 0.01f);
        GFW.CustomEffect.Parameters["WaveFreq"].SetValue(SubstringToInt(parameters, 2, 1) * 10f);
        GFW.CustomEffect.Parameters["WaveSpeed"].SetValue(SubstringToInt(parameters, 3, 1) * 1f);
        GFW.CustomEffect.Parameters["ScrollX"].SetValue(SubstringToInt(parameters, 4, 1) * 0.02f);
        GFW.CustomEffect.Parameters["ScrollY"].SetValue(SubstringToInt(parameters, 5, 1) * 0.02f);
        GFW.CustomEffect.Parameters["OutlineThickness"].SetValue(SubstringToInt(parameters, 6, 1) * 0.03f);
        GFW.CustomEffect.Parameters["NoiseAmount"].SetValue(SubstringToInt(parameters, 7, 1) * 0.05f);
        GFW.CustomEffect.Parameters["ColorMode"].SetValue(SubstringToInt(parameters, 8, 1));
        GFW.CustomEffect.Parameters["DistortMode"].SetValue(SubstringToInt(parameters, 9, 1));
        var border = new Vector4(
            (float)(SubstringToInt(parameters, 10, 1) * 0.12),
            (float)(SubstringToInt(parameters, 11, 1) * 0.12),
            (float)(SubstringToInt(parameters, 12, 1) * 0.12),
            (float)(SubstringToInt(parameters, 13, 1) * 0.12));
        GFW.CustomEffect.Parameters["Border"].SetValue(border);       
        GFW.CustomEffect.Parameters["Color"].SetValue(color);

        GFW.SpriteBatch.Begin(effect: GFW.CustomEffect);
        GameSingleImage.DrawCustomSprite(index, x, y, Color.White, flipX, flipY);
        GFW.SpriteBatch.End();
        GFW.SpriteBatch.Begin();
    }

    private static string FixLength(string input, int x)
    {
        if (input.Length > x)
        {
            return input.Substring(0, x);
        }
        else if (input.Length < x)
        {
            return input.PadRight(x, '0');
        }

        return input;
    }
    #endregion

    #region Flags
    public static void SetFlag(int index, int flag)
    {
        GameGrid.SetFlag(index, flag);
    }

    public static int GetFlag(int index)
    {
        return GameGrid.GetFlag(index);
    }

    public static void LoadFlags(string data)
    {
        GameGrid.SetFlags(data);
    }

    public static string GetFlags()
    {
        return GameGrid.GetFlags();
    }

    #endregion

    #region MapFunctions
    public static void CreateMap(int columns, int rows, int size)
    {
        MapGrid.Create(columns, rows, size);
    }

    public static void SetTileInMap(int x, int y, int tileIndex = 0)
    {
        MapGrid.SetTile(x, y, tileIndex);
    }

    public static int GetSpriteFromMap(int x, int y)
    {
        return MapGrid.GetSpriteFromMap(x, y);
    }

    public static void DrawMap(int mapX, int mapY, int x, int y, int width, int height, int colorIndex = -1, int transparency = 10)
    {
        MapGrid.DrawMap(mapX, mapY, x, y, width, height, colorIndex < 0 ? Color.White : ColorUtils.GetColor(colorIndex, transparency));
    }

    public static void UpdateTileInMap(int x0, int y0, int x1, int y1, int tileIndex = 0)
    {
        MapGrid.UpdateTileInMap(x0, y0, x1, y1, tileIndex);
    }

    public static string GetMap()
    {
        return MapGrid.GetMap();
    }

    public static void SetMap(string grid)
    {
        if (string.IsNullOrWhiteSpace(grid))
        {
            return;
        }

        MapGrid.SetMap(grid);
    }
    #endregion

    #region GridFunctions
    public static void NewGrid(int columns, int rows, int size, bool enableUndoRedo = false)
    {
        GameGrid.Create(columns, rows, size, enableUndoRedo);
    }

    public static void UndoGrid()
    {
        GameGrid.Undo();
    }

    public static void RedoGrid()
    {
        GameGrid.Redo();
    }

    public static void CopyGrid(int x, int y, int w, int h)
    {
        GameGrid.Copy(x, y, w, h);
    }

    public static void PasteGrid(int x, int y, int w, int h)
    {
        GameGrid.Paste(x, y, w, h);
    }

    public static void MoveGrid(int x, int y, int w, int h, int deltaX, int deltaY)
    {
        GameGrid.MoveGrid(x, y, w, h, deltaX, deltaY); ;
    }    

    public static void SetGrid(string grid)
    {
        GameGrid.SetGameGrid(grid);
    }

    public static string GetGrid()
    {
        return GameGrid.GetGameGrid();
    }

    public static string GetGridAsBase64(int x, int y, int w, int h)
    {
        return GameGrid.GetGameGridAsBase64(x, y, w, h);
    }

    public static void SetPixel(int x, int y, int colorIndex = -1)
    {
        GameGrid.SetPixel(x, y,colorIndex);
    }

    public static void PaintBucket(int sx, int sy, int x, int y, int w, int h, int colorIndex = -1)
    {
        GameGrid.PaintBucket(sx, sy, x, y, w, h, colorIndex);
    }

    public static void SetLine(int x0, int y0, int x1, int y1, int colorIndex = -1)
    {
        GameGrid.SetLine(x0, y0, x1, y1, colorIndex);
    }

    public static void SetRect(int x0, int y0, int x1, int y1, int colorIndex = -1, bool fill = false)
    {
        GameGrid.SetRect(x0, y0, x1, y1, colorIndex, fill);
    }

    public static void SetCirc(int x0, int y0, int x1, int y1, int colorIndex = -1, bool fill = false)
    {
        GameGrid.SetCirc(x0, y0, x1, y1, colorIndex, fill);
    }

    public static int GetPixel(int x, int y)
    {
        return GameGrid.GetPixel(x, y);
    }

    public static void DrawGrid(
        int n, int x, int y, int scale, int colorIndex = -1, int transparency = 10, int w = 1, int h = 1,
        bool flipX = false, bool flipY = false)
    {
        GameGrid.DrawCustomGrid(n, x,y, scale, colorIndex < 0 ? Color.White : ColorUtils.GetColor(colorIndex, transparency), w,h,flipX,flipY);
    }
    #endregion

    #region InputFunctions
    public static LuaTable GetMousePos()
    {
        var mousepos = MouseInput.MouseVirtualPosition();
        LuaTable table = _lua.DoString("return {}")[0] as LuaTable;
        table["x"] = mousepos.X;
        table["y"] = mousepos.Y;

        return table;
    }

    public static bool MouseButtonPressed(int i)
    {
        if (i == 1)
        {
            return MouseInput.RightButton_Pressed();
        }
        else
        {
            return MouseInput.LeftButton_Pressed();
        }
    }

    public static bool MouseButtonJustPressed(int i)
    {
        if (i == 1)
        {
            return MouseInput.RightButton_JustPressed();
        }
        else
        {
            return MouseInput.LeftButton_JustPressed();
        }
    }

    public static bool MouseButtonReleased(int i)
    {
        if (i == 1)
        {
            return MouseInput.RightButton_Released();
        }
        else
        {
            return MouseInput.LeftButton_Released();
        }
    }

    public static bool Scroll(int i)
    {
        if (i == 1)
        {
            return MouseInput.ScrollUp();
        }
        else
        {
            return MouseInput.ScrollDown();
        }
    }

    public static void UpdateCursor(int i)
    {
        MouseInput.UpdateCursor(i);
    }

    public static bool JustPressed(int keyNumber)
    {
        if (!Enum.IsDefined(typeof(Keys), keyNumber))
        {
            return false;
        }

        return Input.KeyboardInput.JustPressed((Keys)keyNumber);
    }

    public static bool Released(int keyNumber)
    {
        if (!Enum.IsDefined(typeof(Keys), keyNumber))
        {
            return false;
        }

        return Input.KeyboardInput.Released((Keys)keyNumber);
    }

    public static bool Pressed(int keyNumber)
    {
        if (!Enum.IsDefined(typeof(Keys), keyNumber))
        {
            return false;
        }

        return Input.KeyboardInput.Pressed((Keys)keyNumber);
    }

    public static bool GamePadJustPressed(int buttonNumber, int playerIndex = 0)
    {
        if (!IsGamePadDefined(buttonNumber, playerIndex))
        {
            return false;
        }

        return GamepadInput.JustPressed((Buttons)buttonNumber, (PlayerIndex)playerIndex);
    }

    public static bool GamePadReleased(int buttonNumber, int playerIndex = 0)
    {
        if (!IsGamePadDefined(buttonNumber, playerIndex))
        {
            return false;
        }

        return GamepadInput.Released((Buttons)buttonNumber, (PlayerIndex)playerIndex);
    }

    public static bool GamePadPressed(int buttonNumber, int playerIndex = 0)
    {
        if (!IsGamePadDefined(buttonNumber, playerIndex))
        {
            return false;
        }

        return GamepadInput.Pressed((Buttons)buttonNumber, (PlayerIndex)playerIndex);
    }

    private static bool IsGamePadDefined(int buttonNumber, int playerIndex)
    {
        if (!Enum.IsDefined(typeof(Buttons), buttonNumber))
        {
            return false;
        }

        if (!Enum.IsDefined(typeof(PlayerIndex), playerIndex))
        {
            return false;
        }

        return true;
    }
    #endregion

    #region DrawFunctions
    public static void ShowHideMouse(bool show)
    {
        GFW.ShowHideMouse(show);
    }

    public static void DrawRect(int x, int y, int width, int height, int colorIndex = 0, int transparency = 10, int thickness = 1)
    {
        Shapes.DrawRectBorder(x, y, width, height, ColorUtils.GetColor(colorIndex, transparency), thickness);
    }

    public static void DrawRectFill(int x, int y, int width, int height, int colorIndex = 0, int transparency = 10)
    {
        Shapes.DrawRectFill(x, y, width, height, ColorUtils.GetColor(colorIndex, transparency));
    }

    public static void DrawCirc(int x, int y, int r, int colorIndex = 0, int transparency = 10)
    {
        CircleToRect(x, y, r, out int ox, out int oy, out int x0, out int y0, out int x1, out int y1);
        Shapes.DrawCirc(ox, oy, x0, y0, x1, y1, ColorUtils.GetColor(colorIndex, transparency));
    }

    public static void DrawCircFill(int x, int y, int r, int colorIndex = 0, int transparency = 10)
    {
        CircleToRect(x, y, r, out int ox, out int oy, out int x0, out int y0, out int x1, out int y1);
        Shapes.DrawCircFill(ox, oy, x0, y0, x1, y1, ColorUtils.GetColor(colorIndex, transparency));
    }

    public static void DrawCirc2(int ox, int oy, int x0, int y0, int x1, int y1, int colorIndex = 0, int transparency = 10, int thickness = 1)
    {
        Shapes.DrawCirc(ox, oy, x0, y0, x1, y1, ColorUtils.GetColor(colorIndex, transparency), thickness);
    }

    public static void DrawCircFill2(int ox, int oy, int x0, int y0, int x1, int y1, int colorIndex = 0, int transparency = 10, int thickness = 1)
    {
        Shapes.DrawCircFill(ox, oy, x0, y0, x1, y1, ColorUtils.GetColor(colorIndex, transparency), thickness);
    }

    private static void CircleToRect(int x, int y, int r, out int ox, out int oy, out int x0, out int y0, out int x1, out int y1)
    {
        ox = 0;
        oy = 0;
        x0 = x - r;
        y0 = y - r;
        x1 = x + r;
        y1 = y + r;
    }

    public static void DrawLine(int x0, int y0, int x1, int y1, int scale = 1, int colorIndex = 0, int transparency = 10)
    {
        Shapes.DrawLine(x0, y0, x1, y1, scale, ColorUtils.GetColor(colorIndex, transparency));
    }

    public static void DrawPixel(int x, int y, int colorIndex = 0, int transparency = 10)
    {
        Shapes.DrawPixel(x, y, ColorUtils.GetColor(colorIndex, transparency));
    }

    public static void Print(string text, int x, int y, int colorIndex = 0, bool wraptext = false, int wrapLimit = 0)
    {
        Font.DrawText(text, new Vector2(x, y), ColorUtils.GetColor(colorIndex), wraptext, wrapLimit);
    }

    public static void Camera(float x = 0.0f, float y = 0.0f)
    {
        Camera2D.Camera(x, y);
    }
    #endregion

    #region SystemFunctions
    public static LuaTable GetVirtualScreen()
    {
        LuaTable table = _lua.DoString("return {}")[0] as LuaTable;
        table["x"] = ScreenUtils.BaseBox.X;
        table["y"] = ScreenUtils.BaseBox.Y;
        table["width"] = ScreenUtils.BaseBox.Width;
        table["height"] = ScreenUtils.BaseBox.Height;

        return table;
    }

    public static void ConfigFps30()
    {
        GFW.UpdateFPS(30);
    }

    public static void ConfigFps60()
    {
        GFW.UpdateFPS(60);
    }

    public static void EnableCRTshader(bool value, int inner = 85, int outer = 110)
    {
        GFW.EnableCRTshader(value, inner, outer);
    }

    public static void ConfigBackGroundColor(int colorIndex)
    {
        GFW.BackgroundColor = colorIndex;
    }

    public static int GetFps()
    {
        return TimeUtils.FPS;
    }

    public static bool IsFocused()
    {
        return ScreenUtils.IsFocused;
    }
    #endregion

    #region IOFileFunctions
    public static bool HasFile(string fileName)
    {
        return TxtFileIO.HasFile(fileName);
    }

    public static string ReadFile(string fileName)
    {
        return TxtFileIO.Read(fileName);
    }

    public static void CreateFile(string fileName, string content)
    {
        TxtFileIO.Create(fileName, content);
    }

    public static void UpdateFile(string fileName, string content)
    {
        TxtFileIO.Update(fileName, content);
    }

    public static void DeleteFile(string fileName)
    {
        TxtFileIO.Delete(fileName);
    }

    public static void CreateOrUpdateFile(string fileName, string content)
    {
        TxtFileIO.CreateOrUpdate(fileName, content);
    }

    public static void ReadSfx(string sfxfilename)
    {
        if (!HasFile(sfxfilename))
        {
            return;
        }
        var content = TxtFileIO.Read(sfxfilename);
        _player.ConvertStringToData(content);
    }

    public static void CreateOrUpdateSfx(string sfxfilename)
    {
        var content = _player.ConvertDataToString();
        if (string.IsNullOrWhiteSpace(content))
        {
            return;
        }
        TxtFileIO.CreateOrUpdate(sfxfilename, content);
    }
    #endregion

    #region TableFunctions
    public static void CreateTable(string tableName, LuaTable columnsTable)
    {
        if (columnsTable == null || columnsTable.Values.Count == 0)
        {
            LuaError.SetError("Table must have at least one column");
            return;
        }

        var columns = new string[columnsTable.Values.Count];
        int i = 0;
        foreach (var val in columnsTable.Values)
        {
            columns[i++] = val?.ToString() ?? "";
        }

        TableIO.CreateTable(tableName, columns);
    }

    public static LuaTable ReadTable(string tableName)
    {
        var tableData = TableIO.ReadTable(tableName);

        LuaTable luaTable = _lua.DoString("return {}")[0] as LuaTable;

        for (int i = 0; i < tableData.Count; i++)
        {
            var row = tableData[i];
            LuaTable rowTable = _lua.DoString("return {}")[0] as LuaTable;
            for (int j = 0; j < row.Length; j++)
            {
                rowTable[j + 1] = row[j]; // Lua is 1-indexed
            }
            luaTable[i + 1] = rowTable;
        }

        return luaTable;
    }

    public static void InsertRow(string tableName, LuaTable valuesTable)
    {
        if (valuesTable == null || valuesTable.Values.Count == 0) return;

        var values = ToArray(valuesTable.Values);
        TableIO.InsertRow(tableName, values);
    }

    public static void UpdateRow(string tableName, int rowIndex, LuaTable valuesTable)
    {
        if (valuesTable == null || valuesTable.Values.Count == 0) return;

        var values = ToArray(valuesTable.Values);
        TableIO.UpdateRow(tableName, rowIndex, values);
    }

    public static void UpdateCell(string tableName, int rowIndex, int columnIndex, string value)
    {
        TableIO.UpdateCell(tableName, rowIndex, columnIndex, value);
    }

    public static void DeleteRow(string tableName, int rowIndex)
    {
        TableIO.DeleteRow(tableName, rowIndex);
    }

    private static string[] ToArray(ICollection values)
    {
        var valuesList = new string[values.Count];
        int i = 0;
        foreach (var val in values)
        {
            valuesList[i] = val?.ToString() ?? string.Empty;
            i++;
        }

        return valuesList;
    }
    #endregion

    #region SfxFunctions
    public static void SetNoteSfx(int index, int noteIndex, string note)
    {
        _player.SetNote(index, noteIndex, note);
    }

    public static string GetSfx(int index)
    {
        var sb = new StringBuilder();
        sb = _player.GetSfx(index, sb);
        return sb.ToString();
    }

    public static bool ValidSfx(string sound)
    {
        return _player.IsValidSoundString(sound);
    }

    public static void SetSfxSpeed(int index, int speed = 1)
    {
        _player.SetSpeed(index, speed);
    }

    public static void PlaySfx(int index)
    {
        _player.PlaySfx(index);
    }
    #endregion

    #region TimerFunctions
    public static void StartTimer(int i = 0)
    {
        TimeUtils.StartTimer(i);
    }

    public static double GetTimer(int i = 0, int d = 4)
    {
        return TimeUtils.GetTime(i, d);
    }

    public static void PauseGame()
    {
        GFW.PauseGame();
    }

    public static void ResumeGame()
    {
        GFW.ResumeGame();
    }    

    public static string GetDateTime(int i = 0)
    {
        return TimeUtils.GetDateTime(i);
    }

    public static double GetDeltaTime()
    {
        return TimeUtils.Delta;
    }

    public static double GetElapsedTime()
    {
        return TimeUtils.ElapsedTime;
    }
    #endregion

    #region Utils
    public static int SubstringToInt(string source, int start, int length)
    {
        return int.Parse(source.AsSpan(start, length));
    }
    #endregion
}