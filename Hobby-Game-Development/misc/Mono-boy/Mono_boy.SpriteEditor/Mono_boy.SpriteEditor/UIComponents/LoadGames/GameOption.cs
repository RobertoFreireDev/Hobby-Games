using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.Utils;

namespace Mono_boy.SpriteEditor.UIComponents.LoadGames;

internal class GameOption : UIComponent
{
    private int _primaryColor;
    private int _hoverColor;
    public TextField Label;
    public int GameIndex;

    public GameOption(TextField label, Rectangle bounds, int gameIndex) : base(GlobalManager.PixelTexture, bounds, 1)
    {
        _primaryColor = 1;
        _hoverColor = 2;
        Label = label;
        GameIndex = gameIndex;
    }

    public override void Update()
    {
        if (IsMouseOver())
        {
            Color = _hoverColor;
            Label.UpdateColor(Color);
        }
        else
        {
            Color = _primaryColor;
            Label.UpdateColor(Color);
        }

        if (IsClicked())
        {

        }
    }

    public override void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;

        if (GameIndex == Games.GetCurrentGameIndex())
        {
            spriteBatch.CustomDraw(Texture, Bounds, ColorUtils.GetColor(3));
            spriteBatch.DrawBorder(Bounds, Color, 2, Point.Zero);
        }
        else
        {
            spriteBatch.DrawBorder(Bounds, Color, 2, Point.Zero);
        }
        Label.Draw();
    }
}
