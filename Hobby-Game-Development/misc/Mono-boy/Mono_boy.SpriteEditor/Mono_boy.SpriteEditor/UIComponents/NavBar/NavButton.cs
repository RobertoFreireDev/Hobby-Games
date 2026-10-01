using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.Base;

namespace Mono_boy.SpriteEditor.UIComponents.NavBar;

internal class NavButton : BaseButton
{
    public NavButtonEnum Type;

    public NavButton(Texture2D texture, Rectangle bounds, NavButtonEnum type, int buttonClickType) : base(texture, bounds, buttonClickType)
    {
        Type = type;
    }
}