using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace gameengine.Data;

internal static class FrameworkData
{
    public static GraphicsDevice GraphicsDevice; 
    public static GraphicsDeviceManager GraphicsDeviceManager;
    public static GameWindow Window;
    public static SpriteBatch SpriteBatch;
    public static float DeltaTime;
}
