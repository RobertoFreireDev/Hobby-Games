using System;

namespace Mono_boy.SpriteEditor.Models;

public class CurrentTime
{
    public int Year { get; set; }
    public int Month { get; set; }
    public int Day { get; set; }
    public int Hour { get; set; }
    public int Minute { get; set; }
    public int Second { get; set; }

    public CurrentTime()
    {
        DateTime currentDateTime = DateTime.Now;

        Year = currentDateTime.Year;
        Month = currentDateTime.Month;
        Day = currentDateTime.Day;
        Hour = currentDateTime.Hour;
        Minute = currentDateTime.Minute;
        Second = currentDateTime.Second;
    }
}
