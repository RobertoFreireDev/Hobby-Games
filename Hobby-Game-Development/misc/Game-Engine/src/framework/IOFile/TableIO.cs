using System.Collections.Generic;
using System.Linq;
using System;
using System.Text;
using blackbox.Utils;

namespace blackbox.IOFile;

public static class TableIO
{
    private const string extension = "csv";
    private const string path = "Tables";
    private const char delimiter = ';';

    public static void CreateTable(string tableName, params string[] columns)
    {
        if (columns == null || columns.Length == 0)
        {
            LuaError.SetError("Table must have at least one column");
            return;
        }

        var header = string.Join(delimiter.ToString(), columns.Select(FormatValue));
        FileIO.Create(tableName, extension, header, path);
    }

    public static List<string[]> ReadTable(string tableName)
    {
        if (!FileIO.HasFile(tableName, extension, path))
            return new List<string[]>();

        var content = FileIO.Read(tableName, extension, path);
        content = content.Replace("\r\n", "\n");
        var lines = content.Split('\n', StringSplitOptions.RemoveEmptyEntries);

        return lines.Select(ParseCsvLine).ToList();
    }

    public static void InsertRow(string tableName, params string[] values)
    {
        var table = ReadTable(tableName);
        if (table.Count == 0) return;

        if (values.Length != table[0].Length)
        {
            LuaError.SetError("Column count mismatch");
            return;
        }

        table.Add(values.Select(FormatValue).ToArray());
        WriteTable(tableName, table);
    }

    public static void UpdateRow(string tableName, int rowIndex, params string[] values)
    {
        var table = ReadTable(tableName);
        if (rowIndex < 0 || rowIndex + 1 >= table.Count)
        {
            LuaError.SetError("Invalid row index");
            return;
        }

        table[rowIndex + 1] = values.Select(FormatValue).ToArray();
        WriteTable(tableName, table);
    }

    public static void UpdateCell(string tableName, int rowIndex, int columnIndex, string value)
    {
        var table = ReadTable(tableName);

        if (rowIndex < 0 || rowIndex + 1 >= table.Count)
        {
            LuaError.SetError($"Table {tableName}: Invalid row index {rowIndex}. Table contains {table.Count} lines");
            return;
        }

        if (columnIndex < 0 || columnIndex >= table[0].Length)
        {
            LuaError.SetError($"Table {tableName}: Invalid column index {columnIndex}. Table contains {table[0].Length} columns");
            return;
        }

        table[rowIndex + 1][columnIndex] = FormatValue(value);
        WriteTable(tableName, table);
    }

    public static void DeleteRow(string tableName, int rowIndex)
    {
        var table = ReadTable(tableName);

        if (rowIndex < 0 || rowIndex + 1 >= table.Count)
        {
            LuaError.SetError("Invalid row index");
            return;
        }

        table.RemoveAt(rowIndex + 1);
        WriteTable(tableName, table);
    }

    private static void WriteTable(string tableName, List<string[]> table)
    {
        var sb = new StringBuilder();

        foreach (var row in table)
        {
            sb.AppendLine(string.Join(delimiter.ToString(), row));
        }

        var content = sb.ToString().TrimEnd();
        content = content
            .Replace("\r\n", "\n");

        FileIO.Update(tableName, extension, content, path);
    }

    private static List<char> allowedChars = new List<char>()
    {
        '0','1','2','3','4','5','6','7','8','9',
        'A','B','C','D','E','F','G','H','I','J','K',
        'L','M','N','O','P','Q','R','S','T','U','V',
        'W','X','Y','Z',
        'a','b','c','d','e','f','g','h','i','j','k',
        'l','m','n','o','p','q','r','s','t','u','v',
        'w','x','y','z',
        ',','.',':','[',']','{','}',
        '|','#','$','%','(',')','!','?',
        '"','\'','_','+','-','=','*','/','\\',
        '<','>',' ','~','Ꮖ'
    }; // Don't allow delimiter ';'

    private static string FormatValue(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return string.Empty;

        return new string(value.Where(c => allowedChars.Contains(c)).ToArray());
    }

    private static string[] ParseCsvLine(string line)
    {
        var result = new List<string>();
        var sb = new StringBuilder();
        bool inQuotes = false;

        for (int i = 0; i < line.Length; i++)
        {
            char c = line[i];

            if (c == delimiter)
            {
                result.Add(sb.ToString());
                sb.Clear();
            }
            else
            {
                sb.Append(c);
            }
        }

        result.Add(sb.ToString());
        return result.ToArray();
    }
}

