using GameEngine.Enums;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace GameEngine.Utils;

public static class InputUtils
{
    private static KeyboardState _currentKeyboardState;
    private static GamePadState _currentGamePadState;
    private static KeyboardState _previousKeyboardState;
    private static GamePadState _previousGamePadState;
    private static float _sensibility = GameConstants.Constants.Config.InputSensibility;

    public static bool IsKeyDown(InputEnum inputkey)
    {
        _currentKeyboardState = Keyboard.GetState();
        _currentGamePadState = GamePad.GetState(PlayerIndex.One);

        return IsKeyDown(inputkey, _currentKeyboardState, _currentGamePadState);
    }

    public static bool IsKeyJustPressed(InputEnum inputkey)
    {
        _currentKeyboardState = Keyboard.GetState();
        _currentGamePadState = GamePad.GetState(PlayerIndex.One);

        return IsKeyDown(inputkey, _currentKeyboardState, _currentGamePadState) 
            && !IsKeyDown(inputkey, _previousKeyboardState, _previousGamePadState);
    }

    public static bool IsKeyReleased(InputEnum inputkey)
    {
        _currentKeyboardState = Keyboard.GetState();
        _currentGamePadState = GamePad.GetState(PlayerIndex.One);

        return !IsKeyDown(inputkey, _currentKeyboardState, _currentGamePadState)
            && IsKeyDown(inputkey, _previousKeyboardState, _previousGamePadState);
    }

    public static void UpdatePreviousState()
    {
        _previousKeyboardState = _currentKeyboardState;
        _previousGamePadState = _currentGamePadState;
    }

    private static bool IsKeyDown(InputEnum inputkey, KeyboardState keyboard, GamePadState gamepad)
    {
        var result = false;

        switch (inputkey)
        {
            case InputEnum.LEFT:
                result = keyboard.IsKeyDown(Keys.Left) || gamepad.ThumbSticks.Left.X < -_sensibility || gamepad.DPad.Left == ButtonState.Pressed;
                break;
            case InputEnum.RIGHT:
                result = keyboard.IsKeyDown(Keys.Right) || gamepad.ThumbSticks.Left.X > _sensibility || gamepad.DPad.Right == ButtonState.Pressed;
                break;
            case InputEnum.UP:
                result = keyboard.IsKeyDown(Keys.Up) || gamepad.ThumbSticks.Left.Y > _sensibility || gamepad.DPad.Up == ButtonState.Pressed;
                break;
            case InputEnum.DOWN:
                result = keyboard.IsKeyDown(Keys.Down) || gamepad.ThumbSticks.Left.Y < -_sensibility || gamepad.DPad.Down == ButtonState.Pressed;
                break;
            case InputEnum.ESCAPE:
                result = keyboard.IsKeyDown(Keys.Escape) || gamepad.Buttons.Back == ButtonState.Pressed; ;
                break;
            case InputEnum.ENTER:
                result = keyboard.IsKeyDown(Keys.Enter) || gamepad.Buttons.Start == ButtonState.Pressed;
                break;
        }

        return result;
    }
}