namespace blackbox.IOFile;

public static class TxtFileIO
{
    private static string extension = "txt";

    public static bool HasFile(string fileName)
    {
        return FileIO.HasFile(fileName, extension);
    }

    public static string Read(string fileName)
    {
        return FileIO.Read(fileName, extension);
    }

    public static void Create(string fileName, string content)
    {
        FileIO.Create(fileName, extension, content);
    }

    public static void Update(string fileName, string content)
    {
        FileIO.Update(fileName, extension, content);
    }

    public static void CreateOrUpdate(string fileName, string content)
    {
        FileIO.CreateOrUpdate(fileName, extension, content);
    }

    public static void Delete(string fileName)
    {
        FileIO.Delete(fileName, extension);
    }
}