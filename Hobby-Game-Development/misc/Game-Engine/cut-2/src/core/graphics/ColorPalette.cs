namespace cut2.core.graphics;

public static class ColorPalette
{
    private static Color[] Colors = new Color[Constants.GameDataSizes.ColorPalette];
    private static readonly Color TransparentColor = new Color(0, 0, 0, 0);
    private static readonly string[] ColorPalettes = new string[Constants.GameDataSizes.QtyPalettes]
        {
            "#7c3f58,#eb6b6f,#f9a875,#fff6d3",
            "#332c50,#46878f,#94e344,#e2f3e4",
            "#211e20,#555568,#a0a08b,#e9efec",
            "#051f39,#4a2480,#c53a9d,#ff8e80",
            "#081820,#346856,#88c070,#e0f8d0",
            "#5a3921,#6b8c42,#7bc67b,#ffffb5",
            "#181010,#84739c,#f7b58c,#ffefff",
            "#372a39,#aa644d,#788374,#f5e9bf"
        };

    public static Color GetColor(int id)
    {
        if (id == - 2)
        {
            return Color.Black;
        }

        if (id == -1)
        {
            return Color.White;
        }

        if (id < Constants.GameDataSizes.ColorPaletteMin || id > Constants.GameDataSizes.ColorPaletteMax)
        {
            return TransparentColor;
        }

        return Colors[id]; 
    }

    public static void SetColorPalette(int id = 0)
    {
        string[] colors = ColorPalettes[id].Split(',');

        Colors[0] = TransparentColor;
        for (int i = 0; i < Constants.GameDataSizes.ColorPaletteMax; i++)
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