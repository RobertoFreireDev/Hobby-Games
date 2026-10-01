using mega8.core.common;
using mega8.core.graphics;
using mega8.core.sfx;
using Microsoft.Xna.Framework.Input;
using System;

namespace mega8.core.Lua;

internal class LuaBinding
{
    private static NLua.Lua _lua;
    private string _scriptName = "main";
    private static SfxEngine _sfxEngine = new SfxEngine();

    public LuaBinding(string script)
    {
        _sfxEngine.LoadSfxs(FileIO.SplitData(FileIO.Read(Constants.File.Name, Constants.File.Extensions.Sfx)));
        _lua = new NLua.Lua();
        _lua.UseTraceback = true;

        // sfx
        _lua.RegisterFunction("sfx", this, GetType().GetMethod("Sfx"));

        // input
        _lua.RegisterFunction("btn", this, GetType().GetMethod("Pressed"));
        _lua.RegisterFunction("btnp", this, GetType().GetMethod("JustPressed"));
        _lua.RegisterFunction("btnr", this, GetType().GetMethod("Released"));

        // draw
        _lua.RegisterFunction("line", this, GetType().GetMethod("DrawLine"));

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

    #region functions
    public static void Sfx(int index)
    {
        _sfxEngine.Sfx(index);
    }

    public static bool JustPressed(int keyNumber)
    {
        if (!Enum.IsDefined(typeof(Keys), keyNumber))
        {
            return false;
        }

        return input.KeyboardInput.JustPressed((Keys)keyNumber);
    }

    public static bool Released(int keyNumber)
    {
        if (!Enum.IsDefined(typeof(Keys), keyNumber))
        {
            return false;
        }

        return input.KeyboardInput.Released((Keys)keyNumber);
    }

    public static bool Pressed(int keyNumber)
    {
        if (!Enum.IsDefined(typeof(Keys), keyNumber))
        {
            return false;
        }

        return input.KeyboardInput.Pressed((Keys)keyNumber);
    }

    public static void DrawLine(int x0, int y0, int x1, int y1, int colorIndex = 1, int transparency = 10)
    {
        PixelledShapes.DrawLine(x0, y0, x1, y1, ColorPalette.GetColor(colorIndex, transparency));
    }
    #endregion

    public void Unload()
    {
        _sfxEngine.Sfx(-1);   // stop all channels
        _sfxEngine.Dispose();
    }
}
