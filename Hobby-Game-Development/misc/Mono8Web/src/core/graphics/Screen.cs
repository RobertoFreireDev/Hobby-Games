namespace mono8.core.graphics;

internal static class Screen
{
    public static Rectangle BoxToDraw;
    public static float ScaleX;
    public static float ScaleY;
    public static Rectangle BaseBox = new Rectangle(0, 0, Constants.Screen.ResolutionX, Constants.Screen.ResolutionY);
    private static Point GameResolution;
    public static bool IsFocused { private set; get; }

    public static void SetResolution(GraphicsDeviceManager graphics, GraphicsDevice graphicsDevice, int w = 0, int h = 0)
    {
#if BLAZORGL
        // In the browser the canvas is sized by the page (100vw x 100vh). Render at the full canvas
        // size so SetBoxToDraw can do real scaling instead of the browser stretching a 256x144
        // framebuffer up to the canvas (a blurry, non-integer scale). The resize handler passes the
        // new canvas size (w, h) in CSS pixels; use it directly. Setting canvas.width/height in JS
        // does not update KNI's GL viewport, so falling back to reading the viewport would give a
        // stale size and the resize would be a no-op. Only the initial LoadContent call (w == h == 0)
        // reads the viewport, which is valid at that point.
        if (w == 0 || h == 0)
        {
            var viewport = graphicsDevice.Viewport;
            w = viewport.Width;
            h = viewport.Height;
        }
        GameResolution = new Point(Math.Max(w, BaseBox.Width), Math.Max(h, BaseBox.Height));
#else
        GameResolution = new Point(Math.Max(w, BaseBox.Width), Math.Max(h, BaseBox.Height));
#endif
        ApplyChanges(graphics, graphicsDevice);
    }

    private static void ApplyChanges(GraphicsDeviceManager graphics, GraphicsDevice graphicsDevice)
    {
        if (graphics.IsFullScreen)
        {
            graphics.PreferredBackBufferWidth = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Width;
            graphics.PreferredBackBufferHeight = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Height;
        }
        else
        {
            graphics.PreferredBackBufferWidth = GameResolution.X;
            graphics.PreferredBackBufferHeight = GameResolution.Y;
        }
        graphics.ApplyChanges();
        SetBoxToDraw(graphicsDevice);
    }

    public static void ToggleFullScreen(GraphicsDeviceManager graphics, GraphicsDevice graphicsDevice)
    {
        graphics.IsFullScreen = !graphics.IsFullScreen;
        ApplyChanges(graphics, graphicsDevice);
    }

    public static void UpdateIsFocused(bool isActive, bool isFullScreen)
    {
        IsFocused = isFullScreen || isActive;
    }

    public static void SetBoxToDraw(GraphicsDevice graphicsDevice)
    {
        var viewPort = graphicsDevice.Viewport;

#if BLAZORGL
        // In the browser the canvas is an arbitrary full-viewport rectangle whose size the user
        // controls, so whole-multiple integer scaling would waste most of the window on borders.
        // Instead fill the canvas as much as possible while preserving the 16:9 aspect ratio: a
        // single float scale, centred, with the remainder letterboxed by DrawGameBorder. The
        // mouse->virtual transform divides by ScaleX/ScaleY, so it stays consistent automatically.
        float fit = Math.Min(
            (float)viewPort.Width / BaseBox.Width,
            (float)viewPort.Height / BaseBox.Height);
        fit = Math.Max(1f, fit);
        int scaleWidth = (int)(BaseBox.Width * fit);
        int scaleHeight = (int)(BaseBox.Height * fit);
#else
        // Desktop: pick the largest whole multiple of the base resolution that fits the viewport,
        // then centre it (letterbox/pillarbox the remainder). Whole multiples keep pixels perfectly
        // sharp on a desktop window the engine sizes to a multiple of 256x144.
        int multx = viewPort.Width / BaseBox.Width;
        int multy = viewPort.Height / BaseBox.Height;
        int mult = Math.Max(1, Math.Min(multx, multy));
        int scaleWidth = mult * BaseBox.Width;
        int scaleHeight = mult * BaseBox.Height;
#endif
        int offsetX = (viewPort.Width - scaleWidth) / 2;
        int offsetY = (viewPort.Height - scaleHeight) / 2;
        BoxToDraw = new Rectangle(offsetX, offsetY, scaleWidth, scaleHeight);

        ScaleX = (float)BoxToDraw.Width / BaseBox.Width;
        ScaleY = (float)BoxToDraw.Height / BaseBox.Height;
    }

    public static Rectangle ScaleRectangle(Rectangle bounds)
    {
        var boxToDraw = BoxToDraw;
        var scaleX = ScaleX;
        var scaleY = ScaleY;

        return new Rectangle(
            boxToDraw.X + (int)Math.Floor(bounds.X * scaleX),
            boxToDraw.Y + (int)Math.Floor(bounds.Y * scaleY),
            (int)Math.Ceiling(bounds.Width * scaleX),
            (int)Math.Ceiling(bounds.Height * scaleY));
    }
}
