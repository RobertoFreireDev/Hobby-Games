using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.UIComponents.Base;

namespace Mono_boy.SpriteEditor.UIComponents.MapEditor;

internal class LayerButton : BaseButton
{
    public int Type; // 0 - see 1 - select
    public int Layer;

    public LayerButton(Texture2D texture, Rectangle bounds, int type, bool selected, int layer) : base(texture, bounds, 1)
    {
        Type = type;
        Selected = selected;
        Layer = layer;
    }
}