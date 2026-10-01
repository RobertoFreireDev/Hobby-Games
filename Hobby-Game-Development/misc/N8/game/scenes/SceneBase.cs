namespace game.scenes;

internal abstract class SceneBase
{
    internal static SceneBase Current { get; private set; }

    internal static void ChangeTo(SceneBase next)
    {
        Current?.OnExit();
        NGame.API.load(next.DataFolder);
        Current = next;
        Current.OnEnter();
    }

    protected abstract string DataFolder { get; }
    protected abstract void OnEnter();
    protected abstract void OnExit();
    internal abstract void Update(float elapsedGameTime);
    internal abstract void Draw();
}
