namespace mono8.core.common;

/// <summary>
/// Bridge for exporting/importing a whole cartridge through a host-provided file dialog. The web
/// head wires these to browser "save as" download and file-picker dialogs (see index.html); on
/// desktop they stay null, so the menu-bar Save/Load buttons are harmless no-ops. This mirrors the
/// <see cref="FileIO.OnWrite"/> pattern: the shared engine stays framework-agnostic and each head
/// supplies the host-specific IO.
/// </summary>
public static class CartIO
{
    /// <summary>Save <c>content</c> via a host "save as" dialog (<c>suggestedName</c> is the default file
    /// name), then invoke <c>onDone</c> once the dialog is dismissed (whether the user saved or cancelled).</summary>
    public static Action<string, string, Action> OnExport;

    /// <summary>Open a host file picker; when the user chooses a file, invoke <c>apply</c> with its text.
    /// Either way, invoke <c>onDone</c> once the dialog is dismissed (whether a file was chosen or cancelled).</summary>
    public static Action<Action<string>, Action> OnImport;
}
