using Microsoft.Xna.Framework;

namespace Mono_boy.SpriteEditor.UIComponents.PlayGame;

public static class CameraManipulator
{
    private static Vector2 Position = new Vector2(0, 0);

    private static Rectangle Game;

    public static Vector2 GetCameraPosition()
    {
        return new Vector2 (Position.X + Game.X, Position.Y + Game.Y);
    }

    public static Vector2 GetOnlyCameraPosition()
    {
        return Position;
    }

    public static void LoadCamera(Rectangle game)
    {
        Game = game;
    }

    public static void UpdateForFollowPosition(Vector2 position, float smoothFactor)
    {
        var desiredPosition = new Vector2(
            (-position.X + (Game.Width / 2)),
            (-position.Y + (Game.Height / 2))
        );

        Position = Vector2.Lerp(Position, desiredPosition, smoothFactor);
    }

    public static void UpdateForGridCamera(Vector2 position)
    {
        var column = (int)position.X / Game.Width;
        var row = (int)position.Y / Game.Height;
        Position = new Vector2(-column * Game.Width, -row * Game.Height);
    }
}