using Microsoft.Xna.Framework;
using System.Linq;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Utils;
using System;
using Mono_boy.SpriteEditor.Input;

namespace Mono_boy.SpriteEditor.UIComponents.SongEditor;

internal class Piano
{
    public Point Position;
    public static int StartNote = 24;
    public int BlackNotesNumber = 21;
    public static int NotesNumber = 52; 
    public int CurrentTimeIndex = 0;
    public static int SongLength = 800;
    public int CurrentOctave = 4;
    public int FirstOctave = 2;
    public int LastOctave = 7;
    public int CurrentPage = 0;
    public int RowsPerPage = 50;
    public int Pages;
    public int MaxLengthOneNote = 16;
    public int CurrentNoteInTime;

    // Draw values
    public int WhiteKeyWidth = 30;
    public int WhiteKeyHeight = 100;
    public int BlackKeyWidth = 16;
    public int BlackKeyHeight = 60;
    public int SizeY = 8;
    public int Pointer = 0;

    public Piano()
    {
        Position = new Point((GlobalManager.GraphicsDevice.Viewport.Width - (NotesNumber - BlackNotesNumber) * WhiteKeyWidth) /2, 82);
        Pages = SongLength / RowsPerPage;
        SizeY = (GlobalManager.GraphicsDevice.Viewport.Height - 250) / 50;
    }

    public void Update()
    {
        HandleOctaves();
        HandleNotes();
        HandleCursor();
        HandlePage();
        HandleSpeed();
        DeleteNote();
        PlayNotes();
        SetDefaultNoteInTime();
    }

    private void HandleSpeed()
    {
        var decSpeed = InputStateManager.IsRReleased();
        var incSpeed = InputStateManager.IsTReleased();

        if (decSpeed)
        {
            if (SongEditorManager.SongMinLength > SongEditorManager.MinSpeed)
            {
                SongEditorManager.SongMinLength -= 2;
            }
        }
        else if (incSpeed)
        {
            if (SongEditorManager.SongMinLength < SongEditorManager.MaxSpeed)
            {
                SongEditorManager.SongMinLength += 2;
            }
        }
    }

    private void HandlePage()
    {
        var previousPage = InputStateManager.IsQReleased();
        var nextPage = InputStateManager.IsWReleased();

        if (previousPage)
        {
            if (CurrentTimeIndex - RowsPerPage > 0)
            {
                CurrentTimeIndex = CurrentTimeIndex - RowsPerPage;
                Pointer -= RowsPerPage;
            }
            else
            {
                CurrentTimeIndex = 0;
                Pointer = 0;
            }
            Pointer = Math.Max(Pointer, 0);
        }
        else if (nextPage)
        {
            if (CurrentTimeIndex + RowsPerPage < SongLength - 1)
            {
                CurrentTimeIndex = CurrentTimeIndex + RowsPerPage;
                Pointer += RowsPerPage;
            }
            else
            {
                CurrentTimeIndex = SongLength - 1;
                Pointer = SongLength - 1;
            }
            Pointer = Math.Min(Pointer, SongLength - RowsPerPage);
        }

        CurrentPage = CurrentTimeIndex / RowsPerPage;
    }

    public void SetDefaultNoteInTime()
    {
        if (SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, CurrentNoteInTime] > 0)
        {
            return;
        }

