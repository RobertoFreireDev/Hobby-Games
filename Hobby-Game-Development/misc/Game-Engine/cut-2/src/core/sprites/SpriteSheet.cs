namespace cut2.core.sprites;

internal class SpriteSheet
{
    public int[,] Data;

    public Texture2D Texture;

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

                if (ch >= '0' && ch <= '4')
                    Data[r, c] = ch - '0';
            }
        }
    }

    private void DataToTextures()
    {
        int width = Data.GetLength(1);
        int height = Data.GetLength(0);
        int pixelCount = width * height;

        var fullData = new Color[pixelCount];
        for (int y = 0; y < height; y++)
            for (int x = 0; x < width; x++)
            {
                int colorIndex = Data[y, x];
                fullData[y * width + x] = colorIndex == 0
                    ? Color.Transparent
                    : ColorPalette.GetColor(colorIndex);
            }
        Texture = new Texture2D(cut2.GraphicsDeviceRef, width, height);
        Texture.SetData(fullData);
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

        cut2.SpriteBatch.Draw(Texture, destination, source, effects);
    }
}