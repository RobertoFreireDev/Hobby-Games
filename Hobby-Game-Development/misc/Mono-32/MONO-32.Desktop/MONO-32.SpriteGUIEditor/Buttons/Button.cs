using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MONO_32.SpriteGUIEditor.Enums;

namespace MONO_32.SpriteGUIEditor.Buttons;

internal class Button
{
    public ButtonTypeEnum Type;

    public Texture2D Texture;

    public Rectangle Rectangle;

    public Button(ButtonTypeEnum type, Texture2D texture)
    {
        Type = type;
        Texture = texture;
        Rectangle = new Rectangle(0, 0, UIVariables.ButtonSize, UIVariables.ButtonSize);
    }
}
