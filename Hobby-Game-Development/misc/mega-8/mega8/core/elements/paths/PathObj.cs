namespace mega8.core.elements.paths;

/// <summary>
/// A path moves an object along a sequence of (x,y) positions over a fixed duration.
/// Supports easing (time), shape (space), loop, pingpong, pause/resume/restart.
/// </summary>
public struct PathObj
{
    // ── Definition ───────────────────────────────────────────────────────
    public (float X, float Y)[] Points;
    public float Duration;      // total seconds for one pass
    public int Easing;        // 0-7  (same ids as Tween)
    public bool Loop;
    public bool PingPong;
    public int Shape;         // 0=Linear 1=SmallCurve 2=Circular 3=BigCurve 4=Rectangular

    // ── Runtime state ────────────────────────────────────────────────────
    public float Elapsed;       // seconds within current pass
    public bool Paused;
    public bool IsComplete;    // true when non-looping path has finished
    public int Direction;     // +1 forward, -1 backward (pingpong)

    // ── Current output ───────────────────────────────────────────────────
    public float X;
    public float Y;

    // ────────────────────────────────────────────────────────────────────

    public void Update(float dt)
    {
        if (Paused || IsComplete) return;
        if (Duration <= 0f || Points == null || Points.Length < 2) return;

        Elapsed += dt * Direction;

        // Handle end-of-pass
        if (Direction > 0 && Elapsed >= Duration)
        {
            if (PingPong)
            {
                Elapsed = Duration;
                Direction = -1;
            }
            else if (Loop)
            {
                Elapsed -= Duration;
            }
            else
            {
                Elapsed = Duration;
                IsComplete = true;
            }
        }
        else if (Direction < 0 && Elapsed <= 0f)
        {
            if (Loop)
            {
                Elapsed += Duration;
                Direction = +1;
            }
            else
            {
                Elapsed = 0f;
                Direction = +1;
                IsComplete = true;
            }
        }

        Evaluate();
    }

    /// <summary>Recalculate X/Y from current Elapsed without advancing time.</summary>
    public void Evaluate()
    {
        if (Points == null || Points.Length == 0) return;
        if (Points.Length == 1) { X = Points[0].X; Y = Points[0].Y; return; }
        if (Duration <= 0f) { X = Points[^1].X; Y = Points[^1].Y; return; }

        float t01 = Math.Clamp(Elapsed / Duration, 0f, 1f);
        float te = ApplyEasing(t01);                          // eased 0..1

        int segCount = Points.Length - 1;
        float segF = te * segCount;
        int seg = Math.Clamp((int)segF, 0, segCount - 1);
        float local = segF - seg;                           // 0..1 within segment

        (X, Y) = Interpolate(seg, local);
    }

    // ── Shape interpolation ──────────────────────────────────────────────

    private (float x, float y) Interpolate(int seg, float t)
    {
        var p0 = Points[seg];
        var p1 = Points[seg + 1];

        return Shape switch
        {
            0 => LinearLerp(p0, p1, t),
            1 => CatmullRom(seg, t, tension: 0.5f),           // small curve
            2 => CircularArc(p0, p1, t),
            3 => CatmullRom(seg, t, tension: 1.5f),           // big curve (over-tensioned)
            4 => Rectangular(p0, p1, t),
            _ => LinearLerp(p0, p1, t)
        };
    }

    private static (float x, float y) LinearLerp(
        (float X, float Y) a, (float X, float Y) b, float t)
        => (a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t);

    /// <summary>
    /// Catmull-Rom spline through all path points.
    /// tension=0.5 → standard smooth, tension=1.5 → exaggerated overshoot.
    /// </summary>
    private (float x, float y) CatmullRom(int seg, float t, float tension)
    {
        // Clamp ghost points at ends
        var p0 = Points[Math.Max(seg - 1, 0)];
        var p1 = Points[seg];
        var p2 = Points[Math.Min(seg + 1, Points.Length - 1)];
        var p3 = Points[Math.Min(seg + 2, Points.Length - 1)];

        float t2 = t * t, t3 = t2 * t;

        float CatmullCoord(float v0, float v1, float v2, float v3)
        {
            float m1 = tension * (v2 - v0);
            float m2 = tension * (v3 - v1);
            return (2 * v1 - 2 * v2 + m1 + m2) * t3
                 + (-3 * v1 + 3 * v2 - 2 * m1 - m2) * t2
                 + m1 * t
                 + v1;
        }

        return (
            CatmullCoord(p0.X, p1.X, p2.X, p3.X),
            CatmullCoord(p0.Y, p1.Y, p2.Y, p3.Y)
        );
    }

    /// <summary>
    /// Arc through p0 and p1 whose midpoint bulges perpendicular to the chord.
    /// The bulge magnitude is half the chord length, giving a quarter-circle feel.
    /// </summary>
    private static (float x, float y) CircularArc(
        (float X, float Y) p0, (float X, float Y) p1, float t)
    {
        float mx = (p0.X + p1.X) * 0.5f;
        float my = (p0.Y + p1.Y) * 0.5f;

        // Perpendicular to the chord (normalised)
        float dx = p1.X - p0.X, dy = p1.Y - p0.Y;
        float len = MathF.Sqrt(dx * dx + dy * dy);
        if (len < 1e-6f) return LinearLerp(p0, p1, t);

        float nx = -dy / len * len * 0.5f;
        float ny = dx / len * len * 0.5f;

        // Control point sits at midpoint + perpendicular bulge
        float cx = mx + nx, cy = my + ny;

        // Quadratic Bézier: p0 → ctrl → p1
        float u = 1f - t;
        return (
            u * u * p0.X + 2 * u * t * cx + t * t * p1.X,
            u * u * p0.Y + 2 * u * t * cy + t * t * p1.Y
        );
    }

    /// <summary>
    /// Right-angle movement: travel horizontally first, then vertically.
    /// </summary>
    private static (float x, float y) Rectangular(
        (float X, float Y) p0, (float X, float Y) p1, float t)
    {
        if (t < 0.5f)
            return (p0.X + (p1.X - p0.X) * (t / 0.5f), p0.Y);
        else
            return (p1.X, p0.Y + (p1.Y - p0.Y) * ((t - 0.5f) / 0.5f));
    }

    // ── Easing (mirrors Tween) ───────────────────────────────────────────

    private float ApplyEasing(float t) => Easing switch
    {
        0 => t,
        1 => t * t,
        2 => t * (2f - t),
        3 => t < 0.5f ? 2f * t * t : -1f + (4f - 2f * t) * t,
        4 => 1f - MathF.Cos(t * MathF.PI * 0.5f),
        5 => t * t,
        6 => t * t * t,
        7 => 1f - MathF.Sqrt(1f - t * t),
        _ => t
    };
}