        for (int i = 0; i < NotesNumber; i++)
        {
            if (SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, i] > 0)
            {
                CurrentNoteInTime = i;
                return;
            }
        }
    }

    private void HandleCursor()
    {
        var up = InputStateManager.IsUpJustPressed();
        var down = InputStateManager.IsDownJustPressed();
        var left = InputStateManager.IsLeftJustPressed();
        var right = InputStateManager.IsRightJustPressed();

        if (up && CurrentTimeIndex > 0)
        {
            CurrentTimeIndex -= 1;
            if (Pointer > 0 && CurrentTimeIndex < Pointer + MaxLengthOneNote)
            {
                Pointer -= 1;
            }
        }
        else if (down && CurrentTimeIndex < SongLength - 1)
        {
            CurrentTimeIndex += 1;
            if (Pointer < SongLength - RowsPerPage && CurrentTimeIndex > Pointer + RowsPerPage - MaxLengthOneNote)
            {
                Pointer += 1;
            }
        }
        else if (left)
        {
            for (int i = CurrentNoteInTime - 1; i >= 0; i--)
            {
                if (SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, i] > 0)
                {
                    CurrentNoteInTime = i;
                    break;
                }
            }
        }
        else if (right)
        {
            for (int i = CurrentNoteInTime + 1; i < NotesNumber; i++)
            {
                if (SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, i] > 0)
                {
                    CurrentNoteInTime = i;
                    break;
                }
            }
        }
    }

    public void PlayNotes()
    {
        if (!InputStateManager.IsSpaceReleased())
        {
            return;
        }

        var melodyId = $"melody{SongEditorManager.CurrentSong}";
        if (Sfx.IsPlaying(melodyId))
        {
            Sfx.Stop(melodyId);
            return;
        }

        Sfx.AddOrUpdateMelody(
            melodyId,
            Sfx.CreateMelody(
                SongEditorManager.Songs[SongEditorManager.CurrentSong],
                SongEditorManager.SongMinLength, 
                SongLength, 
                NotesNumber, 
                StartNote));
        Sfx.Play(melodyId);
    }

    public void DeleteNote()
    {
        if (!InputStateManager.IsDelJustPressed())
        {
            return;
        }

        SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, CurrentNoteInTime] = 0;
    }

    public void HandleOctaves()
    {
        if (InputStateManager.Is2Pressed())
        {
            CurrentOctave = 2;
        }
        else if (InputStateManager.Is3Pressed())
        {
            CurrentOctave = 3;
        }
        else if (InputStateManager.Is4Pressed())
        {
            CurrentOctave = 4;
        }
        else if (InputStateManager.Is5Pressed())
        {
            CurrentOctave = 5;
        }
        else if (InputStateManager.Is6Pressed())
        {
            CurrentOctave = 6;
        }
        else if (InputStateManager.Is7Pressed())
        {
            CurrentOctave = 7;
        }
    }

    public void HandleNotes()
    {
        if (InputStateManager.IsAReleased())
        {
            SetNote(InputStateManager.IsControlPressed() ? 1 : 0);
        }
        if (InputStateManager.IsSReleased())
        {
            SetNote(InputStateManager.IsControlPressed() ? 3 : 2);
        }
        if (InputStateManager.IsDReleased())
        {
            SetNote(4);
        }
        if (InputStateManager.IsFReleased())
        {
            SetNote(InputStateManager.IsControlPressed() ? 6 : 5);
        }
        if (InputStateManager.IsGReleased())
        {
            SetNote(InputStateManager.IsControlPressed() ? 8 : 7);
        }
        if (InputStateManager.IsHReleased())
        {
            SetNote(InputStateManager.IsControlPressed() ? 10 : 9);
        }
        if (InputStateManager.IsJReleased())
        {
            SetNote(11);
        }
    }

    public void SetNote(int note)
    {
        if (CurrentOctave == FirstOctave)
        {
            if (note >= 9 && note <= 11)
            {
                note -= 9;
            }
            else
            {
                return;
            }
        }
        else if (CurrentOctave == LastOctave)
        {
            if (note == 0)
            {
                note = NotesNumber - 1;
            }
            else
            {
                return;
            }
        }
        else if (CurrentOctave > FirstOctave && CurrentOctave <= LastOctave)
        {
            note += 3 + 12 * (CurrentOctave - FirstOctave - 1);
        }

        if (CanAddNote())
        {
            SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, note] = GetValue();
            CurrentNoteInTime = note;
        }

        int GetValue()
        {
            int value = SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, note];
            return value < MaxLengthOneNote ? value + 1 : 0;
        }

        bool CanAddNote()
        {
            var countNotes = 0;

            for (int i = 0; i < NotesNumber; i++)
            {
                if (SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, i] > 0
                    && note != i)
                {
                    countNotes++;
                }
            }

            if (countNotes == 7)
            {
                return false;
            }

            var result = true;
            var value = GetValue();

            // Analyzing previous notes
            var start = CurrentTimeIndex - MaxLengthOneNote < 0 ? 0 : CurrentTimeIndex - MaxLengthOneNote;
            for (int i = start; i < CurrentTimeIndex; i++)
            {
                if (SongEditorManager.Songs[SongEditorManager.CurrentSong][i, note] + i > CurrentTimeIndex)
                {
                    return false;
                }
            }

            // Analyzing next notes
            var end = CurrentTimeIndex + value > SongLength ? SongLength : CurrentTimeIndex + value;
            for (int i = CurrentTimeIndex + 1; i < end; i++)
            {
                if (value + CurrentTimeIndex > SongLength
                    || SongEditorManager.Songs[SongEditorManager.CurrentSong][i, note] > 0 && value + CurrentTimeIndex > i)
                {
                    return false;
                }
            }

            // Analyzing last item index
            if (CurrentTimeIndex == SongLength - 1 && value > 1)
            {
                return false;
            }

            return result; 
        }
    }

    public void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        var texture = GlobalManager.PixelTexture;

        int xPosition = 0;

        // Draw Piano White keys
        for (int i = 0; i < NotesNumber; i++)
        {
            bool isWhiteKey = IsWhiteKey(i);

            if (isWhiteKey)
            {
                var whiteRect = new Rectangle(Position.X + xPosition, Position.Y, WhiteKeyWidth, WhiteKeyHeight);
                var color = 2;
                if (SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, i] > 0)
                {
                    color = 3;
                }
                spriteBatch.CustomDraw(texture,whiteRect,ColorUtils.GetColor(color));
                spriteBatch.DrawBorder(whiteRect, 1, 1, Point.Zero);
                xPosition += WhiteKeyWidth;
            }
        }

        xPosition = 0;

        // Draw Piano Black keys
        for (int i = 0; i < NotesNumber; i++)
        {
            bool isBlackKey = !IsWhiteKey(i);

            if (isBlackKey)
            {
                var blackRect = new Rectangle(Position.X + xPosition - (BlackKeyWidth / 2), Position.Y, BlackKeyWidth, BlackKeyHeight);
                var color = 1;
                if (SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, i] > 0)
                {
                    color = 3;
                }
                spriteBatch.CustomDraw(texture,blackRect,ColorUtils.GetColor(color));
                spriteBatch.DrawBorder(blackRect, 1, 1, Point.Zero);
            }
            else
            {
                xPosition += WhiteKeyWidth;
            }
        }
        
        var currentNote = "  ";
        if (SongEditorManager.Songs[SongEditorManager.CurrentSong][CurrentTimeIndex, CurrentNoteInTime] > 0)
        {
            currentNote = ((Note)(CurrentNoteInTime + 1)).ToString();
        }
        spriteBatch.DrawText("Page:" + CurrentPage + " Time:" + CurrentTimeIndex + " Pointer:" + Pointer + " Octave:" + CurrentOctave + " Note:" + currentNote + " Speed:" + SongEditorManager.SongMinLength, new Vector2(Position.X, Position.Y + 100), 1);
        int h = 0;
        int yOffSet = 120;

        // Draw Grid
        spriteBatch.DrawBorder(new Rectangle(Position.X, Position.Y + yOffSet, WhiteKeyWidth*(NotesNumber - BlackNotesNumber), SizeY* RowsPerPage), 1, 1, Point.Zero);
        for (int x = 0; x < (NotesNumber - BlackNotesNumber); x++)
        {
            for (int y = 0; y < RowsPerPage; y++)
            {
                int drawX = Position.X + x * WhiteKeyWidth;
                int drawY = Position.Y + yOffSet + y * SizeY;
                // Draw vertical lines
                spriteBatch.CustomDraw(texture, new Rectangle(drawX, Position.Y + yOffSet, 1, SizeY * RowsPerPage), ColorUtils.GetColor(1));
                // Draw horizontal lines
                spriteBatch.CustomDraw(texture, new Rectangle(Position.X, drawY, WhiteKeyWidth * (NotesNumber - BlackNotesNumber), 1), ColorUtils.GetColor(1));
            }
        }

        // Draw selected White keys from previous page
        var startPage = Math.Max(0, Pointer - MaxLengthOneNote);
        for (int y = startPage; y < Pointer; y++)
        {
            xPosition = 0;

            for (int i = 0; i < NotesNumber; i++)
            {
                bool isWhiteKey = IsWhiteKey(i);
                if (SongEditorManager.Songs[SongEditorManager.CurrentSong][y, i] > 0)
                {
                    if (isWhiteKey)
                    {
                        var whiteRect = new Rectangle(Position.X + xPosition, Position.Y + yOffSet, WhiteKeyWidth, SizeY * SliceNoteBegin(y, i));
                        var color = CurrentTimeIndex == y && CurrentNoteInTime == i ? 3 : 2;

                        if (whiteRect.Height > 0)
                        {
                            spriteBatch.CustomDraw(texture, whiteRect, ColorUtils.GetColor(color));
                            spriteBatch.DrawBorder(whiteRect, 1, 1, Point.Zero);
                        }
                    }
                }

                if (isWhiteKey)
                {
                    xPosition += WhiteKeyWidth;
                }
            }
            h++;
        }

        h = 0;
        // Draw selected Black keys from previous page
        for (int y = startPage; y < Pointer; y++)
        {
            xPosition = 0;
            for (int i = 0; i < NotesNumber; i++)
            {
                bool isWhiteKey = IsWhiteKey(i);
                if (SongEditorManager.Songs[SongEditorManager.CurrentSong][y, i] > 0)
                {
                    if (!isWhiteKey)
                    {
                        var blackRect = new Rectangle(Position.X + xPosition - (BlackKeyWidth / 2), Position.Y + 120, BlackKeyWidth, SizeY * SliceNoteBegin(y, i));
                        var color = CurrentTimeIndex == y && CurrentNoteInTime == i ? 3 : 1;

                        if (blackRect.Height > 0)
                        {
                            spriteBatch.CustomDraw(texture, blackRect, ColorUtils.GetColor(color));
                            spriteBatch.DrawBorder(blackRect, 1, 1, Point.Zero);
                        }
                    }
                }

                if (isWhiteKey)
                {
                    xPosition += WhiteKeyWidth;
                }
            }
            h++;
        }

        h = 0;
        // Draw selected White keys
        for (int y = Pointer; y < Pointer + RowsPerPage; y++)
        {
            xPosition = 0;

            if (CurrentTimeIndex == y)
            {
                spriteBatch.CustomDraw(texture, new Rectangle(Position.X, Position.Y + yOffSet + h * SizeY, WhiteKeyWidth * (NotesNumber - BlackNotesNumber), SizeY), ColorUtils.GetColor(2)*0.5f);
            }

            for (int i = 0; i < NotesNumber; i++)
            {
                bool isWhiteKey = IsWhiteKey(i);
                if (SongEditorManager.Songs[SongEditorManager.CurrentSong][y, i] > 0)
                {
                    if (isWhiteKey)
                    {
                        var whiteRect = new Rectangle(Position.X + xPosition, Position.Y + yOffSet + h * SizeY, WhiteKeyWidth, SizeY* SliceNoteEnd(y, i));
                        var color = CurrentTimeIndex == y && CurrentNoteInTime == i ? 3 : 2;
                        spriteBatch.CustomDraw(texture, whiteRect, ColorUtils.GetColor(color));
                        spriteBatch.DrawBorder(whiteRect, 1, 1, Point.Zero);
                    }
                }

                if (isWhiteKey)
                {
                    xPosition += WhiteKeyWidth;
                }
            }
            h++;
        }

        h = 0;
        // Draw selected Black keys
        for (int y = Pointer; y < Pointer + RowsPerPage; y++)
        {
            xPosition = 0;
            for (int i = 0; i < NotesNumber; i++)
            {
                bool isWhiteKey = IsWhiteKey(i);
                if (SongEditorManager.Songs[SongEditorManager.CurrentSong][y, i] > 0)
                {
                    if (!isWhiteKey)
                    {
                        var blackRect = new Rectangle(Position.X + xPosition - (BlackKeyWidth / 2), Position.Y + 120 + h * SizeY, BlackKeyWidth, SizeY* SliceNoteEnd(y, i));
                        var color = CurrentTimeIndex == y && CurrentNoteInTime == i ? 3 : 1;
                        spriteBatch.CustomDraw(texture, blackRect, ColorUtils.GetColor(color));
                        spriteBatch.DrawBorder(blackRect, 1, 1, Point.Zero);
                    }
                }

                if (isWhiteKey)
                {
                    xPosition += WhiteKeyWidth;
                }
            }
            h++;
        }
    }

    private bool IsWhiteKey(int keyIndex)
    {
        int[] whiteKeyPattern = { 0, 2, 3, 5, 7, 8, 10 };  // Indices for white keys in an octave
        int noteInOctave = keyIndex% 12;
        return whiteKeyPattern.Contains(noteInOctave);
    }

    private int SliceNoteEnd(int index, int note)
    {
        var value = SongEditorManager.Songs[SongEditorManager.CurrentSong][index, note];

        if (value >= Pointer + RowsPerPage - index)
        {
            return Pointer + RowsPerPage - index;
        }

        return value;
    }

    private int SliceNoteBegin(int index, int note)
    {
        var value = SongEditorManager.Songs[SongEditorManager.CurrentSong][index, note];
        if (value > Pointer - index)
        {
            return value - Pointer + index;
        }

        return 0;
    }
}