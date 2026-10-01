namespace mono8.core.input;

public static class InputStateManager
{
    private static KeyboardState _currentKeyboardState;
    private static KeyboardState _previousKeyboardState;
    private static MouseState _currentMouseState;
    private static MouseState _previousMouseState;

    // When a host file dialog (cart Save/Load) opens on a left-click, the dismissing/opening mouse-up
    // fires over the OS dialog, not the canvas, so KNI's left-button state stays stuck at Pressed after
    // the dialog closes. That makes mousel()/mouselp() report input every frame until a real click
    // delivers the missing mouse-up. While this latch is set, the left button reads as unpressed; it
    // clears once the button has genuinely settled to Released again.
    private static bool _suppressLeftUntilReleased;
    private static readonly Dictionary<PlayerIndex, GamePadState> _previousGamePadStates = new();
    private static readonly Dictionary<PlayerIndex, GamePadState> _currentGamePadStates = new();

    public static KeyboardState CurrentKeyboardState()
    {
        return _currentKeyboardState;
    }

    public static KeyboardState PreviousKeyboardState()
    {
        return _previousKeyboardState;
    }

    public static MouseState CurrentMouseState()
    {
        return _currentMouseState;
    }

    public static MouseState PreviousMouseState()
    {
        return _previousMouseState;
    }

    /// <summary>Ignore the left mouse button until it is genuinely released again. Called when a host
    /// file dialog is dismissed so a stuck "pressed" state (the mouse-up was eaten by the OS dialog)
    /// doesn't leak a phantom click/drag into the editors on resume.</summary>
    public static void SuppressLeftButtonUntilReleased()
    {
        _suppressLeftUntilReleased = true;
    }

    public static bool IsLeftButtonSuppressed()
    {
        return _suppressLeftUntilReleased;
    }

    public static GamePadState CurrentGamePadState(PlayerIndex index)
    {
        if (_currentGamePadStates.TryGetValue(index, out var state))
            return state;

        return GamePad.GetState(index);
    }

    public static GamePadState PreviousGamePadState(PlayerIndex index)
    {
        if (_previousGamePadStates.TryGetValue(index, out var state))
            return state;

        return GamePad.GetState(index);
    }

    public static bool IsGamePadConnected(PlayerIndex index)
    {
        return _currentGamePadStates.ContainsKey(index) && _currentGamePadStates[index].IsConnected;
    }

    public static void Update()
    {
        _previousKeyboardState = _currentKeyboardState;
        _currentKeyboardState = Keyboard.GetState();

        _previousMouseState = _currentMouseState;
        _currentMouseState = Mouse.GetState();

        // Clear the latch only once the button has fully settled to Released across both frames, so the
        // Pressed->Released transition frame is still swallowed and doesn't surface a phantom mouselr.
        if (_suppressLeftUntilReleased
            && _currentMouseState.LeftButton == ButtonState.Released
            && _previousMouseState.LeftButton == ButtonState.Released)
        {
            _suppressLeftUntilReleased = false;
        }

        foreach (var index in Enum.GetValues<PlayerIndex>())
        {
            _previousGamePadStates[index] = _currentGamePadStates.ContainsKey(index)
                ? _currentGamePadStates[index]
                : GamePad.GetState(index);
        }

        foreach (var index in Enum.GetValues<PlayerIndex>())
        {
            _currentGamePadStates[index] = GamePad.GetState(index);
        }
    }
}
