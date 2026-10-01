namespace game;

public class NGame
{
    public static INPico8API API;

    public NGame(INPico8API api)
    {
        API = api;
    }

    public void Init()
    {
        SceneBase.ChangeTo(new LastPilotScene());
    }

    public void Update(float elapsedGameTime)
    {
        SceneBase.Current.Update(elapsedGameTime);
    }

    public void Draw()
    {
        SceneBase.Current.Draw();
    }
}
