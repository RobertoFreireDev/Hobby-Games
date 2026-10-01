namespace mono8.core.common;

public static class FileIO
{
    /// <summary>
    /// Called after every successful <see cref="Write"/> with the bare file name (e.g. "data.map")
    /// and its full contents. The web head uses this to mirror writes into browser localStorage so
    /// edits survive a page reload (the WASM in-memory filesystem is wiped on reload). Null on
    /// desktop, where <see cref="File.WriteAllText(string, string)"/> already persists to disk.
    /// </summary>
    public static Action<string, string> OnWrite;

    public static string Read(string fileName, string extension, string path = "")
    {
        try
        {
            var fullPath = BuildPath(fileName, extension, path);

            using (StreamReader reader = new StreamReader(fullPath))
            {
                return reader.ReadToEnd();
            }
        }
        catch
        {
            return string.Empty;
        }
        
    }

    public static void Write(string fileName, string extension, string content, string path = "")
    {
        var fullPath = BuildPath(fileName, extension, path);
        File.WriteAllText(fullPath, content);
        OnWrite?.Invoke($"{fileName}.{extension}", content);
    }

    public static string BuildPath(string fileName, string extension, string path)
    {
        var basePath = string.IsNullOrWhiteSpace(path)
            ? Directory.GetCurrentDirectory()
            : path;

        fileName += $".{extension}";
        return Path.Combine(basePath, fileName);
    }

    public static string[] SplitData(string data)
    {
        return data.Split('\n');
    }
}
