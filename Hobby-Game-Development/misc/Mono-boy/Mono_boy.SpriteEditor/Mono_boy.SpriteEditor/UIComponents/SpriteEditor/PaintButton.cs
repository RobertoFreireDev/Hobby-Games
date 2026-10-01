using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.Base;

namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class PaintButton : BaseButton
{
    public PaintModeEnum PaintMode;

    public PaintButton(Texture2D texture, Rectangle bounds, PaintModeEnum paintMode, int buttonClickType) : base(texture, bounds, buttonClickType)
    {
        PaintMode = paintMode;
    }
}