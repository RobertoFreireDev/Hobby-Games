using MoonSharp.Interpreter;

namespace mono8.core.common;

public static class ErrorHandler
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
        // Always log the full exception (type, message, stack trace) to the browser console.
        Console.Error.WriteLine(ex);

        var message = string.Empty;

        if (!string.IsNullOrWhiteSpace(ex?.Source))
        {
            message += ex.Source + "\n";
        }

        // MoonSharp Lua errors (syntax/runtime) put the source location (chunk:line) in
        // DecoratedMessage; the plain Message drops it (e.g. just "unexpected symbol near '_init'").
        message += ex is InterpreterException lua && !string.IsNullOrWhiteSpace(lua.DecoratedMessage)
            ? lua.DecoratedMessage
            : ex?.Message;

        SetErrorInternal(message);
    }

    public static void SetError(string message)
    {
        // Always log the full error message to the browser console.
        Console.Error.WriteLine(message);

        SetErrorInternal(message);
    }

    private static void SetErrorInternal(string message)
    {
        Mono8Game.GameAPI?.StopSounds();
        _error = true;
        _message = message;
    }

    public static void Draw()
    {
        Mono8Game.SpriteBatch.DrawBaseBox(-2);
        Text.DrawText(_message, new Vector2(2, 2), -1, true);
    }
}