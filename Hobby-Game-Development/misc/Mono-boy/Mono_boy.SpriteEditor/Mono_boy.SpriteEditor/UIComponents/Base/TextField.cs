using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Manager;

namespace Mono_boy.SpriteEditor.UIComponents.Base;

internal class TextField
{
    private string Text;
    private Vector2 Position;
    private int Color;

    public TextField(Vector2 position, string text)
    {
        Position = position;
        Text = text;
        Color = 1;
    }

    public void UpdateText(string text)
    {
        Text = text;
    }

    public void UpdateColor(int color)
    {
        Color = color;
    }

    public void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.DrawText(Text, Position, Color);
    }
}