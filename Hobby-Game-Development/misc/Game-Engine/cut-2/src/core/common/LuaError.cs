namespace cut2.core.common;

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
        var message = string.Empty;

        if (!string.IsNullOrWhiteSpace(ex?.Source))
        {
            message += ex.Source;
        }

        message += ex.Message;

        SetError(message);
    }

    public static void SetError(string message)
    {
        cut2.LuaProgram?.StopSounds();
        _error = true;
        _message = message;
    }

    public static void Draw()
    {
        cut2.SpriteBatch.DrawRectFill(
            Screen.BaseBox.X,
            Screen.BaseBox.Y,
            Screen.BaseBox.Width,
            Screen.BaseBox.Height,
            -2);
        Text.DrawText(_message, new Vector2(2, 2), -1, true);
    }
}