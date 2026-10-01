namespace mega8.core.elements.particles;

/// <summary>
/// Manages thousands of particles with a compact array pool.
/// Particles are stored contiguously; dead slots are swapped with the tail
/// so iteration stays tight (no gaps, no per-frame allocation).
/// </summary>
internal sealed class ParticleSystem
{
    private const int BucketCount = Constants.Scene.ZindexMax - Constants.Scene.ZindexMin + 1;
    private const int DefaultBucketCapacity = 512;

    private readonly Particle[][] _buckets;
    private readonly int[] _counts;

    public ParticleSystem(int bucketCapacity = DefaultBucketCapacity)
    {
        _buckets = new Particle[BucketCount][];
        _counts = new int[BucketCount];
        for (int i = 0; i < BucketCount; i++)
            _buckets[i] = new Particle[bucketCapacity];
    }

    // ── Emitter ──────────────────────────────────────────────────────────

    public void Emit(in Particle p, int zIndex)
    {
        if (p.TTL <= 0f) return;

        int z = Constants.Scene.ClampZindex(zIndex);
        ref int count = ref _counts[z];
        Particle[] bucket = _buckets[z];

        if (count == bucket.Length)
            GrowBucket(z);

        _buckets[z][count++] = p;
    }

    // ── Update ───────────────────────────────────────────────────────────

    public void Update(float dt)
    {
        for (int z = 0; z < BucketCount; z++)
        {
            Particle[] bucket = _buckets[z];
            int i = 0;
            while (i < _counts[z])
            {
                ref Particle p = ref bucket[i];
                p.Age += dt;

                if (p.Age >= p.TTL)
                {
                    bucket[i] = bucket[--_counts[z]];
                    continue;
                }

                UpdateMovement(ref p, dt);
                UpdateRotation(ref p, dt);

                if (p.HasAnimation)
                    UpdateAnimation(ref p);

                i++;
            }
        }
    }

    private static void UpdateMovement(ref Particle p, float dt)
    {
        float vx, vy, ax, ay, maxX, maxY;

        if (p.HasMovementAnim)
        {
            int f = p.CurrentFrame;
            vx = p.VelocityXs![f];
            vy = p.VelocityYs![f];
            ax = p.AccelerationXs![f];
            ay = p.AccelerationYs![f];
            maxX = p.MaxSpeedXs![f];
            maxY = p.MaxSpeedYs![f];

            // write back so the running velocity integrates frame-to-frame
            p.VelocityX = vx;
            p.VelocityY = vy;
        }
        else
        {
            ax = p.AccelerationX;
            ay = p.AccelerationY;
            maxX = p.MaxSpeedX;
            maxY = p.MaxSpeedY;

            p.VelocityX += ax * dt;
            p.VelocityY += ay * dt;

            if (maxX > 0f) p.VelocityX = Math.Clamp(p.VelocityX, -maxX, maxX);
            if (maxY > 0f) p.VelocityY = Math.Clamp(p.VelocityY, -maxY, maxY);
        }

        p.X += p.VelocityX * dt;
        p.Y += p.VelocityY * dt;
    }

    private static void UpdateRotation(ref Particle p, float dt)
    {
        float av, aa, maxAv, cx, cy;

        if (p.HasRotationAnim)
        {
            int f = p.CurrentFrame;
            av = p.AngularVelocities![f];
            aa = p.AngularAccelerations![f];
            maxAv = p.MaxAngularSpeeds![f];
            cx = p.RotationCenterXs![f];
            cy = p.RotationCenterYs![f];
            p.Angle = p.Angles![f];
            p.AngularVelocity = av;
        }
        else
        {
            p.AngularVelocity += p.AngularAcceleration * dt;
            if (p.MaxAngularSpeed > 0f)
                p.AngularVelocity = Math.Clamp(p.AngularVelocity,
                    -p.MaxAngularSpeed, p.MaxAngularSpeed);
            p.Angle += p.AngularVelocity * dt;

            av = p.AngularVelocity;
            cx = p.RotationCenterX;
            cy = p.RotationCenterY;
        }

        float dx = p.X - cx;
        float dy = p.Y - cy;
        float cos = MathF.Cos(av * dt);
        float sin = MathF.Sin(av * dt);

        p.X = cx + dx * cos - dy * sin;
        p.Y = cy + dx * sin + dy * cos;
    }

    private static void UpdateAnimation(ref Particle p)
    {
        int f = p.CurrentFrame;

        if (p.SprIdxs != null) p.SprIdx = p.SprIdxs[f];
        if (p.SprSizeIdxs != null) p.SprSize = p.SprSizeIdxs[f];
    }

    // ── Draw ─────────────────────────────────────────────────────────────

    /// <summary>
    /// Draws all particles in a specific z-index bucket.
    /// Called by Scene.Draw() in z-order interleaved with entities.
    /// </summary>
    public void DrawBucket(int zIndex)
    {
        int z = Constants.Scene.ClampZindex(zIndex);
        Particle[] bucket = _buckets[z];
        int count = _counts[z];

        for (int i = 0; i < count; i++)
        {
            ref readonly Particle p = ref bucket[i];
            LuaBinding.SpriteSheet.Draw(
                p.SprIdx, (int)p.X, (int)p.Y,
                p.SprSize);
        }
    }

    // ── Housekeeping ─────────────────────────────────────────────────────

    public void Clear()
    {
        for (int z = 0; z < BucketCount; z++)
            _counts[z] = 0;
    }

    private void GrowBucket(int z)
    {
        var bigger = new Particle[_buckets[z].Length * 2];
        Array.Copy(_buckets[z], bigger, _counts[z]);
        _buckets[z] = bigger;
    }
}
