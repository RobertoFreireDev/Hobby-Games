using blackbox.Binding;
using blackbox.IOFile;
using System;

namespace blackbox.Utils;

public static class LuaError
{
    private static string _message = string.Empty;
    private static bool _error = false;

    public static void Reset()
    {
        _message = string.Empty;
        _error = false;
    }

    public static bool HasError()
    {
        return _error;
    }

    public static void SetError(Exception ex)
    {
        var message = ex.Message;

        if (!string.IsNullOrWhiteSpace(ex?.Source))
        {
            message += "\n" + "Source: " + ex.Source;
        }

        if (!string.IsNullOrWhiteSpace(ex?.InnerException?.Message))
        {
            message += "\n" + "Inner Ex: " + ex.InnerException.Message;
        }

        SetError(message);
    }

    public static void SetError(string message)
    {
        ColorUtils.SetDefaultalette();
        LuaBinding.EnableCRTshader(false);
        _error = true;
        _message = message;
        TableIO.InsertRow(SystemLogs.Table, new string[] { DateTime.UtcNow.ToString(), SystemLogs.TypeError, message });
    }

    public static void Draw()
    {
        LuaBinding.DrawRectFill(
            ScreenUtils.BaseBox.X,
            ScreenUtils.BaseBox.Y,
            ScreenUtils.BaseBox.Width,
            ScreenUtils.BaseBox.Height,
            0);
        LuaBinding.Print(_message, 2, 2, 1, true);
    }
}
