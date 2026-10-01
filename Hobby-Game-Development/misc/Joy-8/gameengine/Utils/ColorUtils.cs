using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;

namespace gameengine.Utils;

internal static class ColorUtils
{
    private static Color PrimaryColor;

    private static Color SecondaryColor;

    private static Color TertiaryColor;

    private static Color QuaternaryColor;

    private static Color Color5;

    private static Color Color6;

    private static Color Color7;

    private static Color Color8;

    private static Color Color9;

    private static Color Color10;

    private static Color Color11;

    private static Color Color12;

    private static Color Color13;

    private static Color Color14;

    private static Color Color15;

    private static Color Color16;

    private static int CurrentPalette;

    public static int GetCurrentPalette()
    {
        return CurrentPalette;
    }

    public static List<string> PaletteList { get; private set; } = new List<string>()
    {
        "#0a080d,#dfe9f5,#f7aaa8,#697594,#d4689a,#782c96,#e83562,#f2825c,#ffc76e,#88c44d,#3f9e59,#373461,#4854a8,#7199d9,#9e5252,#4d2536",
        "#000000,#fafafa,#999999,#666666,#1a1a1a,#333333,#4d4d4d,#666666,#808080,#999999,#b3b3b3,#cccccc,#e6e6e6,#f2f2f2,#d9d9d9,#bfbfbf",
        "#1f0e1c,#7ec4c1,#d26471,#34859d,#3e2137,#584563,#8c8fae,#9a6348,#d79b7d,#f5edba,#c0c741,#647d34,#e4943a,#9d303b,#17434b,#70377f",
        "#7e775d,#eef7d2,#cee1bd,#b4cb9f,#d7bc63,#9c8e5c,#f3f763,#dfdf80,#e9eb7a,#d1d06b,#8cb560,#a3d667,#c0aa60,#73a167,#b2e86d,#778f63",
        "#00474f,#ffbdbb,#f88c6e,#d4826b,#475b58,#225054,#6a645d,#8e6e61,#b17766,#156d8e,#467b96,#6b869b,#8e8f9f,#b199a3,#d5a3a7,#f8adac",
        "#65471e,#f8d8ab,#b57075,#dcab80,#b8aaaa,#fff5f5,#fca5c2,#ec4646,#ffa322,#f9fa93,#7bc188,#8ed3f8,#5989a3,#d793fa,#74518e,#1d173c",
        "#000000,#95cecd,#eeee77,#4c898b,#0e3e5b,#15894c,#95ce56,#f7a046,#d64b33,#5a340e,#b05670,#ffad93,#ffffff,#acaaac,#626562,#ad601a",
        "#0b0d0a,#b1b8a9,#dee6b8,#665f57,#383730,#82857b,#95bdb2,#5a7b85,#273245,#477a5a,#81ba78,#d4ea92,#b59766,#8f5450,#66403c,#40292f",
        "#272223,#f2d3ac,#e7a76c,#c28462,#905b54,#513a3d,#7a6977,#878c87,#b5c69a,#606b31,#b19e3f,#f8c65c,#d58b39,#996336,#6a422c,#b55b39",
        "#000000,#fff1e8,#3fa66f,#ab5236,#365987,#ffdd34,#50e112,#430067,#94216a,#ff004d,#ff8426,#0033ff,#29adff,#00ffcc,#c2c3c7,#5f574f",
        "#140c1c,#deeed6,#dad45e,#6daa2c,#6dc2ca,#442434,#30346d,#4e4a4e,#854c30,#346524,#d04648,#757161,#597dce,#d27d2c,#8595a1,#d2aa99",
        "#222533,#fafffc,#a3c0e6,#6275ba,#ffab7b,#ff6c7a,#dc435b,#3f48c2,#448de7,#2bdb72,#a7f547,#ffeb33,#f58931,#db4b3d,#a63d57,#36354d",
        "#000000,#e6e1f2,#ffd9f4,#7b8ac6,#b2b7e1,#595b7d,#fffcff,#e1adc3,#ad80a6,#fba2d7,#fae0c7,#f0abab,#97c4aa,#bfedf5,#73c9eb,#caaff5",
        "#1f2025,#e2d9e4,#6c9a9a,#52675d,#f3c893,#37403b,#e5987d,#cb5e5c,#72334c,#c0a5a9,#bf7d85,#804d53,#403038,#7c8fb2,#4c5274,#2e334d",
        "#4b3d44,#d1b187,#c77b58,#ae5d40,#79444a,#ba9158,#927441,#4d4539,#77743b,#b3a555,#d2c9a5,#8caba1,#4b726e,#574852,#847875,#ab9b8e",
        "#1a1c2c,#f4f4f4,#94b0c2,#566c86,#b13e53,#333c57,#ef7d57,#ffcd75,#5d275d,#a7f070,#38b764,#257179,#29366f,#3b5dc9,#41a6f6,#73eff7",
        "#010101,#fffffe,#ff7bdb,#17bbd3,#031b75,#108c00,#720c0a,#6c1c9e,#b25116,#b8b0a8,#4a4842,#0b63c4,#9bce00,#73f5d5,#e89e00,#fef255",
        "#000000,#fff0a0,#ee9852,#b68c56,#724c30,#291a13,#463007,#755a0b,#ab811d,#5e260e,#a1430f,#ff8b18,#f6bf3a,#552012,#9a361e,#eb5731",
        "#120919,#deeed6,#e5bba7,#a4b2bf,#4d4b44,#1b1f4b,#592942,#106836,#854a2f,#d04648,#ed8f3b,#ebd951,#61ad36,#5190c8,#776e87,#e384a2",
        "#27142b,#ede8e1,#a66372,#5d858c,#0a401a,#6d852c,#b3a724,#e6eb6a,#a7dbbb,#3d476e,#32244d,#d6c2ba,#bf9684,#733754,#451e3e,#2e0f29",
        "#000000,#ffffff,#ffffb0,#7e70ca,#a8734a,#e9b287,#772d26,#b66862,#85d4dc,#c5ffff,#a85fb4,#e99df5,#559e4a,#92df87,#42348b,#bdcc71",
        "#08050e,#ebd5bd,#66c3d9,#387cee,#8c1e2c,#dc443c,#ff8c66,#c75b38,#d66f24,#e4ba32,#21913b,#83b535,#3539a2,#998da2,#594e6f,#2b1a4b",        
        "#4e5d66,#b4c9d8,#ddb9a1,#a06b63,#a5a3b3,#7e8e99,#b0c09a,#8f9f91,#7a885e,#525747,#a0a294,#a3856d,#6f5f52,#d29a8d,#a0949a,#6e504d",
        "#373545,#e0e0e0,#c4b152,#5a6ead,#616478,#aed6f5,#4a8264,#5db365,#ad8c4b,#7c9fd9,#c9597a,#e8899e,#695661,#8f6f7a,#c4a082,#e5cea5",
    };

