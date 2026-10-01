namespace mono8.core.lua;

/// <summary>
/// Holds the cartridge's Lua game source — the <c>__lua__</c> section of <c>data.mono8</c>. Unlike the
/// sprite/map/sfx sheets this is raw text rather than a parsed structure, but it plugs into the same
/// load/serialize pipeline (<see cref="mono8.core.common.DataFile"/>) so the Lua code round-trips
/// through the single cartridge file. The stored source is capped at
/// <see cref="Constants.GameDataSizes.LuaMaxLength"/> characters.
/// </summary>
public class LuaSheet
{
    private string _code = string.Empty;

    /// <summary>The current Lua source (never null; empty when the cartridge has no script).</summary>
    public string Code => _code;

    /// <summary>Load the <c>__lua__</c> section body, supplied as lines (DataFile/PICO-8 style).</summary>
    public void LoadLua(string[] lines) => _code = Clamp(string.Join("\n", lines ?? Array.Empty<string>()));

    /// <summary>Replace the current Lua source (e.g. from an editor), enforcing the length cap.</summary>
    public void SetCode(string code) => _code = Clamp(code);

    /// <summary>Serialize back to the <c>__lua__</c> section body written into <c>data.mono8</c>.</summary>
    public string ToLuaText() => _code;

    // Enforce the character cap so a cartridge can't carry an unbounded script.
    private static string Clamp(string code)
    {
        if (string.IsNullOrEmpty(code)) return string.Empty;
        return code.Length > Constants.GameDataSizes.LuaMaxLength
            ? code.Substring(0, Constants.GameDataSizes.LuaMaxLength)
            : code;
    }
}
