using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MONO_32.SpriteGUIEditor;
using MONO_32.SpriteGUIEditor.Enums;

namespace Buttons;

internal class Palette
{
    public Color[] ColorPalette;

    public int PaletteSize; // Size of each color cell in the palette

    private Rectangle[] PaletteRectangles;

    public int Columns;

    public Palette(
        ColorPaletteEnum colorPaletteEnum,
        int columns,
        int paletteSize)
    {
        Columns = columns;
        PaletteSize = paletteSize;
        ColorPalette = GetPallete(colorPaletteEnum);
    }

    public void CreatePalleteRectangles()
    {
        PaletteRectangles = new Rectangle[ColorPalette.Length];
        for (int i = 0; i < ColorPalette.Length; i++)
        {
            int x = i % Columns * PaletteSize; // Arrange palette in Columns
            int y = i / Columns * PaletteSize; // Arrange palette in rows
            PaletteRectangles[i] = new Rectangle(UIVariables.Pallete.Left + x, UIVariables.Pallete.Top + y, PaletteSize, PaletteSize);
        }
    }

    public Color? UpdateSelectedColor(Point mousePosition)
    {
        for (int i = 0; i < ColorPalette.Length; i++)
        {
            if (PaletteRectangles[i].Contains(mousePosition))
            {
                return ColorPalette[i];
            }
        }

        return null;
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        for (int i = 0; i < ColorPalette.Length; i++)
        {
            spriteBatch.Begin();
            spriteBatch.Draw(UIVariables.PixelTexture, PaletteRectangles[i], ColorPalette[i]);
            spriteBatch.End();
        }
    }

