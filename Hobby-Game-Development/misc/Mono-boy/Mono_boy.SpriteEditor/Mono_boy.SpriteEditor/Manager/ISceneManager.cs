using Mono_boy.SpriteEditor.Enums;

namespace Mono_boy.SpriteEditor.Manager;

internal interface ISceneManager
{
    public SceneEnum SceneType { get;}

    public NavButtonEnum NavButton { get; }    

    public void LoadContent();

    public void Reload();

    public void Update();

    public void Draw();
}