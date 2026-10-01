namespace mono8;

public class Mono8Game : Game
{
    internal static Mono8Game Instance;
    private GraphicsDeviceManager _graphics;
    public static PixelledSpriteBatch SpriteBatch;
    internal static Mono8API GameAPI;
    private RenderTarget2D sceneTarget;
    public static GraphicsDevice GraphicsDeviceRef;
    public static int DisplayFps = 0;
    private const double TargetFps = 30.0;
    private double _elapsedTime = 0;
    private int _fpsCounter = 0;
    private Intro _intro = new Intro();

    public Mono8Game()
    {
        Instance = this;
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
        ErrorHandler.Reset();
        GameAPI = new Mono8API();
    }

    protected override void Initialize()
    {
        TargetElapsedTime = TimeSpan.FromSeconds(1.0 / TargetFps);
        base.Initialize();
    }

    // Called by the web head when the browser canvas is resized, passing the new canvas size (in CSS
    // pixels). Re-derives the render resolution and recomputes the letterbox box. The dimensions must
    // come from JS: KNI's GL viewport does not reflect a canvas.width/height change until the backbuffer
    // is re-applied, so reading it back would be stale. The fixed 256x144 sceneTarget does not need
    // recreating. No-op harm on desktop.
    public void RecomputeScreen(int width, int height)
    {
        Screen.SetResolution(_graphics, GraphicsDevice, width, height);
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
#if !BLAZORGL
        // The browser window owns its own position; KNI's BlazorGL GameWindow has no Position setter.
        Window.Position = new Point(window.ClientBounds.X, window.ClientBounds.Y);
#endif
    }

    protected override void LoadContent()
    {
        GraphicsDeviceRef = GraphicsDevice;
        Screen.SetResolution(_graphics, GraphicsDevice);
        SpriteBatch = new PixelledSpriteBatch(GraphicsDevice);
        _graphics.SynchronizeWithVerticalRetrace = true;
        // The scene is authored at the native 256x144 resolution and blitted (stretched) to
        // Screen.BoxToDraw. Size the target to the base resolution explicitly so the blit source is
        // always the true 256x144 scene; otherwise the browser's full-canvas backbuffer would make
        // this target canvas-sized and throw off both the render and the mouse->virtual mapping.
        sceneTarget = new RenderTarget2D(
            GraphicsDevice,
            Constants.Screen.ResolutionX,
            Constants.Screen.ResolutionY,
            false,
            SurfaceFormat.Color,
            DepthFormat.None);
        Text.GetCharacterTextures(GraphicsDevice);
        LoadFiles();
    }

    protected override void Update(GameTime gameTime)
    {
#if !BLAZORGL
        // A browser tab cannot quit itself, and desktop display-mode fullscreen is meaningless in
        // the browser (the tab owns its own fullscreen via the Fullscreen API). Desktop only.
        if (KeybrdInput.IsAltF4Pressed())
            Exit();

        if (KeybrdInput.IsF2Released())
        {
            Screen.ToggleFullScreen(_graphics, GraphicsDevice);
        }
#endif

        if (!_intro.IsFinished)
        {
            _intro.Update(gameTime);
            base.Update(gameTime);
            return;
        }

        if (GameAPI.IsPlayingGame)
        {
            Menu.Update();
        }
        Screen.UpdateIsFocused(IsActive, _graphics.IsFullScreen);
        InputStateManager.Update();
        GameAPI.Update(gameTime);
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.SetRenderTarget(sceneTarget);
        GraphicsDevice.Clear(Color.Black);
        Camera2D.Camera(0, 0);
        SpriteBatch.Begin();
        if (_intro.IsFinished)
        {
            GameAPI.Draw();
        }
        else
        {
            _intro.Draw(GameAPI);
        }
        SpriteBatch.End();
        GraphicsDevice.SetRenderTarget(null);
        GraphicsDevice.Clear(Color.Black);
        SpriteBatch.Begin(SpriteSortMode.Immediate, BlendState.Opaque, SamplerState.PointClamp, effect: null);
        SpriteBatch.Draw(sceneTarget, Screen.BoxToDraw, -1);
        SpriteBatch.End();
        SpriteBatch.Begin(SamplerState.PointClamp);
        DrawGameBorder();
        SpriteBatch.End();

        _elapsedTime += gameTime.ElapsedGameTime.TotalSeconds;
        _fpsCounter++;

        if (_elapsedTime >= 1.0)
        {
            DisplayFps = _fpsCounter;
            _fpsCounter = 0;
            _elapsedTime -= 1.0;
        }

        base.Draw(gameTime);
    }

    protected override void UnloadContent()
    {
        GameAPI.Unload();
        base.UnloadContent();
    }

    public void DrawGameBorder()
    {
        var viewport = GraphicsDevice.Viewport.Bounds;
        var hole = Screen.ScaleRectangle(Screen.BaseBox);
        var colorIndex = ColorPalette.BlackColorIndex;
        SpriteBatch.DrawRectFill(viewport.X, viewport.Y, viewport.Width, viewport.Y + hole.Y, colorIndex);
        SpriteBatch.DrawRectFill(viewport.X, hole.Bottom, viewport.Width, viewport.Bottom - hole.Bottom, colorIndex);
        SpriteBatch.DrawRectFill(viewport.X, hole.Y, hole.X - viewport.X, hole.Height, colorIndex);
        SpriteBatch.DrawRectFill(hole.Right, hole.Y, viewport.Right - hole.Right, hole.Height, colorIndex);
    }
}