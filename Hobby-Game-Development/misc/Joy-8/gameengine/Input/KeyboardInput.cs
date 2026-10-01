using Microsoft.Xna.Framework.Input;
using System.Collections.Generic;

namespace gameengine.Input;

internal class KeyboardInput
{
    public static Keys GetAlphaNumericTextFieldJustPressedKeys()
    {
        foreach (var key in InputStateManager.CurrentKeyboardState().GetPressedKeys())
        {
            var keysToCheck = new List<Keys> { Keys.Back, Keys.Delete, Keys.Left, Keys.Right, Keys.Space };

            if (!(key >= Keys.A && key <= Keys.Z) 
                && !(key >= Keys.D0 && key <= Keys.D9)
                && !keysToCheck.Contains(key))
            {
                continue;
            }

            if (JustPressed(key))
            {
                return key;
            }
        }

        return Keys.None;
    }

    public static bool IsAltF4Pressed()
    {
        return Pressed(Keys.LeftAlt) && Pressed(Keys.F4);
    } 
    
    public static bool IsEscPressed()
    {
        return Pressed(Keys.Escape);
    }

    public static bool IsSpacedJustPressed()
    {
        return JustPressed(Keys.Space);
    }

    public static bool IsF2Released()
    {
        return Released(Keys.F2);
    }

    public static bool IsUpPressed()
    {
        return Pressed(Keys.Up);
    }
    public static bool IsDownPressed()
    {
        return Pressed(Keys.Down);
    }

    public static bool IsLeftPressed()
    {
        return Pressed(Keys.Left);
    }

    public static bool IsRightPressed()
    {
        return Pressed(Keys.Right);
    }

    public static bool IsShiftPressed()
    {
        return Pressed(Keys.LeftShift) || Pressed(Keys.RightShift);
    }

    public static bool IsControlPressed()
    {
        return Pressed(Keys.LeftControl) || Pressed(Keys.RightControl);
    }

    private static bool JustPressed(Keys key)
    {
        return InputStateManager.CurrentKeyboardState()[key] == KeyState.Down && InputStateManager.PreviousKeyboardState()[key] == KeyState.Up;
    }

    private static bool Released(Keys key)
    {
        return InputStateManager.CurrentKeyboardState()[key] == KeyState.Up && InputStateManager.PreviousKeyboardState()[key] == KeyState.Down;
    }

    private static bool Pressed(Keys currentKey)
    {
        return InputStateManager.CurrentKeyboardState()[currentKey] == KeyState.Down;
    }
}