    public static Color GetColor(int Color)
    {
        switch (Color)
        {
            case 0:
                return new Color(0, 0, 0, 0);
            case 1:
                return PrimaryColor;
            case 2:
                return SecondaryColor;
            case 3:
                return TertiaryColor;
            case 4:
                return QuaternaryColor;
            case 5:
                return Color5;
            case 6:
                return Color6;
            case 7:
                return Color7;
            case 8:
                return Color8;
            case 9:
                return Color9;
            case 10:
                return Color10;
            case 11:
                return Color11;
            case 12:
                return Color12;
            case 13:
                return Color13;
            case 14:
                return Color14;
            case 15:
                return Color15;
            case 16:
                return Color16;
            default:
                return new Color(0, 0, 0, 0);
        }
    }

    public static Color GetColor(int Color, int paletteIndex)
    {
        var (color1, color2, color3, color4,
                color5, color6, color7, color8,
                color9, color10, color11, color12,
                color13, color14, color15, color16) = ColorUtils.GetPalette(paletteIndex);

        switch (Color)
        {
            case 0:
                return new Color(0, 0, 0, 0);
            case 1:
                return color1;
            case 2:
                return color2;
            case 3:
                return color3;
            case 4:
                return color4;
            case 5:
                return color5;
            case 6:
                return color6;
            case 7:
                return color7;
            case 8:
                return color8;
            case 9:
                return color9;
            case 10:
                return color10;
            case 11:
                return color11;
            case 12:
                return color12;
            case 13:
                return color13;
            case 14:
                return color14;
            case 15:
                return color15;
            case 16:
                return color16;
            default:
                return new Color(0, 0, 0, 0);
        }
    }

    public static void SetPalette(int index)
    {
        CurrentPalette = index;
        string[] colors = PaletteList[index].Split(',');
        PrimaryColor = GetColor(colors[0].Trim());
        SecondaryColor = GetColor(colors[1].Trim());
        TertiaryColor = GetColor(colors[2].Trim());
        QuaternaryColor = GetColor(colors[3].Trim());
        Color5 = GetColor(colors[4].Trim());
        Color6 = GetColor(colors[5].Trim());
        Color7 = GetColor(colors[6].Trim());
        Color8 = GetColor(colors[7].Trim());
        Color9 = GetColor(colors[8].Trim());
        Color10 = GetColor(colors[9].Trim());
        Color11 = GetColor(colors[10].Trim());
        Color12 = GetColor(colors[11].Trim());
        Color13 = GetColor(colors[12].Trim());
        Color14 = GetColor(colors[13].Trim());
        Color15 = GetColor(colors[14].Trim());
        Color16 = GetColor(colors[15].Trim());
    }

    public static (Color, Color, Color, Color, Color, Color, Color, Color, Color, Color, Color, Color, Color, Color, Color, Color) GetPalette(int index)
    {
        string[] colors = PaletteList[index].Split(',');
        return (
            GetColor(colors[0].Trim()),
            GetColor(colors[1].Trim()),
            GetColor(colors[2].Trim()),
            GetColor(colors[3].Trim()),
            GetColor(colors[4].Trim()),
            GetColor(colors[5].Trim()),
            GetColor(colors[6].Trim()),
            GetColor(colors[7].Trim()),
            GetColor(colors[8].Trim()),
            GetColor(colors[9].Trim()),
            GetColor(colors[10].Trim()),
            GetColor(colors[11].Trim()),
            GetColor(colors[12].Trim()),
            GetColor(colors[13].Trim()),
            GetColor(colors[14].Trim()),
            GetColor(colors[15].Trim())
        );
    }

    private static Color GetColor(string hexColor)
    {
        hexColor = hexColor.Substring(1);
        int r = Convert.ToInt32(hexColor.Substring(0, 2), 16);
        int g = Convert.ToInt32(hexColor.Substring(2, 2), 16);
        int b = Convert.ToInt32(hexColor.Substring(4, 2), 16);
        return new Color(r, g, b);
    }
}

