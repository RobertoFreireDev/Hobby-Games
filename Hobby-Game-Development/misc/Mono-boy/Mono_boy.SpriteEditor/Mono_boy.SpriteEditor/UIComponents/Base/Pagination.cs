namespace Mono_boy.SpriteEditor.UIComponents.Base;

internal class Pagination
{
    public int Row;
    public int Column;
    public int CurrentPage;
    public int Pages;

    public Pagination(int row, int column, int currentPage, int pages)
    {
        Row = row;
        Column = column;
        CurrentPage = currentPage;
        Pages = pages;
    }

    public void NextPage()
    {
        if (CurrentPage < Pages - 1)
        {
            CurrentPage++;
        }
    }

    public void PreviousPage()
    {
        if (CurrentPage > 0)
        {
            CurrentPage--;
        }
    }

    public void FirstPage()
    {
        CurrentPage = 0;
    }

    public void LastPage()
    {
        CurrentPage = Pages - 1;
    }
}
