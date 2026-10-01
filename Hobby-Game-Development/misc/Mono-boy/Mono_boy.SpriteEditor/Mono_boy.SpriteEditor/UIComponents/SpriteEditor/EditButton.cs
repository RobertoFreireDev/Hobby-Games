using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.Base;

namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class EditButton : BaseButton
{
    public EditEnum Type;

    public EditButton(Texture2D texture, Rectangle bounds, EditEnum type, int buttonClickType) : base(texture, bounds, buttonClickType)
    {
        Type = type;
    }

    public override void Update()
    {
        if (ShouldDisableButton())
        {
            return;
        }

        base.Update();
    }

    public override void Draw()
    {
        if (ShouldDisableButton())
        {
            return;
        }

        base.Draw();
    }

    private bool ShouldDisableButton()
    {
        if (Type == EditEnum.Copy)
        {
            return !SpriteGrid.RectangleSelection.HasValue;
        }
        else if (Type == EditEnum.Paste)
        {
            return blink.IsBlinking() == false && !EditCard.HasCopied;
        }
        else
        {
            return false;
        }
    }
}