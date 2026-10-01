using Microsoft.Xna.Framework.Input;

namespace blackbox.Input;

public static class KeyboardInput
{
    public static bool IsAltF4Pressed()
    {
        return Pressed(Keys.LeftAlt) && Pressed(Keys.F4);
    }

    public static bool IsEscPressed()
    {
        return Pressed(Keys.Escape);
    }

    public static bool IsF2Released()
    {
        return Released(Keys.F2);
    }

    public static bool JustPressed(Keys key)
    {
        return InputStateManager.CurrentKeyboardState()[key] == KeyState.Down && InputStateManager.PreviousKeyboardState()[key] == KeyState.Up;
    }

    public static bool Released(Keys key)
    {
        return InputStateManager.CurrentKeyboardState()[key] == KeyState.Up && InputStateManager.PreviousKeyboardState()[key] == KeyState.Down;
    }

    public static bool Pressed(Keys key)
    {
        return InputStateManager.CurrentKeyboardState()[key] == KeyState.Down;
    }
}
