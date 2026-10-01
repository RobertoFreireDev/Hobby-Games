namespace mega8.core.elements;

internal interface IDrawableElement
{
    public int ZIndex { get; set; }
    public bool IsAnimation { get; set; }
    void Update(GameTime game);
    void Draw(int parentX = 0, int parentY = 0);
}

internal class PixelElement : IDrawableElement
{
    public int ZIndex { get; set; }
    public int X { get; set; }
    public int Y { get; set; }
    public bool IsAnimation { get; set; }  = false;
    private int ColorIndex;

    public void Update(GameTime game)
    {

    }

    public PixelElement(int x, int y, int colorIndex, int zIndex)
    {
        X = x; 
        Y = y; 
        ColorIndex = colorIndex;
        ZIndex = Constants.Scene.ClampZindex(zIndex);
    }

    public void Draw(int parentX = 0, int parentY = 0)
    {
        Mega8.SpriteBatch.DrawPixel(parentX + X, parentY + Y, ColorIndex);
    }
}

internal class RectElement : IDrawableElement
{
    public int ZIndex { get; set; }
    public int X { get; set; }
    public int Y { get; set; }
    public bool IsAnimation { get; set; } = false;
    public bool Fill;
    private int W;
    private int H;
    private int ColorIndex;

    public RectElement(bool fill, int x, int y, int w, int h, int colorIndex, int zIndex)
    {
        Fill = fill;
        X = x;
        Y = y;
        W = w;
        H = h;
        ColorIndex = colorIndex;
        ZIndex = Constants.Scene.ClampZindex(zIndex);
    }

    public void Update(GameTime game)
    {

    }

    public void Draw(int parentX = 0, int parentY = 0)
    {
        if (Fill)
        {
            Mega8.SpriteBatch.DrawRectFill(parentX + X, parentY + Y, W, H, ColorIndex);
            return;
        }

        Mega8.SpriteBatch.DrawRect(parentX + X, parentY + Y, W, H, ColorIndex);
    }
}

internal class SpriteElement : IDrawableElement
{
    public int ZIndex { get; set; } 
    public int SpriteIndex;
    public int X { get; set; }
    public int Y { get; set; }
    public bool IsAnimation { get; set; } = false;
    private int Scale;
    private int Width;
    private int Height;
    private bool FlipX;
    private bool FlipY;

    public SpriteElement(int spriteIndex, int x, int y, int zIndex, int scale = 1, int w = 1, int h = 1, bool flipX = false, bool flipY = false)
    {
        SpriteIndex = spriteIndex;
        X = x;
        Y = y;
        ZIndex = Constants.Scene.ClampZindex(zIndex);
        // TO DO: Clamp with min and max values. Put min and max in constant class
        Scale = scale; 
        Width = w; 
        Height = h;
        FlipX = flipX;
        FlipY = flipY;
    }

    public void Update(GameTime game)
    {

    }

    public void Draw(int parentX = 0, int parentY = 0)
    {
        LuaBinding.SpriteSheet.Draw(
                SpriteIndex, parentX + X, parentY + Y,
                Scale, Width, Height, FlipX, FlipY);
    }
}

internal class AnimationElement : IDrawableElement
{
    public int ZIndex { get; set; }
    public bool IsAnimation { get; set; } = true;
    public List<IDrawableElement> Frames = new List<IDrawableElement>();
    public int CurrentFrameIndex = 0;
    public bool Paused = false;
    public float Speed = 8f;

    private Counter Counter = new Counter();

    public AnimationElement(int zIndex, bool paused = false, float speed = 8f) 
    {
        ZIndex = Constants.Scene.ClampZindex(zIndex);
        Paused = paused;
        Speed = speed;
    }

    public void AddRectFrame(bool fill, int x, int y, int w, int h, int colorIndex)
    {
        Frames.Add(new RectElement(fill, x, y, w, h, colorIndex, 0));
    }

    public void Update(GameTime game)
    {
        if (Paused || Frames.Count == 0)
            return;

        Counter.Update(game);

        float frameDuration = 1f / Speed;
        if (Counter.Time >= frameDuration)
        {
            Counter.Reset(Counter.Time - frameDuration);
            CurrentFrameIndex++;
            if (CurrentFrameIndex >= Frames.Count)
            {
                CurrentFrameIndex = 0;
            }             
        }
    }

    public void Draw(int parentX = 0, int parentY = 0)
    {
        if (Frames.Count == 0)
            return;

        Frames[CurrentFrameIndex].Draw(parentX, parentY);
    }
}