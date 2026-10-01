using System;

namespace blackbox.Utils;

public static class ArrayUtils
{
    public static string IntArrayToString(int[,] data)
    {
        int rows = data.GetLength(0);
        int cols = data.GetLength(1);

        var sb = new System.Text.StringBuilder();

        for (int y = 0; y < rows; y++)
        {
            for (int x = 0; x < cols; x++)
            {
                sb.Append(data[y, x]);

                if (x < cols - 1)
                    sb.Append(",");
            }

            if (y < rows - 1)
                sb.Append('\n');
        }

        return sb.ToString();
    }

    public static void StringToIntArray(int[,] data, string input)
    {
        int dataRows = data.GetLength(0);
        int dataCols = data.GetLength(1);
        string[] rows = input.Split(new[] { '\n' }, StringSplitOptions.RemoveEmptyEntries);
        int rowCount = rows.Length;
        int colCount = rows[0].Split(',').Length;

        if (dataRows != rowCount || dataCols != colCount)
        {
            return;
        }

        for (int y = 0; y < rowCount; y++)
        {
            string[] cols = rows[y].Split(',');
            if (cols.Length != colCount)
                throw new FormatException("Inconsistent number of columns in input string.");

            for (int x = 0; x < colCount; x++)
            {
                data[y, x] = int.Parse(cols[x]);
            }
        }
    }
}
