using System.Text;

namespace mega8.core.graphics;

public static class ColorPalette
{
    private static Color[] Colors = new Color[Constants.GameDataSizes.ColorPalette];

    private const string DefaultColorSwap = "0123456789abcdefghijklmnopqrstuvw";

    private static string ColorSwap = DefaultColorSwap;

    private static string BackupColorSwap = DefaultColorSwap;

    private static string defaultPalette = "#000000,#ffffff,#f7aaa8,#697594,#d4689a,#782c96,#e83562,#f2825c,#ffc76e,#88c44d,#3f9e59,#373461,#4854a8,#7199d9,#9e5252,#4d2536," +
        "#1a1c2c,#5d275d,#b13e53,#ffa300,#ffec27,#a7f070,#38b764,#257179,#29366f,#3b5dc9,#41a6f6,#73eff7,#f4f4f4,#94b0c2,#566c86,#333c57";

    public static bool IsDefaultColorSwap()
    {
        return ColorSwap == DefaultColorSwap;
    }

    public static void BackUpColorSwap()
    {
        BackupColorSwap = ColorSwap;
    }

    public static void UseBackUpColorSwap()
    {
        ColorSwap = BackupColorSwap;
    }

    public static void ResetColorSwap()
    {
        ColorSwap = DefaultColorSwap;
    }

    public static void SetSwapOneColor(Dictionary<int, int> colors)
    {
        if (colors == null || colors.Count == 0)
        {
            return;
        }

        var newColorSwap = new StringBuilder(ColorSwap);

        foreach (var kvp in colors)
        {
            int sourceColor = kvp.Key;
            int targetColor = kvp.Value;

            if (sourceColor < Constants.GameDataSizes.ColorPaletteMin ||
                sourceColor > Constants.GameDataSizes.ColorPaletteMax ||
                targetColor < 0 ||
                targetColor > Constants.GameDataSizes.ColorPaletteMax)
            {
                continue;
            }

            newColorSwap[sourceColor] = IndexToColorChar(targetColor);
        }

        ColorSwap = newColorSwap.ToString();
    }

    private static char IndexToColorChar(int index)
    {
        if (index >= 0 && index <= 9)
            return (char)('0' + index);

        if (index >= 10 && index <= Constants.GameDataSizes.ColorPaletteMax)
            return (char)('a' + (index - 10));

        throw new ArgumentOutOfRangeException(nameof(index));
    }

    public static void SetColorSwap(string colorSwap)
    {
        if (string.IsNullOrWhiteSpace(colorSwap))
        {
            ColorSwap = DefaultColorSwap;
            return;
        }

        if (colorSwap.Trim().Length != Constants.GameDataSizes.ColorPaletteMax
                || colorSwap.Any(c => ColorCharToIndex(c) < 0))
        {
            return;
        }

        ColorSwap = "0" + colorSwap;
    }

    public static int ColorCharToIndex(char ch)
    {
        if (ch >= '0' && ch <= '9') return ch - '0';
        if (ch >= 'a' && ch <= 'w') return ch - 'a' + 10;
        return -1;
    }

    public static Color GetColor(int pos)
    {
        if (pos < 0 || pos >= Constants.GameDataSizes.ColorPalette)
        {
            return new Color(0, 0, 0, 0);
        }

        return Colors[ColorCharToIndex(ColorSwap[pos])]; 
    }

    public static void SetColorPalette()
    {
        string[] colors = defaultPalette.Split(',');

        Colors[0] = new Color(0, 0, 0, 0);
        for (int i = 0; i < Constants.GameDataSizes.ColorPalette - 1; i++)
        {
            Colors[i+1] = GetColor(colors[i].Trim());
        }

        Color GetColor(string hexColor)
        {
            try
            {
                hexColor = hexColor.Substring(1);
                int r = Convert.ToInt32(hexColor.Substring(0, 2), 16);
                int g = Convert.ToInt32(hexColor.Substring(2, 2), 16);
                int b = Convert.ToInt32(hexColor.Substring(4, 2), 16);
                return new Color(r, g, b);
            }
            catch
            {
                return Colors[0];
            }
        }
    }
}