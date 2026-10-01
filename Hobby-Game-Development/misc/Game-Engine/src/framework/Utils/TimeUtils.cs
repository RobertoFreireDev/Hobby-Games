using Microsoft.Xna.Framework;
using System;

namespace blackbox.Utils;

public static class TimeUtils
{
    public static double ElapsedTime { private set; get; } = 0;
    public static double Delta { private set; get; }
    public static int FPS => _fps;
    private static int _frameCounter = 0;
    private static double _elapsedTime = 0;
    private static int _fps = 0;
    private static double[] Timers = new double[16];

    public static void Reset()
    {
        ElapsedTime = 0;
        _frameCounter = 0;
        _elapsedTime = 0;
        _fps = 0;
        Timers = new double[16];
    }

    public static void Update(GameTime gameTime)
    {
        Delta = gameTime.ElapsedGameTime.TotalSeconds;

        _frameCounter++;
        ElapsedTime += Delta;
        _elapsedTime += Delta;
        if (ScreenUtils.IsFocused && !GFW.GamePaused)
        {
            for (int i = 0; i < Timers.Length; i++)
            {
                Timers[i] += Delta;
            }
        }

        if (_elapsedTime >= 1)
        {
            _fps = _frameCounter;
            _frameCounter = 0;
            _elapsedTime = 0;
        }
    }

    public static void StartTimer(int i)
    {
        if (i < 0 || i >= Timers.Length)
            return;

        Timers[i] = 0.0;
    }

    public static double GetTime(int i = 0, int d = 2)
    {
        if (i < 0 || i >= Timers.Length)
            return 0.0;

        return Math.Round(Timers[i], d);
    }

    public static string GetDateTime(int i)
    {
        if (i == 1)
        {
            return DateTime.UtcNow.ToLongDateString();
        }

        if (i == 2)
        {
            return DateTime.UtcNow.ToLongTimeString();
        }

        if (i == 3)
        {
            return DateTime.UtcNow.ToShortDateString();
        }

        if (i == 4)
        {
            return DateTime.UtcNow.ToShortTimeString();
        }

        return DateTime.UtcNow.ToString();
    }
}
