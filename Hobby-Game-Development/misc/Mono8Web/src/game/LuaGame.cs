using System.Linq;
using System.Text;
using MoonSharp.Interpreter;

namespace mono8.game;

/// <summary>
/// Runs the cartridge's Lua game. The Lua source lives in the <c>__lua__</c> section of
/// <c>data.mono8</c> (see <see cref="mono8.core.lua.LuaSheet"/>) and is compiled fresh each time the
/// game is launched (the Esc state cycle). The whole PICO-8-style API (see <see cref="IMono8API"/>) is exposed to
/// Lua as global functions, and the standard <c>_init</c>/<c>_update</c>/<c>_draw</c> entry points are
/// called by the engine — matching PICO-8 conventions.
///
/// MoonSharp is a pure-C# Lua interpreter, so the same code runs under both heads (desktop and the
/// WASM web head) with no native dependency. Any syntax or runtime error surfaces as an exception,
/// which <see cref="Mono8API"/> catches and hands to the on-screen <see cref="ErrorHandler"/>.
/// </summary>
internal class LuaGame : IEditor
{
    public static IMono8API API;

    private Script _script;
    private DynValue _update;
    private DynValue _draw;
    private string _message;

    public LuaGame(IMono8API api)
    {
        API = api;
    }

    // (Re)compile the current cartridge Lua and run its _init. Called on every launch, so edits to the
    // __lua__ section take effect on the next launch without restarting the engine.
    public void Init()
    {
        try
        {
            _script = null;
            _update = _draw = null;
            _message = null;

            var code = Mono8API.LuaSheet.Code;
            if (string.IsNullOrWhiteSpace(code))
            {
                _message = "NO LUA CODE";
                return;
            }

            // Reflection interop only: the WASM head has no Reflection.Emit, so avoid MoonSharp's codegen.
            UserData.DefaultAccessMode = InteropAccessMode.Reflection;
            UserData.RegisterType<IMono8API>();

            var script = new Script(CoreModules.Preset_SoftSandbox);
            script.Globals.Set("__api", UserData.Create(API, UserData.GetDescriptorForType<IMono8API>(true)));
            script.DoString(ApiBindingPreamble());
            script.DoString(code);

            _script = script;
            _update = script.Globals.Get("_update");
            _draw = script.Globals.Get("_draw");

            var init = script.Globals.Get("_init");
            if (init.Type == DataType.Function) script.Call(init);
        }
        catch (Exception ex) { ErrorHandler.SetError(ex); }
    }

    public void Update(float elapsedSeconds)
    {
        try
        {
            if (_script != null && _update.Type == DataType.Function)
                _script.Call(_update, elapsedSeconds);
        }
        catch (Exception ex) { ErrorHandler.SetError(ex); }
    }

    public void Draw()
    {
        try
        {
            if (_script != null && _draw.Type == DataType.Function)
            {
                _script.Call(_draw);
                return;
            }

            // No _draw (e.g. an empty cartridge): show a hint instead of a blank screen.
            if (_message != null)
            {
                API.cls(Constants.Colors.DarkBlue);
                API.print(_message, 8, 8, Constants.Colors.White);
            }
        }
        catch (Exception ex) { ErrorHandler.SetError(ex); }
    }

    // Expose every IMono8API method as a flat global Lua function (PICO-8 style: spr, map, btn, …),
    // each delegating to the registered api userdata. Generated from the interface so the Lua surface
    // never drifts from the C# API, and MoonSharp resolves overloads/optional args at call time.
    private static string ApiBindingPreamble()
    {
        var sb = new StringBuilder();
        foreach (var name in typeof(IMono8API).GetMethods().Select(m => m.Name).Distinct())
            sb.Append("function ").Append(name).Append("(...) return __api:").Append(name).Append("(...) end\n");
        return sb.ToString();
    }
}
