using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.Base;

namespace Mono_boy.SpriteEditor.UIComponents.Common;

internal class SpriteCellButton : BaseButton
{
    public NavPageEnum Type { private set; get; }

    public SpriteCellButton(Texture2D texture, Rectangle bounds, NavPageEnum type, int buttonClickType) : base(texture, bounds, buttonClickType)
    {
        Type = type;
    }
}
