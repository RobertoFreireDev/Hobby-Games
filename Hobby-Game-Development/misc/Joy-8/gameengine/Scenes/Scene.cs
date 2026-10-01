using gameengine.Utils.Objects;

namespace gameengine.Scenes;

internal abstract class Scene
{
    private Timer _startSceneTimer = new Timer(0.2f);
    protected SceneManager _sceneManager;

    public Scene(SceneManager sceneManager)
    {
        _sceneManager = sceneManager;
    }

    public void BaseUpdate()
    {
        _startSceneTimer.Update();
        if (_startSceneTimer.IsActive())
        {
            return;
        }

        Update();
    }

    public abstract void Update();

    public void BaseDraw()
    {
        Draw();
    }

    public abstract void Draw();

    public void BaseExit()
    {
        Exit();
    }

    public abstract void Exit();

    public void BaseEnter()
    {
        _startSceneTimer.Enable();
        Enter();
    }

    public abstract void Enter();
}
