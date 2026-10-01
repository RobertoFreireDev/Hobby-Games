namespace mega8.core.elements;

public class Counter
{
    public float Time { get; private set; }

    public Counter()
    {
        Time = 0f;
    }

    public void Reset(float diff)
    {
        Time = diff;
    }

    public void Update(GameTime gameTime)
    {
        Time += (float)gameTime.ElapsedGameTime.TotalSeconds;
    }
}