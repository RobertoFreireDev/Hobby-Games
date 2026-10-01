using System.Collections.Generic;
using System.Text;

namespace mono8.core.common;

/// <summary>
/// Parses and builds the single-file Mono8 cartridge format: one text file whose sections are
/// introduced by a <c>__{extension}__</c> header line (PICO-8 style), e.g. <c>__gfx__</c> or
/// <c>__map__</c>. Everything from a header up to the next header (or end of file) is that section's
/// body. This replaces the previous one-file-per-extension layout, so a whole cartridge round-trips
/// through a single <c>data.mono8</c> file.
/// </summary>
public static class DataFile
{
    /// <summary>Splits a cartridge file into section bodies keyed by extension name (the header
    /// text without the surrounding <c>__</c>). Content before the first header is ignored.</summary>
    public static Dictionary<string, string> Parse(string raw)
    {
        var sections = new Dictionary<string, string>();
        if (string.IsNullOrEmpty(raw)) return sections;

        string current = null;
        var body = new StringBuilder();

        foreach (var line in raw.Split('\n'))
        {
            var header = SectionName(line);
            if (header != null)
            {
                if (current != null) sections[current] = TrimTrailingNewline(body);
                current = header;
                body.Clear();
                continue;
            }
            if (current == null) continue; // ignore anything before the first header
            body.Append(line).Append('\n');
        }
        if (current != null) sections[current] = TrimTrailingNewline(body);
        return sections;
    }

    /// <summary>Builds a cartridge file from ordered <c>(extension, body)</c> sections. Each body is
    /// the same newline-joined text the sheets produce, so it round-trips through <see cref="Parse"/>.</summary>
    public static string Build(IEnumerable<(string Extension, string Body)> sections)
    {
        var sb = new StringBuilder();
        foreach (var (extension, body) in sections)
        {
            sb.Append("__").Append(extension).Append("__\n");
            sb.Append(body);
            if (body.Length == 0 || body[body.Length - 1] != '\n') sb.Append('\n');
        }
        return sb.ToString();
    }

    // A header is a line that is nothing but __name__ (surrounding whitespace tolerated).
    private static string SectionName(string line)
    {
        var trimmed = line.Trim();
        if (trimmed.Length > 4 && trimmed.StartsWith("__") && trimmed.EndsWith("__"))
            return trimmed.Substring(2, trimmed.Length - 4);
        return null;
    }

    // Drop the single '\n' appended after the last body line so a section round-trips to exactly
    // the text the sheet handed us (which is the join of its lines, with no trailing newline).
    private static string TrimTrailingNewline(StringBuilder body)
    {
        if (body.Length > 0 && body[body.Length - 1] == '\n') body.Length -= 1;
        return body.ToString();
    }
}
