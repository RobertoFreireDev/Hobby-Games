namespace cut2;

public class cut2 : Game
{
    private GraphicsDeviceManager _graphics;
    public static PixelledSpriteBatch SpriteBatch;
    internal static LuaBinding LuaProgram;
    private RenderTarget2D sceneTarget;
    public static GraphicsDevice GraphicsDeviceRef;

    public cut2()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        Window.AllowUserResizing = true;
        IsMouseVisible = true;
        ColorPalette.SetColorPalette();
        IsFixedTimeStep = true;
        Window.ClientSizeChanged += OnResize;
    }

    public void LoadFiles()
    {
        LuaError.Reset();
        LuaProgram = new LuaBinding();
    }

    protected override void Initialize()
    {
        TargetElapsedTime = TimeSpan.FromSeconds(1.0 / 60.0);
        base.Initialize();
    }

    private void OnResize(Object sender, EventArgs e)
    {
        if (sender is not GameWindow)
        {
            return;
        }

        var window = (GameWindow)sender;

        if (window.ClientBounds.Width == _graphics.PreferredBackBufferWidth && window.ClientBounds.Height == _graphics.PreferredBackBufferHeight)
        {
            return;
        }

        Screen.SetResolution(_graphics, GraphicsDevice, window.ClientBounds.Width, window.ClientBounds.Height);
        Window.Position = new Point(window.ClientBounds.X, window.ClientBounds.Y);
    }

    protected override void LoadContent()
    {
        GraphicsDeviceRef = GraphicsDevice;
        Screen.SetResolution(_graphics, GraphicsDevice);
        SpriteBatch = new PixelledSpriteBatch(GraphicsDevice);
        _graphics.SynchronizeWithVerticalRetrace = true;
        sceneTarget = new RenderTarget2D(
            GraphicsDevice,
            GraphicsDevice.PresentationParameters.BackBufferWidth,
            GraphicsDevice.PresentationParameters.BackBufferHeight,
            false,
            SurfaceFormat.Color,
            DepthFormat.None);
        Text.GetCharacterTextures(GraphicsDevice);
        LoadFiles();
    }

    protected override void Update(GameTime gameTime)
    {
        if (KeybrdInput.IsAltF4Pressed())
            Exit();

        if (KeybrdInput.IsF2Released())
        {
            Screen.ToggleFullScreen(_graphics, GraphicsDevice);
        }

        Screen.UpdateIsFocused(IsActive, _graphics.IsFullScreen);
        InputStateManager.Update();
        LuaProgram.Update(gameTime);
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.SetRenderTarget(sceneTarget);
        GraphicsDevice.Clear(Color.Black);
        SpriteBatch.Begin();
        LuaProgram.Draw();
        SpriteBatch.End();
        GraphicsDevice.SetRenderTarget(null);
        GraphicsDevice.Clear(Color.Black);
        SpriteBatch.Begin(SpriteSortMode.Immediate, BlendState.Opaque, SamplerState.PointClamp, effect: null);
        SpriteBatch.Draw(sceneTarget, Screen.BoxToDraw, -1);
        SpriteBatch.End();
        SpriteBatch.Begin(SamplerState.PointClamp);
        DrawGameBorder();
        SpriteBatch.End();
        base.Draw(gameTime);
    }

    protected override void UnloadContent()
    {
        LuaProgram.Unload();
        base.UnloadContent();
    }

    public void DrawGameBorder()
    {
        var viewport = GraphicsDevice.Viewport.Bounds;
        var hole = Screen.ScaleRectangle(Screen.BaseBox);
        var color = Color.Black;
        SpriteBatch.DrawRectFill(viewport.X, viewport.Y, viewport.Width, viewport.Y + hole.Y, color);
        SpriteBatch.DrawRectFill(viewport.X, hole.Bottom, viewport.Width, viewport.Bottom - hole.Bottom, color);
        SpriteBatch.DrawRectFill(viewport.X, hole.Y, hole.X - viewport.X, hole.Height, color);
        SpriteBatch.DrawRectFill(hole.Right, hole.Y, viewport.Right - hole.Right, hole.Height, color);
    }
}