using Microsoft.Xna.Framework;
using System;

namespace blackbox.Graphics;

public static class Camera2D
{
    public static Vector2 Position { get; private set; } = Vector2.Zero;

    public static void Camera(float x = 0.0f, float y = 0.0f)
    {
        Position = new Vector2(x, y);
    }

    public static Matrix GetViewMatrix()
    {
        Vector2 pos = Position;
        pos.X = (float)Math.Floor(pos.X);
        pos.Y = (float)Math.Floor(pos.Y);
        return Matrix.CreateTranslation(new Vector3(-pos, 0f));
    }
}