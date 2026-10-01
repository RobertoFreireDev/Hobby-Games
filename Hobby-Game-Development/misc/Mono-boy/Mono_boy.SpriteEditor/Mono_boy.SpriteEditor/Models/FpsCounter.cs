using Mono_boy.SpriteEditor.Manager;

namespace Mono_boy.SpriteEditor.Models;

public class FpsCounter
{
    private double elapsedTime;
    private int frameCounter;
    public int Fps { get; private set; }

    public FpsCounter()
    {
        elapsedTime = 0;
        frameCounter = 0;
        Fps = 0;
    }

    public void Update()
    {
        elapsedTime += GlobalManager.DeltaTime;
        frameCounter++;

        if (elapsedTime >= 1)
        {
            Fps = frameCounter;
            frameCounter = 0;
            elapsedTime = 0;
        }
    }
}
