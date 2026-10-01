using System.Drawing;

namespace mega8.core.elements;

internal class Entity
{
    public int X;
    public int Y;
    public int ZIndex;
    public bool[] Flags = new bool[Constants.Entity.QtyFlags];
    public bool[] CollideWithFlags = new bool[Constants.Entity.QtyFlags];
    public int BodyX;
    public int BodyY;
    public int BodyW;
    public int BodyH;
    public IDrawableElement[] Elements = new IDrawableElement[Constants.Entity.MaxElements];
    public bool[] ActiveElements = new bool[Constants.Entity.MaxElements];
    private Dictionary<int, int> ColorSwap = new Dictionary<int, int>();

    public Entity(
        int x, 
        int y, 
        int zIndex)
    {
        X = x;
        Y = y;
        ZIndex = Constants.Scene.ClampZindex(zIndex);
    }

    private static bool[] GetBits(int value)
    {
        return new bool[8]
        {
            (value & 0b00000001) != 0,
            (value & 0b00000010) != 0,
            (value & 0b00000100) != 0,
            (value & 0b00001000) != 0,
            (value & 0b00010000) != 0,
            (value & 0b00100000) != 0,
            (value & 0b01000000) != 0,
            (value & 0b10000000) != 0
        };
    }

    public void SetActiveElements(int activeElements) => ActiveElements = GetBits(activeElements);
    public void SetFlags(int flags) => Flags = GetBits(flags);
    public void SetCollisionFlags(int collideWithFlags) => CollideWithFlags = GetBits(collideWithFlags);

    public void SetBody(int x, int y, int w, int h)
    {
        BodyX = x;
        BodyY = y;
        BodyW = w;
        BodyH = h;
    }

    private static bool FlagsMatch(bool[] entityFlags, bool[] mask)
    {
        if (mask == null) return true;

        int length = Math.Min(entityFlags.Length, mask.Length);
        for (int i = 0; i < length; i++)
        {
            // If the mask requires true and the entity has it, return true immediately
            if (mask[i] && entityFlags[i])
            {
                return true;
            }
        }

        return false;
    }

    private (int x1, int y1, int x2, int y2) WorldBody()
    {
        int x1 = X + BodyX;
        int y1 = Y + BodyY;
        return (x1, y1, x1 + BodyW - 1, y1 + BodyH - 1);
    }

    public bool CollidesWithPoint(int px, int py, bool[] flagsMask = null)
    {
        if (!FlagsMatch(Flags, flagsMask)) return false;
        var (x1, y1, x2, y2) = WorldBody();
        return px >= x1 && px <= x2 && py >= y1 && py <= y2;
    }

    public bool CollidesWithRect(int rx, int ry, int rw, int rh, bool[] flagsMask = null)
    {
        if (!FlagsMatch(Flags, flagsMask)) return false;
        var (x1, y1, x2, y2) = WorldBody();
        int rx2 = rx + rw - 1;
        int ry2 = ry + rh - 1;
        return x1 <= rx2 && x2 >= rx && y1 <= ry2 && y2 >= ry;
    }

    public T SetElement<T>(int key, T newElement) where T : IDrawableElement
    {
        Elements[key] = newElement;

        return (T) Elements[key];
    }

    public void RemoveElement(int key)
    {
        Elements[key] = null;
    }

    public void SwapColorIndex(int ci, int cj)
    {
        ci = Math.Clamp(ci, Constants.GameDataSizes.ColorPaletteMin, Constants.GameDataSizes.ColorPaletteMax);
        cj = Math.Clamp(cj, 0, Constants.GameDataSizes.ColorPaletteMax);

        if (ColorSwap.ContainsKey(ci))
        {
            ColorSwap[ci] = cj;
        }
        else
        {
            ColorSwap.Add(ci, cj);
        }
    }

    public void Draw()
    {
        var needSwap = ColorSwap != null && ColorSwap.Count > 0;

        if (needSwap)
        {
            ColorPalette.SetSwapOneColor(ColorSwap);
        }
        var activeElements = new List<IDrawableElement>();

        for (int i = 0; i < Constants.Entity.MaxElements; i++)
        {
            if (ActiveElements[i] && Elements[i] != null)
            {
                activeElements.Add(Elements[i]);
            }
        }

        foreach (var orderedActiveElement in activeElements.OrderBy(e => e.ZIndex))
        {
            orderedActiveElement.Draw(X, Y);
        }

        if (needSwap)
        {
            ColorPalette.UseBackUpColorSwap();
        }
    }
}
