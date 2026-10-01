using blackbox.Graphics;
using blackbox.Assets;
using blackbox.Binding;
using blackbox.Input;
using blackbox.IOFile;
using blackbox.Utils;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;

namespace blackbox;

public class GFW : Game
{
    public GraphicsDeviceManager _graphics;
    public static Dictionary<string, Texture2D> SystemTextures = new Dictionary<string, Texture2D>();
    public static Dictionary<char, Texture2D> MediumFontTextures;
    public static List<Texture2D> MouseTextures;
    public static Texture2D PixelTexture;
    public static SafeSpriteBatch SpriteBatch;
    public static int FPS;
    public static bool ShowMouse = true;
    public static bool ApplyCRTshader = false;
    public static int BackgroundColor;
    private static bool Updated = false;
    private static bool IsFullScreen = false;
    private static LuaBinding LuaProgram;
    public static bool GamePaused = false;
    public static Effect CustomEffect;
    private Effect crtEffect;
    private static float Inner = 0.00f;
    private static float Outer = 0.00f;
    private RenderTarget2D sceneTarget;

    public GFW()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        Window.AllowUserResizing = true;
        IsMouseVisible = false;
        IsFixedTimeStep = true;
        Window.ClientSizeChanged += OnResize;
        LoadMetadata();
    }
    
    private void LoadMetadata()
    {
        
        if (TxtFileIO.HasFile(Constants.MetadataFilename))
        {
            AppConfig.SetConfig(TxtFileIO.Read(Constants.MetadataFilename));
        }

        IsFullScreen = AppConfig.IsFullscreen;
        Updated = true;
        ColorUtils.SetPalette(AppConfig.Palette);
        Window.Title = string.IsNullOrWhiteSpace(AppConfig.Title) ? "Black Box" : AppConfig.Title;

        if (AppConfig.ResolutionX > 64 && AppConfig.ResolutionY > 64)
        {
            ScreenUtils.BaseBox = new Rectangle(0, 0, AppConfig.ResolutionX, AppConfig.ResolutionY);
        }
    }

    public static void PauseGame()
    {
        GamePaused = true;
    }

    public static void ResumeGame()
    {
        GamePaused = false;
    }

    public static void ShowHideMouse(bool value)
    {
        ShowMouse = value;
    }

    public static void EnableCRTshader(bool value, int inner, int outer)
    {
        ApplyCRTshader = value;
        Inner = Math.Clamp(inner,0,110) * 0.01f;
        Outer = Math.Clamp(outer,0,110) * 0.01f;
    }

    public static void UpdateFPS(int fps)
    {
        FPS = fps;
        Updated = true;
    }

    public static void LoadMainFile()
    {
        LuaError.Reset();
        var script = string.Empty;
        if (LuaFileIO.HasFile(Constants.Mainfilename))
        {
            script = LuaFileIO.Read(Constants.Mainfilename);
        }
        LuaProgram = new LuaBinding(script);
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

        ScreenUtils.SetResolution(_graphics, GraphicsDevice, window.ClientBounds.Width, window.ClientBounds.Height);
        Window.Position = new Point(window.ClientBounds.X, window.ClientBounds.Y);
    }

    protected override void Initialize()
    {
        base.Initialize();
    }

    protected override void LoadContent()
    {
        ScreenUtils.SetResolution(_graphics, GraphicsDevice);
        GraphUtils.GraphicsDevice = GraphicsDevice;
        Window.Position = new Point(0, 35);
        SystemTextures = Images.GetAllImages();
        PixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        PixelTexture.SetData(new Color[] { Color.White });
        SpriteBatch = new SafeSpriteBatch(new SpriteBatch(GraphicsDevice));
        MediumFontTextures = Font.GetCharacterTextures(GraphicsDevice, SystemTextures["medium_font"]);
        MouseTextures = TextureUtils.GetTextures(SystemTextures["mouse"], 2, 16, 16);
        LoadMainFile();
        _graphics.SynchronizeWithVerticalRetrace = true;
        crtEffect = Content.Load<Effect>("CRT");
        CustomEffect = Content.Load<Effect>("CustomShader");
        sceneTarget = new RenderTarget2D(
            GraphicsDevice,
            GraphicsDevice.PresentationParameters.BackBufferWidth,
            GraphicsDevice.PresentationParameters.BackBufferHeight,
            false,
            SurfaceFormat.Color,
            DepthFormat.None);
    }

    protected override void Update(GameTime gameTime)
    {
        if (KeyboardInput.IsAltF4Pressed())
            Exit();

        if (KeyboardInput.IsF2Released())
        {
            ScreenUtils.ToggleFullScreen(_graphics, GraphicsDevice);
            IsFullScreen = _graphics.IsFullScreen;
        }
            

        if (KeyboardInput.IsEscPressed())
            LoadMainFile();

        ScreenUtils.UpdateIsFocused(IsActive, _graphics.IsFullScreen);
        InputStateManager.Update();

        LuaProgram.Update();

        if (Updated)
        {
            if (_graphics.IsFullScreen != IsFullScreen)
            {
                ScreenUtils.ToggleFullScreen(_graphics, GraphicsDevice);
                IsFullScreen = _graphics.IsFullScreen;
            }

            TargetElapsedTime = FPS != 30 ? TimeSpan.FromSeconds(1.0 / 60.0) : TimeSpan.FromSeconds(1.0 / 30.0);
            Updated = false;
        }

        crtEffect.Parameters["Resolution"].SetValue(
            new Vector2(GraphicsDevice.PresentationParameters.BackBufferWidth,
                        GraphicsDevice.PresentationParameters.BackBufferHeight));
        crtEffect.Parameters["Inner"].SetValue(Inner);
        crtEffect.Parameters["Outer"].SetValue(Outer);
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        TimeUtils.Update(gameTime);
        GraphicsDevice.SetRenderTarget(sceneTarget);
        GraphicsDevice.Clear(ColorUtils.GetColor(BackgroundColor));
        SpriteBatch.Begin();
        LuaProgram.Draw();        
        SpriteBatch.End();

        GraphicsDevice.SetRenderTarget(null);
        GraphicsDevice.Clear(Color.Black);

        crtEffect.Parameters["Resolution"].SetValue(new Vector2(
            sceneTarget.Width,
            sceneTarget.Height
        ));

        SpriteBatch.Begin(SpriteSortMode.Immediate, BlendState.Opaque, SamplerState.PointClamp, effect: ApplyCRTshader ? crtEffect : null);
        SpriteBatch.Draw(sceneTarget, ScreenUtils.BoxToDraw, Color.White);
        SpriteBatch.End();

        SpriteBatch.Begin(SamplerState.PointClamp);
        if (ShowMouse)
        {
            SpriteBatch.DrawMouse();
        }
        DrawRectWithHole(ScreenUtils.ScaleRectangle(ScreenUtils.BaseBox), Color.Black);
        SpriteBatch.End();
        base.Draw(gameTime);
    }

    public void DrawRectWithHole(Rectangle hole, Color color)
    {
        var viewport = GraphicsDevice.Viewport.Bounds;
        SpriteBatch.Draw(PixelTexture, new Rectangle(viewport.X, viewport.Y, viewport.Width, viewport.Y + hole.Y), color);
        SpriteBatch.Draw(PixelTexture, new Rectangle(viewport.X, hole.Bottom, viewport.Width, viewport.Bottom - hole.Bottom), color);
        SpriteBatch.Draw(PixelTexture, new Rectangle(viewport.X, hole.Y, hole.X - viewport.X, hole.Height), color);
        SpriteBatch.Draw(PixelTexture, new Rectangle(hole.Right, hole.Y, viewport.Right - hole.Right, hole.Height), color);
    }
}
