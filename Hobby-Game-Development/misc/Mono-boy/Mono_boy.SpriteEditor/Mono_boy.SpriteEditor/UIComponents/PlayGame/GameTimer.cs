using Mono_boy.SpriteEditor.Manager;

namespace Mono_boy.SpriteEditor.UIComponents.PlayGame;
public static class GameTimer
{
    private static float elapsedTime;

    public static void Reset()
    {
        elapsedTime = 0f;
    }

    public static void Update()
    {
        elapsedTime += GlobalManager.DeltaTime;
    }

    public static double ToSeconds()
    {
        return elapsedTime;
    }
}
