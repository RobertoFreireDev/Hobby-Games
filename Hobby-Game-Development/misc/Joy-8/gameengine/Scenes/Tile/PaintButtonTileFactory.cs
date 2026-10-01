using gameengine.Scenes.Shared.UI;
using gameengine.Scenes.Shared.UI.Buttons.Paint;

namespace gameengine.Scenes.Tile;

internal static class PaintButtonTileFactory
{
    public static PaintButton CreatePaintButton(UIComponentEnum component)
    {
        switch (component)
        {
            case UIComponentEnum.PencilTileButton:
                return new PencilPaintButton(component);
            case UIComponentEnum.BucketTileButton:
                return new BucketPaintButton(component);
            case UIComponentEnum.EraserTileButton:
                return new EraserPaintButton(component);
            case UIComponentEnum.LineTileButton:
                return new LinePaintButton(component);
            case UIComponentEnum.RectangleTileButton:
                return new RectanglePaintButton(component);
            case UIComponentEnum.CircleTileButton:
                return new CirclePaintButton(component);
            case UIComponentEnum.CopyTileButton:
                return new CopyPaintButton(component);
            case UIComponentEnum.PasteTileButton:
                return new PastePaintButton(component);
            case UIComponentEnum.UndoTileButton:
                return new UndoPaintButton(component);
            case UIComponentEnum.RedoTileButton:
                return new RedoPaintButton(component);
            case UIComponentEnum.PixelSize1TileButton:
                return new PixelSize1PaintButton(component);
            case UIComponentEnum.PixelSize2TileButton:
                return new PixelSize2PaintButton(component);
            case UIComponentEnum.PixelSize3TileButton:
                return new PixelSize3PaintButton(component);
            case UIComponentEnum.PixelSize4TileButton:
                return new PixelSize4PaintButton(component);
            case UIComponentEnum.SelectionRectangleTileButton:
                return new SelectionRectanglePaintButton(component);
            case UIComponentEnum.FlipHTileButton:
                return new FlipHPaintButton(component);
            case UIComponentEnum.FlipVTileButton:
                return new FlipVPaintButton(component);
            case UIComponentEnum.DeleteTileButton:
                return new DeletePaintButton(component);
            case UIComponentEnum.RotateLeftTileButton:
                return new RotateLeftPaintButton(component);
            case UIComponentEnum.RotateRightTileButton:
                return new RotateRightPaintButton(component);
        }

        return null;
    }
}
