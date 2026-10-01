using mega8.core.common;
using mega8.core.graphics;
using mega8.core.input;
using mega8.core.Lua;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace mega8;

public class Mega8 : Game
{
    private GraphicsDeviceManager _graphics;
    public static PixelledSpriteBatch SpriteBatch;
    private static LuaBinding LuaProgram;
    private RenderTarget2D sceneTarget;

    public Mega8()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        IsMouseVisible = true;
        ColorPalette.SetPalette();
    }

    public void LoadFiles()
    {
        LuaError.Reset();
        LuaProgram = new LuaBinding(FileIO.Read(Constants.File.Main, Constants.File.Extensions.Lua));
    }

    protected override void Initialize()
    {
        LoadFiles();
        base.Initialize();
    }

    protected override void LoadContent()
    {
        Screen.SetResolution(_graphics, GraphicsDevice);
        PixelledShapes.SetPixelTexture(GraphicsDevice);
        SpriteBatch = new PixelledSpriteBatch(new SpriteBatch(GraphicsDevice));
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
        InputStateManager.Update();
        LuaProgram.Update();
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
        SpriteBatch.Draw(sceneTarget, Screen.BoxToDraw, Color.White);
        SpriteBatch.End();

        base.Draw(gameTime);
    }

    protected override void UnloadContent()
    {
        LuaProgram.Unload();
        base.UnloadContent();
    }
}