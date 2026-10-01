using Mono_boy.SpriteEditor.UIComponents.Base;

namespace Mono_boy.SpriteEditor.UIComponents.ConfigEditor;

internal class ConfigOption
{
    public TextField Label;

    public Dropdown Dropdown;

    public ConfigOption(TextField label, Dropdown dropdown)
    {
        Label = label;
        Dropdown = dropdown;
    }

    public void Update()
    {
        Dropdown.Update();
    }

    public void Draw()
    {
        Label.Draw();
        Dropdown.Draw();
    }
}
