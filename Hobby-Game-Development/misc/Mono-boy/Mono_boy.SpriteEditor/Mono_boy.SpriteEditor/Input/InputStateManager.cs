using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace Mono_boy.SpriteEditor.Input;

public static class InputStateManager
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

    public static Point MousePosition()
    {
        return _currentMouseState.Position;
    }

    public static bool IsMouseLeftButtonJustPressed()
    {
        return _currentMouseState.LeftButton == ButtonState.Pressed && _previousMouseState.LeftButton == ButtonState.Released;
    }

    public static bool IsMouseLeftButtonReleased()
    {
        return _currentMouseState.LeftButton == ButtonState.Released && _previousMouseState.LeftButton == ButtonState.Pressed;
    }

    public static bool IsMouseLeftButtonPressed()
    {
        return _currentMouseState.LeftButton == ButtonState.Pressed;
    }

    public static bool IsMouseRightButtonPressed()
    {
        return _currentMouseState.RightButton == ButtonState.Pressed;
    }

    public static bool IsKeyEscapePressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.Escape);
    }

    public static bool IsControlZReleased()
    {
        var controlDown = _currentKeyboardState.IsKeyDown(Keys.LeftControl) || _currentKeyboardState.IsKeyDown(Keys.RightControl);
        var zReleased = _previousKeyboardState.IsKeyDown(Keys.Z) && !_currentKeyboardState.IsKeyDown(Keys.Z);
        return controlDown && zReleased;
    }

    public static bool IsControlPressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.LeftControl) || _currentKeyboardState.IsKeyDown(Keys.RightControl);
    }

    public static bool IsF11Released()
    {
        return _previousKeyboardState.IsKeyDown(Keys.F11) && !_currentKeyboardState.IsKeyDown(Keys.F11);
    }

    public static bool IsF10Released()
    {
        return _previousKeyboardState.IsKeyDown(Keys.F10) && !_currentKeyboardState.IsKeyDown(Keys.F10);
    }

    public static bool IsSpaceReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.Space) && !_currentKeyboardState.IsKeyDown(Keys.Space);
    }

    public static bool IsRReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.R) && !_currentKeyboardState.IsKeyDown(Keys.R);
    }

    public static bool IsTReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.T) && !_currentKeyboardState.IsKeyDown(Keys.T);
    }

    public static bool IsQReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.Q) && !_currentKeyboardState.IsKeyDown(Keys.Q);
    }

    public static bool IsWReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.W) && !_currentKeyboardState.IsKeyDown(Keys.W);
    }

    public static bool IsZReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.Z) && !_currentKeyboardState.IsKeyDown(Keys.Z);
    }

    public static bool IsXReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.X) && !_currentKeyboardState.IsKeyDown(Keys.X);
    }

    public static bool IsNReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.N) && !_currentKeyboardState.IsKeyDown(Keys.N);
    }

    public static bool IsMReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.M) && !_currentKeyboardState.IsKeyDown(Keys.M);
    }

    public static bool Is0Pressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.NumPad0);
    }

    public static bool Is1Pressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.NumPad1);
    }

    public static bool Is2Pressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.NumPad2);
    }

    public static bool Is3Pressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.NumPad3);
    }

    public static bool Is4Pressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.NumPad4);
    }

    public static bool Is5Pressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.NumPad5);
    }

    public static bool Is6Pressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.NumPad6);
    }

    public static bool Is7Pressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.NumPad7);
    }

    public static bool Is8Pressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.NumPad8);
    }

    public static bool Is9Pressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.NumPad9);
    }

    public static bool IsAReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.A) && !_currentKeyboardState.IsKeyDown(Keys.A);
    }

    public static bool IsSReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.S) && !_currentKeyboardState.IsKeyDown(Keys.S);
    }

    public static bool IsDReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.D) && !_currentKeyboardState.IsKeyDown(Keys.D);
    }

    public static bool IsFReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.F) && !_currentKeyboardState.IsKeyDown(Keys.F);
    }

    public static bool IsGReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.G) && !_currentKeyboardState.IsKeyDown(Keys.G);
    }

    public static bool IsHReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.H) && !_currentKeyboardState.IsKeyDown(Keys.H);
    }

    public static bool IsJReleased()
    {
        return _previousKeyboardState.IsKeyDown(Keys.J) && !_currentKeyboardState.IsKeyDown(Keys.J);
    }

    public static bool IsUpPressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.Up);
    }

    public static bool IsDownPressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.Down);
    }

    public static bool IsLeftPressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.Left);
    }

    public static bool IsRightPressed()
    {
        return _currentKeyboardState.IsKeyDown(Keys.Right);
    }

    public static bool IsUpJustPressed()
    {
        return IsKeyJustPressed(Keys.Up);
    }

    public static bool IsDownJustPressed()
    {
        return IsKeyJustPressed(Keys.Down);
    }

    public static bool IsLeftJustPressed()
    {
        return IsKeyJustPressed(Keys.Left);
    }

    public static bool IsRightJustPressed()
    {
        return IsKeyJustPressed(Keys.Right);
    }

    public static bool IsBackJustPressed()
    {
        return IsKeyJustPressed(Keys.Back);
    }

    public static bool IsDelJustPressed()
    {
        return IsKeyJustPressed(Keys.Delete);
    }

    public static bool IsEnterJustPressed()
    {
        return IsKeyJustPressed(Keys.Enter);
    }

    public static bool IsTabJustPressed()
    {
        return IsKeyJustPressed(Keys.Tab);
    }

    public static char GetCharJustPressed()
    {
        foreach (Keys key in _currentKeyboardState.GetPressedKeys())
        {
            if (IsKeyJustPressed(key))
            {
                return GetCharPressed(key);
            }
        }

        return '\0';
    }

    public static Keys[] GetPressedKeys()
    {
        return _currentKeyboardState.GetPressedKeys();
    }

    public static bool IsPreviousPressed(Keys key)
    {
        return _previousKeyboardState.IsKeyUp(key);
    }

    private static bool IsKeyJustPressed(Keys key)
    {
        return _currentKeyboardState.IsKeyDown(key) && !_previousKeyboardState.IsKeyDown(key);
    }

    public static char GetCharPressed(Keys key)
    {
        switch (key)
        {
            default:
                if (key >= Keys.A && key <= Keys.Z)
                {
                    if (IsShiftPressed())
                        return (char)key;
                    else
                        return key.ToString().ToLower()[0];
                }
                break;

            case (Keys.D1):
                if (IsShiftPressed())
                    return '!';
                else
                    return '1';
            case (Keys.D2):
                if (IsShiftPressed())
                    return '@';
                else
                    return '2';
            case (Keys.D3):
                if (IsShiftPressed())
                    return '#';
                else
                    return '3';
            case (Keys.D4):
                if (IsShiftPressed())
                    return '$';
                else
                    return '4';
            case (Keys.D5):
                if (IsShiftPressed())
                    return '%';
                else
                    return '5';
            case (Keys.D6):
                if (IsShiftPressed())
                    return '^';
                else
                    return '6';
            case (Keys.D7):
                if (IsShiftPressed())
                    return '&';
                else
                    return '7';
            case (Keys.D8):
                if (IsShiftPressed())
                    return '*';
                else
                    return '8';
            case (Keys.D9):
                if (IsShiftPressed())
                    return '(';
                else
                    return '9';
            case (Keys.D0):
                if (IsShiftPressed())
                    return ')';
                else
                    return '0';
            case (Keys.OemComma):
                if (IsShiftPressed())
                    return '<';
                else
                    return ',';
            case Keys.OemPeriod:
                if (IsShiftPressed())
                    return '>';
                else
                    return '.';
            case Keys.OemQuestion:
                if (IsShiftPressed())
                    return '?';
                else
                    return '/';
            case Keys.OemSemicolon:
                if (IsShiftPressed())
                    return ':';
                else
                    return ';';
            case Keys.OemQuotes:
                if (IsShiftPressed())
                    return '"';
                else
                    return '\'';
            case Keys.OemBackslash:
                if (IsShiftPressed())
                    return '|';
                else
                    return '\\';
            case Keys.OemOpenBrackets:
                if (IsShiftPressed())
                    return '{';
                else
                    return '[';
            case Keys.OemCloseBrackets:
                if (IsShiftPressed())
                    return '}';
                else
                    return ']';
            case Keys.OemMinus:
                if (IsShiftPressed())
                    return '_';
                else
                    return '-';
            case Keys.OemPlus:
                if (IsShiftPressed())
                    return '+';
                else
                    return '=';
            case Keys.Space:
                return ' ';
        }

        return '\0';
    }

    private static bool IsShiftPressed()
    {
        return _currentKeyboardState[Keys.LeftShift] == KeyState.Down || _currentKeyboardState[Keys.RightShift] == KeyState.Down;
    }
}