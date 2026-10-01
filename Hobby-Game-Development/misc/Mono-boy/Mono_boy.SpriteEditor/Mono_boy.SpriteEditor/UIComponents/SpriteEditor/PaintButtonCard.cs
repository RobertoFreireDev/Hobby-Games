using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using System;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class PaintButtonCard : Card, IDisposable
{
    public static PaintModeEnum? PaintMode;

    public PaintButtonCard(Rectangle bounds) : base(bounds, InitializeComponents())
    {
        foreach (var button in _components)
        {
            button.Clicked += Button_Clicked;
        }
    }

    private static List<UIComponent> InitializeComponents()
    {
        // default button
        PaintMode = PaintModeEnum.Pencil;
        var defaultButton = new PaintButton(GlobalManager.Textures["pencil_button"], new Rectangle(6, 6, 32, 32), PaintModeEnum.Pencil, 1);
        defaultButton.Selected = true;

        var buttons = new List<UIComponent>()
        {
            defaultButton,
            new PaintButton(GlobalManager.Textures["bucket_button"], new Rectangle(6,44,32,32), PaintModeEnum.Bucket, 1),
            new PaintButton(GlobalManager.Textures["eraser_button"], new Rectangle(6,82,32,32), PaintModeEnum.Eraser, 1),
            new PaintButton(GlobalManager.Textures["line_button"], new Rectangle(6,120,32,32), PaintModeEnum.Line, 1),
            new PaintButton(GlobalManager.Textures["rectangle_button"], new Rectangle(6,158,32,32), PaintModeEnum.Rectangle, 1),
            new PaintButton(GlobalManager.Textures["circle_button"], new Rectangle(6,196,32,32), PaintModeEnum.Circle, 1),
            new PaintButton(GlobalManager.Textures["selection_rectangle_button"], new Rectangle(6,232,32,32), PaintModeEnum.SelectionRectangle, 1),
        };

        return buttons;
    }

    public void Dispose()
    {
        foreach (var button in _components)
        {
            button.Clicked -= Button_Clicked;
        }
    }

    private void Button_Clicked(object sender, EventArgs e)
    {
        foreach (var component in _components)
        {
            component.Selected = component is PaintButton && sender is PaintButton && component == sender;
            if (component.Selected)
            {
                PaintMode = ((PaintButton)component).PaintMode;
            }
        }
    }
}