    private Color[] GetPallete(ColorPaletteEnum colorPaletteEnum)
    {
        switch (colorPaletteEnum)
        {
            case ColorPaletteEnum.MiniMax32:

                return new Color[]
                {
                    // Grays
                    new Color(0x00, 0x00, 0x00), // Black            
                    new Color(0x15, 0x15, 0x15), // Charcoal Black
                    new Color(0x33, 0x33, 0x33), // Charcoal Gray
                    new Color(0x55, 0x55, 0x55), // Dark Gray
                    new Color(0x7F, 0x7F, 0x7F), // Gray
                    new Color(0xA0, 0xA0, 0xA0), // Medium Light Gray
                    new Color(0xC0, 0xC0, 0xC0), // Silver
                    new Color(0xFF, 0xFF, 0xFF), // White
                    new Color(0xFA, 0xFF, 0xFF), // fffffaff
                    new Color(0xC1, 0xD7, 0xDB), // c1d7db
                    new Color(0x69, 0x7D, 0x8E), // 697d8e
                    new Color(0x38, 0x43, 0x5F), // 38435f
                    new Color(0x26, 0x22, 0x45), // 262245
                    new Color(0x13, 0x0E, 0x26), // 130e26
                    new Color(0x34, 0xDD, 0xDA), // 34ddda
                    new Color(0x2C, 0x9C, 0xD5), // 2c9cd5
                    new Color(0x77, 0x81, 0xFF), // 7781ff
                    new Color(0x49, 0x4F, 0xE1), // 494fe1
                    new Color(0x21, 0x3F, 0xBE), // 213fbe
                    new Color(0x0D, 0x24, 0x87), // 0d2487
                    new Color(0xE3, 0x3D, 0x98), // e33d98
                    new Color(0x98, 0x22, 0xA8), // 9822a8
                    new Color(0xE5, 0x3A, 0x4A), // e53a4a
                    new Color(0x8F, 0x11, 0x57), // 8f1157
                    new Color(0xEB, 0x82, 0x2B), // eb822b
                    new Color(0xB0, 0x2B, 0x36), // b02b36
                    new Color(0xFF, 0xE5, 0x70), // fffe570
                    new Color(0xF9, 0xA1, 0x35), // f9a135
                    new Color(0x65, 0xEF, 0x42), // 65ef42
                    new Color(0x11, 0x8C, 0x60), // 118c60
                    new Color(0xA8, 0xC4, 0xAF), // a8c4af
                    new Color(0x69, 0x8E, 0x86), // 698e86
                    new Color(0x32, 0x55, 0x55), // 325555
                    new Color(0xE3, 0xB1, 0x75), // e3b175
                    new Color(0xB6, 0x68, 0x3C), // b6683c
                    new Color(0x8A, 0x3E, 0x1B), // 8a3e1b
                    new Color(0x49, 0x18, 0x16), // 491816
                    new Color(0xFF, 0xD5, 0xBC), // fffd5bc
                    new Color(0xF5, 0xA5, 0x9F)  // f5a59f
                };
            case ColorPaletteEnum.TwilioQuest76:
                return new Color[]
                {
                    new Color(0xFF, 0xFF, 0xFF), // ffffff
                    new Color(0xEA, 0xEA, 0xE8), // eaeae8
                    new Color(0xCE, 0xCA, 0xC9), // cecec9
                    new Color(0xAB, 0xAF, 0xB9), // abafb9
                    new Color(0xA1, 0x88, 0x97), // a18897
                    new Color(0x75, 0x62, 0x76), // 756276
                    new Color(0x5D, 0x46, 0x60), // 5d4660
                    new Color(0x4C, 0x32, 0x50), // 4c3250
                    new Color(0x43, 0x26, 0x41), // 432641
                    new Color(0x28, 0x19, 0x2F), // 28192f
                    new Color(0xFB, 0x75, 0x75), // fb7575
                    new Color(0xFB, 0x3B, 0x64), // fb3b64
                    new Color(0xC8, 0x31, 0x57), // c83157
                    new Color(0x8E, 0x37, 0x5C), // 8e375c
                    new Color(0x4F, 0x23, 0x51), // 4f2351
                    new Color(0x35, 0x15, 0x44), // 351544
                    new Color(0xF7, 0x4A, 0x53), // f74a53
                    new Color(0xF2, 0x2F, 0x46), // f22f46
                    new Color(0xBC, 0x16, 0x42), // bc1642
                    new Color(0xFC, 0xC5, 0x39), // fcc539
                    new Color(0xF8, 0x7B, 0x1B), // f87b1b
                    new Color(0xF8, 0x40, 0x1B), // f8401b
                    new Color(0xBD, 0x27, 0x09), // bd2709
                    new Color(0x7C, 0x12, 0x2B), // 7c122b
                    new Color(0xFF, 0xE0, 0x8B), // ffe08b
                    new Color(0xFA, 0xC0, 0x5A), // fac05a
                    new Color(0xEB, 0x8F, 0x48), // eb8f48
                    new Color(0xD1, 0x74, 0x41), // d17441
                    new Color(0xC7, 0x52, 0x39), // c75239
                    new Color(0xB1, 0x29, 0x35), // b12935
                    new Color(0xFD, 0xBD, 0x8F), // fdbd8f
                    new Color(0xF0, 0x88, 0x6B), // f0886b
                    new Color(0xD3, 0x68, 0x53), // d36853
                    new Color(0xAE, 0x45, 0x4A), // ae454a
                    new Color(0x8C, 0x31, 0x32), // 8c3132
                    new Color(0x54, 0x23, 0x23), // 542323
                    new Color(0xA8, 0x58, 0x48), // a85848
                    new Color(0x83, 0x40, 0x4C), // 83404c
                    new Color(0x67, 0x31, 0x4B), // 67314b
                    new Color(0x3F, 0x23, 0x23), // 3f2323
                    new Color(0xD4, 0x95, 0x77), // d49577
                    new Color(0x9F, 0x70, 0x5A), // 9f705a
                    new Color(0x84, 0x57, 0x50), // 845750
                    new Color(0x63, 0x3B, 0x3F), // 633b3f
                    new Color(0x7B, 0xD7, 0xA9), // 7bd7a9
                    new Color(0x52, 0xB2, 0x81), // 52b281
                    new Color(0x14, 0x85, 0x68), // 148568
                    new Color(0x14, 0x67, 0x56), // 146756
                    new Color(0x22, 0x47, 0x4C), // 22474c
                    new Color(0x10, 0x2F, 0x34), // 102f34
                    new Color(0xEB, 0xFF, 0x8B), // ebff8b
                    new Color(0xB3, 0xE3, 0x63), // b3e363
                    new Color(0x4C, 0xBD, 0x56), // 4cbd56
                    new Color(0x2F, 0x87, 0x35), // 2f8735
                    new Color(0x0B, 0x59, 0x31), // 0b5931
                    new Color(0x97, 0xBF, 0x6E), // 97bf6e
                    new Color(0x89, 0x9F, 0x66), // 899f66
                    new Color(0x61, 0x85, 0x5A), // 61855a
                    new Color(0x4C, 0x60, 0x51), // 4c6051
                    new Color(0x73, 0xDF, 0xF2), // 73dff2
                    new Color(0x2A, 0xBB, 0xD0), // 2abbd0
                    new Color(0x31, 0x5D, 0xCD), // 315dcd
                    new Color(0x47, 0x2A, 0x9C), // 472a9c
                    new Color(0xA0, 0xD8, 0xD7), // a0d8d7
                    new Color(0x7D, 0xBE, 0xFA), // 7dbefa
                    new Color(0x66, 0x8F, 0xAF), // 668faf
                    new Color(0x58, 0x5D, 0x81), // 585d81
                    new Color(0x45, 0x36, 0x5D), // 45365d
                    new Color(0xF6, 0xBA, 0xFE), // f6bafe
                    new Color(0xD5, 0x9F, 0xF4), // d59ff4
                    new Color(0xB0, 0x70, 0xEB), // b070eb
                    new Color(0x7C, 0x3C, 0xE1), // 7c3ce1
                    new Color(0xDB, 0xCF, 0xB1), // dbcfb1
                    new Color(0xA9, 0xA4, 0x8D), // a9a48d
                    new Color(0x7B, 0x83, 0x82), // 7b8382
                    new Color(0x5F, 0x5F, 0x6E)  // 5f5f6e
                };
            case ColorPaletteEnum.PAX24:
                return new Color[]
                {
                    new Color(0xF4, 0xF5, 0xEF), // f4f5ef
                    new Color(0xF8, 0xC7, 0xA4), // f8c7a4
                    new Color(0xE7, 0x84, 0xA8), // e784a8
                    new Color(0xEB, 0x9D, 0x45), // eb9d45
                    new Color(0xBB, 0x9A, 0x3E), // bb9a3e
                    new Color(0xF6, 0xE4, 0x55), // f6e455
                    new Color(0xC8, 0xDB, 0xDF), // c8dbdf
                    new Color(0xA1, 0x46, 0xAA), // a146aa
                    new Color(0xD7, 0x4D, 0x4C), // d74d4c
                    new Color(0xA6, 0x5D, 0x35), // a65d35
                    new Color(0x8F, 0xCB, 0x62), // 8fcb62
                    new Color(0x35, 0x88, 0x4E), // 35884e
                    new Color(0xA0, 0xAB, 0xB1), // a0abb1
                    new Color(0x96, 0x2F, 0x2C), // 962f2c
                    new Color(0x68, 0x2D, 0x2C), // 682d2c
                    new Color(0x85, 0xDF, 0xEB), // 85dfeb
                    new Color(0x33, 0x9C, 0xA3), // 339ca3
                    new Color(0x1B, 0x4C, 0x5A), // 1b4c5a
                    new Color(0x5E, 0x6A, 0x82), // 5e6a82
                    new Color(0x19, 0x10, 0x23), // 191023
                    new Color(0x72, 0xAD, 0xEE), // 72adee
                    new Color(0x43, 0x5E, 0xDB), // 435edb
                    new Color(0x47, 0x43, 0x94), // 474394
                    new Color(0x32, 0x2D, 0x4F)  // 322d4f
                };
            case ColorPaletteEnum.Resurrect64:
                return new Color[]
                {
                    new Color(0x2E, 0x22, 0x2F),
                    new Color(0x3E, 0x35, 0x46),
                    new Color(0x62, 0x55, 0x65),
                    new Color(0x96, 0x6C, 0x6C),
                    new Color(0xAB, 0x94, 0x7A),
                    new Color(0x69, 0x4F, 0x62),
                    new Color(0x7F, 0x70, 0x8A),
                    new Color(0x9B, 0xAB, 0xB2),
                    new Color(0xC7, 0xDC, 0xD0),
                    new Color(0xFF, 0xFF, 0xFF),
                    new Color(0x6E, 0x27, 0x27),
                    new Color(0xB3, 0x38, 0x31),
                    new Color(0xEA, 0x4F, 0x36),
                    new Color(0xF5, 0x7D, 0x4A),
                    new Color(0xAE, 0x23, 0x34),
                    new Color(0xE8, 0x3B, 0x3B),
                    new Color(0xFB, 0x6B, 0x1D),
                    new Color(0xF7, 0x96, 0x17),
                    new Color(0xF9, 0xC2, 0x2B),
                    new Color(0x7A, 0x30, 0x45),
                    new Color(0x9E, 0x45, 0x39),
                    new Color(0xCD, 0x68, 0x3D),
                    new Color(0xE6, 0x90, 0x4E),
                    new Color(0xFB, 0xB9, 0x54),
                    new Color(0x4C, 0x3E, 0x24),
                    new Color(0x67, 0x66, 0x33),
                    new Color(0xA2, 0xA9, 0x47),
                    new Color(0xD5, 0xE0, 0x4B),
                    new Color(0xFB, 0xFF, 0x86),
                    new Color(0x16, 0x5A, 0x4C),
                    new Color(0x23, 0x90, 0x63),
                    new Color(0x1E, 0xBC, 0x73),
                    new Color(0x91, 0xDB, 0x69),
                    new Color(0xCD, 0xDF, 0x6C),
                    new Color(0x31, 0x36, 0x38),
                    new Color(0x37, 0x4E, 0x4A),
                    new Color(0x54, 0x7E, 0x64),
                    new Color(0x92, 0xA9, 0x84),
                    new Color(0xB2, 0xBA, 0x90),
                    new Color(0x0B, 0x5E, 0x65),
                    new Color(0x0B, 0x8A, 0x8F),
                    new Color(0x0E, 0xAF, 0x9B),
                    new Color(0x30, 0xE1, 0xB9),
                    new Color(0x8F, 0xF8, 0xE2),
                    new Color(0x32, 0x33, 0x53),
                    new Color(0x48, 0x4A, 0x77),
                    new Color(0x4D, 0x65, 0xB4),
                    new Color(0x4D, 0x9B, 0xE6),
                    new Color(0x8F, 0xD3, 0xFF),
                    new Color(0x45, 0x29, 0x3F),
                    new Color(0x6B, 0x3E, 0x75),
                    new Color(0x90, 0x5E, 0xA9),
                    new Color(0xA8, 0x84, 0xF3),
                    new Color(0xEA, 0xAD, 0xED),
                    new Color(0x75, 0x3C, 0x54),
                    new Color(0xA2, 0x4B, 0x6F),
                    new Color(0xCF, 0x65, 0x7F),
                    new Color(0xED, 0x80, 0x99),
                    new Color(0x83, 0x1C, 0x5D),
                    new Color(0xC3, 0x24, 0x54),
                    new Color(0xF0, 0x4F, 0x78),
                    new Color(0xF6, 0x81, 0x81),
                    new Color(0xFC, 0xA7, 0x90),
                    new Color(0xFD, 0xCB, 0xB0)
                };
            case ColorPaletteEnum.Vinik24:
                return new Color[]
                {
                    new Color(0x00, 0x00, 0x00), // #000000
                    new Color(0x6F, 0x67, 0x76), // #6f6776
                    new Color(0x9A, 0x9A, 0x97), // #9a9a97
                    new Color(0xC5, 0xCC, 0xB8), // #c5ccb8
                    new Color(0x8B, 0x55, 0x80), // #8b5580
                    new Color(0xC3, 0x88, 0x90), // #c38890
                    new Color(0xA5, 0x93, 0xA5), // #a593a5
                    new Color(0x66, 0x60, 0x92), // #666092
                    new Color(0x9A, 0x4F, 0x50), // #9a4f50
                    new Color(0xC2, 0x8D, 0x75), // #c28d75
                    new Color(0x7C, 0xA1, 0xC0), // #7ca1c0
                    new Color(0x41, 0x6A, 0xA3), // #416aa3
                    new Color(0x8D, 0x62, 0x68), // #8d6268
                    new Color(0xBE, 0x95, 0x5C), // #be955c
                    new Color(0x68, 0xAC, 0xA9), // #68aca9
                    new Color(0x38, 0x70, 0x80), // #387080
                    new Color(0x6E, 0x69, 0x62), // #6e6962
                    new Color(0x93, 0xA1, 0x67), // #93a167
                    new Color(0x6E, 0xAA, 0x78), // #6eaa78
                    new Color(0x55, 0x70, 0x64), // #557064
                    new Color(0x9D, 0x9F, 0x7F), // #9d9f7f
                    new Color(0x7E, 0x9E, 0x99), // #7e9e99
                    new Color(0x5D, 0x68, 0x72), // #5d6872
                    new Color(0x43, 0x34, 0x55)  // #433455
                };
        }

        return null;
    }
}