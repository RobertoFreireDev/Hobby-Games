namespace mega8.core.elements.particles;

internal struct Particle
{
    // ── Main ─────────────────────────────────────────────────────────────
    public float X;
    public float Y;
    public float Age;          // seconds elapsed
    public float TTL;          // seconds to live (must be > 0)

    public int SprIdx;
    public int SprSize;

    // ── Animation (optional – arrays are null when not set) ───────────────
    public int[]? SprIdxs;      // 8 entries
    public int[]? SprSizeIdxs; // 8 entries

    // current animation frame: min(7, floor(Age / TTL * 8))
    public int CurrentFrame => Math.Min(7, (int)(Age / TTL * 8));
    public bool HasAnimation => SprIdxs != null;

    // ── Movement (per-frame arrays, null = single value from index 0) ─────
    public float[]? VelocityXs;
    public float[]? VelocityYs;
    public float[]? AccelerationXs;
    public float[]? AccelerationYs;
    public float[]? MaxSpeedXs;
    public float[]? MaxSpeedYs;

    // scalar fallbacks (used when arrays are null)
    public float VelocityX;
    public float VelocityY;
    public float AccelerationX;
    public float AccelerationY;
    public float MaxSpeedX;
    public float MaxSpeedY;

    // ── Rotation (per-frame arrays, null = single value) ──────────────────
    public float[]? Angles;
    public float[]? RotationCenterXs;
    public float[]? RotationCenterYs;
    public float[]? AngularVelocities;
    public float[]? AngularAccelerations;
    public float[]? MaxAngularSpeeds;

    // scalar fallbacks
    public float Angle;
    public float RotationCenterX;
    public float RotationCenterY;
    public float AngularVelocity;
    public float AngularAcceleration;
    public float MaxAngularSpeed;

    public bool HasMovementAnim => VelocityXs != null;
    public bool HasRotationAnim => Angles != null;
}