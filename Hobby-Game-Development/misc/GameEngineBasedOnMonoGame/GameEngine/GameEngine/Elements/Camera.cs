using GameEngine.Elements.Managers;
using Microsoft.Xna.Framework;

namespace GameEngine.Elements;

public static class Camera
{
    public static Vector2 Position = new Vector2(0, 0);

    public static int GridSizeWidth;

    public static int GridSizeHeight;

    public static void LoadCamera(int gridSizeWidth, int gridSizeHeight)
    {
        GridSizeWidth = gridSizeWidth;
        GridSizeHeight = gridSizeHeight;
    }

    public static void LoadCamera()
    {
        GridSizeWidth = GlobalManager.GraphicsDeviceManager.PreferredBackBufferWidth;
        GridSizeHeight = GlobalManager.GraphicsDeviceManager.PreferredBackBufferHeight;
    }

    public static void UpdateForFollowPosition(Vector2 position, float smoothFactor)
    {
        var desiredPosition = new Vector2(
            (-position.X + (GridSizeWidth / 2)),
            (-position.Y + (GridSizeHeight / 2))
        );

        Position = Vector2.Lerp(Position, desiredPosition, smoothFactor);
    }

    public static void UpdateForGridCamera(Vector2 position)
    {
        var column = (int)position.X / GridSizeWidth;
        var row = (int)position.Y / GridSizeHeight;
        Position = new Vector2(-column * GridSizeWidth, -row * GridSizeHeight);
    }
}