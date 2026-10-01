using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace MONO_32.Engine.Input;

public static class InputUtils
{
    private static KeyboardState _currentKeyboardState;
    private static KeyboardState _previousKeyboardState;
    private static MouseState _currentMouseState;
    private static MouseState _previousMouseState;

    public static void Update()
    {
        _previousKeyboardState = _currentKeyboardState;
        _currentKeyboardState = Keyboard.GetState();

        _previousMouseState = _currentMouseState;
        _currentMouseState = Mouse.GetState();
    }

    public static bool IsControlZReleased()
    {
        var controlDown = _currentKeyboardState.IsKeyDown(Keys.LeftControl) || _currentKeyboardState.IsKeyDown(Keys.RightControl);
        var zReleased = _previousKeyboardState.IsKeyDown(Keys.Z) && !_currentKeyboardState.IsKeyDown(Keys.Z);
        return controlDown && zReleased;
    }

    public static bool IsMouseLeftButtonPressed()
    {
        return _currentMouseState.LeftButton == ButtonState.Pressed;
    }

    public static Point MousePosition()
    {
        return _currentMouseState.Position;
    }

    public static bool IsMouseLeftButtonJustPressed()
    {
        return _currentMouseState.LeftButton == ButtonState.Pressed && _previousMouseState.LeftButton != ButtonState.Pressed;
    }

    public static bool IsMouseLeftButtonReleased()
    {
        return _currentMouseState.LeftButton != ButtonState.Pressed && _previousMouseState.LeftButton == ButtonState.Pressed;
    }

    public static Keys[] GetReleasedKeys()
    {
        return _previousKeyboardState.GetPressedKeys()
                .Where(key => !_currentKeyboardState.IsKeyDown(key))
                .ToArray();
    }

    public static bool IsKeyPressed(Keys key)
    {
        return _currentKeyboardState.IsKeyDown(key);
    }
}