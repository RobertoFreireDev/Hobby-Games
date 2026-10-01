namespace cut2.core.lua;

internal class LuaBinding
{
    private static NLua.Lua _lua;
    private static SfxEngine _sfxEngine = new SfxEngine();
    public static SpriteSheet SpriteSheet = new SpriteSheet();

    public LuaBinding()
    {
        _sfxEngine.LoadSfxs(FileIO.SplitData(FileIO.Read(Constants.File.Name, Constants.File.Extensions.Sfx)));
        SpriteSheet.LoadSprites(FileIO.SplitData(FileIO.Read(Constants.File.Name, Constants.File.Extensions.SpriteSheet)));
        _lua = new NLua.Lua();

        // palette
        _lua.RegisterFunction("pal", this, GetType().GetMethod(nameof(SetColorPalette)));

        // sfx
        _lua.RegisterFunction("sfx", this, GetType().GetMethod(nameof(Sfx)));

        // input
        _lua.RegisterFunction("btn", this, GetType().GetMethod(nameof(LuaBtn)));
        _lua.RegisterFunction("btnp", this, GetType().GetMethod(nameof(LuaBtnp)));
        _lua.RegisterFunction("btnr", this, GetType().GetMethod(nameof(LuaBtnr)));

        // Mouse
        _lua.RegisterFunction("mouseup", this, GetType().GetMethod(nameof(LuaMouseScrollUp)));
        _lua.RegisterFunction("mousedown", this, GetType().GetMethod(nameof(LuaMouseScrollDown)));
        _lua.RegisterFunction("mouselp", this, GetType().GetMethod(nameof(LuaMouseLeftJustPressed)));
        _lua.RegisterFunction("mouselr", this, GetType().GetMethod(nameof(LuaMouseLeftReleased)));
        _lua.RegisterFunction("mousel", this, GetType().GetMethod(nameof(LuaMouseLeftPressed)));
        _lua.RegisterFunction("mouserp", this, GetType().GetMethod(nameof(LuaMouseRightJustPressed)));
        _lua.RegisterFunction("mouserr", this, GetType().GetMethod(nameof(LuaMouseRightReleased)));
        _lua.RegisterFunction("mouser", this, GetType().GetMethod(nameof(LuaMouseRightPressed)));
        _lua.RegisterFunction("mousexy", this, GetType().GetMethod(nameof(LuaMousePos)));

        // Draw
        _lua.RegisterFunction("spr", this, GetType().GetMethod(nameof(DrawSprite)));
        _lua.RegisterFunction("print", this, GetType().GetMethod(nameof(DrawText)));
        _lua.RegisterFunction("cam", this, GetType().GetMethod(nameof(Camera)));

        try
        {
            _lua.DoFile(FileIO.BuildPath(Constants.File.Main, Constants.File.Extensions.Lua, string.Empty));
        }
        catch (NLua.Exceptions.LuaScriptException ex) { LuaError.SetError(ex); }
        catch (Exception) { LuaError.SetError(Constants.Error.UNKWONERRORMESSAGE); }

        if (LuaError.HasError()) return;

        try
        {
            _lua.GetFunction("_init")?.Call();
        }
        catch (NLua.Exceptions.LuaScriptException ex) { LuaError.SetError(ex); }
        catch (Exception) { LuaError.SetError(Constants.Error.UNKWONERRORMESSAGE); }
    }

    public void Update(GameTime gameTime)
    {
        if (LuaError.HasError()) return;

        try
        {
            _lua.GetFunction("_update")?.Call();
        }
        catch (NLua.Exceptions.LuaScriptException ex) { LuaError.SetError(ex); }
        catch (Exception) { LuaError.SetError(Constants.Error.UNKWONERRORMESSAGE); }
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
            _lua.GetFunction("_draw")?.Call();
        }
        catch (NLua.Exceptions.LuaScriptException ex) { LuaError.SetError(ex); }
        catch (Exception) { LuaError.SetError(Constants.Error.UNKWONERRORMESSAGE); }
    }

    #region palette
    public static void SetColorPalette(int id)
    {
        ColorPalette.SetColorPalette(id);
    }    
    #endregion

    #region sfx
    public static void Sfx(int index, int channel = -1, int offset = 0, int length = -1)
        => _sfxEngine.Sfx(index, channel, offset, length);
    #endregion

    #region input
    public static bool LuaBtn(int index) => ButtonInput.Pressed(index);
    public static bool LuaBtnp(int index) => ButtonInput.JustPressed(index);
    public static bool LuaBtnr(int index) => ButtonInput.Released(index);

    // Mouse
    public static bool LuaMouseScrollUp() => MouseInputBinding.ScrollUp();
    public static bool LuaMouseScrollDown() => MouseInputBinding.ScrollDown();
    public static bool LuaMouseLeftJustPressed() => MouseInputBinding.LeftJustPressed();
    public static bool LuaMouseLeftReleased() => MouseInputBinding.LeftReleased();
    public static bool LuaMouseLeftPressed() => MouseInputBinding.LeftPressed();
    public static bool LuaMouseRightJustPressed() => MouseInputBinding.RightJustPressed();
    public static bool LuaMouseRightReleased() => MouseInputBinding.RightReleased();
    public static bool LuaMouseRightPressed() => MouseInputBinding.RightPressed();

    public static LuaTable LuaMousePos()
    {
        var mousepos = MouseInputBinding.PosXY();
        LuaTable table = _lua.DoString("return {}")[0] as LuaTable;
        table["x"] = mousepos.X;
        table["y"] = mousepos.Y;

        return table;
    }
    #endregion

    #region draw
    public static void DrawSprite(int n, int x, int y, int scale = 1, int w = 1, int h = 1,
        bool flipX = false, bool flipY = false)
    {
        SpriteSheet.Draw(n, x, y, scale, w, h, flipX, flipY);
    }

    public static void DrawText(string msg, int x, int y, int colorIndex = 1)
    {
        Text.DrawText(msg, new Vector2(x, y), colorIndex);
    }

    public static void Camera(int x = 0, int y = 0)
    {
        Camera2D.Camera(x, y);
    }
    #endregion

    public void StopSounds() => _sfxEngine.Sfx(-1);

    public void Unload()
    {
        StopSounds();
        _sfxEngine.Dispose();
    }
}