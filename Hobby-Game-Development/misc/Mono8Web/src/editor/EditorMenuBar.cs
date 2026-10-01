namespace mono8.editor;

internal class EditorMenuBar
{
    private const int MapViewSplitIcon = 13;
    private const int MapViewFullIcon = 14;
    private const int SfxViewPrimaryIcon = 30;
    private const int SfxViewAltIcon = 31;
    private const int SaveIcon = 61;
    private const int LoadIcon = 62;

    private const string SaveLabel = "Save Cart";
    private const string LoadLabel = "Load Cart";
    private const string MapViewLabel = "Toggle Map View";
    private const string SfxViewLabel = "Toggle Sfx View";

    private readonly IEditorAPI _api;
    private readonly EditorRegistry _registry;
    private readonly Button[] _buttons;
    private readonly Button _saveButton;
    private readonly Button _loadButton;
    private readonly Button _mapViewToggle;
    private readonly Button _sfxViewToggle;

    // Shows the hovered button's name along the bottom bar, like a tooltip.
    private readonly EventNotifier _hoverLabel;

    public Rectangle Bounds { get; }

    public EditorMenuBar(IEditorAPI api, EditorRegistry registry)
    {
        _api = api;
        _registry = registry;

        int size = Constants.GameDataSizes.TileSize;
        Bounds = new Rectangle(0, 0, Constants.Screen.ResolutionX, size);

        _hoverLabel = new EventNotifier(api, 0.5f, 1, Constants.Screen.ResolutionY - size + 1);

        // Save/Load export/import the whole cartridge; they sit at the far left, always visible.
        _saveButton = new Button(2, 0, size, SaveIcon);
        _loadButton = new Button(2 + size, 0, size, LoadIcon);

        // The contextual view toggle follows, after a small gap.
        int toggleX = 2 + size * 2 + 4;
        _mapViewToggle = new Button(toggleX, 0, size, MapViewSplitIcon);
        _sfxViewToggle = new Button(toggleX, 0, size, SfxViewPrimaryIcon);

        int count = registry.Entries.Count;
        int startX = Constants.Screen.ResolutionX - count * size;
        _buttons = new Button[count];
        for (int i = 0; i < count; i++)
        {
            _buttons[i] = new Button(startX + i * size, 0, size, registry.Entries[i].IconIndex);
        }
    }

    public void Update(float elapsedSeconds)
    {
        var mouse = _api.mousexy();

        // Age the previous frame's label first, then (re)arm it for whatever is hovered now,
        // so a freshly hovered button's name is never aged out in the same frame it is set.
        _hoverLabel.Update(elapsedSeconds);
        string hovered = HoverLabel(mouse);
        if (hovered != null)
        {
            _hoverLabel.AddEvent(hovered);
        }

        if (_saveButton.IsClicked(_api, mouse))
        {
            _api.ExportCart();
            return;
        }

        if (_loadButton.IsClicked(_api, mouse))
        {
            _api.ImportCart();
            return;
        }

        if (_registry.Active is MapEditor mapEditor && _mapViewToggle.IsClicked(_api, mouse))
        {
            mapEditor.FullMapView = !mapEditor.FullMapView;
            return;
        }

        if (_registry.Active is SfxEditor sfxEditor && _sfxViewToggle.IsClicked(_api, mouse))
        {
            sfxEditor.AltView = !sfxEditor.AltView;
            return;
        }

        for (int i = 0; i < _buttons.Length; i++)
        {
            if (_buttons[i].IsClicked(_api, mouse))
            {
                _registry.SwitchTo(i);
                break;
            }
        }
    }

    // The name of the button under the mouse, or null when hovering none. Mirrors the
    // click order so the contextual view toggles only match while their editor is active.
    private string HoverLabel((int x, int y) mouse)
    {
        if (_saveButton.Bounds.Contains(mouse.x, mouse.y)) return SaveLabel;
        if (_loadButton.Bounds.Contains(mouse.x, mouse.y)) return LoadLabel;

        if (_registry.Active is MapEditor && _mapViewToggle.Bounds.Contains(mouse.x, mouse.y)) return MapViewLabel;
        if (_registry.Active is SfxEditor && _sfxViewToggle.Bounds.Contains(mouse.x, mouse.y)) return SfxViewLabel;

        for (int i = 0; i < _buttons.Length; i++)
        {
            if (_buttons[i].Bounds.Contains(mouse.x, mouse.y)) return _registry.Entries[i].Label;
        }

        return null;
    }

    public void Draw()
    {
        _api.rectfill(0, 0, Constants.Screen.ResolutionX, Bounds.Height - 1, Constants.Colors.Orange);

        _saveButton.Draw(_api, false);
        _loadButton.Draw(_api, false);

        for (int i = 0; i < _buttons.Length; i++)
        {
            _buttons[i].Draw(_api, i == _registry.ActiveIndex);
        }

        if (_registry.Active is MapEditor mapEditor)
        {
            _mapViewToggle.IconIndex = mapEditor.FullMapView ? MapViewFullIcon : MapViewSplitIcon;
            _mapViewToggle.Draw(_api, mapEditor.FullMapView);
        }
        else if (_registry.Active is SfxEditor sfxEditor)
        {
            _sfxViewToggle.IconIndex = sfxEditor.AltView ? SfxViewAltIcon : SfxViewPrimaryIcon;
            _sfxViewToggle.Draw(_api, sfxEditor.AltView);
        }

        _hoverLabel.Draw();
    }
}
