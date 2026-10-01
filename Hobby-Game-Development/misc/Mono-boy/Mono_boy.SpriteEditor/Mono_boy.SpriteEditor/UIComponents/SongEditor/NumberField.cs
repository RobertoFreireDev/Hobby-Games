using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;

namespace Mono_boy.SpriteEditor.UIComponents.SongEditor;

internal class NumberField : UIComponent
{
    private int Number;
    private int Color;

    public NumberField(Rectangle bounds, int number) : base(GlobalManager.PixelTexture, bounds, 1)
    {
        Number = number;
        Color = 1;
    }

    public override void Update()
    {
        Number = SongEditorManager.CurrentSong;
    }

    public override void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.DrawText(Number.ToString("D3"), new Vector2(Bounds.X, Bounds.Y), Color);
    }
}