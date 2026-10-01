using gameengine.Data;
using gameengine.Scenes.Rename;
using gameengine.Scenes.Shared.UI;
using gameengine.Utils;
using Microsoft.Xna.Framework;
using System;

namespace gameengine.Scenes;

internal class SaveScene : Scene
{
    private SingleLineTextField _textField;
    private ConfirmButton _confirmButton;

    public SaveScene(SceneManager sceneManager) : base(sceneManager)
    {
        var buttonWidth = 84;
        var buttonHeight = 30;
        var textMaxLentgh = 30;
        var scale = 3f;
        var offSet = -1;
        var width = (int)(textMaxLentgh * (FontAtlasUtils.MediumFont.CharWidth + offSet) * scale);
        var center = GameEngineData.BaseBoxCenter;
        var textHeight = (int)(FontAtlasUtils.MediumFont.CharHeight * scale + 10);
        GameEngineData.UIComponentBounds[UIComponentEnum.NewSceneSaveTextField] = new Rectangle(
            center.X - width/2,
            center.Y,
            width,
            textHeight);
        _textField = new SingleLineTextField(UIComponentEnum.NewSceneSaveTextField, textMaxLentgh, scale, offSet);
        GameEngineData.UIComponentBounds[UIComponentEnum.RenameConfirmButton] = new Rectangle(
            center.X + width / 2 - buttonWidth,
            center.Y + textHeight + 5,
            buttonWidth,
            buttonHeight);
        _confirmButton = new ConfirmButton(UIComponentEnum.RenameConfirmButton, scale, offSet);
        _confirmButton.Clicked += ConfirmButton_Clicked;

        GameEngineData.Images.Add(
                "renametextfieldborder",
                TextureUtils.CreateRectangleTexture(GameEngineData.UIComponentBounds[UIComponentEnum.NewSceneSaveTextField], 3));
        GameEngineData.Images.Add(
                "confirmbuttonborder",
                TextureUtils.CreateRectangleTexture(GameEngineData.UIComponentBounds[UIComponentEnum.RenameConfirmButton], 3));
    }

    public override void Update()
    {
        _textField.Update();
        _confirmButton.Update();
        _confirmButton.Disable = string.IsNullOrWhiteSpace(_textField.GetTextValue());
    }

    public override void Draw()
    {
        FrameworkData.SpriteBatch.DrawText_MediumFont("Enter the title of your game:", new Vector2(20, 30), 1, 1f, 3f, -1);
        _textField.Draw();
        _confirmButton.Draw();
    }

    public override void Exit()
    {
    }

    public override void Enter()
    {
        _textField.UpdateTextValue(GameData.Name);
    }

    private void ConfirmButton_Clicked(object sender, EventArgs e)
    {
        var gameName = _textField.GetTextValue();
        if (string.IsNullOrWhiteSpace(gameName))
        {
            return;
        }

        GameData.UpdateName(gameName);
        _sceneManager.ChangeScene(_sceneManager.MenuScene);
    }
}