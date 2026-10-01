using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MONO_32.SpriteGUIEditor.Enums;
using System.Collections.Generic;

namespace MONO_32.SpriteGUIEditor;

internal static class UIVariables
{
    public static Dictionary<string, Texture2D> Textures;

    public static Texture2D PixelTexture;

    public static int OffsetX;

    public static int OffsetY;

    public static Color SelectedColor;

    public static SpriteFont DefaultFont;

    public static string TextFileName = "";

    public static PaintModeEnum PaintMode;

    public static int Margin = 8;

    public static int ButtonSize = 24;

    public static int CellSize = 14;

    public static int GridSize = 32;

    public static int TextInputFieldWidth = 120;

    public static Rectangle Edition;

    public static Rectangle PaintButtons;

    public static Rectangle Pallete;

    public static void LoadVariables(
        Texture2D pixelTexture,
        PaintModeEnum paintModeEnum,
        Color color,
        int offsetX,
        int offsetY)
    {
        PixelTexture = pixelTexture;
        SelectedColor = color;
        OffsetX = offsetX;
        OffsetY = offsetY;
        PaintMode = paintModeEnum;
        Edition = new Rectangle(offsetX, offsetY, 8 * 32, 1 * 32);
        PaintButtons = new Rectangle(Edition.Left, Edition.Bottom + Margin, 8 * 32, 1 * 32);
        Pallete = new Rectangle(PaintButtons.Left, PaintButtons.Bottom + Margin, 8 * 32, 6 * 32);
    }
}
