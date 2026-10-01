using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;

namespace Mono_boy.SpriteEditor.UIComponents.MapEditor;

internal class SelectedTile : UIComponent
{
    public SelectedTile(Vector2 selectedTilePosition, int size) : base(
        GlobalManager.PixelTexture, 
        new Rectangle((int)selectedTilePosition.X, (int)selectedTilePosition.Y, size, size),
        1)
    {
    }

    public override void Update()
    {
    }

    public override void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.CustomDraw(MapEditorManager.TileEditor.GridColorsList[MapEditorManager.SelectedTile], Bounds, Microsoft.Xna.Framework.Color.White);
    }
}
