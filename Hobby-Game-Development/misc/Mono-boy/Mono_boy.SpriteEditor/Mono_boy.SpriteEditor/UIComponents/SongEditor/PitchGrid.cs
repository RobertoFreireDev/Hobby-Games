using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Input;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Utils;
using System;

namespace Mono_boy.SpriteEditor.UIComponents.SongEditor;

internal class PitchGrid
{
    public (Note, uint)[] Melody;

    public int indexPitch;

    public Point Position;

    public int MaxPitch = 400;

    public int PitchPage = 20;

    public uint IncNoteLength = 20;

    public int MaxNoteLength;

    private double _moveDelay = 0.1;

    private double _moveTimer = 0;

    private int MaxNote = Enum.GetValues(typeof(Note)).Length - 1; // Max pitch index

    public PitchGrid()
    {
        ResetMelody();
        Position = new Point(200, 165); 
        MaxNoteLength = (int)IncNoteLength * 4;
    }

    public void Update()
    {
        if (InputStateManager.IsSpaceReleased())
        {
            var melody = new (Note, Note, Note, Note, uint)[]
            {
                (Note.D4, Note.A4, Note.FSharp4, Note.C5, 80), // D major chord
                (Note.Empty, Note.Empty, Note.Empty, Note.E5, 80), // B minor chord
                (Note.G4, Note.B4, Note.D5, Note.C5, 80),      // G major chord
                (Note.Empty, Note.Empty, Note.Empty, Note.Empty, 80),      // E minor chord
                (Note.Empty, Note.Empty, Note.Empty, Note.Empty, 80), // D major chord
                (Note.B4, Note.D5, Note.FSharp4, Note.E5, 80), // B minor chord
                (Note.Empty, Note.Empty, Note.Empty, Note.C5, 80),      // G major chord
                (Note.E4, Note.G4, Note.B4, Note.Empty, 80)       // E minor chord
            };

            //Sfx.AddOrUpdateMelody("melody", melody);
            Sfx.Play("melody");
        }
        MovePitch();
    }

    private void ResetMelody()
    {
        Melody = new (Note, uint)[MaxPitch];
        for (int i = 0; i < Melody.Length; i++)
        {
            Melody[i] = ((Note)1, 0);
        }
    }

    private void MovePitch()
    {
        _moveTimer += GlobalManager.DeltaTime;

        if (_moveTimer < _moveDelay)
        {
            return;
        }

        var up = InputStateManager.IsUpPressed();
        var down = InputStateManager.IsDownPressed();
        var left = InputStateManager.IsLeftPressed();
        var right = InputStateManager.IsRightPressed();
        var control = InputStateManager.IsControlPressed();

        if (control)
        {
            if (Melody[indexPitch].Item2 == MaxNoteLength)
            {
                Melody[indexPitch].Item2 = 0;
            }
            else
            {
                Melody[indexPitch].Item2 += IncNoteLength;
            }
        }
        else if (right)
        {
            if (Melody[indexPitch].Item1 == (Note)MaxNote)
            {
                Melody[indexPitch].Item1 = (Note)1;
            }
            else
            {
                Melody[indexPitch].Item1 = (Note)((int)Melody[indexPitch].Item1 + 1);
            }
        }
        else if (left)
        {
            if (Melody[indexPitch].Item1 == (Note)1)
            {
                Melody[indexPitch].Item1 = (Note)MaxNote;
            }
            else
            {
                Melody[indexPitch].Item1 = (Note)((int)Melody[indexPitch].Item1 - 1);
            }
        }
        else if (up && indexPitch > 0)
        {
            indexPitch -= 1;
        }
        else if (down && indexPitch < MaxPitch - 1)
        {
            indexPitch += 1;
        }

        _moveTimer = 0;
    }

    private bool HasIndex<T>(T[] array, int index)
    {
        return index >= 0 && index < array.Length;
    }

    public void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        var texture = GlobalManager.PixelTexture;
        var sizeX = 32;
        var sizeY = 16;
        var margin = 6;

        int page = indexPitch / PitchPage;
        int index = indexPitch % PitchPage;
        for (int y = 0; y < PitchPage; y++)
        {
            int sizeNoteX = (int)((int)Melody[y + page* PitchPage].Item2 * 8/ IncNoteLength);
            int positionNoteX = (int)Melody[y + page * PitchPage].Item1 * sizeX;

            spriteBatch.CustomDraw(
                texture,
                new Rectangle(Position.X + positionNoteX, Position.Y + y * (sizeY + margin), sizeNoteX, sizeY),
                ColorUtils.GetColor(1)
            );
        }

        var count = 0;
        foreach (var note in Sfx.NoteMap)
        {
            if (count == 0)
            {
                count++;
                continue;
            }
            spriteBatch.DrawText(note.Key, new Vector2(Position.X + count * sizeX, Position.Y - 20), 1);
            count++;
        }

        spriteBatch.CustomDraw(
            texture,
            new Rectangle(Position.X + (int)Melody[indexPitch].Item1 * sizeX, Position.Y + index * (sizeY + margin) + sizeY + 2, sizeX, 2),
            ColorUtils.GetColor(1)
        );

        spriteBatch.DrawText("Page:" + page, new Vector2(Position.X + sizeX, Position.Y - 34), 1);
    }

}