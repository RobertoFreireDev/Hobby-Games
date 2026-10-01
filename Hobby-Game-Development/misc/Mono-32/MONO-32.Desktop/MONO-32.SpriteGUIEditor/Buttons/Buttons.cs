using Buttons;
using Grid;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MONO_32.SpriteGUIEditor.Enums;
using MONO_32.SpriteGUIEditor.Extensions;
using System.Collections.Generic;

namespace MONO_32.SpriteGUIEditor.Buttons;

internal class Buttons
{
    public TextInputField TextInputField;

    private List<Button> buttons = new List<Button>();
    private Button selectedButton;

    public Buttons(ButtonTypeEnum buttonSelected)
    {
        var saveButton = new Button(
            ButtonTypeEnum.Save,
            UIVariables.Textures["save_button"]);
        var pencilButton = new Button(
            ButtonTypeEnum.Pencil,
            UIVariables.Textures["pencil_button"]);
        var eraserButton = new Button(
            ButtonTypeEnum.Eraser,
            UIVariables.Textures["eraser_button"]);
        var bucketButton = new Button(
            ButtonTypeEnum.Bucket,
            UIVariables.Textures["bucket_button"]);

        buttons = new List<Button>()
            {
                saveButton,
                bucketButton,
                eraserButton,
                pencilButton
            };

        var paintButtons = 0;

        foreach (var button in buttons)
        {
            if (button.Type == buttonSelected)
            {
                selectedButton = button;
            }

            if (button.Type == ButtonTypeEnum.Save)
            {
                button.Rectangle = new Rectangle(
                    UIVariables.Edition.Left + button.Rectangle.X,
                    UIVariables.Edition.Top + button.Rectangle.Y,
                    button.Rectangle.Width,
                    button.Rectangle.Height
                );
            }
            else
            {
                button.Rectangle = new Rectangle(
                    UIVariables.PaintButtons.Left + paintButtons * UIVariables.ButtonSize + button.Rectangle.X,
                    UIVariables.PaintButtons.Top + button.Rectangle.Y,
                    button.Rectangle.Width,
                    button.Rectangle.Height
                );
                paintButtons++;
            }
        }

        TextInputField = new TextInputField(
            UIVariables.DefaultFont,
            new Rectangle(
                saveButton.Rectangle.Right + UIVariables.Margin,
                saveButton.Rectangle.Y,
                UIVariables.TextInputFieldWidth,
                saveButton.Rectangle.Height));
    }

    public void Update(Point mousePosition, SpriteGrid spriteGrid, GraphicsDevice graphicsDevice)
    {
        for (int i = 0; i < buttons.Count; i++)
        {
            if (buttons[i].Rectangle.Contains(mousePosition))
            {
                switch (buttons[i].Type)
                {
                    case Enums.ButtonTypeEnum.Save:
                        if (!string.IsNullOrWhiteSpace(UIVariables.TextFileName))
                        {
                            var exportTexture = spriteGrid.ConvertToTexture2D(graphicsDevice);
                            exportTexture.SaveImageAsPng(UIVariables.TextFileName + ".png");
                        }
                        break;
                    case Enums.ButtonTypeEnum.Bucket:
                        selectedButton = buttons[i]; 
                        UIVariables.PaintMode = Enums.PaintModeEnum.Bucket;
                        break;
                    case Enums.ButtonTypeEnum.Pencil:
                        selectedButton = buttons[i]; 
                        UIVariables.PaintMode = Enums.PaintModeEnum.Pencil;
                        break;
                    case Enums.ButtonTypeEnum.Eraser:
                        selectedButton = buttons[i]; 
                        UIVariables.PaintMode = Enums.PaintModeEnum.Eraser;
                        break;
                }
            }
        }
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        for (int i = 0; i < buttons.Count; i++)
        {
            spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend);
            var color = buttons[i] == selectedButton ? Color.Green : Color.Black;

            if (buttons[i].Type == ButtonTypeEnum.Save && string.IsNullOrWhiteSpace(UIVariables.TextFileName))
            {
                color = Color.DarkGray;
            }
            spriteBatch.Draw(buttons[i].Texture, buttons[i].Rectangle, color);
            spriteBatch.End();
        }
    }
}
