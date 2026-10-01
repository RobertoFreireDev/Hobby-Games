namespace mega8.core.elements.tweens;

public struct Tween
{
    public float From;
    public float To;
    public float Duration;   // seconds
    public float Elapsed;    // seconds elapsed since (re)start
    public int Easing;     // 0-7

    /// <summary>Current interpolated value. Ready to read after Update().</summary>
    public float Value;

    public bool IsComplete => Elapsed >= Duration;

    public void Update(float dt)
    {
        if (Duration <= 0f) { Value = To; return; }

        Elapsed = Math.Min(Elapsed + dt, Duration);
        float t = Elapsed / Duration;   // 0..1
        Value = From + (To - From) * Ease(t);
    }

    // ── Easing functions ─────────────────────────────────────────────────
    // All map t ∈ [0,1] → [0,1]
    private float Ease(float t) => Easing switch
    {
        0 => t,                                         // linear
        1 => t * t,                                     // ease in  (quad)
        2 => t * (2f - t),                              // ease out (quad)
        3 => t < 0.5f ? 2f * t * t                      // ease in/out (quad)
                      : -1f + (4f - 2f * t) * t,
        4 => 1f - MathF.Cos(t * MathF.PI * 0.5f),      // sine in
        5 => t * t,                                     // quad  (alias for 1, kept explicit)
        6 => t * t * t,                                 // cubic in
        7 => 1f - MathF.Sqrt(1f - t * t),              // circ in
        _ => t
    };
}