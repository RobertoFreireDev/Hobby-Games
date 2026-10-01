namespace mega8.core.sprites;

internal class SpriteSheet
{
    public int[,] Data;

    public Texture2D[] Textures; // [0] = full color, [1..32] = per-color white masks

    public Rectangle[] TileRects;

    public void LoadSprites(string[] sheet)
    {
        LoadData(sheet);
        DataToTextures();
        CalculateTileRects();
    }

    private void CalculateTileRects()
    {
        int columns = Constants.GameDataSizes.SpriteSheetColumns;
        int rows = Constants.GameDataSizes.SpriteSheetRows;
        int size = Constants.GameDataSizes.TileSize;
        int total = columns * rows;
        TileRects = new Rectangle[total];
        for (int i = 0; i < total; i++)
        {
            int x = (i % columns) * size;
            int y = (i / columns) * size;
            TileRects[i] = new Rectangle(x, y, size, size);
        }
    }

    private void LoadData(string[] sheet)
    {
        Data = new int[Constants.GameDataSizes.SpriteSheetY, Constants.GameDataSizes.SpriteSheetX];

        for (int r = 0; r < 128; r++)
        {
            for (int c = 0; c < 128; c++)
            {
                char ch = sheet?[r]?[c] ?? '0';

                if (ch >= '0' && ch <= '9')
                    Data[r, c] = ch - '0';
                else if (ch >= 'a' && ch <= 'w')
                    Data[r, c] = ch - 'a' + 10;
            }
        }
    }

    private void DataToTextures()
    {
        int width = Data.GetLength(1);
        int height = Data.GetLength(0);
        int pixelCount = width * height;

        Textures = new Texture2D[33];

        // Textures[0]: full color, color 0 = transparent
        var fullData = new Color[pixelCount];
        for (int y = 0; y < height; y++)
            for (int x = 0; x < width; x++)
            {
                int colorIndex = Data[y, x];
                fullData[y * width + x] = colorIndex == 0
                    ? Color.Transparent
                    : ColorPalette.GetColor(colorIndex);
            }
        Textures[0] = new Texture2D(Mega8.GraphicsDeviceRef, width, height);
        Textures[0].SetData(fullData);

        // Textures[1..32]: white mask for each palette color, everything else transparent
        for (int colorIndex = Constants.GameDataSizes.ColorPaletteMin; colorIndex <= Constants.GameDataSizes.ColorPaletteMax; colorIndex++)
        {
            var maskData = new Color[pixelCount];
            for (int y = 0; y < height; y++)
                for (int x = 0; x < width; x++)
                    maskData[y * width + x] = Data[y, x] == colorIndex
                        ? Color.White
                        : Color.Transparent;

            Textures[colorIndex] = new Texture2D(Mega8.GraphicsDeviceRef, width, height);
            Textures[colorIndex].SetData(maskData);
        }
    }

    public void Draw(
        int n, int x, int y, int scale, int w = 1, int h = 1,
        bool flipX = false, bool flipY = false)
    {
        var source = new Rectangle(
            (n % Constants.GameDataSizes.SpriteSheetColumns) * Constants.GameDataSizes.TileSize,
            (n / Constants.GameDataSizes.SpriteSheetColumns) * Constants.GameDataSizes.TileSize,
            w * Constants.GameDataSizes.TileSize,
            h * Constants.GameDataSizes.TileSize);
        var destination = new Rectangle(
            x, y,
            w * Constants.GameDataSizes.TileSize * scale,
            h * Constants.GameDataSizes.TileSize * scale);

        SpriteEffects effects = SpriteEffects.None;
        if (flipX) effects |= SpriteEffects.FlipHorizontally;
        if (flipY) effects |= SpriteEffects.FlipVertically;

        if (ColorPalette.IsDefaultColorSwap())
        {
            Mega8.SpriteBatch.Draw(Textures[0], destination, source, Color.White, effects);
            return;
        }

        for (int i = Constants.GameDataSizes.ColorPaletteMin; i < Constants.GameDataSizes.ColorPaletteMax; i++)
        {
            Color tint = ColorPalette.GetColor(i);
            Mega8.SpriteBatch.Draw(Textures[i], destination, source, tint, effects);
        }
    }
}